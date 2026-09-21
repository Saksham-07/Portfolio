import 'dart:ui' show ImageFilter, PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/portfolio_data.dart';
import '../retro_os/contact_window.dart' show openEmail, openLink, openResume;
import '../retro_os/portfolio_projects_section.dart' show ProjectModule, portfolioProjects;

/// Futuristic "holo" UI for the modules opened from the 3D room.
const _panel = Color(0xFF0B1020);
const _card = Color(0xFF131B30);
const _ink = Color(0xFFE6EDF7);
const _muted = Color(0xFF8FA0B8);

/// Frosted dark-glass shell shared by every module.
class HoloPanel extends StatelessWidget {
  const HoloPanel({super.key, required this.title, required this.accent, required this.child, this.subtitle});
  final String title;
  final String? subtitle;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 40, spreadRadius: 1)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_panel.withValues(alpha: 0.96), const Color(0xFF070B16).withValues(alpha: 0.97)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.2),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(22, 10, 10, 10),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: accent.withValues(alpha: 0.25))),
                    gradient: LinearGradient(colors: [accent.withValues(alpha: 0.16), Colors.transparent]),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: accent, blurRadius: 10)],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: const TextStyle(color: _ink, fontWeight: FontWeight.w700, letterSpacing: 3, fontSize: 13)),
                            if (subtitle != null)
                              Text(subtitle!, style: TextStyle(color: accent, fontSize: 10, letterSpacing: 1.6)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        icon: const Icon(Icons.close_rounded, color: _muted),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---- shared bits ---------------------------------------------------------------------

ScrollBehavior _dragScroll(BuildContext context) => ScrollConfiguration.of(context).copyWith(
      dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
    );

class _Section extends StatelessWidget {
  const _Section(this.title, this.accent, this.child);
  final String title;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 3, height: 14, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2.4)),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.accent, {this.dense = false});
  final String text;
  final Color accent;
  final bool dense;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: dense ? 9 : 12, vertical: dense ? 4 : 6),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.4)),
        ),
        child: Text(text, style: TextStyle(color: _ink, fontSize: dense ? 10.5 : 12, fontWeight: FontWeight.w500)),
      );
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: child,
      );
}

/// Pulsing "open to work" pill.
class _OpenToWork extends StatefulWidget {
  const _OpenToWork(this.accent);
  final Color accent;

  @override
  State<_OpenToWork> createState() => _OpenToWorkState();
}

class _OpenToWorkState extends State<_OpenToWork> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF34D399).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _c,
              builder: (_, _) => Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF34D399),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: const Color(0xFF34D399).withValues(alpha: 0.4 + 0.5 * _c.value), blurRadius: 4 + 8 * _c.value)],
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('OPEN TO WORK', style: TextStyle(color: Color(0xFF6EE7B7), fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1.6)),
          ],
        ),
      );
}

// ---- ABOUT (living-room TV) --------------------------------------------------------------

