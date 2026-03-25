// Copyright (c) 2025 Sedat Aras — Platr. MIT License.
import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import { useAuthStore } from '../store/authStore';
import { useTheme } from '../hooks/useTheme';
import MainTabNavigator from './MainTabNavigator';
import SplashScreen from '../screens/auth/SplashScreen';
import LoginScreen from '../screens/auth/LoginScreen';
import RegisterScreen from '../screens/auth/RegisterScreen';
import PlateDetailScreen from '../screens/plate/PlateDetailScreen';
import AddPlateScreen from '../screens/plate/AddPlateScreen';
import EditProfileScreen from '../screens/profile/EditProfileScreen';
import LegalScreen from '../screens/legal/LegalScreen';
import { Plate } from '../types';

export type RootStackParamList = {
  Splash: undefined;
  Auth: undefined;
  Register: undefined;
  Main: undefined;
  PlateDetail: { plateId: string };
  AddPlate: {
    onDuplicateFound?: (plateId: string) => void;
    onPlateCreated?: (plate: Plate) => void;
  };
  EditProfile: undefined;
  Legal: undefined;
};

const Stack = createStackNavigator<RootStackParamList>();

export default function RootNavigator() {
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated);
  const isLoading = useAuthStore((s) => s.isLoading);
  const { colors, isDarkMode } = useTheme();

  return (
    <NavigationContainer
      theme={{
        dark: isDarkMode,
        colors: {
          primary: colors.primary,
          background: colors.background,
          card: colors.surface,
          text: colors.text,
          border: colors.border,
          notification: colors.primary,
        },
        fonts: {
          regular: { fontFamily: 'System', fontWeight: '400' },
          medium:  { fontFamily: 'System', fontWeight: '500' },
          bold:    { fontFamily: 'System', fontWeight: '700' },
          heavy:   { fontFamily: 'System', fontWeight: '900' },
        },
      }}
    >
      <Stack.Navigator screenOptions={{ headerShown: false }}>
        <Stack.Screen name="Splash" component={SplashScreen} />
        {isAuthenticated ? (
          <>
            <Stack.Screen name="Main" component={MainTabNavigator} />
            <Stack.Screen
              name="PlateDetail"
              component={PlateDetailScreen}
              options={{ headerShown: true, title: '' }}
            />
            <Stack.Screen
              name="AddPlate"
              component={AddPlateScreen}
              options={{
                headerShown: true,
                title: 'Add Plate',
                presentation: 'modal',
              }}
            />
            <Stack.Screen
              name="EditProfile"
              component={EditProfileScreen}
              options={{ headerShown: true, title: 'Edit Profile', presentation: 'modal' }}
            />
            <Stack.Screen
              name="Legal"
              component={LegalScreen}
              options={{ headerShown: true, title: 'Legal & Privacy' }}
            />
          </>
        ) : (
          <>
            <Stack.Screen name="Auth" component={LoginScreen} />
            <Stack.Screen
              name="Register"
              component={RegisterScreen}
              options={{ headerShown: true, title: 'Create Account', presentation: 'modal' }}
            />
          </>
        )}
      </Stack.Navigator>
    </NavigationContainer>
  );
}
