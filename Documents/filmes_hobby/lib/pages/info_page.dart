import 'package:flutter/material.dart';
import 'package:translator/translator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class InfoPage extends StatefulWidget {
  final Map<String, dynamic> filme;

  const InfoPage({super.key, required this.filme});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  final translator = GoogleTranslator();

  // Chaves constantes para o armazenamento
  static const String _favoritesKey = 'favoriteMovies';
  static const String _watchedKey =
      'watchedMovies'; // NOVO: Chave para "Já Assisti"

  String titulo = "";
  String genero = "";
  String diretor = "";
  String sinopse = "";
  bool carregando = true;
  bool _isFavorite = false;
  bool _isWatched = false; // NOVO ESTADO: Rastrea se o filme foi assistido

  @override
  void initState() {
    super.initState();
    _loadStatus(); // Funcao unificada para carregar ambos os status
    traduzirDados();
  }

  // --------------------------
  // NOVO: CARREGAR AMBOS STATUS
  // --------------------------
  Future<void> _loadStatus() async {
    final String movieTitle = widget.filme["Title"] ?? '';
    if (movieTitle.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    // 1. Status de Favorito
    final List<String> favoritesList = prefs.getStringList(_favoritesKey) ?? [];
    final bool isFav = favoritesList.any(
      (movieJson) => jsonDecode(movieJson)['Title'] == movieTitle,
    );

    // 2. Status de Já Assisti (usando a nova chave)
    final List<String> watchedList = prefs.getStringList(_watchedKey) ?? [];
    final bool isWtd = watchedList.any(
      (movieJson) => jsonDecode(movieJson)['Title'] == movieTitle,
    );

    setState(() {
      _isFavorite = isFav;
      _isWatched = isWtd; // Atualiza o novo estado
    });
  }

  // --------------------------
  // TRADUZIR DADOS (Inalterado)
  // --------------------------
  Future<void> traduzirDados() async {
    titulo = await widget.filme["Title"];
    genero = await traduzir(widget.filme["Genre"]);
    diretor = await traduzir(widget.filme["Director"]);
    sinopse = await traduzir(widget.filme["Plot"]);

    setState(() => carregando = false);
  }

  Future<String> traduzir(String? texto) async {
    if (texto == null || texto == "N/A") return "Não disponível";
    final trad = await translator.translate(texto, to: "pt");
    return trad.text;
  }

  // --------------------------
  // LÓGICA DE PERSISTÊNCIA GENÉRICA (usada pelo Favorito e Já Assisti)
  // --------------------------
  Future<void> _toggleListStatus(
    String key,
    bool isCurrentlyInList,
    Function(bool) updateState,
    String title,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> currentList = prefs.getStringList(key) ?? [];

    final String movieTitle = widget.filme["Title"] ?? '';
    if (movieTitle.isEmpty) return;

    final String currentMovieJson = jsonEncode(widget.filme);
    bool shouldBeInList = !isCurrentlyInList;

    if (shouldBeInList) {
      // ADICIONAR
      if (!currentList.any(
        (movieJson) => jsonDecode(movieJson)['Title'] == movieTitle,
      )) {
        currentList.add(currentMovieJson);
      }
    } else {
      // REMOVER
      currentList.removeWhere(
        (movieJson) => jsonDecode(movieJson)['Title'] == movieTitle,
      );
    }

    await prefs.setStringList(key, currentList);

    updateState(shouldBeInList);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          shouldBeInList ? '$title adicionado!' : '$title removido.',
        ),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  // --------------------------
  // ATUALIZADO: ALTERNAR FAVORITO
  // --------------------------
  void _toggleFavorite() {
    _toggleListStatus(
      _favoritesKey,
      _isFavorite,
      (newValue) => setState(() => _isFavorite = newValue),
      'Filme adicionado aos favoritos',
    );
  }

  // --------------------------
  // NOVO: ALTERNAR JÁ ASSISTI
  // --------------------------
  void _toggleWatched() {
    _toggleListStatus(
      _watchedKey,
      _isWatched,
      (newValue) => setState(() => _isWatched = newValue),
      'Filme marcado como assistido',
    );
  }

  // --------------------------
  // UI COM NOVOS ÍCONES
  // --------------------------
  @override
  Widget build(BuildContext context) {
    const String fallback = "assets/sem_imagem.png";

    bool temPoster =
        widget.filme["Poster"] != null &&
        widget.filme["Poster"] != "N/A" &&
        widget.filme["Poster"].toString().startsWith("http");

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo.isEmpty ? "Detalhes do Filme" : titulo),
        backgroundColor: Colors.deepPurple,
        actions: [
          // NOVO BOTÃO: JÁ ASSISTI
          IconButton(
            icon: Icon(
              // Ícone de olho preenchido se assistido, ou olho contornado
              _isWatched ? Icons.visibility : Icons.visibility_outlined,
              color: Colors.white,
            ),
            onPressed: _toggleWatched,
          ),

          // BOTÃO EXISTENTE: FAVORITO
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),

      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: temPoster
                        ? Image.network(
                            widget.filme["Poster"],
                            width: 200,
                            height: 300,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            fallback,
                            width: 200,
                            height: 300,
                            fit: BoxFit.cover,
                          ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Ano: ${widget.filme["Year"] ?? "N/A"}",
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 5),

                  Text("Gênero: $genero", style: const TextStyle(fontSize: 16)),

                  const SizedBox(height: 5),

                  Text(
                    "Diretor: $diretor",
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    "Sinopse:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 5),

                  Text(sinopse, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
    );
  }
}
