class Task {
  final int? id;
  final String title;
  final String description;
  final String status;
  final int? lastModified;
  final String? sentiment;

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.status,
    this.lastModified,
    this.sentiment,
  });

  // Copy with method to update fields easily
  Task copyWith({
    int? id,
    String? title,
    String? description,
    String? status,
    int? lastModified,
    String? sentiment,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      lastModified: lastModified ?? this.lastModified,
      sentiment: sentiment ?? this.sentiment,
    );
  }

  // Convert a Task into a Map for DB storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'lastModified': lastModified ?? DateTime.now().millisecondsSinceEpoch,
      'sentiment': sentiment,
    };
  }

  // Create a Task from a Map
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      status: map['status'],
      lastModified: map['lastModified'],
      sentiment: map['sentiment'],
    );
  }

  // ===== JSON serialization for backend API =====

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'lastModified': lastModified ?? DateTime.now().millisecondsSinceEpoch,
      'sentiment': sentiment,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      lastModified: json['lastModified'],
      sentiment: json['sentiment'],
    );
  }
}
