import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../auth/presentation/auth_provider.dart';
import 'event_detail_page.dart';
import 'event_form_page.dart';
import 'event_provider.dart';
import 'widgets/event_card.dart';

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});
  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  final _search = TextEditingController();

  static const _filters = <EventFilter, String>{
    EventFilter.semua: 'Semua',
    EventFilter.festival: 'Festival Musik',
    EventFilter.solo: 'Konser Solo',
    EventFilter.world: 'World Tour',
    EventFilter.wishlist: 'Wishlist',
    EventFilter.dikunjungi: 'Sudah Dikunjungi',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<EventProvider>().fetchEvents());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openDetail(String id) => Navigator.push(context,
      MaterialPageRoute(builder: (_) => EventDetailPage(eventId: id)));

  void _openForm() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const EventFormPage()));

  void _bell() => ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('Belum ada notifikasi baru')));

  void _showSortSheet() {
    final p = context.read<EventProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 16),
              const Text('Urutkan Event',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final m in SortMode.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(sortLabel(m),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  trailing: p.sort == m
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.ink)
                      : null,
                  onTap: () {
                    p.setSort(m);
                    Navigator.pop(sheetCtx);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<EventProvider>();
    final auth = context.watch<AuthProvider>();
    final wide = isWideLayout(context);
    final events = p.events;
    final loadingFirst = p.isLoading && p.allEvents.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: wide
          ? FloatingActionButton.extended(
              onPressed: _openForm,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22)),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah Event',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            )
          : FloatingActionButton(
              onPressed: _openForm,
              shape: const CircleBorder(),
              child: const Icon(Icons.add_rounded, size: 30),
            ),
      body: LayoutBuilder(
        builder: (context, c) {
          final side =
              c.maxWidth > 1220 ? (c.maxWidth - 1180) / 2 : (wide ? 32.0 : 16.0);
          final avail = c.maxWidth - side * 2;
          final cols = (avail / 230).floor().clamp(2, 5).toInt();
          const gap = 14.0;
          final itemW = (avail - gap * (cols - 1)) / cols;
          final gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: gap,
            mainAxisSpacing: gap,
            mainAxisExtent: itemW * 1.04 + EventCard.infoHeight,
          );
          Widget box(Widget child, {double top = 14}) => SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(side, top, side, 0),
                  child: child,
                ),
              );

          return RefreshIndicator(
            onRefresh: p.fetchEvents,
            color: AppColors.ink,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (!wide)
                  SliverAppBar(
                    pinned: true,
                    automaticallyImplyLeading: false,
                    toolbarHeight: 72,
                    titleSpacing: 16,
                    title: Row(
                      children: [
                        const LogoMark(size: 44),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('CONCERT RADAR',
                                style: TextStyle(
                                    fontSize: 10,
                                    letterSpacing: 1.3,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.muted)),
                            BrandText(fontSize: 21),
                          ],
                        ),
                      ],
                    ),
                    actions: [
                      RoundIconButton(
                          icon: Icons.notifications_none_rounded,
                          onTap: _bell,
                          tooltip: 'Notifikasi'),
                      const SizedBox(width: 10),
                      InitialAvatar(text: auth.email ?? '?', size: 44),
                      const SizedBox(width: 16),
                    ],
                    bottom: const PreferredSize(
                        preferredSize: Size.fromHeight(1),
                        child: Divider(height: 1)),
                  ),
                if (wide)
                  box(
                    Row(
                      children: [
                        Expanded(child: _searchField(p)),
                        const SizedBox(width: 12),
                        RoundIconButton(
                            icon: Icons.tune_rounded,
                            bg: AppColors.ink,
                            fg: Colors.white,
                            size: 54,
                            bordered: false,
                            tooltip: 'Urutkan',
                            onTap: _showSortSheet),
                        const SizedBox(width: 18),
                        RoundIconButton(
                            icon: Icons.notifications_none_rounded,
                            size: 48,
                            onTap: _bell,
                            tooltip: 'Notifikasi'),
                        const SizedBox(width: 10),
                        InitialAvatar(text: auth.email ?? '?', size: 48),
                      ],
                    ),
                    top: 24,
                  )
                else
                  box(
                    Row(
                      children: [
                        Expanded(child: _searchField(p)),
                        const SizedBox(width: 10),
                        RoundIconButton(
                            icon: Icons.tune_rounded,
                            bg: AppColors.ink,
                            fg: Colors.white,
                            size: 54,
                            bordered: false,
                            tooltip: 'Urutkan',
                            onTap: _showSortSheet),
                      ],
                    ),
                    top: 16,
                  ),
                box(
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final f in _filters.entries)
                          _filterPill(p, f.key, f.value),
                      ],
                    ),
                  ),
                  top: 16,
                ),
                box(_summaryCard(p), top: 6),
                box(_sectionHeader(p, events.length), top: 22),
                if (loadingFirst)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(side, 16, side, 110),
                    sliver: SliverGrid(
                      gridDelegate: gridDelegate,
                      delegate: SliverChildBuilderDelegate(
                          (_, __) => const Skeleton(),
                          childCount: cols * 2),
                    ),
                  )
                else if (p.error != null && p.allEvents.isEmpty)
                  box(_errorState(p), top: 60)
                else if (events.isEmpty)
                  box(_emptyState(p), top: 50)
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(side, 16, side, 110),
                    sliver: SliverGrid(
                      gridDelegate: gridDelegate,
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => EventCard(
                          event: events[i],
                          onTap: () => _openDetail(events[i].id!),
                          onFavorite: () => p.toggleFavorite(events[i]),
                        ),
                        childCount: events.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _searchField(EventProvider p) => TextField(
        controller: _search,
        onChanged: p.setQuery,
        decoration: InputDecoration(
          hintText: 'Cari musisi, festival, atau venue...',
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
          suffixIcon: p.query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () {
                    _search.clear();
                    p.setQuery('');
                  },
                ),
        ),
      );

  Widget _filterPill(EventProvider p, EventFilter f, String label) {
    final sel = p.filter == f;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: sel ? AppColors.ink : Colors.white,
        shape: StadiumBorder(
            side: BorderSide(color: sel ? AppColors.ink : AppColors.border)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => p.setFilter(f),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              label,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: sel ? Colors.white : AppColors.ink),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(EventProvider p) {
    final Widget sync;
    if (p.error != null) {
      sync = const Pill('Offline',
          icon: Icons.cloud_off_rounded,
          bg: AppColors.redBg,
          fg: AppColors.red,
          fontSize: 12);
    } else if (p.isLoading) {
      sync = const Pill('Syncing',
          icon: Icons.cloud_sync_rounded,
          bg: AppColors.orangeBg,
          fg: AppColors.orange,
          fontSize: 12);
    } else {
      sync = const Pill('Synced',
          icon: Icons.cloud_done_outlined,
          bg: AppColors.greenBg,
          fg: AppColors.green,
          borderColor: Color(0xFFBFE5CC),
          fontSize: 12);
    }
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
                color: AppColors.ink, shape: BoxShape.circle),
            child: const Icon(Icons.track_changes_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Target Konser ${DateTime.now().year}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('${p.allEvents.length} Event Incaran',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              sync,
              const SizedBox(height: 6),
              const Text('Supabase Cloud',
                  style: TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(EventProvider p, int count) => Row(
        children: [
          const Expanded(
            child: Text('Jadwal Mendatang',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800, height: 1.15)),
          ),
          const SizedBox(width: 10),
          Pill('$count Ditampilkan',
              bg: AppColors.subtle, fg: AppColors.ink, fontSize: 11.5),
          const SizedBox(width: 12),
          PopupMenuButton<SortMode>(
            tooltip: 'Urutkan',
            initialValue: p.sort,
            onSelected: p.setSort,
            color: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            itemBuilder: (_) => [
              for (final m in SortMode.values)
                PopupMenuItem(
                  value: m,
                  child: Text(sortLabel(m),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(sortLabel(p.sort),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(width: 4),
                const Icon(Icons.swap_vert_rounded, size: 18),
              ],
            ),
          ),
        ],
      );

  Widget _emptyState(EventProvider p) {
    final searching = p.query.isNotEmpty || p.filter != EventFilter.semua;
    return Column(
      children: [
        IconTile(
            icon: searching
                ? Icons.search_off_rounded
                : Icons.queue_music_rounded,
            color: AppColors.purple,
            bg: AppColors.purpleBg,
            size: 72),
        const SizedBox(height: 14),
        Text(searching ? 'Event tidak ditemukan' : 'Belum ada event',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
            searching
                ? 'Coba kata kunci atau filter lain'
                : 'Tekan tombol + untuk mulai mencatat konser incaranmu',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted)),
      ],
    );
  }

  Widget _errorState(EventProvider p) => Column(
        children: [
          const IconTile(
              icon: Icons.cloud_off_rounded,
              color: AppColors.red,
              bg: AppColors.redBg,
              size: 72),
          const SizedBox(height: 12),
          Text(p.error!, textAlign: TextAlign.center),
          TextButton(onPressed: p.fetchEvents, child: const Text('Coba lagi')),
        ],
      );
}
