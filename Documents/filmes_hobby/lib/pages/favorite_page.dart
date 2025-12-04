import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'info_page.dart';
import 'add_movie_page.dart'; // Nova página que vamos criar

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  static const String _favoritesKey = 'favoriteMovies'; 
  List<Map<String, dynamic>> _favoriteMovies = [];
  bool _isLoading = true;
  
  String fallback = "assets/sem_imagem.png";

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }
  
  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final List<String> favoritesJsonList = prefs.getStringList(_favoritesKey) ?? [];
    final List<Map<String, dynamic>> loadedMovies = favoritesJsonList.map((movieJson) {
      return jsonDecode(movieJson) as Map<String, dynamic>;
    }).toList();
    setState(() {
      _favoriteMovies = loadedMovies;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meus Filmes Favoritos"),
        backgroundColor: Colors.deepPurple,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navega para a página de adicionar novo filme
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddMoviePage()),
          );
          // Recarrega favoritos ao voltar
          _loadFavorites();
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.deepPurple,
        tooltip: "Adicionar novo filme",
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favoriteMovies.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      "Você não tem nenhum filme favorito ainda. Adicione alguns tocando no ícone de coração!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _favoriteMovies.length,
                  itemBuilder: (context, index) {
                    final filme = _favoriteMovies[index];
                    bool temPoster =
                        filme["Poster"] != null &&
                        filme["Poster"] != "N/A" &&
                        filme["Poster"].toString().startsWith("http");

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      elevation: 4,
                      child: ListTile(
                        leading: SizedBox(
                          width: 60,
                          height: 80,
                          child: temPoster
                              ? Image.network(
                                  filme["Poster"],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(fallback, fit: BoxFit.cover);
                                  },
                                )
                              : Image.asset(fallback, fit: BoxFit.cover),
                        ),
                        title: Text(filme["Title"] ?? "Filme Sem Título",
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(filme["Year"] ?? "Ano não disponível",
                            style: const TextStyle(color: Colors.grey)),
                        trailing: const Icon(Icons.favorite, color: Colors.red),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => InfoPage(filme: filme)),
                          );
                          _loadFavorites(); 
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
