import '../../domain/entities/savings_pocket_entity.dart';

class SavingsPocketModel extends SavingsPocketEntity {
  const SavingsPocketModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.targetAmount,
    required super.currentAmount,
    required super.createdAt,
  });

  factory SavingsPocketModel.fromJson(Map<String, dynamic> j) {
    final target = (j['target_amount'] is num)
        ? (j['target_amount'] as num).toDouble()
        : double.tryParse(j['target_amount']?.toString() ?? '0') ?? 0.0;

    final current = (j['current_amount'] is num)
        ? (j['current_amount'] as num).toDouble()
        : double.tryParse(j['current_amount']?.toString() ?? '0') ?? 0.0;

    DateTime crDate;
    try {
      crDate = DateTime.parse(j['created_at'].toString());
    } catch (_) {
      crDate = DateTime.now();
    }

    return SavingsPocketModel(
      id: j['id']?.toString() ?? '',
      userId: j['user_id']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      targetAmount: target,
      currentAmount: current,
      createdAt: crDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'target_amount': targetAmount,
        'current_amount': currentAmount,
      };
}
