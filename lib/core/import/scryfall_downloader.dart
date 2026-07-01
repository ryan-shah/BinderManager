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

/// A streaming download handle for Scryfall bulk data.
///
/// Provides the raw byte [stream] for consumption without buffering the
/// entire payload in memory, plus [totalBytes] for progress tracking.
class ScryfallDownload {
  /// The raw byte stream from the HTTP response body.
  final Stream<List<int>> stream;

  /// Expected total bytes from Content-Length, or null if unknown.
  final int? totalBytes;

  ScryfallDownload({required this.stream, this.totalBytes});
}

/// Downloads the Scryfall Default Cards bulk JSON.
///
/// 1. Hits the Scryfall bulk-data endpoint to discover the download URI.
/// 2. Returns a [ScryfallDownload] with the byte stream and size metadata.
///
/// The caller is responsible for consuming the stream. For large payloads
/// (~150 MB), pipe the stream directly into a parser rather than buffering
/// all bytes in memory.
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

  /// Opens a streaming download of the Default Cards JSON.
  ///
  /// Returns a [ScryfallDownload] whose [ScryfallDownload.stream] yields
  /// byte chunks as they arrive. Consume the stream to drive the download.
  Future<ScryfallDownload> downloadStream() async {
    final uri = await _resolveDownloadUri();

    final request = http.Request('GET', uri);
    final streamedResponse = await _client.send(request);

    if (streamedResponse.statusCode != 200) {
      throw ScryfallDownloadException(
        'Failed to download bulk data: HTTP ${streamedResponse.statusCode}',
      );
    }

    return ScryfallDownload(
      stream: streamedResponse.stream,
      totalBytes: streamedResponse.contentLength,
    );
  }

  /// Downloads the Default Cards JSON into memory.
  ///
  /// Convenience wrapper around [downloadStream] for tests and native
  /// platforms where memory is not constrained. On web, prefer
  /// [downloadStream] to avoid holding ~150 MB in a single allocation.
  Future<List<int>> download({
    void Function(DownloadProgress progress)? onProgress,
  }) async {
    final dl = await downloadStream();
    var bytesReceived = 0;
    final builder = BytesBuilder(copy: false);

    await for (final chunk in dl.stream) {
      builder.add(chunk);
      bytesReceived += chunk.length;
      onProgress?.call(DownloadProgress(bytesReceived, dl.totalBytes));
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
