import 'package:flutter/material.dart';

class BotAvatar extends StatelessWidget {
  final double size;
  final bool isAnimated;

  const BotAvatar({
    super.key,
    this.size = 40,
    this.isAnimated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6B5BFA), // Purple
            Color(0xFF5CE1E6), // Cyan
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5CE1E6).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shopping Bag Body
          Positioned(
            top: size * 0.15,
            left: size * 0.15,
            right: size * 0.15,
            bottom: size * 0.05,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(size * 0.08),
              ),
            ),
          ),

          // Left Handle
          Positioned(
            top: size * 0.08,
            left: size * 0.25,
            child: Container(
              width: size * 0.12,
              height: size * 0.18,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF5CE1E6),
                  width: size * 0.04,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(size * 0.1),
                  topRight: Radius.circular(size * 0.1),
                ),
              ),
            ),
          ),

          // Right Handle
          Positioned(
            top: size * 0.08,
            right: size * 0.25,
            child: Container(
              width: size * 0.12,
              height: size * 0.18,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF5CE1E6),
                  width: size * 0.04,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(size * 0.1),
                  topRight: Radius.circular(size * 0.1),
                ),
              ),
            ),
          ),

          // Left Eye
          Positioned(
            top: size * 0.28,
            left: size * 0.24,
            child: Container(
              width: size * 0.12,
              height: size * 0.14,
              decoration: const BoxDecoration(
                color: Color(0xFF5CE1E6),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: size * 0.05,
                  height: size * 0.07,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2C3E50),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),

          // Right Eye
          Positioned(
            top: size * 0.28,
            right: size * 0.24,
            child: Container(
              width: size * 0.12,
              height: size * 0.14,
              decoration: const BoxDecoration(
                color: Color(0xFF5CE1E6),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: size * 0.05,
                  height: size * 0.07,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2C3E50),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),

          // Happy Mouth (curved smile)
          Positioned(
            bottom: size * 0.16,
            child: CustomPaint(
              size: Size(size * 0.2, size * 0.08),
              painter: SmilePainter(size: size * 0.2),
            ),
          ),

          // Shine Effect
          Positioned(
            top: size * 0.2,
            right: size * 0.22,
            child: Container(
              width: size * 0.08,
              height: size * 0.08,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SmilePainter extends CustomPainter {
  final double size;
  SmilePainter({required this.size});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = const Color(0xFFFF8C00)
      ..strokeWidth = size * 0.15
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.quadraticBezierTo(
      size * 0.5,
      size * 0.4,
      size,
      0,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(SmilePainter oldDelegate) => false;
}
