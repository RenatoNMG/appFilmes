import 'package:filmes_hobby/auth/login_page.dart';
import 'package:filmes_hobby/pages/info_page.dart';
import 'package:filmes_hobby/pages/favorite_page.dart';
import 'package:filmes_hobby/pages/watched_page.dart';
import 'package:filmes_hobby/service/servide_omdb.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _searchController = TextEditingController();
  final OmdbService _service = OmdbService();

  List<dynamic> filmes = [];
  bool carregando = false;

  Map<String, String> categoriaMap = {
    "Ação": "action",
    "Comédia": "comedy",
    "Drama": "drama",
    "Terror": "horror",
    "Ficção": "sci-fi",
    "Romance": "romance",
  };

  @override
  void initState() {
    super.initState();
    carregarCatalogoInicial();
  }

  Future<void> carregarCatalogoInicial() async {
    setState(() => carregando = true);

    final resultado = await _service.buscarFilmes("batman");

    setState(() {
      filmes = resultado;
      carregando = false;
    });
  }

  Future<void> buscarFilmes(String query) async {
    if (query.isEmpty) {
      carregarCatalogoInicial();
      return;
    }

    setState(() => carregando = true);

    final resultado = await _service.buscarFilmes(query);

    setState(() {
      filmes = resultado;
      carregando = false;
    });
  }

  Future<void> buscarPorCategoria(String categoria) async {
    final palavra = categoriaMap[categoria]!;

    setState(() => carregando = true);

    final resultado = await _service.buscarFilmes(palavra);

    setState(() {
      filmes = resultado;
      carregando = false;
    });
  }

  Widget _buildPoster(String? url) {
    if (url == null || url.isEmpty || url == "N/A") {
      return Image.asset(
        "assets/sem_imagem.png",
        width: 50,
        height: 70,
        fit: BoxFit.cover,
      );
    }

    return Image.network(
      url,
      width: 50,
      height: 70,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          "assets/sem_imagem.png",
          width: 50,
          height: 70,
          fit: BoxFit.cover,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.deepPurple,
        actions: [
          // BOTÃO SAIR
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginPage()),
                (route) => false,
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.visibility, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WatchedPage()),
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritePage()),
              );
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Buscar filmes...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => buscarFilmes(value),
            ),

            const SizedBox(height: 15),

            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: categoriaMap.keys.map((cat) {
                  return GestureDetector(
                    onTap: () => buscarPorCategoria(cat),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        cat,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              "Filmes",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: carregando
                  ? const Center(child: CircularProgressIndicator())
                  : filmes.isEmpty
                      ? const Center(child: Text("Nenhum filme encontrado"))
                      : ListView.builder(
                          itemCount: filmes.length,
                          itemBuilder: (context, index) {
                            var filme = filmes[index];

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: _buildPoster(filme["Poster"]),
                                ),
                                title: Text(filme["Title"]),
                                subtitle: Text(filme["Year"] ?? ""),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                ),
                                onTap: () async {
                                  final detalhes = await _service.buscarDetalhes(
                                    filme["imdbID"],
                                  );

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          InfoPage(filme: detalhes),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
