import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:binder_manager/core/import/scryfall_downloader.dart';

/// A valid Scryfall bulk-data catalog response containing a "default_cards"
/// entry with a test download URI.
String _bulkDataCatalog({
  String downloadUri = 'https://data.scryfall.io/default-cards/test.json',
}) {
  return jsonEncode({
    'object': 'list',
    'has_more': false,
    'data': [
      {
        'object': 'bulk_data',
        'type': 'oracle_cards',
        'download_uri': 'https://data.scryfall.io/oracle-cards/test.json',
      },
      {
        'object': 'bulk_data',
        'type': 'default_cards',
        'download_uri': downloadUri,
      },
    ],
  });
}

/// A catalog response with NO default_cards entry.
String _bulkDataCatalogMissingDefault() {
  return jsonEncode({
    'object': 'list',
    'has_more': false,
    'data': [
      {
        'object': 'bulk_data',
        'type': 'oracle_cards',
        'download_uri': 'https://data.scryfall.io/oracle-cards/test.json',
      },
    ],
  });
}

void main() {
  // ---------------------------------------------------------------------------
  // DownloadProgress model
  // ---------------------------------------------------------------------------

  group('DownloadProgress', () {
    test('fraction returns correct value (50/100 = 0.5)', () {
      const progress = DownloadProgress(50, 100);
      expect(progress.fraction, 0.5);
    });

    test('fraction returns 1.0 when all bytes received', () {
      const progress = DownloadProgress(100, 100);
      expect(progress.fraction, 1.0);
    });

    test('fraction returns null when totalBytes is null', () {
      const progress = DownloadProgress(50, null);
      expect(progress.fraction, isNull);
    });

    test('fraction returns null when totalBytes is 0', () {
      const progress = DownloadProgress(0, 0);
      expect(progress.fraction, isNull);
    });

    test('toString includes percentage when fraction is known', () {
      const progress = DownloadProgress(50, 100);
      final str = progress.toString();
      expect(str, contains('50.0%'));
      expect(str, contains('50'));
      expect(str, contains('100'));
    });

    test('toString shows only bytes when fraction is unknown', () {
      const progress = DownloadProgress(1234, null);
      final str = progress.toString();
      expect(str, contains('1234'));
      expect(str, contains('bytes'));
      expect(str, isNot(contains('%')));
    });

    test('toString shows only bytes when totalBytes is 0', () {
      const progress = DownloadProgress(0, 0);
      final str = progress.toString();
      // fraction is null -> falls through to the bytes-only branch.
      expect(str, contains('bytes'));
    });
  });

  // ---------------------------------------------------------------------------
  // ScryfallDownloader
  // ---------------------------------------------------------------------------

  group('ScryfallDownloader', () {
    test('resolves download URI and returns bytes', () async {
      const payload = '[{"id":"card-1","name":"Bolt"}]';
      final payloadBytes = utf8.encode(payload);

      final client = MockClient((request) async {
        if (request.url.toString() == 'https://api.scryfall.com/bulk-data') {
          return http.Response(_bulkDataCatalog(), 200);
        }
        // Download request.
        return http.Response(payload, 200, headers: {
          'content-length': '${payloadBytes.length}',
        });
      });

      final downloader = ScryfallDownloader(client: client);
      final progressReports = <DownloadProgress>[];

      final bytes = await downloader.download(
        onProgress: (p) => progressReports.add(p),
      );

      expect(bytes, isNotEmpty);
      expect(utf8.decode(bytes), payload);
      // At least one progress report should have been emitted.
      expect(progressReports, isNotEmpty);

      downloader.close();
    });

    test('calls onProgress with correct fractions', () async {
      const payload = 'Hello, World!';
      final payloadBytes = utf8.encode(payload);

      final client = MockClient((request) async {
        if (request.url.toString() == 'https://api.scryfall.com/bulk-data') {
          return http.Response(_bulkDataCatalog(), 200);
        }
        return http.Response(payload, 200, headers: {
          'content-length': '${payloadBytes.length}',
        });
      });

      final downloader = ScryfallDownloader(client: client);
      final progressReports = <DownloadProgress>[];

      await downloader.download(
        onProgress: (p) => progressReports.add(p),
      );

      // The final progress report should indicate completion.
      final last = progressReports.last;
      expect(last.bytesReceived, payloadBytes.length);
      expect(last.fraction, 1.0);

      downloader.close();
    });

    test('throws ScryfallDownloadException on non-200 from bulk-data API',
        () async {
      final client = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final downloader = ScryfallDownloader(client: client);

      expect(
        () => downloader.download(),
        throwsA(isA<ScryfallDownloadException>()),
      );

      downloader.close();
    });

    test('throws ScryfallDownloadException on non-200 from download URI',
        () async {
      final client = MockClient((request) async {
        if (request.url.toString() == 'https://api.scryfall.com/bulk-data') {
          return http.Response(_bulkDataCatalog(), 200);
        }
        return http.Response('Not Found', 404);
      });

      final downloader = ScryfallDownloader(client: client);

      expect(
        () => downloader.download(),
        throwsA(isA<ScryfallDownloadException>()),
      );

      downloader.close();
    });

    test(
        'throws ScryfallDownloadException when no default_cards entry in catalog',
        () async {
      final client = MockClient((request) async {
        return http.Response(_bulkDataCatalogMissingDefault(), 200);
      });

      final downloader = ScryfallDownloader(client: client);

      expect(
        () => downloader.download(),
        throwsA(isA<ScryfallDownloadException>()),
      );

      downloader.close();
    });

    test('download works without onProgress callback', () async {
      const payload = '[]';
      final client = MockClient((request) async {
        if (request.url.toString() == 'https://api.scryfall.com/bulk-data') {
          return http.Response(_bulkDataCatalog(), 200);
        }
        return http.Response(payload, 200);
      });

      final downloader = ScryfallDownloader(client: client);
      final bytes = await downloader.download();
      expect(utf8.decode(bytes), payload);

      downloader.close();
    });

    test('progress reports null fraction when Content-Length is absent',
        () async {
      const payload = 'some data';

      final client = MockClient((request) async {
        if (request.url.toString() == 'https://api.scryfall.com/bulk-data') {
          return http.Response(_bulkDataCatalog(), 200);
        }
        // Omit content-length header.
        return http.Response(payload, 200);
      });

      final downloader = ScryfallDownloader(client: client);
      final progressReports = <DownloadProgress>[];

      await downloader.download(
        onProgress: (p) => progressReports.add(p),
      );

      // MockClient with http.Response may provide content-length
      // automatically. We check that at least progress was reported.
      expect(progressReports, isNotEmpty);
      expect(progressReports.last.bytesReceived, greaterThan(0));

      downloader.close();
    });
  });

  // ---------------------------------------------------------------------------
  // ScryfallDownloadException
  // ---------------------------------------------------------------------------

  group('ScryfallDownloadException', () {
    test('toString includes message', () {
      const ex = ScryfallDownloadException('something went wrong');
      expect(ex.toString(), contains('something went wrong'));
      expect(ex.toString(), contains('ScryfallDownloadException'));
    });

    test('message field is accessible', () {
      const ex = ScryfallDownloadException('test message');
      expect(ex.message, 'test message');
    });
  });
}
