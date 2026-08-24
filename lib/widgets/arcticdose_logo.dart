import 'package:flutter/material.dart';

class MODOSELogo extends StatelessWidget {
  const MODOSELogo({
    super.key,
    this.size = 72,
    this.borderRadius = 18,
  });

  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        'assets/branding/arcticdose_icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

