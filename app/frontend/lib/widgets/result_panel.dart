import 'package:flutter/material.dart';
import 'dart:convert';
import '../constants/colors.dart';

class ResultPanel extends StatelessWidget {
  final String verdict;
  final double confidence;
  final List<dynamic> signals;
  final String? heatmapBase64;

  const ResultPanel({
    super.key, 
    required this.verdict, 
    required this.confidence,
    required this.signals,
    this.heatmapBase64, 
  });

  @override
  Widget build(BuildContext context) {
    // Determine colors dynamically based on the verdict
    final isAI = verdict == 'AI-Generated';
    final mainColor = isAI ? const Color(0xFFFF4757) : kAccent;
    final icon = isAI ? Icons.smart_toy_outlined : Icons.verified_outlined;
    final subtitle = isAI ? 'High confidence detection' : 'Authentic image detected';

    return Container(
      decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: mainColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              const Text('Analysis Complete', style: TextStyle(color: kTextSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: mainColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: mainColor.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(icon, color: mainColor, size: 36),
                const SizedBox(height: 12),
                Text(verdict, style: TextStyle(color: mainColor, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: kTextSecondary.withOpacity(0.8), fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Update the bars to use the dynamic confidence score!
          ConfidenceBar(label: 'AI Probability', value: isAI ? confidence : 1 - confidence, color: const Color(0xFFFF4757)),
          const SizedBox(height: 12),
          ConfidenceBar(label: 'Authenticity', value: isAI ? 1 - confidence : confidence, color: kAccent),
          const SizedBox(height: 20),
          const Text('Signal Breakdown', style: TextStyle(color: kTextSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
          const SizedBox(height: 12),
          ...signals.map((s) => SignalRow(label: s['label'], status: s['status'])),
          const SizedBox(height: 12),

          if (heatmapBase64 != null) ...[
            const Text('Forensic Heatmap', style: TextStyle(color: kTextSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                base64Decode(heatmapBase64!),
                width: double.infinity,
                height: 600,
                fit: BoxFit.cover,
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class ConfidenceBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const ConfidenceBar({super.key, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 12)),
            Text('${(value * 100).toInt()}%', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: value, backgroundColor: kBorder, valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 6),
        ),
      ],
    );
  }
}

class SignalRow extends StatelessWidget {
  final String label;
  final String status;
  const SignalRow({super.key, required this.label, required this.status});

  Color get _statusColor {
    if (status == 'Anomaly' || status == 'Synthetic' || status == 'Irregular') return const Color(0xFFFF4757);
    if (status == 'Missing') return const Color(0xFFFFB830);
    return kAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
            child: Text(status, style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class EmptyResultPanel extends StatelessWidget {
  const EmptyResultPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 420,
      decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_search, color: kTextSecondary.withOpacity(0.3), size: 48),
            const SizedBox(height: 16),
            Text('Upload an image to see results', style: TextStyle(color: kTextSecondary.withOpacity(0.5), fontSize: 14)),
          ],
        ),
      ),
    );
  }
}