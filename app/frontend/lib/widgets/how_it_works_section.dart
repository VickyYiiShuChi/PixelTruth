import 'package:flutter/material.dart';
import '../constants/colors.dart';

class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

@override
  Widget build(BuildContext context) {
    final steps = [
      _StepData(
        step: '01',
        icon: Icons.cloud_upload_outlined,
        title: 'Upload Your Image',
        description:
            'Start by uploading any image you want to verify. PixelTruth accepts JPG, PNG, WEBP, and HEIC formats up to 20MB. You can drag and drop a file directly onto the upload zone, browse your device, or paste a public image URL.',
      ),
      _StepData(
        step: '02',
        icon: Icons.biotech_outlined,
        title: 'Vision Transformer Analysis',
        description:
            'Our engine processes the image through a fine-tuned Vision Transformer (ViT-B/16) model. Instead of scanning traditional pixels, it breaks the image into patches and uses self-attention mechanisms to detect subtle AI-generated artifacts learned from the DeepDetect 2025 dataset.',
      ),
      _StepData(
        step: '03',
        icon: Icons.visibility_outlined,
        title: 'Grad-CAM Heatmap Generation',
        description:
            'Instead of acting as a black box, our PyTorch backend tracks the mathematical gradients flowing backward through the neural network. It generates a Gradient-weighted Class Activation Mapping (Grad-CAM) heatmap to show you exactly which areas influenced the model\'s decision.',
      ),
      _StepData(
        step: '04',
        icon: Icons.analytics_outlined,
        title: 'Dynamic Signal Extraction',
        description:
            'Based on the ViT model\'s findings, we extract specific neural forensic signals. We evaluate pixel frequency anomalies, synthetic noise patterns, and structural irregularities that are characteristic of AI-generation pipelines.',
      ),
      _StepData(
        step: '05',
        icon: Icons.speed_outlined,
        title: 'Verdict & Confidence Report',
        description:
            'Within 2 seconds, you receive a clear verdict: Authentic or AI-Generated. Alongside the verdict, you get a full confidence breakdown, a signal-by-signal report, and the visual Grad-CAM forensic overlay.',
      ),
    ];

    final faqs = [
      _FaqData(
        'How was PixelTruth trained?', 
        'PixelTruth is powered by a Vision Transformer (ViT-B/16) fine-tuned on the state-of-the-art DeepDetect 2025 benchmark dataset. We use advanced data augmentation and mixed-precision training to ensure robust performance across diverse image types.'
      ),
      _FaqData(
        'What does the forensic heatmap show?', 
        'The Grad-CAM heatmap highlights the specific areas of the image that the neural network focused on to make its decision. Red or "hot" areas indicate the visual artifacts that heavily influenced the AI, while blue or "cool" areas were largely ignored.'
      ),
      _FaqData(
        'Can it detect which specific AI generated the image?', 
        'Currently, PixelTruth operates as a highly accurate binary classifier. It is designed to definitively answer whether an image is AI-Generated or Authentic, rather than guessing the specific generative model (like Midjourney or DALL-E).'
      ),
      _FaqData(
        'Does PixelTruth store my uploaded images?', 
        'No. Images are processed entirely in memory by our backend server and are immediately discarded after the analysis completes. Your data stays yours.'
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: kAccentBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kAccentBlue.withOpacity(0.3)),
                  ),
                  child: const Text('Under the Hood', style: TextStyle(color: kAccentBlue, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 20),
                const Text(
                  'How PixelTruth Works',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kTextPrimary, fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1.0),
                ),
                const SizedBox(height: 12),
                const Text(
                  'A five-step forensic pipeline that leaves no pixel unchecked.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kTextSecondary, fontSize: 16, height: 1.6),
                ),
              ],
            ),
          ),

          const SizedBox(height: 64),

          // Steps
          ...steps.map((s) => _StepCard(data: s)),

          const SizedBox(height: 64),

          // FAQ
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(color: kTextPrimary, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          const Text('Everything you need to know about the detection process.', style: TextStyle(color: kTextSecondary, fontSize: 14)),
          const SizedBox(height: 28),
          ...faqs.map((f) => _FaqCard(data: f)),

          const SizedBox(height: 60),
        ],
      ),
    );
  }
}

// ── Step Card ──────────────────────────────────
class _StepData {
  final String step;
  final IconData icon;
  final String title;
  final String description;
  const _StepData({required this.step, required this.icon, required this.title, required this.description});
}

class _StepCard extends StatelessWidget {
  final _StepData data;
  const _StepCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kAccent.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(data.step, style: const TextStyle(color: kAccent, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ),
          ),
          const SizedBox(width: 20),
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kAccentBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: kAccentBlue, size: 22),
          ),
          const SizedBox(width: 20),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title, style: const TextStyle(color: kTextPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(data.description, style: const TextStyle(color: kTextSecondary, fontSize: 14, height: 1.65)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── FAQ Card ───────────────────────────────────
class _FaqData {
  final String question;
  final String answer;
  const _FaqData(this.question, this.answer);
}

class _FaqCard extends StatefulWidget {
  final _FaqData data;
  const _FaqCard({required this.data});

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _expanded ? kSurfaceAlt : kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _expanded ? kAccentBlue.withOpacity(0.4) : kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(widget.data.question, style: const TextStyle(color: kTextPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                Icon(_expanded ? Icons.remove : Icons.add, color: kAccentBlue, size: 18),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 12),
              const Divider(color: kBorder, height: 1),
              const SizedBox(height: 12),
              Text(widget.data.answer, style: const TextStyle(color: kTextSecondary, fontSize: 14, height: 1.65)),
            ],
          ],
        ),
      ),
    );
  }
}