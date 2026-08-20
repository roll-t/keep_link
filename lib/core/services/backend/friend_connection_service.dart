import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';

class FriendConnectionPayload {
  const FriendConnectionPayload({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.rawLink,
  });

  final String userId;
  final String displayName;
  final String? email;
  final String? photoUrl;
  final String rawLink;
}

class FriendConnectionService {
  FriendConnectionService._();

  static const _scheme = 'keeplink';
  static const _host = 'open';
  static const _path = '/friend';

  static String buildLink(User user) {
    final payload = {
      'uid': user.uid,
      'displayName': user.displayName ?? '',
      'email': user.email,
      'photoUrl': user.photoURL,
      'ts': DateTime.now().toIso8601String(),
    };

    final encoded = base64Url.encode(utf8.encode(jsonEncode(payload)));
    return Uri(
      scheme: _scheme,
      host: _host,
      path: _path,
      queryParameters: {'data': encoded},
    ).toString();
  }

  static FriendConnectionPayload? parseLink(String rawInput) {
    final link = _extractLink(rawInput.trim());
    if (link == null) return null;

    final uri = Uri.tryParse(link);
    if (uri == null ||
        uri.scheme != _scheme ||
        uri.host != _host ||
        uri.path != _path ||
        !uri.queryParameters.containsKey('data')) {
      return null;
    }

    final encoded = uri.queryParameters['data'];
    if (encoded == null || encoded.isEmpty) return null;

    try {
      final normalized = base64Url.normalize(encoded);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      final userId = (json['uid'] ?? '').toString();
      final displayName = (json['displayName'] ?? '').toString();
      if (userId.isEmpty || displayName.isEmpty) return null;

      return FriendConnectionPayload(
        userId: userId,
        displayName: displayName,
        email: json['email']?.toString(),
        photoUrl: json['photoUrl']?.toString(),
        rawLink: link,
      );
    } catch (_) {
      return null;
    }
  }

  static String? _extractLink(String rawInput) {
    if (rawInput.isEmpty) return null;
    if (rawInput.startsWith('$_scheme://')) {
      return rawInput;
    }

    final match = RegExp(r'keeplink://open/friend\?data=[^\s]+').firstMatch(rawInput);
    return match?.group(0);
  }
}
