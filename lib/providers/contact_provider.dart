import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/contact.dart';
import 'auth_provider.dart';

class SyncResult {
  final bool success;
  final String? connectUrl;
  final String? error;

  SyncResult({required this.success, this.connectUrl, this.error});
}

class ContactProvider extends ChangeNotifier {
  AuthProvider? _auth;
  List<Contact> _contacts = [];
  bool _isLoading = false;

  ContactProvider(this._auth);

  List<Contact> get contacts => _contacts;
  bool get isLoading => _isLoading;

  String get _baseUrl => 'https://www.pramari.de/coach/api/v1/contacts';

  void updateAuth(AuthProvider? auth) {
    _auth = auth;
    if (_auth?.accessToken != null && _contacts.isEmpty) {
      fetchContacts();
    }
  }

  Future<void> fetchContacts({bool isRetry = false}) async {
    final token = _auth?.accessToken;
    if (token == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(response.body);
        final List<dynamic> data = (decodedData is Map) ? (decodedData["results"] ?? decodedData["items"] ?? []) : decodedData;
        _contacts = data.map((item) => Contact.fromMap(item)).toList();
      } else if (response.statusCode == 401 && !isRetry) {
        final refreshed = await _auth?.refresh() ?? false;
        if (refreshed) {
          return await fetchContacts(isRetry: true);
        }
      }
    } catch (e) {
      debugPrint('Error fetching contacts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addContact(Contact contact) async {
    return _addContactInternal(contact, isRetry: false);
  }

  Future<bool> _addContactInternal(Contact contact, {required bool isRetry}) async {
    final token = _auth?.accessToken;
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: contact.toJson(),
      );

      if (response.statusCode == 201) {
        final newContact = Contact.fromMap(jsonDecode(response.body));
        _contacts.add(newContact);
        notifyListeners();
        return true;
      } else if (response.statusCode == 401 && !isRetry) {
        final refreshed = await _auth?.refresh() ?? false;
        if (refreshed) {
          return await _addContactInternal(contact, isRetry: true);
        }
      }
    } catch (e) {
      debugPrint('Error adding contact: $e');
    }
    return false;
  }

  Future<bool> updateContact(Contact contact) async {
    return _updateContactInternal(contact, isRetry: false);
  }

  Future<bool> _updateContactInternal(Contact contact, {required bool isRetry}) async {
    final token = _auth?.accessToken;
    if (token == null) return false;

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/${contact.id}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: contact.toJson(),
      );

      if (response.statusCode == 200) {
        final updated = Contact.fromMap(jsonDecode(response.body));
        final idx = _contacts.indexWhere((c) => c.id == contact.id);
        if (idx != -1) {
          _contacts[idx] = updated;
          notifyListeners();
        }
        return true;
      } else if (response.statusCode == 401 && !isRetry) {
        final refreshed = await _auth?.refresh() ?? false;
        if (refreshed) {
          return await _updateContactInternal(contact, isRetry: true);
        }
      }
    } catch (e) {
      debugPrint('Error updating contact: $e');
    }
    return false;
  }

  Future<bool> deleteContact(String id) async {
    return _deleteContactInternal(id, isRetry: false);
  }

  Future<bool> _deleteContactInternal(String id, {required bool isRetry}) async {
    final token = _auth?.accessToken;
    if (token == null) return false;

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        _contacts.removeWhere((c) => c.id == id);
        notifyListeners();
        return true;
      } else if (response.statusCode == 401 && !isRetry) {
        final refreshed = await _auth?.refresh() ?? false;
        if (refreshed) {
          return await _deleteContactInternal(id, isRetry: true);
        }
      }
    } catch (e) {
      debugPrint('Error deleting contact: $e');
    }
    return false;
  }

  Future<SyncResult> syncGoogleContacts({bool isRetry = false}) async {
    final token = _auth?.accessToken;
    if (token == null) return SyncResult(success: false, error: 'No access token');

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sync_google_contacts/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await fetchContacts();
        return SyncResult(success: true);
      } else if (response.statusCode == 401) {
        final body = jsonDecode(response.body);
        if (body is Map && body.containsKey('connect_url')) {
          return SyncResult(
            success: false,
            connectUrl: body['connect_url'],
          );
        }

        if (!isRetry) {
          final refreshed = await _auth?.refresh() ?? false;
          if (refreshed) {
            return await syncGoogleContacts(isRetry: true);
          }
        }
      }
      return SyncResult(success: false, error: 'Sync failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('Error syncing google contacts: $e');
      return SyncResult(success: false, error: e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
