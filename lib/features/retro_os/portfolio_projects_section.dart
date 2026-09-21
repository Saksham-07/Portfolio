import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:video_player/video_player.dart';

import 'contact_window.dart' show openLink;

/// All portfolio projects (shared by the retro window and the 3D room panels).
final List<ProjectModule> portfolioProjects = [
  ProjectModule(
    title: 'Merchandising Analytics',
    subtitle: 'Order, Buyer & Shipment Intelligence',
    icon: Iconsax.box,
    color: const Color(0xFFFBD38D), // Retro Orange
    techStack: ['Flutter', 'CustomPainter', 'REST APIs', 'Dart'],
    description: 'The command centre for an export garment business: every order, buyer and shipment in one '
        'screen. Merchandisers filter by financial year, team or order number and drill from company-wide '
        'totals down to a single style — replacing a stack of daily Excel reports. '
        '(Client names, people and figures in the previews are mock data.)',
    highlights: [
      'Built 14 dashboard cards — buyer-wise booking, OTD, FHD performance, target vs actual, sales trends, leftover stock and more.',
      'Hand-drew every chart with CustomPainter — no chart library — for full control over animation and a small bundle.',
      'Designed shipment tracking across air freight, delayed, recent and upcoming shipments so delays surface before they cost money.',
      'Added Qty/Value toggles and year/team/order filters so one screen serves both management and merchandisers.',
    ],
    screenshots: const ['assets/screenshots/ppms_Merchandising1.jpg', 'assets/screenshots/ppms_Merchandising2.jpg', 'assets/screenshots/ppms_Merchandising3.jpg'],
  ),
  ProjectModule(
    title: 'Enterprise Analytics',
    subtitle: 'Finance, Budget vs Actual & Sales Dashboards',
    icon: Iconsax.chart_2,
    color: const Color(0xFF90CDF4), // Retro Blue
    techStack: ['Flutter', 'Custom Painters', 'REST APIs', 'SQL', 'Provider'],
    description: 'Finance dashboards built for leadership: Budget vs Actual margins by buyer, a finance overview, '
        'sales turnover and sales comparison — turning raw ERP data into decisions on a phone.',
    highlights: [
      'Built Budget vs Actual views comparing booked, actual and net margin per buyer (the KPI wheel in UI_LAB comes from here).',
      'Shipped Finance Dashboard, Sales Turnover and Sales Comparison modules for management reviews.',
      'Developed custom-painted chart widgets for smooth, library-free rendering.',
      'Structured SQL stored procedures to aggregate financial data quickly.',
    ],
    screenshots: const ['assets/screenshots/ppms_budgetvsact1.jpg', 'assets/screenshots/ppms_budgetvsact2.jpg', 'assets/screenshots/ppms_financeDash1.jpg', 'assets/screenshots/ppms_financeDash2.jpg'],
  ),
  ProjectModule(
    title: 'Quality & Audit Systems',
    subtitle: 'Multi-Stage Garment Audits & Machine Repair',
    icon: Iconsax.scan_barcode,
    color: const Color(0xFFFFB6B9), // Retro Pink
    techStack: ['Flutter', 'Provider', 'BLoC', 'Offline-First Sync', 'Flask'],
    description: 'Factory-floor apps for quality inspectors and maintenance crews. Defects are logged at every '
        'stage of production, and broken machines go through a tracked request-and-approval pipeline.',
    highlights: [
      'Built audit flows for every production stage: Sampling, Sewing, Finishing, End-Line and Fabric audits.',
      'Created a machine repair workflow — raise a request by unit/line/machine, approve, and track to closure.',
      'Designed multi-step forms with strict validation that floor staff can finish in seconds.',
      'Kept the UI responsive during heavy data sync on shared factory devices.',
    ],
    screenshots: const ['assets/screenshots/ppms_audit.jpg', 'assets/screenshots/ppms_endlineaudit.jpg', 'assets/screenshots/ppms_endauditreport.jpg'],
  ),
  ProjectModule(
    title: 'ESS & HR Operations',
    subtitle: 'Self-Service, Gate Pass & Skill Matrix',
    icon: Iconsax.profile_2user,
    color: const Color(0xFFF6E05E), // Retro Yellow
    techStack: ['Flutter', 'BLoC', 'Python Flask', 'SQL Server', 'Provider'],
    description: 'Employee self-service for a large workforce with role-based access: leaves, attendance, '
        'payslips and approvals for employees, with oversight tools for HR and management.',
    highlights: [
      'Shipped leave application & approval, attendance, payslip download, helpdesk and management approvals in one hub.',
      'Built a digital Gate Pass: employees request an exit with destination and reason, managers approve, security tracks it live.',
      'Built Visitor Management: register guests with ID proof, pre-approved and scheduled visits, live inside/checked-out counts.',
      'Created a Skill Matrix dashboard showing A/B-grade operator skills line by line across all units.',
      'Engineered role-based menus that adapt to each user\'s permissions in real time.',
    ],
    screenshots: const ['assets/screenshots/ppms_gatepass1.jpg', 'assets/screenshots/ppms_gatepass3.jpg', 'assets/screenshots/ppms_visitor_managment2.jpg', 'assets/screenshots/ppms_leaveApplication.jpg', 'assets/screenshots/ppms_attendence.jpg', 'assets/screenshots/ppms_helpdesk.jpg', 'assets/screenshots/ppms_skillMatrix1.jpg', 'assets/screenshots/ppms_skillMatrix2.jpg'],
  ),
  ProjectModule(
    title: 'RFID Inventory Engine',
    subtitle: 'Native Android App for Zebra RFD40 Readers',
    icon: Iconsax.cpu_charge,
    color: const Color(0xFF68D391), // Retro Green
    techStack: ['Java', 'Android SDK', 'Zebra RFID SDK', 'Bluetooth', 'OkHttp', 'REST APIs'],
    description: 'A native Android app that pairs with a Zebra RFD40 UHF RFID reader over Bluetooth and verifies '
        'garment cartons on the packing floor. Operators pick a packing list, PO, style and carton, sweep the '
        'tags, and the app checks every one before saving it to the server. It needs a physical reader; '
        'the previews use sample data and the app\'s built-in test-tag injector.',
    highlights: [
      'Integrated Zebra\'s RFID API3 SDK: reader discovery by Bluetooth address per unit, connect/disconnect, and a configurable reader power level.',
      'Decodes each SGTIN-96 EPC into its GTIN/SKU on-device, then checks it against the expected SKUs and colour for the selected style and order.',
      'Flags every tag as valid, duplicate, SKU missing or colour mismatch, using a duplicate check against previously saved tags.',
      'Built carton (box or individual) and GOH scan modes with a target-quantity counter that blocks over-count saves.',
      'De-duplicates tag reads in a set and processes them in 2-second batches so the list stays smooth during a sweep.',
      'Gated each mode behind server-side user rights, with login and unit-specific reader lists.',
    ],
    screenshots: const [
      'assets/screenshots/rfid_login.jpg',
      'assets/screenshots/rfid_reader.jpg',
      'assets/screenshots/rfid_setup.jpg',
      'assets/screenshots/rfid_validated.jpg',
      'assets/screenshots/rfid_validated2.jpg',
      'assets/screenshots/rfid_settings.jpg',
    ],
  ),
  ProjectModule(
    title: 'Workforce Welfare',
    subtitle: 'Welfare Tracker, Feedback & Meetings',
    icon: Iconsax.heart,
    color: const Color(0xFFFEB2B2), // Retro Coral
    techStack: ['Flutter', 'REST APIs', 'File Uploads', 'Dart'],
    description: 'Tools that give factory workers a voice. Group heads collect feedback from their teams, '
        'employees raise complaints with photo evidence, and HR tracks welfare programmes and meetings month by month.',
    highlights: [
      'Built a Welfare Tracker showing monthly programme attendance vs target, attrition and feedback scores per financial year.',
      'Created group-head feedback flows with appreciation/complaint types and a management report view.',
      'Shipped a Feedback & Complaints module with image/PDF attachments, filterable by unit and department.',
      'Added meeting attendance & feedback with attendee lists and role-restricted back-dating.',
    ],
    screenshots: const ['assets/screenshots/ppms_welfareTracker.jpg', 'assets/screenshots/ppms_meetingFeedback.jpg'],
  ),
  ProjectModule(
    title: 'Brandforge',
    subtitle: 'Logo Studio & Animation Gallery',
    icon: Iconsax.magic_star,
    color: const Color(0xFFB794F4), // Retro Purple
    techStack: ['Django', 'Python', 'SQLite', 'Icon APIs', 'JavaScript'],
    description: 'A web-based logo studio that generates a live "Your Brand" wordmark preview across dozens of '
        'animated presets, letting founders browse motion styles for their identity before committing to one. '
        'Built on a Django/SQLite backend, pulling icon options from two free public icon APIs.',
    highlights: [
      'Built a gallery of 20+ distinct animated logo presets rendered live in the browser.',
      'Rendered a live text preview per card so users see their own company name animate instantly.',
      'Integrated two free icon APIs so users can pair their wordmark with a matching icon.',
    ],
    deviceFrame: DeviceFrame.desktop,
    videoAsset: 'assets/screenshots/brandforge_demo.mp4',
    screenshots: const [
      'assets/screenshots/brandforge_ui.jpg',
      'assets/screenshots/brandforge_ui_2.jpg',
      'assets/screenshots/brandforge_ui_3.jpg',
    ],
  ),
  ProjectModule(
    title: 'Velvet Ledger',
    subtitle: 'Offline Personal Ledger & Expense Tracker',
    icon: Iconsax.wallet_2,
    color: const Color(0xFF81E6D9), // Retro Teal
    techStack: ['Flutter', 'Provider', 'SQLite', 'Dart'],
    description: 'A personal-finance app, built end to end: track who owes you and who you owe, log daily '
        'spending, and split shared bills. Everything lives on the device in SQLite — no account, no cloud — '
        'with a JSON backup you can save anywhere through the share sheet.',
    highlights: [
      'Modelled money as integer minor units (never doubles) with strict input parsing, so balances never drift by a cent.',
      'Enforced data integrity in the schema itself: CHECK constraints, foreign keys and cascading deletes.',
      'Built split-expense: one bill divided equally across chosen people, posting each share to the ledger and your own share to spending.',
      'Added per-person ledger reports and date-range spending reports, plus a switchable ledger currency.',
      'Wrote transactional backup & restore that checks the file is a Velvet Ledger backup and rolls back if any row is rejected.',
      'Covered the store, split logic and UI with unit and widget tests.',
    ],
    screenshots: const ['assets/screenshots/velvet_home.jpg', 'assets/screenshots/velvet_balance.jpg', 'assets/screenshots/velvet_split.jpg', 'assets/screenshots/velvet_spending.jpg'],
  ),
];

