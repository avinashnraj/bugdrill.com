import React, { useEffect, useRef } from 'react';
import { View, Text, StyleSheet, Animated } from 'react-native';
import { colors, spacing, borderRadius, fontSize, fontWeight } from '../constants/theme';

interface ProgressBarProps {
  current: number;
  total: number;
  showLabel?: boolean;
  height?: number;
  color?: string;
}

export default function ProgressBar({
  current,
  total,
  showLabel = true,
  height = 8,
  color = colors.primary,
}: ProgressBarProps) {
  const progress = total > 0 ? (current / total) * 100 : 0;
  const animatedWidth = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    Animated.spring(animatedWidth, {
      toValue: progress,
      tension: 50,
      friction: 7,
      useNativeDriver: false,
    }).start();
  }, [progress]);

  return (
    <View style={styles.container}>
      {showLabel && (
        <Text style={styles.label}>
          {current} / {total} completed
        </Text>
      )}
      <View style={[styles.track, { height }]}>
        <Animated.View
          style={[
            styles.progress,
            {
              width: animatedWidth.interpolate({
                inputRange: [0, 100],
                outputRange: ['0%', '100%'],
              }),
              backgroundColor: color,
              height,
            },
          ]}
        />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    width: '100%',
  },
  label: {
    fontSize: fontSize.sm,
    color: colors.textSecondary,
    marginBottom: spacing.xs,
    fontWeight: fontWeight.medium,
  },
  track: {
    width: '100%',
    backgroundColor: colors.gray200,
    borderRadius: borderRadius.full,
    overflow: 'hidden',
  },
  progress: {
    borderRadius: borderRadius.full,
  },
});
