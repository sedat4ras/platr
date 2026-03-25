// Copyright (c) 2025 Sedat Aras — Platr. MIT License.
import { verifyAttribution } from '../core/attribution';
// Attribution integrity check — see src/core/attribution.ts
// To request removal, contact: sedat@platr.com.au
if (!verifyAttribution()) {
  throw new Error('Attribution removed. Contact sedat@platr.com.au to discuss licensing.');
}
import { useAuthStore } from '../store/authStore';
import { AuthUser, Comment, Plate, PlateCreateRequest, StarStatusResponse } from '../types';

const BASE_URL = process.env.EXPO_PUBLIC_API_URL!;

class ApiError extends Error {
  status: number;
  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

export class DuplicatePlateError extends Error {
  existingPlateId: string;
  stateCode: string;
  plateText: string;
  constructor(existingPlateId: string, stateCode: string, plateText: string) {
    super(`Plate ${stateCode}·${plateText} already exists.`);
    this.existingPlateId = existingPlateId;
    this.stateCode = stateCode;
    this.plateText = plateText;
  }
}

async function request<T>(
  method: string,
  path: string,
  body?: object
): Promise<T> {
  const token = useAuthStore.getState().token;
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
  if (token) headers['Authorization'] = `Bearer ${token}`;

  const res = await fetch(`${BASE_URL}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });

  if (res.status === 409) {
    const data = await res.json();
    throw new DuplicatePlateError(data.existing_plate_id, data.state_code, data.plate_text);
  }

  if (!res.ok) {
    const text = await res.text();
    throw new ApiError(res.status, text);
  }

  if (res.status === 204) return undefined as T;
  return res.json();
}

// ── Auth ────────────────────────────────────────────────────────────────────

export async function loginApi(email: string, password: string): Promise<{ access_token: string; refresh_token: string }> {
  return request('POST', '/auth/login', { login: email, password });
}

export async function googleSignInApi(idToken: string): Promise<{ access_token: string; refresh_token: string }> {
  return request('POST', '/auth/google', { id_token: idToken });
}

export async function appleSignInApi(
  identityToken: string,
  fullName?: string
): Promise<{ access_token: string; refresh_token: string }> {
  return request('POST', '/auth/apple', { identity_token: identityToken, full_name: fullName });
}

export async function registerApi(
  username: string,
  email: string,
  password: string,
  displayName?: string
): Promise<{ access_token: string; user: AuthUser }> {
  return request('POST', '/auth/register', { username, email, password, display_name: displayName });
}

export async function fetchMeApi(): Promise<AuthUser> {
  return request('GET', '/auth/me');
}

// ── Plates ──────────────────────────────────────────────────────────────────

export async function listPlatesApi(stateCode = 'VIC'): Promise<Plate[]> {
  return request('GET', `/plates?state_code=${stateCode}`);
}

export async function searchPlatesApi(query: string, stateCode = 'VIC'): Promise<Plate[]> {
  return request('GET', `/plates/search?q=${encodeURIComponent(query)}&state_code=${stateCode}`);
}

export async function getPlateApi(id: string): Promise<Plate> {
  return request('GET', `/plates/${id}`);
}

export async function createPlateApi(payload: PlateCreateRequest): Promise<Plate> {
  return request('POST', '/plates', payload);
}

export async function starPlateApi(id: string): Promise<StarStatusResponse> {
  return request('POST', `/plates/${id}/star`);
}

export async function unstarPlateApi(id: string): Promise<StarStatusResponse> {
  return request('DELETE', `/plates/${id}/star`);
}

export async function getStarStatusApi(id: string): Promise<StarStatusResponse> {
  return request('GET', `/plates/${id}/star`);
}

export async function listMyPlatesApi(): Promise<Plate[]> {
  return request('GET', '/plates/submitted-by-me');
}

export async function uploadPlatePhotoApi(plateId: string, imageUri: string): Promise<Plate> {
  const token = useAuthStore.getState().token;
  const formData = new FormData();
  formData.append('photo', { uri: imageUri, type: 'image/jpeg', name: 'plate.jpg' } as any);
  const res = await fetch(`${BASE_URL}/plates/${plateId}/photo`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` },
    body: formData,
  });
  if (!res.ok) throw new Error('Photo upload failed');
  return res.json();
}

// ── Comments ────────────────────────────────────────────────────────────────

export async function listCommentsApi(plateId: string): Promise<Comment[]> {
  return request('GET', `/plates/${plateId}/comments`);
}

export async function postCommentApi(plateId: string, body: string): Promise<Comment> {
  return request('POST', `/plates/${plateId}/comments`, { body });
}

export async function reportCommentApi(commentId: string, reason: string): Promise<void> {
  return request('POST', `/comments/${commentId}/report`, { reason });
}

export async function blockUserApi(userId: string): Promise<void> {
  return request('POST', `/users/${userId}/block`);
}

// ── Ownership ────────────────────────────────────────────────────────────────

export async function claimPlateVicroadsApi(plateId: string, screenshotUri: string): Promise<void> {
  const token = useAuthStore.getState().token;
  const formData = new FormData();
  formData.append('screenshot', { uri: screenshotUri, type: 'image/jpeg', name: 'vicroads.jpg' } as any);
  const res = await fetch(`${BASE_URL}/plates/${plateId}/claim/vicroads`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` },
    body: formData,
  });
  if (!res.ok) throw new Error('Claim submission failed');
}

export async function getClaimStatusApi(plateId: string): Promise<{ status: string; is_verified: boolean }> {
  return request('GET', `/plates/${plateId}/claim/status`);
}

export async function toggleCommentsApi(plateId: string): Promise<Plate> {
  return request('PATCH', `/plates/${plateId}/comments/toggle`);
}

// ── Profile ──────────────────────────────────────────────────────────────────

export async function updateProfileApi(data: { display_name?: string; bio?: string }): Promise<AuthUser> {
  return request('PATCH', '/auth/me', data);
}

export async function deleteAccountApi(): Promise<void> {
  return request('DELETE', '/auth/me');
}
