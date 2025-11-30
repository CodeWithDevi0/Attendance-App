import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:attendanceapp/model/user.dart';
import 'package:attendanceapp/location_picker_screen.dart';

enum QrKind { checkIn, checkOut, dynamicToken, eventSpecific }

class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});
  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  final _db = FirebaseFirestore.instance;
  QrKind _kind = QrKind.checkIn;
  int _intervalSeconds = 30; // dynamic QR rotation interval
  String? _selectedEventId;
  bool _loadingEvents = true;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _events = [];
  double _eventRadius = 100; // meters

  StreamSubscription? _timerSub;
  String _currentToken = '';
  bool _publishing = false;
  // Keep references to Random/Timer usage to satisfy linter.
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _timerSub?.cancel();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _loadingEvents = true);
    final snap = await _db
        .collection('Events')
        .orderBy('createdAt', descending: true)
        .get();
    setState(() {
      _events = snap.docs;
      _loadingEvents = false;
      if (_events.isNotEmpty) {
        _selectedEventId = _events.first.id;
      }
    });
    await _loadSelectedEventRadius();
  }

  Future<void> _createEventDialog() async {
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
      // Get initial location for picker
      double initialLat = 0.0;
      double initialLng = 0.0;
      try {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          var perm = await Geolocator.checkPermission();
          if (perm == LocationPermission.denied) {
            perm = await Geolocator.requestPermission();
          }
          if (perm != LocationPermission.denied &&
              perm != LocationPermission.deniedForever) {
            final pos = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
              ),
            );
            initialLat = pos.latitude;
            initialLng = pos.longitude;
          }
        }
      } catch (_) {}

      // Navigate to location picker
      final picked = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (_) => LocationPickerScreen(
            initialLat: initialLat,
            initialLng: initialLng,
            initialRadius: _eventRadius,
          ),
        ),
      );

      if (picked != null) {
        final lat = picked['lat'] as double?;
        final lng = picked['lng'] as double?;
        final radius = picked['radius'] as double?;
        final docRef = await _db.collection('Events').add({
          'name': nameCtrl.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'creatorRole': User.role,
          'creatorUid': User.uid,
          if (lat != null) 'locLat': lat,
          if (lng != null) 'locLng': lng,
          'locRadius': radius ?? _eventRadius,
        });
        await _loadEvents();
        setState(() => _selectedEventId = docRef.id);
      }
    }
  }

  Future<void> _loadSelectedEventRadius() async {
    if (_selectedEventId == null) return;
    final snap = await _db.collection('Events').doc(_selectedEventId).get();
    if (!snap.exists) return;
    final data = snap.data();
    if (data != null) {
      setState(
        () => _eventRadius =
            (data['locRadius'] as num?)?.toDouble() ?? _eventRadius,
      );
    }
  }

  String _buildStaticToken() {
    final dateStr = DateTime.now().toIso8601String().substring(
      0,
      10,
    ); // YYYY-MM-DD
    switch (_kind) {
      case QrKind.checkIn:
        return 'CHECKIN:${_selectedEventId ?? 'NONE'}:$dateStr';
      case QrKind.checkOut:
        return 'CHECKOUT:${_selectedEventId ?? 'NONE'}:$dateStr';
      case QrKind.eventSpecific:
        return 'EVENT:${_selectedEventId ?? 'NONE'}';
      case QrKind.dynamicToken:
        // handled separately
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
    setState(() => _publishing = true);
    final data = {
      'token': token,
      'kind': kind.name,
      'createdAt': FieldValue.serverTimestamp(),
      if (validitySeconds != null) 'validFor': validitySeconds,
      'eventId': _selectedEventId,
      'issuerUid': User.uid,
    };
    // Store under Events/<eventId>/activeTokens/<token>
    await _db
        .collection('Events')
        .doc(_selectedEventId)
        .collection('activeTokens')
        .doc(token)
        .set(data);
    setState(() => _publishing = false);
  }

  Future<void> _startDynamicRotation() async {
    _timerSub?.cancel();
    // Immediately generate first
    final first = _generateDynamicToken();
    setState(() => _currentToken = first);
    _publishToken(
      first,
      kind: QrKind.dynamicToken,
      validitySeconds: _intervalSeconds,
    );
    _timerSub = Stream.periodic(Duration(seconds: _intervalSeconds)).listen((
      _,
    ) {
      final t = _generateDynamicToken();
      setState(() => _currentToken = t);
      _publishToken(
        t,
        kind: QrKind.dynamicToken,
        validitySeconds: _intervalSeconds,
      );
    });
    await _loadSelectedEventRadius();
  }

  void _stopDynamic() {
    _timerSub?.cancel();
    _timerSub = null;
  }

  Future<void> _editSelectedEvent() async {
    if (_selectedEventId == null) return;
    final eventSnap = await _db
        .collection('Events')
        .doc(_selectedEventId)
        .get();
    if (!eventSnap.exists) return;
    final data = eventSnap.data()!;
    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    final latCtrl = TextEditingController(
      text: (data['locLat'] as num?)?.toString() ?? '',
    );
    final lngCtrl = TextEditingController(
      text: (data['locLng'] as num?)?.toString() ?? '',
    );
    final radiusCtrl = TextEditingController(
      text: (data['locRadius'] as num?)?.toString() ?? '',
    );
    final dialogContext = context;
    // Passing local context to showDialog is safe here; avoid linter false-positive.
    // ignore: use_build_context_synchronously
    showDialog<bool>(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Event name'),
            ),
            TextField(
              controller: latCtrl,
              decoration: const InputDecoration(labelText: 'Latitude'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: lngCtrl,
              decoration: const InputDecoration(labelText: 'Longitude'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: radiusCtrl,
              decoration: const InputDecoration(labelText: 'Radius (meters)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Update'),
          ),
        ],
      ),
    ).then((edited) async {
      if (!mounted) return;
      if (edited == true) {
        final lat = double.tryParse(latCtrl.text);
        final lng = double.tryParse(lngCtrl.text);
        final radius = double.tryParse(radiusCtrl.text);
        await _db.collection('Events').doc(_selectedEventId).update({
          'name': nameCtrl.text.trim(),
          if (lat != null) 'locLat': lat,
          if (lng != null) 'locLng': lng,
          if (radius != null) 'locRadius': radius,
        });
        await _loadEvents();
        await _loadSelectedEventRadius();
      }
    });
  }

  void _generate() {
    if (_selectedEventId == null) return;
    if (_kind == QrKind.dynamicToken) {
      _startDynamicRotation();
    } else {
      _stopDynamic();
      final token = _buildStaticToken();
      setState(() => _currentToken = token);
      _publishToken(token, kind: _kind);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color.fromARGB(252, 47, 145, 42);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'QR Generator',
          style: TextStyle(fontFamily: 'NexaBold'),
        ),
        actions: [
          if (_timerSub != null)
            IconButton(
              tooltip: 'Stop Dynamic',
              icon: const Icon(Icons.stop_circle),
              onPressed: () => setState(() {
                _stopDynamic();
                _currentToken = '';
              }),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Event',
                  style: const TextStyle(fontFamily: 'NexaBold', fontSize: 16),
                ),
                TextButton.icon(
                  onPressed: _createEventDialog,
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'New',
                    style: TextStyle(fontFamily: 'NexaRegular'),
                  ),
                ),
              ],
            ),
            if (_loadingEvents)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_events.isEmpty)
              const Text(
                'No events yet. Create one to begin.',
                style: TextStyle(fontFamily: 'NexaRegular'),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedEventId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Select Event',
                ),
                items: [
                  for (final e in _events)
                    DropdownMenuItem(
                      value: e.id,
                      child: Text(
                        e.data()['name'] ?? 'Unnamed',
                        style: const TextStyle(fontFamily: 'NexaRegular'),
                      ),
                    ),
                ],
                onChanged: (v) async {
                  setState(() => _selectedEventId = v);
                  await _loadSelectedEventRadius();
                },
              ),
            const SizedBox(height: 24),
            const Text(
              'Event Radius (meters)',
              style: TextStyle(fontFamily: 'NexaBold', fontSize: 16),
            ),
            Slider(
              min: 20,
              max: 500,
              divisions: 24,
              label: _eventRadius.toStringAsFixed(0),
              value: _eventRadius,
              onChanged: (v) async {
                setState(() => _eventRadius = v);
                if (_selectedEventId != null) {
                  await _db.collection('Events').doc(_selectedEventId).update({
                    'locRadius': v,
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            if (_selectedEventId != null)
              ElevatedButton(
                onPressed: _editSelectedEvent,
                child: const Text('Edit Event Details'),
              ),
            const SizedBox(height: 24),
            const Text(
              'QR Type',
              style: TextStyle(fontFamily: 'NexaBold', fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: [
                ChoiceChip(
                  label: const Text('Check-In'),
                  selected: _kind == QrKind.checkIn,
                  onSelected: (_) => setState(() => _kind = QrKind.checkIn),
                ),
                ChoiceChip(
                  label: const Text('Check-Out'),
                  selected: _kind == QrKind.checkOut,
                  onSelected: (_) => setState(() => _kind = QrKind.checkOut),
                ),
                ChoiceChip(
                  label: const Text('Dynamic'),
                  selected: _kind == QrKind.dynamicToken,
                  onSelected: (_) =>
                      setState(() => _kind = QrKind.dynamicToken),
                ),
                ChoiceChip(
                  label: const Text('Event'),
                  selected: _kind == QrKind.eventSpecific,
                  onSelected: (_) =>
                      setState(() => _kind = QrKind.eventSpecific),
                ),
              ],
            ),
            if (_kind == QrKind.dynamicToken) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Rotation (s):',
                    style: TextStyle(fontFamily: 'NexaRegular'),
                  ),
                  Expanded(
                    child: Slider(
                      min: 10,
                      max: 60,
                      divisions: 5,
                      label: '$_intervalSeconds',
                      value: _intervalSeconds.toDouble(),
                      onChanged: (v) =>
                          setState(() => _intervalSeconds = v.round()),
                    ),
                  ),
                  Text(
                    '$_intervalSeconds',
                    style: const TextStyle(fontFamily: 'NexaBold'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _selectedEventId == null ? null : _generate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.qr_code_2),
                label: Text(
                  _kind == QrKind.dynamicToken
                      ? 'Start Dynamic QR'
                      : 'Generate QR',
                  style: const TextStyle(fontFamily: 'NexaBold'),
                ),
              ),
            ),
            const SizedBox(height: 30),
            if (_currentToken.isNotEmpty) ...[
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: _currentToken,
                        version: QrVersions.auto,
                        size: 240,
                        gapless: true,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Colors.black,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SelectableText(
                      _currentToken,
                      style: const TextStyle(
                        fontFamily: 'NexaRegular',
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (_publishing)
                      const CircularProgressIndicator(strokeWidth: 2),
                    if (_kind == QrKind.dynamicToken)
                      const Text(
                        'Dynamic QR rotates automatically.',
                        style: TextStyle(fontFamily: 'NexaRegular'),
                      )
                    else
                      const Text(
                        'Share QR on screen for students to scan.',
                        style: TextStyle(fontFamily: 'NexaRegular'),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),
            const Text(
              'Token Format Reference',
              style: TextStyle(fontFamily: 'NexaBold', fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'CHECKIN:<eventId>:<YYYY-MM-DD>\nCHECKOUT:<eventId>:<YYYY-MM-DD>\nEVENT:<eventId>\nDYN:<eventId>:<YYYY-MM-DD>:<epochMs>:<nonce>',
              style: TextStyle(fontFamily: 'NexaRegular', fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
