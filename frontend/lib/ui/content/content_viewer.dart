import 'package:flutter/material.dart';
import 'package:frontend/models/content.dart';
import 'article_view.dart';
import 'quiz_view.dart';
import 'guide_view.dart';

class ContentViewer extends StatelessWidget {
  final Content content;

  const ContentViewer({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    // Display different UI based on content type
    switch (content.type) {
      case 'article':
        return ArticleView(content: content);
      case 'quiz':
        return QuizView(content: content);
      case 'guide':
        return GuideView(content: content);
      default:
        return ArticleView(content: content); // Default fallback
    }
  }
}
