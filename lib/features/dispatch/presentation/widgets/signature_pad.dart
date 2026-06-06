import 'package:flutter/material.dart';

class SignaturePad extends StatefulWidget {
  final void Function(String? signaturePath) onChanged;
  final double height;

  const SignaturePad({
    super.key,
    required this.onChanged,
    this.height = 180,
  });

  @override
  State<SignaturePad> createState() => SignaturePadState();
}

class SignaturePadState extends State<SignaturePad> {
  final List<Offset?> _points = [];
  bool _hasSignature = false;

  void clear() {
    setState(() {
      _points.clear();
      _hasSignature = false;
    });
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFB0BEC5), width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _points.add(details.localPosition);
                  _hasSignature = true;
                });
                widget.onChanged('signature_local_${DateTime.now().millisecondsSinceEpoch}');
              },
              onPanEnd: (_) => _points.add(null),
              child: CustomPaint(
                painter: _SignaturePainter(_points),
                size: Size.infinite,
                child: !_hasSignature
                    ? const Center(
                        child: Text(
                          'Firma aquí con el dedo',
                          style: TextStyle(
                            color: Color(0xFF90A4AE),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _hasSignature ? clear : null,
            icon: const Icon(Icons.refresh),
            label: const Text('Limpiar firma'),
          ),
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter(this.points);

  final List<Offset?> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A237E)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      if (current != null && next != null) {
        canvas.drawLine(current, next, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
