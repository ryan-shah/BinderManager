import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Progress information for a Scryfall bulk download.
class DownloadProgress {
  /// Bytes received so far.
  final int bytesReceived;

  /// Total expected bytes, or null if the server didn't send Content-Length.
  final int? totalBytes;

  const DownloadProgress(this.bytesReceived, this.totalBytes);

  /// Fraction complete in [0.0, 1.0], or null if total is unknown.
  double? get fraction =>
      totalBytes != null && totalBytes! > 0 ? bytesReceived / totalBytes! : null;

  @override
  String toString() {
    final pct = fraction;
    if (pct != null) {
      return '${(pct * 100).toStringAsFixed(1)}%'
          ' ($bytesReceived / $totalBytes bytes)';
    }
    return '$bytesReceived bytes';
  }
}

/// Downloads the Scryfall Default Cards bulk JSON.
///
/// 1. Hits the Scryfall bulk-data endpoint to discover the download URI.
/// 2. Stream-downloads the JSON, reporting progress via [onProgress].
/// 3. Returns the complete bytes of the JSON file.
///
/// For a ~150 MB download this will hold the full payload in memory. If
/// memory pressure becomes an issue, consider writing to a temp file and
/// returning its path instead.
class ScryfallDownloader {
  static const _bulkDataUrl = 'https://api.scryfall.com/bulk-data';

  final http.Client _client;

  ScryfallDownloader({http.Client? client}) : _client = client ?? http.Client();

  /// Discovers the download URI for the "default_cards" bulk data type.
  Future<Uri> _resolveDownloadUri() async {
    final response = await _client.get(Uri.parse(_bulkDataUrl));

    if (response.statusCode != 200) {
      throw ScryfallDownloadException(
        'Failed to fetch bulk-data catalog: HTTP ${response.statusCode}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>;

    for (final entry in data) {
      final map = entry as Map<String, dynamic>;
      if (map['type'] == 'default_cards') {
        return Uri.parse(map['download_uri'] as String);
      }
    }

    throw const ScryfallDownloadException(
      'No "default_cards" entry found in Scryfall bulk-data catalog.',
    );
  }

  /// Downloads the Default Cards JSON, calling [onProgress] periodically.
  ///
  /// Returns the raw bytes of the JSON payload.
  Future<List<int>> download({
    void Function(DownloadProgress progress)? onProgress,
  }) async {
    final uri = await _resolveDownloadUri();

    final request = http.Request('GET', uri);
    final streamedResponse = await _client.send(request);

    if (streamedResponse.statusCode != 200) {
      throw ScryfallDownloadException(
        'Failed to download bulk data: HTTP ${streamedResponse.statusCode}',
      );
    }

    final totalBytes = streamedResponse.contentLength;
    var bytesReceived = 0;
    final builder = BytesBuilder(copy: false);

    await for (final chunk in streamedResponse.stream) {
      builder.add(chunk);
      bytesReceived += chunk.length;
      onProgress?.call(DownloadProgress(bytesReceived, totalBytes));
    }

    return builder.takeBytes();
  }

  /// Releases underlying HTTP resources.
  void close() => _client.close();
}

/// Thrown when a Scryfall download operation fails.
class ScryfallDownloadException implements Exception {
  final String message;
  const ScryfallDownloadException(this.message);

  @override
  String toString() => 'ScryfallDownloadException: $message';
}
