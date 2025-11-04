import 'package:flutter_tts/flutter_tts.dart';

/// TTS (Text-to-Speech) 서비스
/// 피드백을 음성으로 재생
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  FlutterTts? _flutterTts;
  bool _isInitialized = false;
  String? _lastSpokenText; // 중복 방지용

  /// TTS 초기화 (비동기 - 메인 스레드 블로킹 방지)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _flutterTts = FlutterTts();

      // 초기화를 비동기로 처리하여 메인 스레드 블로킹 방지
      await Future.wait([
        _flutterTts!.setLanguage('ko-KR'),
        _flutterTts!.setSpeechRate(0.45),
        _flutterTts!.setPitch(1.0),
        _flutterTts!.setVolume(1.0),
      ]);

      _isInitialized = true;
    } catch (e) {
      print('TTS 초기화 실패: $e');
      // 초기화 실패해도 앱이 계속 작동하도록 함
    }
  }

  /// 텍스트를 음성으로 재생
  /// [text]: 재생할 텍스트
  /// [force]: true면 이전과 같은 텍스트도 재생
  Future<void> speak(String text, {bool force = false}) async {
    if (!_isInitialized) {
      await initialize();
      if (!_isInitialized) return;
    }

    // 중복 방지: 같은 텍스트는 재생 안 함
    if (!force && _lastSpokenText == text) {
      return;
    }

    try {
      // 이모지 제거 (TTS가 이모지를 제대로 읽지 못함)
      final cleanText = _removeEmojis(text);

      if (cleanText.isEmpty) return;

      await _flutterTts!.stop(); // 이전 재생 중단
      await _flutterTts!.speak(cleanText);

      _lastSpokenText = text;
    } catch (e) {
      print('TTS 재생 실패: $e');
    }
  }

  /// 이모지 제거
  String _removeEmojis(String text) {
    return text
        .replaceAll(RegExp(r'[🎉✓⏳⚠️]'), '') // 이모지 제거
        .trim();
  }

  /// TTS 중지
  Future<void> stop() async {
    if (_isInitialized && _flutterTts != null) {
      await _flutterTts!.stop();
    }
  }

  /// 리소스 해제
  Future<void> dispose() async {
    if (_flutterTts != null) {
      await _flutterTts!.stop();
      _flutterTts = null;
      _isInitialized = false;
      _lastSpokenText = null;
    }
  }

  /// 마지막 재생한 텍스트 초기화 (다음 재생을 위해)
  void resetLastSpoken() {
    _lastSpokenText = null;
  }
}
