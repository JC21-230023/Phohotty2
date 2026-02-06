import 'dart:async';
import 'package:translator/translator.dart';
import 'tag_dictionary.dart';
import 'tag_dictionary_store.dart';
import 'tag_normalizer.dart';
import 'package:flutter/material.dart';

class TagTranslator {
  static final _translator = GoogleTranslator();
  static bool _initialized = false;

  // 🔽 起動時に呼ぶ
  static Future<void> init() async {
    if (_initialized) return;

    try {
      final stored = await TagDictionaryStore.load();
      tagDictionaryJa.addAll(stored);
      _initialized = true;
    } catch (e) {
      debugPrint('TagDictionary init error: $e');
      // Continue anyway - TAG_DICT can be empty
      _initialized = true;
    }
  }

  static Future<String> toJapaneseSmart(String tag) async {
    try {
      await init();

      final normalized = normalizeTag(tag);

      // ① 辞書にある
      if (tagDictionaryJa.containsKey(normalized)) {
        final result = tagDictionaryJa[normalized];
        if (result != null && result.isNotEmpty) {
          return result;
        }
      }

      // ② 自動翻訳（タイムアウト30秒）
      try {
        final translated = await _translator
            .translate(tag, to: 'ja')
            .timeout(const Duration(seconds: 30));

        final ja = translated.text;

        if (ja.isEmpty) {
          // If translation is empty, return original tag
          return tag;
        }

        // ③ 辞書に追加
        tagDictionaryJa[normalized] = ja;
        try {
          await TagDictionaryStore.save(tagDictionaryJa).timeout(
            const Duration(seconds: 5),
          );
        } catch (saveError) {
          debugPrint('Failed to save tag dictionary: $saveError');
          // Continue anyway - dictionary save is not critical
        }

        return ja;
      } on TimeoutException catch (_) {
        debugPrint('Translation timeout for tag: $tag');
        // Return original tag if translation times out
        return tag;
      }
    } catch (e) {
      debugPrint('Translation error for tag "$tag": $e');
      // Default: return the original tag
      return tag;
    }
  }

  static Future<List<String>?> toJapaneseSmartList(
      List<String>? tags) async {
    if (tags == null || tags.isEmpty) {
      return null;
    }

    try {
      final results = await Future.wait(
        tags.map(toJapaneseSmart),
        eagerError: false, // Continue on error for some tags
      ).timeout(const Duration(seconds: 45)); // Global timeout

      // Filter out null or empty results
      return results.where((t) => t.isNotEmpty).toList();
    } catch (e) {
      debugPrint('Error translating tag list: $e');
      // Fallback: return original tags
      return tags;
    }
  }
}
