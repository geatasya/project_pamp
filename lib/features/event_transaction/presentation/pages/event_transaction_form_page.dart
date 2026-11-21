import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../event/domain/event_entity.dart';
import '../../domain/entities/event_transaction_entity.dart';
import '../providers/event_transaction_provider.dart';

class EventTransactionFormPage extends StatefulWidget {
  final EventTransactionEntity? editTransaction;

  const EventTransactionFormPage({
    super.key,
    this.editTransaction,
  });

  @override
  State<EventTransactionFormPage> createState() => _EventTransactionFormPageState();
}

class _EventTransactionFormPageState extends State<EventTransactionFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  String? _selectedEventId;
  String? _selectedPocketId;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  bool get _isEdit => widget.editTransaction != null;

  @override
  void initState() {
    super.initState();
    final edit = widget.editTransaction;
    _amountController = TextEditingController(
      text: edit != null ? edit.amount.toInt().toString() : '',
    );
    _notesController = TextEditingController(
      text: edit?.notes ?? '',
    );

    if (edit != null) {
      _selectedEventId = edit.eventId;
      _selectedPocketId = edit.pocketId;
      _selectedDate = edit.transactionDate;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<EventTransactionProvider>();
      p.fetchAll().then((_) {
        if (!mounted) return;
        // Jika mode tambah dan belum terpilih, pasang default jika ada
        if (!_isEdit) {
          if (_selectedPocketId == null && p.pockets.isNotEmpty) {
            setState(() {
              _selectedPocketId = p.pockets.first['id']?.toString();
            });
          }
          if (_selectedEventId == null && p.eligibleEvents.isNotEmpty) {
            setState(() {
              _selectedEventId = p.eligibleEvents.first.id;
            });
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatRupiah(double v) => NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(v);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedEventId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih event konser terlebih dahulu.')),
      );
      return;
    }

    if (_selectedPocketId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih Pocket / Kas tabungan terlebih dahulu.')),
      );
      return;
    }

    final p = context.read<EventTransactionProvider>();
    final amount = double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ?? 0;

    // Cari info event dan pocket untuk konfirmasi
    EventEntity? chosenEvent;
    for (final e in p.eligibleEvents) {
      if (e.id == _selectedEventId) {
        chosenEvent = e;
        break;
      }
    }

    Map<String, dynamic>? chosenPocket;
    for (final pk in p.pockets) {
      if (pk['id']?.toString() == _selectedPocketId) {
        chosenPocket = pk;
        break;
      }
    }

    final pocketBalance = (chosenPocket?['current_amount'] is num)
        ? (chosenPocket!['current_amount'] as num).toDouble()
        : double.tryParse(chosenPocket?['current_amount']?.toString() ?? '0') ?? 0.0;

    // Cek saldo jika bukan edit di pocket yang sama dengan nominal lebih kecil
    if (!_isEdit && amount > pocketBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saldo pocket tidak mencukupi! Saldo saat ini: ${_formatRupiah(pocketBalance)}',
          ),
        ),
      );
      return;
    }

    // Tampilkan Dialog Ringkasan Konfirmasi
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(_isEdit ? 'Konfirmasi Perubahan' : 'Konfirmasi Pengeluaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Periksa kembali rincian transaksi sebelum disimpan:',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            _summaryRow('Event', chosenEvent?.name ?? widget.editTransaction?.eventName ?? '-'),
            const SizedBox(height: 8),
            _summaryRow('Nominal', _formatRupiah(amount), highlight: true),
            const SizedBox(height: 8),
            _summaryRow('Sumber Kas', chosenPocket?['name'] ?? '-'),
            const SizedBox(height: 8),
            _summaryRow('Tanggal', DateFormat('dd MMM yyyy', 'id_ID').format(_selectedDate)),
            if (_notesController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              _summaryRow('Catatan', _notesController.text.trim()),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Periksa Lagi'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_isEdit ? 'Simpan Perubahan' : 'Konfirmasi & Potong Saldo'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);

    bool ok;
    if (_isEdit) {
      ok = await p.updateTransaction(
        transactionId: widget.editTransaction!.id,
        newEventId: _selectedEventId!,
        newPocketId: _selectedPocketId!,
        newAmount: amount,
        newTransactionDate: _selectedDate,
        newNotes: _notesController.text.trim(),
      );
    } else {
      ok = await p.createTransaction(
        eventId: _selectedEventId!,
        pocketId: _selectedPocketId!,
        amount: amount,
        transactionDate: _selectedDate,
        notes: _notesController.text.trim(),
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Transaksi pengeluaran event berhasil diperbarui.'
                : 'Transaksi pengeluaran event berhasil dicatat & saldo pocket berkurang.',
          ),
        ),
      );
      // Jika edit dari detail, pop form dan beri sinyal refresh
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(p.error ?? 'Gagal menyimpan transaksi'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  Widget _summaryRow(String label, String value, {bool highlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: highlight ? AppColors.red : AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<EventTransactionProvider>();
    final eligibleEvents = p.eligibleEvents;
    final pockets = p.pockets;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Transaksi Event' : 'Catat Pengeluaran Event'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Banner Informasi Syarat Event
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.purpleBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.purple.withAlpha(50)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppColors.purple, size: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Hanya event yang telah masuk Wishlist dan berstatus "Sudah Dikunjungi" yang dapat dicatat pengeluarannya.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.purple,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 1. Pilih Event Konser
                const Text(
                  '1. Pilih Event Konser',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                if (eligibleEvents.isEmpty && !_isEdit)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Belum ada event yang memenuhi syarat.',
                          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.red),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Buka menu "Jadwal Konser", tambahkan event ke Wishlist, lalu tandai sebagai "Sudah Dikunjungi" terlebih dahulu.',
                          style: TextStyle(fontSize: 12, color: AppColors.muted),
                        ),
                      ],
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _selectedEventId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      hintText: 'Pilih konser yang dikunjungi',
                      prefixIcon: Icon(Icons.festival_outlined, color: AppColors.muted),
                    ),
                    items: [
                      for (final ev in eligibleEvents)
                        DropdownMenuItem<String>(
                          value: ev.id,
                          child: Text(
                            '${ev.name} • ${ev.location}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                          ),
                        ),
                      // Jika mode edit dan event saat ini belum ada di list
                      if (_isEdit &&
                          _selectedEventId != null &&
                          !eligibleEvents.any((e) => e.id == _selectedEventId))
                        DropdownMenuItem<String>(
                          value: _selectedEventId,
                          child: Text(
                            widget.editTransaction?.eventName ?? 'Event Terpilih',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                          ),
                        ),
                    ],
                    onChanged: (val) => setState(() => _selectedEventId = val),
                    validator: (v) => v == null ? 'Pilih salah satu event' : null,
                  ),
                const SizedBox(height: 20),

                // 2. Nominal Pengeluaran Aktual
                const Text(
                  '2. Nominal Pengeluaran (Rp)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: 'Contoh: 250000',
                    prefixIcon: Icon(Icons.payments_outlined, color: AppColors.muted),
                  ),
                  validator: (v) {
                    final val = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                    if (val == null || val <= 0) {
                      return 'Nominal pengeluaran harus lebih besar dari 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 3. Pilih Kas / Pocket Tabungan
                const Text(
                  '3. Pilih Kas / Pocket Sumber Dana',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                if (pockets.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Text(
                      'Belum ada Pocket tabungan. Buat kantong tabungan di menu "Tabungan" terlebih dahulu.',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.red, fontSize: 12.5),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _selectedPocketId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      hintText: 'Pilih pocket tabungan',
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined, color: AppColors.muted),
                    ),
                    items: [
                      for (final pk in pockets)
                        DropdownMenuItem<String>(
                          value: pk['id']?.toString(),
                          child: Text(
                            '${pk['name']} (Saldo: ${_formatRupiah((pk['current_amount'] is num) ? (pk['current_amount'] as num).toDouble() : 0)})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                          ),
                        ),
                    ],
                    onChanged: (val) => setState(() => _selectedPocketId = val),
                    validator: (v) => v == null ? 'Pilih salah satu kas/pocket' : null,
                  ),
                const SizedBox(height: 20),

                // 4. Tanggal Transaksi
                const Text(
                  '4. Tanggal Transaksi',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_outlined, color: AppColors.muted),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        const Spacer(),
                        const Text(
                          'Ubah',
                          style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Catatan Tambahan
                const Text(
                  '5. Catatan Pengeluaran (Opsional)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Pembelian tiket Presale 1, Transportasi Kereta, dll.',
                  ),
                ),
                const SizedBox(height: 32),

                // Tombol Simpan
                FilledButton(
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(_isEdit ? 'Simpan Perubahan' : 'Simpan Transaksi Pengeluaran'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
