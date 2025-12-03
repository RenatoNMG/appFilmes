import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // NOVO
import 'dart:convert'; // NOVO

import 'info_page.dart'; // Para navegação de volta aos detalhes

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  // Chave de armazenamento (deve ser a mesma da InfoPage)
  static const String _favoritesKey = 'favoriteMovies'; 
  
  List<Map<String, dynamic>> _favoriteMovies = [];
  bool _isLoading = true;
  
  String fallback = "assets/sem_imagem.png";

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }
  
  // --------------------------
  // CARREGAR FAVORITOS DO SHARED PREFERENCES
  // --------------------------
  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true); // Inicia carregando
    
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Carrega a lista de JSON strings
    final List<String> favoritesJsonList = prefs.getStringList(_favoritesKey) ?? [];
    
    // 2. Converte as JSON strings de volta para Map<String, dynamic>
    final List<Map<String, dynamic>> loadedMovies = favoritesJsonList.map((movieJson) {
      return jsonDecode(movieJson) as Map<String, dynamic>;
    }).toList();

    // 3. Atualiza o estado da UI
    setState(() {
      _favoriteMovies = loadedMovies;
      _isLoading = false;
    });
  }

  // --------------------------
  // BUILD
  // --------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meus Filmes Favoritos"),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Mostra carregando
          : _favoriteMovies.isEmpty
              ? const Center(
                  // Mensagem se a lista de favoritos estiver vazia
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
                        
                        title: Text(
                          filme["Title"] ?? "Filme Sem Título",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          filme["Year"] ?? "Ano não disponível",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        
                        trailing: const Icon(Icons.favorite, color: Colors.red),

                        onTap: () async {
                          // Navega para InfoPage e aguarda o retorno.
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InfoPage(filme: filme),
                            ),
                          );
                          // Após retornar da InfoPage (e o usuário talvez remover o favorito), 
                          // recarrega a lista para refletir o estado atual.
                          _loadFavorites(); 
                        },
                      ),
                    );
                  },
                ),
    );
  }
}