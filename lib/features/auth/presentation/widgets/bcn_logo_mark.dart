import 'dart:math' as math;

import 'package:flutter/material.dart';

class BcnLogoMark extends StatelessWidget {
  const BcnLogoMark({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    final double diamond = size * 0.56;
    final double border = size * 0.09;

    return SizedBox(
      width: size * 1.9,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          _Diamond(
            top: size * 0.20,
            left: 0,
            side: diamond,
            borderWidth: border,
            color: const Color(0xFF018751),
          ),
          _Diamond(
            top: 0,
            left: size * 0.46,
            side: diamond,
            borderWidth: border,
            color: const Color(0xFFF4B315),
          ),
          _Diamond(
            top: size * 0.20,
            left: size * 0.92,
            side: diamond,
            borderWidth: border,
            color: const Color(0xFFE91F2D),
          ),
        ],
      ),
    );
  }
}

class _Diamond extends StatelessWidget {
  const _Diamond({
    required this.top,
    required this.left,
    required this.side,
    required this.borderWidth,
    required this.color,
  });

  final double top;
  final double left;
  final double side;
  final double borderWidth;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      child: Transform.rotate(
        angle: math.pi / 4,
        child: Container(
          width: side,
          height: side,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: borderWidth),
          ),
        ),
      ),
    );
  }
}
