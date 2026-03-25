// Copyright (c) 2025 Sedat Aras — Platr. MIT License.
import { create } from 'zustand';

interface ThemeState {
  isDarkMode: boolean;
  toggleTheme: () => void;
  setDarkMode: (isDark: boolean) => void;
}

export const useThemeStore = create<ThemeState>((set) => ({
  isDarkMode: true, // Platr defaults to dark — plates look best on dark bg
  toggleTheme: () => set((state) => ({ isDarkMode: !state.isDarkMode })),
  setDarkMode: (isDarkMode) => set({ isDarkMode }),
}));