class PortfolioProjectsSection extends StatefulWidget {
  const PortfolioProjectsSection({super.key});

  @override
  State<PortfolioProjectsSection> createState() => _PortfolioProjectsSectionState();
}

class _PortfolioProjectsSectionState extends State<PortfolioProjectsSection> {
  ProjectModule? _selectedProject;
  int _hoveredIndex = -1;

  List<ProjectModule> get _highValueProjects => portfolioProjects;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // MAIN GRID VIEW
        Container(
          color: const Color(0xFFF4EFE6), // Retro background
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    // Cards stay boxy (square) on big windows, but never shorter than their own content needs:
                    // in a small (resized) window the grid scrolls instead of squeezing the cards until they overflow.
                    const maxTile = 400.0, gap = 24.0, minTileHeight = 340.0;
                    final columns = math.max(1, (box.maxWidth / (maxTile + gap)).ceil());
                    final tileWidth = (box.maxWidth - (columns - 1) * gap) / columns;
                    return GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: maxTile, // Maximum width of a single card
                        crossAxisSpacing: gap,
                        mainAxisSpacing: gap,
                        mainAxisExtent: math.max(tileWidth, minTileHeight),
                      ),
                      itemCount: _highValueProjects.length,
                      itemBuilder: (context, index) {
                        return _buildBrutalistProjectTile(_highValueProjects[index], index);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // INTERACTIVE DETAILED OVERLAY (RETRO MODAL)
        if (_selectedProject != null)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _selectedProject = null),
              child: Container(
                color: Colors.black.withValues(alpha: 0.6), // Harsh overlay, no blur
                alignment: Alignment.center,
                padding: const EdgeInsets.all(24.0),
                child: GestureDetector(
                  onTap: () {}, // Prevent taps from closing the modal
                  child: _buildBrutalistDetailsCard(_selectedProject!),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBrutalistProjectTile(ProjectModule project, int index) {
    bool isHovered = _hoveredIndex == index;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: GestureDetector(
        onTap: () => setState(() => _selectedProject = project),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          transform: Matrix4.translationValues(
              isHovered ? -4 : 0,
              isHovered ? -4 : 0,
              0
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black,
                offset: isHovered ? const Offset(8, 8) : const Offset(4, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card Header
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: project.color,
                  border: const Border(bottom: BorderSide(color: Colors.black, width: 4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(project.icon, color: Colors.black, size: 24),
                    const Icon(Icons.open_in_new, color: Colors.black, size: 20),
                  ],
                ),
              ),
              // Card Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.title.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        project.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Container(
                          color: project.color.withValues(alpha: 0.12),
                          child: Center(child: _MiniPhoneFrame(project: project, variant: index)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Preview Tech Stack
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: project.techStack.take(2).map((tech) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: Text(
                            tech.toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                          ),
                        )).toList(),
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

  Widget _buildBrutalistDetailsCard(ProjectModule project) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.85,
      constraints: const BoxConstraints(maxWidth: 750),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EFE6),
        border: Border.all(color: Colors.black, width: 4),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(12, 12))],
      ),
      child: Column(
        children: [
          // Harsh Brutalist Dialog Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: project.color,
              border: const Border(bottom: BorderSide(color: Colors.black, width: 4)),
            ),
            child: Row(
              children: [
                Icon(project.icon, color: Colors.black, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    project.title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _selectedProject = null),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5F56),
                      border: Border.all(color: Colors.black, width: 3),
                      boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
                    ),
                    child: const Icon(Icons.close, color: Colors.black, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Body Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.subtitle.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // PREVIEW / SCREENSHOTS
                  _buildBrutalistSectionHeader('PREVIEW'),
                  const SizedBox(height: 12),
                  _ScreenshotGallery(project: project),
                  const SizedBox(height: 32),

                  // OVERVIEW
                  _buildBrutalistSectionHeader('OVERVIEW'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 3),
                    ),
                    child: Text(
                      project.description,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // HIGHLIGHTS
                  _buildBrutalistSectionHeader('KEY HIGHLIGHTS'),
                  const SizedBox(height: 16),
                  ...project.highlights.map((highlight) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: project.color,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            highlight,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 32),

                  // TECH STACK
                  _buildBrutalistSectionHeader('TECH STACK'),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: project.techStack.map((tech) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 3),
                        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))],
                      ),
                      child: Text(
                        tech.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          color: Colors.black,
                        ),
                      ),
                    )).toList(),
                  ),

                  // LINKS (only when the project has public URLs)
                  if (project.repoUrl != null || project.liveUrl != null) ...[
                    const SizedBox(height: 32),
                    _buildBrutalistSectionHeader('LINKS'),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (project.liveUrl != null) _linkButton('LIVE DEMO', project.liveUrl!, project.color),
                        if (project.repoUrl != null) _linkButton('SOURCE CODE', project.repoUrl!, Colors.white),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkButton(String label, String url, Color color) {
    return GestureDetector(
      onTap: () => openLink(url),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.black, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))],
          ),
          child: Text(
            '$label ↗',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
          ),
        ),
      ),
    );
  }

  Widget _buildBrutalistSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(color: Colors.black),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 14,
          fontFamily: 'monospace',
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

