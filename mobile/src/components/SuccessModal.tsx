import React, { useEffect, useRef } from 'react';
import {
  Modal,
  View,
  Text,
  StyleSheet,
  Animated,
  Dimensions,
  TouchableOpacity,
} from 'react-native';
import { colors, spacing, fontSize, fontWeight, borderRadius } from '../constants/theme';

interface SuccessModalProps {
  visible: boolean;
  onClose: () => void;
  onContinue: () => void;
  title?: string;
  message?: string;
  isCorrect: boolean;
}

const { width, height } = Dimensions.get('window');

export default function SuccessModal({
  visible,
  onClose,
  onContinue,
  title,
  message,
  isCorrect,
}: SuccessModalProps) {
  const scaleAnim = useRef(new Animated.Value(0)).current;
  const fadeAnim = useRef(new Animated.Value(0)).current;
  const bounceAnim = useRef(new Animated.Value(0)).current;
  const confettiAnims = useRef(
    Array.from({ length: 20 }, () => ({
      translateY: new Animated.Value(0),
      translateX: new Animated.Value(0),
      rotate: new Animated.Value(0),
      opacity: new Animated.Value(1),
    }))
  ).current;

  useEffect(() => {
    if (visible) {
      // Reset animations
      scaleAnim.setValue(0);
      fadeAnim.setValue(0);
      bounceAnim.setValue(0);
      confettiAnims.forEach((anim) => {
        anim.translateY.setValue(0);
        anim.translateX.setValue(0);
        anim.rotate.setValue(0);
        anim.opacity.setValue(1);
      });

      // Start animations
      Animated.parallel([
        // Background fade in
        Animated.timing(fadeAnim, {
          toValue: 1,
          duration: 300,
          useNativeDriver: true,
        }),
        // Modal scale in
        Animated.spring(scaleAnim, {
          toValue: 1,
          tension: 50,
          friction: 7,
          useNativeDriver: true,
        }),
      ]).start();

      // Bounce animation for icon
      Animated.sequence([
        Animated.delay(200),
        Animated.spring(bounceAnim, {
          toValue: 1,
          tension: 100,
          friction: 3,
          useNativeDriver: true,
        }),
      ]).start();

      // Confetti animation (only for correct answers)
      if (isCorrect) {
        confettiAnims.forEach((anim, index) => {
          const randomX = (Math.random() - 0.5) * width;
          const randomRotate = Math.random() * 720;
          
          Animated.parallel([
            Animated.timing(anim.translateY, {
              toValue: height,
              duration: 2000 + Math.random() * 1000,
              useNativeDriver: true,
            }),
            Animated.timing(anim.translateX, {
              toValue: randomX,
              duration: 2000 + Math.random() * 1000,
              useNativeDriver: true,
            }),
            Animated.timing(anim.rotate, {
              toValue: randomRotate,
              duration: 2000 + Math.random() * 1000,
              useNativeDriver: true,
            }),
            Animated.timing(anim.opacity, {
              toValue: 0,
              duration: 2000,
              useNativeDriver: true,
            }),
          ]).start();
        });
      }
    }
  }, [visible]);

  if (!visible) return null;

  const defaultTitle = isCorrect ? '🎉 Correct!' : '💡 Not Quite';
  const defaultMessage = isCorrect
    ? 'Great job! You fixed the bug!'
    : "Don't worry, try again!";

  return (
    <Modal transparent visible={visible} animationType="none" onRequestClose={onClose}>
      <Animated.View style={[styles.overlay, { opacity: fadeAnim }]}>
        {/* Confetti */}
        {isCorrect && (
          <View style={StyleSheet.absoluteFill}>
            {confettiAnims.map((anim, index) => (
              <Animated.View
                key={index}
                style={[
                  styles.confetti,
                  {
                    left: width / 2 - 10,
                    top: height / 3,
                    backgroundColor: [
                      colors.primary,
                      colors.success,
                      colors.warning,
                      colors.info,
                    ][index % 4],
                    transform: [
                      { translateY: anim.translateY },
                      { translateX: anim.translateX },
                      {
                        rotate: anim.rotate.interpolate({
                          inputRange: [0, 720],
                          outputRange: ['0deg', '720deg'],
                        }),
                      },
                    ],
                    opacity: anim.opacity,
                  },
                ]}
              />
            ))}
          </View>
        )}

        <Animated.View
          style={[
            styles.modal,
            {
              transform: [{ scale: scaleAnim }],
              backgroundColor: isCorrect ? colors.successLight : colors.errorLight,
            },
          ]}
        >
          <Animated.Text
            style={[
              styles.icon,
              {
                transform: [{ scale: bounceAnim }],
              },
            ]}
          >
            {isCorrect ? '🎉' : '🤔'}
          </Animated.Text>

          <Text
            style={[
              styles.title,
              { color: isCorrect ? colors.successDark : colors.errorDark },
            ]}
          >
            {title || defaultTitle}
          </Text>

          <Text style={styles.message}>{message || defaultMessage}</Text>

          <View style={styles.buttonContainer}>
            {!isCorrect && (
              <TouchableOpacity style={styles.tryAgainButton} onPress={onClose}>
                <Text style={styles.tryAgainText}>Try Again</Text>
              </TouchableOpacity>
            )}

            <TouchableOpacity
              style={[
                styles.continueButton,
                {
                  backgroundColor: isCorrect ? colors.success : colors.primary,
                  width: isCorrect ? '100%' : '48%',
                },
              ]}
              onPress={onContinue}
            >
              <Text style={styles.continueText}>
                {isCorrect ? 'Continue' : 'See Solution'}
              </Text>
            </TouchableOpacity>
          </View>
        </Animated.View>
      </Animated.View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modal: {
    width: width * 0.85,
    borderRadius: borderRadius.xl,
    padding: spacing.xl,
    alignItems: 'center',
  },
  icon: {
    fontSize: 80,
    marginBottom: spacing.lg,
  },
  title: {
    fontSize: fontSize.xxxl,
    fontWeight: fontWeight.bold,
    marginBottom: spacing.md,
    textAlign: 'center',
  },
  message: {
    fontSize: fontSize.md,
    color: colors.textSecondary,
    textAlign: 'center',
    marginBottom: spacing.xl,
  },
  buttonContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    width: '100%',
    gap: spacing.md,
  },
  tryAgainButton: {
    flex: 1,
    paddingVertical: spacing.md,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.white,
    borderWidth: 2,
    borderColor: colors.error,
    alignItems: 'center',
  },
  tryAgainText: {
    fontSize: fontSize.md,
    fontWeight: fontWeight.semibold,
    color: colors.error,
  },
  continueButton: {
    flex: 1,
    paddingVertical: spacing.md,
    borderRadius: borderRadius.lg,
    alignItems: 'center',
  },
  continueText: {
    fontSize: fontSize.md,
    fontWeight: fontWeight.semibold,
    color: colors.white,
  },
  confetti: {
    position: 'absolute',
    width: 10,
    height: 10,
    borderRadius: 5,
  },
});
