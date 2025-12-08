import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:attendanceapp/model/user.dart';
import 'package:attendanceapp/location_picker_screen.dart';
import 'package:attendanceapp/services/location_service.dart';

enum QrKind { checkIn, checkOut, dynamicToken, eventSpecific }

class UnifiedEventScreen extends StatefulWidget {
  const UnifiedEventScreen({super.key});

  @override
  State<UnifiedEventScreen> createState() => _UnifiedEventScreenState();
}

class _UnifiedEventScreenState extends State<UnifiedEventScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  QrKind _kind = QrKind.checkIn;
  int _intervalSeconds = 30;
  String? _selectedEventId;
  StreamSubscription? _timerSub;
  String _currentToken = '';
  bool _publishing = false;
  final Random _rand = Random();

  @override
  void dispose() {
    _timerSub?.cancel();
    super.dispose();
  }

  // --- HELPER TO SHOW ERRORS ---
  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Determines the stream of events based on User Role.
  /// - Admin: Sees ALL events.
  /// - Others (Teacher): Sees only events they created.
  Stream<QuerySnapshot> _getEventsStream() {
    Query<Map<String, dynamic>> query = _db.collection('Events');

    // Case-insensitive check for admin role
    bool isAdmin = (User.role ?? '').toLowerCase().trim() == 'admin';

    if (!isAdmin) {
      // If NOT admin, filter to show only events created by this user
      query = query.where('creatorUid', isEqualTo: User.uid);
    }

    // Return events sorted by creation date
    return query.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> _createEvent() async {
    // 1. SECURITY CHECK: Are we logged in?
    if (User.uid.isEmpty) {
      _showSnack('Error: You are not logged in. Cannot create event.');
      return;
    }

    final nameCtrl = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Event'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Event name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (created == true && nameCtrl.text.trim().isNotEmpty) {
      double lat = 0.0;
      double lng = 0.0;

      // 2. LOCATION FETCH
      try {
        final locService = LocationService();
        final initialized = await locService.initialize();
        if (initialized) {
          lat = await locService.getLatitude() ?? 0.0;
          lng = await locService.getLongitude() ?? 0.0;
        }
      } catch (e) {
        print('Location Warning (Web/Perms): $e. Using default (0,0).');
      }

      // 3. DATABASE SAVE
      try {
        final docRef = await _db.collection('Events').add({
          'name': nameCtrl.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'creatorRole': User.role,
          'creatorUid': User.uid,
          'locLat': lat,
          'locLng': lng,
          'locRadius': 100.0, // default
        });

        setState(() => _selectedEventId = docRef.id);
        _showSnack('Event created successfully!');
      } catch (e) {
        _showSnack('Database Error: $e');
        print('Create Event Error: $e');
      }
    }
  }

  Future<void> _editEvent(DocumentSnapshot event) async {
    final data = event.data() as Map<String, dynamic>;
    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    double lat = (data['locLat'] as num?)?.toDouble() ?? 0.0;
    double lng = (data['locLng'] as num?)?.toDouble() ?? 0.0;
    double radius = (data['locRadius'] as num?)?.toDouble() ?? 100.0;

    if (lat == 0.0 && lng == 0.0) {
      try {
        final locService = LocationService();
        final initialized = await locService.initialize();
        if (initialized) {
          lat = await locService.getLatitude() ?? 0.0;
          lng = await locService.getLongitude() ?? 0.0;
        }
      } catch (e) {
        print('Location Warning during Edit: $e');
      }
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Event Name'),
                ),
                const SizedBox(height: 16),
                Text(
                  'Location: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                ),
                Text('Radius: ${radius.toStringAsFixed(0)}m'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final picked = await Navigator.of(ctx)
                          .push<Map<String, dynamic>>(
                            MaterialPageRoute(
                              builder: (_) => LocationPickerScreen(
                                initialLat: lat,
                                initialLng: lng,
                                initialRadius: radius,
                              ),
                            ),
                          );
                      if (picked != null) {
                        setState(() {
                          lat = picked['lat'];
                          lng = picked['lng'];
                          radius = picked['radius'];
                        });
                      }
                    } catch (e) {
                      print("Location Picker Error: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Map picker not supported on this platform/configuration.',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Edit Location & Radius'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved == true && mounted) {
      try {
        await _db.collection('Events').doc(event.id).update({
          'name': nameCtrl.text.trim(),
          'locLat': lat,
          'locLng': lng,
          'locRadius': radius,
        });
        _showSnack('Event updated successfully');
      } catch (e) {
        _showSnack('Update Failed: $e');
      }
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text(
          'Are you sure you want to delete this event? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _db.collection('Events').doc(eventId).delete();
        _showSnack('Event deleted successfully');
      } catch (e) {
        _showSnack('Delete Failed: $e');
      }
    }
  }

  String _buildStaticToken() {
    final dateStr = DateTime.now().toIso8601String().substring(0, 10);
    switch (_kind) {
      case QrKind.checkIn:
        return 'CHECKIN:${_selectedEventId ?? 'NONE'}:$dateStr';
      case QrKind.checkOut:
        return 'CHECKOUT:${_selectedEventId ?? 'NONE'}:$dateStr';
      case QrKind.eventSpecific:
        return 'EVENT:${_selectedEventId ?? 'NONE'}';
      case QrKind.dynamicToken:
        return '';
    }
  }

  String _generateDynamicToken() {
    final nonce = _rand.nextInt(1 << 32).toRadixString(16);
    final now = DateTime.now();
    final dateStr = now.toIso8601String().substring(0, 10);
    return 'DYN:${_selectedEventId ?? 'NONE'}:$dateStr:${now.millisecondsSinceEpoch}:$nonce';
  }

  Future<void> _publishToken(
    String token, {
    required QrKind kind,
    int? validitySeconds,
  }) async {
    if (_selectedEventId == null) return;
    if (User.uid.isEmpty) return;

    setState(() => _publishing = true);

    try {
      final data = {
        'token': token,
        'kind': kind.name,
        'createdAt': FieldValue.serverTimestamp(),
        if (validitySeconds != null) 'validFor': validitySeconds,
        'eventId': _selectedEventId,
        'issuerUid': User.uid,
      };
      await _db
          .collection('Events')
          .doc(_selectedEventId)
          .collection('activeTokens')
          .doc(token)
          .set(data);
    } catch (e) {
      print("Database Error publishing token: $e");
    }

    if (mounted) setState(() => _publishing = false);
  }

  void _generateQR(String eventId) {
    setState(() => _selectedEventId = eventId);
    setState(() => _currentToken = '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Generate QR Code'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<QrKind>(
                  value: _kind,
                  items: QrKind.values
                      .map(
                        (k) => DropdownMenuItem(value: k, child: Text(k.name)),
                      )
                      .toList(),
                  onChanged: (v) {
                    setState(() => _kind = v!);
                    setDialogState(() => _kind = v!);
                  },
                ),
                if (_kind == QrKind.dynamicToken)
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Interval (seconds)',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _intervalSeconds = int.tryParse(v) ?? 30,
                  ),
                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _publishing
                      ? null
                      : () async {
                          if (User.uid.isEmpty) {
                            Navigator.pop(ctx);
                            _showSnack(
                              'Login required to generate valid QR codes.',
                            );
                            return;
                          }

                          if (_kind == QrKind.dynamicToken) {
                            _timerSub?.cancel();
                            final first = _generateDynamicToken();

                            setState(() => _currentToken = first);
                            setDialogState(() => _currentToken = first);

                            await _publishToken(
                              first,
                              kind: QrKind.dynamicToken,
                              validitySeconds: _intervalSeconds,
                            );

                            _timerSub =
                                Stream.periodic(
                                  Duration(seconds: _intervalSeconds),
                                ).listen((_) {
                                  final t = _generateDynamicToken();
                                  if (mounted && ctx.mounted) {
                                    setState(() => _currentToken = t);
                                    setDialogState(() => _currentToken = t);
                                    _publishToken(
                                      t,
                                      kind: QrKind.dynamicToken,
                                      validitySeconds: _intervalSeconds,
                                    );
                                  }
                                });
                          } else {
                            final token = _buildStaticToken();

                            setState(() => _currentToken = token);
                            setDialogState(() => _currentToken = token);

                            await _publishToken(token, kind: _kind);
                          }
                        },
                  child: Text(
                    _kind == QrKind.dynamicToken
                        ? 'Start Dynamic QR'
                        : 'Generate QR',
                  ),
                ),

                if (_currentToken.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 220,
                          height: 220,
                          child: QrImageView(
                            data: _currentToken,
                            version: QrVersions.auto,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          _currentToken,
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _timerSub?.cancel();
                Navigator.pop(ctx);
              },
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    ).then((_) => _timerSub?.cancel());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Event Management',
          style: TextStyle(fontFamily: 'NexaBold', color: Colors.white),
        ),
        backgroundColor: const Color(0xFF28a745), // Success Green
        iconTheme: const IconThemeData(color: Colors.white), // White Back Arrow
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createEvent,
        backgroundColor: const Color(0xFF28a745), // Success Green
        child: const Icon(Icons.add, color: Colors.white),
      ),
      // --- CENTERED & CONSTRAINED WIDTH ---
      body: Center(
        child: Container(
          // Constraints ensure cards don't get too wide on PC
          constraints: const BoxConstraints(maxWidth: 600),
          child: StreamBuilder<QuerySnapshot>(
            stream: _getEventsStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final events = snapshot.data!.docs;
              if (events.isEmpty) {
                return const Center(
                  child: Text('No events found. Create one to get started.'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  final data = event.data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'Unnamed Event';
                  final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                  final creatorRole = data['creatorRole'] ?? 'unknown';
                  final locLat = data['locLat'];
                  final locLng = data['locLng'];
                  final locRadius = data['locRadius'] ?? 100.0;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        name,
                        style: const TextStyle(
                          fontFamily: 'NexaBold',
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        'Created: ${createdAt != null ? createdAt.toString().substring(0, 16) : 'Unknown'}\n'
                        'By: $creatorRole\n'
                        'Location: ${locLat != null && locLng != null ? '${locLat.toStringAsFixed(4)}, ${locLng.toStringAsFixed(4)}' : 'Not set'}\n'
                        'Radius: ${locRadius.toStringAsFixed(0)}m',
                        style: const TextStyle(fontFamily: 'NexaRegular'),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            // --- CHANGED: Blue Icon ---
                            icon: const Icon(Icons.qr_code, color: Colors.blue),
                            onPressed: () => _generateQR(event.id),
                          ),
                          IconButton(
                            // --- CHANGED: Success Green Icon ---
                            icon: const Icon(
                              Icons.edit,
                              color: Color(0xFF28a745),
                            ),
                            onPressed: () => _editEvent(event),
                          ),
                          IconButton(
                            // --- CHANGED: Danger Red Icon ---
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteEvent(event.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
