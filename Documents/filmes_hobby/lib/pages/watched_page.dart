import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'info_page.dart';

class WatchedPage extends StatefulWidget {
  const WatchedPage({super.key});

  @override
  State<WatchedPage> createState() => _WatchedPageState();
}

class _WatchedPageState extends State<WatchedPage> {
  static const String _watchedKey = 'watchedMovies'; 
  
  List<Map<String, dynamic>> _watchedMovies = [];
  bool _isLoading = true;
  
  String fallback = "assets/sem_imagem.png";

  @override
  void initState() {
    super.initState();
    _loadWatchedMovies();
  }
  
  // ---------------------------------------------
  // FUNÇÃO DE CÁLCULO DE TEMPO TOTAL (NOVA)
  // ---------------------------------------------
  String _calculateTotalTime() {
    int totalMinutes = 0;
    
    for (var filme in _watchedMovies) {
      final runtimeString = filme["Runtime"]; // Ex: "120 min" ou "N/A"
      
      if (runtimeString != null && runtimeString != "N/A") {
        try {
          // Extrai o número e remove ' min' (ou similar)
          final parts = runtimeString.split(' ');
          final minutes = int.parse(parts[0]);
          totalMinutes += minutes;
        } catch (e) {
          // Ignora filmes onde o Runtime não pode ser convertido (caso de erro na API)
          print('Erro ao analisar Runtime: $runtimeString. Erro: $e');
        }
      }
    }

    if (totalMinutes == 0) return "0 minutos";

    // Converte minutos para Horas e Minutos
    final hours = totalMinutes ~/ 60; // Divisão inteira
    final minutes = totalMinutes % 60;  // Resto

    if (hours > 0) {
      return "${hours}h ${minutes}m";
    } else {
      return "${minutes}m";
    }
  }

  // ---------------------------------------------
  // CARREGAR FILMES ASSISTIDOS
  // ---------------------------------------------
  Future<void> _loadWatchedMovies() async {
    setState(() => _isLoading = true);
    
    final prefs = await SharedPreferences.getInstance();
    
    final List<String> watchedJsonList = prefs.getStringList(_watchedKey) ?? [];
    
    final List<Map<String, dynamic>> loadedMovies = watchedJsonList.map((movieJson) {
      return jsonDecode(movieJson) as Map<String, dynamic>;
    }).toList();

    setState(() {
      _watchedMovies = loadedMovies;
      _isLoading = false;
    });
  }

  // --------------------------
  // BUILD
  // --------------------------
  @override
  Widget build(BuildContext context) {
    // Calcula o tempo total na fase de build
    final String totalTime = _calculateTotalTime();
    final int totalCount = _watchedMovies.length;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meus Filmes Assistidos"),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) 
          : Column( // Alteramos para Column para colocar o Card no topo
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ----------------------------------------------------
                // NOVO: CARD DE DETALHES E ESTATÍSTICAS
                // ----------------------------------------------------
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 6,
                    color: Colors.teal.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            icon: Icons.movie_filter,
                            count: totalCount.toString(),
                            label: "Filmes Vistos",
                          ),
                          _buildStatItem(
                            icon: Icons.access_time,
                            count: totalTime,
                            label: "Tempo Total",
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // ----------------------------------------------------
                
                Expanded( // Envolve o ListView.builder em Expanded
                  child: totalCount == 0
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              "Você não marcou nenhum filme como assistido ainda. Marque na página de detalhes!",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: totalCount,
                          itemBuilder: (context, index) {
                            final filme = _watchedMovies[index];
                            
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
                                
                                trailing: const Icon(Icons.check_circle, color: Colors.teal),

                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => InfoPage(filme: filme),
                                    ),
                                  );
                                  _loadWatchedMovies(); 
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  // Widget auxiliar para construir o item de estatística
  Widget _buildStatItem({required IconData icon, required String count, required String label}) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.teal.shade700),
        const SizedBox(height: 4),
        Text(
          count,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ],
    );
  }
}