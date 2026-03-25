import { create } from 'zustand';
import * as SecureStore from 'expo-secure-store';
import { AuthUser } from '../types';

const TOKEN_KEY = 'platr_access_token';

interface AuthState {
  currentUser: AuthUser | null;
  token: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  initAuth: () => Promise<void>;
  setAuth: (user: AuthUser | null, token: string) => Promise<void>;
  logout: () => Promise<void>;
  setUser: (user: AuthUser) => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  currentUser: null,
  token: null,
  isAuthenticated: false,
  isLoading: true,

  initAuth: async () => {
    try {
      const token = await SecureStore.getItemAsync(TOKEN_KEY);
      if (token) {
        set({ token, isAuthenticated: true, isLoading: false });
      } else {
        set({ isLoading: false });
      }
    } catch {
      set({ isLoading: false });
    }
  },

  setAuth: async (user: AuthUser | null, token: string) => {
    await SecureStore.setItemAsync(TOKEN_KEY, token);
    set({ currentUser: user, token, isAuthenticated: true });
  },

  logout: async () => {
    await SecureStore.deleteItemAsync(TOKEN_KEY);
    set({ currentUser: null, token: null, isAuthenticated: false });
  },

  setUser: (user: AuthUser) => set({ currentUser: user }),
}));
