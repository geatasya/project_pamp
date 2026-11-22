import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui_kit.dart';
import '../domain/entities/pocket_transaction_entity.dart';
import '../domain/entities/savings_pocket_entity.dart';
import 'providers/savings_provider.dart';

class SavingsPage extends StatefulWidget {
  const SavingsPage({super.key});

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SavingsProvider>().fetchData();
    });
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ============================================================
  // TAMBAH / EDIT KANTONG TABUNGAN
  // ============================================================

  Future<void> _pocketDialog({SavingsPocketEntity? pocket}) async {
    final nameController = TextEditingController(
      text: pocket?.name ?? '',
    );
    final targetController = TextEditingController(
      text: pocket != null ? pocket.targetAmount.toInt().toString() : '',
    );
    final formKey = GlobalKey<FormState>();

    try {
      final result = await showDialog<bool>(
        context: context,
        useRootNavigator: false,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(pocket == null ? 'Buat tabungan baru' : 'Edit tabungan'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama tabungan',
                        hintText: 'Contoh: Tiket BigBang Fest',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama tabungan wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: targetController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Target tabungan (Rp)',
                        hintText: 'Contoh: 1500000',
                      ),
                      validator: (value) {
                        final val = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
                        if (val == null || val <= 0) {
                          return 'Target harus lebih dari 0';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    Navigator.of(dialogContext).pop(true);
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      );

      if (!mounted || result != true) return;

      final p = context.read<SavingsProvider>();
      final target = double.parse(targetController.text.trim().replaceAll(',', '.'));

      bool success;
      if (pocket == null) {
        success = await p.createNewPocket(
          name: nameController.text.trim(),
          targetAmount: target,
        );
      } else {
        success = await p.editPocket(
          id: pocket.id,
          name: nameController.text.trim(),
          targetAmount: target,
        );
      }

      if (!mounted) return;

      if (success) {
        _message(pocket == null ? 'Tabungan berhasil dibuat' : 'Tabungan berhasil diperbarui');
      } else {
        _message(p.error ?? 'Gagal menyimpan tabungan');
      }
    } finally {
      nameController.dispose();
      targetController.dispose();
    }
  }

  // ============================================================
  // HAPUS KANTONG TABUNGAN
  // ============================================================

  Future<void> _deletePocket(SavingsPocketEntity pocket) async {
    final p = context.read<SavingsProvider>();
    final hasTransactions = p.transactions.any((t) => t.pocketId == pocket.id);

    if (hasTransactions) {
      _message('Tabungan tidak dapat dihapus karena memiliki riwayat transaksi.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Hapus tabungan?'),
          content: Text('Tabungan "${pocket.name}" akan dihapus secara permanen.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    final success = await p.removePocket(pocket.id);
    if (!mounted) return;

    if (success) {
      _message('Tabungan berhasil dihapus');
    } else {
      _message(p.error ?? 'Gagal menghapus tabungan');
    }
  }

  // ============================================================
  // DEPOSIT / WITHDRAW MANUAL (FEATURE 3)
  // ============================================================

  Future<void> _transactionDialog({SavingsPocketEntity? pocket}) async {
    final p = context.read<SavingsProvider>();
    if (p.pockets.isEmpty) {
      _message('Buat tabungan terlebih dahulu.');
      return;
    }

    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    String selectedPocketId = pocket?.id ?? p.pockets.first.id;
    String type = 'deposit';
    DateTime date = DateTime.now();

    try {
      final result = await showDialog<bool>(
        context: context,
        useRootNavigator: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (ctx, setDialogState) {
              return AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                title: const Text('Catat transaksi kas'),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedPocketId,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Pilih tabungan'),
                          items: p.pockets.map((item) {
                            return DropdownMenuItem<String>(
                              value: item.id,
                              child: Text(
                                '${item.name} (${_currency.format(item.currentAmount)})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedPocketId = val);
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: type,
                          decoration: const InputDecoration(labelText: 'Jenis transaksi'),
                          items: const [
                            DropdownMenuItem(value: 'deposit', child: Text('Setoran (Menabung)')),
                            DropdownMenuItem(value: 'withdraw', child: Text('Penarikan (Keluar)')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => type = val);
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Nominal (Rp)',
                            hintText: 'Contoh: 100000',
                          ),
                          validator: (value) {
                            final amount = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
                            if (amount == null || amount <= 0) {
                              return 'Nominal harus lebih dari 0';
                            }
                            final selected = p.pockets.firstWhere((item) => item.id == selectedPocketId);
                            if (type == 'withdraw' && amount > selected.currentAmount) {
                              return 'Saldo tabungan tidak mencukupi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Tanggal transaksi'),
                          subtitle: Text(DateFormat('dd MMM yyyy', 'id_ID').format(date)),
                          trailing: const Icon(Icons.calendar_month_outlined),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: dialogContext,
                              useRootNavigator: false,
                              initialDate: date,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setDialogState(() => date = picked);
                            }
                          },
                        ),
                        TextFormField(
                          controller: notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Catatan (opsional)',
                            hintText: 'Contoh: Menabung dari uang saku',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Batal'),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (formKey.currentState?.validate() ?? false) {
                        Navigator.of(dialogContext).pop(true);
                      }
                    },
                    child: const Text('Simpan'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (!mounted || result != true) return;

      final amount = double.parse(amountController.text.trim().replaceAll(',', '.'));
      final success = await p.recordTransaction(
        pocketId: selectedPocketId,
        type: type,
        amount: amount,
        date: date,
        notes: notesController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        _message(type == 'deposit' ? 'Setoran tabungan berhasil dicatat' : 'Penarikan tabungan berhasil dicatat');
      } else {
        _message(p.error ?? 'Gagal mencatat transaksi');
      }
    } finally {
      amountController.dispose();
      notesController.dispose();
    }
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SavingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Tabungan Saya'),
        actions: [
          IconButton(
            onPressed: p.fetchData,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Muat ulang',
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _pocketDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Buat Tabungan'),
      ),
      body: p.isLoading && p.pockets.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : p.error != null && p.pockets.isEmpty
              ? _errorView(p)
              : RefreshIndicator(
                  onRefresh: p.fetchData,
                  color: AppColors.ink,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    children: [
                      _summaryCard(p),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Kantong Tabungan',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _transactionDialog(),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Transaksi'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (p.pockets.isEmpty)
                        _emptyCard(
                          'Belum ada tabungan',
                          'Buat kantong tabungan pertamamu untuk mulai mengumpulkan uang sesuai target.',
                        )
                      else
                        ...p.pockets.map(_pocketCard),
                      const SizedBox(height: 22),
                      const Text(
                        'Riwayat Transaksi Keuangan',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      if (p.transactions.isEmpty)
                        _emptyCard(
                          'Belum ada transaksi',
                          'Setoran, penarikan, dan pengeluaran event akan ditampilkan di sini.',
                        )
                      else
                        ...p.transactions.take(40).map(_transactionTile),
                    ],
                  ),
                ),
    );
  }

  Widget _errorView(SavingsProvider p) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.red),
            const SizedBox(height: 12),
            const Text(
              'Data tabungan belum dapat dimuat',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              p.error ?? 'Terjadi kesalahan sistem',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: p.fetchData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(SavingsProvider p) {
    final progress = p.totalTarget <= 0 ? 0.0 : (p.totalBalance / p.totalTarget).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL TABUNGAN',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currency.format(p.totalBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Target keseluruhan ${_currency.format(p.totalTarget)} (${(progress * 100).toStringAsFixed(1)}% tercapai)',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  'Total Setoran',
                  p.totalDeposit,
                  Icons.south_west_rounded,
                  AppColors.greenBg,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryItem(
                  'Total Penarikan & Event',
                  p.totalWithdraw,
                  Icons.north_east_rounded,
                  AppColors.redBg,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, double value, IconData icon, Color background) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: AppColors.ink),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                ),
                Text(
                  _currency.format(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pocketCard(SavingsPocketEntity pocket) {
    final balance = pocket.currentAmount;
    final target = pocket.targetAmount;
    final progress = pocket.progress;
    final completed = pocket.isCompleted;

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    pocket.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                if (completed)
                  const Pill(
                    'TERCAPAI',
                    bg: AppColors.greenBg,
                    fg: AppColors.green,
                    fontSize: 10,
                  ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'deposit') {
                      _transactionDialog(pocket: pocket);
                    } else if (value == 'edit') {
                      _pocketDialog(pocket: pocket);
                    } else if (value == 'delete') {
                      _deletePocket(pocket);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'deposit', child: Text('Catat transaksi')),
                    PopupMenuItem(value: 'edit', child: Text('Edit tabungan')),
                    PopupMenuItem(value: 'delete', child: Text('Hapus tabungan')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${_currency.format(balance)} / ${_currency.format(target)}',
              style: const TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.subtle,
                valueColor: AlwaysStoppedAnimation<Color>(completed ? AppColors.green : AppColors.purple),
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(1)}% tercapai',
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                const Spacer(),
                Text(
                  _currency.format((target - balance).clamp(0.0, double.infinity)),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _transactionDialog(pocket: pocket),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Transaksi'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TRANSACTION TILE (DUAL SOURCE: MANUAL & EVENT)
  // ============================================================

  Widget _transactionTile(PocketTransactionEntity tx) {
    final isDeposit = tx.isDeposit;
    final isEvent = tx.isFromEvent;

    final dateStr = DateFormat('dd MMM yyyy', 'id_ID').format(tx.transactionDate);
    final notes = tx.notes?.trim();

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: isEvent
              ? AppColors.purpleBg
              : (isDeposit ? AppColors.greenBg : AppColors.redBg),
          child: Icon(
            isEvent
                ? Icons.receipt_long_rounded
                : (isDeposit ? Icons.south_west_rounded : Icons.north_east_rounded),
            color: isEvent
                ? AppColors.purple
                : (isDeposit ? AppColors.green : AppColors.red),
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                isEvent
                    ? (tx.eventName ?? 'Pengeluaran Event')
                    : (tx.pocketName ?? 'Tabungan'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (isEvent) ...[
              const SizedBox(width: 6),
              const Pill(
                'EVENT',
                bg: AppColors.purpleBg,
                fg: AppColors.purple,
                fontSize: 9,
              ),
            ],
          ],
        ),
        subtitle: Text(
          [
            dateStr,
            if (isEvent) tx.pocketName ?? 'Pocket Tabungan',
            if (notes != null && notes.isNotEmpty) notes,
          ].join(' • '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        trailing: Text(
          '${isDeposit ? '+' : '-'}${_currency.format(tx.amount)}',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
            color: isDeposit ? AppColors.green : AppColors.red,
          ),
        ),
      ),
    );
  }

  Widget _emptyCard(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.savings_outlined, size: 36, color: AppColors.muted),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
