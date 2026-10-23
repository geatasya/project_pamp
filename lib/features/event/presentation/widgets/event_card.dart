import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../domain/event_entity.dart';
import 'event_helpers.dart';

class EventPoster extends StatelessWidget {
  final String? url;
  const EventPoster({super.key, this.url});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEFEAFD), Color(0xFFDCD3FB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.music_note_rounded,
            size: 52, color: AppColors.purple.withAlpha(150)),
      ),
    );
    if (url == null || url!.isEmpty) return placeholder;
    return Image.network(
      url!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => placeholder,
      loadingBuilder: (c, child, p) =>
          p == null ? child : Container(color: AppColors.subtle),
    );
  }
}

class EventCard extends StatelessWidget {
  static const double infoHeight = 112;

  final EventEntity event;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    required this.onFavorite,
  });

  Widget _badge() {
    if (event.isVisited) {
      return const Pill('DIKUNJUNGI',
          icon: Icons.check_circle_rounded,
          bg: AppColors.greenBg,
          fg: AppColors.green,
          fontSize: 10);
    }
    if (event.eventType != null) {
      return Pill(typeBadge(event.eventType!),
          bg: Colors.white, fg: AppColors.ink, fontSize: 10);
    }
    if (event.isFavorite) {
      return const Pill('WISHLIST',
          bg: AppColors.redBg, fg: AppColors.red, fontSize: 10);
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'poster-${event.id}',
                    child: EventPoster(url: event.imageUrl),
                  ),
                  Positioned(top: 10, left: 10, child: _badge()),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onFavorite,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(220),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          event.isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 19,
                          color: event.isFavorite
                              ? AppColors.red
                              : AppColors.ink.withAlpha(190),
                        ),
                      ),
                    ),
                  ),
                  if (event.priceFrom != null)
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xCC14141C),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          formatRupiah(event.priceFrom!),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: infoHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(event.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.muted)),
                    const Spacer(),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 14, color: AppColors.muted),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(formatShortRange(event),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
