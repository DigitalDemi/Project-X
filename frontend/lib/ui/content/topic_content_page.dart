import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/content.dart';
import 'package:frontend/services/content_service.dart';
import 'package:frontend/models/topic.dart';
import 'content_viewer.dart';

class TopicContentPage extends StatelessWidget {
  final Topic topic;

  const TopicContentPage({
    super.key,
    required this.topic,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text('${topic.subject} - ${topic.name}'),
        elevation: 0,
      ),
      body: FutureBuilder<List<Content>>(
        future: Provider.of<ContentService>(context, listen: false)
            .getContentByTopic(topic.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurpleAccent),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading content: ${snapshot.error}',
                    style: TextStyle(color: Colors.red[400]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final contentList = snapshot.data ?? [];

          if (contentList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book, size: 48, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text(
                    'No learning resources available for this topic yet',
                    style: TextStyle(color: Colors.grey[400]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Group content by type
          final Map<String, List<Content>> contentByType = {
            'article': [],
            'quiz': [],
            'guide': [],
          };

          for (final content in contentList) {
            if (contentByType.containsKey(content.type)) {
              contentByType[content.type]!.add(content);
            } else {
              contentByType.putIfAbsent('other', () => []).add(content);
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopicHeader(topic),
                const SizedBox(height: 24),
                
                ...contentByType.entries.map((entry) {
                  return entry.value.isNotEmpty 
                      ? _buildContentTypeSection(entry.key, entry.value)
                      : const SizedBox.shrink();
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopicHeader(Topic topic) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStageIndicator(topic.stage),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      topic.subject,
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Learning Resources',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageIndicator(String stage) {
    Color color;
    String label;

    switch (stage) {
      case 'first_time':
        color = Colors.red;
        label = 'New';
        break;
      case 'early_stage':
        color = Colors.orange;
        label = 'Learning';
        break;
      case 'mid_stage':
        color = Colors.yellow;
        label = 'Practicing';
        break;
      case 'late_stage':
        color = Colors.lightGreen;
        label = 'Reviewing';
        break;
      case 'mastered':
        color = Colors.green;
        label = 'Mastered';
        break;
      default:
        color = Colors.blue;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildContentTypeSection(String contentType, List<Content> contentList) {
    String title;
    IconData iconData;
    Color color;

    switch (contentType) {
      case 'article':
        title = 'Articles';
        iconData = Icons.article;
        color = Colors.blue;
        break;
      case 'quiz':
        title = 'Quizzes';
        iconData = Icons.quiz;
        color = Colors.orange;
        break;
      case 'guide':
        title = 'Guides';
        iconData = Icons.book;
        color = Colors.green;
        break;
      default:
        title = 'Other Resources';
        iconData = Icons.description;
        color = Colors.purple;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Icon(iconData, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: contentList.length,
          itemBuilder: (context, index) {
            final content = contentList[index];
            return Card(
              color: Colors.grey[900],
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: ListTile(
                title: Text(
                  content.title,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Created: ${_formatDate(content.createdAt)}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                leading: Icon(iconData, color: color),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ContentViewer(content: content),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}