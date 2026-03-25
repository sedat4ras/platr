// Copyright (c) 2025 Sedat Aras — Platr. MIT License.
/**
 * PlateCropModal — custom crop editor.
 *
 * Interactions (all via a single PanResponder on the crop area):
 *  • 1-finger near a corner handle  → resize crop box
 *  • 1-finger elsewhere             → pan the image
 *  • 2-finger pinch                 → zoom the image (up to 20x)
 *
 * Crop math:
 *  displayW = containerW * imageScale
 *  displayH = displayW * (imgH / imgW)
 *  imgLeft  = containerW/2 − displayW/2 + panX
 *  imgTop   = containerH/2 − displayH/2 + panY
 *
 *  originX (image px) = (cropBox.x − imgLeft) / displayW * imgOrigW
 *  cropW   (image px) = cropBox.w / displayW * imgOrigW
 */

import React, { useRef, useState } from 'react';
import {
  View,
  Modal,
  Image,
  TouchableOpacity,
  Text,
  StyleSheet,
  Dimensions,
  PanResponder,
  ActivityIndicator,
  Platform,
} from 'react-native';
import * as ImageManipulator from 'expo-image-manipulator';

// ── Constants ────────────────────────────────────────────────────────────────

const SCREEN      = Dimensions.get('window');
const HANDLE_HIT  = 48;   // touch hit-area around each corner  (px)
const MIN_W       = 60;
const MIN_H       = 40;
const OVERLAY_CLR = 'rgba(0,0,0,0.60)';
const CORNER_CLR  = '#FFFFFF';
const CORNER_LEN  = 22;
const CORNER_W    = 3;

// ── Types ────────────────────────────────────────────────────────────────────

interface Box { x: number; y: number; w: number; h: number; }
type Corner = 'tl' | 'tr' | 'bl' | 'br';

interface Props {
  visible: boolean;
  imageUri: string | null;
  imageDims: { width: number; height: number } | null;
  onCrop: (uri: string, dims: { width: number; height: number }) => void;
  onCancel: () => void;
}

// ── Component ────────────────────────────────────────────────────────────────

