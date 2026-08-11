import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

const Color _shimmerBaseColor = Color(0xFF1A1A2E);
const Color _shimmerHighlightColor = Color(0xFF2A2A4E);

class ShimmerCard extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerCard({
    super.key,
    this.width = 150.0,
    this.height = 225.0,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _shimmerBaseColor,
      highlightColor: _shimmerHighlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _shimmerBaseColor,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class ShimmerCarousel extends StatelessWidget {
  const ShimmerCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _shimmerBaseColor,
      highlightColor: _shimmerHighlightColor,
      child: Container(
        height: 250,
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: _shimmerBaseColor,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class ShimmerHorizontalList extends StatelessWidget {
  final double height;
  
  const ShimmerHorizontalList({
    super.key,
    this.height = 240.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (context, index) => const ShimmerCard(),
        separatorBuilder: (context, index) => const SizedBox(width: 12.0),
      ),
    );
  }
}

class ShimmerDetailPage extends StatelessWidget {
  const ShimmerDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: _shimmerBaseColor,
            highlightColor: _shimmerHighlightColor,
            child: Container(
              height: 300,
              width: double.infinity,
              color: _shimmerBaseColor,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: _shimmerBaseColor,
                  highlightColor: _shimmerHighlightColor,
                  child: Container(
                    height: 32,
                    width: 250,
                    decoration: BoxDecoration(
                      color: _shimmerBaseColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Shimmer.fromColors(
                      baseColor: _shimmerBaseColor,
                      highlightColor: _shimmerHighlightColor,
                      child: Container(
                        height: 24,
                        width: 80,
                        decoration: BoxDecoration(
                          color: _shimmerBaseColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Shimmer.fromColors(
                      baseColor: _shimmerBaseColor,
                      highlightColor: _shimmerHighlightColor,
                      child: Container(
                        height: 24,
                        width: 60,
                        decoration: BoxDecoration(
                          color: _shimmerBaseColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Shimmer.fromColors(
                  baseColor: _shimmerBaseColor,
                  highlightColor: _shimmerHighlightColor,
                  child: Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _shimmerBaseColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                for (int i = 0; i < 4; i++) ...[
                  Shimmer.fromColors(
                    baseColor: _shimmerBaseColor,
                    highlightColor: _shimmerHighlightColor,
                    child: Container(
                      height: i == 0 ? 16 : 14,
                      width: i == 3 ? 200 : double.infinity,
                      decoration: BoxDecoration(
                        color: _shimmerBaseColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
