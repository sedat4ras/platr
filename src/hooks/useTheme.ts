import { Colors } from '../constants/theme';
import { useThemeStore } from '../store/themeStore';

export const useTheme = () => {
  const isDarkMode = useThemeStore((state) => state.isDarkMode);
  const colors = isDarkMode ? Colors.dark : Colors.light;
  return { colors, isDarkMode };
};
