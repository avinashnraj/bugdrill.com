import React from 'react';
import {
  TouchableOpacity,
  Text,
  StyleSheet,
  ActivityIndicator,
  ViewStyle,
  TextStyle,
} from 'react-native';
import { colors, spacing, borderRadius, fontSize, fontWeight, shadows } from '../constants/theme';

type ButtonVariant = 'primary' | 'secondary' | 'success' | 'danger' | 'outline';
type ButtonSize = 'sm' | 'md' | 'lg';

interface ButtonProps {
  title: string;
  onPress: () => void;
  variant?: ButtonVariant;
  size?: ButtonSize;
  disabled?: boolean;
  loading?: boolean;
  fullWidth?: boolean;
  style?: ViewStyle;
  textStyle?: TextStyle;
}

export default function Button({
  title,
  onPress,
  variant = 'primary',
  size = 'md',
  disabled = false,
  loading = false,
  fullWidth = false,
  style,
  textStyle,
}: ButtonProps) {
  const getButtonStyle = (): ViewStyle => {
    const baseStyle: ViewStyle = {
      borderRadius: borderRadius.lg,
      alignItems: 'center',
      justifyContent: 'center',
      flexDirection: 'row',
      ...shadows.sm,
    };

    // Size styles
    const sizeStyles: Record<ButtonSize, ViewStyle> = {
      sm: { paddingHorizontal: spacing.md, paddingVertical: spacing.sm, minHeight: 36 },
      md: { paddingHorizontal: spacing.lg, paddingVertical: spacing.md, minHeight: 48 },
      lg: { paddingHorizontal: spacing.xl, paddingVertical: spacing.lg, minHeight: 56 },
    };

    // Variant styles
    const variantStyles: Record<ButtonVariant, ViewStyle> = {
      primary: { backgroundColor: colors.primary },
      secondary: { backgroundColor: colors.gray700 },
      success: { backgroundColor: colors.success },
      danger: { backgroundColor: colors.error },
      outline: { 
        backgroundColor: 'transparent', 
        borderWidth: 2, 
        borderColor: colors.primary 
      },
    };

    const finalStyle = {
      ...baseStyle,
      ...sizeStyles[size],
      ...variantStyles[variant],
    };

    if (disabled || loading) {
      finalStyle.opacity = 0.5;
    }

    if (fullWidth) {
      finalStyle.width = '100%';
    }

    return finalStyle;
  };

  const getTextStyle = (): TextStyle => {
    const sizeStyles: Record<ButtonSize, TextStyle> = {
      sm: { fontSize: fontSize.sm },
      md: { fontSize: fontSize.md },
      lg: { fontSize: fontSize.lg },
    };

    const variantTextStyles: Record<ButtonVariant, TextStyle> = {
      primary: { color: colors.white },
      secondary: { color: colors.white },
      success: { color: colors.white },
      danger: { color: colors.white },
      outline: { color: colors.primary },
    };

    return {
      fontWeight: fontWeight.semibold,
      ...sizeStyles[size],
      ...variantTextStyles[variant],
    };
  };

  return (
    <TouchableOpacity
      style={[getButtonStyle(), style]}
      onPress={onPress}
      disabled={disabled || loading}
      activeOpacity={0.7}
    >
      {loading ? (
        <ActivityIndicator 
          color={variant === 'outline' ? colors.primary : colors.white} 
          size="small" 
        />
      ) : (
        <Text style={[getTextStyle(), textStyle]}>{title}</Text>
      )}
    </TouchableOpacity>
  );
}
