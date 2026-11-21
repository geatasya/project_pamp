import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../domain/entities/event_transaction_entity.dart';

class EventTransactionCard extends StatelessWidget {
  final EventTransactionEntity transaction;
  final VoidCallback onTap;

  const EventTransactionCard({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  String _formatRupiah(double v) => NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(v);

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy', 'id_ID').format(transaction.transactionDate);

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.redBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.red,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.eventName ?? 'Event Konser',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 13,
                              color: AppColors.muted,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                transaction.pocketName ?? 'Pocket Tabungan',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '-${_formatRupiah(transaction.amount)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.red,
                    ),
                  ),
                ],
              ),
              if (transaction.notes != null && transaction.notes!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.subtle,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    transaction.notes!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.ink,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Pill(
                    'PENGELUARAN EVENT',
                    bg: AppColors.redBg,
                    fg: AppColors.red,
                    fontSize: 9.5,
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
