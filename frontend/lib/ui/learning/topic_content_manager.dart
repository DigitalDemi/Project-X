// lib/ui/learning/topic_content_manager.dart
import 'package:flutter/material.dart';
import 'package:frontend/models/content.dart';
import 'package:frontend/models/topic.dart';
import 'package:frontend/services/content_service.dart';
import 'package:frontend/ui/content/content_viewer.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class TopicContentManagerPage extends StatefulWidget {
  final Topic topic;

  const TopicContentManagerPage({
    super.key,
    required this.topic,
  });

  @override
  State<TopicContentManagerPage> createState() => _TopicContentManagerPageState();
}

class _TopicContentManagerPageState extends State<TopicContentManagerPage> {
  bool _isAddingUrl = false;
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  List<ContentRating> _contentRatings = [];

  @override
  void initState() {
    super.initState();
    _loadContentRatings();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadContentRatings() async {
    // In a real implementation, this would load from a database
    // For now, we'll use mock data
    setState(() {
      _contentRatings = [
        ContentRating(contentId: 'content1', rating: 4, note: 'Very helpful for understanding the concept'),
        ContentRating(contentId: 'content2', rating: 3, note: 'Good examples but could be more comprehensive'),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text('Learning Resources'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopicHeader(),
            const SizedBox(height: 24),
            
            // Resources tabs
            _buildResourcesSection(),
            const SizedBox(height: 24),
            
            // Notes section
            _buildNotesSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddResourceDialog,
        backgroundColor: Colors.deepPurpleAccent,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTopicHeader() {
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStageColor(widget.topic.stage).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.book,
                  color: _getStageColor(widget.topic.stage),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.topic.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.topic.subject,
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoPill(
                _formatStageName(widget.topic.stage),
                _getStageColor(widget.topic.stage),
              ),
              const SizedBox(width: 8),
              _buildInfoPill(
                'Reviews: ${widget.topic.reviewHistory.length}',
                Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildInfoPill(
                'Due: ${_formatDate(widget.topic.nextReview)}',
                Colors.deepPurpleAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResourcesSection() {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                TabBar(
                  tabs: const [
                    Tab(text: 'App Content'),
                    Tab(text: 'Web Links'),
                    Tab(text: 'Study Notes'),
                  ],
                  indicator: BoxDecoration(
                    color: Colors.deepPurpleAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorSize: TabBarIndicatorSize.tab,
                ),
                const SizedBox(
                  height: 300,
                  child: TabBarView(
                    children: [
                      _AppContentTab(),
                      _WebLinksTab(),
                      _StudyNotesTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Topic Notes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white70),
                onPressed: _showEditNotesDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Add study notes for this topic...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
            ),
            maxLines: 5,
            readOnly: true,
            onTap: _showEditNotesDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  void _showAddResourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Add Learning Resource', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.link, color: Colors.green),
              ),
              title: const Text('Add Web Link', style: TextStyle(color: Colors.white)),
              subtitle: Text('Add a URL to an external resource', style: TextStyle(color: Colors.grey[400])),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _isAddingUrl = true;
                });
                _showAddLinkDialog();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.note_add, color: Colors.blue),
              ),
              title: const Text('Add Study Note', style: TextStyle(color: Colors.white)),
              subtitle: Text('Create a personal study note', style: TextStyle(color: Colors.grey[400])),
              onTap: () {
                Navigator.pop(context);
                _showEditNotesDialog();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAddLinkDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Add Web Link', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Resource Title',
                labelStyle: TextStyle(color: Colors.grey[400]),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'URL',
                labelStyle: TextStyle(color: Colors.grey[400]),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                hintText: 'https://',
                hintStyle: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () {
              if (_titleController.text.isNotEmpty && _urlController.text.isNotEmpty) {
                // Save the URL (in a real app, this would save to a database)
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Web link added successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                
                setState(() {
                  _titleController.clear();
                  _urlController.clear();
                  _isAddingUrl = false;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditNotesDialog() {
    // Create a temporary controller with current value
    final tempController = TextEditingController(text: _noteController.text);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Edit Notes', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: tempController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
          ),
          maxLines: 8,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _noteController.text = tempController.text;
              });
              Navigator.pop(context);
              
              // Show a snackbar confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notes saved successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Color _getStageColor(String stage) {
    switch (stage) {
      case 'first_time':
        return Colors.red;
      case 'early_stage':
        return Colors.orange;
      case 'mid_stage':
        return Colors.yellow;
      case 'late_stage':
        return Colors.green;
      case 'mastered':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatStageName(String stage) {
    switch (stage) {
      case 'first_time':
        return 'First Time';
      case 'early_stage':
        return 'Early Stage';
      case 'mid_stage':
        return 'Mid Stage';
      case 'late_stage':
        return 'Late Stage';
      case 'mastered':
        return 'Mastered';
      default:
        return stage;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _AppContentTab extends StatelessWidget {
  const _AppContentTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<ContentService>(
      builder: (context, contentService, child) {
        return FutureBuilder<List<Content>>(
          future: contentService.getContentByTopic('sample-topic-id'), // Replace with actual topic ID
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
                child: Text(
                  'Error loading content: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            
            final contentList = snapshot.data ?? [];
            
            if (contentList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.article, size: 48, color: Colors.grey[600]),
                    const SizedBox(height: 16),
                    const Text(
                      'No learning content available',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Content will appear here as it becomes available',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            
            return ListView.builder(
              itemCount: contentList.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final content = contentList[index];
                return _ContentListItem(
                  content: content,
                  onRate: () => _showRatingDialog(context, content),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showRatingDialog(BuildContext context, Content content) {
    double rating = 0;
    final noteController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Rate This Resource', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              content.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            RatingBar.builder(
              initialRating: 0,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (value) {
                rating = value;
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                labelStyle: TextStyle(color: Colors.grey[400]),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                hintText: 'What did you think of this resource?',
                hintStyle: TextStyle(color: Colors.grey[600]),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () {
              if (rating > 0) {
                // Save the rating (in a real app, this would save to a database)
                Navigator.pop(context);
                
                final contentRating = ContentRating(
                  contentId: content.id,
                  rating: rating,
                  note: noteController.text,
                );
                
                // Show a snackbar confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Rating saved successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _WebLinksTab extends StatelessWidget {
  const _WebLinksTab();

  @override
  Widget build(BuildContext context) {
    // In a real app, this would load from a database
    // For now, use mock data
    final webLinks = [
      WebLink(
        id: '1',
        title: 'Python Basics Tutorial',
        url: 'https://docs.python.org/3/tutorial/index.html',
        addedDate: DateTime.now().subtract(const Duration(days: 5)),
      ),
      WebLink(
        id: '2',
        title: 'Introduction to Algorithms',
        url: 'https://ocw.mit.edu/courses/6-006-introduction-to-algorithms-spring-2020/',
        addedDate: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ];
    
    if (webLinks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 16),
            const Text(
              'No web links added yet',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Add useful web resources for this topic',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: webLinks.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final link = webLinks[index];
        return _WebLinkItem(link: link);
      },
    );
  }
}

class _StudyNotesTab extends StatelessWidget {
  const _StudyNotesTab();

  @override
  Widget build(BuildContext context) {
    // In a real app, this would load from a database
    // For now, use mock data
    final studyNotes = [
      StudyNote(
        id: '1',
        title: 'Key Concepts',
        content: 'These are the important concepts to remember:\n\n- Concept 1\n- Concept 2\n- Concept 3',
        createdDate: DateTime.now().subtract(const Duration(days: 2)),
      ),
      StudyNote(
        id: '2',
        title: 'Practice Problems',
        content: 'Work through these practice problems:\n\n1. Problem description...\n2. Another problem...',
        createdDate: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];
    
    if (studyNotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 16),
            const Text(
              'No study notes added yet',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your personal notes for this topic',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: studyNotes.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final note = studyNotes[index];
        return _StudyNoteItem(note: note);
      },
    );
  }
}

class _ContentListItem extends StatelessWidget {
  final Content content;
  final VoidCallback onRate;

  const _ContentListItem({
    required this.content,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    
    switch (content.type) {
      case 'article':
        color = Colors.blue;
        icon = Icons.article;
        break;
      case 'quiz':
        color = Colors.orange;
        icon = Icons.quiz;
        break;
      case 'guide':
        color = Colors.green;
        icon = Icons.book;
        break;
      default:
        color = Colors.purple;
        icon = Icons.description;
    }
    
    return Card(
      color: Colors.grey[800],
      margin: const EdgeInsets.only(bottom: 12),
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          content.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getContentTypeLabel(content.type),
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.star_border, color: Colors.amber),
                    onPressed: onRate,
                    tooltip: 'Rate this resource',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getContentTypeLabel(String type) {
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
}

class _WebLinkItem extends StatelessWidget {
  final WebLink link;

  const _WebLinkItem({
    required this.link,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[800],
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.link, color: Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        link.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        link.url,
                        style: const TextStyle(
                          color: Colors.lightBlue,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new, color: Colors.white70),
                  onPressed: () {
                    // Open the URL (in a real app, this would use a URL launcher)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Opening: ${link.url}'),
                      ),
                    );
                  },
                  tooltip: 'Open link',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Added: ${_formatDate(link.addedDate)}',
              style: TextStyle(color: Colors.grey[400], fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _StudyNoteItem extends StatelessWidget {
  final StudyNote note;

  const _StudyNoteItem({
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[800],
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.note, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    note.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white70),
                  onPressed: () {
                    // Edit the note (in a real app, this would open an edit dialog)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Editing note...'),
                      ),
                    );
                  },
                  tooltip: 'Edit note',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              note.content,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Created: ${_formatDate(note.createdDate)}',
              style: TextStyle(color: Colors.grey[400], fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class ContentRating {
  final String contentId;
  final double rating;
  final String? note;

  ContentRating({
    required this.contentId,
    required this.rating,
    this.note,
  });
}

class WebLink {
  final String id;
  final String title;
  final String url;
  final DateTime addedDate;

  WebLink({
    required this.id,
    required this.title,
    required this.url,
    required this.addedDate,
  });
}

class StudyNote {
  final String id;
  final String title;
  final String content;
  final DateTime createdDate;

  StudyNote({
    required this.id,
    required this.title,
    required this.content,
    required this.createdDate,
  });
}