import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart'; // Importa o pacote

class AddMoviePage extends StatefulWidget {
  const AddMoviePage({super.key});

  @override
  State<AddMoviePage> createState() => _AddMoviePageState();
}

class _AddMoviePageState extends State<AddMoviePage> {
  static const String _favoritesKey = 'favoriteMovies';

  // Controladores para os campos do formulário
  final _titleController = TextEditingController();
  final _yearController = TextEditingController();
  final _genreController = TextEditingController();
  final _directorController = TextEditingController();
  final _plotController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  // Variável para armazenar o arquivo de imagem selecionado
  File? _pickedImage; 

  @override
  void dispose() {
    _titleController.dispose();
    _yearController.dispose();
    _genreController.dispose();
    _directorController.dispose();
    _plotController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------
  // FUNÇÃO PARA PEGAR IMAGEM
  // ------------------------------------------------------
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  // ------------------------------------------------------
  // FUNÇÃO PARA SALVAR FILME
  // ------------------------------------------------------
  Future<void> _saveMovie() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    String? posterBase64;
    // 1. Tenta converter a imagem (se selecionada) para Base64
    if (_pickedImage != null) {
      try {
        List<int> imageBytes = await _pickedImage!.readAsBytes();
        posterBase64 = base64Encode(imageBytes);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao converter imagem: $e')),
          );
        }
        return; 
      }
    }

    // Cria o mapa do filme
    final newMovie = {
      "Title": _titleController.text.trim(),
      "Year": _yearController.text.trim(),
      "Genre": _genreController.text.trim(),
      "Director": _directorController.text.trim(),
      "Plot": _plotController.text.trim(),
      // Salva a string Base64 no campo "Poster"
      "Poster": posterBase64, 
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> favoritesJsonList = 
          prefs.getStringList(_favoritesKey) ?? [];
      
      final newMovieJson = jsonEncode(newMovie);
      favoritesJsonList.add(newMovieJson);

      await prefs.setStringList(_favoritesKey, favoritesJsonList);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Filme adicionado com sucesso!')),
        );
        // Retorna para a tela anterior e força o recarregamento
        Navigator.pop(context, true); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar o filme: $e')),
        );
      }
    }
  }

  // Widget para os campos de texto, para reduzir a repetição
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    int maxLines = 1,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (required && (value == null || value.isEmpty)) {
            return 'Por favor, insira o $labelText.';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Adicionar Novo Filme"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Campos de Texto
              _buildTextField(controller: _titleController, labelText: 'Título'),
              _buildTextField(controller: _yearController, labelText: 'Ano', required: false),
              _buildTextField(controller: _genreController, labelText: 'Gênero', required: false),
              _buildTextField(controller: _directorController, labelText: 'Direção', required: false),
              _buildTextField(
                controller: _plotController,
                labelText: 'Sinopse (Plot)',
                maxLines: 4,
                required: false,
              ),

              const Divider(height: 32),

              // ------------------------------------------------------
              // SEÇÃO DE IMAGEM
              // ------------------------------------------------------
              const Text(
                "Poster do Filme (Opcional)",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Câmera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade100,
                        foregroundColor: Colors.deepPurple,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galeria'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade100,
                        foregroundColor: Colors.deepPurple,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 10),

              // Pré-visualização da Imagem
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _pickedImage != null
                    ? Image.file(
                        _pickedImage!,
                        fit: BoxFit.cover,
                      )
                    : Center(
                        child: Text(
                          "Nenhuma imagem selecionada",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
              ),

              const SizedBox(height: 30),

              // Botão Salvar
              ElevatedButton.icon(
                onPressed: _saveMovie,
                icon: const Icon(Icons.save),
                label: const Text(
                  'Salvar Filme',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}