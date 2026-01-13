import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Future<BitmapDescriptor> getMarkerIcon(Color color,
    {String? text,
    bool isIcon = false,
    IconData? icon,
    Color? iconColor,
    ui.Image? customImage}) async {
  final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);

  double width = 130.0;
  double circleRadius = (isIcon && icon == Icons.motorcycle_outlined)
      ? 55.0
      : (isIcon ? 45.0 : 38.0);
  double tailLength = 12.0;
  double topPadding = 15.0;
  double totalHeight = topPadding + (circleRadius * 2) + tailLength;
  final Offset center = Offset(width / 2, circleRadius + topPadding);

  if (customImage != null) {
    canvas.drawImage(customImage, Offset.zero, Paint());
  } else {
    if (isIcon && icon == Icons.motorcycle_outlined) {
      final Path bikePath = Path()
        ..addOval(Rect.fromCircle(center: center, radius: circleRadius));
      canvas.drawShadow(bikePath, Colors.black, 4.0, true);

      final Paint glowPaint = Paint()
        ..color = Colors.white.withAlpha(100)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(center, circleRadius + 5, glowPaint);

      final Paint bgPaint = Paint()
        ..color = const ui.Color.fromARGB(255, 60, 58, 58)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, circleRadius, bgPaint);

      final Paint borderPaint = Paint()
        ..color = Colors.yellow.withAlpha(50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawCircle(center, circleRadius, borderPaint);
    } else {
      final Path pinPath = Path();
      pinPath.addOval(Rect.fromCircle(center: center, radius: circleRadius));

      final Path tailPath = Path();
      double tailWidth = 18.0;
      double tailTipY = totalHeight - 2;

      tailPath.moveTo(center.dx - tailWidth, center.dy + (circleRadius * 0.7));
      tailPath.lineTo(center.dx, tailTipY);
      tailPath.lineTo(center.dx + tailWidth, center.dy + (circleRadius * 0.7));
      tailPath.close();

      final Path unifiedPath =
          Path.combine(PathOperation.union, pinPath, tailPath);
      canvas.drawShadow(unifiedPath, Colors.black.withAlpha(50), 3.0, true);
      canvas.drawPath(
          unifiedPath,
          Paint()
            ..color = Colors.white
            ..isAntiAlias = true);
      canvas.drawCircle(center, circleRadius - 5, Paint()..color = color);
    }

    // Draw Content
    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Specifically make the bike icon larger
    double finalFontSize = (isIcon && icon == Icons.motorcycle_outlined)
        ? 65.0
        : (isIcon ? 42.0 : 38.0);

    textPainter.text = TextSpan(
      text: isIcon ? String.fromCharCode(icon!.codePoint) : text,
      style: TextStyle(
        fontSize: finalFontSize,
        color: iconColor ?? Colors.white,
        fontFamily: icon?.fontFamily,
        package: icon?.fontPackage,
        fontWeight: isIcon ? FontWeight.normal : FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
        canvas,
        Offset(center.dx - textPainter.width / 2,
            center.dy - textPainter.height / 2));
  }

  final img = await pictureRecorder
      .endRecording()
      .toImage(width.toInt(), totalHeight.toInt());
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
}
