import 'package:flutter/material.dart';
import '../../services/ics_service.dart';

class TestCalendarPage extends StatefulWidget {
  const TestCalendarPage({super.key});

  @override
  State<TestCalendarPage> createState() => _TestCalendarPageState();
}

class _TestCalendarPageState extends State<TestCalendarPage> {
  final _urlController = TextEditingController();
  final _icsService = IcsService();
  bool _isLoading = false;
  String? _status;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Test Calendar'),
        backgroundColor: Colors.grey[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Paste your Google Calendar ICS URL',
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: 'https://calendar.google.com/...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.deepPurpleAccent),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testCalendar,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Test Connection'),
            ),
            if (_status != null) ...[
              const SizedBox(height: 16),
              Text(
                _status!,
                style: TextStyle(
                  color: _status!.contains('Error') ? Colors.redAccent : Colors.greenAccent,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _testCalendar() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _status = 'Error: Please enter a URL');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Testing connection...';
    });

    try {
      await _icsService.setIcsUrl(url);
      final events = await _icsService.fetchAndParseIcsEvents();
      setState(() => _status = 'Success! Found ${events.length} events');
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}