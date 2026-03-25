import React, { useEffect } from 'react';
import { View } from 'react-native';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { StatusBar } from 'expo-status-bar';
import { useTheme } from './src/hooks/useTheme';
import { useAuthStore } from './src/store/authStore';
import RootNavigator from './src/navigation/RootNavigator';
import { ToastHost } from './src/components/Toast';

function AppContent() {
  const { isDarkMode } = useTheme();
  const initAuth = useAuthStore((s) => s.initAuth);

  useEffect(() => {
    initAuth();
  }, []);

  return (
    <View style={{ flex: 1 }}>
      <StatusBar style={isDarkMode ? 'light' : 'dark'} />
      <RootNavigator />
      <ToastHost />
    </View>
  );
}

export default function App() {
  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <AppContent />
    </GestureHandlerRootView>
  );
}
