import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../auth/presentation/auth_provider.dart';
import '../domain/event_entity.dart';
import 'event_form_page.dart';
import 'event_provider.dart';
import 'widgets/event_card.dart';
import 'widgets/event_helpers.dart';

class EventDetailPage extends StatelessWidget {
  final String eventId;
  const EventDetailPage({super.key, required this.eventId});

  // ---------- aksi ----------
  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Hapus event?'),
        content: const Text('Event ini akan dihapus permanen dari daftar.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus',
                  style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final provider = context.read<EventProvider>();
    final success = await provider.deleteEvent(eventId);
    if (!context.mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(provider.error ?? 'Gagal')));
    }
  }

  Future<void> _open(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link tidak bisa dibuka')));
    }
  }

  Future<void> _openTicket(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await _open(context, uri);
  }

  Future<void> _openMaps(BuildContext context, EventEntity e) {
    final q = '${e.location} ${e.address ?? ''}'.trim();
    return _open(context,
        Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': q}));
  }

  Future<void> _share(BuildContext context, EventEntity e) async {
    final text = StringBuffer()
      ..writeln(e.name)
      ..writeln(formatLongRange(e))
      ..write(e.location);
    if ((e.ticketUrl ?? '').isNotEmpty) text.write('\nTiket: ${e.ticketUrl}');
    await Clipboard.setData(ClipboardData(text: text.toString()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Info event disalin ke clipboard')));
    }
  }

  void _edit(BuildContext context, EventEntity e) => Navigator.push(context,
      MaterialPageRoute(builder: (_) => EventFormPage(event: e)));

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    final p = context.watch<EventProvider>();
    final auth = context.watch<AuthProvider>();
    final e = p.byId(eventId);
    if (e == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final wide = isWideLayout(context);
    final cards = _spaced(_cards(context, p, e), 14);

    final Widget content;
    if (wide) {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _hero(context, p, e, ratio: 1.2),
                const SizedBox(height: 18),
                _title(e),
                const SizedBox(height: 14),
                _infoBar(e),
                const SizedBox(height: 18),
                _actions(context, e),
              ],
            ),
          ),
          const SizedBox(width: 28),
          Expanded(flex: 6, child: Column(children: cards)),
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _hero(context, p, e),
          const SizedBox(height: 18),
          _title(e),
          const SizedBox(height: 14),
          _infoBar(e),
          const SizedBox(height: 14),
          ...cards,
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 68,
        titleSpacing: 14,
        title: Row(
          children: [
            RoundIconButton(
                icon: Icons.arrow_back_rounded,
                size: 42,
                bordered: false,
                bg: AppColors.subtle,
                onTap: () => Navigator.pop(context)),
            const SizedBox(width: 12),
            const LogoMark(size: 34),
            const SizedBox(width: 10),
            const Text('Detail Konser'),
          ],
        ),
        actions: [
          RoundIconButton(
              icon: Icons.ios_share_rounded,
              size: 42,
              tooltip: 'Bagikan',
              onTap: () => _share(context, e)),
          const SizedBox(width: 10),
          InitialAvatar(text: auth.email ?? '?', size: 42),
          const SizedBox(width: 16),
        ],
        bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1), child: Divider(height: 1)),
      ),
      bottomNavigationBar: wide
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(top: false, child: _actions(context, e)),
            ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(wide ? 32 : 16, 16, wide ? 32 : 16, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: content,
          ),
        ),
      ),
    );
  }

  List<Widget> _spaced(List<Widget> items, double gap) {
    final r = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) r.add(SizedBox(height: gap));
      r.add(items[i]);
    }
    return r;
  }

  List<Widget> _cards(BuildContext context, EventProvider p, EventEntity e) {
    final out = <Widget>[
      _scheduleCard(e),
      _locationCard(context, e),
      _ticketCard(context, e),
    ];
    if (e.lineupList.isNotEmpty) out.add(_lineupCard(e));
    final saving = _savingCard(e);
    if (saving != null) out.add(saving);
    out.add(_statusCard(p, e));
    if ((e.description ?? '').trim().isNotEmpty) out.add(_descCard(e));
    if ((e.notes ?? '').trim().isNotEmpty || e.checklistList.isNotEmpty) {
      out.add(_notesCard(context, e));
    }
    return out;
  }

  // ---------- bagian atas ----------
  Widget _hero(BuildContext context, EventProvider p, EventEntity e,
      {double ratio = 1.34}) {
    final genre =
        e.genreList.isNotEmpty ? e.genreList.join(' & ') : e.eventType;
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: AspectRatio(
        aspectRatio: ratio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(tag: 'poster-${e.id}', child: EventPoster(url: e.imageUrl)),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0x99000000)],
                  stops: [0.5, 1],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: RoundIconButton(
                  icon: Icons.chevron_left_rounded,
                  size: 42,
                  bordered: false,
                  bg: Colors.white.withAlpha(235),
                  onTap: () => Navigator.pop(context)),
            ),
            Positioned(
              top: 14,
              right: 14,
              child: RoundIconButton(
                  icon: e.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  fg: e.isFavorite ? AppColors.red : AppColors.ink,
                  size: 42,
                  bordered: false,
                  bg: Colors.white.withAlpha(235),
                  onTap: () => p.toggleFavorite(e)),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (genre != null)
                    Pill(genre,
                        dot: AppColors.orange,
                        bg: Colors.white,
                        fg: AppColors.ink,
                        fontSize: 11.5),
                  if (e.ticketTier != null)
                    Pill(e.ticketTier!,
                        icon: Icons.bolt_rounded,
                        bg: AppColors.green,
                        fg: Colors.white,
                        fontSize: 11.5),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _title(EventEntity e) {
    final sub = [
      e.location,
      if (e.dayCount > 1) '${e.dayCount} Hari Konser',
    ].join(' • ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(e.name,
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.w800, height: 1.15)),
        const SizedBox(height: 6),
        Text(sub, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
      ],
    );
  }

  Widget _infoBar(EventEntity e) {
    final raw = (e.id ?? '').replaceAll('-', '');
    final code = 'evt_${raw.length >= 6 ? raw.substring(0, 6) : raw}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_done_outlined,
              size: 18, color: AppColors.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Tersimpan di Supabase DB ($code)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                  color: AppColors.green, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          const Text('Tersinkron',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.green)),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, EventEntity e) => Row(
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.red,
              side: BorderSide(color: AppColors.red.withAlpha(90)),
              minimumSize: const Size(120, 54),
            ),
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            label: const Text('Hapus'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _edit(context, e),
              icon: const Icon(Icons.edit_rounded, size: 19),
              label: const Text('Edit Event'),
            ),
          ),
        ],
      );

  // ---------- kartu-kartu ----------
  Widget _scheduleCard(EventEntity e) {
    final time = timeText(e);
    return SoftCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconTile(icon: Icons.calendar_month_rounded),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CapsLabel('Tanggal & Jadwal'),
                const SizedBox(height: 4),
                Text(formatLongRange(e),
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w800)),
                if (time != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(Icons.access_time_rounded,
                            size: 16, color: AppColors.orange),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(time,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.muted)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          CountdownBadge(event: e, compact: true),
        ],
      ),
    );
  }

  Widget _locationCard(BuildContext context, EventEntity e) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconTile(
                  icon: Icons.location_on_rounded,
                  color: AppColors.orange,
                  bg: AppColors.orangeBg),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CapsLabel('Lokasi Venue'),
                    const SizedBox(height: 4),
                    Text(e.location,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    if ((e.address ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(e.address!.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.muted)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppColors.subtle,
                shape: const StadiumBorder(
                    side: BorderSide(color: AppColors.border)),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => _openMaps(context, e),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Buka Maps',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w800)),
                        SizedBox(width: 4),
                        Icon(Icons.north_east_rounded, size: 14),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _MapPreview(label: e.location),
        ],
      ),
    );
  }

  Widget _ticketCard(BuildContext context, EventEntity e) {
    final url = (e.ticketUrl ?? '').trim();
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const IconTile(
                  icon: Icons.confirmation_number_rounded,
                  color: AppColors.green,
                  bg: AppColors.greenBg),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CapsLabel('Estimasi Tiket Konser'),
                    const SizedBox(height: 4),
                    Text(
                      e.priceFrom == null
                          ? 'Belum diisi'
                          : formatRupiah(e.priceFrom!),
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w800, height: 1.1),
                    ),
                  ],
                ),
              ),
              if (e.ticketTier != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(30)),
                  child: Text(e.ticketTier!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ],
          ),
          if (url.isNotEmpty) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => _openTicket(context, url),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Beli Tiket'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _lineupCard(EventEntity e) {
    final names = e.lineupList;
    final shown = names.take(3).toList();
    final extra = names.length - shown.length;
    const palette = [
      Color(0xFF7B5CE6),
      Color(0xFFF97316),
      Color(0xFF0F9F8F),
      AppColors.ink,
    ];
    final count = shown.length + (extra > 0 ? 1 : 0);
    final line1 = names.take(2).join(', ');
    final rest = names.skip(2).take(2).join(', ');
    final line2 = rest.isEmpty
        ? ''
        : (names.length > 4 ? '$rest & more' : rest);

    Widget circle(String text, Color color) => Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Center(
            child: Text(text,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
          ),
        );

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.graphic_eq_rounded, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Lineup Highlight',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              Pill('${names.length}${names.length >= 4 ? '+' : ''} HEADLINERS',
                  bg: AppColors.subtle, fg: AppColors.muted, fontSize: 10.5),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 40 + 28.0 * (count - 1),
                height: 40,
                child: Stack(
                  children: [
                    for (var i = 0; i < shown.length; i++)
                      Positioned(
                        left: i * 28.0,
                        child: circle(shown[i][0].toUpperCase(),
                            palette[i % palette.length]),
                      ),
                    if (extra > 0)
                      Positioned(
                        left: shown.length * 28.0,
                        child: circle('+$extra', AppColors.ink),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(line1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800)),
                    if (line2.isNotEmpty)
                      Text(line2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.muted)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget? _savingCard(EventEntity e) {
    final target = e.priceFrom;
    final saved = e.savedAmount;
    if (target == null || saved == null || target <= 0) return null;
    final pct = (saved / target).clamp(0.0, 1.0).toDouble();
    final remaining = target - saved;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconTile(
                  icon: Icons.savings_rounded,
                  color: AppColors.green,
                  bg: AppColors.greenBg),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Target Tabungan Tiket',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                    Text('Saku Konser ${DateTime.now().year}',
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.muted)),
                  ],
                ),
              ),
              Text('${(pct * 100).round()}%',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.teal)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Container(height: 9, color: AppColors.subtle),
                FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(
                    height: 9,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [AppColors.teal, AppColors.purple]),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Terkumpul ${formatRupiah(saved)}',
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w800)),
              Text('Target ${formatRupiah(target)}',
                  style:
                      const TextStyle(fontSize: 12.5, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.subtle,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 17, color: AppColors.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    remaining > 0
                        ? 'Kurang ${formatRupiah(remaining)} lagi untuk checkout!'
                        : 'Target tercapai! Siap checkout tiket 🎉',
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard(EventProvider p, EventEntity e) => SoftCard(
        child: Row(
          children: [
            IconTile(
              icon: e.isVisited
                  ? Icons.check_circle_rounded
                  : Icons.hourglass_bottom_rounded,
              color: e.isVisited ? AppColors.green : AppColors.muted,
              bg: e.isVisited ? AppColors.greenBg : AppColors.subtle,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CapsLabel('Status Kunjungan'),
                  const SizedBox(height: 3),
                  Text(e.isVisited ? 'Sudah dikunjungi' : 'Belum dikunjungi',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            Switch(value: e.isVisited, onChanged: (_) => p.toggleVisited(e)),
          ],
        ),
      );

  Widget _descCard(EventEntity e) => SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CapsLabel('Tentang Event'),
            const SizedBox(height: 8),
            Text(e.description!.trim(),
                style: const TextStyle(
                    fontSize: 14, height: 1.6, color: AppColors.muted)),
          ],
        ),
      );

  Widget _notesCard(BuildContext context, EventEntity e) {
    final notes = (e.notes ?? '').trim();
    final checks = e.checklistList;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note_rounded,
                  size: 24, color: AppColors.orange),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Catatan & Checklist Pribadi',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              GestureDetector(
                onTap: () => _edit(context, e),
                child: const Text('Ubah',
                    style: TextStyle(
                        color: AppColors.teal, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.subtle,
                  borderRadius: BorderRadius.circular(18)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote_rounded,
                      size: 20, color: AppColors.muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(notes,
                        style: const TextStyle(
                            fontSize: 13.5,
                            height: 1.5,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF4A4E63))),
                  ),
                ],
              ),
            ),
          ],
          if (checks.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in checks)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            size: 16, color: AppColors.green),
                        const SizedBox(width: 6),
                        Text(c,
                            style: const TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Pratinjau peta sederhana (gambar vektor) dengan pin nama venue.
class _MapPreview extends StatelessWidget {
  final String label;
  const _MapPreview({required this.label});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 132,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _MapPainter())),
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 240),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(color: Color(0x26000000), blurRadius: 10)
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 16, color: AppColors.red),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w800)),
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

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(Offset.zero & s, Paint()..color = const Color(0xFFE9EEF3));
    final park = Paint()..color = const Color(0xFFD7EBDD);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(s.width * .05, s.height * .10, s.width * .22,
                s.height * .35),
            const Radius.circular(10)),
        park);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(s.width * .72, s.height * .55, s.width * .24,
                s.height * .35),
            const Radius.circular(10)),
        park);
    canvas.drawOval(
        Rect.fromLTWH(s.width * .55, -s.height * .2, s.width * .4, s.height * .5),
        Paint()..color = const Color(0xFFCFE3F2));
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final thin = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(0, s.height * .62), Offset(s.width, s.height * .38), road);
    canvas.drawLine(
        Offset(s.width * .32, 0), Offset(s.width * .46, s.height), road);
    canvas.drawLine(
        Offset(s.width * .70, 0), Offset(s.width * .62, s.height), thin);
    canvas.drawLine(
        Offset(0, s.height * .20), Offset(s.width, s.height * .12), thin);
    canvas.drawLine(
        Offset(0, s.height * .90), Offset(s.width, s.height * .82), thin);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
