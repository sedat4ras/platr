// Copyright (c) 2025 Sedat Aras — Platr. MIT License.
// Platr — PlateRenderer v2
// Supports VIC_STANDARD, VIC_BLACK, and fully configurable VIC_CUSTOM.

import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { PlateStyle, CustomPlateConfig, DEFAULT_CUSTOM_CONFIG } from '../types';

// ── Helpers ──────────────────────────────────────────────────────────────────

function hexToRgba(hex: string, alpha: number): string {
  const h = hex.replace('#', '');
  const r = parseInt(h.substring(0, 2), 16);
  const g = parseInt(h.substring(2, 4), 16);
  const b = parseInt(h.substring(4, 6), 16);
  return `rgba(${r},${g},${b},${alpha})`;
}

function applyConfigSeparator(text: string, sep: string): string {
  if (!sep || text.length < 4) return text;
  const mid = Math.floor(text.length / 2);
  return text.slice(0, mid) + sep + text.slice(mid);
}

// ── Sub-components ────────────────────────────────────────────────────────────

function BoltHoles({ color }: { color: string }) {
  const boltColor = hexToRgba(color, 0.3);
  return (
    <>
      <View style={[boltStyles.bolt, { backgroundColor: boltColor, top: 7, left: 10 }]} />
      <View style={[boltStyles.bolt, { backgroundColor: boltColor, top: 7, right: 10 }]} />
      <View style={[boltStyles.bolt, { backgroundColor: boltColor, bottom: 7, left: 10 }]} />
      <View style={[boltStyles.bolt, { backgroundColor: boltColor, bottom: 7, right: 10 }]} />
    </>
  );
}

const boltStyles = StyleSheet.create({
  bolt: {
    position: 'absolute',
    width: 8,
    height: 8,
    borderRadius: 4,
  },
});

/** Downward-pointing triangle badge — VIC_STANDARD style */
function VicTriangleBadge({ size }: { size: number }) {
  return (
    <View style={[triangleStyles.wrapper, { height: size }]}>
      <View style={[triangleStyles.triangle, {
        borderLeftWidth: size * 0.55,
        borderRightWidth: size * 0.55,
        borderTopWidth: size * 0.9,
      }]} />
      <Text style={[triangleStyles.text, { fontSize: size * 0.28 }]}>VIC</Text>
    </View>
  );
}

const triangleStyles = StyleSheet.create({
  wrapper: {
    position: 'absolute',
    top: 0,
    alignSelf: 'center',
    alignItems: 'center',
    justifyContent: 'flex-start',
  },
  triangle: {
    width: 0,
    height: 0,
    borderLeftColor: 'transparent',
    borderRightColor: 'transparent',
    borderTopColor: '#002E8F',
  },
  text: {
    position: 'absolute',
    top: 2,
    color: '#FFFFFF',
    fontWeight: '900',
    letterSpacing: 0.5,
  },
});

/** Vertical VIC badge — left side */
function VicVerticalBadge({ color, height }: { color: string; height: number }) {
  const fontSize = Math.max(7, height * 0.12);
  return (
    <View style={[verticalStyles.wrapper, { height }]}>
      <Text style={[verticalStyles.letter, { color, fontSize }]}>V</Text>
      <Text style={[verticalStyles.dot, { color, fontSize: fontSize * 0.6 }]}>·</Text>
      <Text style={[verticalStyles.letter, { color, fontSize }]}>I</Text>
      <Text style={[verticalStyles.dot, { color, fontSize: fontSize * 0.6 }]}>·</Text>
      <Text style={[verticalStyles.letter, { color, fontSize }]}>C</Text>
    </View>
  );
}

const verticalStyles = StyleSheet.create({
  wrapper: {
    position: 'absolute',
    left: 8,
    top: 0,
    bottom: 0,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 0,
  },
  letter: { fontWeight: '900', lineHeight: 13 },
  dot: { lineHeight: 8 },
});

/** Small box badge — top left */
function VicBoxBadge({ color, bgColor }: { color: string; bgColor: string }) {
  return (
    <View style={[boxStyles.wrapper, { backgroundColor: color }]}>
      <Text style={[boxStyles.text, { color: bgColor }]}>VIC</Text>
    </View>
  );
}

const boxStyles = StyleSheet.create({
  wrapper: {
    position: 'absolute',
    top: 6,
    left: 8,
    paddingHorizontal: 4,
    paddingVertical: 1,
    borderRadius: 2,
  },
  text: { fontSize: 7, fontWeight: '900', letterSpacing: 0.3 },
});

// ── Main Component ────────────────────────────────────────────────────────────

interface PlateRendererProps {
  plateText: string;
  style: PlateStyle;
  customConfig?: CustomPlateConfig | null;
  width?: number;
}

