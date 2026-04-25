import 'package:flutter/material.dart';
import '../constants/colors.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

@override
  Widget build(BuildContext context) {
    final features = [
      _FeatureData(
        Icons.biotech_outlined, 
        'Neural Forensics', 
        'Deep inspection of pixel-level patterns trained on the latest state-of-the-art DeepDetect 2025 benchmark dataset.'
      ),
      _FeatureData(
        Icons.visibility_outlined, 
        'Grad-CAM Heatmaps', 
        'Visualizes the exact pixels and digital artifacts that influenced the model\'s decision using Gradient-weighted Class Activation Mapping.'
      ),
      _FeatureData(
        Icons.hub_outlined, 
        'Vision Transformer', 
        'Powered by a fine-tuned ViT-B/16 architecture that analyzes images as sequences of patches using advanced self-attention mechanisms.'
      ),
      _FeatureData(
        Icons.speed_outlined, 
        'Real-Time Results', 
        'Scan completes in under 2 seconds with a full confidence breakdown, signal report, and visual forensic overlay.'
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Column(
        children: [
          const Text('How We Detect It', style: TextStyle(color: kTextPrimary, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
          const SizedBox(height: 8),
          const Text('Multiple forensic signals, one definitive answer.', style: TextStyle(color: kTextSecondary, fontSize: 15)),
          const SizedBox(height: 48),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 6,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: features.map((f) => _FeatureCard(data: f)).toList(),
          ),
        ],
      ),
    );
  }
}

class _FeatureData {
  final IconData icon;
  final String title;
  final String desc;
  const _FeatureData(this.icon, this.title, this.desc);
}

class _FeatureCard extends StatelessWidget {
  final _FeatureData data;
  const _FeatureCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: kAccentBlue.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(data.icon, color: kAccentBlue, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(data.title, style: const TextStyle(color: kTextPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(data.desc, style: const TextStyle(color: kTextSecondary, fontSize: 12, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}