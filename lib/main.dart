import 'package:chat_app/constants.dart';
import 'package:chat_app/splashpage.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://aifcmefzikdjdgchvndc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFpZmNtZWZ6aWtkamRnY2h2bmRjIiwicm9sZSI6ImFub24iLCJpYXQiOjE2ODAyOTkwMzcsImV4cCI6MTk5NTg3NTAzN30.3n7mZLtspiNrCABr_LDEhwtQ3WsJu-jXgYZ898wJ15k',
    
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Chat App',
      theme: appTheme,
      home: const SplashPage(),
    );
  }
}