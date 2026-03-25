// Copyright (c) 2025 Sedat Aras — Platr. MIT License.
import React from 'react';
import {
  ScrollView,
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Linking,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useTheme } from '../../hooks/useTheme';
import { BorderRadius, FontSizes, Spacing } from '../../constants/theme';

export default function LegalScreen() {
  const { colors } = useTheme();

  const openEmail = (address: string) => {
    Linking.openURL(`mailto:${address}`).catch(() => {});
  };

  return (
    <ScrollView
      style={{ backgroundColor: colors.background }}
      contentContainerStyle={styles.container}
      showsVerticalScrollIndicator={false}
    >
      {/* Privacy Policy */}
      <LegalCard title="Privacy Policy" icon="shield-checkmark-outline" colors={colors}>
        <LegalSection title="What We Collect" colors={colors}>
          <BulletItem colors={colors}>Email address and username</BulletItem>
          <BulletItem colors={colors}>Plate data you voluntarily submit</BulletItem>
          <BulletItem colors={colors}>Usage analytics (anonymous, aggregated)</BulletItem>
          <BulletItem colors={colors}>Device token for push notifications (optional)</BulletItem>
        </LegalSection>

        <LegalSection title="How We Use Your Data" colors={colors}>
          <BulletItem colors={colors}>To operate and improve the Platr service</BulletItem>
          <BulletItem colors={colors}>To send notifications you opt into</BulletItem>
          <BulletItem colors={colors}>We do not sell your personal data to third parties</BulletItem>
        </LegalSection>

        <LegalSection title="Data Storage" colors={colors}>
          <BulletItem colors={colors}>All data is stored in Australia on secure VPS infrastructure</BulletItem>
          <BulletItem colors={colors}>Data is encrypted in transit using TLS</BulletItem>
          <BulletItem colors={colors}>Compliant with Australian Privacy Principles (APP)</BulletItem>
        </LegalSection>

        <LegalSection title="Your Rights" colors={colors}>
          <BulletItem colors={colors}>You can delete your account and all associated data at any time via Settings</BulletItem>
          <BulletItem colors={colors}>You can request a copy of your data by contacting us</BulletItem>
          <BulletItem colors={colors}>Contact: privacy@platr.com.au</BulletItem>
        </LegalSection>
      </LegalCard>

      {/* Terms of Service */}
      <LegalCard title="Terms of Service" icon="document-text-outline" colors={colors}>
        <LegalSection title="Eligibility" colors={colors}>
          <BulletItem colors={colors}>You must be at least 16 years old to use Platr</BulletItem>
          <BulletItem colors={colors}>This is required under Australian Social Media Minimum Age legislation</BulletItem>
        </LegalSection>

        <LegalSection title="Acceptable Use" colors={colors}>
          <BulletItem colors={colors}>No harassment, hate speech, or threatening content</BulletItem>
          <BulletItem colors={colors}>No spam, duplicate submissions, or misleading information</BulletItem>
          <BulletItem colors={colors}>No illegal content or content that violates others' rights</BulletItem>
        </LegalSection>

        <LegalSection title="Content & Plates" colors={colors}>
          <BulletItem colors={colors}>Plates you submit become publicly visible on Platr</BulletItem>
          <BulletItem colors={colors}>We may remove content that violates these guidelines without notice</BulletItem>
          <BulletItem colors={colors}>Repeated violations may result in account suspension</BulletItem>
        </LegalSection>

        <LegalSection title="Data Sources" colors={colors}>
          <BulletItem colors={colors}>Vehicle registration data is sourced from publicly available VicRoads records</BulletItem>
          <BulletItem colors={colors}>Platr is not affiliated with VicRoads or the Victorian Government</BulletItem>
        </LegalSection>

        <LegalSection title="Disclaimer" colors={colors}>
          <BulletItem colors={colors}>Platr is provided "as is" without warranty of any kind</BulletItem>
          <BulletItem colors={colors}>We are not liable for content submitted by users</BulletItem>
          <BulletItem colors={colors}>Terms may be updated; continued use constitutes acceptance</BulletItem>
        </LegalSection>
      </LegalCard>

      {/* Contact Us */}
      <LegalCard title="Contact Us" icon="mail-outline" colors={colors}>
        <Text style={[styles.contactIntro, { color: colors.textSecondary }]}>
          We're here to help. Reach out to the relevant team below.
        </Text>

        <ContactRow
          label="Privacy Enquiries"
          email="privacy@platr.com.au"
          colors={colors}
          onPress={() => openEmail('privacy@platr.com.au')}
        />
        <ContactRow
          label="Support"
          email="support@platr.com.au"
          colors={colors}
          onPress={() => openEmail('support@platr.com.au')}
        />
      </LegalCard>

      <View style={{ height: 40 }} />
    </ScrollView>
  );
}

