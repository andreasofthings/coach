import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:matrix/matrix.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqlite;

class ChatProvider extends ChangeNotifier {
  Client? _client;
  Room? _room;
  bool _isLoading = false;
  String? _error;
  final String _roomAlias = '#sauna:pramari.de';
  final String _homeserverUrl = 'matrix.pramari.de';

  Client? get client => _client;
  Room? get room => _room;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize(String? token) async {
    if (token == null) {
      _error = 'No token available';
      notifyListeners();
      return;
    }

    if (_client != null && _client!.isLogged()) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      dynamic database;

      if (kIsWeb) {
        // On Web, use the default MatrixSdkDatabase.init which uses web-compatible storage
        database = await MatrixSdkDatabase.init('CoachChat');
      } else {
        // On Native platforms, use sqflite with path_provider
        final directory = await getApplicationSupportDirectory();
        final dbPath = '${directory.path}/matrix_sdk.db';
        database = await MatrixSdkDatabase.init(
          'CoachChat',
          database: await sqlite.openDatabase(dbPath),
        );
      }

      _client = Client(
        'CoachChat',
        database: database,
      );

      await _client!.init();

      await _client!.checkHomeserver(Uri.https(_homeserverUrl, ''));

      // Login with JWT using raw string for login type
      await _client!.login(
        'm.login.jwt',
        token: token,
        initialDeviceDisplayName: 'Coach App',
      );

      // Join the room using joinRoom and find the room in client.rooms
      final roomId = await _client!.joinRoom(_roomAlias);
      _room = _client!.getRoomById(roomId);

      _client!.onSync.stream.listen((SyncUpdate update) {
        notifyListeners();
      });

    } catch (e) {
      _error = 'Chat error: $e';
      debugPrint('Chat initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String text) async {
    if (_room == null) return;
    try {
      await _room!.sendTextEvent(text);
    } catch (e) {
      _error = 'Send error: $e';
      notifyListeners();
    }
  }

  Future<void> leaveRoom() async {
    if (_room != null) {
      try {
        await _room!.leave();
        _room = null;
        notifyListeners();
      } catch (e) {
        debugPrint('Error leaving room: $e');
      }
    }
  }
}
