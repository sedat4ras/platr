import React, { useCallback, useEffect, useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  RefreshControl,
  Alert,
  ActivityIndicator,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { StackNavigationProp } from '@react-navigation/stack';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { RootStackParamList } from '../../navigation/RootNavigator';
import { useTheme } from '../../hooks/useTheme';
import { useAuthStore } from '../../store/authStore';
import { useThemeStore } from '../../store/themeStore';
import { BorderRadius, FontSizes, Spacing } from '../../constants/theme';
import { listMyPlatesApi, fetchMeApi, deleteAccountApi } from '../../services/api';
import { Plate, regoStatusDisplay } from '../../types';
import PlateRenderer from '../../components/PlateRenderer';
import { showToast } from '../../components/Toast';

type Nav = StackNavigationProp<RootStackParamList>;

export default function ProfileScreen() {
  const { colors, isDarkMode } = useTheme();
  const toggleTheme = useThemeStore((s) => s.toggleTheme);
  const nav = useNavigation<Nav>();
  const insets = useSafeAreaInsets();

  const currentUser = useAuthStore((s) => s.currentUser);
  const logout      = useAuthStore((s) => s.logout);
  const setUser     = useAuthStore((s) => s.setUser);

  const [plates, setPlates]     = useState<Plate[]>([]);
  const [loading, setLoading]   = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const displayName = currentUser?.display_name || currentUser?.username || 'Platr User';
  const username    = currentUser?.username ?? '';
  const initials    = displayName.slice(0, 1).toUpperCase();
  const totalSpots  = plates.reduce((s, p) => s + p.star_count, 0);
  const totalViews  = plates.reduce((s, p) => s + p.view_count, 0);

  const load = useCallback(async () => {
    try {
      const [myPlates, me] = await Promise.all([listMyPlatesApi(), fetchMeApi()]);
      setPlates(myPlates);
      setUser(me);
    } catch { /* noop */ }
    finally { setLoading(false); setRefreshing(false); }
  }, []);

  useEffect(() => { load(); }, []);

  const onRefresh = () => { setRefreshing(true); load(); };

  const handleLogout = () => {
    Alert.alert('Sign Out', 'Are you sure you want to sign out?', [
      { text: 'Sign Out', style: 'destructive', onPress: logout },
      { text: 'Cancel', style: 'cancel' },
    ]);
  };

  const handleDeleteAccount = () => {
    Alert.alert(
      'Delete Account',
      'This will permanently delete your account and all your data. This cannot be undone.',
      [
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            try {
              await deleteAccountApi();
              showToast('Account deleted', 'info');
              logout();
            } catch {
              showToast('Failed to delete account. Please try again.', 'error');
            }
          },
        },
        { text: 'Cancel', style: 'cancel' },
      ]
    );
  };

  return (
    <ScrollView
      style={{ backgroundColor: colors.background }}
      refreshControl={
        <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={colors.primary} />
      }
      showsVerticalScrollIndicator={false}
    >
      {/* Hero */}
      <LinearGradient
        colors={[colors.primary, colors.primary + '99', colors.background]}
        style={[styles.hero, { paddingTop: insets.top + Spacing.lg }]}
      >
        {/* Avatar */}
        <View style={styles.avatarRing}>
          <View style={[styles.avatar, { backgroundColor: colors.primary + '40' }]}>
            <Text style={styles.avatarInitial}>{initials}</Text>
          </View>
        </View>

        {/* Name row with edit button */}
        <View style={styles.nameRow}>
          <Text style={styles.displayName}>{displayName}</Text>
          {currentUser?.is_verified && (
            <Ionicons name="checkmark-circle" size={20} color="#FFF" />
          )}
          <TouchableOpacity
            onPress={() => nav.navigate('EditProfile')}
            hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
            style={styles.editIconBtn}
          >
            <Ionicons name="pencil-outline" size={18} color="rgba(255,255,255,0.85)" />
          </TouchableOpacity>
        </View>
        {username && (
          <Text style={styles.username}>@{username}</Text>
        )}
      </LinearGradient>

      {/* Stats */}
      <View style={[styles.statsCard, { backgroundColor: colors.surface, borderColor: colors.border }]}>
        <StatCell value={plates.length} label="Plates" colors={colors} />
        <View style={[styles.statDivider, { backgroundColor: colors.border }]} />
        <StatCell value={totalSpots} label="Spots" colors={colors} />
        <View style={[styles.statDivider, { backgroundColor: colors.border }]} />
        <StatCell value={totalViews} label="Views" colors={colors} />
      </View>

      {/* My plates */}
      <View style={styles.section}>
        <Text style={[styles.sectionTitle, { color: colors.textSecondary }]}>
          MY PLATES {plates.length > 0 ? `(${plates.length})` : ''}
        </Text>

        {loading ? (
          <ActivityIndicator color={colors.primary} style={{ marginVertical: Spacing.xl }} />
        ) : plates.length === 0 ? (
          <View style={styles.emptyPlates}>
            <Ionicons name="car-outline" size={44} color={colors.border} />
            <Text style={[styles.emptyTitle, { color: colors.text }]}>No plates yet</Text>
            <Text style={[styles.emptySubtitle, { color: colors.textSecondary }]}>
              Plates you add will appear here.
            </Text>
          </View>
        ) : (
          plates.map((plate) => (
            <TouchableOpacity
              key={plate.id}
              style={[styles.plateCard, { backgroundColor: colors.card, borderColor: colors.border }]}
              onPress={() => nav.navigate('PlateDetail', { plateId: plate.id })}
              activeOpacity={0.75}
            >
              <PlateRenderer
                plateText={plate.plate_text}
                style={plate.plate_style}
                customConfig={plate.custom_config ? JSON.parse(plate.custom_config as unknown as string) : null}
                width={130}
              />
              <View style={styles.plateInfo}>
                <Text style={[styles.plateCardText, { color: colors.text }]}>
                  {plate.plate_text}
                </Text>
                <RegoBadge plate={plate} colors={colors} />
                <View style={styles.plateCardMeta}>
                  <Ionicons
                    name={plate.is_comments_open ? 'chatbubble' : 'lock-closed'}
                    size={11}
                    color={plate.is_comments_open ? colors.success : colors.textSecondary}
                  />
                  <Text
                    style={[
                      styles.plateCardMetaText,
                      { color: plate.is_comments_open ? colors.success : colors.textSecondary },
                    ]}
                  >
                    {plate.is_comments_open ? 'Open' : 'Closed'}
                  </Text>
                </View>
              </View>
              <Ionicons name="chevron-forward" size={14} color={colors.textSecondary} />
            </TouchableOpacity>
          ))
        )}
      </View>

      {/* Account */}
      <View style={styles.section}>
        <Text style={[styles.sectionTitle, { color: colors.textSecondary }]}>ACCOUNT</Text>

        {/* Edit Profile */}
        <TouchableOpacity
          style={[styles.settingRow, { backgroundColor: colors.card, borderColor: colors.border }]}
          onPress={() => nav.navigate('EditProfile')}
          activeOpacity={0.75}
        >
          <View style={styles.settingLeft}>
            <Ionicons name="person-outline" size={18} color={colors.primary} />
            <Text style={[styles.settingLabel, { color: colors.text }]}>Edit Profile</Text>
          </View>
          <Ionicons name="chevron-forward" size={16} color={colors.textSecondary} />
        </TouchableOpacity>

        {/* Legal & Privacy */}
        <TouchableOpacity
          style={[styles.settingRow, { backgroundColor: colors.card, borderColor: colors.border }]}
          onPress={() => nav.navigate('Legal')}
          activeOpacity={0.75}
        >
          <View style={styles.settingLeft}>
            <Ionicons name="shield-outline" size={18} color={colors.textSecondary} />
            <Text style={[styles.settingLabel, { color: colors.text }]}>Legal & Privacy</Text>
          </View>
          <Ionicons name="chevron-forward" size={16} color={colors.textSecondary} />
        </TouchableOpacity>

        {/* Dark mode toggle */}
        <TouchableOpacity
          style={[styles.settingRow, { backgroundColor: colors.card, borderColor: colors.border }]}
          onPress={toggleTheme}
          activeOpacity={0.75}
        >
          <View style={styles.settingLeft}>
            <Ionicons
              name={isDarkMode ? 'moon' : 'sunny'}
              size={18}
              color={colors.primary}
            />
            <Text style={[styles.settingLabel, { color: colors.text }]}>
              {isDarkMode ? 'Dark Mode' : 'Light Mode'}
            </Text>
          </View>
          <Ionicons name="chevron-forward" size={16} color={colors.textSecondary} />
        </TouchableOpacity>

        {/* Sign out */}
        <TouchableOpacity
          style={[styles.settingRow, { backgroundColor: colors.card, borderColor: colors.border }]}
          onPress={handleLogout}
          activeOpacity={0.75}
        >
          <View style={styles.settingLeft}>
            <Ionicons name="log-out-outline" size={18} color={colors.error} />
            <Text style={[styles.settingLabel, { color: colors.error }]}>Sign Out</Text>
          </View>
        </TouchableOpacity>

        {/* Delete Account */}
        <TouchableOpacity
          style={[styles.settingRow, { backgroundColor: colors.card, borderColor: colors.border }]}
          onPress={handleDeleteAccount}
          activeOpacity={0.75}
        >
          <View style={styles.settingLeft}>
            <Ionicons name="trash-outline" size={18} color={colors.error} />
            <Text style={[styles.settingLabel, { color: colors.error }]}>Delete Account</Text>
          </View>
        </TouchableOpacity>
      </View>

      <View style={{ height: 40 }} />
    </ScrollView>
  );
}

