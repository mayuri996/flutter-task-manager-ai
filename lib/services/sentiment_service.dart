import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';

class SimpleTokenizer {
  final Map<String, int> _vocab;

  SimpleTokenizer(this._vocab);

  List<int> tokenize(String input) {
    final words = input.toLowerCase().split(RegExp(r'\s+'));
    return words.map((w) => _vocab[w] ?? 0).toList(); // unknown = 0
  }

  factory SimpleTokenizer.fromVocab(List<String> vocabList) {
    final map = <String, int>{};
    for (int i = 0; i < vocabList.length; i++) {
      map[vocabList[i]] = i;
    }
    return SimpleTokenizer(map);
  }
}

class SentimentService {
  static final SentimentService _instance = SentimentService._internal();
  factory SentimentService() => _instance;

  SentimentService._internal();

  bool _initialized = false;
  late Interpreter _interpreter;
  late List<String> _labels;
  late SimpleTokenizer _tokenizer;

  final int maxLen = 128; // Match input shape

  Future<void> init() async {
    if (_initialized) return;

    try {
      print('📦 Trying to load: assets/models/mobilebert.tflite');
      _interpreter =
          await Interpreter.fromAsset('assets/models/mobilebert.tflite');
      print('✅ Model loaded successfully');
    } catch (e) {
      print('❌ Failed to load model: $e');
      throw Exception('Failed to load model');
    }

    print('Input tensor shapes:');
    for (var tensor in _interpreter.getInputTensors()) {
      print(tensor.shape);
    }

    print('Output tensor shapes:');
    for (var tensor in _interpreter.getOutputTensors()) {
      print(tensor.shape);
    }

    final vocabAsset = await rootBundle.loadString('assets/vocab.txt');
    final lines = vocabAsset.split('\n');
    final Map<String, int> vocab = {};
    for (int i = 0; i < lines.length; i++) {
      final word = lines[i].trim();
      if (word.isNotEmpty) {
        vocab[word] = i;
      }
    }
    _tokenizer = SimpleTokenizer(vocab);

    final labelsAsset = await rootBundle.loadString('assets/labels.txt');
    _labels = labelsAsset
        .split('\n')
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toList();

    _initialized = true;
  }

  List<int> _preprocess(String input) {
    List<int> tokens = _tokenizer.tokenize(input);

    if (tokens.length > maxLen) {
      tokens = tokens.sublist(0, maxLen);
    } else if (tokens.length < maxLen) {
      tokens += List.filled(maxLen - tokens.length, 0); // pad with 0
    }

    return tokens;
  }

  Future<String> classify(String text) async {
    if (!_initialized) {
      throw Exception("SentimentService not initialized!");
    }

    final tokens = _preprocess(text);
    final typeIds = List.filled(tokens.length, 0);
    final attentionMask = tokens.map((t) => t == 0 ? 0 : 1).toList();

    final inputWordIds = [tokens];
    final inputMask = [attentionMask];
    final inputTypeIds = [typeIds];

    final outputBuffer = List.filled(2, 0.0).reshape([1, 2]);

    try {
      _interpreter.runForMultipleInputs(
        [inputWordIds, inputMask, inputTypeIds],
        {0: outputBuffer},
      );

      final neg = outputBuffer[0][0];
      final pos = outputBuffer[0][1];

      print('💬 NEG: $neg | POS: $pos');

      // 👇 Better classification logic using thresholds
      if (pos > 0.6) {
        return 'positive';
      } else if (neg > 0.6) {
        return 'negative';
      } else if ((pos - neg).abs() < 0.2) {
        return 'negative';
      } else if (pos > neg) {
        return 'somewhat positive';
      } else {
        return 'somewhat negative';
      }
    } catch (e) {
      print('❌ Error during inference: $e');
      return "error";
    }
  }

  void dispose() {
    _interpreter.close();
  }
}