// ── Sub-components ────────────────────────────────────────────────────────────

function LegalCard({
  title,
  icon,
  colors,
  children,
}: {
  title: string;
  icon: string;
  colors: any;
  children: React.ReactNode;
}) {
  return (
    <View style={[styles.card, { backgroundColor: colors.card, borderColor: colors.border }]}>
      <View style={styles.cardHeader}>
        <Ionicons name={icon as any} size={20} color={colors.primary} />
        <Text style={[styles.cardTitle, { color: colors.text }]}>{title}</Text>
      </View>
      <View style={[styles.divider, { backgroundColor: colors.border }]} />
      {children}
    </View>
  );
}

function LegalSection({
  title,
  colors,
  children,
}: {
  title: string;
  colors: any;
  children: React.ReactNode;
}) {
  return (
    <View style={styles.section}>
      <Text style={[styles.sectionTitle, { color: colors.text }]}>{title}</Text>
      {children}
    </View>
  );
}

function BulletItem({ colors, children }: { colors: any; children: React.ReactNode }) {
  return (
    <View style={styles.bulletRow}>
      <View style={[styles.bullet, { backgroundColor: colors.primary }]} />
      <Text style={[styles.bulletText, { color: colors.textSecondary }]}>{children}</Text>
    </View>
  );
}

function ContactRow({
  label,
  email,
  colors,
  onPress,
}: {
  label: string;
  email: string;
  colors: any;
  onPress: () => void;
}) {
  return (
    <TouchableOpacity
      style={[styles.contactRow, { borderColor: colors.border }]}
      onPress={onPress}
      activeOpacity={0.7}
    >
      <View style={styles.contactLeft}>
        <Text style={[styles.contactLabel, { color: colors.text }]}>{label}</Text>
        <Text style={[styles.contactEmail, { color: colors.primary }]}>{email}</Text>
      </View>
      <Ionicons name="chevron-forward" size={16} color={colors.textSecondary} />
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  container: {
    padding: Spacing.md,
    gap: Spacing.md,
  },
  card: {
    borderRadius: BorderRadius.lg,
    padding: Spacing.md,
    borderWidth: 1,
    gap: Spacing.md,
  },
  cardHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.sm,
  },
  cardTitle: {
    fontSize: FontSizes.lg,
    fontWeight: '700',
  },
  divider: {
    height: StyleSheet.hairlineWidth,
    marginHorizontal: -Spacing.md,
  },
  section: {
    gap: Spacing.xs,
  },
  sectionTitle: {
    fontSize: FontSizes.sm,
    fontWeight: '700',
    marginBottom: 2,
  },
  bulletRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: Spacing.sm,
    paddingLeft: Spacing.xs,
  },
  bullet: {
    width: 5,
    height: 5,
    borderRadius: 2.5,
    marginTop: 7,
    flexShrink: 0,
  },
  bulletText: {
    fontSize: FontSizes.sm,
    lineHeight: 20,
    flex: 1,
  },
  contactIntro: {
    fontSize: FontSizes.sm,
    lineHeight: 20,
  },
  contactRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: Spacing.sm,
    borderBottomWidth: StyleSheet.hairlineWidth,
  },
  contactLeft: {
    gap: 2,
  },
  contactLabel: {
    fontSize: FontSizes.sm,
    fontWeight: '600',
  },
  contactEmail: {
    fontSize: FontSizes.sm,
  },
});