const PlateRenderer: React.FC<PlateRendererProps> = ({
  plateText,
  style,
  customConfig,
  width = 300,
}) => {
  const ASPECT = 2.776;
  const height = Math.round(width / ASPECT);
  const cfg = customConfig ?? DEFAULT_CUSTOM_CONFIG;

  // ── VIC_STANDARD ────────────────────────────────────────────────────────────
  if (style === 'VIC_STANDARD') {
    const triangleSize = height * 0.38;
    return (
      <View style={[styles.shadow, { width, height, borderRadius: 14 }]}>
        <LinearGradient
          colors={['#002E8F', '#005ACC']}
          start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }}
          style={[StyleSheet.absoluteFill, { borderRadius: 14 }]}
        />
        <View style={[styles.inner, { backgroundColor: '#FFFFFF', borderRadius: 10, margin: 5 }]}>
          <BoltHoles color="#111111" />
          <VicTriangleBadge size={triangleSize} />
          <Text
            style={[styles.plateText, {
              color: '#111111',
              fontSize: Math.round(height * 0.42),
              marginTop: height * 0.18,
            }]}
            numberOfLines={1}
            adjustsFontSizeToFit
          >
            {plateText.toUpperCase()}
          </Text>
          <Text style={[styles.footer, { color: '#002E8F', fontSize: Math.max(7, height * 0.115) }]}>
            VICTORIA — THE EDUCATION STATE
          </Text>
        </View>
      </View>
    );
  }

  // ── VIC_BLACK (heritage black) ──────────────────────────────────────────────
  if (style === 'VIC_BLACK') {
    return (
      <View style={[styles.shadow, { width, height, borderRadius: 12 }]}>
        {/* Chrome border effect */}
        <LinearGradient
          colors={['#C0C0C0', '#808080', '#C0C0C0']}
          start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }}
          style={[StyleSheet.absoluteFill, { borderRadius: 12 }]}
        />
        <View style={[styles.inner, { backgroundColor: '#141414', borderRadius: 9, margin: 4 }]}>
          <BoltHoles color="#FFFFFF" />
          <VicVerticalBadge color="#AAAAAA" height={height - 8} />
          <Text
            style={[styles.plateText, {
              color: '#FFFFFF',
              fontSize: Math.round(height * 0.44),
              paddingLeft: height * 0.22,
            }]}
            numberOfLines={1}
            adjustsFontSizeToFit
          >
            {plateText.toUpperCase()}
          </Text>
          <Text style={[styles.footer, { color: '#888888', fontSize: Math.max(7, height * 0.11) }]}>
            VICTORIA
          </Text>
        </View>
      </View>
    );
  }

  // ── VIC_CUSTOM ──────────────────────────────────────────────────────────────
  const displayText = applyConfigSeparator(
    plateText.toUpperCase(),
    cfg.separator ?? ''
  );

  const stateTextMap: Record<string, string> = {
    victoria: 'VICTORIA',
    education_state: 'VICTORIA — THE EDUCATION STATE',
    garden_state: 'VICTORIA — GARDEN STATE',
  };
  const stateLabel = cfg.stateText !== 'none' ? stateTextMap[cfg.stateText] : null;

  const borderRadius = 10;
  const borderWidth = cfg.borderStyle === 'none' ? 0 : cfg.borderStyle === 'chrome' ? 4 : 5;
  const borderColors: [string, string] = cfg.borderStyle === 'chrome'
    ? ['#C0C0C0', '#606060']
    : [cfg.borderColor, cfg.borderColor];

  return (
    <View style={[styles.shadow, { width, height, borderRadius: borderRadius + borderWidth }]}>
      {cfg.borderStyle !== 'none' && (
        <LinearGradient
          colors={borderColors}
          start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }}
          style={[StyleSheet.absoluteFill, { borderRadius: borderRadius + borderWidth }]}
        />
      )}
      <View style={[
        styles.inner,
        {
          backgroundColor: cfg.bgColor,
          borderRadius,
          margin: borderWidth,
        },
      ]}>
        <BoltHoles color={cfg.textColor} />

        {/* VIC Badge */}
        {cfg.vicBadge === 'triangle_top' && <VicTriangleBadge size={height * 0.38} />}
        {cfg.vicBadge === 'vertical_left' && (
          <VicVerticalBadge color={cfg.textColor} height={height - 8} />
        )}
        {cfg.vicBadge === 'box_topleft' && (
          <VicBoxBadge color={cfg.textColor} bgColor={cfg.bgColor} />
        )}

        {/* State text top */}
        {stateLabel && cfg.stateTextPosition === 'top' && (
          <Text style={[styles.footer, { color: cfg.textColor + 'AA', fontSize: Math.max(7, height * 0.1), marginBottom: 2 }]}>
            {stateLabel}
          </Text>
        )}

        <Text
          style={[styles.plateText, {
            color: cfg.textColor,
            fontSize: Math.round(height * 0.42),
            paddingLeft: cfg.vicBadge === 'vertical_left' ? height * 0.2 : 0,
            marginTop: cfg.vicBadge === 'triangle_top' ? height * 0.1 : 0,
          }]}
          numberOfLines={1}
          adjustsFontSizeToFit
        >
          {displayText}
        </Text>

        {/* State text bottom */}
        {stateLabel && cfg.stateTextPosition === 'bottom' && (
          <Text style={[styles.footer, { color: cfg.textColor + 'AA', fontSize: Math.max(7, height * 0.1) }]}>
            {stateLabel}
          </Text>
        )}
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  shadow: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 3 },
    shadowOpacity: 0.2,
    shadowRadius: 8,
    elevation: 6,
    overflow: 'hidden',
  },
  inner: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 10,
    paddingVertical: 4,
  },
  plateText: {
    fontWeight: '900',
    textAlign: 'center',
    letterSpacing: 2,
    includeFontPadding: false,
    width: '100%',
  },
  footer: {
    fontWeight: '600',
    letterSpacing: 0.8,
    textAlign: 'center',
  },
});

export default PlateRenderer;
