import React from 'react';
import {
  TouchableOpacity,
  Text,
  ActivityIndicator,
  ViewStyle,
  TextStyle,
} from 'react-native';
import { useTheme } from '../hooks/useTheme';
import { BorderRadius, FontSizes, Spacing } from '../constants/theme';

interface ButtonProps {
  title: string;
  onPress: () => void;
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  loading?: boolean;
  disabled?: boolean;
  style?: ViewStyle;
  textStyle?: TextStyle;
  icon?: React.ReactNode;
}

const Button: React.FC<ButtonProps> = ({
  title,
  onPress,
  variant = 'primary',
  size = 'md',
  loading = false,
  disabled = false,
  style,
  textStyle,
  icon,
}) => {
  const { colors } = useTheme();
  const isDisabled = disabled || loading;

  const getButtonStyle = (): ViewStyle => {
    const sizeStyles: Record<string, ViewStyle> = {
      sm: { paddingVertical: Spacing.sm, paddingHorizontal: Spacing.md },
      md: { paddingVertical: Spacing.md - 2, paddingHorizontal: Spacing.lg },
      lg: { paddingVertical: Spacing.md + 2, paddingHorizontal: Spacing.xl },
    };
    const variantStyles: Record<string, ViewStyle> = {
      primary:   { backgroundColor: isDisabled ? colors.disabled : colors.primary },
      secondary: { backgroundColor: isDisabled ? colors.disabled : colors.secondary },
      outline:   { backgroundColor: 'transparent', borderWidth: 1.5, borderColor: isDisabled ? colors.disabled : colors.primary },
      ghost:     { backgroundColor: 'transparent' },
      danger:    { backgroundColor: isDisabled ? colors.disabled : colors.error },
    };
    return {
      borderRadius: BorderRadius.md,
      alignItems: 'center',
      justifyContent: 'center',
      flexDirection: 'row',
      gap: 8,
      ...sizeStyles[size],
      ...variantStyles[variant],
    };
  };

  const getTextStyle = (): TextStyle => {
    const sizeStyles: Record<string, TextStyle> = {
      sm: { fontSize: FontSizes.sm },
      md: { fontSize: FontSizes.md },
      lg: { fontSize: FontSizes.lg },
    };
    const variantStyles: Record<string, TextStyle> = {
      primary:   { color: '#FFFFFF' },
      secondary: { color: '#FFFFFF' },
      outline:   { color: isDisabled ? colors.disabled : colors.primary },
      ghost:     { color: isDisabled ? colors.disabled : colors.primary },
      danger:    { color: '#FFFFFF' },
    };
    return { fontWeight: '600', ...sizeStyles[size], ...variantStyles[variant] };
  };

  return (
    <TouchableOpacity
      style={[getButtonStyle(), style]}
      onPress={onPress}
      disabled={isDisabled}
      activeOpacity={0.75}
      accessibilityLabel={title}
      accessibilityRole="button"
      accessibilityState={{ disabled: isDisabled, busy: loading }}
    >
      {loading ? (
        <ActivityIndicator
          color={variant === 'outline' || variant === 'ghost' ? colors.primary : '#FFFFFF'}
          size="small"
        />
      ) : (
        <>
          {icon}
          <Text style={[getTextStyle(), textStyle]}>{title}</Text>
        </>
      )}
    </TouchableOpacity>
  );
};

export default Button;