/// How a project's preview art is framed: a phone bezel for mobile apps,
/// or a browser-style window chrome for web projects.
enum DeviceFrame { mobile, desktop }

class ProjectModule {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String description;
  final List<String> techStack;
  final List<String> highlights;
  final List<String> screenshots; // asset paths, e.g. 'assets/screenshots/ess_1.png'
  final String? videoAsset; // optional preview clip, e.g. 'assets/screenshots/demo.mp4'
  final DeviceFrame deviceFrame;
  final String? repoUrl; // public source, shown as a button when set
  final String? liveUrl; // live demo / store page, shown as a button when set

  ProjectModule({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.description,
    required this.techStack,
    required this.highlights,
    this.screenshots = const [],
    this.videoAsset,
    this.deviceFrame = DeviceFrame.mobile,
    this.repoUrl,
    this.liveUrl,
  });
}

/// Retro device frame used as a screenshot stand-in: a phone bezel for
/// mobile (portrait) apps, or a browser window chrome for web projects
/// ([ProjectModule.deviceFrame]). Drop a real image path into
/// [ProjectModule.screenshots] and it renders that instead of the mock UI.
/// `variant` picks a mock layout so placeholders don't all look identical.
class _MiniPhoneFrame extends StatelessWidget {
  final ProjectModule project;
  final int variant;
  final bool showVideo;

