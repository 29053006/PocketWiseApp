class User {
  final int? id;
  final String name;
  final String? avatar;

  User({this.id, required this.name, this.avatar});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
    };
  }
}
