import 'package:filmes_hobby/auth/RegisterPage.dart';
import 'package:flutter/material.dart';
import 'package:filmes_hobby/service/firebase_service.dart';
import 'package:filmes_hobby/pages/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Color primaryAppColor = Colors.deepPurple;
  final Color accentColor = Colors.teal;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  final FirebaseService _firebaseService =
      FirebaseService(collectionName: "usuarios");

  bool carregando = false;

  void fazerLogin() async {
    if (_emailController.text.isEmpty || _senhaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos")),
      );
      return;
    }

    setState(() => carregando = true);

    try {
      final usuarios = await _firebaseService.readAll();

      // 🔥 Igual o Register, mas mais seguro
      final user = usuarios.firstWhere(
        (u) =>
            (u["email"]?.toString().trim() ?? "") ==
                _emailController.text.trim() &&
            (u["senha"]?.toString().trim() ?? "") ==
                _senhaController.text.trim(),
        orElse: () => {},
      );

      if (user.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email ou senha incorretos")),
        );
        return;
      }

      // LOGIN OK
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MyHomePage(title: "Filmes"),
        ),
      );
    } catch (erro) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao fazer login: $erro")),
      );
    } finally {
      setState(() => carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Login"),
        backgroundColor: primaryAppColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.login, size: 60, color: primaryAppColor),
              const SizedBox(height: 20),

              const Text(
                "Bem-vindo de volta!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 40),

              // EMAIL
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email, color: accentColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // SENHA
              TextField(
                controller: _senhaController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Senha",
                  prefixIcon: Icon(Icons.lock, color: accentColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAppColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: carregando ? null : fazerLogin,
                child: carregando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "ENTRAR",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterPage(),
                    ),
                  );
                },
                child: Text(
                  "Não tem conta? Criar agora",
                  style: TextStyle(
                    color: primaryAppColor,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