export default function PlateCropModal({
  visible, imageUri, imageDims, onCrop, onCancel,
}: Props) {
  // All mutable state is kept in both a ref (for gesture handlers, no stale
  // closures) and a mirrored useState (for re-renders).
  const contRef  = useRef({ w: SCREEN.width, h: SCREEN.height * 0.72 });
  const scaleRef = useRef(1);
  const panRef   = useRef({ x: 0, y: 0 });
  const boxRef   = useRef<Box>({ x: 30, y: 0, w: 300, h: 110 });
  const originRef = useRef({ x: 0, y: 0 }); // View's pageX/Y on screen

  const [cont,  setCont]  = useState(contRef.current);
  const [scale, setScale] = useState(1);
  const [pan,   setPan]   = useState({ x: 0, y: 0 });
  const [box,   setBox]   = useState<Box>(boxRef.current);
  const [cropping, setCropping] = useState(false);

  function syncBox(b: Box)  { boxRef.current  = b; setBox(b); }
  function syncScale(s: number) { scaleRef.current = s; setScale(s); }
  function syncPan(p: { x: number; y: number }) { panRef.current = p; setPan(p); }

  // ── Layout ─────────────────────────────────────────────────────────────────

  function initLayout(w: number, h: number) {
    contRef.current = { w, h };
    setCont({ w, h });
    const bw = w - 60;
    const bh = Math.round(bw * 0.34);
    const b = { x: 30, y: (h - bh) / 2, w: bw, h: bh };
    syncBox(b);
    syncScale(1);
    syncPan({ x: 0, y: 0 });
  }

  // ── Gesture helpers ─────────────────────────────────────────────────────────

  function touchDist(t1: any, t2: any) {
    const dx = t2.pageX - t1.pageX;
    const dy = t2.pageY - t1.pageY;
    return Math.sqrt(dx * dx + dy * dy);
  }

  function nearCorner(lx: number, ly: number, b: Box): Corner | null {
    const D = HANDLE_HIT / 2;
    const pts: [Corner, number, number][] = [
      ['tl', b.x,       b.y      ],
      ['tr', b.x + b.w, b.y      ],
      ['bl', b.x,       b.y + b.h],
      ['br', b.x + b.w, b.y + b.h],
    ];
    for (const [c, cx, cy] of pts) {
      if (Math.abs(lx - cx) <= D && Math.abs(ly - cy) <= D) return c;
    }
    return null;
  }

  // Convert pageX/Y → local (crop area) coords
  function toLocal(pageX: number, pageY: number) {
    return { x: pageX - originRef.current.x, y: pageY - originRef.current.y };
  }

  // ── PanResponder ───────────────────────────────────────────────────────────

  const gesture = useRef<{
    type: 'none' | 'pan' | 'pinch' | 'corner';
    corner: Corner | null;
    startBox: Box;
    startPan: { x: number; y: number };
    startScale: number;
    startDist: number;
    startTouchX: number;
    startTouchY: number;
  }>({
    type: 'none', corner: null,
    startBox: boxRef.current,
    startPan: { x: 0, y: 0 }, startScale: 1,
    startDist: 0, startTouchX: 0, startTouchY: 0,
  });

  const pan_responder = useRef(PanResponder.create({
    onStartShouldSetPanResponder: () => true,
    onMoveShouldSetPanResponder:  () => true,

    onPanResponderGrant: (e) => {
      const ts = e.nativeEvent.touches;
      const g  = gesture.current;

      if (ts.length >= 2) {
        g.type       = 'pinch';
        g.startDist  = touchDist(ts[0], ts[1]);
        g.startScale = scaleRef.current;
      } else {
        const { x: lx, y: ly } = toLocal(ts[0].pageX, ts[0].pageY);
        const c = nearCorner(lx, ly, boxRef.current);
        if (c) {
          g.type       = 'corner';
          g.corner     = c;
          g.startBox   = { ...boxRef.current };
          g.startTouchX = lx;
          g.startTouchY = ly;
        } else {
          g.type     = 'pan';
          g.startPan = { ...panRef.current };
          g.startTouchX = lx;
          g.startTouchY = ly;
        }
      }
    },

    onPanResponderMove: (e) => {
      const ts = e.nativeEvent.touches;
      const g  = gesture.current;

      if (g.type === 'pinch' && ts.length >= 2) {
        const d        = touchDist(ts[0], ts[1]);
        const newScale = Math.max(1, Math.min(20, g.startScale * (d / g.startDist)));
        syncScale(newScale);

      } else if (g.type === 'corner' && ts.length >= 1) {
        const { x: lx, y: ly } = toLocal(ts[0].pageX, ts[0].pageY);
        const dx = lx - g.startTouchX;
        const dy = ly - g.startTouchY;
        const s  = g.startBox;
        let { x, y, w, h } = s;
        const c = g.corner!;

        if (c === 'tl') { x += dx; w -= dx; y += dy; h -= dy; }
        if (c === 'tr') { w += dx;           y += dy; h -= dy; }
        if (c === 'bl') { x += dx; w -= dx;           h += dy; }
        if (c === 'br') { w += dx;                     h += dy; }

        if (w < MIN_W) { if (c === 'tl' || c === 'bl') x = s.x + s.w - MIN_W; w = MIN_W; }
        if (h < MIN_H) { if (c === 'tl' || c === 'tr') y = s.y + s.h - MIN_H; h = MIN_H; }

        syncBox({ x, y, w, h });

      } else if (g.type === 'pan' && ts.length >= 1) {
        const { x: lx, y: ly } = toLocal(ts[0].pageX, ts[0].pageY);
        syncPan({
          x: g.startPan.x + (lx - g.startTouchX),
          y: g.startPan.y + (ly - g.startTouchY),
        });
      }
    },

    onPanResponderRelease:   () => { gesture.current.type = 'none'; },
    onPanResponderTerminate: () => { gesture.current.type = 'none'; },
  })).current;

  // ── Crop ────────────────────────────────────────────────────────────────────

  async function handleUse() {
    if (!imageUri || !imageDims) return;
    setCropping(true);
    try {
      const { w: cW, h: cH } = contRef.current;
      const { width: iW, height: iH } = imageDims;
      const s  = scaleRef.current;
      const p  = panRef.current;
      const b  = boxRef.current;

      const dispW = cW * s;
      const dispH = dispW * (iH / iW);
      const imgL  = cW / 2 - dispW / 2 + p.x;
      const imgT  = cH / 2 - dispH / 2 + p.y;

      const originX = Math.max(0, Math.round((b.x - imgL) / dispW * iW));
      const originY = Math.max(0, Math.round((b.y - imgT) / dispH * iH));
      const cropW   = Math.min(iW - originX, Math.max(1, Math.round(b.w / dispW * iW)));
      const cropH   = Math.min(iH - originY, Math.max(1, Math.round(b.h / dispH * iH)));

      const result = await ImageManipulator.manipulateAsync(
        imageUri,
        [{ crop: { originX, originY, width: cropW, height: cropH } }],
        { compress: 0.90, format: ImageManipulator.SaveFormat.JPEG },
      );
      onCrop(result.uri, { width: result.width, height: result.height });
    } finally {
      setCropping(false);
    }
  }

  // ── Render ──────────────────────────────────────────────────────────────────

  if (!imageUri || !imageDims) return null;

  const { w: cW, h: cH } = cont;
  const dispW = cW * scale;
  const dispH = dispW * (imageDims.height / imageDims.width);
  const imgL  = cW / 2 - dispW / 2 + pan.x;
  const imgT  = cH / 2 - dispH / 2 + pan.y;

  const { x: bx, y: by, w: bw, h: bh } = box;

  const cornerPositions: [Corner, number, number][] = [
    ['tl', bx,      by      ],
    ['tr', bx + bw, by      ],
    ['bl', bx,      by + bh ],
    ['br', bx + bw, by + bh ],
  ];

  return (
    <Modal visible={visible} animationType="slide" statusBarTranslucent>
      <View style={styles.root}>

        {/* ── Header ── */}
        <View style={styles.header}>
          <TouchableOpacity style={styles.hBtn} onPress={onCancel} disabled={cropping}>
            <Text style={styles.cancelTxt}>Cancel</Text>
          </TouchableOpacity>
          <Text style={styles.hTitle}>Crop Plate</Text>
          <TouchableOpacity style={styles.hBtn} onPress={handleUse} disabled={cropping}>
            {cropping
              ? <ActivityIndicator color="#007AFF" size="small" />
              : <Text style={styles.useTxt}>Use</Text>}
          </TouchableOpacity>
        </View>

        {/* ── Crop canvas ── */}
        <View
          style={styles.canvas}
          onLayout={(e) => {
            const { width, height } = e.nativeEvent.layout;
            initLayout(width, height);
          }}
          ref={(v) => {
            // Measure absolute position so toLocal() is accurate
            v?.measure((_x, _y, _w, _h, px, py) => {
              originRef.current = { x: px, y: py };
            });
          }}
          {...pan_responder.panHandlers}
        >
          {/* Image */}
          <Image
            source={{ uri: imageUri }}
            style={{ position: 'absolute', left: imgL, top: imgT, width: dispW, height: dispH }}
            resizeMode="cover"
          />

          {/* Dark overlays (4 panels, no pointer events) */}
          <View pointerEvents="none" style={StyleSheet.absoluteFill}>
            {/* Top */}
            <View style={[styles.overlay, { position: 'absolute', top: 0, left: 0, right: 0, height: Math.max(0, by) }]} />
            {/* Left */}
            <View style={[styles.overlay, { position: 'absolute', top: by, left: 0, width: Math.max(0, bx), height: bh }]} />
            {/* Right */}
            <View style={[styles.overlay, { position: 'absolute', top: by, left: bx + bw, right: 0, height: bh }]} />
            {/* Bottom */}
            <View style={[styles.overlay, { position: 'absolute', top: by + bh, left: 0, right: 0, bottom: 0 }]} />

            {/* Crop frame border */}
            <View style={[styles.cropBorder, { left: bx, top: by, width: bw, height: bh }]}>
              {/* Rule-of-thirds guides */}
              <View style={[styles.guide, { left: bw / 3, top: 0, bottom: 0, width: 1 }]} />
              <View style={[styles.guide, { left: (bw * 2) / 3, top: 0, bottom: 0, width: 1 }]} />
            </View>

            {/* Corner L-markers */}
            {cornerPositions.map(([c, cx, cy]) => (
              <View
                key={c}
                style={[
                  styles.cornerMark,
                  { left: cx - CORNER_LEN / 2, top: cy - CORNER_LEN / 2 },
                  c === 'tl' && { borderTopWidth: CORNER_W, borderLeftWidth:  CORNER_W },
                  c === 'tr' && { borderTopWidth: CORNER_W, borderRightWidth: CORNER_W },
                  c === 'bl' && { borderBottomWidth: CORNER_W, borderLeftWidth:  CORNER_W },
                  c === 'br' && { borderBottomWidth: CORNER_W, borderRightWidth: CORNER_W },
                ]}
              />
            ))}
          </View>
        </View>

        {/* ── Footer hint ── */}
        <View style={styles.footer}>
          <Text style={styles.hint}>Drag corners to resize  ·  Pinch to zoom  ·  Drag to pan</Text>
        </View>
      </View>
    </Modal>
  );
}

// ── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  root:   { flex: 1, backgroundColor: '#000' },

  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingTop: Platform.OS === 'ios' ? 56 : 16,
    paddingHorizontal: 16,
    paddingBottom: 12,
    backgroundColor: '#000',
  },
  hBtn:      { minWidth: 60, alignItems: 'center', paddingVertical: 4 },
  hTitle:    { color: '#FFF', fontSize: 15, fontWeight: '700' },
  cancelTxt: { color: '#AAA', fontSize: 15 },
  useTxt:    { color: '#007AFF', fontSize: 16, fontWeight: '700' },

  canvas: { flex: 1, overflow: 'hidden', backgroundColor: '#111' },

  overlay:    { backgroundColor: OVERLAY_CLR },
  cropBorder: { position: 'absolute', borderWidth: 1, borderColor: 'rgba(255,255,255,0.4)' },
  guide:      { position: 'absolute', backgroundColor: 'rgba(255,255,255,0.15)' },

  cornerMark: {
    position: 'absolute',
    width: CORNER_LEN,
    height: CORNER_LEN,
    borderColor: CORNER_CLR,
  },

  footer: {
    paddingVertical: 16,
    alignItems: 'center',
    backgroundColor: '#000',
  },
  hint: { color: '#888', fontSize: 12 },
});
