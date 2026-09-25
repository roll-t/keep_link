import 'package:flutter/material.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';

/// Sweeping shimmer animation wrapper.
class AppShimmer extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  const AppShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.baseColor ?? AppColors.shimmerBase;
    final highlight = widget.highlightColor ?? AppColors.shimmerHighlight;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          // Paint the gradient only inside the opaque skeleton shapes. Using
          // srcATop here retained most of their original white color, making
          // the shimmer much brighter than the configured dark palette.
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-1.5, -0.3),
              end: const Alignment(1.5, 0.3),
              stops: const [0.0, 0.42, 0.5, 0.58, 1.0],
              colors: [base, base, highlight, base, base],
              transform: _SlidingGradientTransform(
                slidePercent: _controller.value,
              ),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 2 - 1),
      0.0,
      0.0,
    );
  }
}

/// Skeleton placeholder for a single [LinkListItem].
class LinkListItemSkeleton extends StatelessWidget {
  final double thumbnailWidth;
  final bool hasTrailingButton;

  const LinkListItemSkeleton({
    super.key,
    this.thumbnailWidth = 136,
    this.hasTrailingButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final minH = (thumbnailWidth * 9 / 16).roundToDouble();

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minH < 76 ? 76 : minH),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail 16:9 placeholder
            SizedBox(
              width: thumbnailWidth,
              child: Container(color: AppColors.white),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  0,
                  10,
                  hasTrailingButton ? 8 : 16,
                  10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Title line 1
                    Container(
                      height: 13,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Title line 2
                    Container(
                      height: 13,
                      width: 120,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 7),
                    // Description
                    Container(
                      height: 10,
                      width: 160,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Favicon / domain / dot / date
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          width: 50,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 44,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (hasTrailingButton)
              Padding(
                padding: const EdgeInsets.only(right: 16, top: 10),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 72,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer placeholder list for link lists.
class LinkListShimmer extends StatelessWidget {
  final int itemCount;
  final double thumbnailWidth;
  final bool hasTrailingButton;
  final EdgeInsetsGeometry padding;

  const LinkListShimmer({
    super.key,
    this.itemCount = 6,
    this.thumbnailWidth = 136,
    this.hasTrailingButton = false,
    this.padding = const EdgeInsets.only(top: 4, bottom: 24),
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, __) => Divider(
          height: .5,
          thickness: 0.8,
          indent: 0,
          endIndent: 0,
          color: AppColors.white.withOpacityCompat(0.10),
        ),
        itemBuilder: (_, __) => LinkListItemSkeleton(
          thumbnailWidth: thumbnailWidth,
          hasTrailingButton: hasTrailingButton,
        ),
      ),
    );
  }
}

/// Skeleton matching the square cards used by the Home link grid.
class LinkGridItemSkeleton extends StatelessWidget {
  const LinkGridItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(
        color: AppColors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Container(
                width: double.infinity,
                height: 13,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 78,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer placeholder for the two-column link grid on Home.
class LinkGridShimmer extends StatelessWidget {
  const LinkGridShimmer({
    super.key,
    this.itemCount = 6,
    this.padding = const EdgeInsets.fromLTRB(12, 100, 12, 112),
  });

  final int itemCount;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: GridView.builder(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemCount: itemCount,
        itemBuilder: (_, __) => const LinkGridItemSkeleton(),
      ),
    );
  }
}

/// Skeleton placeholder for a single category item.
class CategoryItemSkeleton extends StatelessWidget {
  final bool hasTrailingButton;

  const CategoryItemSkeleton({super.key, this.hasTrailingButton = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 130,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 11,
                  width: 80,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ],
            ),
          ),
          if (hasTrailingButton) ...[
            const SizedBox(width: 10),
            Container(
              width: 72,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shimmer placeholder list for category lists.
class CategoryListShimmer extends StatelessWidget {
  final int itemCount;
  final bool hasTrailingButton;
  final EdgeInsetsGeometry padding;

  const CategoryListShimmer({
    super.key,
    this.itemCount = 6,
    this.hasTrailingButton = true,
    this.padding = const EdgeInsets.only(top: 4, bottom: 24),
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, __) => Divider(
          height: .5,
          thickness: 0.8,
          indent: 0,
          endIndent: 0,
          color: AppColors.white.withOpacityCompat(0.10),
        ),
        itemBuilder: (_, __) =>
            CategoryItemSkeleton(hasTrailingButton: hasTrailingButton),
      ),
    );
  }
}
