import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'package:http/http.dart' as http;

class AuthProvider extends ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final _appLinks = AppLinks();

  bool _isAuthenticated = false;
  String? _accessToken;
  String? _idToken;
  String? _refreshToken;
  Future<bool>? _refreshFuture;

  bool get isAuthenticated => _isAuthenticated;
  String? get accessToken => _accessToken;
  String? get idToken => _idToken;

  final _linkController = StreamController<Uri>.broadcast();
  Stream<Uri> get linkStream => _linkController.stream;

  AuthProvider() {
    _init();
  }

  @override
  void dispose() {
    _linkController.close();
    super.dispose();
  }

  Future<void> _init() async {
    await _loadTokens();
    _handleIncomingLinks();
  }

  Future<void> _loadTokens() async {
    try {
      _accessToken = await _secureStorage.read(key: 'access_token');
      _idToken = await _secureStorage.read(key: 'id_token');
      _refreshToken = await _secureStorage.read(key: 'refresh_token');

      if (_accessToken != null) {
        _isAuthenticated = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading tokens from secure storage: $e');
    }
  }

  void _handleIncomingLinks() {
    _appLinks.uriLinkStream.listen((uri) {
      _processCallbackUri(uri);
    });

    // Check initial link
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _processCallbackUri(uri);
      }
    });
  }

  Future<void> _processCallbackUri(Uri uri) async {
    _linkController.add(uri);
    final code = uri.queryParameters['code'];
    if (code != null) {
      debugPrint('Received code from redirect: $code');
      await _exchangeCodeForTokens(code);
    }
  }

  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~';
    final random = Random.secure();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }

  String _generateCodeChallenge(String verifier) {
    var bytes = utf8.encode(verifier);
    var digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  String? _getConfigValue(String key) {
    String value = '';
    switch (key) {
      case 'OAUTH_CLIENT_ID':
        value = const String.fromEnvironment('OAUTH_CLIENT_ID');
        break;
      case 'OAUTH_REDIRECT_URL':
        value = const String.fromEnvironment('OAUTH_REDIRECT_URL');
        if (value.isEmpty) {
          value = kIsWeb
              ? 'https://coach.pramari.de/login-callback.html'
              : 'de.pramari.coach:/oauth2redirect';
        }
        break;
      case 'OAUTH_DISCOVERY_URL':
        value = const String.fromEnvironment('OAUTH_DISCOVERY_URL');
        if (value.isEmpty) {
          value = 'https://id.pramari.de/application/o/coach/.well-known/openid-configuration';
        }
        break;
      case 'OAUTH_AUTHORIZATION_ENDPOINT':
        value = const String.fromEnvironment('OAUTH_AUTHORIZATION_ENDPOINT');
        break;
      case 'OAUTH_TOKEN_ENDPOINT':
        value = const String.fromEnvironment('OAUTH_TOKEN_ENDPOINT');
        break;
      default:
        return null;
    }
    return _sanitizeUrl(value);
  }

  String? _sanitizeUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    // Automatically replace /innovation/ with /coach/ to fix outdated environment variables
    return url.replaceAll('/innovation/', '/coach/');
  }
  void _validateEnv() {
    final clientId = _getConfigValue('OAUTH_CLIENT_ID');
    if (clientId == null || clientId.isEmpty) {
      throw Exception('OAUTH_CLIENT_ID is not defined. Please build with --dart-define=OAUTH_CLIENT_ID=...');
    }
  }

  Future<void> login({String? flow, String? idpHint}) async {
    try {
      _validateEnv();

      final clientId = _getConfigValue('OAUTH_CLIENT_ID')!;
      final redirectUrl = _getConfigValue('OAUTH_REDIRECT_URL')!;
      final discoveryUrl = _getConfigValue('OAUTH_DISCOVERY_URL')!;
      final authEndpoint = _getConfigValue('OAUTH_AUTHORIZATION_ENDPOINT');

      final effectiveFlow = flow ?? 'coach-login';

      if (kIsWeb) {
        String finalAuthEndpoint = '';
        if (authEndpoint != null && authEndpoint.isNotEmpty) {
          finalAuthEndpoint = authEndpoint;
        } else {
          debugPrint('Fetching discovery doc from $discoveryUrl');
          final response = await http.get(Uri.parse(discoveryUrl));
          if (response.statusCode != 200) throw Exception('Failed to load discovery document: ${response.statusCode}');
          final discovery = jsonDecode(response.body);
          finalAuthEndpoint = discovery['authorization_endpoint'];
        }

        // 2. Prepare PKCE
        final verifier = _generateRandomString(64);
        await _secureStorage.write(key: 'code_verifier', value: verifier);
        final challenge = _generateCodeChallenge(verifier);

        // 3. Construct Auth URL
        final Map<String, String> queryParams = {
          'client_id': clientId,
          'redirect_uri': redirectUrl,
          'response_type': 'code',
          'scope': 'openid profile email offline_access https://www.googleapis.com/auth/contacts.readonly',
          'code_challenge': challenge,
          'code_challenge_method': 'S256',
        };

        if (effectiveFlow.isNotEmpty) {
          queryParams['authentik_flow'] = effectiveFlow;
        }
        if (idpHint != null && idpHint.isNotEmpty) {
          queryParams['idp_hint'] = idpHint;
        }

        final authUri = Uri.parse(finalAuthEndpoint).replace(queryParameters: queryParams);

        // 4. Redirect
        if (await canLaunchUrl(authUri)) {
          await launchUrl(authUri, webOnlyWindowName: '_self');
        } else {
          throw Exception('Could not launch $authUri');
        }
        return;
      }

      // Native platform logic
      debugPrint('Starting native login with clientId: $clientId, redirectUrl: $redirectUrl');

      final Map<String, String> additionalParameters = {};
      if (effectiveFlow.isNotEmpty) {
        additionalParameters['authentik_flow'] = effectiveFlow;
      }
      if (idpHint != null && idpHint.isNotEmpty) {
        additionalParameters['idp_hint'] = idpHint;
      }

      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          clientId,
          redirectUrl,
          discoveryUrl: discoveryUrl,
          scopes: ['openid', 'profile', 'email', 'offline_access', 'https://www.googleapis.com/auth/contacts.readonly'],
          additionalParameters: additionalParameters.isNotEmpty ? additionalParameters : null,
        ),
      );

      if (result != null) {
        await _saveTokens(result.accessToken, result.idToken, result.refreshToken);
      }
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    }
  }

  Future<void> _exchangeCodeForTokens(String code) async {
    try {
      final clientId = _getConfigValue('OAUTH_CLIENT_ID')!;
      final redirectUrl = _getConfigValue('OAUTH_REDIRECT_URL')!;
      final discoveryUrl = _getConfigValue('OAUTH_DISCOVERY_URL')!;
      final tokenEndpoint = _getConfigValue('OAUTH_TOKEN_ENDPOINT');
      final verifier = await _secureStorage.read(key: 'code_verifier');

      String finalTokenEndpoint = '';
      if (tokenEndpoint != null && tokenEndpoint.isNotEmpty) {
        finalTokenEndpoint = tokenEndpoint;
      } else {
        final response = await http.get(Uri.parse(discoveryUrl));
        final discovery = jsonDecode(response.body);
        finalTokenEndpoint = discovery['token_endpoint'];
      }

      final tokenResponse = await http.post(
        Uri.parse(finalTokenEndpoint),
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': redirectUrl,
          'client_id': clientId,
          'code_verifier': verifier ?? '',
        },
      );

      if (tokenResponse.statusCode == 200) {
        final data = jsonDecode(tokenResponse.body);
        await _saveTokens(data['access_token'], data['id_token'], data['refresh_token']);
        await _secureStorage.delete(key: 'code_verifier');
      } else {
        debugPrint('Token exchange failed: ${tokenResponse.body}');
      }
    } catch (e) {
      debugPrint('Error exchanging code: $e');
    }
  }

  Future<void> _saveTokens(String? access, String? id, String? refresh) async {
    _accessToken = access;
    _idToken = id;
    _refreshToken = refresh;

    if (_accessToken != null) {
      await _secureStorage.write(key: 'access_token', value: _accessToken);
      if (_idToken != null) await _secureStorage.write(key: 'id_token', value: _idToken);
      if (_refreshToken != null) await _secureStorage.write(key: 'refresh_token', value: _refreshToken);

      _isAuthenticated = true;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _accessToken = null;
    _idToken = null;
    _refreshToken = null;
    _isAuthenticated = false;

    try {
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'id_token');
      await _secureStorage.delete(key: 'refresh_token');
    } catch (e) {
      debugPrint('Error clearing tokens during logout: $e');
    }

    notifyListeners();
  }

  Future<bool> refresh() async {
    if (_refreshToken == null) return false;
    if (_refreshFuture != null) return _refreshFuture!;

    _refreshFuture = _doRefresh();
    try {
      return await _refreshFuture!;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<bool> _doRefresh() async {
    try {
      _validateEnv();
      final clientId = _getConfigValue('OAUTH_CLIENT_ID')!;
      final redirectUrl = _getConfigValue('OAUTH_REDIRECT_URL')!;
      final discoveryUrl = _getConfigValue('OAUTH_DISCOVERY_URL')!;
      final tokenEndpoint = _getConfigValue('OAUTH_TOKEN_ENDPOINT');

      if (kIsWeb) {
        String finalTokenEndpoint = '';
        if (tokenEndpoint != null && tokenEndpoint.isNotEmpty) {
          finalTokenEndpoint = tokenEndpoint;
        } else {
          final response = await http.get(Uri.parse(discoveryUrl));
          final discovery = jsonDecode(response.body);
          finalTokenEndpoint = discovery['token_endpoint'];
        }

        final refreshResponse = await http.post(
          Uri.parse(finalTokenEndpoint),
          body: {
            'grant_type': 'refresh_token',
            'client_id': clientId,
            'refresh_token': _refreshToken,
          },
        );

        if (refreshResponse.statusCode == 200) {
          final data = jsonDecode(refreshResponse.body);
          await _saveTokens(data['access_token'], data['id_token'], data['refresh_token']);
          return true;
        } else {
          await logout();
          return false;
        }
      }

      final result = await _appAuth.token(
        TokenRequest(
          clientId,
          redirectUrl,
          discoveryUrl: discoveryUrl,
          refreshToken: _refreshToken,
          scopes: ['openid', 'profile', 'email', 'offline_access', 'https://www.googleapis.com/auth/contacts.readonly'],
        ),
      );

      // result is TokenResponse which is non-nullable in newer flutter_appauth or at least the analyzer thinks so
      await _saveTokens(result.accessToken, result.idToken, result.refreshToken);
      return true;
    } catch (e) {
      debugPrint('Refresh token error: $e');
      await logout();
      return false;
    }
  }
}
