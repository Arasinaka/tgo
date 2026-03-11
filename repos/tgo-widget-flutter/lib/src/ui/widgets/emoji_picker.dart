import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 微信风格表情面板
class EmojiPicker extends StatefulWidget {
  final void Function(String emoji) onEmojiSelected;
  final VoidCallback onDelete;
  final VoidCallback? onSend;
  final VoidCallback onClose;

  const EmojiPicker({
    super.key,
    required this.onEmojiSelected,
    required this.onDelete,
    this.onSend,
    required this.onClose,
  });

  @override
  State<EmojiPicker> createState() => _EmojiPickerState();
}

class _EmojiPickerState extends State<EmojiPicker> {
  int _selectedTab = 0;

  static const List<String> _smileys = [
    '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '🙂', '🙃',
    '😉', '😊', '😇', '🥰', '😍', '🤩', '😘', '😗', '☺️', '😚',
    '😙', '😋', '😛', '😜', '🤪', '😝', '🫠', '🤗', '🥲', '🫡',
    '🤔', '🤫', '🤐', '🤥', '😶', '😏', '😐', '😑', '😬', '🙄',
  ];

  static const List<String> _hearts = [
    '❤️', '🩵', '💛', '💚', '💙', '💜', '🧡', '🖤', '🤍', '🤎',
    '💘', '💖', '💗', '💓', '💕', '💞', '💌', '❣️', '💔', '❤️‍🔥',
  ];

  static const List<String> _party = [
    '🎉', '🎊', '✨', '⭐️', '🌟', '💫', '🔥', '⚡️', '🎈', '🎁',
    '🥳', '👏', '👍', '🙌', '🤝', '💪', '👊', '✊', '🤛', '🤜',
  ];

  List<String> get _currentEmojis {
    switch (_selectedTab) {
      case 0:
        return _smileys;
      case 1:
        return _hearts;
      case 2:
        return _party;
      default:
        return _smileys;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    // 不设置固定高度，让父容器控制
    return Container(
      width: double.infinity,
      color: const Color(0xFFF6F6F6),
      child: Column(
        children: [
          // 表情网格 - 使用 Expanded 填充剩余空间
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: _currentEmojis.length,
              itemBuilder: (context, index) {
                final emoji = _currentEmojis[index];
                return _EmojiButton(
                  emoji: emoji,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onEmojiSelected(emoji);
                  },
                );
              },
            ),
          ),

          // 底部工具栏
          Container(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 6,
              bottom: 6 + bottomPadding,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFEDEDED),
              border: Border(
                top: BorderSide(color: Color(0xFFDCDCDC), width: 0.5),
              ),
            ),
            child: Row(
              children: [
                // 分类标签
                _EmojiTab(
                  icon: Icons.face_rounded,
                  isSelected: _selectedTab == 0,
                  onTap: () => setState(() => _selectedTab = 0),
                ),
                _EmojiTab(
                  icon: Icons.favorite_rounded,
                  isSelected: _selectedTab == 1,
                  onTap: () => setState(() => _selectedTab = 1),
                ),
                _EmojiTab(
                  icon: Icons.celebration_rounded,
                  isSelected: _selectedTab == 2,
                  onTap: () => setState(() => _selectedTab = 2),
                ),
                
                const Spacer(),
                
                // 删除按钮
                _ToolButton(
                  onPressed: widget.onDelete,
                  child: const Icon(
                    Icons.backspace_outlined,
                    color: Color(0xFF181818),
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // 发送按钮
                _SendButton(
                  onPressed: widget.onSend,
                  enabled: widget.onSend != null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmojiTab extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _EmojiTab({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 22,
          color: isSelected ? const Color(0xFF181818) : const Color(0xFF888888),
        ),
      ),
    );
  }
}

class _EmojiButton extends StatefulWidget {
  final String emoji;
  final VoidCallback onTap;

  const _EmojiButton({
    required this.emoji,
    required this.onTap,
  });

  @override
  State<_EmojiButton> createState() => _EmojiButtonState();
}

class _EmojiButtonState extends State<_EmojiButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 1.3 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Center(
          child: Text(
            widget.emoji,
            style: const TextStyle(fontSize: 26),
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;

  const _ToolButton({
    required this.child,
    required this.onPressed,
  });

  @override
  State<_ToolButton> createState() => _ToolButtonState();
}

class _ToolButtonState extends State<_ToolButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onPressed();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 44,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _isPressed ? const Color(0xFFDDDDDD) : Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

class _SendButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool enabled;

  const _SendButton({
    required this.onPressed,
    required this.enabled,
  });

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = widget.enabled 
        ? const Color(0xFF07C160) 
        : const Color(0xFFCCCCCC);
    
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: widget.enabled ? () => setState(() => _isPressed = false) : null,
      onTap: widget.enabled ? () {
        HapticFeedback.mediumImpact();
        widget.onPressed?.call();
      } : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 56,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _isPressed ? bgColor.withOpacity(0.8) : bgColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          '发送',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
