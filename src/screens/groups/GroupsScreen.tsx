import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useTheme } from '../../hooks/useTheme';
import { FontSizes, Spacing } from '../../constants/theme';

export default function GroupsScreen() {
  const { colors } = useTheme();

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      <Ionicons name="people" size={56} color={colors.textSecondary} />
      <Text style={[styles.title, { color: colors.text }]}>Groups</Text>
      <Text style={[styles.subtitle, { color: colors.textSecondary }]}>
        Car communities are coming soon.{'\n'}
        Connect with VIC plate owners, organise cruises, and more.
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: Spacing.md,
    padding: Spacing.xl,
  },
  title: { fontSize: FontSizes.xl, fontWeight: '700' },
  subtitle: { fontSize: FontSizes.md, textAlign: 'center', lineHeight: 22 },
});
