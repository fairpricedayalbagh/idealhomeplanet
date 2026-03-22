class Holiday {
  final String id;
  final String name;
  final DateTime date;
  final bool isOptional;

  Holiday({
    required this.id,
    required this.name,
    required this.date,
    this.isOptional = false,
  });

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      id: json['id'] as String,
      name: json['name'] as String,
      date: DateTime.parse(json['date'] as String),
      isOptional: json['isOptional'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'date': date.toIso8601String().split('T')[0],
        'isOptional': isOptional,
      };
}
