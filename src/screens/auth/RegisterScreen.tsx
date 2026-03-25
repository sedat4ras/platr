// Copyright (c) 2025 Sedat Aras — Platr. MIT License.
import React, { useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useTheme } from '../../hooks/useTheme';
import { useAuthStore } from '../../store/authStore';
import { registerApi } from '../../services/api';
import { BorderRadius, FontSizes, Spacing } from '../../constants/theme';
import Button from '../../components/Button';
import Input from '../../components/Input';

export default function RegisterScreen() {
  const { colors } = useTheme();
  const nav = useNavigation();
  const setAuth = useAuthStore((s) => s.setAuth);

  const [username, setUsername]       = useState('');
  const [email, setEmail]             = useState('');
  const [displayName, setDisplayName] = useState('');
  const [password, setPassword]       = useState('');
  const [confirm, setConfirm]         = useState('');
  const [loading, setLoading]         = useState(false);
  const [error, setError]             = useState('');

  const valid =
    username.trim().length >= 3 &&
    email.trim().includes('@') &&
    password.length >= 8 &&
    password === confirm;

  const handleRegister = async () => {
    if (!valid) {
      if (password !== confirm) setError('Passwords do not match.');
      else if (password.length < 8) setError('Password must be at least 8 characters.');
      return;
    }
    setLoading(true);
    setError('');
    try {
      const { access_token, user } = await registerApi(
        username.trim(),
        email.trim(),
        password,
        displayName.trim() || undefined
      );
      await setAuth(user, access_token);
    } catch (e: any) {
      setError(e.message || 'Registration failed. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <KeyboardAvoidingView
      style={{ flex: 1, backgroundColor: colors.background }}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <ScrollView
        contentContainerStyle={[styles.scroll, { paddingBottom: 40 }]}
        keyboardShouldPersistTaps="handled"
      >
        <View style={[styles.card, { backgroundColor: colors.card, borderColor: colors.border }]}>
          <Text style={[styles.heading, { color: colors.text }]}>Create your account</Text>

          <Input
            label="Username"
            icon="at-outline"
            placeholder="platruser"
            value={username}
            onChangeText={setUsername}
            autoCapitalize="none"
            autoCorrect={false}
            returnKeyType="next"
          />
          <Input
            label="Display Name (optional)"
            icon="person-outline"
            placeholder="John Smith"
            value={displayName}
            onChangeText={setDisplayName}
            containerStyle={{ marginTop: Spacing.md }}
            returnKeyType="next"
          />
          <Input
            label="Email"
            icon="mail-outline"
            placeholder="your@email.com"
            value={email}
            onChangeText={setEmail}
            keyboardType="email-address"
            autoCapitalize="none"
            autoCorrect={false}
            containerStyle={{ marginTop: Spacing.md }}
            returnKeyType="next"
          />
          <Input
            label="Password"
            icon="lock-closed-outline"
            placeholder="Min. 8 characters"
            value={password}
            onChangeText={setPassword}
            isPassword
            containerStyle={{ marginTop: Spacing.md }}
            returnKeyType="next"
          />
          <Input
            label="Confirm Password"
            icon="lock-closed-outline"
            placeholder="Repeat password"
            value={confirm}
            onChangeText={setConfirm}
            isPassword
            containerStyle={{ marginTop: Spacing.md }}
            returnKeyType="go"
            onSubmitEditing={handleRegister}
            error={confirm.length > 0 && confirm !== password ? 'Passwords do not match' : undefined}
          />

          {!!error && (
            <Text style={[styles.errorText, { color: colors.error }]}>{error}</Text>
          )}

          <Button
            title="Create Account"
            onPress={handleRegister}
            loading={loading}
            disabled={!valid}
            style={{ marginTop: Spacing.lg }}
            size="lg"
          />
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  scroll: {
    flexGrow: 1,
    paddingHorizontal: Spacing.lg,
    paddingTop: Spacing.xl,
    paddingBottom: 40,
  },
  card: {
    borderRadius: BorderRadius.xl,
    padding: Spacing.lg,
    borderWidth: 1,
    gap: 0,
  },
  heading: {
    fontSize: FontSizes.xl,
    fontWeight: '700',
    marginBottom: Spacing.lg,
  },
  errorText: {
    fontSize: FontSizes.sm,
    textAlign: 'center',
    marginTop: Spacing.sm,
  },
});
