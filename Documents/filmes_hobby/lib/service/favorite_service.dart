import 'dart:convert';
import 'dart:typed_data';
import 'package:filmes_hobby/pages/add_movie_page.dart';
import 'package:filmes_hobby/pages/info_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  static const String _favoritesKey = 'favoriteMovies';
  List<Map<String, dynamic>> _favoriteMovies = [];
  bool _isLoading = true;

  // Garanta que este caminho para a imagem de fallback esteja correto no seu projeto
  final String fallback = "assets/sem_imagem.png"; 

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  // ------------------------------------------------------
  // MÉTODO DE CARREGAMENTO
  // ------------------------------------------------------
  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final List<String> favoritesJsonList =
        prefs.getStringList(_favoritesKey) ?? [];

    final loadedMovies = favoritesJsonList.map((movieJson) {
      return jsonDecode(movieJson) as Map<String, dynamic>;
    }).toList();

    setState(() {
      _favoriteMovies = loadedMovies;
      _isLoading = false;
    });
  }

  // ------------------------------------------------------
  // MÉTODO DE REMOÇÃO (Mantido do passo anterior)
  // ------------------------------------------------------
  Future<void> _removeFavorite(int index) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Remove o filme da lista local
    _favoriteMovies.removeAt(index);

    // Converte a lista atualizada de volta para JSON
    final List<String> updatedFavoritesJsonList = _favoriteMovies.map((movie) {
      return jsonEncode(movie);
    }).toList();

    // Salva a lista atualizada no SharedPreferences
    await prefs.setStringList(_favoritesKey, updatedFavoritesJsonList);

    setState(() {}); // Força a reconstrução da lista

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Filme removido dos favoritos.')),
      );
    }
  }

  // ------------------------------------------------------
  // MÉTODO buildPoster CORRIGIDO (SOLUÇÃO PARA O BASE64)
  // ------------------------------------------------------
  Widget buildPoster(String? poster) {
    if (poster == null || poster.isEmpty) {
      return Image.asset(fallback, fit: BoxFit.cover);
    }

    // Se for URL (Filmes de API ou URL colada)
    if (poster.startsWith("http")) {
      return Image.network(
        poster,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Image.asset(fallback, fit: BoxFit.cover),
      );
    }

    // Tenta decodificar Base64 (Filme adicionado localmente)
    try {
      // 🚨 CORREÇÃO ESSENCIAL: Remove todos os espaços em branco (incluindo quebras de linha)
      // que podem corromper a string Base64 salva no SharedPreferences.
      String cleanBase64 = poster.replaceAll(RegExp(r'\s+'), '');
      
      Uint8List bytes = base64Decode(cleanBase64);
      return Image.memory(bytes, fit: BoxFit.cover);
    } catch (e) {
      // Se a decodificação falhar, mostra a imagem de fallback
      return Image.asset(fallback, fit: BoxFit.cover);
    }
  }

  // ------------------------------------------------------
  // WIDGET PRINCIPAL
  // ------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meus Filmes Favoritos"),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              // Navega para a página de adicionar filme e recarrega ao retornar
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddMoviePage()),
              );
              _loadFavorites();
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favoriteMovies.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      "Você não tem nenhum filme favorito ainda.\nAdicione alguns tocando no botão +",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _favoriteMovies.length,
                  itemBuilder: (context, index) {
                    final filme = _favoriteMovies[index];

                    return Card(
                      margin:
                          const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      elevation: 4,
                      child: ListTile(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InfoPage(filme: filme),
                            ),
                          );
                          _loadFavorites();
                        },
                        leading: SizedBox(
                          width: 60,
                          height: 80,
                          // Chama o método buildPoster corrigido
                          child: buildPoster(filme["Poster"]),
                        ),
                        title: Text(
                          filme["Title"] ?? "Filme Sem Título",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          // Exibe o Gênero ou o Ano como subtítulo
                          filme["Genre"] ?? filme["Year"] ?? "Informação não disponível",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeFavorite(index),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}