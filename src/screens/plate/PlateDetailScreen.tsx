// Copyright (c) 2025 Sedat Aras — Platr. MIT License.
import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  TextInput,
  TouchableOpacity,
  ActivityIndicator,
  StyleSheet,
  Alert,
  RefreshControl,
  Switch,
} from 'react-native';
import { useRoute, RouteProp, useNavigation } from '@react-navigation/native';
import { StackNavigationProp } from '@react-navigation/stack';
import { Ionicons } from '@expo/vector-icons';
import * as Haptics from 'expo-haptics';
import * as ImagePicker from 'expo-image-picker';
import { RootStackParamList } from '../../navigation/RootNavigator';
import { useTheme } from '../../hooks/useTheme';
import { BorderRadius, FontSizes, Spacing } from '../../constants/theme';
import {
  getPlateApi,
  starPlateApi,
  unstarPlateApi,
  getStarStatusApi,
  listCommentsApi,
  postCommentApi,
  reportCommentApi,
  blockUserApi,
  claimPlateVicroadsApi,
  toggleCommentsApi,
} from '../../services/api';
import { useAuthStore } from '../../store/authStore';
import { Comment, Plate } from '../../types';
import PlateRenderer from '../../components/PlateRenderer';
import { showToast } from '../../components/Toast';

type Route = RouteProp<RootStackParamList, 'PlateDetail'>;
type Nav = StackNavigationProp<RootStackParamList, 'PlateDetail'>;

type ClaimState = 'idle' | 'picking' | 'submitting' | 'submitted';

const REPORT_REASONS = [
  'Spam or misleading',
  'Harassment or hateful speech',
  'Violent or dangerous content',
  'Nudity or sexual content',
  'Other',
];

