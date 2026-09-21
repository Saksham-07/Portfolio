import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

import '../../core/portfolio_data.dart';

const _jobColors = [Color(0xFFFFB6B9), Color(0xFF68D391), Color(0xFFE2E8F0)];

/// The ABOUT_ME page, shared by the retro desktop window and the 3D room's TV.
class AboutMeWindow extends StatelessWidget {
  const AboutMeWindow({super.key});

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF90CDF4),
                border: Border.all(color: Colors.black, width: 4),
                boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(6, 6))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SAKSHAM BIR SINGH', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -1)),
                  const SizedBox(height: 4),
                  const Text('APPLICATION DEVELOPER', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                  const SizedBox(height: 12),
                  Container(height: 4, color: Colors.black),
                  const SizedBox(height: 12),
                  const Text(
                      '📍 Faridabad, Haryana, India\n✉️ Saksham200111@gmail.com\n📞 +91 8810435497',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, fontFamily: 'monospace', height: 1.5)
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // PROFILE
            _buildSectionTitle('PROFILE'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 3),
              ),
              child: const Text(
                aboutProfile,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.5),
              ),
            ),
            const SizedBox(height: 32),

            // CATEGORIZED SKILLS
            _buildSectionTitle('CORE SKILLS'),
            for (final (i, g) in aboutSkills.indexed) ...[
              if (i > 0) const SizedBox(height: 12),
              _buildSkillCategory(g.$1, g.$2),
            ],
            const SizedBox(height: 32),

            // EXPERIENCE
            _buildSectionTitle('EXPERIENCE'),
            for (final (i, j) in aboutJobs.indexed) ...[
              if (i > 0) const SizedBox(height: 16),
              _buildExperienceCard(
                role: j.role,
                company: j.company,
                date: j.date,
                color: _jobColors[i % _jobColors.length],
                bullets: j.bullets,
              ),
            ],
            const SizedBox(height: 32),

            // PROJECTS
            _buildSectionTitle('KEY PROJECTS'),
            for (final (i, p) in aboutKeyProjects.indexed) ...[
              if (i > 0) const SizedBox(height: 12),
              _buildProjectCard(p.title, p.tech, p.desc),
            ],
            const SizedBox(height: 32),

            // EDUCATION
            _buildSectionTitle('EDUCATION'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 3),
                boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, e) in aboutEducation.indexed) ...[
                    if (i > 0) ...[
                      const SizedBox(height: 16),
                      const Divider(color: Colors.black, thickness: 2),
                      const SizedBox(height: 16),
                    ],
                    Text(e.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                    Text(e.place, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'monospace')),
                    const SizedBox(height: 4),
                    Text(e.score, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: const BoxDecoration(color: Colors.black),
        child: Text(
          title,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              fontFamily: 'monospace',
              letterSpacing: 1.5
          ),
        ),
      ),
    );
  }

  Widget _buildExperienceCard({
    required String role,
    required String company,
    required String date,
    required Color color,
    required List<String> bullets
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              border: const Border(bottom: BorderSide(color: Colors.black, width: 3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                const SizedBox(height: 4),
                Text('$company | $date', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: bullets.map((b) => _buildBrutalistBullet(b)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillCategory(String title, List<String> skills) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, fontFamily: 'monospace')),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skills.map((skill) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF6E05E),
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
            ),
            child: Text(skill, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, fontFamily: 'monospace')),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildProjectCard(String title, String tech, String desc) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EFE6),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
          const SizedBox(height: 4),
          Text(tech, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, fontFamily: 'monospace', color: Colors.black54)),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildBrutalistBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4, right: 12),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFFF6E05E),
              border: Border.all(color: Colors.black, width: 2),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
