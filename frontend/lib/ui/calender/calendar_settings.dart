// lib/ui/calendar/calendar_settings.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/ics_service.dart';

class CalendarSettingsPage extends StatefulWidget {
  const CalendarSettingsPage({super.key});

  @override
  State<CalendarSettingsPage> createState() => _CalendarSettingsPageState();
}

class _CalendarSettingsPageState extends State<CalendarSettingsPage> {
  final _icsUrlController = TextEditingController();
  final _icsService = IcsService();
  bool _isLoading = false;
  String? _icsUrl;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final url = await _icsService.getIcsUrl();
      setState(() {
        _icsUrl = url;
        _icsUrlController.text = url ?? '';
      });
    } catch (e) {
      setState(() => _errorMessage = 'Error loading settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final url = _icsUrlController.text.trim();
      if (url.isEmpty) {
        // Remove URL if empty
        await _icsService.setIcsUrl('');
        setState(() {
          _icsUrl = null;
          _successMessage = 'Calendar disconnected successfully';
        });
        return;
      }

      // Test URL before saving
      if (!_isValidIcsUrl(url)) {
        setState(() => _errorMessage = 'Invalid ICS URL format');
        return;
      }

      await _icsService.setIcsUrl(url);
      
      // Test fetching events
      try {
        final events = await _icsService.fetchAndParseIcsEvents();
        setState(() {
          _icsUrl = url;
          _successMessage = 'Calendar connected successfully (${events.length} events found)';
        });
      } catch (e) {
        setState(() => _errorMessage = 'Error fetching calendar: $e');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error saving settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _isValidIcsUrl(String url) {
    // Basic URL validation
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return false;
    }
    
    // Should end with .ics for most calendar URLs
    return url.toLowerCase().endsWith('.ics');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text('Calendar Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current status
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _icsUrl != null ? Icons.check_circle : Icons.cancel,
                          color: _icsUrl != null ? Colors.green : Colors.red[400],
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _icsUrl != null ? 'Calendar Connected' : 'No Calendar Connected',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_icsUrl != null) ...[
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: _icsUrl!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('URL copied to clipboard')),
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _icsUrl!,
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.copy,
                                        color: Colors.white70,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ICS URL input
                  const Text(
                    'Calendar URL (ICS Format)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _icsUrlController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'https://calendar.google.com/calendar/ical/...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[700]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.deepPurpleAccent),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () => _icsUrlController.clear(),
                      ),
                    ),
                    onSubmitted: (_) => _saveSettings(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Error/success messages
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  
                  if (_successMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(_icsUrl != null ? 'Update Calendar' : 'Connect Calendar'),
                    ),
                  ),

                  // Disconnect button
                  if (_icsUrl != null) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          _icsUrlController.clear();
                          _saveSettings();
                        },
                        child: const Text(
                          'Disconnect Calendar',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // Instructions
                  _buildInstructionsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildInstructionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How to get your Google Calendar URL:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStep(1, 'Go to Google Calendar in a browser (not in the app)'),
          _buildStep(2, 'Click the three dots (⋮) next to your calendar in the left sidebar'),
          _buildStep(3, 'Click "Settings and sharing"'),
          _buildStep(4, 'Scroll down to "Integrate calendar" section'),
          _buildStep(5, 'Look for "Secret address in iCal format"'),
          _buildStep(6, 'Click "Copy" to copy the .ics URL'),
          _buildStep(7, 'Paste the URL here and click "Connect Calendar"'),
          const SizedBox(height: 16),
          const Text(
            'Note: Make sure your calendar is set to public or sharing settings allow access.',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.deepPurpleAccent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _icsUrlController.dispose();
    super.dispose();
  }
}