export default function PlateDetailScreen() {
  const { colors } = useTheme();
  const route = useRoute<Route>();
  const nav = useNavigation<Nav>();
  const { plateId } = route.params;

  const currentUser = useAuthStore((s) => s.currentUser);

  const [plate, setPlate]         = useState<Plate | null>(null);
  const [comments, setComments]   = useState<Comment[]>([]);
  const [loading, setLoading]     = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [starred, setStarred]     = useState(false);
  const [starLoading, setStarLoading] = useState(false);
  const [commentBody, setCommentBody] = useState('');
  const [postingComment, setPostingComment] = useState(false);
  const [claimState, setClaimState] = useState<ClaimState>('idle');
  const [togglingComments, setTogglingComments] = useState(false);

  const load = async () => {
    try {
      const [p, c, starStatus] = await Promise.all([
        getPlateApi(plateId),
        listCommentsApi(plateId),
        getStarStatusApi(plateId),
      ]);
      setPlate(p);
      setComments(c);
      setStarred(starStatus.starred);
      nav.setOptions({ title: `${p.state_code} · ${p.plate_text}` });
    } catch { /* noop */ }
    finally { setLoading(false); setRefreshing(false); }
  };

  useEffect(() => { load(); }, [plateId]);

  const onRefresh = () => { setRefreshing(true); load(); };

  const handleStar = async () => {
    if (!plate) return;
    setStarLoading(true);
    try {
      const res = starred
        ? await unstarPlateApi(plate.id)
        : await starPlateApi(plate.id);
      setStarred(res.starred);
      setPlate((prev) => prev ? { ...prev, star_count: res.star_count } : prev);
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    } catch { /* noop */ }
    finally { setStarLoading(false); }
  };

  const handlePostComment = async () => {
    if (!plate || !commentBody.trim()) return;
    setPostingComment(true);
    try {
      const c = await postCommentApi(plate.id, commentBody.trim());
      setComments((prev) => [c, ...prev]);
      setCommentBody('');
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    } catch { /* noop */ }
    finally { setPostingComment(false); }
  };

  const handleReport = (comment: Comment) => {
    Alert.alert('Report Comment', 'Why are you reporting this?', [
      ...REPORT_REASONS.map((r) => ({
        text: r,
        onPress: () => reportCommentApi(comment.id, r).catch(() => {}),
      })),
      { text: 'Cancel', style: 'cancel' },
    ]);
  };

  const handleBlock = (comment: Comment) => {
    Alert.alert('Block User', `Block @${comment.author_username}?`, [
      {
        text: 'Block',
        style: 'destructive',
        onPress: () => blockUserApi(comment.author_user_id).catch(() => {}),
      },
      { text: 'Cancel', style: 'cancel' },
    ]);
  };

  const handleToggleComments = async () => {
    if (!plate) return;
    setTogglingComments(true);
    try {
      const updated = await toggleCommentsApi(plate.id);
      setPlate(updated);
      showToast(updated.is_comments_open ? 'Comments enabled' : 'Comments disabled', 'success');
    } catch {
      showToast('Failed to update comments setting', 'error');
    } finally {
      setTogglingComments(false);
    }
  };

  const handleClaimViVicroads = async () => {
    if (!plate || claimState === 'submitting') return;

    setClaimState('picking');
    try {
      const result = await ImagePicker.launchImageLibraryAsync({
        mediaTypes: ImagePicker.MediaTypeOptions.Images,
        allowsEditing: false,
        quality: 0.8,
      });

      if (result.canceled || !result.assets?.length) {
        setClaimState('idle');
        return;
      }

      const uri = result.assets[0].uri;
      setClaimState('submitting');

      await claimPlateVicroadsApi(plate.id, uri);
      setClaimState('submitted');
      showToast("Claim submitted! We'll review within 48 hours.", 'success');
    } catch {
      setClaimState('idle');
      showToast('Failed to submit claim. Please try again.', 'error');
    }
  };

  if (loading) {
    return (
      <View style={[styles.center, { backgroundColor: colors.background }]}>
        <ActivityIndicator color={colors.primary} size="large" />
      </View>
    );
  }

  if (!plate) {
    return (
      <View style={[styles.center, { backgroundColor: colors.background }]}>
        <Text style={{ color: colors.textSecondary }}>Plate not found.</Text>
      </View>
    );
  }

  const isOwner = !!currentUser && plate.owner_user_id === currentUser.id;
  const isOwnedByOther = plate.ownership_verified && plate.owner_user_id !== currentUser?.id;
  const canClaim = !plate.ownership_verified && plate.owner_user_id !== currentUser?.id;

  return (
    <ScrollView
      style={{ backgroundColor: colors.background }}
      contentContainerStyle={styles.scroll}
      refreshControl={
        <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={colors.primary} />
      }
    >
      {/* Plate render */}
      <View style={styles.plateWrap}>
        <PlateRenderer
          plateText={plate.plate_text}
          style={plate.plate_style}
          customConfig={plate.custom_config ? JSON.parse(plate.custom_config as unknown as string) : null}
          width={320}
        />
      </View>

      {/* Stats + Star button */}
      <View style={styles.statsRow}>
        <StatBadge icon="star" value={plate.star_count} label="Stars" colors={colors} />
        <StatBadge icon="eye" value={plate.view_count} label="Views" colors={colors} />
        <View style={{ flex: 1 }} />
        <TouchableOpacity
          style={[
            styles.starBtn,
            { backgroundColor: starred ? colors.primary : colors.card, borderColor: colors.primary },
          ]}
          onPress={handleStar}
          disabled={starLoading}
          activeOpacity={0.8}
        >
          {starLoading ? (
            <ActivityIndicator color={starred ? '#FFF' : colors.primary} size="small" />
          ) : (
            <>
              <Ionicons name={starred ? 'star' : 'star-outline'} size={14} color={starred ? '#FFF' : colors.primary} />
              <Text style={[styles.starBtnText, { color: starred ? '#FFF' : colors.primary }]}>
                {starred ? 'Starred' : 'Star'}
              </Text>
            </>
          )}
        </TouchableOpacity>
      </View>

      {/* Ownership Badge */}
      {isOwner && (
        <View style={[styles.ownerBadge, { backgroundColor: colors.success + '20', borderColor: colors.success + '40' }]}>
          <Ionicons name="checkmark-circle" size={15} color={colors.success} />
          <Text style={[styles.ownerBadgeText, { color: colors.success }]}>You own this plate</Text>
        </View>
      )}
      {isOwnedByOther && (
        <View style={[styles.ownerBadge, { backgroundColor: colors.border, borderColor: colors.border }]}>
          <Ionicons name="checkmark-circle-outline" size={15} color={colors.textSecondary} />
          <Text style={[styles.ownerBadgeText, { color: colors.textSecondary }]}>Owned</Text>
        </View>
      )}

      {/* Owner Controls */}
      {isOwner && (
        <View style={[styles.card, { backgroundColor: colors.card, borderColor: colors.border }]}>
          <Text style={[styles.cardTitle, { color: colors.text }]}>Owner Controls</Text>
          <View style={styles.ownerControlRow}>
            <View style={styles.ownerControlLeft}>
              <Ionicons
                name={plate.is_comments_open ? 'chatbubble' : 'lock-closed'}
                size={16}
                color={plate.is_comments_open ? colors.success : colors.textSecondary}
              />
              <View>
                <Text style={[styles.ownerControlLabel, { color: colors.text }]}>Comments</Text>
                <Text style={[styles.ownerControlSub, { color: colors.textSecondary }]}>
                  {plate.is_comments_open ? 'Open — anyone can comment' : 'Closed — comments disabled'}
                </Text>
              </View>
            </View>
            {togglingComments ? (
              <ActivityIndicator size="small" color={colors.primary} />
            ) : (
              <Switch
                value={plate.is_comments_open}
                onValueChange={handleToggleComments}
                trackColor={{ false: colors.border, true: colors.primary + '80' }}
                thumbColor={plate.is_comments_open ? colors.primary : colors.textSecondary}
              />
            )}
          </View>
        </View>
      )}

      {/* Claim Section */}
      {canClaim && (
        <View style={[styles.card, { backgroundColor: colors.card, borderColor: colors.border }]}>
          <Text style={[styles.cardTitle, { color: colors.text }]}>Own this plate?</Text>
          <Text style={[styles.claimBody, { color: colors.textSecondary }]}>
            Upload a VicRoads screenshot showing your name and this plate number. Our team will verify within 24–48 hours.
          </Text>

          {claimState === 'submitted' ? (
            <View style={[styles.claimSubmittedRow, { backgroundColor: colors.success + '15' }]}>
              <Ionicons name="checkmark-circle" size={16} color={colors.success} />
              <Text style={[styles.claimSubmittedText, { color: colors.success }]}>
                Pending review
              </Text>
            </View>
          ) : (
            <TouchableOpacity
              style={[
                styles.claimBtn,
                {
                  backgroundColor: claimState === 'submitting' ? colors.primary + '60' : colors.primary,
                },
              ]}
              onPress={handleClaimViVicroads}
              disabled={claimState === 'picking' || claimState === 'submitting'}
              activeOpacity={0.8}
            >
              {claimState === 'submitting' ? (
                <ActivityIndicator color="#FFF" size="small" />
              ) : (
                <>
                  <Ionicons name="cloud-upload-outline" size={16} color="#FFF" />
                  <Text style={styles.claimBtnText}>
                    {claimState === 'picking' ? 'Selecting…' : 'Submit VicRoads Screenshot'}
                  </Text>
                </>
              )}
            </TouchableOpacity>
          )}
        </View>
      )}

      {/* Comments */}
      <View style={[styles.card, { backgroundColor: colors.card, borderColor: colors.border }]}>
        <Text style={[styles.cardTitle, { color: colors.text }]}>Comments</Text>

        {!plate.is_comments_open ? (
          <View style={styles.closedRow}>
            <Ionicons name="lock-closed" size={14} color={colors.textSecondary} />
            <Text style={[styles.closedText, { color: colors.textSecondary }]}>
              Comments are closed for this plate.
            </Text>
          </View>
        ) : (
          <>
            {/* Input */}
            <View style={[styles.commentInput, { backgroundColor: colors.inputBackground, borderColor: colors.border }]}>
              <TextInput
                style={[styles.commentField, { color: colors.text }]}
                placeholder="Add a comment…"
                placeholderTextColor={colors.textSecondary}
                value={commentBody}
                onChangeText={setCommentBody}
                multiline
                maxLength={500}
              />
              <TouchableOpacity
                style={[
                  styles.sendBtn,
                  {
                    backgroundColor:
                      commentBody.trim() ? colors.primary : colors.disabled,
                  },
                ]}
                onPress={handlePostComment}
                disabled={!commentBody.trim() || postingComment}
              >
                {postingComment ? (
                  <ActivityIndicator color="#FFF" size="small" />
                ) : (
                  <Ionicons name="send" size={16} color="#FFF" />
                )}
              </TouchableOpacity>
            </View>

            {/* Comment list */}
            {comments.filter(c => !c.is_hidden).length === 0 ? (
              <Text style={[styles.noComments, { color: colors.textSecondary }]}>
                No comments yet. Be the first!
              </Text>
            ) : (
              comments.filter(c => !c.is_hidden).map((c) => (
                <CommentRow
                  key={c.id}
                  comment={c}
                  colors={colors}
                  onReport={() => handleReport(c)}
                  onBlock={() => handleBlock(c)}
                />
              ))
            )}
          </>
        )}
      </View>
    </ScrollView>
  );
}

