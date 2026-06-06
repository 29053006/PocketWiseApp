class Transaction {
  final int? id;
  final String type;
  final double amount;
  final String category;
  final DateTime date;
  final String description;

  Transaction({
    this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.date,
    required this.description,
  });

  Transaction copyWith({
    int? id,
    String? type,
    double? amount,
    String? category,
    DateTime? date,
    String? description,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(), // Storing date as a string
      'description': description,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      type: map['type'],
      amount: map['amount'],
      category: map['category'],
      date: DateTime.parse(map['date']), // Parsing date from a string
      description: map['description'],
    );
  }
}
