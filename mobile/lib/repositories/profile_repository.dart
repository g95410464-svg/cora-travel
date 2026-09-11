import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/traveler_profile.dart';

class ProfileRepository {
  static const _key = 'cora.traveler.v1';
  Future<TravelerProfile?> load() async {
    final storage = await SharedPreferences.getInstance();
    final value = storage.getString(_key);
    if (value == null) return null;
    try {
      return TravelerProfile.fromJson(
          jsonDecode(value) as Map<String, dynamic>);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<void> save(TravelerProfile profile) async {
    final storage = await SharedPreferences.getInstance();
    if (!await storage.setString(_key, jsonEncode(profile.toJson()))) {
      throw StateError('No se pudo guardar el perfil');
    }
  }

  Future<void> clear() async {
    final storage = await SharedPreferences.getInstance();
    if (!await storage.remove(_key)) {
      throw StateError('No se pudo borrar el perfil');
    }
  }
}
