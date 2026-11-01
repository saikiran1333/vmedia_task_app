import '../domain/entities/hello_entity.dart';

class HelloModel {
  final int id;
  final int userId;
  final String title;
  final String body;

  const HelloModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  factory HelloModel.fromJson(Map<String, dynamic> json) {
    return HelloModel(
      id: json['id'] as int? ?? 0,
      userId: json['userId'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
    };
  }

  HelloEntity toEntity() {
    return HelloEntity(
      id: id,
      userId: userId,
      title: title,
      body: body,
    );
  }
}
