import 'package:flutter/material.dart';

import 'demo_data.dart';

class ProductVisual extends StatelessWidget {
  const ProductVisual({
    super.key,
    required this.item,
    this.width = 84,
    this.height = 76,
  });

  final RentalItem item;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF4F8FF), Color(0xFFE9F0FB)],
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: CustomPaint(painter: _ProductPainter(item.kind)),
  );
}

class _ProductPainter extends CustomPainter {
  const _ProductPainter(this.kind);
  final ProductKind kind;

  static const dark = Color(0xFF2F3847);
  static const deep = Color(0xFF1D2634);
  static const metal = Color(0xFFD8E1EB);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 150);
    final glow = Paint()..color = const Color(0xFFE1EBFC);
    canvas.drawCircle(const Offset(164, 24), 48, glow);
    canvas.drawCircle(const Offset(25, 129), 36, glow);
    canvas.drawOval(
      Rect.fromLTWH(36, 119, 132, 16),
      Paint()..color = const Color(0x33394765),
    );
    switch (kind) {
      case ProductKind.vr:
        _vr(canvas);
      case ProductKind.projector:
        _projector(canvas);
      case ProductKind.camera:
        _camera(canvas);
      case ProductKind.tripod:
        _tripod(canvas);
      case ProductKind.light:
        _light(canvas);
      case ProductKind.laptop:
        _laptop(canvas);
    }
    canvas.restore();
  }

  void _vr(Canvas c) {
    final strap = Path()
      ..moveTo(77, 57)
      ..cubicTo(86, 19, 113, 17, 130, 57);
    c.drawPath(
      strap,
      Paint()
        ..color = deep
        ..strokeWidth = 15
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(47, 57, 123, 59),
        const Radius.circular(21),
      ),
      Paint()..color = deep,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(35, 52, 123, 62),
        const Radius.circular(18),
      ),
      Paint()..color = dark,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(41, 56, 108, 54),
        const Radius.circular(15),
      ),
      Paint()..color = const Color(0xFF414B5A),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(44, 58, 102, 23),
        const Radius.circular(12),
      ),
      Paint()..color = const Color(0xFF535F6E),
    );
    c.drawCircle(
      const Offset(153, 86),
      6,
      Paint()..color = const Color(0xFF697585),
    );
  }

  void _projector(Canvas c) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(34, 56, 132, 62),
        const Radius.circular(14),
      ),
      Paint()..color = const Color(0xFFB9C5D0),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(36, 50, 128, 61),
        const Radius.circular(14),
      ),
      Paint()..color = const Color(0xFFF7FAFC),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(45, 57, 109, 43),
        const Radius.circular(8),
      ),
      Paint()..color = metal,
    );
    c.drawCircle(
      const Offset(95, 80),
      23,
      Paint()..color = const Color(0xFF7189A6),
    );
    c.drawCircle(
      const Offset(95, 80),
      17,
      Paint()..color = const Color(0xFF304867),
    );
    c.drawCircle(
      const Offset(95, 80),
      9,
      Paint()..color = const Color(0xFF8FC4E2),
    );
    c.drawCircle(
      const Offset(144, 83),
      4,
      Paint()..color = const Color(0xFF607992),
    );
  }

  void _camera(Canvas c) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(40, 50, 120, 69),
        const Radius.circular(14),
      ),
      Paint()..color = dark,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(68, 40, 43, 19),
        const Radius.circular(4),
      ),
      Paint()..color = deep,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(47, 57, 22, 15),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF586476),
    );
    c.drawCircle(const Offset(105, 84), 33, Paint()..color = deep);
    c.drawCircle(
      const Offset(105, 84),
      25,
      Paint()..color = const Color(0xFF657488),
    );
    c.drawCircle(
      const Offset(105, 84),
      19,
      Paint()..color = const Color(0xFF21354D),
    );
    c.drawCircle(
      const Offset(105, 84),
      11,
      Paint()..color = const Color(0xFF60849E),
    );
    c.drawCircle(
      const Offset(145, 60),
      4,
      Paint()..color = const Color(0xFFDCE6F2),
    );
  }

  void _tripod(Canvas c) {
    final p = Paint()
      ..color = dark
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5;
    c.drawLine(const Offset(100, 61), const Offset(56, 127), p);
    c.drawLine(const Offset(100, 61), const Offset(144, 127), p);
    c.drawLine(const Offset(100, 61), const Offset(100, 129), p);
    c.drawLine(const Offset(84, 82), const Offset(115, 82), p);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(82, 44, 38, 20),
        const Radius.circular(4),
      ),
      Paint()..color = deep,
    );
    c.drawLine(const Offset(100, 44), const Offset(100, 34), p);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(84, 29, 32, 7),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF5E6A78),
    );
  }

  void _light(Canvas c) {
    final p = Paint()
      ..color = dark
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5;
    c.drawLine(const Offset(100, 79), const Offset(100, 128), p);
    c.drawLine(const Offset(100, 109), const Offset(65, 129), p);
    c.drawLine(const Offset(100, 109), const Offset(135, 129), p);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(61, 24, 78, 61),
        const Radius.circular(8),
      ),
      Paint()..color = dark,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(68, 31, 64, 47),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFF2F8FF),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(76, 38, 48, 33),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFD8E9FF),
    );
  }

  void _laptop(Canvas c) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(42, 35, 116, 75),
        const Radius.circular(7),
      ),
      Paint()..color = deep,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(48, 41, 104, 63),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF7FA9D7),
    );
    final screen = Path()
      ..moveTo(50, 98)
      ..lineTo(107, 42)
      ..lineTo(150, 42)
      ..lineTo(150, 102)
      ..close();
    c.drawPath(screen, Paint()..color = const Color(0x334A6EAD));
    final base = Path()
      ..moveTo(42, 109)
      ..lineTo(158, 109)
      ..lineTo(170, 122)
      ..lineTo(30, 122)
      ..close();
    c.drawPath(base, Paint()..color = metal);
    c.drawLine(
      const Offset(61, 116),
      const Offset(139, 116),
      Paint()
        ..color = const Color(0xFFA5B4C5)
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _ProductPainter oldDelegate) =>
      kind != oldDelegate.kind;
}