class HoloAbout extends StatelessWidget {
  const HoloAbout({super.key, required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: _dragScroll(context),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 32),
        children: [
          // identity card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(colors: [accent.withValues(alpha: 0.22), _card.withValues(alpha: 0.4)]),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _OpenToWork(Colors.green),
                const SizedBox(height: 14),
                const Text(aboutName, style: TextStyle(color: _ink, fontSize: 26, fontWeight: FontWeight.w300, letterSpacing: 3)),
                const SizedBox(height: 4),
                Text(aboutTitle, style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 3)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Tag(contactLocation, accent, dense: true),
                    _Tag(contactEmail, accent, dense: true),
                    _Tag(contactPhone, accent, dense: true),
                  ],
                ),
              ],
            ),
          ),
          _Section('PROFILE', accent, const Text(aboutProfile, style: TextStyle(color: _ink, fontSize: 13.5, height: 1.65))),
          _Section(
            'CORE SKILLS',
            accent,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final g in aboutSkills) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(g.$1, style: const TextStyle(color: _muted, fontSize: 10.5, letterSpacing: 1.6)),
                  ),
                  Wrap(spacing: 8, runSpacing: 8, children: [for (final s in g.$2) _Tag(s, accent)]),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
          _Section(
            'EXPERIENCE',
            accent,
            Column(children: [for (final (i, j) in aboutJobs.indexed) _TimelineItem(job: j, accent: accent, last: i == aboutJobs.length - 1)]),
          ),
          _Section(
            'KEY PROJECTS',
            accent,
            Column(
              children: [
                for (final p in aboutKeyProjects)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.title, style: const TextStyle(color: _ink, fontWeight: FontWeight.w700, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(p.tech, style: TextStyle(color: accent, fontSize: 11, letterSpacing: 0.6)),
                          const SizedBox(height: 10),
                          Text(p.desc, style: const TextStyle(color: _muted, fontSize: 12.5, height: 1.55)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _Section(
            'EDUCATION',
            accent,
            Column(
              children: [
                for (final e in aboutEducation)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _GlassCard(
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.school_outlined, color: accent, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.title, style: const TextStyle(color: _ink, fontWeight: FontWeight.w700, fontSize: 13.5)),
                                const SizedBox(height: 2),
                                Text(e.place, style: const TextStyle(color: _muted, fontSize: 11.5)),
                              ],
                            ),
                          ),
                          Text(e.score, style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.job, required this.accent, required this.last});
  final Job job;
  final Color accent;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 26,
            child: Column(
              children: [
                const SizedBox(height: 6),
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: accent, blurRadius: 8)]),
                ),
                if (!last) Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4), color: accent.withValues(alpha: 0.28))),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 14),
              child: _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.role, style: const TextStyle(color: _ink, fontWeight: FontWeight.w700, fontSize: 14.5)),
                    const SizedBox(height: 3),
                    Text('${job.company}  ·  ${job.date}', style: TextStyle(color: accent, fontSize: 11.5)),
                    const SizedBox(height: 12),
                    for (final b in job.bullets)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 7, right: 10),
                              child: Container(width: 5, height: 5, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                            ),
                            Expanded(child: Text(b, style: const TextStyle(color: _muted, fontSize: 12.5, height: 1.5))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- CONTACT (hall console) -------------------------------------------------------------------

class HoloContact extends StatelessWidget {
  const HoloContact({super.key, required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    Widget action(IconData icon, String label, String detail, VoidCallback onTap, {bool primary = false}) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _HoverTile(
            accent: accent,
            primary: primary,
            onTap: onTap,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: primary ? accent : accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: primary ? const Color(0xFF0B1020) : accent, size: 21),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(color: _ink, fontWeight: FontWeight.w700, fontSize: 13.5, letterSpacing: 1.2)),
                      const SizedBox(height: 2),
                      Text(detail, style: const TextStyle(color: _muted, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.north_east_rounded, color: accent.withValues(alpha: 0.8), size: 18),
              ],
            ),
          ),
        );

    return ScrollConfiguration(
      behavior: _dragScroll(context),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
        children: [
          const Align(alignment: Alignment.centerLeft, child: _OpenToWork(Colors.green)),
          const SizedBox(height: 16),
          const Text("LET'S BUILD\nSOMETHING", style: TextStyle(color: _ink, fontSize: 30, fontWeight: FontWeight.w300, letterSpacing: 3, height: 1.2)),
          const SizedBox(height: 12),
          const Text(
            'Flutter developer with 2.5+ years shipping a production ERP used on real factory floors. Open to Flutter / mobile roles: on-site, hybrid or remote, and open to relocating.',
            style: TextStyle(color: _muted, fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 24),
          action(Icons.download_rounded, 'DOWNLOAD RESUME', 'PDF · 1 page', openResume, primary: true),
          action(Icons.alternate_email_rounded, 'EMAIL', contactEmail, openEmail),
          action(Icons.work_outline_rounded, 'LINKEDIN', 'linkedin.com/in/saksham-bir-singh', () => openLink(contactLinkedIn)),
          action(Icons.code_rounded, 'GITHUB', 'github.com/Saksham-07', () => openLink(contactGithub)),
          action(Icons.phone_rounded, 'CALL', contactPhone, () => openLink(contactPhoneUri)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(12)),
            child: Text('> Based in Faridabad, India (IST)\n> Usually replies within 24 hours',
                style: TextStyle(color: accent, fontFamily: 'monospace', fontSize: 12, height: 1.7)),
          ),
        ],
      ),
    );
  }
}

