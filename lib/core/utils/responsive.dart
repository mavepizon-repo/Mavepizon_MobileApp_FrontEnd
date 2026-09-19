import 'package:flutter/material.dart';

enum ScreenType { mobile, tablet, desktop }

class ResponsiveUtils {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  static ScreenType getScreenType(double width) {
    if (width < mobileBreakpoint) return ScreenType.mobile;
    if (width < tabletBreakpoint) return ScreenType.tablet;
    return ScreenType.desktop;
  }

  static double scaledFont(BuildContext context, double mobileSize) {
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 375).clamp(0.85, 1.3);
    return mobileSize * scale;
  }

  static double scaledSpacing(BuildContext context, double mobileSpacing) {
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 375).clamp(0.9, 1.5);
    return mobileSpacing * scale;
  }

  static EdgeInsets screenPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final type = getScreenType(width);
    final h = type == ScreenType.mobile
        ? 16.0
        : type == ScreenType.tablet
            ? 24.0
            : 32.0;
    final v = 16.0;
    return EdgeInsets.symmetric(horizontal: h, vertical: v);
  }

  static EdgeInsets horizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final type = getScreenType(width);
    final h = type == ScreenType.mobile
        ? 16.0
        : type == ScreenType.tablet
            ? 24.0
            : 32.0;
    return EdgeInsets.symmetric(horizontal: h);
  }

  static double contentMaxWidth(BuildContext context) {
    final type = getScreenType(MediaQuery.of(context).size.width);
    if (type == ScreenType.desktop) return 900;
    if (type == ScreenType.tablet) return 700;
    return double.infinity;
  }

  static int gridColumns(BuildContext context) {
    final type = getScreenType(MediaQuery.of(context).size.width);
    if (type == ScreenType.desktop) return 3;
    if (type == ScreenType.tablet) return 2;
    return 1;
  }

  static bool isMobile(BuildContext context) =>
      getScreenType(MediaQuery.of(context).size.width) == ScreenType.mobile;

  static bool isTablet(BuildContext context) =>
      getScreenType(MediaQuery.of(context).size.width) == ScreenType.tablet;

  static bool isDesktop(BuildContext context) =>
      getScreenType(MediaQuery.of(context).size.width) == ScreenType.desktop;
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenType type, double width)
      builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final type = ResponsiveUtils.getScreenType(width);
        return builder(context, type, width);
      },
    );
  }
}

class ResponsiveCentered extends StatelessWidget {
  final Widget child;
  final double? maxWidth;

  const ResponsiveCentered({super.key, required this.child, this.maxWidth});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? ResponsiveUtils.contentMaxWidth(context),
        ),
        child: child,
      ),
    );
  }
}

class ResponsivePadding extends StatelessWidget {
  final Widget child;

  const ResponsivePadding({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveUtils.screenPadding(context),
      child: child,
    );
  }
}

class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final double gap;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.gap = 16,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, type, width) {
        if (type == ScreenType.mobile && width < 480) {
          return Column(
            crossAxisAlignment:
                crossAxisAlignment == CrossAxisAlignment.center
                    ? CrossAxisAlignment.stretch
                    : crossAxisAlignment,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: gap),
                children[i],
              ],
            ],
          );
        }
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: children,
        );
      },
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double gap;
  final double? childAspectRatio;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.gap = 16,
    this.childAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, type, width) {
        final cols = ResponsiveUtils.gridColumns(context);
        if (cols > 1) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: gap,
              mainAxisSpacing: gap,
              childAspectRatio: childAspectRatio ?? 1.6,
            ),
            itemCount: children.length,
            itemBuilder: (_, i) => children[i],
          );
        }
        return Column(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(height: gap),
              children[i],
            ],
          ],
        );
      },
    );
  }
}

extension ResponsiveContext on BuildContext {
  ScreenType get screenType => ResponsiveUtils.getScreenType(
      MediaQuery.of(this).size.width);

  bool get isMobile =>
      ResponsiveUtils.getScreenType(MediaQuery.of(this).size.width) ==
      ScreenType.mobile;

  bool get isTablet =>
      ResponsiveUtils.getScreenType(MediaQuery.of(this).size.width) ==
      ScreenType.tablet;

  bool get isDesktop =>
      ResponsiveUtils.getScreenType(MediaQuery.of(this).size.width) ==
      ScreenType.desktop;

  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  EdgeInsets get responsivePadding =>
      ResponsiveUtils.screenPadding(this);

  EdgeInsets get responsiveHorizontalPadding =>
      ResponsiveUtils.horizontalPadding(this);

  int get gridColumns => ResponsiveUtils.gridColumns(this);
}
