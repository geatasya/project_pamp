class SavingsPocketEntity {
  final String id;
  final String userId;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime createdAt;

  const SavingsPocketEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.createdAt,
  });

  double get progress {
    if (targetAmount <= 0) return 0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  bool get isCompleted => currentAmount >= targetAmount && targetAmount > 0;
}
