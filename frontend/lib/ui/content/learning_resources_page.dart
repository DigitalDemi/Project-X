// lib/ui/content/learning_resources_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/content.dart';
import 'package:frontend/services/content_service.dart';
import 'content_viewer.dart';
import 'search_delegate.dart';

class LearningResourcesPage extends StatefulWidget {
  const LearningResourcesPage({super.key});

  @override
  State<LearningResourcesPage> createState() => _LearningResourcesPageState();
}

class _LearningResourcesPageState extends State<LearningResourcesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Fetch all content when the page loads
    final contentService = Provider.of<ContentService>(context, listen: false);
    contentService.fetchAllContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text('Learning Resources'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final selectedContent = await showSearch(
                context: context,
                delegate: ContentSearchDelegate(
                  Provider.of<ContentService>(context, listen: false),
                ),
              );

              if (selectedContent != null) {
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ContentViewer(content: selectedContent),
                    ),
                  );
                }
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.deepPurpleAccent,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'By Subject'),
            Tab(text: 'By Type'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AllResourcesTab(),
          SubjectOrganizedTab(),
          TypeOrganizedTab(),
        ],
      ),
    );
  }
}

class AllResourcesTab extends StatelessWidget {
  const AllResourcesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildOverviewView();
  }

  Widget _buildOverviewView() {
    return Consumer<ContentService>(
      builder: (context, contentService, child) {
        if (contentService.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.deepPurpleAccent,
              ),
            ),
          );
        }

        if (contentService.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Error: ${contentService.error}',
                  style: TextStyle(color: Colors.red[400]),
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: () => contentService.fetchAllContent(),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        }

        final contentList = contentService.content;
        if (contentList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.menu_book, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text(
                  'No learning resources available yet',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: contentList.length,
          itemBuilder: (context, index) {
            final content = contentList[index];
            return ResourceCard(content: content);
          },
        );
      },
    );
  }
}

class ResourceCard extends StatelessWidget {
  final Content content;

  const ResourceCard({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContentViewer(content: content),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildTypeIndicator(content.type),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      content.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _getTypeDescription(content.type),
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Added: ${_formatDate(content.createdAt)}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContentViewer(content: content),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Open'),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIndicator(String type) {
    IconData iconData;
    Color color;

    switch (type) {
      case 'article':
        iconData = Icons.article;
        color = Colors.blue;
        break;
      case 'quiz':
        iconData = Icons.quiz;
        color = Colors.orange;
        break;
      case 'guide':
        iconData = Icons.book;
        color = Colors.green;
        break;
      default:
        iconData = Icons.description;
        color = Colors.purple;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: color, size: 20),
    );
  }

  String _getTypeDescription(String type) {
    switch (type) {
      case 'article':
        return 'An in-depth article about this topic';
      case 'quiz':
        return 'A self-assessment quiz to test your knowledge';
      case 'guide':
        return 'A step-by-step guide to learn this concept';
      default:
        return 'Learning resource';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class SubjectOrganizedTab extends StatelessWidget {
  const SubjectOrganizedTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ContentService>(
      builder: (context, contentService, child) {
        if (contentService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Group content by subject
        final Map<String, List<Content>> contentBySubject = {};

        for (final content in contentService.content) {
          for (final topicId in content.relatedTopicIds) {
            final parts = topicId.split(':');
            if (parts.isNotEmpty) {
              final subject = parts[0];
              contentBySubject.putIfAbsent(subject, () => []);
              if (!contentBySubject[subject]!.contains(content)) {
                contentBySubject[subject]!.add(content);
              }
            }
          }
        }

        if (contentBySubject.isEmpty) {
          return Center(
            child: Text(
              'No content organized by subject yet',
              style: TextStyle(color: Colors.grey[400]),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: contentBySubject.length,
          itemBuilder: (context, index) {
            final subject = contentBySubject.keys.elementAt(index);
            final subjectContent = contentBySubject[subject]!;

            return _buildSubjectSection(subject, subjectContent);
          },
        );
      },
    );
  }

  Widget _buildSubjectSection(String subject, List<Content> content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            subject,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...content.map((item) => ResourceCard(content: item)).toList(),
        const Divider(color: Colors.grey),
      ],
    );
  }
}

class TypeOrganizedTab extends StatelessWidget {
  const TypeOrganizedTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ContentService>(
      builder: (context, contentService, child) {
        if (contentService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Group content by type
        final Map<String, List<Content>> contentByType = {
          'article': [],
          'quiz': [],
          'guide': [],
          'other': [],
        };

        for (final content in contentService.content) {
          if (contentByType.containsKey(content.type)) {
            contentByType[content.type]!.add(content);
          } else {
            contentByType['other']!.add(content);
          }
        }

        // Remove empty types
        contentByType.removeWhere((_, items) => items.isEmpty);

        if (contentByType.isEmpty) {
          return Center(
            child: Text(
              'No content available',
              style: TextStyle(color: Colors.grey[400]),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: contentByType.length,
          itemBuilder: (context, index) {
            final type = contentByType.keys.elementAt(index);
            final typeContent = contentByType[type]!;

            return _buildTypeSection(type, typeContent);
          },
        );
      },
    );
  }

  Widget _buildTypeSection(String type, List<Content> content) {
    String title;
    IconData iconData;
    Color color;

    switch (type) {
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
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ...content.map((item) => ResourceCard(content: item)).toList(),
        const Divider(color: Colors.grey),
      ],
    );
  }
}
