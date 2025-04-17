import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/content.dart';
import '../../services/content_service.dart';
import 'content_viewer.dart';

class ContentList extends StatelessWidget {
  final String topicId;
  
  const ContentList({
    super.key,
    required this.topicId,
  });
  
  @override
  Widget build(BuildContext context) {
    return Consumer<ContentService>(
      builder: (context, contentService, child) {
        return FutureBuilder<List<Content>>(
          future: contentService.getContentByTopic(topicId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurpleAccent),
                ),
              );
            } else if (snapshot.hasError) {
              return Text(
                'Error loading content: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[800]!, width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.article_outlined,
                      size: 40,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No learning resources available for this topic yet',
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final contentList = snapshot.data!;
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.menu_book,
                        color: Colors.deepPurpleAccent,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Learning Resources',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: contentList.length,
                    separatorBuilder: (context, index) => Divider(
                      color: Colors.grey[800],
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final content = contentList[index];
                      return ContentListItem(content: content);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class ContentListItem extends StatelessWidget {
  final Content content;

  const ContentListItem({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ContentViewer(content: content),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            _buildContentTypeIcon(content.type),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getContentTypeLabel(content.type),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[600],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentTypeIcon(String type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'article':
        iconData = Icons.article;
        iconColor = Colors.blue;
        break;
      case 'quiz':
        iconData = Icons.quiz;
        iconColor = Colors.orange;
        break;
      case 'guide':
        iconData = Icons.book;
        iconColor = Colors.green;
        break;
      default:
        iconData = Icons.description;
        iconColor = Colors.purple;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  String _getContentTypeLabel(String type) {
    switch (type) {
      case 'article':
        return 'Article';
      case 'quiz':
        return 'Self-Assessment Quiz';
      case 'guide':
        return 'Interactive Guide';
      default:
        return 'Resource';
    }
  }
}