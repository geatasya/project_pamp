import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../providers/event_transaction_provider.dart';
import '../widgets/event_transaction_card.dart';
import 'event_transaction_detail_page.dart';
import 'event_transaction_form_page.dart';

class EventTransactionListPage extends StatefulWidget {
  const EventTransactionListPage({super.key});

  @override
  State<EventTransactionListPage> createState() => _EventTransactionListPageState();
}

class _EventTransactionListPageState extends State<EventTransactionListPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventTransactionProvider>().fetchAll();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatRupiah(double v) => NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(v);

  void _openForm() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EventTransactionFormPage()),
    );
  }

  void _openDetail(dynamic transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventTransactionDetailPage(transaction: transaction),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<EventTransactionProvider>();
    final wide = isWideLayout(context);
    final transactions = p.filteredTransactions;
    final loading = p.isLoading && p.transactions.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Transaksi Pengeluaran Event'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      floatingActionButton: wide
          ? FloatingActionButton.extended(
              onPressed: _openForm,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Catat Pengeluaran', style: TextStyle(fontWeight: FontWeight.w800)),
            )
          : FloatingActionButton(
              onPressed: _openForm,
              shape: const CircleBorder(),
              child: const Icon(Icons.add_rounded, size: 28),
            ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: RefreshIndicator(
            onRefresh: p.fetchAll,
            color: AppColors.ink,
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: wide ? 24 : 16, vertical: 16),
              children: [
                // 1. Ringkasan Pengeluaran
                SoftCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.redBg,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: AppColors.red,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Pengeluaran Event',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatRupiah(p.totalExpense),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Pill(
                        '${p.transactions.length} Transaksi',
                        bg: AppColors.subtle,
                        fg: AppColors.ink,
                        fontSize: 11.5,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Search Field
                TextField(
                  controller: _searchController,
                  onChanged: p.setSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Cari event, kas/pocket, atau catatan...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
                    suffixIcon: p.searchQuery.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              p.setSearchQuery('');
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 18),

                // 3. Header List
                Row(
                  children: [
                    const Text(
                      'Riwayat Pengeluaran',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${transactions.length} Ditampilkan',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 4. Content State
                if (loading) ...[
                  for (int i = 0; i < 4; i++)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        height: 110,
                        child: Skeleton(radius: 22),
                      ),
                    ),
                ] else if (p.error != null && p.transactions.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        const IconTile(
                          icon: Icons.error_outline_rounded,
                          color: AppColors.red,
                          bg: AppColors.redBg,
                          size: 64,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          p.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: p.fetchAll,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                ] else if (transactions.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 50),
                    child: Column(
                      children: [
                        IconTile(
                          icon: p.searchQuery.isNotEmpty
                              ? Icons.search_off_rounded
                              : Icons.receipt_long_outlined,
                          color: AppColors.purple,
                          bg: AppColors.purpleBg,
                          size: 72,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          p.searchQuery.isNotEmpty
                              ? 'Transaksi tidak ditemukan'
                              : 'Belum ada pengeluaran event',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p.searchQuery.isNotEmpty
                              ? 'Coba gunakan kata kunci pencarian yang lain'
                              : 'Tekan tombol "+" di bawah untuk mencatat pengeluaran konser incaranmu',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  for (final tx in transactions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: EventTransactionCard(
                        transaction: tx,
                        onTap: () => _openDetail(tx),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
