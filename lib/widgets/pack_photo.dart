import 'package:flutter/material.dart';

import 'package:lean_streak/core/constants/app_colors.dart';

/// The front of the pack, or a plain box when there is no photo.
class PackPhoto extends StatelessWidget {
  const PackPhoto(this.url, {super.key, this.size = 48});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: AppColors.surfaceVariant,
      child: Icon(Icons.inventory_2_outlined, color: AppColors.textSecondary),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox.square(
        dimension: size,
        child: url == null
            ? placeholder
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}
