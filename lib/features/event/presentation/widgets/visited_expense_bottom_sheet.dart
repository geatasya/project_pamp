import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../event_transaction/presentation/providers/event_transaction_provider.dart';
import '../../../savings/domain/entities/savings_pocket_entity.dart';
import '../../../savings/presentation/providers/savings_provider.dart';
import '../../domain/event_entity.dart';
import 'event_helpers.dart';

/// Menampilkan Smart Action Bottom Sheet untuk konfirmasi dan validasi saldo
/// saat konser ditandai sebagai 'Sudah Dikunjungi'.
Future<void> showVisitedExpenseSheet(
  BuildContext context, {
  required EventEntity event,
}) async {
  // Pastikan data tabungan terbaru sudah ter-load
  final savingsProv = context.read<SavingsProvider>();
  final txProv = context.read<EventTransactionProvider>();
  await Future.wait([
    savingsProv.fetchData(),
    txProv.fetchAll(),
  ]);

  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _VisitedExpenseSheetContent(event: event),
  );
}

class _VisitedExpenseSheetContent extends StatefulWidget {
  final EventEntity event;
  const _VisitedExpenseSheetContent({required this.event});

  @override
  State<_VisitedExpenseSheetContent> createState() =>
      _VisitedExpenseSheetContentState();
}