class _HoverTile extends StatefulWidget {
  const _HoverTile({required this.child, required this.onTap, required this.accent, this.primary = false});
  final Widget child;
  final VoidCallback onTap;
  final Color accent;
  final bool primary;

  @override
  State<_HoverTile> createState() => _HoverTileState();
}

class _HoverTileState extends State<_HoverTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _card.withValues(alpha: _hover ? 1 : 0.8),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: widget.accent.withValues(alpha: _hover || widget.primary ? 0.75 : 0.22)),
              boxShadow: _hover ? [BoxShadow(color: widget.accent.withValues(alpha: 0.25), blurRadius: 22)] : null,
            ),
            child: widget.child,
          ),
        ),
      );
}

// ---- PROJECTS (study desk) ------------------------------------------------------------------------

class HoloProjects extends StatefulWidget {
  const HoloProjects({super.key, required this.accent});
  final Color accent;

  @override
  State<HoloProjects> createState() => _HoloProjectsState();
}

class _HoloProjectsState extends State<HoloProjects> {
  ProjectModule? _open;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: _open == null
          ? ScrollConfiguration(
              key: const ValueKey('grid'),
              behavior: _dragScroll(context),
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 320,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.86,
                ),
                itemCount: portfolioProjects.length,
                itemBuilder: (_, i) => _ProjectCard(project: portfolioProjects[i], accent: accent, onTap: () => setState(() => _open = portfolioProjects[i])),
              ),
            )
          : _ProjectDetail(key: ValueKey(_open!.title), project: _open!, accent: accent, onBack: () => setState(() => _open = null)),
    );
  }
}

