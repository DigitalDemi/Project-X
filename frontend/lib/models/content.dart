class Content {
  final String id;
  final String title;
  final String type;
  final String content;
  final DateTime createdAt;
  final List<String> relatedTopicIds;

  Content({
    required this.id,
    required this.title,
    required this.type,
    required this.content,
    required this.createdAt,
    this.relatedTopicIds = const [],
  });

  factory Content.fromMap(Map<String, dynamic> map) {
    return Content(
      id: map['id'],
      title: map['title'],
      type: map['type'],
      content: map['content'],
      createdAt: DateTime.parse(map['created_at']),
      relatedTopicIds: List<String>.from(map['related_topic_ids'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'related_topic_ids': relatedTopicIds,
    };
  }
}