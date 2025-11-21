import 'package:flutter/material.dart';

class TagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const TagChip({
    super.key,
    required this.label,
    required this.onTap,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final isCustom = !_isAlphabetOnly(label);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: _backgroundColor(context, selected, isCustom),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _borderColor(context, selected, isCustom),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.add,
              size: 16,
              color: _iconColor(context, selected, isCustom),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: _textColor(context, selected, isCustom),
                fontWeight: FontWeight.w500,
              ),
            )
          ],
        ),
      ),
    );
  }

  /// カスタムタグ判定（日本語含む）
  bool _isAlphabetOnly(String input) {
    final reg = RegExp(r'^[a-zA-Z0-9 ]+$');
    return reg.hasMatch(input);
  }

  /// --- 色のロジック ---
  Color _backgroundColor(BuildContext context, bool selected, bool isCustom) {
    if (selected) {
      return isCustom ? Colors.green.shade600 : Theme.of(context).primaryColor;
    } else {
      return isCustom ? Colors.green.shade100 : Colors.grey.shade200;
    }
  }

  Color _borderColor(BuildContext context, bool selected, bool isCustom) {
    if (selected) {
      return isCustom ? Colors.green.shade700 : Theme.of(context).primaryColor;
    } else {
      return isCustom ? Colors.green.shade300 : Colors.grey.shade400;
    }
  }

  Color _iconColor(BuildContext context, bool selected, bool isCustom) {
    if (selected) {
      return Colors.white;
    } else {
      return isCustom ? Colors.green.shade800 : Colors.grey.shade600;
    }
  }

  Color _textColor(BuildContext context, bool selected, bool isCustom) {
    if (selected) {
      return Colors.white;
    } else {
      return isCustom ? Colors.green.shade900 : Colors.black87;
    }
  }
}
