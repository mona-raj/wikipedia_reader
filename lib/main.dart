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

    return MaterialApp(home: ArticleView());
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

class ArticleView extends StatelessWidget {
  ArticleView({super.key});

  final articleViewModel = ArticleViewModel(ArticleModel());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Wikipedia Flutter")),
      body: ListenableBuilder(
        listenable: articleViewModel,
        builder: (context, child) {
          return switch ((
            articleViewModel.loading,
            articleViewModel.summary,
            articleViewModel.errorMessage,
          )) {
            (true, _, _) => CircularProgressIndicator(),
            (false, _, String message) => Center(child: Text(message)),
            (false, null, null) => Center(
              child: Text('An unknown error has occurred.'),
            ),
            // The summary must be non-null in this switch case.
            (false, Summary summary, null) => ArticlePage(
              summary: summary,
              nextArticleCallback: articleViewModel.getRandomArticleSummary,
            ),
          };
        },
      ),
    );
  }
}

class ArticlePage extends StatelessWidget {
  const ArticlePage({
    super.key,
    required this.summary,
    required this.nextArticleCallback,
  });

  final Summary summary;
  final VoidCallback nextArticleCallback;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ArticleWidget(summary: summary),
          ElevatedButton(
            onPressed: nextArticleCallback,
            child: Text('Next Random Article'),
          ),
        ],
      ),
    );
  }
}

class ArticleWidget extends StatelessWidget {
  ArticleWidget({super.key, required this.summary});

  final Summary summary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        spacing: 10.0,
        children: [
          if (summary.hasImage) Image.network(summary.originalImage!.source),
          Text(
            summary.titles.normalized,
            overflow: TextOverflow.ellipsis,
            style: TextTheme.of(context).displaySmall,
          ),
          if (summary.description != null)
            Text(
              summary.description!,
              overflow: TextOverflow.ellipsis,
              style: TextTheme.of(context).bodySmall,
            ),
          Text(summary.extract),
        ],
      ),
    );
  }
}
