import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/repositories/google_calendar_connection_repository.dart';

enum GoogleCalendarTileState { loading, disconnected, connecting, connected, error }

class GoogleCalendarConnectionTile extends StatefulWidget {
  const GoogleCalendarConnectionTile({
    super.key,
    this.repository,
    this.launch = launchUrl,
  });

  final GoogleCalendarConnectionRepository? repository;
  final Future<bool> Function(Uri, {LaunchMode mode}) launch;

  @override
  State<GoogleCalendarConnectionTile> createState() => _GoogleCalendarConnectionTileState();
}

class _GoogleCalendarConnectionTileState extends State<GoogleCalendarConnectionTile>
    with WidgetsBindingObserver {
  late final GoogleCalendarConnectionRepository _repository;
  GoogleCalendarTileState _state = GoogleCalendarTileState.loading;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? GoogleCalendarConnectionRepository.firebase();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    try {
      final status = await _repository.status();
      if (mounted) setState(() => _state = status.connected ? GoogleCalendarTileState.connected : GoogleCalendarTileState.disconnected);
    } catch (_) {
      if (mounted) setState(() => _state = GoogleCalendarTileState.error);
    }
  }

  Future<void> _connect() async {
    setState(() => _state = GoogleCalendarTileState.connecting);
    try {
      final uri = await _repository.begin();
      final opened = await widget.launch(uri, mode: LaunchMode.externalApplication);
      if (!opened) throw StateError('Could not launch OAuth URL');
      // Opening a browser is not success. The callback-backed status remains authoritative.
      if (mounted) setState(() => _state = GoogleCalendarTileState.disconnected);
    } catch (_) {
      if (mounted) setState(() => _state = GoogleCalendarTileState.error);
    }
  }

  Future<void> _disconnect() async {
    setState(() => _state = GoogleCalendarTileState.connecting);
    try {
      await _repository.disconnect();
      if (mounted) setState(() => _state = GoogleCalendarTileState.disconnected);
    } catch (_) {
      if (mounted) setState(() => _state = GoogleCalendarTileState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _state == GoogleCalendarTileState.loading || _state == GoogleCalendarTileState.connecting;
    final connected = _state == GoogleCalendarTileState.connected;
    final subtitle = switch (_state) {
      GoogleCalendarTileState.loading => '確認中',
      GoogleCalendarTileState.connecting => '処理中',
      GoogleCalendarTileState.connected => '連携済み',
      GoogleCalendarTileState.error => 'エラー（タップして再試行）',
      GoogleCalendarTileState.disconnected => '未連携',
    };
    return ListTile(
      leading: const Icon(Icons.event_available),
      title: const Text('Google Calendar'),
      subtitle: Text(subtitle),
      onTap: _state == GoogleCalendarTileState.error ? _refresh : null,
      trailing: busy
          ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2))
          : connected
              ? TextButton(onPressed: _disconnect, child: const Text('連携解除'))
              : FilledButton(onPressed: _connect, child: const Text('Google Calendarと連携')),
    );
  }
}
