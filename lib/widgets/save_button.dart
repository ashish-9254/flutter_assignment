import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/photo.dart';
import '../providers/saved_provider.dart';

/// Bookmark button used on grid tiles ([compact]) and on the detail screen.
///
/// - Its state comes from [SavedProvider], so it is correct the moment the
///   screen opens and updates when the photo is saved / removed anywhere.
/// - Saving gives a haptic tick and a "pop" animation on the icon.
class SaveButton extends StatefulWidget {
  final Photo photo;

  /// Small circular overlay (true) or labelled pill (false).
  final bool compact;

  const SaveButton({super.key, required this.photo, this.compact = true});

  @override
  State<SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<SaveButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.4)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.4, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    final saved = context.read<SavedProvider>();
    final willSave = !saved.isSaved(widget.photo.id);

    HapticFeedback.lightImpact();
    if (willSave) _controller.forward(from: 0);

    try {
      await saved.toggle(widget.photo);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update your saved photos.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // select() rebuilds this button only when *this photo's* saved state
    // flips, not every time any photo is saved. Important for a long grid.
    final isSaved = context.select<SavedProvider, bool>(
          (p) => p.isSaved(widget.photo.id),
    );

    return widget.compact ? _buildCompact(isSaved) : _buildLabelled(isSaved);
  }

  Widget _buildCompact(bool isSaved) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: ScaleTransition(
              scale: _scale,
              child: Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_border,
                size: 20,
                color: isSaved ? const Color(0xFFFFD166) : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabelled(bool isSaved) {
    final p = AppPalette.of(context);
    final fg = isSaved ? p.onPrimary : p.textPrimary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isSaved ? p.primary : p.card,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: isSaved ? p.primary : p.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _onTap,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _scale,
                  child: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    size: 20,
                    color: fg,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isSaved ? 'Saved' : 'Save',
                  style: TextStyle(color: fg, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}