// ── Sub-components ──────────────────────────────────────────────────────────

function StatBadge({ icon, value, label, colors }: any) {
  return (
    <View style={styles.statBadge}>
      <Ionicons name={icon} size={12} color={colors.textSecondary} />
      <Text style={[styles.statValue, { color: colors.text }]}>{value}</Text>
      <Text style={[styles.statLabel, { color: colors.textSecondary }]}>{label}</Text>
    </View>
  );
}

function CommentRow({ comment, colors, onReport, onBlock }: {
  comment: Comment; colors: any; onReport: () => void; onBlock: () => void;
}) {
  const showMenu = () => {
    Alert.alert(
      `@${comment.author_username}`,
      undefined,
      [
        { text: 'Report Comment', style: 'destructive', onPress: onReport },
        { text: 'Block User', style: 'destructive', onPress: onBlock },
        { text: 'Cancel', style: 'cancel' },
      ]
    );
  };

  return (
    <View style={[styles.commentRow, { borderTopColor: colors.border }]}>
      <View style={styles.commentHeader}>
        <Text style={[styles.commentAuthor, { color: colors.accent }]}>
          @{comment.author_username}
        </Text>
        <Text style={[styles.commentTime, { color: colors.textSecondary }]}>
          {new Date(comment.created_at).toLocaleDateString()}
        </Text>
        <TouchableOpacity onPress={showMenu} hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}>
          <Ionicons name="ellipsis-horizontal" size={16} color={colors.textSecondary} />
        </TouchableOpacity>
      </View>
      <Text style={[styles.commentBody, { color: colors.text }]}>{comment.body}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  center: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  scroll: { padding: Spacing.md, gap: Spacing.md, paddingBottom: 40 },

  plateWrap: { alignItems: 'center', paddingVertical: Spacing.sm },

  statsRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.lg,
    paddingHorizontal: Spacing.xs,
  },
  statBadge: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  statValue: { fontSize: FontSizes.sm, fontWeight: '700' },
  statLabel: { fontSize: FontSizes.xs },

  starBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm + 2,
    borderRadius: BorderRadius.full,
    borderWidth: 1.5,
  },
  starBtnText: { fontWeight: '700', fontSize: FontSizes.sm },

  ownerBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    alignSelf: 'flex-start',
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.xs,
    borderRadius: BorderRadius.full,
    borderWidth: 1,
  },
  ownerBadgeText: { fontSize: FontSizes.xs, fontWeight: '700' },

  card: {
    borderRadius: BorderRadius.lg,
    padding: Spacing.md,
    borderWidth: 1,
    gap: Spacing.sm,
  },
  cardTitle: { fontSize: FontSizes.md, fontWeight: '700' },

  ownerControlRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: Spacing.sm,
  },
  ownerControlLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.sm,
    flex: 1,
  },
  ownerControlLabel: { fontSize: FontSizes.sm, fontWeight: '600' },
  ownerControlSub: { fontSize: FontSizes.xs, marginTop: 1 },

  claimBody: { fontSize: FontSizes.sm, lineHeight: 20 },
  claimBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: Spacing.sm,
    paddingVertical: Spacing.sm + 2,
    borderRadius: BorderRadius.md,
  },
  claimBtnText: { color: '#FFF', fontSize: FontSizes.sm, fontWeight: '700' },
  claimSubmittedRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingVertical: Spacing.sm,
    paddingHorizontal: Spacing.md,
    borderRadius: BorderRadius.md,
  },
  claimSubmittedText: { fontSize: FontSizes.sm, fontWeight: '600' },

  closedRow: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  closedText: { fontSize: FontSizes.sm },

  commentInput: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    borderRadius: BorderRadius.md,
    borderWidth: 1,
    padding: Spacing.sm,
    gap: Spacing.sm,
  },
  commentField: { flex: 1, fontSize: FontSizes.md, maxHeight: 100, paddingVertical: 0 },
  sendBtn: {
    width: 36,
    height: 36,
    borderRadius: 18,
    alignItems: 'center',
    justifyContent: 'center',
  },

  noComments: { fontSize: FontSizes.sm, textAlign: 'center', paddingVertical: Spacing.md },

  commentRow: { paddingTop: Spacing.md, borderTopWidth: StyleSheet.hairlineWidth, gap: 4 },
  commentHeader: { flexDirection: 'row', alignItems: 'center', gap: Spacing.sm },
  commentAuthor: { fontSize: FontSizes.sm, fontWeight: '700', flex: 1 },
  commentTime: { fontSize: FontSizes.xs },
  commentBody: { fontSize: FontSizes.sm, lineHeight: 20 },
});
