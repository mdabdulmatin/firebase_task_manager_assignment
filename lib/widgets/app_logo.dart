import 'package:flutter/material.dart';

import '../utils/app_style.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 54});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: const Color(0xFFEFF2F7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D111827),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          FlutterLogo(size: size * 0.48),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(size * 0.08),
                border: Border.all(color: Colors.white, width: 1.3),
              ),
              child: Icon(
                Icons.bolt_rounded,
                size: size * 0.17,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
