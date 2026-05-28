import 'package:flutter/material.dart';

class AbonLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const AbonLogo({
    super.key,
    this.size = 100,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Premium brand badge
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFF7043), // Light warm orange
                Color(0xFFFF3D00), // Deep rich orange-red
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF3D00).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.restaurant_menu_rounded,
              size: size * 0.5,
              color: Colors.white,
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 16),
          const Text(
            'ABON KITCHEN',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Color(0xFFFF3D00),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Rasa Istimewa, Kualitas Utama',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}
