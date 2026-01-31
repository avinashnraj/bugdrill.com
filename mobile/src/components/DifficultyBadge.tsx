import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { colors, spacing, borderRadius, fontSize, fontWeight } from '../constants/theme';

interface DifficultyBadgeProps {
  difficulty: 'Beginner' | 'Medium' | 'Hard';
  size?: 'sm' | 'md' | 'lg';
}

export default function DifficultyBadge({ difficulty, size = 'md' }: DifficultyBadgeProps) {
  const getColor = () => {
    switch (difficulty) {
      case 'Beginner':
        return { bg: colors.successLight, text: colors.successDark };
      case 'Medium':
        return { bg: colors.warningLight, text: '#92400E' };
      case 'Hard':
        return { bg: colors.errorLight, text: colors.errorDark };
      default:
        return { bg: colors.gray100, text: colors.gray700 };
    }
  };

  const getSizeStyles = () => {
    switch (size) {
      case 'sm':
        return { paddingHorizontal: spacing.sm, paddingVertical: 2, fontSize: fontSize.xs };
      case 'lg':
        return { paddingHorizontal: spacing.md, paddingVertical: spacing.sm, fontSize: fontSize.md };
      default:
        return { paddingHorizontal: spacing.sm, paddingVertical: 4, fontSize: fontSize.sm };
    }
  };

  const colorScheme = getColor();
  const sizeStyles = getSizeStyles();

  return (
    <View
      style={[
        styles.badge,
        { 
          backgroundColor: colorScheme.bg,
          paddingHorizontal: sizeStyles.paddingHorizontal,
          paddingVertical: sizeStyles.paddingVertical,
        },
      ]}
    >
      <Text
        style={[
          styles.text,
          { 
            color: colorScheme.text,
            fontSize: sizeStyles.fontSize,
          },
        ]}
      >
        {difficulty}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  badge: {
    borderRadius: borderRadius.md,
    alignSelf: 'flex-start',
  },
  text: {
    fontWeight: fontWeight.semibold,
  },
});
