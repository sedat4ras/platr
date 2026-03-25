// Copyright (c) 2025 Sedat Aras — Platr. MIT License.
import React, { useState, useCallback } from 'react';
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  ActivityIndicator,
  StyleSheet,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { StackNavigationProp } from '@react-navigation/stack';
import { Ionicons } from '@expo/vector-icons';
import { useTheme } from '../../hooks/useTheme';
import { BorderRadius, FontSizes, Spacing } from '../../constants/theme';
import { searchPlatesApi } from '../../services/api';
import { Plate } from '../../types';
import PlateRenderer from '../../components/PlateRenderer';
import Input from '../../components/Input';
import { RootStackParamList } from '../../navigation/RootNavigator';

type Nav = StackNavigationProp<RootStackParamList>;

export default function SearchScreen() {
  const { colors } = useTheme();
  const nav = useNavigation<Nav>();

  const [query, setQuery]     = useState('');
  const [results, setResults] = useState<Plate[]>([]);
  const [loading, setLoading] = useState(false);
  const [searched, setSearched] = useState(false);

  const handleSearch = useCallback(async (text: string) => {
    setQuery(text);
    if (text.trim().length < 1) {
      setResults([]);
      setSearched(false);
      return;
    }
    setLoading(true);
    try {
      const res = await searchPlatesApi(text.trim());
      setResults(res);
      setSearched(true);
    } catch { /* noop */ }
    finally { setLoading(false); }
  }, []);

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      <View style={styles.searchBar}>
        <Input
          placeholder="Search plates e.g. ABC123"
          value={query}
          onChangeText={handleSearch}
          autoCapitalize="characters"
          autoCorrect={false}
          label=""
        />
      </View>

      {loading && (
        <ActivityIndicator color={colors.primary} style={{ marginTop: Spacing.lg }} />
      )}

      {!loading && searched && results.length === 0 && (
        <View style={styles.empty}>
          <Ionicons name="search" size={40} color={colors.textSecondary} />
          <Text style={[styles.emptyText, { color: colors.textSecondary }]}>
            No plates found for "{query}"
          </Text>
          <TouchableOpacity
            style={[styles.addBtn, { backgroundColor: colors.primary }]}
            onPress={() => nav.navigate('AddPlate', {})}
          >
            <Ionicons name="add" size={16} color="#FFF" />
            <Text style={styles.addBtnText}>Add this plate</Text>
          </TouchableOpacity>
        </View>
      )}

      <FlatList
        data={results}
        keyExtractor={(p) => p.id}
        contentContainerStyle={styles.list}
        renderItem={({ item }) => (
          <TouchableOpacity
            style={[styles.row, { backgroundColor: colors.card, borderColor: colors.border }]}
            onPress={() => nav.navigate('PlateDetail', { plateId: item.id })}
            activeOpacity={0.75}
          >
            <PlateRenderer
              plateText={item.plate_text}
              style={item.plate_style}
              customConfig={item.custom_config ? JSON.parse(item.custom_config as unknown as string) : null}
              width={140}
            />
            <View style={styles.rowInfo}>
              <Text style={[styles.plateText, { color: colors.text }]}>
                {item.state_code} · {item.plate_text}
              </Text>
              {item.vehicle.vehicle_make && (
                <Text style={[styles.vehicleText, { color: colors.textSecondary }]}>
                  {[item.vehicle.vehicle_year, item.vehicle.vehicle_make, item.vehicle.vehicle_model]
                    .filter(Boolean).join(' ')}
                </Text>
              )}
              <View style={styles.meta}>
                <Ionicons name="star" size={12} color={colors.textSecondary} />
                <Text style={[styles.metaText, { color: colors.textSecondary }]}>{item.star_count}</Text>
              </View>
            </View>
            <Ionicons name="chevron-forward" size={16} color={colors.textSecondary} />
          </TouchableOpacity>
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  searchBar: { padding: Spacing.md, paddingBottom: 0 },
  list: { padding: Spacing.md, gap: Spacing.sm },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.md,
    padding: Spacing.sm,
    borderRadius: BorderRadius.lg,
    borderWidth: 1,
  },
  rowInfo: { flex: 1, gap: 2 },
  plateText: { fontSize: FontSizes.md, fontWeight: '700' },
  vehicleText: { fontSize: FontSizes.xs },
  meta: { flexDirection: 'row', alignItems: 'center', gap: 3, marginTop: 2 },
  metaText: { fontSize: FontSizes.xs },
  empty: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: Spacing.md },
  emptyText: { fontSize: FontSizes.md, textAlign: 'center' },
  addBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.sm + 2,
    borderRadius: BorderRadius.full,
  },
  addBtnText: { color: '#FFF', fontWeight: '700', fontSize: FontSizes.sm },
});
