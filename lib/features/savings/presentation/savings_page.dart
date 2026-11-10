import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';

class SavingsPage extends StatefulWidget {
  const SavingsPage({super.key});

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  List<Map<String, dynamic>> _pockets = [];
  List<Map<String, dynamic>> _transactions = [];

  String? get _userId => _supabase.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ============================================================
  // DATA
  // ============================================================

  Future<void> _loadData({bool showLoading = false}) async {
    final userId = _userId;

    if (userId == null) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _refreshing = false;
        _error = 'Sesi login tidak ditemukan. Silakan login kembali.';
      });
      return;
    }

    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else if (mounted) {
      setState(() {
        _refreshing = true;
        _error = null;
      });
    }

    try {
      final pocketResponse = await _supabase
          .from('savings_pockets')
          .select()
          .eq('user_id', userId)
          .order('created_at');

      final transactionResponse = await _supabase
          .from('savings_pocket_transactions')
          .select()
          .eq('user_id', userId)
          .order('transaction_date', ascending: false)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _pockets = List<Map<String, dynamic>>.from(pocketResponse);
        _transactions =
        List<Map<String, dynamic>>.from(transactionResponse);

        _loading = false;
        _refreshing = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _refreshing = false;
        _error = e.toString();
      });
    }
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _balance(Map<String, dynamic> pocket) {
    return _asDouble(pocket['current_amount']);
  }

  double _target(Map<String, dynamic> pocket) {
    return _asDouble(pocket['target_amount']);
  }

  double get _totalBalance {
    return _pockets.fold<double>(
      0,
          (sum, pocket) => sum + _balance(pocket),
    );
  }

  double get _totalTarget {
    return _pockets.fold<double>(
      0,
          (sum, pocket) => sum + _target(pocket),
    );
  }

  double get _totalDeposit {
    return _transactions
        .where((item) => item['transaction_type'] == 'deposit')
        .fold<double>(
      0,
          (sum, item) => sum + _asDouble(item['amount']),
    );
  }

  double get _totalWithdraw {
    return _transactions
        .where((item) => item['transaction_type'] == 'withdraw')
        .fold<double>(
      0,
          (sum, item) => sum + _asDouble(item['amount']),
    );
  }

  double _progress(Map<String, dynamic> pocket) {
    final target = _target(pocket);

    if (target <= 0) return 0;

    return (_balance(pocket) / target).clamp(0.0, 1.0);
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  // ============================================================
  // TAMBAH / EDIT KANTONG TABUNGAN
  // ============================================================

  Future<void> _pocketDialog({
    Map<String, dynamic>? pocket,
  }) async {
    final nameController = TextEditingController(
      text: pocket?['name']?.toString() ?? '',
    );

    final targetController = TextEditingController(
      text: pocket?['target_amount']?.toString() ?? '',
    );

    final formKey = GlobalKey<FormState>();

    try {
      final result = await showDialog<bool>(
        context: context,
        useRootNavigator: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(
              pocket == null
                  ? 'Buat tabungan baru'
                  : 'Edit tabungan',
            ),
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
                        hintText: 'Contoh: Liburan, Laptop, Dana Darurat',
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
                      keyboardType:
                      const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Target tabungan (Rp)',
                        hintText: 'Contoh: 5000000',
                      ),
                      validator: (value) {
                        final amount = double.tryParse(
                          (value ?? '').trim().replaceAll(',', '.'),
                        );

                        if (amount == null || amount <= 0) {
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
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
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

      final userId = _userId;

      if (userId == null) {
        _message('Sesi login tidak ditemukan.');
        return;
      }

      final target = double.parse(
        targetController.text.trim().replaceAll(',', '.'),
      );

      if (pocket == null) {
        await _supabase.from('savings_pockets').insert({
          'user_id': userId,
          'name': nameController.text.trim(),
          'target_amount': target,
          'current_amount': 0,
        });
      } else {
        await _supabase
            .from('savings_pockets')
            .update({
          'name': nameController.text.trim(),
          'target_amount': target,
        })
            .eq('id', pocket['id'])
            .eq('user_id', userId);
      }

      if (!mounted) return;

      await _loadData();

      if (!mounted) return;

      _message(
        pocket == null
            ? 'Tabungan berhasil dibuat'
            : 'Tabungan berhasil diperbarui',
      );
    } catch (e) {
      if (!mounted) return;

      _message('Gagal menyimpan tabungan: $e');
    } finally {
      nameController.dispose();
      targetController.dispose();
    }
  }

  // ============================================================
  // HAPUS KANTONG TABUNGAN
  // ============================================================

  Future<void> _deletePocket(
      Map<String, dynamic> pocket,
      ) async {
    final pocketId = pocket['id'].toString();

    final hasTransactions = _transactions.any(
          (item) => item['pocket_id'].toString() == pocketId,
    );

    if (hasTransactions) {
      _message(
        'Tabungan tidak dapat dihapus karena memiliki riwayat transaksi.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus tabungan?'),
          content: Text(
            'Tabungan "${pocket['name']}" akan dihapus secara permanen.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    final userId = _userId;

    if (userId == null) {
      _message('Sesi login tidak ditemukan.');
      return;
    }

    try {
      await _supabase
          .from('savings_pockets')
          .delete()
          .eq('id', pocket['id'])
          .eq('user_id', userId);

      if (!mounted) return;

      await _loadData();

      if (!mounted) return;

      _message('Tabungan berhasil dihapus');
    } catch (e) {
      if (!mounted) return;

      _message('Gagal menghapus tabungan: $e');
    }
  }

  // ============================================================
  // DEPOSIT / WITHDRAW
  // ============================================================

  Future<void> _transactionDialog({
    Map<String, dynamic>? pocket,
  }) async {
    if (_pockets.isEmpty) {
      _message('Buat tabungan terlebih dahulu.');
      return;
    }

    final formKey = GlobalKey<FormState>();

    final amountController = TextEditingController();
    final notesController = TextEditingController();

    String selectedPocketId =
        pocket?['id']?.toString() ?? _pockets.first['id'].toString();

    String type = 'deposit';

    DateTime date = DateTime.now();

    try {
      final result = await showDialog<bool>(
        context: context,
        useRootNavigator: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                title: const Text('Catat transaksi tabungan'),
                content: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: type,
                          decoration: const InputDecoration(
                            labelText: 'Jenis transaksi',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'deposit',
                              child: Text('Setor tabungan'),
                            ),
                            DropdownMenuItem(
                              value: 'withdraw',
                              child: Text('Tarik tabungan'),
                            ),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              type = value ?? 'deposit';
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: selectedPocketId,
                          decoration: const InputDecoration(
                            labelText: 'Pilih tabungan',
                          ),
                          items: _pockets.map((item) {
                            return DropdownMenuItem<String>(
                              value: item['id'].toString(),
                              child: Text(item['name'].toString()),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) return;

                            setDialogState(() {
                              selectedPocketId = value;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: amountController,
                          keyboardType:
                          const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Nominal (Rp)',
                            hintText: 'Contoh: 100000',
                          ),
                          validator: (value) {
                            final amount = double.tryParse(
                              (value ?? '').trim().replaceAll(',', '.'),
                            );

                            if (amount == null || amount <= 0) {
                              return 'Nominal harus lebih dari 0';
                            }

                            final selected = _pockets.firstWhere(
                                  (item) =>
                              item['id'].toString() ==
                                  selectedPocketId,
                            );

                            if (type == 'withdraw' &&
                                amount > _balance(selected)) {
                              return 'Saldo tabungan tidak mencukupi';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Tanggal transaksi'),
                          subtitle: Text(
                            DateFormat(
                              'dd MMM yyyy',
                              'id_ID',
                            ).format(date),
                          ),
                          trailing: const Icon(
                            Icons.calendar_month_outlined,
                          ),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: dialogContext,
                              useRootNavigator: false,
                              initialDate: date,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );

                            if (picked != null &&
                                dialogContext.mounted) {
                              setDialogState(() {
                                date = picked;
                              });
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
                    onPressed: () {
                      Navigator.of(dialogContext).pop(false);
                    },
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

      final userId = _userId;

      if (userId == null) {
        _message('Sesi login tidak ditemukan.');
        return;
      }

      final amount = double.parse(
        amountController.text.trim().replaceAll(',', '.'),
      );

      final selectedPocket = _pockets.firstWhere(
            (item) => item['id'].toString() == selectedPocketId,
      );

      final currentBalance = _balance(selectedPocket);

      // Validasi saldo dilakukan sekali lagi sebelum menyimpan.
      if (type == 'withdraw' && amount > currentBalance) {
        _message('Saldo tabungan tidak mencukupi.');
        return;
      }

      final newBalance = type == 'deposit'
          ? currentBalance + amount
          : currentBalance - amount;

      // Simpan transaksi.
      await _supabase.from('savings_pocket_transactions').insert({
        'pocket_id': selectedPocketId,
        'user_id': userId,
        'transaction_type': type,
        'amount': amount,
        'notes': notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
        'transaction_date': DateFormat('yyyy-MM-dd').format(date),
      });

      // Perbarui saldo kantong tabungan.
      await _supabase
          .from('savings_pockets')
          .update({
        'current_amount': newBalance,
      })
          .eq('id', selectedPocketId)
          .eq('user_id', userId);

      if (!mounted) return;

      await _loadData();

      if (!mounted) return;

      _message(
        type == 'deposit'
            ? 'Setoran tabungan berhasil dicatat'
            : 'Penarikan tabungan berhasil dicatat',
      );
    } catch (e) {
      if (!mounted) return;

      _message('Gagal mencatat transaksi: $e');
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Tabungan Saya'),
        actions: [
          IconButton(
            onPressed: () => _loadData(),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pocketDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Buat Tabungan'),
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _error != null
          ? _errorView()
          : RefreshIndicator(
        onRefresh: () => _loadData(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            16,
            12,
            16,
            100,
          ),
          children: [
            if (_refreshing)
              const LinearProgressIndicator(),

            _summaryCard(),

            const SizedBox(height: 22),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Kantong Tabungan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
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

            if (_pockets.isEmpty)
              _emptyCard(
                'Belum ada tabungan',
                'Buat kantong tabungan pertamamu untuk mulai '
                    'mengumpulkan uang sesuai target.',
              )
            else
              ..._pockets.map(_pocketCard),

            const SizedBox(height: 22),

            const Text(
              'Riwayat Transaksi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 10),

            if (_transactions.isEmpty)
              _emptyCard(
                'Belum ada transaksi',
                'Setoran dan penarikan tabungan akan '
                    'ditampilkan di sini.',
              )
            else
              ..._transactions
                  .take(30)
                  .map(_transactionTile),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR VIEW
  // ============================================================

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppColors.red,
            ),
            const SizedBox(height: 12),
            const Text(
              'Data tabungan belum dapat dimuat',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => _loadData(showLoading: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _summaryCard() {
    final progress = _totalTarget <= 0
        ? 0.0
        : (_totalBalance / _totalTarget).clamp(0.0, 1.0);

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
            _currency.format(_totalBalance),
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
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Target keseluruhan ${_currency.format(_totalTarget)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  'Total Setoran',
                  _totalDeposit,
                  Icons.south_west_rounded,
                  AppColors.greenBg,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryItem(
                  'Total Penarikan',
                  _totalWithdraw,
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

  Widget _summaryItem(
      String label,
      double value,
      IconData icon,
      Color background,
      ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .10),
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
            child: Icon(
              icon,
              size: 16,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
                Text(
                  _currency.format(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // POCKET CARD
  // ============================================================

  Widget _pocketCard(Map<String, dynamic> pocket) {
    final balance = _balance(pocket);
    final target = _target(pocket);
    final progress = _progress(pocket);

    final completed = target > 0 && balance >= target;

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: AppColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.purpleBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.savings_rounded,
                    color: AppColors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pocket['name'].toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        completed ? 'Target tercapai!' : 'Sedang menabung',
                        style: TextStyle(
                          color: completed
                              ? AppColors.green
                              : AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
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
                    PopupMenuItem(
                      value: 'deposit',
                      child: Text('Catat transaksi'),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit tabungan'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Hapus tabungan'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              _currency.format(balance),
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Target ${_currency.format(target)}',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  completed ? AppColors.green : AppColors.purple,
                ),
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(1)}% tercapai',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Text(
                  _currency.format(
                    (target - balance).clamp(0.0, double.infinity),
                  ),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _transactionDialog(pocket: pocket);
                    },
                    icon: const Icon(
                      Icons.add_rounded,
                      size: 18,
                    ),
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
  // TRANSACTION TILE
  // ============================================================

  Widget _transactionTile(
      Map<String, dynamic> transaction,
      ) {
    final isDeposit =
        transaction['transaction_type'] == 'deposit';

    Map<String, dynamic>? pocket;

    for (final item in _pockets) {
      if (item['id'].toString() ==
          transaction['pocket_id'].toString()) {
        pocket = item;
        break;
      }
    }

    final date = DateTime.tryParse(
      transaction['transaction_date'].toString(),
    );

    final notes = transaction['notes']?.toString();

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: AppColors.border,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 5,
        ),
        leading: CircleAvatar(
          backgroundColor: isDeposit
              ? AppColors.greenBg
              : AppColors.redBg,
          child: Icon(
            isDeposit
                ? Icons.south_west_rounded
                : Icons.north_east_rounded,
            color: isDeposit
                ? AppColors.green
                : AppColors.red,
          ),
        ),
        title: Text(
          pocket?['name']?.toString() ?? 'Tabungan',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          [
            if (date != null)
              DateFormat('dd MMM yyyy', 'id_ID').format(date),
            if (notes != null && notes.isNotEmpty) notes,
          ].join(' • '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.muted,
          ),
        ),
        trailing: Text(
          '${isDeposit ? '+' : '-'}'
              '${_currency.format(_asDouble(transaction['amount']))}',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDeposit
                ? AppColors.green
                : AppColors.red,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyCard(
      String title,
      String subtitle,
      ) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.savings_outlined,
            size: 36,
            color: AppColors.muted,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}