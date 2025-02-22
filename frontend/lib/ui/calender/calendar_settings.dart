// lib/ui/calendar/calendar_settings.dart
import 'package:flutter/material.dart';
import '../../services/ics_service.dart';
import '../../services/google_calendar_service.dart';

class CalendarSettingsPage extends StatefulWidget {
  const CalendarSettingsPage({super.key});

  @override
  State<CalendarSettingsPage> createState() => _CalendarSettingsPageState();
}

class _CalendarSettingsPageState extends State<CalendarSettingsPage> {
  final _icsUrlController = TextEditingController();
  final _icsService = IcsService();
  final _googleService = GoogleCalendarService();
  bool _isGoogleConnected = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final icsUrl = await _icsService.getIcsUrl();
    final googleConnected = await _googleService.isConnected();
    
    setState(() {
      _icsUrlController.text = icsUrl ?? '';
      _isGoogleConnected = googleConnected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text('Calendar Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ICS Calendar Section
          _buildSection(
            title: 'ICS Calendar',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _icsUrlController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'ICS URL',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'https://example.com/calendar.ics',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    await _icsService.setIcsUrl(_icsUrlController.text);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ICS URL saved')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                  ),
                  child: const Text('Save ICS URL'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Google Calendar Section
          _buildSection(
            title: 'Google Calendar',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status: ${_isGoogleConnected ? 'Connected' : 'Not Connected'}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      if (_isGoogleConnected) {
                        await _googleService.disconnect();
                      } else {
                        await _googleService.connect();
                      }
                      await _loadSettings();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isGoogleConnected 
                      ? Colors.red 
                      : Colors.deepPurpleAccent,
                  ),
                  child: Text(_isGoogleConnected ? 'Disconnect' : 'Connect'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Calendar Display Settings
          _buildSection(
            title: 'Display Settings',
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    'Show ICS Events',
                    style: TextStyle(color: Colors.white),
                  ),
                  value: true, // TODO: Implement preference
                  onChanged: (value) {
                    // TODO: Save preference
                  },
                ),
                SwitchListTile(
                  title: const Text(
                    'Show Google Calendar Events',
                    style: TextStyle(color: Colors.white),
                  ),
                  value: true, // TODO: Implement preference
                  onChanged: (value) {
                    // TODO: Save preference
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          child,
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