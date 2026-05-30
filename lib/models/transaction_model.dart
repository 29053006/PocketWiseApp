class Transaction {
  int? id;
  String type;
  double amount;
  String category;
  DateTime date;
  String description;

  Transaction({
    this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.date,
    required this.description,
  });

  // Convert a Transaction object into a Map object
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

  // Convert a Map object into a Transaction object
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
