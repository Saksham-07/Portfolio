import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const String resumeFileName = 'Saksham_Bir_Singh_Resume.pdf';

/// Opens the resume PDF served from web/ in a new tab.
Future<void> openResume() => _open(Uri.base.resolve(resumeFileName));

Future<void> _open(Uri uri) => launchUrl(uri, webOnlyWindowName: '_blank');

/// Opens a pre-filled email to Saksham.
Future<void> openEmail() => _open(Uri.parse(
    'mailto:Saksham200111@gmail.com?subject=Flutter%20Developer%20Opportunity'));

/// Opens any external link in a new tab.
Future<void> openLink(String url) => _open(Uri.parse(url));

class ContactWindow extends StatelessWidget {
  const ContactWindow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4EFE6),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _AvailableBadge(),
            const SizedBox(height: 14),
            const Text("LET'S BUILD SOMETHING",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5, height: 1.1)),
            const SizedBox(height: 8),
            const Text(
              'Flutter developer with 2.5+ years shipping a production ERP used on real factory floors. '
              'Open to Flutter / mobile roles — on-site, hybrid or remote, and open to relocating.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.5, color: Colors.black87),
            ),
            const SizedBox(height: 22),
            _ContactButton(
              label: 'DOWNLOAD RESUME',
              detail: 'PDF · 1 page',
              icon: Icons.download,
              color: const Color(0xFFF6E05E),
              big: true,
              onTap: openResume,
            ),
            const SizedBox(height: 14),
            _ContactButton(
              label: 'EMAIL',
              detail: 'Saksham200111@gmail.com',
              icon: Icons.alternate_email,
              color: const Color(0xFF90CDF4),
              onTap: openEmail,
            ),
            const SizedBox(height: 14),
            _ContactButton(
              label: 'LINKEDIN',
              detail: 'linkedin.com/in/saksham-bir-singh',
              icon: Icons.work_outline,
              color: const Color(0xFFB794F4),
              onTap: () => _open(Uri.parse('https://www.linkedin.com/in/saksham-bir-singh')),
            ),
            const SizedBox(height: 14),
            _ContactButton(
              label: 'GITHUB',
              detail: 'github.com/Saksham-07',
              icon: Icons.code,
              color: const Color(0xFF68D391),
              onTap: () => _open(Uri.parse('https://github.com/Saksham-07')),
            ),
            const SizedBox(height: 14),
            _ContactButton(
              label: 'CALL',
              detail: '+91 88104 35497',
              icon: Icons.phone,
              color: const Color(0xFFFFB6B9),
              onTap: () => _open(Uri.parse('tel:+918810435497')),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Colors.black),
              child: const Text(
                '> Based in Faridabad, India (IST)\n> Usually replies within 24 hours',
                style: TextStyle(color: Color(0xFF68D391), fontFamily: 'monospace', fontSize: 12, height: 1.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailableBadge extends StatefulWidget {
  const _AvailableBadge();

  @override
  State<_AvailableBadge> createState() => _AvailableBadgeState();
}

class _AvailableBadgeState extends State<_AvailableBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _blink =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _blink,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFF27C93F),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text('AVAILABLE FOR NEW ROLES',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, fontFamily: 'monospace', letterSpacing: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactButton extends StatefulWidget {
  final String label;
  final String detail;
  final IconData icon;
  final Color color;
  final bool big;
  final VoidCallback onTap;

  const _ContactButton({
    required this.label,
    required this.detail,
    required this.icon,
    required this.color,
    required this.onTap,
    this.big = false,
  });

  @override
  State<_ContactButton> createState() => _ContactButtonState();
}

class _ContactButtonState extends State<_ContactButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          transform: Matrix4.translationValues(_hover ? -3 : 0, _hover ? -3 : 0, 0),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: widget.big ? 18 : 12),
          decoration: BoxDecoration(
            color: widget.color,
            border: Border.all(color: Colors.black, width: 3),
            boxShadow: [BoxShadow(color: Colors.black, offset: _hover ? const Offset(7, 7) : const Offset(4, 4))],
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: Colors.black, size: widget.big ? 28 : 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.label,
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: widget.big ? 18 : 14, letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text(widget.detail,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_outward, color: Colors.black, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
