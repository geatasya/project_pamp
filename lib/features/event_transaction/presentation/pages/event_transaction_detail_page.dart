import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../domain/entities/event_transaction_entity.dart';
import '../providers/event_transaction_provider.dart';
import 'event_transaction_form_page.dart';

class EventTransactionDetailPage extends StatelessWidget {
  final EventTransactionEntity transaction;

  const EventTransactionDetailPage({
    super.key,
    required this.transaction,
  });

  String _formatRupiah(double v) => NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(v);

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Hapus Transaksi?'),
        content: Text(
          'Transaksi sebesar ${_formatRupiah(transaction.amount)} akan dihapus. '
          'Saldo pada Pocket "${transaction.pocketName ?? 'Tabungan'}" akan otomatis dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus Transaksi'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final provider = context.read<EventTransactionProvider>();
    final success = await provider.deleteTransaction(transaction.id);

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi berhasil dihapus & saldo pocket telah dikembalikan.'),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Gagal menghapus transaksi')),
      );
    }
  }

  void _openEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventTransactionFormPage(editTransaction: transaction),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txDateStr = DateFormat('dd MMMM yyyy', 'id_ID').format(transaction.transactionDate);
    final createdAtStr = transaction.createdAt != null
        ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(transaction.createdAt!)
        : '-';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Detail Pengeluaran Event'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Transaksi',
            onPressed: () => _openEdit(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
            tooltip: 'Hapus Transaksi',
            onPressed: () => _confirmDelete(context),
          ),
          const SizedBox(width: 8),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SoftCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.redBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: AppColors.red,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Total Pengeluaran',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '-${_formatRupiah(transaction.amount)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppColors.red,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Pill(
                      'PENGELUARAN DARI POCKET TABUNGAN',
                      bg: AppColors.subtle,
                      fg: AppColors.ink,
                      fontSize: 11,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SoftCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'INFORMASI EVENT',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w800,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _tile(
                      Icons.festival_rounded,
                      'Nama Event',
                      transaction.eventName ?? 'Event Konser',
                      AppColors.purple,
                      AppColors.purpleBg,
                    ),
                    if (transaction.eventLocation != null && transaction.eventLocation!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _tile(
                        Icons.location_on_outlined,
                        'Lokasi / Venue',
                        transaction.eventLocation!,
                        AppColors.teal,
                        AppColors.tealBg,
                      ),
                    ],
                    if (transaction.eventDate != null) ...[
                      const SizedBox(height: 12),
                      _tile(
                        Icons.event_available_rounded,
                        'Tanggal Event',
                        DateFormat('dd MMMM yyyy', 'id_ID').format(transaction.eventDate!),
                        AppColors.green,
                        AppColors.greenBg,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SoftCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RINCIAN TRANSAKSI',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w800,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _tile(
                      Icons.account_balance_wallet_rounded,
                      'Sumber Dana (Kas/Pocket)',
                      transaction.pocketName ?? 'Pocket Tabungan',
                      AppColors.orange,
                      AppColors.orangeBg,
                    ),
                    const SizedBox(height: 12),
                    _tile(
                      Icons.calendar_today_rounded,
                      'Tanggal Transaksi Dicatat',
                      txDateStr,
                      AppColors.ink,
                      AppColors.subtle,
                    ),
                    const SizedBox(height: 12),
                    _tile(
                      Icons.description_outlined,
                      'Catatan / Keperluan',
                      (transaction.notes != null && transaction.notes!.trim().isNotEmpty)
                          ? transaction.notes!.trim()
                          : 'Tidak ada catatan tambahan',
                      AppColors.muted,
                      AppColors.subtle,
                    ),
                    const SizedBox(height: 12),
                    _tile(
                      Icons.schedule_rounded,
                      'Waktu Pencatatan Sistem',
                      createdAtStr,
                      AppColors.muted,
                      AppColors.subtle,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.red,
                        side: BorderSide(color: AppColors.red.withAlpha(90)),
                      ),
                      onPressed: () => _confirmDelete(context),
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      label: const Text('Hapus Transaksi'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _openEdit(context),
                      icon: const Icon(Icons.edit_rounded, size: 20),
                      label: const Text('Edit Transaksi'),
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

  Widget _tile(IconData icon, String title, String value, Color iconColor, Color iconBg) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