class _VisitedExpenseSheetContentState
    extends State<_VisitedExpenseSheetContent> {
  SavingsPocketEntity? _selectedPocket;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final savings = context.read<SavingsProvider>();
    final amount = (widget.event.priceFrom != null && widget.event.priceFrom! > 0)
        ? widget.event.priceFrom!.toDouble()
        : 500000.0;

    // Prioritaskan pocket yang saldonya mencukupi
    if (savings.pockets.isNotEmpty) {
      _selectedPocket = savings.pockets.firstWhere(
        (p) => p.currentAmount >= amount,
        orElse: () => savings.pockets.first,
      );
    }
  }

  Future<void> _handleConfirmPayment(
    BuildContext context,
    SavingsPocketEntity pocket,
    double amount,
  ) async {
    setState(() => _isProcessing = true);
    final txProv = context.read<EventTransactionProvider>();
    final savingsProv = context.read<SavingsProvider>();

    try {
      final key = txProv.generateIdempotencyKey();
      final notes =
          'Pengeluaran tiket ${widget.event.name} (Saldo diambil dari kantong: ${pocket.name})';

      await txProv.createTransaction(
        eventId: widget.event.id!,
        pocketId: pocket.id,
        amount: amount,
        transactionDate: DateTime.now(),
        notes: notes,
      );

      await Future.wait([
        txProv.fetchAll(),
        savingsProv.fetchData(),
      ]);

      if (!context.mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 Pengeluaran ${formatRupiah(amount)} berhasil dicatat dari kantong "${pocket.name}"!',
          ),
          backgroundColor: AppColors.ink,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mencatat pengeluaran: $e'),
          backgroundColor: AppColors.red,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showQuickDepositDialog(
    BuildContext context,
    SavingsPocketEntity pocket,
    double neededAmount,
  ) async {
    final controller =
        TextEditingController(text: neededAmount.toInt().toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('Top-Up ${pocket.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masukkan nominal setor saldo untuk mencukupi pembelian tiket:',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                labelText: 'Nominal Setoran',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dlgCtx, true),
            child: const Text('Setor Sekarang'),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      final depositAmount = double.tryParse(controller.text) ?? neededAmount;
      if (depositAmount <= 0) return;

      final savingsProv = context.read<SavingsProvider>();
      final success = await savingsProv.recordTransaction(
        pocketId: pocket.id,
        type: 'deposit',
        amount: depositAmount,
        date: DateTime.now(),
        notes: 'Top-up saldo untuk tiket konser ${widget.event.name}',
      );

      if (success && mounted) {
        // Refresh pilihan pocket lokal
        final updated = savingsProv.pockets.firstWhere(
          (p) => p.id == pocket.id,
          orElse: () => pocket,
        );
        setState(() {
          _selectedPocket = updated;
        });
      }
    }
  }

  Future<void> _showCreatePocketDialog(BuildContext context) async {
    final nameCtrl = TextEditingController(text: 'Tabungan Konser Utama');
    final amount = (widget.event.priceFrom != null && widget.event.priceFrom! > 0)
        ? widget.event.priceFrom!.toDouble()
        : 1000000.0;
    final targetCtrl =
        TextEditingController(text: (amount * 2).toInt().toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Buat Kantong Tabungan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Kantong'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: targetCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                labelText: 'Target Tabungan',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dlgCtx, true),
            child: const Text('Buat Kantong'),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      final savingsProv = context.read<SavingsProvider>();
      final target = double.tryParse(targetCtrl.text) ?? amount * 2;
      final created = await savingsProv.createNewPocket(
        name: nameCtrl.text.trim(),
        targetAmount: target,
      );
      if (created && mounted) {
        setState(() {
          if (savingsProv.pockets.isNotEmpty) {
            _selectedPocket = savingsProv.pockets.last;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final savings = context.watch<SavingsProvider>();
    final pockets = savings.pockets;
    final amount = (widget.event.priceFrom != null && widget.event.priceFrom! > 0)
        ? widget.event.priceFrom!.toDouble()
        : 500000.0;

    // Pastikan _selectedPocket konsisten dengan state provider
    if (_selectedPocket != null && pockets.isNotEmpty) {
      _selectedPocket = pockets.firstWhere(
        (p) => p.id == _selectedPocket!.id,
        orElse: () => pockets.first,
      );
    } else if (_selectedPocket == null && pockets.isNotEmpty) {
      _selectedPocket = pockets.first;
    }

    final currentBalance = _selectedPocket?.currentAmount ?? 0.0;
    final isBalanceSufficient = currentBalance >= amount;
    final remainingDeficit = amount - currentBalance;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Container(
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Indikator drag bar
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Header
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: AppColors.greenBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.celebration_rounded,
                        color: AppColors.green,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Konser Telah Dikunjungi! 🎉',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Konfirmasi pencatatan pengeluaran dari tabungan:',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Tutup',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Ringkasan Event
                SoftCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.purpleBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.festival_rounded,
                          color: AppColors.purple,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.event.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.event.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Biaya Tiket',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatRupiah(amount),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Pilihan Kantong Tabungan
                const CapsLabel('PILIH KANTONG TABUNGAN (SUMBER DANA)'),
                const SizedBox(height: 10),

                if (pockets.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.orangeBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.orange.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined,
                            color: AppColors.orange, size: 30),
                        const SizedBox(height: 8),
                        const Text(
                          'Kamu belum memiliki kantong tabungan.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () => _showCreatePocketDialog(context),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Buat Kantong Tabungan Baru'),
                        ),
                      ],
                    ),
                  )
                else ...[
                  // Dropdown pilihan pocket
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.subtle,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedPocket?.id,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        items: pockets.map((pk) {
                          return DropdownMenuItem<String>(
                            value: pk.id,
                            child: Row(
                              children: [
                                const Icon(Icons.account_balance_wallet_rounded,
                                    size: 18, color: AppColors.muted),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    pk.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Text(
                                  formatRupiah(pk.currentAmount),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: pk.currentAmount >= amount
                                        ? AppColors.green
                                        : AppColors.red,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() {
                            _selectedPocket =
                                pockets.firstWhere((p) => p.id == val);
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // KONDISI A: Saldo CUKUP
                  if (isBalanceSufficient)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.greenBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.green.withOpacity(0.35)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.green, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Saldo Tabungan Mencukupi ✅',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.green,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Sisa saldo setelah pemotongan: ${formatRupiah(currentBalance - amount)}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  // KONDISI B: Saldo KURANG
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.redBg,
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: AppColors.red.withOpacity(0.35)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: AppColors.red, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Isi Tabungan Belum Mencukupi! ⚠️',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.red,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Saldo di kantong ini baru ${formatRupiah(currentBalance)} (Kurang ${formatRupiah(remainingDeficit)}).',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],

                const SizedBox(height: 24),

                // Tombol Aksi
                if (_isProcessing)
                  const Center(child: CircularProgressIndicator())
                else if (isBalanceSufficient && _selectedPocket != null) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleConfirmPayment(
                        context,
                        _selectedPocket!,
                        amount,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.receipt_long_rounded, size: 20),
                      label: const Text(
                        'Potong Saldo & Catat Transaksi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Status tetap tersimpan sebagai Sudah Dikunjungi ✅ (Tanpa potong saldo)'),
                            duration: Duration(milliseconds: 1600),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text(
                        'Hanya Tandai Dikunjungi (Tanpa Potong Tabungan)',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Status tetap tersimpan sebagai Sudah Dikunjungi ✅'),
                                duration: Duration(milliseconds: 1600),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Nanti Saja',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _selectedPocket == null
                              ? () => _showCreatePocketDialog(context)
                              : () => _showQuickDepositDialog(
                                    context,
                                    _selectedPocket!,
                                    remainingDeficit,
                                  ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.add_circle_outline_rounded,
                              size: 18),
                          label: Text(
                            _selectedPocket == null
                                ? 'Buat Kantong Dulu'
                                : 'Top-Up Saldo Tabungan',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
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
