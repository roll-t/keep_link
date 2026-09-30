import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/features/friend/presentation/controller/share_conversation_controller.dart';

Future<void> showMessengerMessageMenu({
  required BuildContext context,
  required ShareConversationEntry entry,
  required Rect targetRect,
  required Widget bubbleWidget,
  required String? currentReaction,
  required ValueChanged<String> onReactionSelected,
  required VoidCallback onCopy,
  required VoidCallback onOpen,
  required VoidCallback onDelete,
}) {
  HapticFeedback.mediumImpact();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'MessengerContextMenu',
    barrierColor: Colors.black.withOpacityCompat(0.55),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return MessengerContextMenuOverlay(
        entry: entry,
        targetRect: targetRect,
        bubbleWidget: bubbleWidget,
        currentReaction: currentReaction,
        animation: animation,
        onReactionSelected: onReactionSelected,
        onCopy: onCopy,
        onOpen: onOpen,
        onDelete: onDelete,
      );
    },
    transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

class MessengerContextMenuOverlay extends StatefulWidget {
  const MessengerContextMenuOverlay({
    super.key,
    required this.entry,
    required this.targetRect,
    required this.bubbleWidget,
    required this.currentReaction,
    required this.animation,
    required this.onReactionSelected,
    required this.onCopy,
    required this.onOpen,
    required this.onDelete,
  });

  final ShareConversationEntry entry;
  final Rect targetRect;
  final Widget bubbleWidget;
  final String? currentReaction;
  final Animation<double> animation;
  final ValueChanged<String> onReactionSelected;
  final VoidCallback onCopy;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  State<MessengerContextMenuOverlay> createState() => _MessengerContextMenuOverlayState();
}

class _MessengerContextMenuOverlayState extends State<MessengerContextMenuOverlay> {
  static const List<String> _defaultEmojis = ['❤️', '😆', '😮', '😢', '😡', '👍'];

