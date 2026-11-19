import 'package:flutter/material.dart';

import '../models/barengin_models.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: compact ? 34 : 42,
        height: compact ? 34 : 42,
        decoration: BoxDecoration(
          color: AppColors.forest,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(
          Icons.bubble_chart_rounded,
          color: Colors.white,
          size: compact ? 20 : 25,
        ),
      ),
      const SizedBox(width: 10),
      Text(
        'barengin.',
        style: TextStyle(
          fontSize: compact ? 20 : 25,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.2,
          color: AppColors.forest,
        ),
      ),
    ],
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.actionLabel, this.onAction});
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 17,
          color: AppColors.ink,
        ),
      ),
      if (actionLabel != null)
        TextButton(
          onPressed: onAction,
          child: Text(
            actionLabel!,
            style: const TextStyle(
              color: AppColors.sageDark,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
    ],
  );
}

class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, this.name = '?', this.imageUrl, this.size = 42});
  final String name;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.sageLight,
      backgroundImage: imageUrl == null || imageUrl!.isEmpty
          ? null
          : NetworkImage(imageUrl!),
      child: imageUrl == null || imageUrl!.isEmpty
          ? Text(
              initial,
              style: TextStyle(
                color: AppColors.forest,
                fontWeight: FontWeight.w800,
                fontSize: size * .36,
              ),
            )
          : null,
    );
  }
}

class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    super.key,
    required this.category,
    this.size = 44,
    this.selected = false,
  });
  final Category category;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final slug = category.slug;
    final icon = slug.contains('sport')
        ? Icons.sports_basketball_rounded
        : slug.contains('hangout')
        ? Icons.coffee_rounded
        : slug.contains('study')
        ? Icons.menu_book_rounded
        : (slug == 'art' || slug.startsWith('art-'))
        ? Icons.explore_rounded
        : slug.contains('creative')
        ? Icons.palette_rounded
        : Icons.volunteer_activism_rounded;
    final bg = slug.contains('sport')
        ? AppColors.sageLight
        : slug.contains('hangout')
        ? AppColors.peach
        : slug.contains('study')
        ? AppColors.lemon
        : (slug == 'art' || slug.startsWith('art-'))
        ? AppColors.blue
        : slug.contains('creative')
        ? AppColors.lavender
        : const Color(0xFFE4F0EC);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * .32),
        border: selected
            ? Border.all(color: AppColors.sageDark, width: 1.5)
            : null,
      ),
      child: Icon(icon, color: AppColors.forest, size: size * .48),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});
  final String status;
  @override
  Widget build(BuildContext context) {
    final Color color =
        status == 'published' || status == 'accepted' || status == 'completed'
        ? const Color(0xFF3F7957)
        : status == 'pending' || status == 'draft'
        ? const Color(0xFF9C7A36)
        : status == 'ongoing'
        ? const Color(0xFF4E7391)
        : AppColors.danger;
    final bg = color.withValues(alpha: .10);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        statusLabel(status),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.activity,
    required this.onTap,
    this.trailing,
  });
  final Activity activity;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      activity.categoryName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: .8,
                        fontWeight: FontWeight.w800,
                        color: AppColors.sageDark,
                      ),
                    ),
                  ),
                  if (trailing != null)
                    trailing!
                  else
                    const Icon(
                      Icons.arrow_outward_rounded,
                      color: AppColors.muted,
                      size: 18,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          formatSchedule(activity.startsAt, activity.endsAt),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.muted,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                [
                                  activity.venueName,
                                  activity.area,
                                  activity.city,
                                ].where((x) => x.isNotEmpty).join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 66,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.sageLight,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: const Icon(
                      Icons.diversity_3_rounded,
                      color: AppColors.sageDark,
                      size: 29,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.people_alt_outlined,
                    color: AppColors.sageDark,
                    size: 15,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${activity.joinedCount}/${activity.capacity} peserta',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: activity.capacity == 0
                            ? 0
                            : (activity.joinedCount / activity.capacity)
                                  .clamp(0, 1)
                                  .toDouble(),
                        minHeight: 5,
                        backgroundColor: AppColors.line,
                        color: AppColors.sage,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    formatRupiah(activity.budgetAmount),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.forest,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.explore_outlined,
    this.actionLabel,
    this.onAction,
  });
  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: const BoxDecoration(
            color: AppColors.sageLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 34, color: AppColors.sageDark),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.muted,
            height: 1.45,
            fontSize: 13,
          ),
        ),
        if (actionLabel != null) ...[
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    ),
  );
}

void showAppMessage(
  BuildContext context,
  String message, {
  bool error = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.danger : AppColors.forest,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
