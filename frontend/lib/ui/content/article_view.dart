import 'package:flutter/material.dart';
import 'package:frontend/models/content.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ArticleView extends StatelessWidget {
  final Content content;

  const ArticleView({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text(content.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: MarkdownBody(
          data: content.content,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(color: Colors.white, fontSize: 16),
            h1: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            h2: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            h3: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            code: TextStyle(backgroundColor: Colors.grey[800], color: Colors.white),
            blockquote: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic),
          ),
        ),
      ),
    );
  }
}