function StatCell({ value, label, colors }: { value: number; label: string; colors: any }) {
  return (
    <View style={styles.statCell}>
      <Text style={[styles.statValue, { color: colors.text }]}>{value}</Text>
      <Text style={[styles.statLabel, { color: colors.textSecondary }]}>{label}</Text>
    </View>
  );
}

function RegoBadge({ plate, colors }: { plate: Plate; colors: any }) {
  const { label, colorKey } = regoStatusDisplay(plate.vehicle.rego_status);
  const regoColor = colors[colorKey];
  return (
    <View style={[styles.regoBadge, { backgroundColor: regoColor + '20' }]}>
      <View style={[styles.regoDot, { backgroundColor: regoColor }]} />
      <Text style={[styles.regoLabel, { color: regoColor }]}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  hero: {
    alignItems: 'center',
    paddingBottom: Spacing.xl,
    gap: Spacing.sm,
  },
  avatarRing: {
    width: 96,
    height: 96,
    borderRadius: 48,
    borderWidth: 2.5,
    borderColor: 'rgba(255,255,255,0.4)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatar: {
    width: 84,
    height: 84,
    borderRadius: 42,
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatarInitial: { fontSize: 36, fontWeight: '700', color: '#FFF' },
  nameRow: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  displayName: { fontSize: FontSizes.xl, fontWeight: '700', color: '#FFF' },
  username: { fontSize: FontSizes.sm, color: 'rgba(255,255,255,0.7)' },
  editIconBtn: {
    padding: 2,
  },

  statsCard: {
    flexDirection: 'row',
    marginHorizontal: Spacing.md,
    marginTop: -Spacing.md,
    borderRadius: BorderRadius.lg,
    borderWidth: 1,
    paddingVertical: Spacing.md,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.08,
    shadowRadius: 6,
    elevation: 3,
  },
  statCell: { flex: 1, alignItems: 'center', gap: 2 },
  statValue: { fontSize: FontSizes.lg, fontWeight: '700' },
  statLabel: { fontSize: FontSizes.xs },
  statDivider: { width: 1, marginVertical: 4 },

  section: { paddingHorizontal: Spacing.md, paddingTop: Spacing.lg, gap: Spacing.sm },
  sectionTitle: { fontSize: FontSizes.xs, fontWeight: '700', letterSpacing: 0.8 },

  plateCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: Spacing.md,
    borderRadius: BorderRadius.lg,
    borderWidth: 1,
    gap: Spacing.md,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  plateInfo: { flex: 1, gap: 5 },
  plateCardText: { fontSize: FontSizes.md, fontWeight: '700' },
  plateCardMeta: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  plateCardMetaText: { fontSize: FontSizes.xs, fontWeight: '500' },

  regoBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: BorderRadius.full,
    alignSelf: 'flex-start',
  },
  regoDot: { width: 6, height: 6, borderRadius: 3 },
  regoLabel: { fontSize: FontSizes.xs, fontWeight: '700' },

  emptyPlates: { alignItems: 'center', gap: Spacing.sm, paddingVertical: Spacing.xl },
  emptyTitle: { fontSize: FontSizes.md, fontWeight: '700' },
  emptySubtitle: { fontSize: FontSizes.sm, textAlign: 'center' },

  settingRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: Spacing.md,
    borderRadius: BorderRadius.lg,
    borderWidth: 1,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.04,
    shadowRadius: 3,
    elevation: 1,
  },
  settingLeft: { flexDirection: 'row', alignItems: 'center', gap: Spacing.sm },
  settingLabel: { fontSize: FontSizes.md },
});
