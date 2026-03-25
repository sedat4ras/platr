import React, { useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  ActivityIndicator,
  StyleSheet,
  Alert,
  Modal,
  FlatList,
  TextInput,
  Image,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { StackNavigationProp } from '@react-navigation/stack';
import { Ionicons } from '@expo/vector-icons';
import * as ImagePicker from 'expo-image-picker';
import { RootStackParamList } from '../../navigation/RootNavigator';
import { useTheme } from '../../hooks/useTheme';
import { BorderRadius, FontSizes, Spacing } from '../../constants/theme';
import { createPlateApi, uploadPlatePhotoApi, DuplicatePlateError } from '../../services/api';
import {
  PlateStyle, CustomPlateConfig, DEFAULT_CUSTOM_CONFIG,
  VicBadgeStyle, StateTextOption, SeparatorStyle, BorderStyleOption,
  PLATE_STYLE_META,
} from '../../types';
import PlateRenderer from '../../components/PlateRenderer';
import PlateCropModal from '../../components/PlateCropModal';
import Button from '../../components/Button';
import Input from '../../components/Input';

const ALLOWED = /^[A-Z0-9]$/;
const STYLES: PlateStyle[] = ['VIC_STANDARD', 'VIC_BLACK', 'VIC_CUSTOM'];

const BG_COLORS = ['#1A1A1A', '#141414', '#FFFFFF', '#F5F5EE', '#0D1530', '#1A0000', '#001A1A', '#1A001A'];
const TEXT_COLORS = ['#FFFFFF', '#CCCCCC', '#111111', '#002E8F', '#D9B24C', '#2D5A27', '#801020', '#E6C160'];

// Fixed preview config for the style picker modal (not user's current config)
const PICKER_PREVIEW_CONFIG: CustomPlateConfig = {
  bgColor: '#1A1A1A',
  textColor: '#FFD700',
  borderStyle: 'flat',
  borderColor: '#555555',
  vicBadge: 'none',
  stateText: 'none',
  stateTextPosition: 'bottom',
  separator: '',
};

const PRESET_SEPARATORS = ['', ' ', '·', '◆', '-'];
const PRESET_SEP_LABELS: Record<string, string> = {
  '': 'None',
  ' ': 'Space',
  '·': '·  Dot',
  '◆': '◆  Diamond',
  '-': '–  Dash',
};

type Nav = StackNavigationProp<RootStackParamList>;

export default function AddPlateScreen() {
  const { colors } = useTheme();
  const nav = useNavigation<Nav>();

  const [plateText, setPlateText] = useState('');
  const [plateStyle, setPlateStyle] = useState<PlateStyle>('VIC_STANDARD');
  const [customCfg, setCustomCfg] = useState<CustomPlateConfig>({ ...DEFAULT_CUSTOM_CONFIG });
  const [loading, setLoading] = useState(false);
  const [showStylePicker, setShowStylePicker] = useState(false);

  // Photo mode
  const [photoMode, setPhotoMode] = useState(false);
  const [photoUri, setPhotoUri] = useState<string | null>(null);
  const [photoDims, setPhotoDims] = useState<{ width: number; height: number } | null>(null);
  // Raw picked photo waiting to be cropped
  const [rawPhotoUri, setRawPhotoUri] = useState<string | null>(null);
  const [rawPhotoDims, setRawPhotoDims] = useState<{ width: number; height: number } | null>(null);
  const [showCropModal, setShowCropModal] = useState(false);

  // Custom separator text input value (only shows when not a preset)
  const isPresetSep = PRESET_SEPARATORS.includes(customCfg.separator);
  const customSepInputValue = isPresetSep ? '' : customCfg.separator;

  const meta = PLATE_STYLE_META[plateStyle];

  const handleTextChange = (raw: string) => {
    const filtered = raw
      .toUpperCase()
      .split('')
      .filter((c) => ALLOWED.test(c))
      .join('')
      .slice(0, meta.maxChars);
    setPlateText(filtered);
  };

  const setCfg = (partial: Partial<CustomPlateConfig>) =>
    setCustomCfg((prev) => ({ ...prev, ...partial }));

  const pickPhoto = async (fromCamera: boolean) => {
    const { status } = fromCamera
      ? await ImagePicker.requestCameraPermissionsAsync()
      : await ImagePicker.requestMediaLibraryPermissionsAsync();

    if (status !== 'granted') {
      Alert.alert('Permission needed', fromCamera ? 'Camera access is required.' : 'Photo library access is required.');
      return;
    }

    // Pick without any editing — we handle crop ourselves
    const result = fromCamera
      ? await ImagePicker.launchCameraAsync({ allowsEditing: false, quality: 0.92 })
      : await ImagePicker.launchImageLibraryAsync({ allowsEditing: false, quality: 0.92 });

    if (!result.canceled && result.assets[0]) {
      const asset = result.assets[0];
      setRawPhotoUri(asset.uri);
      setRawPhotoDims(
        asset.width && asset.height
          ? { width: asset.width, height: asset.height }
          : null
      );
      setShowCropModal(true);
    }
  };

  const showPhotoPicker = () => {
    Alert.alert('Add Photo', 'Choose source', [
      { text: 'Take Photo', onPress: () => pickPhoto(true) },
      { text: 'Choose from Library', onPress: () => pickPhoto(false) },
      { text: 'Cancel', style: 'cancel' },
    ]);
  };

  const handleSubmit = async () => {
    if (!plateText.trim()) return;
    setLoading(true);
    try {
      const plate = await createPlateApi({
        plate_text: plateText,
        plate_style: plateStyle,
        custom_config: plateStyle === 'VIC_CUSTOM' ? customCfg : null,
      });

      if (photoUri) {
        try {
          await uploadPlatePhotoApi(plate.id, photoUri);
        } catch {
          // Photo upload failure is non-blocking
        }
      }

      nav.goBack();
      nav.navigate('PlateDetail', { plateId: plate.id });
    } catch (e) {
      if (e instanceof DuplicatePlateError) {
        Alert.alert(
          'Plate Already Exists',
          `${e.stateCode} · ${e.plateText} is already in the database. View it?`,
          [
            { text: 'View Plate', onPress: () => { nav.goBack(); nav.navigate('PlateDetail', { plateId: e.existingPlateId }); } },
            { text: 'Cancel', style: 'cancel' },
          ]
        );
      } else {
        Alert.alert('Error', (e as Error).message);
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <ScrollView
      style={{ backgroundColor: colors.background }}
      contentContainerStyle={styles.scroll}
      keyboardShouldPersistTaps="handled"
    >
      {/* Mode toggle */}
      <View style={[styles.modeToggle, { backgroundColor: colors.card, borderColor: colors.border }]}>
        <TouchableOpacity
          style={[styles.modeBtn, !photoMode && { backgroundColor: colors.primary }]}
          onPress={() => setPhotoMode(false)}
        >
          <Ionicons name="color-palette-outline" size={14} color={!photoMode ? '#FFF' : colors.textSecondary} />
          <Text style={[styles.modeBtnText, { color: !photoMode ? '#FFF' : colors.textSecondary }]}>Visual</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.modeBtn, photoMode && { backgroundColor: colors.primary }]}
          onPress={() => setPhotoMode(true)}
        >
          <Ionicons name="camera-outline" size={14} color={photoMode ? '#FFF' : colors.textSecondary} />
          <Text style={[styles.modeBtnText, { color: photoMode ? '#FFF' : colors.textSecondary }]}>Photo</Text>
        </TouchableOpacity>
      </View>

      {/* Preview */}
      <View style={styles.preview}>
        {photoMode ? (
          <TouchableOpacity
            style={[styles.photoPlaceholder, { borderColor: colors.border, backgroundColor: colors.card }]}
            onPress={showPhotoPicker}
            activeOpacity={0.75}
          >
            {photoUri ? (
              <Image
                source={{ uri: photoUri }}
                style={[styles.photoPreview, photoDims ? { width: photoDims.width, height: photoDims.height } : {}]}
                resizeMode="contain"
              />
            ) : (
              <>
                <Ionicons name="camera" size={36} color={colors.textSecondary} />
                <Text style={[styles.photoHint, { color: colors.textSecondary }]}>
                  Take your plate's photo
                </Text>
                <Text style={[styles.photoSubHint, { color: colors.textSecondary }]}>
                  or upload it instead of using the visualised version
                </Text>
              </>
            )}
          </TouchableOpacity>
        ) : (
          <PlateRenderer
            plateText={plateText || 'PLATR'}
            style={plateStyle}
            customConfig={plateStyle === 'VIC_CUSTOM' ? customCfg : null}
            width={300}
          />
        )}
        {photoMode && photoUri && (
          <TouchableOpacity style={styles.changePhoto} onPress={showPhotoPicker}>
            <Text style={[styles.changePhotoText, { color: colors.primary }]}>Change photo</Text>
          </TouchableOpacity>
        )}
      </View>

      {/* Plate text */}
      <View style={[styles.card, { backgroundColor: colors.card, borderColor: colors.border }]}>
        <Text style={[styles.label, { color: colors.textSecondary }]}>PLATE NUMBER</Text>
        <Input
          label=""
          placeholder={meta.formatHint}
          value={plateText}
          onChangeText={handleTextChange}
          autoCapitalize="characters"
          autoCorrect={false}
          maxLength={meta.maxChars}
        />
        <Text style={[styles.hint, { color: colors.textSecondary }]}>
          {plateText.length}/{meta.maxChars} · Victoria plates only
        </Text>
      </View>

      {/* Style picker (hidden in photo mode) */}
      {!photoMode && (
        <TouchableOpacity
          style={[styles.card, styles.row, { backgroundColor: colors.card, borderColor: colors.border }]}
          onPress={() => setShowStylePicker(true)}
          activeOpacity={0.75}
        >
          <View>
            <Text style={[styles.label, { color: colors.textSecondary }]}>PLATE STYLE</Text>
            <Text style={[styles.value, { color: colors.text }]}>{meta.displayName}</Text>
          </View>
          <Ionicons name="chevron-forward" size={18} color={colors.textSecondary} />
        </TouchableOpacity>
      )}

      {/* Custom config panel — only when VIC_CUSTOM selected & not photo mode */}
      {!photoMode && plateStyle === 'VIC_CUSTOM' && (
        <View style={[styles.card, { backgroundColor: colors.card, borderColor: colors.border, gap: Spacing.md }]}>
          <Text style={[styles.label, { color: colors.textSecondary }]}>CUSTOM OPTIONS</Text>

          <ConfigSection label="Background" colors={colors}>
            <ColorRow colors={BG_COLORS} selected={customCfg.bgColor} onSelect={(c) => setCfg({ bgColor: c })} />
          </ConfigSection>

          <ConfigSection label="Text color" colors={colors}>
            <ColorRow colors={TEXT_COLORS} selected={customCfg.textColor} onSelect={(c) => setCfg({ textColor: c })} />
          </ConfigSection>

          <ConfigSection label="Border" colors={colors}>
            <ChipRow
              options={[
                { key: 'none', label: 'None' },
                { key: 'chrome', label: 'Chrome' },
                { key: 'flat', label: 'Flat' },
              ]}
              selected={customCfg.borderStyle}
              onSelect={(v) => setCfg({ borderStyle: v as BorderStyleOption })}
              colors={colors}
            />
            {customCfg.borderStyle === 'flat' && (
              <ColorRow colors={TEXT_COLORS} selected={customCfg.borderColor} onSelect={(c) => setCfg({ borderColor: c })} />
            )}
          </ConfigSection>

          <ConfigSection label="VIC Badge" colors={colors}>
            <ChipRow
              options={[
                { key: 'none', label: 'None' },
                { key: 'triangle_top', label: 'Triangle' },
                { key: 'vertical_left', label: 'Vertical' },
                { key: 'box_topleft', label: 'Box' },
              ]}
              selected={customCfg.vicBadge}
              onSelect={(v) => setCfg({ vicBadge: v as VicBadgeStyle })}
              colors={colors}
            />
          </ConfigSection>

          <ConfigSection label="State text" colors={colors}>
            <ChipRow
              options={[
                { key: 'none', label: 'None' },
                { key: 'victoria', label: 'Victoria' },
                { key: 'education_state', label: 'Edu. State' },
                { key: 'garden_state', label: 'Garden St.' },
              ]}
              selected={customCfg.stateText}
              onSelect={(v) => setCfg({ stateText: v as StateTextOption })}
              colors={colors}
            />
            {customCfg.stateText !== 'none' && (
              <ChipRow
                options={[
                  { key: 'bottom', label: 'Bottom' },
                  { key: 'top', label: 'Top' },
                ]}
                selected={customCfg.stateTextPosition}
                onSelect={(v) => setCfg({ stateTextPosition: v as 'top' | 'bottom' })}
                colors={colors}
              />
            )}
          </ConfigSection>

          {/* Separator */}
          <ConfigSection label="Separator" colors={colors}>
            <ChipRow
              options={PRESET_SEPARATORS.map((s) => ({ key: s, label: PRESET_SEP_LABELS[s] }))}
              selected={isPresetSep ? customCfg.separator : '__custom__'}
              onSelect={(v) => setCfg({ separator: v as SeparatorStyle })}
              colors={colors}
            />
            {/* Custom char input */}
            <View style={[sepStyles.row, { borderColor: colors.border }]}>
              <Text style={[sepStyles.label, { color: colors.textSecondary }]}>Custom:</Text>
              <TextInput
                style={[sepStyles.input, {
                  color: colors.text,
                  borderColor: !isPresetSep ? colors.primary : colors.border,
                  backgroundColor: colors.inputBackground,
                }]}
                value={customSepInputValue}
                onChangeText={(v) => {
                  const char = v.slice(-1); // allow only 1 char
                  setCfg({ separator: char });
                }}
                maxLength={1}
                placeholder="e.g. /"
                placeholderTextColor={colors.textSecondary}
              />
            </View>
          </ConfigSection>
        </View>
      )}

      <Button
        title="Add Plate"
        onPress={handleSubmit}
        loading={loading}
        disabled={plateText.length < 1 || (photoMode && !photoUri)}
        size="lg"
        style={{ marginHorizontal: Spacing.md }}
      />

      {/* Crop modal */}
      <PlateCropModal
        visible={showCropModal}
        imageUri={rawPhotoUri}
        imageDims={rawPhotoDims}
        onCrop={(uri, dims) => {
          setShowCropModal(false);
          setPhotoUri(uri);
          const scale = 300 / dims.width;
          setPhotoDims({ width: 300, height: Math.round(dims.height * scale) });
        }}
        onCancel={() => setShowCropModal(false)}
      />

      {/* Style picker modal */}
      <Modal visible={showStylePicker} animationType="slide" presentationStyle="pageSheet">
        <View style={[styles.modal, { backgroundColor: colors.background }]}>
          <View style={[styles.modalHeader, { borderBottomColor: colors.border }]}>
            <Text style={[styles.modalTitle, { color: colors.text }]}>Choose Style</Text>
            <TouchableOpacity onPress={() => setShowStylePicker(false)}>
              <Ionicons name="close" size={24} color={colors.text} />
            </TouchableOpacity>
          </View>
          <FlatList
            data={STYLES}
            keyExtractor={(s) => s}
            renderItem={({ item }) => (
              <TouchableOpacity
                style={[
                  styles.styleOption,
                  { borderBottomColor: colors.border },
                  item === plateStyle && { backgroundColor: colors.primary + '15' },
                ]}
                onPress={() => { setPlateStyle(item); setShowStylePicker(false); }}
              >
                <PlateRenderer
                  plateText="ABC123"
                  style={item}
                  customConfig={item === 'VIC_CUSTOM' ? PICKER_PREVIEW_CONFIG : null}
                  width={140}
                />
                <Text style={[styles.styleOptionText, { color: colors.text }]}>
                  {PLATE_STYLE_META[item].displayName}
                </Text>
                {item === plateStyle && (
                  <Ionicons name="checkmark" size={18} color={colors.primary} />
                )}
              </TouchableOpacity>
            )}
          />
        </View>
      </Modal>
    </ScrollView>
  );
}

// ── Sub-components ────────────────────────────────────────────────────────────

function ConfigSection({ label, children, colors }: { label: string; children: React.ReactNode; colors: any }) {
  return (
    <View style={{ gap: 6 }}>
      <Text style={[{ color: colors.textSecondary, fontSize: FontSizes.xs, fontWeight: '700' }]}>{label}</Text>
      {children}
    </View>
  );
}

function ColorRow({ colors: colorList, selected, onSelect }: { colors: string[]; selected: string; onSelect: (c: string) => void }) {
  return (
    <View style={colorRowStyles.row}>
      {colorList.map((c) => (
        <TouchableOpacity
          key={c}
          style={[
            colorRowStyles.swatch,
            { backgroundColor: c },
            selected === c && colorRowStyles.swatchSelected,
          ]}
          onPress={() => onSelect(c)}
        />
      ))}
    </View>
  );
}

const colorRowStyles = StyleSheet.create({
  row: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  swatch: { width: 28, height: 28, borderRadius: 14, borderWidth: 1, borderColor: '#33333340' },
  swatchSelected: { borderWidth: 3, borderColor: '#FFFFFF' },
});

function ChipRow({ options, selected, onSelect, colors }: {
  options: { key: string; label: string }[];
  selected: string;
  onSelect: (v: string) => void;
  colors: any;
}) {
  return (
    <View style={chipStyles.row}>
      {options.map((o) => (
        <TouchableOpacity
          key={o.key}
          style={[
            chipStyles.chip,
            { borderColor: selected === o.key ? colors.primary : colors.border },
            selected === o.key && { backgroundColor: colors.primary + '20' },
          ]}
          onPress={() => onSelect(o.key)}
        >
          <Text style={[chipStyles.chipText, { color: selected === o.key ? colors.primary : colors.textSecondary }]}>
            {o.label}
          </Text>
        </TouchableOpacity>
      ))}
    </View>
  );
}

const chipStyles = StyleSheet.create({
  row: { flexDirection: 'row', flexWrap: 'wrap', gap: 6 },
  chip: {
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 20,
    borderWidth: 1.5,
  },
  chipText: { fontSize: FontSizes.xs, fontWeight: '600' },
});

const sepStyles = StyleSheet.create({
  row: { flexDirection: 'row', alignItems: 'center', gap: 8, marginTop: 4 },
  label: { fontSize: FontSizes.xs, fontWeight: '600' },
  input: {
    width: 48,
    height: 32,
    borderWidth: 1.5,
    borderRadius: 8,
    textAlign: 'center',
    fontSize: FontSizes.md,
    fontWeight: '700',
  },
});

const styles = StyleSheet.create({
  scroll: { gap: Spacing.md, padding: Spacing.md, paddingBottom: 40 },
  preview: { alignItems: 'center', paddingVertical: Spacing.lg, gap: Spacing.sm },
  card: { borderRadius: BorderRadius.lg, padding: Spacing.md, borderWidth: 1, gap: Spacing.sm },
  label: { fontSize: FontSizes.xs, fontWeight: '700', letterSpacing: 0.8 },
  hint: { fontSize: FontSizes.xs },
  value: { fontSize: FontSizes.md, fontWeight: '600', marginTop: 2 },
  row: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },

  modeToggle: {
    flexDirection: 'row',
    borderRadius: BorderRadius.full,
    borderWidth: 1,
    padding: 3,
    gap: 4,
  },
  modeBtn: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 5,
    paddingVertical: 7,
    borderRadius: BorderRadius.full,
  },
  modeBtnText: { fontSize: FontSizes.sm, fontWeight: '700' },

  photoPlaceholder: {
    width: 300,
    height: 120,
    borderRadius: 12,
    borderWidth: 2,
    borderStyle: 'dashed',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    paddingHorizontal: 20,
  },
  photoPreview: { width: 300, borderRadius: 12 },
  photoHint: { fontSize: FontSizes.sm, fontWeight: '600', textAlign: 'center' },
  photoSubHint: { fontSize: FontSizes.xs, textAlign: 'center', opacity: 0.7 },
  changePhoto: { marginTop: -4 },
  changePhotoText: { fontSize: FontSizes.sm, fontWeight: '600' },

  modal: { flex: 1 },
  modalHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: Spacing.md,
    borderBottomWidth: 1,
  },
  modalTitle: { fontSize: FontSizes.lg, fontWeight: '700' },
  styleOption: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: Spacing.md,
    borderBottomWidth: StyleSheet.hairlineWidth,
    gap: Spacing.md,
  },
  styleOptionText: { fontSize: FontSizes.md, flex: 1 },
});
