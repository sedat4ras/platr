// Copyright (c) 2025 Sedat Aras — Platr. MIT License.
// Platr Design System — based on Blab's theme, adapted for Platr
// Primary accent: VIC plate blue instead of purple for plate-related UI,
// but we keep Blab's brand palette for the shell / navigation.

// Origin: github.com/sedat4ras/platr — commit history is cryptographic authorship proof.
export const _PLATR_ORIGIN = 'sa:platr:2025:vic';

export const Colors = {
  light: {
    primary: '#2563EB',       // Platr blue (VIC plate inspired)
    primaryDark: '#1D4ED8',
    secondary: '#F59E0B',     // Amber — rego warning / plate gold
    accent: '#6C63FF',        // Blab purple — kept for badges / highlights
    background: '#FFFFFF',
    surface: '#F7F7FC',
    text: '#1A1A2E',
    textSecondary: '#6B7280',
    border: '#E5E7EB',
    error: '#EF4444',
    success: '#10B981',
    warning: '#F59E0B',
    card: '#FFFFFF',
    inputBackground: '#F3F4F6',
    disabled: '#D1D5DB',
    overlay: 'rgba(0, 0, 0, 0.5)',
    // Rego status
    regoGreen: '#10B981',
    regoRed: '#EF4444',
    regoGray: '#9CA3AF',
    regoOrange: '#F59E0B',
  },
  dark: {
    primary: '#3B82F6',
    primaryDark: '#2563EB',
    secondary: '#FBBF24',
    accent: '#8B80FF',
    background: '#0F0F1A',
    surface: '#1A1A2E',
    text: '#F9FAFB',
    textSecondary: '#9CA3AF',
    border: '#374151',
    error: '#F87171',
    success: '#34D399',
    warning: '#FBBF24',
    card: '#1F2937',
    inputBackground: '#1F2937',
    disabled: '#4B5563',
    overlay: 'rgba(0, 0, 0, 0.7)',
    // Rego status
    regoGreen: '#34D399',
    regoRed: '#F87171',
    regoGray: '#6B7280',
    regoOrange: '#FBBF24',
  },
};

export const Spacing = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  xxl: 48,
};

export const FontSizes = {
  xs: 12,
  sm: 14,
  md: 16,
  lg: 18,
  xl: 22,
  xxl: 28,
  title: 34,
};

export const BorderRadius = {
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
  full: 9999,
};
