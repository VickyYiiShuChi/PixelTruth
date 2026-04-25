import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final values = [
      _ValueData(Icons.gpp_good_outlined, 'Accuracy First', 'We never ship a detection model until it clears a 99%+ threshold on our internal benchmark. Confidence scores are honest — we surface uncertainty rather than hide it.'),
      _ValueData(Icons.visibility_off_outlined, 'Privacy by Design', 'Your images are never stored. Analysis happens in memory, results are returned, and data is discarded. What you upload stays yours.'),
      _ValueData(Icons.update_outlined, 'Always Up to Date', 'New generative models appear every month. Our detection pipeline is updated continuously so coverage never falls behind the frontier.'),
      _ValueData(Icons.people_outline, 'Built for Everyone', 'From journalists verifying sources to everyday users spotting fakes on social media — PixelTruth is designed to be fast, clear, and accessible without a technical background.'),
    ];

    final team = [
      _TeamData('Ling Sheng Han', 'Co-Founder & CEO', 'Former ML research lead at a computer vision lab. Built her first GAN detector in 2021 after noticing how quickly misinformation spreads with convincing imagery.'),
      _TeamData('Vicky Yii Shu Chi', 'Co-Founder & CTO', 'Full-stack engineer with a background in cryptography and digital forensics. Designed the core neural forensics pipeline that powers PixelTruth.'),
      _TeamData('Moses Ko Xiang Yiik', 'Head of Research', 'PhD in computer vision. Leads the model detection team and manages the ongoing benchmark dataset of 12M+ images used to train and evaluate our classifiers.'),
      _TeamData('Tam Yu You', 'Product Designer', 'Crafts the user experience and interface design. Focused on making complex forensic data intuitive and actionable for users of all backgrounds.'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header ──
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: kAccent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kAccent.withOpacity(0.3)),
                  ),
                  child: const Text('Our Story', style: TextStyle(color: kAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Built to Defend Truth',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kTextPrimary, fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1.0),
                ),
                const SizedBox(height: 16),
                const SizedBox(
                  width: 620,
                  child: Text(
                    'PixelTruth was developed in 2026 by computer science students at Universiti Tunku Abdul Rahman (UTAR) as an application-based prototype for the UCCD3094 Principles of Deep Learning course. '
                    'Our goal is to combat visual misinformation by replacing traditional "black box" detection with transparent, interpretable Vision Transformer heatmaps.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kTextSecondary, fontSize: 15, height: 1.7),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 64),

          // ── Mission ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kAccent.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10, height: 10,
                      decoration: const BoxDecoration(color: kAccent, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    const Text('Our Mission', style: TextStyle(color: kAccent, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  '"To make visual truth verifiable — for everyone, instantly."',
                  style: TextStyle(color: kTextPrimary, fontSize: 22, fontWeight: FontWeight.w700, height: 1.4, letterSpacing: -0.3),
                ),
                const SizedBox(height: 16),
                const Text(
                  'We build detection technology that keeps pace with generative AI. As models improve, so does our forensics engine — trained continuously on new outputs to ensure no generation technique goes undetected.',
                  style: TextStyle(color: kTextSecondary, fontSize: 14, height: 1.7),
                ),
              ],
            ),
          ),

          const SizedBox(height: 56),

          // ── Values ──
          const Text('What We Stand For', style: TextStyle(color: kTextPrimary, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 6),
          const Text('The principles behind every decision we make.', style: TextStyle(color: kTextSecondary, fontSize: 14)),
          const SizedBox(height: 28),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 6,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: values.map((v) => _ValueCard(data: v)).toList(),
          ),

          const SizedBox(height: 56),

          // ── Team ──
          const Text('The Team', style: TextStyle(color: kTextPrimary, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 6),
          const Text('Small team, serious mission.', style: TextStyle(color: kTextSecondary, fontSize: 14)),
          const SizedBox(height: 28),
          ...team.map((t) => _TeamCard(data: t)),

          const SizedBox(height: 56),

          // ── Contact CTA ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kBorder),
            ),
            child: Column(
              children: [
                const Text('Get in Touch', style: TextStyle(color: kTextPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                const Text(
                  'Questions, partnerships, press inquiries, or API access — we\'d love to hear from you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kTextSecondary, fontSize: 14, height: 1.6),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [kAccentBlue, kAccent]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('contact@pixeltruth.ai', style: TextStyle(color: kBg, fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 60),
        ],
      ),
    );
  }
}

// ── Value Card ─────────────────────────────────
class _ValueData {
  final IconData icon;
  final String title;
  final String description;
  const _ValueData(this.icon, this.title, this.description);
}

class _ValueCard extends StatelessWidget {
  final _ValueData data;
  const _ValueCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: kAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: kAccent, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(data.title, style: const TextStyle(color: kTextPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(data.description, style: const TextStyle(color: kTextSecondary, fontSize: 12, height: 1.55)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Team Card ──────────────────────────────────
class _TeamData {
  final String name;
  final String role;
  final String bio;
  const _TeamData(this.name, this.role, this.bio);
}

class _TeamCard extends StatelessWidget {
  final _TeamData data;
  const _TeamCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar placeholder
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: kAccentBlue.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: kAccentBlue.withOpacity(0.4), width: 1.5),
            ),
            child: Center(
              child: Text(
                data.name[0],
                style: const TextStyle(color: kAccentBlue, fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.name, style: const TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(data.role, style: const TextStyle(color: kAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Text(data.bio, style: const TextStyle(color: kTextSecondary, fontSize: 13, height: 1.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}