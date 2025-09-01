import 'package:flutter/material.dart';

enum ScreenSize {
  sm,
  md,
  lg,
}

class BaseComponent extends StatelessWidget {
  const BaseComponent({super.key});

  @override
  Widget build(BuildContext context) {
    final size = ScreenUtils.size(context);
    switch (size) {
      case ScreenSize.lg:
        return bodyLg(context);
      case ScreenSize.md:
        return bodyMd(context);
      case ScreenSize.sm:
        return body(context);
    }
  }

  Widget body(BuildContext context) {
    return const SizedBox.shrink();
  }

  Widget bodyMd(BuildContext context) {
    return body(context);
  }

  Widget bodyLg(BuildContext context) {
    return body(context);
  }
}

class ScreenUtils {
  static const breakpointSm = 800.0;
  static const breakpointMd = 1050.0;

  static ScreenSize size(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < breakpointSm) {
      return ScreenSize.sm;
    }
    if (width < breakpointMd) {
      return ScreenSize.md;
    }
    return ScreenSize.lg;
  }
}
