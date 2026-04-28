// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const baseUrl = 'https://regatta.fhettinga.nl/api';

  /// Logs in an existing user. Returns a map containing 'token' and 'email'.
  /// Throws a [String] error message on failure.
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw data['error'] as String? ?? 'Inloggen mislukt.';
    }
    return data;
  }

  /// Registers a new user. Returns a map containing 'token' and 'email'.
  /// Throws a [String] error message on failure.
  Future<Map<String, dynamic>> register(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 201) {
      throw data['error'] as String? ?? 'Registratie mislukt.';
    }
    return data;
  }

  /// Returns all server tracks for this user as raw maps (includes id + filename).
  Future<List<Map<String, dynamic>>> listServerTracks(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/tracks'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);
  }

  /// Returns the list of GPX filenames already on the server for this user.
  Future<List<String>> listTrackFilenames(String token) async {
    final tracks = await listServerTracks(token);
    return tracks
        .map((e) => (e['filename'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  // ── Races ──────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> listRaces(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/races'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);
  }

  Future<void> linkTrackToRace(String token, int raceId, int trackId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/races/$raceId/tracks'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'track_id': trackId}),
    );
    if (res.statusCode != 201) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      throw data['error'] as String? ?? 'Koppelen mislukt (${res.statusCode}).';
    }
  }

  Future<void> unlinkTrackFromRace(
      String token, int raceId, int trackId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/races/$raceId/tracks/$trackId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      throw data['error'] as String? ?? 'Ontkoppelen mislukt.';
    }
  }

  Future<List<Map<String, dynamic>>> getRaceTracks(
      String token, int raceId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/races/$raceId/tracks'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);
  }

  // ── Klassen / deelnamecodes ────────────────────────────────────────────────

  /// Zoek een deelnamecode op — geeft wedstrijd+klasse info terug.
  Future<Map<String, dynamic>> lookupCode(String token, String code) async {
    final res = await http.get(
      Uri.parse('$baseUrl/join/${code.toUpperCase().trim()}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw data['error'] as String? ?? 'Onbekende code.';
    }
    return data;
  }

  /// Koppel een track via deelnamecode.
  Future<void> joinWithCode(String token, String code, int trackId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/join'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'code': code.toUpperCase().trim(), 'track_id': trackId}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      throw data['error'] as String? ?? 'Koppelen mislukt.';
    }
  }

  /// Uploads a GPX file to the server.
  /// Optionally includes [windDirectionDeg] as a form field.
  /// Throws a [String] error message on failure.
  Future<void> uploadTrack(
    File gpxFile,
    String token, {
    double? windDirectionDeg,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/tracks'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(
      await http.MultipartFile.fromPath(
        'gpx',
        gpxFile.path,
        filename: gpxFile.uri.pathSegments.last,
      ),
    );

    if (windDirectionDeg != null) {
      request.fields['wind_direction_deg'] = windDirectionDeg.toString();
    }

    final streamed = await request.send();
    if (streamed.statusCode != 201) {
      final body = await streamed.stream.bytesToString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      throw data['error'] as String? ?? 'Upload mislukt (${streamed.statusCode}).';
    }
  }
}

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