class _ProjectCard extends StatefulWidget {
  const _ProjectCard({required this.project, required this.accent, required this.onTap});
  final ProjectModule project;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.project;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: (_hover ? p.color : Colors.white).withValues(alpha: _hover ? 0.8 : 0.08)),
            boxShadow: _hover ? [BoxShadow(color: p.color.withValues(alpha: 0.3), blurRadius: 24)] : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (p.screenshots.isNotEmpty)
                      Image.asset(p.screenshots.first, fit: BoxFit.cover, alignment: Alignment.topCenter, cacheWidth: 420, errorBuilder: (_, _, _) => const SizedBox())
                    else
                      const SizedBox(),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [p.color.withValues(alpha: 0.35), _card.withValues(alpha: 0.2), _card],
                          stops: const [0, 0.55, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(11), border: Border.all(color: p.color.withValues(alpha: 0.6))),
                        child: Icon(p.icon, color: p.color, size: 19),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _ink, fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 3),
                      Text(p.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 11.5, height: 1.35)),
                      const SizedBox(height: 8),
                      Flexible(
                        child: ClipRect(
                          child: Wrap(spacing: 6, runSpacing: 6, children: [for (final t in p.techStack.take(2)) _Tag(t, p.color, dense: true)]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectDetail extends StatelessWidget {
  const _ProjectDetail({super.key, required this.project, required this.accent, required this.onBack});
  final ProjectModule project;
  final Color accent;
  final VoidCallback onBack;

  void _lightbox(BuildContext context, String asset) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(ctx).pop(),
              child: InteractiveViewer(maxScale: 5, child: Padding(padding: const EdgeInsets.all(24), child: Image.asset(asset, fit: BoxFit.contain))),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: Colors.white24),
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ),
        ],
      ),
    );
  }

  void _video(BuildContext context, String asset) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: _DemoVideo(asset: asset),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = project;
    return ScrollConfiguration(
      behavior: _dragScroll(context),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onBack,
              icon: Icon(Icons.arrow_back_rounded, size: 18, color: accent),
              label: Text('ALL PROJECTS', style: TextStyle(color: accent, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w700)),
            ),
          ),
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: p.color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14), border: Border.all(color: p.color.withValues(alpha: 0.6))),
                child: Icon(p.icon, color: p.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.title, style: const TextStyle(color: _ink, fontSize: 21, fontWeight: FontWeight.w600)),
                    Text(p.subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          if (p.screenshots.isNotEmpty || p.videoAsset != null)
            _Section(
              'PREVIEW',
              p.color,
              SizedBox(
                height: 290,
                child: ScrollConfiguration(
                  behavior: _dragScroll(context),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      if (p.videoAsset != null)
                        GestureDetector(
                          onTap: () => _video(context, p.videoAsset!),
                          child: Container(
                            width: 200,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(colors: [p.color.withValues(alpha: 0.5), _card]),
                              border: Border.all(color: p.color.withValues(alpha: 0.6)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_circle_fill_rounded, size: 54, color: p.color),
                                const SizedBox(height: 10),
                                const Text('WATCH DEMO', style: TextStyle(color: _ink, fontWeight: FontWeight.w700, letterSpacing: 2, fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                      for (final s in p.screenshots)
                        GestureDetector(
                          onTap: () => _lightbox(context, s),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.12))),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(s, height: 290, fit: BoxFit.fitHeight, cacheHeight: 580, errorBuilder: (_, _, _) => const SizedBox(width: 160)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          _Section('OVERVIEW', p.color, Text(p.description, style: const TextStyle(color: _ink, fontSize: 13.5, height: 1.65))),
          _Section(
            'KEY HIGHLIGHTS',
            p.color,
            Column(
              children: [
                for (final h in p.highlights)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 6, right: 12),
                          child: Container(width: 6, height: 6, decoration: BoxDecoration(color: p.color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: p.color, blurRadius: 6)])),
                        ),
                        Expanded(child: Text(h, style: const TextStyle(color: _muted, fontSize: 13, height: 1.5))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          _Section('TECH STACK', p.color, Wrap(spacing: 8, runSpacing: 8, children: [for (final t in p.techStack) _Tag(t, p.color)])),
          if (p.repoUrl != null || p.liveUrl != null)
            _Section(
              'LINKS',
              p.color,
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (p.liveUrl != null) _LinkButton('LIVE DEMO', p.color, () => openLink(p.liveUrl!)),
                  if (p.repoUrl != null) _LinkButton('SOURCE CODE', p.color, () => openLink(p.repoUrl!)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton(this.label, this.color, this.onTap);
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(side: BorderSide(color: color), foregroundColor: color, shape: const StadiumBorder()),
        icon: const Icon(Icons.north_east_rounded, size: 16),
        label: Text(label, style: const TextStyle(letterSpacing: 1.6, fontSize: 12, fontWeight: FontWeight.w700)),
      );
}

class _DemoVideo extends StatefulWidget {
  const _DemoVideo({required this.asset});
  final String asset;

  @override
  State<_DemoVideo> createState() => _DemoVideoState();
}

class _DemoVideoState extends State<_DemoVideo> {
  late final VideoPlayerController _c = VideoPlayerController.asset(widget.asset);
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _c.initialize().then((_) {
      if (!mounted) return;
      _c
        ..setLooping(true)
        ..play();
      setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox(height: 240, child: Center(child: CircularProgressIndicator()));
    return GestureDetector(
      onTap: () => setState(() => _c.value.isPlaying ? _c.pause() : _c.play()),
      child: AspectRatio(aspectRatio: _c.value.aspectRatio, child: VideoPlayer(_c)),
    );
  }
}

// ---- GAMES (lounge kiosks) ----------------------------------------------------------------------------

/// Hosts one of the games in a "display bezel"; the same game is mirrored as a placeholder on the room's kiosk.
class HoloGame extends StatelessWidget {
  const HoloGame({super.key, required this.accent, required this.child});
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.cast_rounded, size: 15, color: accent),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('MIRRORED ON THE LOUNGE DISPLAY', style: TextStyle(color: _muted, fontSize: 10, letterSpacing: 1.8)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.black,
                border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.4),
                boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.25), blurRadius: 24)],
              ),
              padding: const EdgeInsets.all(8),
              child: ClipRRect(borderRadius: BorderRadius.circular(14), child: child),
            ),
          ),
        ],
      ),
    );
  }
}
