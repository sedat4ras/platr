// Copyright (c) 2025 Sedat Aras — Platr. MIT License.
import { Colors } from '../constants/theme';
import { useThemeStore } from '../store/themeStore';

export const useTheme = () => {
  const isDarkMode = useThemeStore((state) => state.isDarkMode);
  const colors = isDarkMode ? Colors.dark : Colors.light;
  return { colors, isDarkMode };
};
