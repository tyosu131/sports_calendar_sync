import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/repositories/google_calendar_connection_repository.dart';

enum GoogleCalendarTileState { loading, disconnected, connecting, syncing, connected, syncError, reauthRequired, error }

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
  bool _awaitingOAuth = false;

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
    if (state == AppLifecycleState.resumed) _refresh(afterOAuth: _awaitingOAuth);
  }

  Future<void> _refresh({bool afterOAuth = false}) async {
    try {
      GoogleCalendarConnectionStatus status;
      // The HTTPS callback can finish just after app resume. Poll for at most
      // ~6 seconds; backend state, not browser launch, remains authoritative.
      if (afterOAuth) {
        if (mounted) setState(() => _state = GoogleCalendarTileState.connecting);
        status = await _repository.waitForConnection();
      } else { status = await _repository.status(); }
      _awaitingOAuth = false;
      if (!mounted) return;
      if (status.reauthRequired) {
        setState(() => _state = GoogleCalendarTileState.reauthRequired);
      } else if (!status.connected) {
        setState(() => _state = GoogleCalendarTileState.disconnected);
      } else if (status.syncStatus == 'error') {
        setState(() => _state = GoogleCalendarTileState.syncError);
      } else if (status.syncStatus == 'synced') {
        setState(() => _state = GoogleCalendarTileState.connected);
      } else {
        setState(() => _state = GoogleCalendarTileState.syncing);
        await _sync();
      }
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
      _awaitingOAuth = true;
      if (mounted) setState(() => _state = GoogleCalendarTileState.connecting);
    } catch (_) {
      if (mounted) setState(() => _state = GoogleCalendarTileState.error);
    }
  }

  Future<void> _sync() async {
    if (mounted) setState(() => _state = GoogleCalendarTileState.syncing);
    try {
      final result = await _repository.syncNow();
      if (mounted) setState(() => _state = result == 'synced' ? GoogleCalendarTileState.connected : GoogleCalendarTileState.reauthRequired);
    } catch (_) { if (mounted) setState(() => _state = GoogleCalendarTileState.syncError); }
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
    final busy = _state == GoogleCalendarTileState.loading || _state == GoogleCalendarTileState.connecting || _state == GoogleCalendarTileState.syncing;
    final connected = _state == GoogleCalendarTileState.connected ||
        _state == GoogleCalendarTileState.syncError || _state == GoogleCalendarTileState.syncing;
    final subtitle = switch (_state) {
      GoogleCalendarTileState.loading => '確認中',
      GoogleCalendarTileState.connecting => '処理中',
      GoogleCalendarTileState.syncing => '連携済み・同期中',
      GoogleCalendarTileState.connected => '連携済み・同期済み',
      GoogleCalendarTileState.syncError => '連携済み・同期エラー（タップして再試行）',
      GoogleCalendarTileState.reauthRequired => '再連携が必要です',
      GoogleCalendarTileState.error => 'エラー（タップして再試行）',
      GoogleCalendarTileState.disconnected => '未連携',
    };
    return ListTile(
      leading: const Icon(Icons.event_available),
      title: const Text('Google Calendar'),
      subtitle: Text(subtitle),
      onTap: _state == GoogleCalendarTileState.error ? _refresh : _state == GoogleCalendarTileState.syncError ? _sync : null,
      trailing: busy
          ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2))
          : connected
              ? TextButton(onPressed: _disconnect, child: const Text('連携解除'))
              : FilledButton(onPressed: _connect, child: Text(_state == GoogleCalendarTileState.reauthRequired ? '再連携' : 'Google Calendarと連携')),
    );
  }
}
