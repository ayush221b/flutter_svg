import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Fetches an HTTP resource from the specified [url] using the specified [headers].
Future<Uint8List> httpGet(String url, {Map<String, String> headers}) async {
  final HttpClient httpClient = HttpClient();
  final Uri uri = Uri.base.resolve(url);
  final String _hash = _getBase64EncodedUrl(url);

  // Now before we make the api call, lets check if this file is in cache
  final File _cachedFile = await _getFileFromCache(_hash);
  Uint8List _responseBytes;
  if (_cachedFile == null || _cachedFile.lengthSync() <= 0) {
    final HttpClientRequest request = await httpClient.getUrl(uri);
    if (headers != null) {
      headers.forEach((String key, String value) {
        request.headers.add(key, value);
      });
    }
    final HttpClientResponse response = await request.close();

    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('Could not get network asset', uri: uri);
    }

    _responseBytes = await consolidateHttpClientResponseBytes(response);
    _putFileInCache(_hash, _responseBytes);
  } else {
    _responseBytes = _cachedFile.readAsBytesSync();
  }

  return _responseBytes;
}

Future<File> _getFileFromCache(String hash) async {
  try {
    return (await DefaultCacheManager().getFileFromCache(hash)).file;
  } catch (err, stacktrace) {
    print(err);
    print(stacktrace);
    return null;
  }
}

Future<void> _putFileInCache(String hash, Uint8List responseBytes) async {
  try {
    await DefaultCacheManager().putFile(hash, responseBytes);
  } catch (err, stacktrace) {
    print(err);
    print(stacktrace);
  }
}

String _getBase64EncodedUrl(String url) {
  return base64Url.encode(utf8.encode(url));
}
