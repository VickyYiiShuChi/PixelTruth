import 'package:flutter/material.dart';
import '../constants/colors.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(40, 80, 40, 60),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),            
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 8),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Is That Image\nReal or AI-Generated?',
            textAlign: TextAlign.center,
            style: TextStyle(color: kTextPrimary, fontSize: 52, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: -1.5),
          ),
          const SizedBox(height: 20),
          const Text(
            'Upload any image and our neural forensics engine\nwill reveal the truth in seconds.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kTextSecondary, fontSize: 17, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        width: 1,
        height: 28,
        color: kBorder,
      );
}

class _StatBadge extends StatelessWidget {
  final String value;
  final String label;
  const _StatBadge({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: kAccent, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 12)),
      ],
    );
  }
}