import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/routing/replace_route.dart';

// Core imports (Adjust these paths to match your project structure)
import 'package:protfolio/features/retro_os/models/window_data.dart';
import 'package:protfolio/features/retro_os/neo_minesweeper.dart';

// Custom OS Components
import 'animated_memphis_background.dart';
import 'about_window.dart';
import 'contact_window.dart';
import 'neo_ui_lab.dart';
import 'retro_boot_screen.dart';
import 'neo_snake_game.dart';
import 'neo_memory_game.dart';
import 'neo_terminal.dart';
import 'portfolio_projects_section.dart';

/// Which edge/corner of a window is being dragged to resize it.
enum _Edge {
  left(l: true),
  right(r: true),
  top(t: true),
  bottom(b: true),
  topLeft(t: true, l: true),
  topRight(t: true, r: true),
  bottomLeft(b: true, l: true),
  bottomRight(b: true, r: true);

  const _Edge({this.l = false, this.r = false, this.t = false, this.b = false});
  final bool l, r, t, b;

  MouseCursor get cursor => switch (this) {
        _Edge.left || _Edge.right => SystemMouseCursors.resizeLeftRight,
        _Edge.top || _Edge.bottom => SystemMouseCursors.resizeUpDown,
        _Edge.topLeft || _Edge.bottomRight => SystemMouseCursors.resizeUpLeftDownRight,
        _Edge.topRight || _Edge.bottomLeft => SystemMouseCursors.resizeUpRightDownLeft,
      };
}

class RetroOSView extends StatefulWidget {
  const RetroOSView({super.key});

  @override
  State<RetroOSView> createState() => _RetroOSViewState();
}

class _RetroOSViewState extends State<RetroOSView> {
  // Boot sequence state
  bool _hasBooted = false;

