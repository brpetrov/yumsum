import 'package:flutter/material.dart';

import 'package:lean_streak/core/constants/app_colors.dart';

/// The front of the pack, a spinner while it downloads, or a plain box
/// when there is no photo.
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
                // No frame yet means it's still on its way.
                frameBuilder: (_, image, frame, synchronous) =>
                    synchronous || frame != null
                    ? image
                    : ColoredBox(
                        color: AppColors.surfaceVariant,
                        child: Center(
                          child: SizedBox.square(
                            dimension: size / 3,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                errorBuilder: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}
