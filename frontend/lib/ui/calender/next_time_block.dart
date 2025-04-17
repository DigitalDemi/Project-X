import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/ics_service.dart';
import '../../models/calendar_event.dart';
import 'calendar_settings.dart';

class NextTimeBlock extends StatefulWidget {
  const NextTimeBlock({super.key});

  @override
  State<NextTimeBlock> createState() => _NextTimeBlockState();
}

class _NextTimeBlockState extends State<NextTimeBlock> {
  final _icsService = IcsService();
  List<CalendarEvent> _upcomingEvents = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _error;
  Timer? _refreshTimer;
  bool _isConnected = false;
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _initializeCalendar();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _refreshEvents(showIndicator: true);
    });
  }

  Future<void> _initializeCalendar() async {
    setState(() => _isLoading = true);
    
    try {
      final url = await _icsService.getIcsUrl();
      if (mounted) {
        setState(() {
          _isConnected = url != null;
          _isLoading = false;
        });
      }
      
      if (_isConnected) {
        _refreshEvents();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Unable to initialize calendar';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshEvents({bool showIndicator = false}) async {
    if (!mounted || _isSyncing) return;

    setState(() {
      if (showIndicator) _isSyncing = true;
      _error = null;
    });

    try {
      final events = await _icsService.getUpcomingEvents(daysAhead: 1);
      if (mounted) {
        setState(() {
          _upcomingEvents = events;
          _lastSyncTime = DateTime.now();
          _isSyncing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Unable to fetch calendar events';
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with sync status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Expanded(
                child: Text(
                  'NEXT TIME BLOCK',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isConnected) ...[
                    if (_isSyncing)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                        ),
                      )
                    else if (_lastSyncTime != null)
                      const SizedBox(
                        width: 16,
                        child: Icon(
                          Icons.sync,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ),
                  ],
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white70),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CalendarSettingsPage()),
                        ).then((_) => _initializeCalendar());
                      },
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurpleAccent),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 36, color: Colors.red[400]),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.red[400], fontSize: 12),
              textAlign: TextAlign.center,
            ),
            TextButton(
              onPressed: () => _refreshEvents(showIndicator: true),
              child: const Text('Try Again', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }

    if (!_isConnected) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.calendar_today,
              size: 36,
              color: Colors.white70,
            ),
            SizedBox(height: 8),
            Text(
              'No calendar connected',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_upcomingEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.event_available,
              size: 36,
              color: Colors.white70,
            ),
            SizedBox(height: 8),
            Text(
              'No upcoming events',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _upcomingEvents.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final event = _upcomingEvents[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _formatEventTime(event.startTime),
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatEventTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}