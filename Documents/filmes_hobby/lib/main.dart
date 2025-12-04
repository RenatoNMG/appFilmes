
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:filmes_hobby/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  // Inicializa o Firebase
  await Firebase.initializeApp();

  runApp(const MyApp());
}
