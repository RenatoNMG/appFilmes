import 'dart:convert';
import 'package:http/http.dart' as http;

class OmdbService {
  final String apiKey = "7248ff03"; // sua chave OMDb

  // 🔍 Buscar filmes por título (lista)
  Future<List<dynamic>> buscarFilmes(String titulo) async {
    final url = Uri.parse(
      "https://www.omdbapi.com/?apikey=$apiKey&s=$titulo",
    );

    final resposta = await http.get(url);

    if (resposta.statusCode == 200) {
      final dados = json.decode(resposta.body);

      // API retorna Response: False se não achar nada
      if (dados["Response"] == "True") {
        return dados["Search"]; // lista de filmes
      } else {
        return [];
      }
    } else {
      throw Exception("Erro ao conectar na API OMDb");
    }
  }

  // 🎬 Buscar detalhes completos pelo ID (para InfoPage)
  Future<Map<String, dynamic>> buscarDetalhes(String imdbID) async {
    final url = Uri.parse(
      "https://www.omdbapi.com/?apikey=$apiKey&i=$imdbID&plot=full",
    );

    final resposta = await http.get(url);

    if (resposta.statusCode == 200) {
      final dados = json.decode(resposta.body);

      // Se a API retornar erro, devolve um mapa vazio
      if (dados["Response"] == "True") {
        return dados;
      } else {
        return {};
      }
    } else {
      throw Exception("Erro ao buscar detalhes do filme");
    }
  }
}