  final List<WindowData> _openWindows = [];
  int _nextZIndex = 1;
  late Timer _clockTimer;
  String _currentTime = '';
  bool _isStartMenuOpen = false;
  bool _isShutDown = false;

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());

    // Pre-load the Projects window so it's ready when the boot sequence finishes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final media = MediaQuery.of(context);
      final isMobile = media.size.width < 600;
      final top = media.padding.top;
      // Desktop: open beside the icon columns so every desktop icon stays visible without moving the window.
      Rect? bounds;
      if (!isMobile) {
        const iconW = 90.0, iconH = 96.0, gap = 24.0, iconCount = 7;
        final colHeight = (media.size.height - top - 24 - 88).clamp(120.0, double.infinity);
        final perColumn = math.max(1, ((colHeight + gap) / (iconH + gap)).floor());
        final columns = (iconCount / perColumn).ceil();
        final left = 24 + columns * iconW + (columns - 1) * gap + 28;
        final width = math.min(media.size.width - left - 32, 820.0);
        bounds = Rect.fromLTWH(left, top + 16, math.max(width, 360.0), media.size.height - top - 110);
      }
      _openWindow(
        title: 'ABOUT_ME.TXT',
        type: WindowType.about,
        screenSize: media.size,
        topPadding: top,
        maximize: isMobile, // phones keep the full-screen window
        bounds: bounds,
      );
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  void _updateClock() {
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    setState(() {
      _currentTime = '$hour:$minute $period';
    });
  }

  Color _getWindowColor(WindowType type) {
    switch (type) {
      case WindowType.projects: return const Color(0xFF90CDF4); // Blue
      case WindowType.about: return const Color(0xFFFFB6B9); // Pink
      case WindowType.contact: return const Color(0xFF68D391); // Green
      case WindowType.folder: return const Color(0xFFF6E05E); // Yellow Folder
      case WindowType.snake: return const Color(0xFFB794F4); // Purple
      case WindowType.minesweeper: return const Color(0xFFE2E8F0); // Red
      case WindowType.memory: return const Color(0xFF68D391); // Green
      case WindowType.uilab: return const Color(0xFF2780C9);
      case WindowType.terminal: return const Color(0xFF27C93F);
    }
  }

  void _openWindow({
    required String title,
    required WindowType type,
    required Size screenSize,
    required double topPadding,
    bool maximize = false,
    Rect? bounds, // explicit initial position + size (overrides the defaults)
  }) {
    setState(() {
      _isStartMenuOpen = false;
    });

    final existingIndex = _openWindows.indexWhere((w) => w.type == type);
    if (existingIndex != -1) {
      _openWindows[existingIndex].isMinimized = false; // Un-minimize if it was minimized
      _bringToFront(_openWindows[existingIndex]);
      return;
    }

    final isMobile = screenSize.width < 600;

    double windowWidth = isMobile ? (screenSize.width - 32) : 520.0;
    double windowHeight = isMobile ? (screenSize.height * 0.65) : 420.0;

    if ((type == WindowType.snake || type == WindowType.minesweeper || type == WindowType.memory) && !isMobile) {
      windowWidth = 420.0;
      windowHeight = 464.0;
    }

    // Standard positions
    final posX = isMobile ? 16.0 : (100.0 + (_openWindows.length * 30));
    final posY = isMobile ? (topPadding + 80.0) : (80.0 + (_openWindows.length * 30));

    // Calculate fullscreen dimensions if maximize is true
    final initialSize = maximize
        ? Size(screenSize.width - 200, screenSize.height - topPadding - 110)
        : Size(windowWidth, windowHeight);

    final initialPos = maximize
        ? Offset(150, topPadding + 16)
        : Offset(posX, posY);

    final newWindow = WindowData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      type: type,
      position: bounds?.topLeft ?? initialPos,
      size: bounds?.size ?? initialSize,
      zIndex: _nextZIndex++,
    )..isMaximized = maximize && bounds == null;

    setState(() {
      _openWindows.add(newWindow);
    });
  }

  void _bringToFront(WindowData window) {
    setState(() {
      window.zIndex = _nextZIndex++;
    });
  }

  void _closeWindow(String id) {
    setState(() {
      _openWindows.removeWhere((w) => w.id == id);
    });
  }

  void _toggleMaximize(WindowData window, Size screenSize, double topPadding) {
    setState(() {
      if (window.isMaximized) {
        final isMobile = screenSize.width < 600;

        double wWidth = isMobile ? (screenSize.width - 32) : 520.0;
        double wHeight = isMobile ? (screenSize.height * 0.65) : 420.0;

        if ((window.type == WindowType.snake || window.type == WindowType.minesweeper || window.type == WindowType.memory) && !isMobile) {
          wWidth = 420.0;
          wHeight = 464.0;
        }

        window.size = Size(wWidth, wHeight);
        window.position = Offset(isMobile ? 16 : 100, isMobile ? topPadding + 80 : 80);
        window.isMaximized = false;
      } else {
        window.position = Offset(16, topPadding + 16);
        window.size = Size(screenSize.width - 32, screenSize.height - topPadding - 110);
        window.isMaximized = true;
      }
      _bringToFront(window);
    });
  }

  // smallest size every window's content still lays out without overflowing (see test/retro_min_size_test.dart)
  static const _minWinW = 340.0, _minWinH = 300.0;

  void _onResizeWindow(WindowData window, _Edge edge, Offset delta, Size screenSize, double topPadding) {
    setState(() {
      window.isMaximized = false; // resizing takes over from maximised
      var left = window.position.dx, top = window.position.dy;
      var right = left + window.size.width, bottom = top + window.size.height;
      if (edge.l) left = (left + delta.dx).clamp(-16.0, right - _minWinW);
      if (edge.r) right = (right + delta.dx).clamp(left + _minWinW, screenSize.width + 16);
      if (edge.t) top = (top + delta.dy).clamp(topPadding, bottom - _minWinH);
      if (edge.b) bottom = (bottom + delta.dy).clamp(top + _minWinH, math.max(top + _minWinH, screenSize.height - 100));
      window.position = Offset(left, top);
      window.size = Size(right - left, bottom - top);
    });
  }

  Widget _resizeHandle(WindowData window, _Edge edge, Size screenSize, double topPadding) {
    const pad = 10.0, corner = 20.0;
    final isCorner = (edge.l || edge.r) && (edge.t || edge.b);
    return Positioned(
      left: edge.l ? 0 : (edge.r ? null : corner),
      right: edge.r ? 0 : (edge.l ? null : corner),
      top: edge.t ? 0 : (edge.b ? null : corner),
      bottom: edge.b ? 0 : (edge.t ? null : corner),
      width: isCorner ? corner : (edge.l || edge.r ? pad + 4 : null),
      height: isCorner ? corner : (edge.t || edge.b ? pad + 4 : null),
      child: MouseRegion(
        cursor: edge.cursor,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (_) => _bringToFront(window),
          onPanUpdate: (d) => _onResizeWindow(window, edge, d.delta, screenSize, topPadding),
        ),
      ),
    );
  }

  void _onDragWindow(WindowData window, Offset delta, Size screenSize, double topPadding) {
    if (window.isMaximized) return;

    setState(() {
      final double maxX = (screenSize.width - window.size.width + 16).clamp(0.0, double.infinity);
      final double maxY = (screenSize.height - 100 - window.size.height).clamp(topPadding, double.infinity);

      final newX = (window.position.dx + delta.dx).clamp(-16.0, maxX);
      final newY = (window.position.dy + delta.dy).clamp(topPadding, maxY);

      window.position = Offset(newX, newY);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasBooted) {
      return RetroBootScreen(
        onBootComplete: () {
          setState(() {
            _hasBooted = true;
          });
        },
      );
    }

    final media = MediaQuery.of(context);
    final screenSize = media.size;
    final topPadding = media.padding.top;
    final isMobile = screenSize.width < 600;

    final sortedWindows = List<WindowData>.from(_openWindows)
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return Scaffold(
      backgroundColor: const Color(0xFFF4EFE6),
      body: GestureDetector(
          onTap: () {
            if (_isStartMenuOpen) setState(() => _isStartMenuOpen = false);
          },
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              // BACKGROUND PATTERN
              const Positioned.fill(
                child: AnimatedMemphisBackground(),
              ),

              // DESKTOP ICONS - wrap into extra columns (or rows on mobile) instead of running under the taskbar
              Positioned(
                left: 24,
                top: topPadding + 24,
                child: isMobile
                    ? SizedBox(
                        width: screenSize.width - 48,
                        child: Wrap(
                          spacing: 24,
                          runSpacing: 24,
                          crossAxisAlignment: WrapCrossAlignment.start,
                          children: _buildDesktopIcons(screenSize, topPadding),
                        ),
                      )
                    : SizedBox(
                        // full height minus top inset and the taskbar (56 tall + 16 margin) plus a gap
                        height: (screenSize.height - topPadding - 24 - 88).clamp(120.0, double.infinity),
                        child: Wrap(
                          direction: Axis.vertical,
                          spacing: 24,
                          runSpacing: 24,
                          children: _buildDesktopIcons(screenSize, topPadding),
                        ),
                      ),
              ),

              // ACTIVE WINDOWS
              ...sortedWindows.map<Widget>((window) {
                return _buildNeoBrutalistWindow(window, screenSize, topPadding);
              }),

              // START MENU FLYOUT
              if (_isStartMenuOpen)
                Positioned(
                  left: 16,
                  bottom: 90,
                  child: _buildStartMenuPopup(screenSize, topPadding),
                ),

              // BOTTOM TASKBAR
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4EFE6),
                    border: Border.all(color: Colors.black, width: 4),
                    boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(6, 6))],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: <Widget>[
                      _buildStartButton(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: _openWindows.map<Widget>((w) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _buildTaskbarTab(w),
                            );
                          }).toList(),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _openWindow(
                          title: 'CONTACT.EXE',
                          type: WindowType.contact,
                          screenSize: screenSize,
                          topPadding: topPadding,
                        ),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF68D391),
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: Text(
                              isMobile ? '● HIRE ME' : '● OPEN TO WORK',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Text(
                          _currentTime,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // SHUTDOWN SCREEN
              if (_isShutDown) _buildShutdownScreen(),
            ],
          ),
      ),
    );
  }

  Widget _buildShutdownScreen() {
    Widget btn(String label, Color color, VoidCallback onTap) => GestureDetector(
          onTap: onTap,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: color,
                border: Border.all(color: Colors.black, width: 3),
                boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
              ),
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontFamily: 'monospace')),
            ),
          ),
        );
    return Positioned.fill(
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "It's now safe to turn off your computer.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF68D391), fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Before you go: Saksham is open to Flutter roles.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 14),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  btn('EMAIL ME', const Color(0xFF90CDF4), openEmail),
                  btn('RESUME.PDF', const Color(0xFFF6E05E), openResume),
                  btn('REBOOT', Colors.white, () => setState(() => _isShutDown = false)),
                  btn('EXIT', const Color(0xFFFF5F56), () => replaceRoute(context, '/')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDesktopIcons(Size screenSize, double topPadding) {
    return [
      _buildDesktopIcon(
        icon: Icons.folder_special,
        color: const Color(0xFF90CDF4),
        label: 'PROJECTS',
        onTap: () => _openWindow(
          title: 'PROJECTS.EXE',
          type: WindowType.projects,
          screenSize: screenSize,
          topPadding: topPadding,
          maximize: true,
        ),
      ),
      _buildDesktopIcon(
        icon: Icons.person_pin,
        color: const Color(0xFFFFB6B9),
        label: 'ABOUT ME',
        onTap: () => _openWindow(
            title: 'ABOUT_ME.TXT',
            type: WindowType.about,
            screenSize: screenSize,
            topPadding: topPadding,
            maximize: true
        ),
      ),
      _buildDesktopIcon(
        icon: Icons.contact_mail,
        color: const Color(0xFF68D391),
        label: 'CONTACT',
        onTap: () => _openWindow(
          title: 'CONTACT.EXE',
          type: WindowType.contact,
          screenSize: screenSize,
          topPadding: topPadding,
        ),
      ),
      _buildDesktopIcon(
        icon: Icons.folder,
        color: const Color(0xFFF6E05E),
        label: 'WORK STUFF🤫',
        onTap: () => _openWindow(
          title: 'C:\\WORK_STUFF',
          type: WindowType.folder,
          screenSize: screenSize,
          topPadding: topPadding,
        ),
      ),
      _buildDesktopIcon(
        icon: Icons.code,
        color: const Color(0xFF27C93F),
        label: 'UI_LAB.EXE',
        onTap: () => _openWindow(
          title: 'UI_LAB.EXE',
          type: WindowType.uilab,
          screenSize: screenSize,
          topPadding: topPadding,
          maximize: true,
        ),
      ),
      _buildDesktopIcon(
        icon: Icons.terminal,
        color: const Color(0xFF000000),
        label: 'TERMINAL.EXE',
        isBlack: true,
        onTap: () => _openWindow(
          title: 'TERMINAL.EXE',
          type: WindowType.terminal,
          screenSize: screenSize,
          topPadding: topPadding,
        ),
      ),
      _buildDesktopIcon(
        icon: Icons.picture_as_pdf,
        color: const Color(0xFFFF5F56),
        label: 'RESUME.PDF',
        onTap: openResume,
      ),
    ];
  }

  Widget _buildDesktopIcon({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
    bool isBlack = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 90,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                border: Border.all(color: Colors.black, width: 3),
                boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
              ),
              child: Icon(icon, size: 36, color: isBlack ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.black),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeoBrutalistWindow(WindowData window, Size screenSize, double topPadding) {
    if (window.isMinimized) return const SizedBox.shrink(); // Hide if minimized

    final windowColor = _getWindowColor(window.type);

    const pad = 10.0; // extra hit area around the window for the resize handles
    return Positioned(
      left: window.position.dx - pad,
      top: window.position.dy - pad,
      width: window.size.width + 2 * pad,
      height: window.size.height + 2 * pad,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(pad),
              child: _windowBody(window, windowColor, screenSize, topPadding),
            ),
          ),
          for (final e in _Edge.values) _resizeHandle(window, e, screenSize, topPadding),
        ],
      ),
    );
  }

  Widget _windowBody(WindowData window, Color windowColor, Size screenSize, double topPadding) {
    return GestureDetector(
        onTapDown: (_) => _bringToFront(window),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 4),
            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(8, 8))],
          ),
          child: Column(
            children: [
              // Brutalist Title Bar
              GestureDetector(
                onPanUpdate: (details) => _onDragWindow(window, details.delta, screenSize, topPadding),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: windowColor,
                    border: const Border(bottom: BorderSide(color: Colors.black, width: 4)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          window.title,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            fontFamily: 'monospace',
                            letterSpacing: 1.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 🚀 NEW: MINIMIZE BUTTON
                      _buildWindowControlButton(
                        icon: Icons.remove,
                        onTap: () => setState(() => window.isMinimized = true),
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      _buildWindowControlButton(
                        icon: window.isMaximized ? Icons.filter_none : Icons.crop_square,
                        onTap: () => _toggleMaximize(window, screenSize, topPadding),
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      _buildWindowControlButton(
                        icon: Icons.close,
                        onTap: () => _closeWindow(window.id),
                        color: const Color(0xFFFF5F56),
                      ),
                    ],
                  ),
                ),
              ),
              // Content Area
              Expanded(
                child: ClipRect(
                  child: _buildWindowContent(window.type, screenSize, topPadding),
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildWindowControlButton({required IconData icon, required VoidCallback onTap, required Color color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
        ),
        child: Icon(icon, size: 14, color: Colors.black),
      ),
    );
  }

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: () => setState(() => _isStartMenuOpen = !_isStartMenuOpen),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: _isStartMenuOpen ? const Color(0xFFF6E05E) : Colors.white,
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              offset: _isStartMenuOpen ? const Offset(0, 0) : const Offset(4, 4),
            )
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.star, size: 18, color: Colors.black),
            SizedBox(width: 6),
            Text('START', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskbarTab(WindowData window) {
    // Determine if this is the active/top-most window
    final activeWindows = _openWindows.where((w) => !w.isMinimized);
    final int topZ = activeWindows.isEmpty ? -1 : activeWindows.map((w) => w.zIndex).reduce(math.max);
    final bool isActive = !window.isMinimized && window.zIndex == topZ;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (window.isMinimized) {
            // Restore from taskbar
            window.isMinimized = false;
            _bringToFront(window);
          } else if (isActive) {
            // Minimize if it's already the active window
            window.isMinimized = true;
          } else {
            // Bring to front if it's open but behind something else
            _bringToFront(window);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        constraints: const BoxConstraints(maxWidth: 140),
        decoration: BoxDecoration(
          color: _getWindowColor(window.type),
          border: Border.all(color: Colors.black, width: 3),
          // 🚀 Active tabs look "pressed in", inactive tabs have a drop shadow
          boxShadow: isActive ? const [] : const [BoxShadow(color: Colors.black, offset: Offset(3, 3))],
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            window.title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace', overflow: TextOverflow.ellipsis),
          ),
        ),
      ),
    );
  }

  Widget _buildStartMenuPopup(Size screenSize, double topPadding) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 4),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(8, 8))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFB794F4),
            padding: const EdgeInsets.all(16),
            child: const Text(
              'MAIN MENU',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'monospace', letterSpacing: 2),
            ),
          ),
          const Divider(height: 4, thickness: 4, color: Colors.black),
          _buildMenuItem(
            icon: Icons.folder_special,
            title: 'PROJECTS',
            color: const Color(0xFF90CDF4),
            onTap: () => _openWindow(title: 'PROJECTS.EXE', type: WindowType.projects, screenSize: screenSize, topPadding: topPadding, maximize: true),
          ),
          _buildMenuItem(
            icon: Icons.person_pin,
            title: 'ABOUT ME',
            color: const Color(0xFFFFB6B9),
            onTap: () => _openWindow(title: 'ABOUT.TXT', type: WindowType.about, screenSize: screenSize, topPadding: topPadding, maximize: true),
          ),
          _buildMenuItem(
            icon: Icons.folder,
            title: 'WORK STUFF',
            color: const Color(0xFFF6E05E),
            onTap: () => _openWindow(title: 'C:\\WORK_STUFF', type: WindowType.folder, screenSize: screenSize, topPadding: topPadding),
          ),
          _buildMenuItem(
            icon: Icons.contact_mail,
            title: 'CONTACT',
            color: const Color(0xFF68D391),
            onTap: () => _openWindow(title: 'CONTACT.EXE', type: WindowType.contact, screenSize: screenSize, topPadding: topPadding),
          ),
          _buildMenuItem(
            icon: Icons.picture_as_pdf,
            title: 'RESUME.PDF',
            color: const Color(0xFFFF5F56),
            onTap: openResume,
          ),
          const Divider(height: 4, thickness: 4, color: Colors.black),
          _buildMenuItem(
            icon: Icons.view_in_ar_outlined,
            title: 'BOOT 2D ROOM',
            color: Colors.white,
            onTap: () => replaceRoute(context, '/isometric'), // replaces retro, so back from the room means home
          ),
          _buildMenuItem(
            icon: Icons.power_settings_new,
            title: 'SHUTDOWN',
            color: const Color(0xFFFF5F56),
            onTap: () => setState(() {
              _isStartMenuOpen = false;
              _isShutDown = true;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: () {
        setState(() => _isStartMenuOpen = false);
        onTap();
      },
      hoverColor: color,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.black),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowContent(WindowType type, Size screenSize, double topPadding) {
    switch (type) {

    // 🚀 WIRED UP THE INTERACTIVE PROJECTS MODULE
      case WindowType.projects:
        return const PortfolioProjectsSection();

      case WindowType.about:
        return const AboutMeWindow();

      case WindowType.folder:
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFFF4EFE6),
          padding: const EdgeInsets.all(24),
          child: Wrap(
            spacing: 32,
            runSpacing: 32,
            children: [
              _buildDesktopIcon(
                icon: Icons.games,
                color: const Color(0xFFB794F4),
                label: 'SNAKE.EXE',
                onTap: () => _openWindow(title: 'SNAKE.EXE', type: WindowType.snake, screenSize: screenSize, topPadding: topPadding),
              ),
              _buildDesktopIcon(
                icon: Icons.close,
                color: const Color(0xFFFF5F56),
                label: 'MINESWEEP.EXE',
                onTap: () => _openWindow(title: 'MINESWEEPER.EXE', type: WindowType.minesweeper, screenSize: screenSize, topPadding: topPadding),
              ),
              _buildDesktopIcon(
                icon: Icons.dashboard,
                color: const Color(0xFF68D391),
                label: 'MEMORY.EXE',
                onTap: () => _openWindow(title: 'MEMORY.EXE', type: WindowType.memory, screenSize: screenSize, topPadding: topPadding),
              ),
            ],
          ),
        );

      case WindowType.snake:
        return const NeoSnakeGame();
      case WindowType.minesweeper:
        return const NeoMinesweeper();
      case WindowType.memory:
        return const NeoMemoryGame();
      case WindowType.uilab:
        return const NeoUiLab();

      case WindowType.contact:
        return const ContactWindow();
      case WindowType.terminal:
        return const NeoTerminal();
    }
  }
}
