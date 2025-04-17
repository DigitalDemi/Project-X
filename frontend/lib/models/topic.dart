class Topic {
  final String id;
  final String subject;
  final String name;
  final String status;
  final String stage;
  final DateTime createdAt;
  final DateTime nextReview;
  final List<Map<String, dynamic>> reviewHistory;

  Topic({
    required this.id,
    required this.subject,
    required this.name,
    required this.status,
    required this.stage,
    required this.createdAt,
    required this.nextReview,
    this.reviewHistory = const [],
  });

  factory Topic.fromMap(Map<String, dynamic> map) {
    return Topic(
      id: map['id'],
      subject: map['subject'],
      name: map['name'],
      status: map['status'],
      stage: map['stage'],
      createdAt: DateTime.parse(map['created_at']),
      nextReview: DateTime.parse(map['next_review']),
      reviewHistory: List<Map<String, dynamic>>.from(map['review_history'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'name': name,
      'status': status,
      'stage': stage,
      'created_at': createdAt.toIso8601String(),
      'next_review': nextReview.toIso8601String(),
      'review_history': reviewHistory,
    };
  }
}