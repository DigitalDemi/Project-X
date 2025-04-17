import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/learning_service.dart';

class AddTopicPage extends StatefulWidget {
  const AddTopicPage({super.key});

  @override
  State<AddTopicPage> createState() => _AddTopicPageState();
}

class _AddTopicPageState extends State<AddTopicPage> {
  final _subjectController = TextEditingController();
  final _topicController = TextEditingController();
  String _status = 'active';
  // ignore: prefer_final_fields
  List<String> _prerequisites = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _subjectController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  void _saveTopic() async {
    if (_subjectController.text.isEmpty || _topicController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both subject and topic name';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final path = '${_subjectController.text}/${_topicController.text}';
      final topicData = {
        'path': path,
        'status': _status,
        'prerequisites': _prerequisites,
      };

      final learningService = Provider.of<LearningService>(context, listen: false);
      await learningService.createTopic(topicData);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error creating topic: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add New Topic',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurpleAccent),
            ))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[400]),
                      ),
                    ),
                  
                  _buildSectionTitle('Subject'),
                  const SizedBox(height: 8),
                  _buildTextField('Enter subject (e.g., Mathematics)', controller: _subjectController),
                  const SizedBox(height: 24),
                  
                  _buildSectionTitle('Topic Name'),
                  const SizedBox(height: 8),
                  _buildTextField('Enter topic name (e.g., Calculus)', controller: _topicController),
                  const SizedBox(height: 24),
                  
                  _buildSectionTitle('Status'),
                  const SizedBox(height: 8),
                  _buildStatusSelector(),
                  const SizedBox(height: 32),
                  
                  // Prerequisites would be here in a more complete implementation
                  // For now, we'll keep it simple
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _saveTopic,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Add Topic'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTextField(String hint, {TextEditingController? controller}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[600]),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildStatusSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _status,
          isExpanded: true,
          dropdownColor: Colors.grey[850],
          style: const TextStyle(color: Colors.white),
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
          items: const [
            DropdownMenuItem(
              value: 'active',
              child: Text('Active'),
            ),
            DropdownMenuItem(
              value: 'disabled',
              child: Text('Disabled'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _status = value!;
            });
          },
        ),
      ),
    );
  }
}