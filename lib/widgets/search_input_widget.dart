import 'package:flutter/material.dart';
//import 'package:provider/provider.dart';


//import 'package:flutter/material.dart';

/// 検索バーと送信（紙飛行機）ボタン、クリア（×）ボタンを持つ再利用可能ウィジェット。
/// 入力が空で送信ボタンが押された場合は、空文字列 "" を onSubmit に渡します。
class SearchInputBar extends StatefulWidget {
  const SearchInputBar({
    super.key,
    required this.onSubmit,
    this.hintText = 'Enter search term...',
    this.initialText = '',
    this.autofocus = false,
  });

  /// 送信時に呼ばれるコールバック（入力文字列を渡す）
  final void Function(String query) onSubmit;

  /// テキストフィールドのヒント
  final String hintText;

  /// 初期表示する文字列
  final String initialText;

  /// 画面表示時に自動でフォーカスするか
  final bool autofocus;

  @override
  State<SearchInputBar> createState() => _SearchInputBarState();
}

class _SearchInputBarState extends State<SearchInputBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText)
      ..addListener(_onControllerTextChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerTextChanged)
      ..dispose();
    super.dispose();
  }

  void _onControllerTextChanged() {
    setState(() {
      // 入力有無でクリアボタンの表示を更新するため再描画
    });
  }

  void _handleSubmit() {
    final text = _controller.text;
    widget.onSubmit(text); // 空の場合は空文字のまま渡す
  }

  void _handleClear() {
    _controller.clear();
    // クリアしたこと自体を通知したい場合は、必要に応じて:
    // widget.onSubmit('');
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      onSubmitted: (_) => _handleSubmit(), // キーボードの完了でも送信
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (_controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Clear search input',
                onPressed: _handleClear,
              ),
            IconButton(
              icon: const Icon(Icons.send),
              tooltip: 'Perform search',
              onPressed: _handleSubmit,
            ),
          ],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
      ),
    );
  }
}
