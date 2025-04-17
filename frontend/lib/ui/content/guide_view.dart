import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:frontend/models/content.dart';

class GuideView extends StatefulWidget {
  final Content content;

  const GuideView({
    super.key,
    required this.content,
  });

  @override
  State<GuideView> createState() => _GuideViewState();
}

class _GuideViewState extends State<GuideView> {
  int _currentStep = 0;
  List<String> _steps = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text(widget.content.title),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentStep + 1) / _steps.length,
              backgroundColor: Colors.grey[800],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Step ${_currentStep + 1} of ${_steps.length}',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.book,
                          color: Colors.green,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'GUIDE',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Step content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _steps.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : MarkdownBody(
                        data: _steps[_currentStep],
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                          h1: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.5),
                          h2: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.5),
                          h3: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.5),
                          blockquote: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic, height: 1.5),
                          code: TextStyle(backgroundColor: Colors.grey[800], color: Colors.white),
                          listBullet: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
              ),
            ),
            
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Back button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _currentStep > 0 ? _previousStep : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        disabledBackgroundColor: Colors.grey[900],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Previous'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Next/Finish button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _currentStep < _steps.length - 1 
                          ? _nextStep 
                          : () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _currentStep < _steps.length - 1 ? 'Next' : 'Finish',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _parseGuideContent();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _parseGuideContent() {
    // Simple parsing - assumes steps are separated by "## Step X" headings
    final content = widget.content.content;
    final stepRegex = RegExp(r'## Step \d+:?(.+?)(?=## Step \d+:|$)', dotAll: true);
    
    final matches = stepRegex.allMatches(content);
    if (matches.isEmpty) {
      // Fallback if no steps found: treat whole content as one step
      setState(() {
        _steps = [content];
      });
    } else {
      setState(() {
        _steps = matches.map((match) => match.group(0)!).toList();
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }
}