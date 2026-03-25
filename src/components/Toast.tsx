// Copyright (c) 2025 Sedat Aras — Platr. MIT License.
import React, { useRef, useImperativeHandle, forwardRef, createRef } from 'react';
import {
  Animated,
  Text,
  StyleSheet,
  SafeAreaView,
} from 'react-native';

type ToastType = 'success' | 'error' | 'info';

interface ToastConfig {
  message: string;
  type: ToastType;
}

interface ToastHandle {
  show: (message: string, type?: ToastType) => void;
}

const TYPE_COLORS: Record<ToastType, string> = {
  success: '#34C759',
  error: '#FF3B30',
  info: '#007AFF',
};

const ToastComponent = forwardRef<ToastHandle>((_, ref) => {
  const translateY = useRef(new Animated.Value(-80)).current;
  const timeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const [config, setConfig] = React.useState<ToastConfig>({ message: '', type: 'info' });
  const [visible, setVisible] = React.useState(false);

  useImperativeHandle(ref, () => ({
    show(message: string, type: ToastType = 'info') {
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current);
        timeoutRef.current = null;
      }

      setConfig({ message, type });
      setVisible(true);

      // Slide in
      Animated.spring(translateY, {
        toValue: 0,
        useNativeDriver: true,
        tension: 80,
        friction: 10,
      }).start();

      // Auto-dismiss after 2.5s
      timeoutRef.current = setTimeout(() => {
        Animated.timing(translateY, {
          toValue: -80,
          duration: 300,
          useNativeDriver: true,
        }).start(() => setVisible(false));
      }, 2500);
    },
  }));

  if (!visible) return null;

  const bg = TYPE_COLORS[config.type];

  return (
    <Animated.View
      style={[
        styles.container,
        { backgroundColor: bg, transform: [{ translateY }] },
      ]}
      pointerEvents="none"
    >
      <SafeAreaView>
        <Text style={styles.message}>{config.message}</Text>
      </SafeAreaView>
    </Animated.View>
  );
});

ToastComponent.displayName = 'Toast';

// Global ref
const toastRef = createRef<ToastHandle>();

export function ToastHost() {
  return <ToastComponent ref={toastRef} />;
}

export function showToast(message: string, type: ToastType = 'info') {
  toastRef.current?.show(message, type);
}

const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    zIndex: 9999,
    paddingHorizontal: 16,
    paddingTop: 12,
    paddingBottom: 12,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 3 },
    shadowOpacity: 0.25,
    shadowRadius: 8,
    elevation: 10,
  },
  message: {
    color: '#FFFFFF',
    fontSize: 15,
    fontWeight: '600',
    textAlign: 'center',
  },
});
