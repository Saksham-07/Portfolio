import 'package:flutter/material.dart';
import '../../../core/theme/retro_colors.dart';
import '../models/window_data.dart';

class RetroWindow extends StatelessWidget {
  final WindowData window;
  final Widget content;
  final VoidCallback onClose;
  final VoidCallback onFocus;
  final VoidCallback onToggleMaximize;
  final Function(Offset delta) onDrag;

  const RetroWindow({
    super.key,
    required this.window,
    required this.content,
    required this.onClose,
    required this.onFocus,
    required this.onToggleMaximize,
    required this.onDrag,
  });

  @override
  Widget build(BuildContext context) {
    if (window.isMinimized) return const SizedBox.shrink();

    return Positioned(
      left: window.position.dx,
      top: window.position.dy,
      width: window.size.width,
      height: window.size.height,
      child: GestureDetector(
        onTapDown: (_) => onFocus(),
        child: Container(
          decoration: BoxDecoration(
            color: RetroColors.windowGray,
            border: const Border(
              top: BorderSide(color: RetroColors.windowHighlight, width: 2),
              left: BorderSide(color: RetroColors.windowHighlight, width: 2),
              right: BorderSide(color: RetroColors.borderBlack, width: 2),
              bottom: BorderSide(color: RetroColors.borderBlack, width: 2),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                offset: Offset(4, 4),
                blurRadius: 6,
              ),
            ],
          ),
          child: Column(
            children: [
              // Title Bar
              GestureDetector(
                onPanUpdate: (details) => onDrag(details.delta),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  color: RetroColors.titleBarBlue,
                  child: Row(
                    children: [
                      const Icon(Icons.computer, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          window.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildRetroButton(
                        icon: window.isMaximized ? Icons.filter_none : Icons.crop_square,
                        onTap: onToggleMaximize,
                      ),
                      const SizedBox(width: 3),
                      _buildRetroButton(
                        icon: Icons.close,
                        onTap: onClose,
                      ),
                    ],
                  ),
                ),
              ),
              // Content Area
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: RetroColors.windowDarkGray, width: 2),
                      left: BorderSide(color: RetroColors.windowDarkGray, width: 2),
                      right: BorderSide(color: RetroColors.windowHighlight, width: 2),
                      bottom: BorderSide(color: RetroColors.windowHighlight, width: 2),
                    ),
                  ),
                  child: content,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRetroButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 18,
        height: 18,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: RetroColors.windowGray,
          border: Border(
            top: BorderSide(color: RetroColors.windowHighlight, width: 1.5),
            left: BorderSide(color: RetroColors.windowHighlight, width: 1.5),
            right: BorderSide(color: RetroColors.borderBlack, width: 1.5),
            bottom: BorderSide(color: RetroColors.borderBlack, width: 1.5),
          ),
        ),
        child: Icon(icon, size: 11, color: Colors.black),
      ),
    );
  }
}