class CampusArtwork extends StatelessWidget {
  const CampusArtwork({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 132,
    width: double.infinity,
    child: CustomPaint(painter: _CampusPainter()),
  );
}

class _CampusPainter extends CustomPainter {
  const _CampusPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 340, size.height / 132);
    final stroke = Paint()
      ..color = const Color(0xFFA8C1EE)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final fill = Paint()..color = const Color(0xFFE6EFFF);
    canvas.drawPath(
      Path()
        ..moveTo(0, 116)
        ..quadraticBezierTo(80, 104, 170, 115)
        ..quadraticBezierTo(260, 102, 340, 116)
        ..lineTo(340, 132)
        ..lineTo(0, 132)
        ..close(),
      fill,
    );
    canvas.drawRect(const Rect.fromLTWH(105, 53, 130, 62), fill);
    canvas.drawRect(const Rect.fromLTWH(105, 53, 130, 62), stroke);
    canvas.drawRect(const Rect.fromLTWH(146, 33, 48, 82), fill);
    canvas.drawRect(const Rect.fromLTWH(146, 33, 48, 82), stroke);
    final roof = Path()
      ..moveTo(142, 34)
      ..lineTo(170, 17)
      ..lineTo(198, 34);
    canvas.drawPath(roof, stroke);
    for (final x in [117.0, 132.0, 207.0, 222.0]) {
      for (final y in [67.0, 88.0]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, 8, 11),
            const Radius.circular(2),
          ),
          stroke,
        );
      }
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(160, 87, 20, 28),
        const Radius.circular(7),
      ),
      stroke,
    );
    for (final x in [30.0, 62.0, 280.0, 313.0]) {
      canvas.drawLine(Offset(x, 88), Offset(x, 119), stroke);
      canvas.drawCircle(Offset(x, 81), 17, fill);
      canvas.drawCircle(Offset(x, 81), 17, stroke);
    }
    canvas.drawLine(const Offset(0, 116), const Offset(340, 116), stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CampusPainter oldDelegate) => false;
}
