import 'package:flutter/material.dart';

class HorizontalList extends StatelessWidget {
  final List<dynamic> items;
  final Widget Function(BuildContext, int) itemBuilder;
  final double height;
  final EdgeInsetsGeometry padding;

  const HorizontalList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.height = 240.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: padding,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: itemBuilder,
        separatorBuilder: (context, index) => const SizedBox(width: 12.0),
      ),
    );
  }
}
