import 'dart:convert'; // for JSON parsing
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';

import 'summary.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Instantiate ArticleViewModel to test http request
    final viewModel = ArticleViewModel(ArticleModel());

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("Wikipedia Flutter")),
        body: const Center(child: Text("Loading...")),
      ),
    );
  }
}

class ArticleModel {
  Future<Summary> getRandomArticleSummary() async {
    final uri = Uri.https(
      'en.wikipedia.org',
      '/api/rest_v1/page/random/summary',
    );

    final response = await get(uri);

    if (response.statusCode != 200) {
      throw HttpException('failed to update resource');
    }

    return Summary.fromJson(jsonDecode(response.body));
  }
}

class ArticleViewModel extends ChangeNotifier {
  final ArticleModel model;
  Summary? summary;
  String? errorMessage;
  bool loading = false;

  ArticleViewModel(this.model) {
    getRandomArticleSummary();
  }

  Future<void> getRandomArticleSummary() async {
    loading = true;
    notifyListeners();

    try {
      summary = await model.getRandomArticleSummary();
      print('Article loaded: ${summary!.titles.normalized}'); // Temporary
      errorMessage = null; // Clears any previous errors
    } on HttpException catch (error) {
      print('Error loading article: ${error.message}'); // Temporary
      errorMessage = error.message;
      summary = null;
    }

    loading = false;
    notifyListeners();
  }
}
