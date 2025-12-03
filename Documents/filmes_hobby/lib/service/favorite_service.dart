import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteService {
  static const String key = "favoritos";

  // --------------------------
  // BUSCAR FAVORITOS
  // --------------------------
  static Future<List> getFavoritos() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(key);

    if (data == null) return [];
    return jsonDecode(data);
  }

  // --------------------------
  // ADICIONAR FAVORITO
  // --------------------------
  static Future<void> addFavorito(Map filme) async {
    final prefs = await SharedPreferences.getInstance();
    final favoritos = await getFavoritos();

    // evita duplicados
    bool existe = favoritos.any((f) => f["imdbID"] == filme["imdbID"]);
    if (!existe) {
      favoritos.add(filme);
    }

    await prefs.setString(key, jsonEncode(favoritos));
  }

  // --------------------------
  // REMOVER FAVORITO
  // --------------------------
  static Future<void> removeFavorito(String imdbID) async {
    final prefs = await SharedPreferences.getInstance();
    final favoritos = await getFavoritos();

    favoritos.removeWhere((f) => f["imdbID"] == imdbID);

    await prefs.setString(key, jsonEncode(favoritos));
  }

  // --------------------------
  // VERIFICAR SE ESTÁ FAVORITADO
  // --------------------------
  static Future<bool> isFavorito(String imdbID) async {
    final favoritos = await getFavoritos();
    return favoritos.any((f) => f["imdbID"] == imdbID);
  }
}
