import 'package:flutter/material.dart';

enum WindowType { projects, about, contact, folder, snake, minesweeper, memory, terminal, uilab }

class WindowData {
  final String id;
  final String title;
  final WindowType type;
  Offset position;
  Size size;
  bool isMinimized;
  bool isMaximized;
  int zIndex;

  WindowData({
    required this.id,
    required this.title,
    required this.type,
    this.position = const Offset(80, 80),
    this.size = const Size(500, 360),
    this.isMinimized = false,
    this.isMaximized = false,
    this.zIndex = 0,
  });
}