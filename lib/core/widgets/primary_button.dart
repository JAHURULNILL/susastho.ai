import 'package:flutter/material.dart';

class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 54,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  double _scale = 1;

  void _setScale(double value) {
    if (!mounted) return;
    setState(() => _scale = value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 100),
      child: SizedBox(
        width: double.infinity,
        height: widget.height,
        child: Listener(
          onPointerDown: (_) => _setScale(0.96),
          onPointerUp: (_) => _setScale(1),
          onPointerCancel: (_) => _setScale(1),
          child: FilledButton.icon(
            onPressed: widget.onPressed,
            icon: Icon(widget.icon ?? Icons.arrow_forward_rounded),
            label: Text(widget.label),
          ),
        ),
      ),
    );
  }
}
