import React, { useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
  ActivityIndicator,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { StackNavigationProp } from '@react-navigation/stack';
import * as AppleAuthentication from 'expo-apple-authentication';
import * as WebBrowser from 'expo-web-browser';
import * as Google from 'expo-auth-session/providers/google';
import { Ionicons } from '@expo/vector-icons';
import { RootStackParamList } from '../../navigation/RootNavigator';
import { useTheme } from '../../hooks/useTheme';
import { useAuthStore } from '../../store/authStore';
import { loginApi, googleSignInApi, appleSignInApi, fetchMeApi } from '../../services/api';
import { BorderRadius, FontSizes, Spacing } from '../../constants/theme';
import Button from '../../components/Button';
import Input from '../../components/Input';

const GOOGLE_IOS_CLIENT_ID = process.env.EXPO_PUBLIC_GOOGLE_IOS_CLIENT_ID ?? '';
const GOOGLE_WEB_CLIENT_ID = process.env.EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID ?? '';

WebBrowser.maybeCompleteAuthSession();

type Nav = StackNavigationProp<RootStackParamList, 'Auth'>;

export default function LoginScreen() {
  const { colors } = useTheme();
  const nav = useNavigation<Nav>();
  const setAuth = useAuthStore((s) => s.setAuth);

  const [email, setEmail]       = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading]   = useState(false);
  const [socialLoading, setSocialLoading] = useState<'apple' | 'google' | null>(null);
  const [error, setError]       = useState('');

  // Expo Go → web client ID, production build → iOS client ID
  const [request, googleResponse, promptGoogleAsync] = Google.useAuthRequest({
    iosClientId: GOOGLE_IOS_CLIENT_ID,
    webClientId: GOOGLE_WEB_CLIENT_ID,
  });


  // Google response'u dinle
  React.useEffect(() => {
    if (googleResponse?.type === 'success') {
      const idToken = googleResponse.authentication?.idToken;
      if (idToken) {
        handleGoogleToken(idToken);
      } else {
        setError('Google sign-in failed: no id_token received.');
        setSocialLoading(null);
      }
    } else if (googleResponse?.type === 'error') {
      setError('Google sign-in failed. Please try again.');
      setSocialLoading(null);
    } else if (googleResponse?.type === 'dismiss') {
      setSocialLoading(null);
    }
  }, [googleResponse]);

  // ── Token'ı backend'e gönder ve giriş yap ──────────────────────────────────
  const finishSocialLogin = async (accessToken: string) => {
    // Token'ı store'a yaz, sonra /auth/me ile user bilgisini çek
    await setAuth(null, accessToken);
    try {
      const user = await fetchMeApi();
      useAuthStore.getState().setUser(user);
    } catch { /* user bilgisi arka planda çekilir */ }
  };

  // ── Google ─────────────────────────────────────────────────────────────────
  const handleGoogleSignIn = async () => {
    if (!GOOGLE_IOS_CLIENT_ID) {
      setError('Google Sign-In henüz yapılandırılmamış.');
      return;
    }
    setSocialLoading('google');
    setError('');
    await promptGoogleAsync();
    // Sonuç useEffect'te yakalanır
  };

  const handleGoogleToken = async (idToken: string) => {
    try {
      const { access_token } = await googleSignInApi(idToken);
      await finishSocialLogin(access_token);
    } catch (e: any) {
      setError(e.message || 'Google sign-in failed.');
    } finally {
      setSocialLoading(null);
    }
  };

  // ── Apple ──────────────────────────────────────────────────────────────────
  const handleAppleSignIn = async () => {
    setSocialLoading('apple');
    setError('');
    try {
      const credential = await AppleAuthentication.signInAsync({
        requestedScopes: [
          AppleAuthentication.AppleAuthenticationScope.FULL_NAME,
          AppleAuthentication.AppleAuthenticationScope.EMAIL,
        ],
      });

      if (!credential.identityToken) {
        throw new Error('Apple did not return an identity token.');
      }

      const fullName = [
        credential.fullName?.givenName,
        credential.fullName?.familyName,
      ]
        .filter(Boolean)
        .join(' ') || undefined;

      const { access_token } = await appleSignInApi(credential.identityToken, fullName);
      await finishSocialLogin(access_token);
    } catch (e: any) {
      if (e.code !== 'ERR_REQUEST_CANCELED') {
        setError(e.message || 'Apple sign-in failed.');
      }
    } finally {
      setSocialLoading(null);
    }
  };

  // ── Email / Password ───────────────────────────────────────────────────────
  const handleLogin = async () => {
    if (!email.trim() || !password) return;
    setLoading(true);
    setError('');
    try {
      const { access_token } = await loginApi(email.trim(), password);
      await finishSocialLogin(access_token);
    } catch (e: any) {
      setError(e.message || 'Login failed. Please check your credentials.');
    } finally {
      setLoading(false);
    }
  };

  const isAppleAvailable = Platform.OS === 'ios';
  const anyLoading = loading || !!socialLoading;

  return (
    <KeyboardAvoidingView
      style={{ flex: 1, backgroundColor: colors.background }}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <ScrollView
        contentContainerStyle={styles.scroll}
        keyboardShouldPersistTaps="handled"
      >
        {/* Header */}
        <View style={styles.header}>
          <Text style={[styles.appName, { color: colors.text }]}>Platr</Text>
          <Text style={[styles.tagline, { color: colors.textSecondary }]}>
            Spot & share number plates
          </Text>
        </View>

        {/* Social buttons */}
        <View style={styles.socialGroup}>
          {/* Google */}
          <TouchableOpacity
            style={[styles.socialBtn, { backgroundColor: colors.card, borderColor: colors.border }]}
            onPress={handleGoogleSignIn}
            disabled={anyLoading}
            activeOpacity={0.75}
          >
            {socialLoading === 'google' ? (
              <ActivityIndicator size="small" color={colors.text} />
            ) : (
              <GoogleLogo />
            )}
            <Text style={[styles.socialBtnText, { color: colors.text }]}>
              Continue with Google
            </Text>
          </TouchableOpacity>

          {/* Apple — iOS only */}
          {isAppleAvailable && (
            <TouchableOpacity
              style={[styles.socialBtn, { backgroundColor: colors.text, borderColor: colors.text }]}
              onPress={handleAppleSignIn}
              disabled={anyLoading}
              activeOpacity={0.75}
            >
              {socialLoading === 'apple' ? (
                <ActivityIndicator size="small" color={colors.background} />
              ) : (
                <Ionicons name="logo-apple" size={20} color={colors.background} />
              )}
              <Text style={[styles.socialBtnText, { color: colors.background }]}>
                Continue with Apple
              </Text>
            </TouchableOpacity>
          )}
        </View>

        {/* Divider */}
        <View style={styles.divider}>
          <View style={[styles.dividerLine, { backgroundColor: colors.border }]} />
          <Text style={[styles.dividerText, { color: colors.textSecondary }]}>or</Text>
          <View style={[styles.dividerLine, { backgroundColor: colors.border }]} />
        </View>

        {/* Email / Password form */}
        <View style={[styles.card, { backgroundColor: colors.card, borderColor: colors.border }]}>
          <Input
            label="Email"
            icon="mail-outline"
            placeholder="your@email.com"
            value={email}
            onChangeText={setEmail}
            keyboardType="email-address"
            autoCapitalize="none"
            autoCorrect={false}
            returnKeyType="next"
            editable={!anyLoading}
          />
          <Input
            label="Password"
            icon="lock-closed-outline"
            placeholder="Password"
            value={password}
            onChangeText={setPassword}
            isPassword
            returnKeyType="go"
            onSubmitEditing={handleLogin}
            containerStyle={{ marginTop: Spacing.md }}
            editable={!anyLoading}
          />

          {!!error && (
            <Text style={[styles.errorText, { color: colors.error }]}>{error}</Text>
          )}

          <Button
            title="Sign In"
            onPress={handleLogin}
            loading={loading}
            disabled={!email.trim() || !password || !!socialLoading}
            style={{ marginTop: Spacing.lg }}
            size="lg"
          />
        </View>

        {/* Register link */}
        <TouchableOpacity
          onPress={() => nav.navigate('Register')}
          activeOpacity={0.7}
          disabled={anyLoading}
        >
          <Text style={[styles.registerText, { color: colors.textSecondary }]}>
            Don't have an account?{' '}
            <Text style={{ color: colors.primary, fontWeight: '700' }}>Sign Up</Text>
          </Text>
        </TouchableOpacity>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

function GoogleLogo() {
  return (
    <View style={styles.googleG}>
      <Text style={styles.googleGText}>G</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  scroll: {
    flexGrow: 1,
    paddingHorizontal: Spacing.lg,
    paddingTop: Spacing.xxl + Spacing.lg,
    paddingBottom: 40,
    gap: Spacing.lg,
  },
  header: { alignItems: 'center', gap: Spacing.xs },
  appName: { fontSize: FontSizes.title + 6, fontWeight: '900', letterSpacing: -1 },
  tagline:  { fontSize: FontSizes.md },
  socialGroup: { gap: Spacing.sm },
  socialBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: Spacing.sm,
    paddingVertical: Spacing.md,
    borderRadius: BorderRadius.md,
    borderWidth: 1.5,
  },
  socialBtnText: { fontSize: FontSizes.md, fontWeight: '600' },
  googleG: {
    width: 22,
    height: 22,
    borderRadius: 11,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#fff',
  },
  googleGText: { fontSize: 14, fontWeight: '900', color: '#4285F4' },
  divider: { flexDirection: 'row', alignItems: 'center', gap: Spacing.sm },
  dividerLine: { flex: 1, height: 1 },
  dividerText: { fontSize: FontSizes.sm },
  card: { borderRadius: BorderRadius.xl, padding: Spacing.lg, borderWidth: 1 },
  errorText: { fontSize: FontSizes.sm, textAlign: 'center', marginTop: Spacing.sm },
  registerText: { textAlign: 'center', fontSize: FontSizes.sm },
});
