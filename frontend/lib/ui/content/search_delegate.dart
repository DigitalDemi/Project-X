import 'package:flutter/material.dart';
import 'package:frontend/models/content.dart';
import 'package:frontend/services/content_service.dart';

class ContentSearchDelegate extends SearchDelegate<Content?> {
  final ContentService contentService;

  ContentSearchDelegate(this.contentService);

  @override
  String get searchFieldLabel => 'Search learning resources...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.grey[400]),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildRecentSearches(context);
    }
    return _buildSearchResults(query);
  }

  Widget _buildRecentSearches(BuildContext context) {
    // This could be enhanced to use shared preferences to store recent searches
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Searches',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.history, color: Colors.grey[600]),
            title: const Text(
              'No recent searches',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          const Divider(color: Colors.grey),
          const SizedBox(height: 24),
          Text(
            'Popular Topics',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Learning',
              'Task Management',
              'Focus',
              'Energy',
              'Habits',
            ].map((topic) => ActionChip(
              label: Text(topic),
              backgroundColor: Colors.grey[800],
              onPressed: () {
                query = topic;
                showResults(context);
              },
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(String searchQuery) {
    if (searchQuery.isEmpty) {
      return Center(
        child: Text(
          'Enter a search term',
          style: TextStyle(color: Colors.grey[400]),
        ),
      );
    }

    // Filter content based on search query
    final searchResults = contentService.content.where((content) {
      return content.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
             content.content.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    if (searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 16),
            Text(
              'No results found for "$searchQuery"',
              style: TextStyle(color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final content = searchResults[index];
        return ListTile(
          title: Text(
            content.title,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            _getTypeLabel(content.type),
            style: TextStyle(color: Colors.grey[400]),
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getTypeColor(content.type).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getTypeIcon(content.type),
              color: _getTypeColor(content.type),
              size: 24,
            ),
          ),
          onTap: () {
            close(context, content);
          },
        );
      },
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'article':
        return 'Article';
      case 'quiz':
        return 'Quiz';
      case 'guide':
        return 'Guide';
      default:
        return 'Resource';
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'article':
        return Icons.article;
      case 'quiz':
        return Icons.quiz;
      case 'guide':
        return Icons.book;
      default:
        return Icons.description;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'article':
        return Colors.blue;
      case 'quiz':
        return Colors.orange;
      case 'guide':
        return Colors.green;
      default:
        return Colors.purple;
    }
  }
}