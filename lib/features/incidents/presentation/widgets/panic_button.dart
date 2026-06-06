import 'package:flutter/material.dart';

class IncidentsPanicButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const IncidentsPanicButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 72,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFD50000),
          foregroundColor: Colors.white,
        ),
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.warning_amber_rounded),
        label: const Text(
          'BOTÓN DE PÁNICO',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
