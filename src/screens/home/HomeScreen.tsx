// Copyright (c) 2025 Sedat Aras — Platr. MIT License.
import React, { useCallback, useEffect, useState } from 'react';
import {
  View,
  Text,
  FlatList,
  TextInput,
  TouchableOpacity,
  ActivityIndicator,
  RefreshControl,
  StyleSheet,
  Pressable,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { StackNavigationProp } from '@react-navigation/stack';
import { Ionicons } from '@expo/vector-icons';
import { RootStackParamList } from '../../navigation/RootNavigator';
import { useTheme } from '../../hooks/useTheme';
import { BorderRadius, FontSizes, Spacing } from '../../constants/theme';
import { listPlatesApi, searchPlatesApi } from '../../services/api';
import { Plate } from '../../types';

type Nav = StackNavigationProp<RootStackParamList>;

function relativeTime(iso: string): string {
  const s = Math.floor((Date.now() - new Date(iso).getTime()) / 1000);
  if (s < 60)     return 'just now';
  if (s < 3600)   return `${Math.floor(s / 60)}m ago`;
  if (s < 86400)  return `${Math.floor(s / 3600)}h ago`;
  if (s < 604800) return `${Math.floor(s / 86400)}d ago`;
  return new Date(iso).toLocaleDateString();
}

export default function HomeScreen() {
  const { colors } = useTheme();
  const nav = useNavigation<Nav>();

  const [query, setQuery]               = useState('');
  const [feed, setFeed]                 = useState<Plate[]>([]);
  const [results, setResults]           = useState<Plate[]>([]);
  const [loadingFeed, setLoadingFeed]   = useState(false);
  const [loadingSearch, setLoadingSearch] = useState(false);
  const [refreshing, setRefreshing]     = useState(false);

  const isSearching = query.length >= 2;

  const loadFeed = useCallback(async () => {
    setLoadingFeed(true);
    try {
      const data = await listPlatesApi('VIC');
      setFeed(data);
    } catch { /* noop */ }
    finally { setLoadingFeed(false); }
  }, []);

  useEffect(() => { loadFeed(); }, []);

  useEffect(() => {
    if (query.length < 2) { setResults([]); return; }
    const t = setTimeout(async () => {
      setLoadingSearch(true);
      try {
        const data = await searchPlatesApi(query, 'VIC');
        setResults(data);
      } catch { /* noop */ }
      finally { setLoadingSearch(false); }
    }, 350);
    return () => clearTimeout(t);
  }, [query]);

  const onRefresh = async () => {
    setRefreshing(true);
    if (isSearching) {
      try { setResults(await searchPlatesApi(query, 'VIC')); } catch { /* noop */ }
    } else {
      await loadFeed();
    }
    setRefreshing(false);
  };

  // ── Feed row ───────────────────────────────────────────────────────────────

  const renderFeedRow = ({ item }: { item: Plate }) => (
    <TouchableOpacity
      style={[styles.feedRow, { backgroundColor: colors.card, borderColor: colors.border }]}
      onPress={() => nav.navigate('PlateDetail', { plateId: item.id })}
      activeOpacity={0.75}
    >
      <View style={styles.feedRowContent}>
        <View style={styles.feedRowLeft}>
          <View style={[styles.stateBadge, { backgroundColor: colors.primary + '20' }]}>
            <Text style={[styles.stateBadgeText, { color: colors.primary }]}>
              {item.state_code}
            </Text>
          </View>
          <Text style={[styles.feedPlateText, { color: colors.text }]}>
            {item.plate_text}
          </Text>
        </View>
        <Ionicons name="chevron-forward" size={14} color={colors.textSecondary} />
      </View>

      <Text style={[styles.feedMeta, { color: colors.textSecondary }]}>
        added by{' '}
        <Text style={{ color: colors.secondary, fontWeight: '700' }}>
          @{item.submitted_by_username ?? 'someone'}
        </Text>
        {'  '}·{'  '}
        {relativeTime(item.created_at)}
      </Text>
    </TouchableOpacity>
  );

  // ── Search row ─────────────────────────────────────────────────────────────

  const renderSearchRow = ({ item }: { item: Plate }) => {
    return (
      <TouchableOpacity
        style={[styles.searchRow, { backgroundColor: colors.card, borderColor: colors.border }]}
        onPress={() => nav.navigate('PlateDetail', { plateId: item.id })}
        activeOpacity={0.75}
      >
        <View style={styles.searchRowTop}>
          <View style={[styles.stateBadge, { backgroundColor: colors.primary + '20' }]}>
            <Text style={[styles.stateBadgeText, { color: colors.primary }]}>
              {item.state_code}
            </Text>
          </View>
          <Text style={[styles.searchPlateText, { color: colors.text }]}>
            {item.plate_text}
          </Text>
          <View style={{ flex: 1 }} />
        </View>

        <View style={styles.searchRowMeta}>
          {item.submitted_by_username && (
            <Text style={[styles.metaChip, { color: colors.secondary }]}>
              @{item.submitted_by_username}
            </Text>
          )}
          <Text style={[styles.metaChip, { color: colors.textSecondary }]}>
            <Ionicons name="star" size={11} /> {item.star_count} stars
          </Text>
        </View>
      </TouchableOpacity>
    );
  };

  // ── Empty states ───────────────────────────────────────────────────────────

  const EmptyFeed = () => (
    <View style={styles.emptyState}>
      <Ionicons name="car-outline" size={64} color={colors.border} />
      <Text style={[styles.emptyTitle, { color: colors.text }]}>No plates yet</Text>
      <Text style={[styles.emptySubtitle, { color: colors.textSecondary }]}>
        Be the first to add one!
      </Text>
      <TouchableOpacity
        style={[styles.addBtn, { backgroundColor: colors.primary }]}
        onPress={() => nav.navigate('AddPlate', {})}
      >
        <Text style={styles.addBtnText}>Add Plate</Text>
      </TouchableOpacity>
    </View>
  );

  const EmptySearch = () => (
    <View style={styles.emptyState}>
      <Ionicons name="search-outline" size={52} color={colors.border} />
      <Text style={[styles.emptyTitle, { color: colors.text }]}>
        No results for "{query}"
      </Text>
      <Text style={[styles.emptySubtitle, { color: colors.textSecondary }]}>
        This plate isn't in the database yet.
      </Text>
    </View>
  );

  const listData = isSearching ? results : feed;
  const isLoading = isSearching ? loadingSearch : (loadingFeed && feed.length === 0);

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      {/* Search bar */}
      <View style={[styles.searchBar, { backgroundColor: colors.surface, borderColor: colors.border }]}>
        <Ionicons name="search" size={16} color={colors.textSecondary} />
        <TextInput
          style={[styles.searchInput, { color: colors.text }]}
          placeholder="Search plates, e.g. ABC123"
          placeholderTextColor={colors.textSecondary}
          value={query}
          onChangeText={setQuery}
          autoCapitalize="characters"
          autoCorrect={false}
          returnKeyType="search"
        />
        {query.length > 0 && (
          <Pressable onPress={() => setQuery('')}>
            <Ionicons name="close-circle" size={16} color={colors.textSecondary} />
          </Pressable>
        )}
      </View>

      {isLoading ? (
        <ActivityIndicator
          style={{ flex: 1 }}
          color={colors.primary}
          size="large"
        />
      ) : (
        <FlatList
          data={listData}
          keyExtractor={(item) => item.id}
          renderItem={isSearching ? renderSearchRow : renderFeedRow}
          contentContainerStyle={[
            styles.list,
            listData.length === 0 && { flex: 1 },
          ]}
          ListEmptyComponent={isSearching ? <EmptySearch /> : <EmptyFeed />}
          refreshControl={
            <RefreshControl
              refreshing={refreshing}
              onRefresh={onRefresh}
              tintColor={colors.primary}
            />
          }
          ItemSeparatorComponent={() => <View style={{ height: Spacing.sm }} />}
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  searchBar: {
    flexDirection: 'row',
    alignItems: 'center',
    margin: Spacing.md,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm + 2,
    borderRadius: BorderRadius.full,
    borderWidth: 1,
    gap: Spacing.sm,
  },
  searchInput: { flex: 1, fontSize: FontSizes.md, paddingVertical: 0 },
  list: { paddingHorizontal: Spacing.md, paddingBottom: 120 },

  // Feed row
  feedRow: {
    padding: Spacing.md,
    borderRadius: BorderRadius.lg,
    borderWidth: 1,
    gap: 6,
  },
  feedRowContent: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  feedRowLeft: { flexDirection: 'row', alignItems: 'center', gap: Spacing.sm },
  feedPlateText: { fontSize: FontSizes.lg, fontWeight: '700', fontFamily: 'monospace' },
  feedMeta: { fontSize: FontSizes.xs },

  // Search row
  searchRow: {
    padding: Spacing.md,
    borderRadius: BorderRadius.lg,
    borderWidth: 1,
    gap: 6,
  },
  searchRowTop: { flexDirection: 'row', alignItems: 'center', gap: Spacing.sm },
  searchPlateText: { fontSize: FontSizes.lg, fontWeight: '700', fontFamily: 'monospace' },
  searchRowMeta: { flexDirection: 'row', gap: Spacing.md },
  metaChip: { fontSize: FontSizes.xs, fontWeight: '500' },

  // State badge
  stateBadge: {
    paddingHorizontal: 7,
    paddingVertical: 2,
    borderRadius: BorderRadius.sm,
  },
  stateBadgeText: { fontSize: FontSizes.xs, fontWeight: '700' },

  // Empty
  emptyState: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: Spacing.sm, paddingTop: 80 },
  emptyTitle: { fontSize: FontSizes.lg, fontWeight: '700' },
  emptySubtitle: { fontSize: FontSizes.sm, textAlign: 'center' },
  addBtn: {
    marginTop: Spacing.sm,
    paddingHorizontal: Spacing.xl,
    paddingVertical: Spacing.md - 2,
    borderRadius: BorderRadius.full,
  },
  addBtnText: { color: '#FFF', fontWeight: '700', fontSize: FontSizes.md },

});
