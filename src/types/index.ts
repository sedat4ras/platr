// Copyright (c) 2025 Sedat Aras — Platr. MIT License.
// Platr TypeScript types

export type PlateStyle = 'VIC_STANDARD' | 'VIC_BLACK' | 'VIC_CUSTOM';

// VIC badge position on custom plates
export type VicBadgeStyle = 'none' | 'triangle_top' | 'vertical_left' | 'box_topleft';

// State text shown on plate
export type StateTextOption = 'none' | 'victoria' | 'education_state' | 'garden_state';

// Separator inserted visually in plate text middle (the actual char to insert, '' = none)
export type SeparatorStyle = string;

// Border style for custom plates
export type BorderStyleOption = 'none' | 'chrome' | 'flat';

export interface CustomPlateConfig {
  bgColor: string;            // hex, e.g. '#222222'
  textColor: string;          // hex, e.g. '#FFFFFF'
  borderStyle: BorderStyleOption;
  borderColor: string;        // hex, used when borderStyle = 'flat'
  vicBadge: VicBadgeStyle;
  stateText: StateTextOption;
  stateTextPosition: 'top' | 'bottom';
  separator: SeparatorStyle;
}

export const DEFAULT_CUSTOM_CONFIG: CustomPlateConfig = {
  bgColor: '#1A1A1A',
  textColor: '#FFFFFF',
  borderStyle: 'chrome',
  borderColor: '#888888',
  vicBadge: 'vertical_left',
  stateText: 'victoria',
  stateTextPosition: 'bottom',
  separator: '',
};

export interface Plate {
  id: string;
  state_code: string;
  plate_text: string;
  plate_style: PlateStyle;
  is_comments_open: boolean;
  star_count: number;
  view_count: number;
  owner_user_id: string | null;
  submitted_by_user_id: string | null;
  submitted_by_username: string | null;
  plate_photo_path: string | null;
  ownership_verified: boolean;
  custom_config: CustomPlateConfig | null;
  created_at: string;
  updated_at: string;
}

export interface Comment {
  id: string;
  plate_id: string;
  author_user_id: string;
  author_username: string;
  body: string;
  is_hidden?: boolean;
  created_at: string;
}

export interface AuthUser {
  id: string;
  username: string;
  email: string;
  display_name: string | null;
  bio?: string | null;
  is_verified: boolean;
  created_at: string;
}

export interface PlateCreateRequest {
  plate_text: string;
  plate_style: PlateStyle;
  custom_config?: CustomPlateConfig | null;
}

export interface StarStatusResponse {
  star_count: number;
  starred: boolean;
}

export interface DuplicatePlateResponse {
  detail: string;
  existing_plate_id: string;
  state_code: string;
  plate_text: string;
}

// Plate style display names
export const PLATE_STYLE_META: Record<PlateStyle, { displayName: string; maxChars: number; formatHint: string }> = {
  VIC_STANDARD: { displayName: 'VIC Standard',  maxChars: 6, formatHint: 'e.g. ABC123' },
  VIC_BLACK:    { displayName: 'VIC Black',      maxChars: 7, formatHint: 'e.g. 1LOVE'  },
  VIC_CUSTOM:   { displayName: 'VIC Custom',     maxChars: 8, formatHint: 'e.g. MY1CAR' },
};

