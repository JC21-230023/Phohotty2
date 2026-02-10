
import 'package:flutter/material.dart';
import 'tag_chip.dart';

/// タグの表示・選択・カスタム追加までを自己完結で扱う StatefulWidget
/// - 親は初期値と onChanged だけ渡せばOK
/// - 画面間での再利用が容易
class TagSelector extends StatefulWidget {
  const TagSelector({
    super.key,
    required this.initialSuggestedTags,
    this.initialCustomTags = const [],
    this.initialSelectedTags = const {},
    this.title = 'タグ候補',
    this.spacing = 8,
    this.runSpacing = 8,
    this.onChanged,
    this.readOnly = false,
  });

  /// 初期の候補（AI等から取得したもの）
  final List<String> initialSuggestedTags;

  /// 初期のカスタムタグ（任意）
  final List<String> initialCustomTags;

  /// 初期選択
  final Set<String> initialSelectedTags;

  /// 選択状態が変わったときに親へ通知（任意）
  final void Function(Set<String> selected)? onChanged;

  /// 見出しタイトル
  final String title;

  final double spacing;
  final double runSpacing;

  /// 表示専用にしたい場合
  final bool readOnly;

  @override
  State<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends State<TagSelector> {
  late final TextEditingController _customTagController;
  late List<String> _suggestedTags;//初期値で書けるタグ
  late List<String> _customTags;//追加のタグ
  late Set<String> _selected;//選択されたタグ
  late Widget? saveButton;//保存ボタン+保存関数

  @override
  void initState() {
    super.initState();
    _customTagController = TextEditingController();
    _suggestedTags = List<String>.from(widget.initialSuggestedTags);
    _customTags = List<String>.from(widget.initialCustomTags);
    _selected = _suggestedTags.toSet();//初期のタグをSelectedへ
  }

  @override
  void didUpdateWidget(covariant TagSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 親から初期配列が更新されるケース（例：AI解析完了後の差し替え）に対応
    if (oldWidget.initialSuggestedTags != widget.initialSuggestedTags) {
      _suggestedTags = List<String>.from(widget.initialSuggestedTags);
    }
    if (oldWidget.initialCustomTags != widget.initialCustomTags) {
      _customTags = List<String>.from(widget.initialCustomTags);
    }
    if (oldWidget.initialSelectedTags != widget.initialSelectedTags) {
      _selected = Set<String>.from(widget.initialSelectedTags);
    }
  }

  @override
  void dispose() {
    _customTagController.dispose();
    super.dispose();
  }

  void _notifyChanged() {
    widget.onChanged?.call(_selected);
  }

  void _toggleTag(String tag) {
    if (widget.readOnly) return;
    setState(() {
      if (_selected.contains(tag)) {
        _selected.remove(tag);
      } else {
        _selected.add(tag);
      }
    });
    _notifyChanged();
  }

  void _addCustomTag(BuildContext context) {
    if (widget.readOnly) return;

    final tag = _customTagController.text.trim();
    if (tag.isEmpty) return;

    if (_selected.contains(tag)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('すでに存在するタグです')),
      );
      return;
    }
    setState(() {
      _customTags.add(tag);
      _selected.add(tag);
      _customTagController.clear();
    });
    _notifyChanged();
  }

  Set<String> getSelectedTags() {
    return _selected;
  }

  @override
  Widget build(BuildContext context) {
    final input = Row(
      children: [
        Expanded(
          child: TextField(
            controller: _customTagController,
            decoration: const InputDecoration(hintText: 'カスタムタグを追加'),
            onSubmitted: (_) => _addCustomTag(context),
            enabled: !widget.readOnly,
          ),
        ),
        IconButton(//タグを追加するボタン
          icon: const Icon(Icons.add),
          onPressed: () => _addCustomTag(context),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: widget.spacing,
          runSpacing: widget.runSpacing,
          children: [
            ..._suggestedTags.map(
              (tag) => TagChip(
                label: tag,
                selected: _selected.contains(tag),
                onTap: () => _toggleTag(tag),
              ),
            ),
            ..._customTags.map(
              (tag) => TagChip(
                label: tag,
                custom: true,
                selected: _selected.contains(tag),
                onTap: () => _toggleTag(tag),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (!widget.readOnly) input,
      ],
    );
  }
}



