import 'package:flutter/material.dart';
import '../constants/colors.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 60),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: kBorder))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(text: 'Pixel', style: TextStyle(color: kTextSecondary, fontWeight: FontWeight.w700, fontSize: 14)),
                TextSpan(text: 'Truth', style: TextStyle(color: kAccent, fontWeight: FontWeight.w700, fontSize: 14)),
                TextSpan(text: ' © 2025 — All rights reserved', style: TextStyle(color: kTextSecondary, fontSize: 13)),
              ],
            ),
          ),
          Row(
            children: ['Privacy', 'Terms', 'API Docs', 'Contact'].map((t) {
              return Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Text(t, style: const TextStyle(color: kTextSecondary, fontSize: 13)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}