  void _handleReaction(String emoji) {
    widget.onReactionSelected(emoji);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    const double reactionBarHeight = 50.0;
    const double menuWidth = 230.0;
    const double menuHeight = 140.0;
    const double gap = 10.0;

    final double spaceBelow = screenSize.height - bottomPadding - widget.targetRect.bottom;
    final double spaceAbove = widget.targetRect.top - topPadding;

    bool showMenuBelow = true;
    double bubbleTop = widget.targetRect.top;

    final double requiredBelow = menuHeight + gap + 16.0;
    final double requiredAbove = reactionBarHeight + gap + 16.0;

    if (spaceBelow < requiredBelow) {
      final double deficit = requiredBelow - spaceBelow;
      if (spaceAbove - deficit >= requiredAbove) {
        bubbleTop -= deficit;
        showMenuBelow = true;
      } else if (spaceAbove >= menuHeight + gap + 16.0) {
        showMenuBelow = false;
      } else {
        bubbleTop = ((screenSize.height - widget.targetRect.height) / 2).clamp(
          topPadding + requiredAbove,
          screenSize.height - bottomPadding - requiredBelow - widget.targetRect.height,
        );
        showMenuBelow = true;
      }
    } else if (spaceAbove < requiredAbove) {
      final double deficit = requiredAbove - spaceAbove;
      if (spaceBelow - deficit >= requiredBelow) {
        bubbleTop += deficit;
        showMenuBelow = true;
      }
    }

    final double reactionBarTop = showMenuBelow
        ? bubbleTop - reactionBarHeight - gap
        : bubbleTop - menuHeight - reactionBarHeight - (gap * 2);

    final double menuTop = showMenuBelow
        ? bubbleTop + widget.targetRect.height + gap
        : bubbleTop - menuHeight - gap;

    final bool isMine = widget.entry.isMine;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Bubble Item
              Positioned(
                top: bubbleTop,
                left: widget.targetRect.left,
                width: widget.targetRect.width,
                height: widget.targetRect.height,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.96, end: 1.0),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacityCompat(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            widget.onOpen();
                          },
                          child: widget.bubbleWidget,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Reaction Bar
              Positioned(
                top: reactionBarTop,
                left: isMine ? null : 14,
                right: isMine ? 14 : null,
                child: ScaleTransition(
                  scale: CurvedAnimation(parent: widget.animation, curve: Curves.easeOutBack),
                  alignment: isMine ? Alignment.bottomRight : Alignment.bottomLeft,
                  child: GestureDetector(
                    onTap: () {}, // prevent background dismissal
                    child: _buildReactionBar(),
                  ),
                ),
              ),

              // Menu Actions Card
              Positioned(
                top: menuTop,
                left: isMine ? null : 14,
                right: isMine ? 14 : null,
                child: ScaleTransition(
                  scale: CurvedAnimation(parent: widget.animation, curve: Curves.easeOutCubic),
                  alignment: isMine
                      ? (showMenuBelow ? Alignment.topRight : Alignment.bottomRight)
                      : (showMenuBelow ? Alignment.topLeft : Alignment.bottomLeft),
                  child: GestureDetector(
                    onTap: () {}, // prevent background dismissal
                    child: SizedBox(width: menuWidth, child: _buildMenuCard(context)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReactionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacityCompat(0.12), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacityCompat(0.4),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: _defaultEmojis
            .map(
              (emoji) => _ReactionEmojiButton(
                emoji: emoji,
                isSelected: widget.currentReaction == emoji,
                onTap: () => _handleReaction(emoji),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context) {
    final isMine = widget.entry.isMine;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF252628),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacityCompat(0.08), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacityCompat(0.45),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Sao chép link
          _MenuItemRow(
            title: widget.entry.isCategory ? 'Sao chép thông tin' : 'Sao chép link',
            icon: Icons.copy_rounded,
            iconSize: 18,
            onTap: () {
              Navigator.of(context).pop();
              widget.onCopy();
            },
          ),
          _buildDivider(),

          // 2. Mở link
          _MenuItemRow(
            title: widget.entry.isCategory ? 'Mở danh mục' : 'Mở link',
            icon: widget.entry.isCategory ? Icons.folder_open_rounded : Icons.open_in_new_rounded,
            iconSize: 19,
            onTap: () {
              Navigator.of(context).pop();
              widget.onOpen();
            },
          ),
          _buildDivider(),

          // 3. Thu hồi / Xóa ở phía tôi
          _MenuItemRow(
            title: isMine ? 'unsend'.tr : 'delete_for_me'.tr,
            titleColor: AppColors.danger,
            icon: Icons.delete_outline_rounded,
            iconColor: AppColors.danger,
            onTap: () {
              Navigator.of(context).pop();
              widget.onDelete();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 0.6, color: Colors.white.withOpacityCompat(0.08));
  }
}

class _ReactionEmojiButton extends StatefulWidget {
  const _ReactionEmojiButton({required this.emoji, required this.isSelected, required this.onTap});

  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_ReactionEmojiButton> createState() => _ReactionEmojiButtonState();
}

class _ReactionEmojiButtonState extends State<_ReactionEmojiButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 140));
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.35,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _controller.forward(),
      onTapCancel: () => _controller.reverse(),
      onTap: () async {
        HapticFeedback.mediumImpact();
        await _controller.forward();
        await _controller.reverse();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: widget.isSelected
                  ? BoxDecoration(
                      color: AppColors.white.withOpacityCompat(0.16),
                      shape: BoxShape.circle,
                    )
                  : null,
              child: TextWidget(text: widget.emoji, size: 20),
            ),
          );
        },
      ),
    );
  }
}

class _MenuItemRow extends StatelessWidget {
  const _MenuItemRow({
    required this.title,
    required this.icon,
    required this.onTap,
    this.titleColor,
    this.iconColor,
    this.iconSize = 20,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? titleColor;
  final Color? iconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.white.withOpacityCompat(0.08),
        highlightColor: AppColors.white.withOpacityCompat(0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextWidget(
                text: title,
                color: titleColor ?? AppColors.white,
                size: 14.5,
                fontWeight: FontWeight.w500,
              ),
              Icon(icon, color: iconColor ?? AppColors.t200, size: iconSize),
            ],
          ),
        ),
      ),
    );
  }
}