  const _MiniPhoneFrame({required this.project, required this.variant, this.showVideo = false});

  bool get _isDesktop => project.deviceFrame == DeviceFrame.desktop;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _isDesktop ? 16 / 10 : 9 / 19.5,
      child: Container(
        padding: EdgeInsets.all(_isDesktop ? 4 : 6),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(_isDesktop ? 10 : 20),
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_isDesktop ? 6 : 14),
          child: _isDesktop
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 18,
                      color: const Color(0xFF3A3A3A),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: const [
                          _WindowDot(Color(0xFFFF5F56)),
                          SizedBox(width: 4),
                          _WindowDot(Color(0xFFFFBD2E)),
                          SizedBox(width: 4),
                          _WindowDot(Color(0xFF27C93F)),
                        ],
                      ),
                    ),
                    Expanded(child: _screen()),
                  ],
                )
              : Stack(
                  children: [
                    Positioned.fill(child: _screen()),
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        margin: const EdgeInsets.only(top: 5),
                        width: 34,
                        height: 7,
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _screen() {
    if (showVideo && project.videoAsset != null) {
      return _VideoScreen(assetPath: project.videoAsset!);
    }
    if (project.screenshots.isNotEmpty) {
      final path = project.screenshots[variant % project.screenshots.length];
      return Image.asset(path, fit: BoxFit.cover);
    }
    return Container(
      color: const Color(0xFFF4F4F4),
      padding: const EdgeInsets.fromLTRB(8, 18, 8, 8),
      child: _mockBody(),
    );
  }

  Widget _mockBody() {
    switch (variant % 3) {
      case 0:
        return _dashboardLayout();
      case 1:
        return _listLayout();
      default:
        return _chartLayout();
    }
  }

  Widget _dashboardLayout() {
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: Row(
            children: [
              Expanded(flex: 2, child: Container(color: project.color.withValues(alpha: 0.7))),
              const SizedBox(width: 4),
              Expanded(child: Container(color: Colors.black12)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(child: _statBox(0.9)),
              const SizedBox(width: 4),
              Expanded(child: _statBox(0.5)),
              const SizedBox(width: 4),
              Expanded(child: _statBox(0.7)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statBox(double fill) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black26)),
      child: FractionallySizedBox(
        alignment: Alignment.bottomCenter,
        heightFactor: fill,
        child: Container(color: project.color),
      ),
    );
  }

  Widget _listLayout() {
    return Column(
      children: List.generate(4, (i) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Container(width: 10, height: 10, color: project.color.withValues(alpha: 0.4 + i * 0.15)),
                const SizedBox(width: 6),
                Expanded(
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.4 + (i % 3) * 0.2,
                    child: Container(height: 4, color: Colors.black26),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _chartLayout() {
    const heights = [0.4, 0.7, 0.5, 0.9, 0.6];
    return Column(
      children: [
        SizedBox(height: 8, child: Container(color: Colors.black12)),
        const SizedBox(height: 6),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(heights.length, (i) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: FractionallySizedBox(
                    heightFactor: heights[i],
                    alignment: Alignment.bottomCenter,
                    child: Container(color: project.color.withValues(alpha: 0.5 + i * 0.08)),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

/// Autoplaying, looping, muted preview clip shown in place of a screenshot.
class _VideoScreen extends StatefulWidget {
  final String assetPath;
  const _VideoScreen({required this.assetPath});

  @override
  State<_VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<_VideoScreen> {
  late final VideoPlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.assetPath)
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
          ),
        ),
      );
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller.value.size.width,
        height: _controller.value.size.height,
        child: VideoPlayer(_controller),
      ),
    );
  }
}

/// Single traffic-light dot for the desktop window chrome.
class _WindowDot extends StatelessWidget {
  final Color color;
  const _WindowDot(this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Swipeable stand-in "screenshot" gallery for the detail modal.
class _ScreenshotGallery extends StatefulWidget {
  final ProjectModule project;

  const _ScreenshotGallery({required this.project});

  @override
  State<_ScreenshotGallery> createState() => _ScreenshotGalleryState();
}

class _ScreenshotGalleryState extends State<_ScreenshotGallery> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _hasVideo => widget.project.videoAsset != null;

  int get _itemCount {
    final real = (_hasVideo ? 1 : 0) + widget.project.screenshots.length;
    return real > 0 ? real : 3;
  }

  void _go(int delta) {
    final next = (_page + delta).clamp(0, _itemCount - 1);
    _controller.animateToPage(next, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  /// Everything the full-size viewer can step through: the demo video first, then the screenshots.
  List<({String path, bool isVideo})> get _media => [
        if (_hasVideo) (path: widget.project.videoAsset!, isVideo: true),
        for (final p in widget.project.screenshots) (path: p, isVideo: false),
      ];

  Widget _buildItem(int i) {
    final isVideo = _hasVideo && i == 0;
    final frame = Center(
      child: _MiniPhoneFrame(project: widget.project, variant: i - (_hasVideo ? 1 : 0), showVideo: isVideo),
    );
    if (_media.isEmpty) return frame; // mock placeholders, nothing to open
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => showDialog(
          context: context,
          barrierColor: Colors.black87,
          builder: (_) => _Lightbox(items: _media, initial: i),
        ),
        child: frame,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 380,
          child: Row(
            children: [
              _arrowButton(Icons.chevron_left, () => _go(-1)),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  color: widget.project.color.withValues(alpha: 0.12),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: PageView(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _page = i),
                    children: List.generate(_itemCount, _buildItem),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _arrowButton(Icons.chevron_right, () => _go(1)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_itemCount, (i) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _page == i ? widget.project.color : Colors.white,
                border: Border.all(color: Colors.black, width: 2),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _arrowButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border.fromBorderSide(BorderSide(color: Colors.black, width: 3)),
          boxShadow: [BoxShadow(color: Colors.black, offset: Offset(3, 3))],
        ),
        child: Icon(icon, color: Colors.black),
      ),
    );
  }
}
/// Full-size viewer: zoomable screenshots or the demo video, with prev/next (buttons or arrow keys).
class _Lightbox extends StatefulWidget {
  final List<({String path, bool isVideo})> items;
  final int initial;
  const _Lightbox({required this.items, required this.initial});

  @override
  State<_Lightbox> createState() => _LightboxState();
}

class _LightboxState extends State<_Lightbox> {
  late int _i = widget.initial;

  void _go(int delta) {
    final next = _i + delta;
    if (next < 0 || next >= widget.items.length) return;
    setState(() => _i = next);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.items[_i];
    return Focus(
      autofocus: true,
      onKeyEvent: (_, e) {
        if (e is! KeyDownEvent) return KeyEventResult.ignored;
        if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _go(-1);
          return KeyEventResult.handled;
        }
        if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
          _go(1);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 40),
                child: item.isVideo
                    ? _FullVideo(key: ValueKey(item.path), assetPath: item.path)
                    : InteractiveViewer(
                        key: ValueKey(item.path),
                        maxScale: 5,
                        child: Image.asset(item.path, fit: BoxFit.contain),
                      ),
              ),
            ),
            Positioned(top: 0, right: 0, child: _lightboxButton(Icons.close, () => Navigator.of(context).pop())),
            if (_i > 0)
              Positioned(left: 0, top: 0, bottom: 0, child: Center(child: _lightboxButton(Icons.chevron_left, () => _go(-1)))),
            if (_i < widget.items.length - 1)
              Positioned(right: 0, top: 0, bottom: 0, child: Center(child: _lightboxButton(Icons.chevron_right, () => _go(1)))),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Center(
                child: Text(
                  '${_i + 1} / ${widget.items.length}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lightboxButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border.fromBorderSide(BorderSide(color: Colors.black, width: 3)),
          boxShadow: [BoxShadow(color: Colors.black, offset: Offset(3, 3))],
        ),
        child: Icon(icon, color: Colors.black),
      ),
    );
  }
}

class _FullVideo extends StatefulWidget {
  final String assetPath;
  const _FullVideo({super.key, required this.assetPath});

  @override
  State<_FullVideo> createState() => _FullVideoState();
}

class _FullVideoState extends State<_FullVideo> {
  late final VideoPlayerController _c;

  @override
  void initState() {
    super.initState();
    _c = VideoPlayerController.asset(widget.assetPath)
      ..setLooping(true)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _c.play();
      });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_c.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white54));
    }
    return GestureDetector(
      onTap: () => setState(() => _c.value.isPlaying ? _c.pause() : _c.play()),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(child: AspectRatio(aspectRatio: _c.value.aspectRatio, child: VideoPlayer(_c))),
          VideoProgressIndicator(_c, allowScrubbing: true, padding: const EdgeInsets.only(top: 8)),
        ],
      ),
    );
  }
}
