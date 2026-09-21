import 'package:flutter/material.dart';

import 'contact_window.dart';

const _green = Color(0xFF68D391);

/// Tiny fake shell: `help` lists the commands. Content mirrors ABOUT_ME.TXT.
const _commands = <String, String>{
  'whoami': 'Saksham Bir Singh - Flutter developer, 2.5+ yrs, Faridabad IN.\n'
      'Ships enterprise mobile/web apps: dashboards, audits, RFID.',
  'skills': 'Languages : Dart, Python, Java, JavaScript\n'
      'Frameworks : Flutter, Django, Android\n'
      'State/Net  : BLoC, Provider, REST, Dio\n'
      'Tools      : GitHub, SQL Server, RFID, Flask',
  'projects': '1. Merchandising / Enterprise Analytics (Flutter)\n'
      '2. Quality & Audit Systems (Flutter, BLoC)\n'
      '3. RFID Inventory Engine (native Android)\n'
      '4. Brandforge (Django)   5. Velvet Ledger (Flutter)\n'
      '-> open PROJECTS.EXE for the full tour.',
};

class NeoTerminal extends StatefulWidget {
  const NeoTerminal({super.key});

  @override
  State<NeoTerminal> createState() => _NeoTerminalState();
}

class _NeoTerminalState extends State<NeoTerminal> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  final _lines = <String>["SAKSHAM_OS [v1.0]  type 'help' to begin."];

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _run(String raw) {
    final cmd = raw.trim().toLowerCase();
    _input.clear();
    _focus.requestFocus();
    if (cmd.isEmpty) return;
    setState(() {
      if (cmd == 'clear') {
        _lines.clear();
        return;
      }
      _lines.add('> $cmd');
      switch (cmd) {
        case 'help':
          _lines.add('whoami  skills  projects  resume  hire  clear');
        case 'resume':
          _lines.add('Opening resume...');
          openResume();
        case 'hire':
          _lines.add('Opening email to Saksham200111@gmail.com...');
          openEmail();
        default:
          _lines.add(_commands[cmd] ?? "'$cmd' not recognized. try 'help'.");
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(color: _green, fontFamily: 'monospace', fontSize: 13, height: 1.5);
    return GestureDetector(
      onTap: _focus.requestFocus,
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scroll,
                children: [for (final l in _lines) Text(l, style: style)],
              ),
            ),
            Row(
              children: [
                const Text('> ', style: style),
                Expanded(
                  child: TextField(
                    controller: _input,
                    focusNode: _focus,
                    autofocus: true,
                    style: style,
                    cursorColor: _green,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                    onSubmitted: _run,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
