import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { StackNavigationProp } from '@react-navigation/stack';
import { useTheme } from '../../hooks/useTheme';
import { useAuthStore } from '../../store/authStore';
import { BorderRadius, FontSizes, Spacing } from '../../constants/theme';
import { updateProfileApi } from '../../services/api';
import { showToast } from '../../components/Toast';
import { RootStackParamList } from '../../navigation/RootNavigator';

type Nav = StackNavigationProp<RootStackParamList>;

export default function EditProfileScreen() {
  const { colors } = useTheme();
  const nav = useNavigation<Nav>();

  const currentUser = useAuthStore((s) => s.currentUser);
  const setUser = useAuthStore((s) => s.setUser);

  const [displayName, setDisplayName] = useState(currentUser?.display_name ?? '');
  const [bio, setBio] = useState(currentUser?.bio ?? '');
  const [saving, setSaving] = useState(false);

  const handleSave = async () => {
    setSaving(true);
    try {
      const updated = await updateProfileApi({
        display_name: displayName.trim() || undefined,
        bio: bio.trim() || undefined,
      });
      setUser(updated);
      showToast('Profile updated', 'success');
      nav.goBack();
    } catch (err: any) {
      const msg = err?.message ?? 'Failed to update profile';
      showToast(msg, 'error');
    } finally {
      setSaving(false);
    }
  };

  return (
    <KeyboardAvoidingView
      style={{ flex: 1, backgroundColor: colors.background }}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <ScrollView
        contentContainerStyle={[styles.container, { backgroundColor: colors.background }]}
        keyboardShouldPersistTaps="handled"
      >
        {/* Display Name */}
        <View style={styles.fieldGroup}>
          <Text style={[styles.label, { color: colors.textSecondary }]}>Display Name</Text>
          <TextInput
            style={[
              styles.input,
              {
                color: colors.text,
                backgroundColor: colors.inputBackground,
                borderColor: colors.border,
              },
            ]}
            value={displayName}
            onChangeText={setDisplayName}
            placeholder="Enter your display name"
            placeholderTextColor={colors.textSecondary}
            maxLength={40}
            autoCorrect={false}
            returnKeyType="next"
          />
          <Text style={[styles.charCount, { color: colors.textSecondary }]}>
            {displayName.length}/40
          </Text>
        </View>

        {/* Bio */}
        <View style={styles.fieldGroup}>
          <Text style={[styles.label, { color: colors.textSecondary }]}>Bio</Text>
          <TextInput
            style={[
              styles.input,
              styles.bioInput,
              {
                color: colors.text,
                backgroundColor: colors.inputBackground,
                borderColor: colors.border,
              },
            ]}
            value={bio}
            onChangeText={setBio}
            placeholder="Tell people about yourself…"
            placeholderTextColor={colors.textSecondary}
            maxLength={150}
            multiline
            textAlignVertical="top"
          />
          <Text style={[styles.charCount, { color: colors.textSecondary }]}>
            {bio.length}/150
          </Text>
        </View>

        {/* Save Button */}
        <TouchableOpacity
          style={[
            styles.saveBtn,
            { backgroundColor: saving ? colors.primary + '70' : colors.primary },
          ]}
          onPress={handleSave}
          disabled={saving}
          activeOpacity={0.85}
        >
          {saving ? (
            <ActivityIndicator color="#FFF" />
          ) : (
            <Text style={styles.saveBtnText}>Save Changes</Text>
          )}
        </TouchableOpacity>

        {/* Cancel */}
        <TouchableOpacity
          style={[styles.cancelBtn, { borderColor: colors.border }]}
          onPress={() => nav.goBack()}
          activeOpacity={0.75}
        >
          <Text style={[styles.cancelBtnText, { color: colors.textSecondary }]}>Cancel</Text>
        </TouchableOpacity>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    padding: Spacing.md,
    gap: Spacing.lg,
    paddingBottom: 40,
  },
  fieldGroup: {
    gap: Spacing.xs,
  },
  label: {
    fontSize: FontSizes.sm,
    fontWeight: '600',
    textTransform: 'uppercase',
    letterSpacing: 0.6,
  },
  input: {
    borderWidth: 1,
    borderRadius: BorderRadius.md,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm + 2,
    fontSize: FontSizes.md,
  },
  bioInput: {
    height: 100,
    paddingTop: Spacing.sm + 2,
  },
  charCount: {
    fontSize: FontSizes.xs,
    textAlign: 'right',
  },
  saveBtn: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: Spacing.md,
    borderRadius: BorderRadius.md,
    marginTop: Spacing.sm,
  },
  saveBtnText: {
    color: '#FFF',
    fontSize: FontSizes.md,
    fontWeight: '700',
  },
  cancelBtn: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: Spacing.md,
    borderRadius: BorderRadius.md,
    borderWidth: 1,
  },
  cancelBtnText: {
    fontSize: FontSizes.md,
    fontWeight: '600',
  },
});
