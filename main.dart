import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screenshot/screenshot.dart';

void main() => runApp(const ArenaForgeApp());

const bg = Color(0xFF090B13);
const card = Color(0xFF121726);
const card2 = Color(0xFF1A2235);
const neon = Color(0xFF39FFB6);
const pink = Color(0xFFFF3D81);
const gold = Color(0xFFFFC857);

class ArenaForgeApp extends StatelessWidget {
  const ArenaForgeApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ArenaForge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(primary: neon, secondary: pink, surface: card),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: card2,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(backgroundColor: neon, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class Team {
  String id, name, short, game;
  String? logoPath;
  int kills, rankPoints, matches, wins;
  Team({required this.id, required this.name, required this.short, required this.game, this.logoPath, this.kills = 0, this.rankPoints = 0, this.matches = 0, this.wins = 0});
  int get total => kills + rankPoints;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'short': short, 'game': game, 'logoPath': logoPath, 'kills': kills, 'rankPoints': rankPoints, 'matches': matches, 'wins': wins};
  factory Team.fromJson(Map<String, dynamic> j) => Team(id: j['id'], name: j['name'], short: j['short'], game: j['game'], logoPath: j['logoPath'], kills: j['kills'] ?? 0, rankPoints: j['rankPoints'] ?? 0, matches: j['matches'] ?? 0, wins: j['wins'] ?? 0);
}

class MatchEntry {
  String id, game, mapName, teamId;
  int rank, kills, rankPoints;
  String createdAt;
  MatchEntry({required this.id, required this.game, required this.mapName, required this.teamId, required this.rank, required this.kills, required this.rankPoints, required this.createdAt});
  int get total => kills + rankPoints;
  Map<String, dynamic> toJson() => {'id': id, 'game': game, 'mapName': mapName, 'teamId': teamId, 'rank': rank, 'kills': kills, 'rankPoints': rankPoints, 'createdAt': createdAt};
  factory MatchEntry.fromJson(Map<String, dynamic> j) => MatchEntry(id: j['id'], game: j['game'], mapName: j['mapName'], teamId: j['teamId'], rank: j['rank'], kills: j['kills'], rankPoints: j['rankPoints'], createdAt: j['createdAt']);
}

class Store extends ChangeNotifier {
  List<Team> teams = [];
  List<MatchEntry> matches = [];
  String game = 'BGMI';
  Store() { load(); }
  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    teams = (jsonDecode(sp.getString('teams') ?? '[]') as List).map((e) => Team.fromJson(e)).toList();
    matches = (jsonDecode(sp.getString('matches') ?? '[]') as List).map((e) => MatchEntry.fromJson(e)).toList();
    if (teams.isEmpty) seed();
    notifyListeners();
  }
  void seed() {
    for (final g in ['BGMI', 'FREE FIRE']) {
      for (int i = 1; i <= 8; i++) {
        teams.add(Team(id: '$g-$i', name: '$g Squad $i', short: 'S$i', game: g, kills: i * 2, rankPoints: 9 - i, matches: 1, wins: i == 1 ? 1 : 0));
      }
    }
  }
  Future<void> save() async { final sp = await SharedPreferences.getInstance(); await sp.setString('teams', jsonEncode(teams.map((e) => e.toJson()).toList())); await sp.setString('matches', jsonEncode(matches.map((e) => e.toJson()).toList())); notifyListeners(); }
  List<Team> get visibleTeams => teams.where((t) => t.game == game).toList()..sort((a, b) => b.total.compareTo(a.total));
  List<MatchEntry> get visibleMatches => matches.where((m) => m.game == game).toList();
  void setGame(String g) { game = g; notifyListeners(); }
  Future<void> addTeam(Team t) async { teams.add(t); await save(); }
  Future<void> addMatch(MatchEntry m) async { matches.add(m); final t = teams.firstWhere((x) => x.id == m.teamId); t.kills += m.kills; t.rankPoints += m.rankPoints; t.matches += 1; if (m.rank == 1) t.wins += 1; await save(); }
  Future<void> resetGame() async { teams.removeWhere((t) => t.game == game); matches.removeWhere((m) => m.game == game); await save(); }
}

final store = Store();

class HomePage extends StatefulWidget { const HomePage({super.key}); @override State<HomePage> createState() => _HomePageState(); }
class _HomePageState extends State<HomePage> {
  int tab = 0;
  final shot = ScreenshotController();
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: store, builder: (_, __) {
      return Scaffold(
        body: SafeArea(child: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [bg, Color(0xFF111A2E)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: Column(children: [
            _Header(onShare: sharePoster),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: ['BGMI', 'FREE FIRE'].map((g) => Expanded(child: Padding(padding: const EdgeInsets.all(4), child: ChoiceChip(selected: store.game == g, label: Text(g), selectedColor: neon, onSelected: (_) => store.setGame(g))))).toList())),
            Expanded(child: IndexedStack(index: tab, children: [Dashboard(shot: shot), const AddMatch(), const TeamsPage(), const TemplatesPage()])),
          ]),
        )),
        floatingActionButton: FloatingActionButton.extended(backgroundColor: pink, onPressed: () => setState(() => tab = 1), label: const Text('Add Result'), icon: const Icon(Icons.add)),
        bottomNavigationBar: NavigationBar(backgroundColor: card, selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i), destinations: const [
          NavigationDestination(icon: Icon(Icons.leaderboard), label: 'Table'),
          NavigationDestination(icon: Icon(Icons.sports_esports), label: 'Result'),
          NavigationDestination(icon: Icon(Icons.groups), label: 'Teams'),
          NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'Templates'),
        ]),
      );
    });
  }
  Future<void> sharePoster() async {
    final bytes = await shot.capture();
    if (bytes == null) return;
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/arenaforge_${DateTime.now().millisecondsSinceEpoch}.png');
    await f.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(f.path)], text: 'ArenaForge ${store.game} points table');
  }
}

class _Header extends StatelessWidget { final VoidCallback onShare; const _Header({required this.onShare}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(16), child: Row(children: [
  Container(width: 52, height: 52, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [neon, pink])), child: const Icon(Icons.bolt, color: Colors.black, size: 32)),
  const SizedBox(width: 12), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ArenaForge', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)), Text('Pro esports points table maker', style: TextStyle(color: Colors.white70))])),
  IconButton(onPressed: onShare, icon: const Icon(Icons.share))
])); }

class Dashboard extends StatelessWidget { final ScreenshotController shot; const Dashboard({super.key, required this.shot}); @override Widget build(BuildContext context) {
  final teams = store.visibleTeams; final top = teams.isEmpty ? null : teams.first;
  return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Screenshot(controller: shot, child: Container(color: Colors.transparent, child: Column(children: [
    Row(children: [Expanded(child: StatCard(title: 'Teams', value: '${teams.length}', icon: Icons.groups)), Expanded(child: StatCard(title: 'Matches', value: '${store.visibleMatches.length}', icon: Icons.map)), Expanded(child: StatCard(title: 'Leader', value: top?.short ?? '-', icon: Icons.emoji_events))]),
    const SizedBox(height: 16),
    PosterCard(teams: teams),
    const SizedBox(height: 16),
    const Align(alignment: Alignment.centerLeft, child: Text('Points Table', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
    const SizedBox(height: 8),
    Table(border: TableBorder.all(color: Colors.white10, borderRadius: BorderRadius.circular(12)), columnWidths: const {0: FlexColumnWidth(.8), 1: FlexColumnWidth(2.2)}, children: [
      row(['#', 'Team', 'M', 'K', 'RP', 'TOT'], head: true),
      ...List.generate(teams.length, (i) { final t = teams[i]; return row(['${i+1}', t.short, '${t.matches}', '${t.kills}', '${t.rankPoints}', '${t.total}']); })
    ]),
  ]))));
} }

TableRow row(List<String> cells, {bool head = false}) => TableRow(decoration: BoxDecoration(color: head ? card2 : Colors.transparent), children: cells.map((c) => Padding(padding: const EdgeInsets.all(10), child: Text(c, textAlign: TextAlign.center, style: TextStyle(fontWeight: head ? FontWeight.bold : FontWeight.w500, color: head ? neon : Colors.white)))).toList());

class StatCard extends StatelessWidget { final String title, value; final IconData icon; const StatCard({super.key, required this.title, required this.value, required this.icon}); @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.all(4), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)), child: Column(children: [Icon(icon, color: neon), Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), Text(title, style: const TextStyle(color: Colors.white60, fontSize: 12))])); }

class PosterCard extends StatelessWidget { final List<Team> teams; const PosterCard({super.key, required this.teams}); @override Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), gradient: const LinearGradient(colors: [Color(0xFF19233D), Color(0xFF330D2B)]), border: Border.all(color: neon.withOpacity(.35))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
  Text('${store.game} CHAMPIONS TABLE', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1)),
  Text(DateFormat('dd MMM yyyy').format(DateTime.now()), style: const TextStyle(color: Colors.white70)), const SizedBox(height: 12),
  ...teams.take(5).map((t) => ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(backgroundColor: neon, foregroundColor: Colors.black, backgroundImage: t.logoPath == null ? null : FileImage(File(t.logoPath!)), child: t.logoPath == null ? Text(t.short.substring(0, 1)) : null), title: Text(t.name), subtitle: Text('Kills ${t.kills} • Rank ${t.rankPoints}'), trailing: Text('${t.total}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: gold)))),
])); }

class AddMatch extends StatefulWidget { const AddMatch({super.key}); @override State<AddMatch> createState() => _AddMatchState(); }
class _AddMatchState extends State<AddMatch> { String? team; final rank = TextEditingController(text: '1'); final kills = TextEditingController(text: '0'); String map = 'Erangel'; @override Widget build(BuildContext context) {
  final teams = store.visibleTeams; team ??= teams.isEmpty ? null : teams.first.id;
  return ListView(padding: const EdgeInsets.all(16), children: [
    const Text('Add Match Result', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 14),
    DropdownButtonFormField(value: team, items: teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(), onChanged: (v) => setState(() => team = v)), const SizedBox(height: 12),
    DropdownButtonFormField(value: map, items: ['Erangel', 'Miramar', 'Sanhok', 'Bermuda', 'Kalahari', 'Purgatory'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(), onChanged: (v) => setState(() => map = v!)), const SizedBox(height: 12),
    TextField(controller: rank, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rank / Position')), const SizedBox(height: 12),
    TextField(controller: kills, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Kills')), const SizedBox(height: 20),
    ElevatedButton.icon(onPressed: team == null ? null : () async { final r = int.tryParse(rank.text) ?? 99; final k = int.tryParse(kills.text) ?? 0; await store.addMatch(MatchEntry(id: DateTime.now().toString(), game: store.game, mapName: map, teamId: team!, rank: r, kills: k, rankPoints: rankPoint(r), createdAt: DateTime.now().toIso8601String())); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Result added'))); }, icon: const Icon(Icons.save), label: const Text('Save Result')),
    const SizedBox(height: 20), Text('Rank point system: #1=10, #2=6, #3=5, #4=4, #5=3, #6-8=2, #9-12=1, rest=0', style: TextStyle(color: Colors.white.withOpacity(.7))),
  ]);
} int rankPoint(int r) { if (r == 1) return 10; if (r == 2) return 6; if (r == 3) return 5; if (r == 4) return 4; if (r == 5) return 3; if (r <= 8) return 2; if (r <= 12) return 1; return 0; } }

class TeamsPage extends StatelessWidget { const TeamsPage({super.key}); @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
  Row(children: [const Expanded(child: Text('Teams', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))), ElevatedButton.icon(onPressed: () => showDialog(context: context, builder: (_) => const AddTeamDialog()), icon: const Icon(Icons.add), label: const Text('Add'))]),
  ...store.visibleTeams.map((t) => Card(color: card, child: ListTile(leading: CircleAvatar(backgroundColor: neon, foregroundColor: Colors.black, backgroundImage: t.logoPath == null ? null : FileImage(File(t.logoPath!)), child: t.logoPath == null ? Text(t.short.substring(0, 1)) : null), title: Text(t.name), subtitle: Text('${t.short} • ${t.matches} matches'), trailing: Text('${t.total}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))))),
  const SizedBox(height: 16), OutlinedButton.icon(onPressed: () => store.resetGame(), icon: const Icon(Icons.refresh), label: const Text('Reset current game data'))
]); }

class AddTeamDialog extends StatefulWidget { const AddTeamDialog({super.key}); @override State<AddTeamDialog> createState() => _AddTeamDialogState(); }
class _AddTeamDialogState extends State<AddTeamDialog> { final name = TextEditingController(); final short = TextEditingController(); String? logo; @override Widget build(BuildContext context) => AlertDialog(backgroundColor: card, title: const Text('Add Team'), content: Column(mainAxisSize: MainAxisSize.min, children: [
  TextField(controller: name, decoration: const InputDecoration(labelText: 'Team name')), const SizedBox(height: 10), TextField(controller: short, decoration: const InputDecoration(labelText: 'Short name')), const SizedBox(height: 10), OutlinedButton.icon(onPressed: pick, icon: const Icon(Icons.image), label: const Text('Upload JPG/PNG logo')),
]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), ElevatedButton(onPressed: () async { if (name.text.trim().isEmpty) return; await store.addTeam(Team(id: DateTime.now().toString(), name: name.text.trim(), short: short.text.trim().isEmpty ? name.text.trim().substring(0, 2).toUpperCase() : short.text.trim().toUpperCase(), game: store.game, logoPath: logo)); if (context.mounted) Navigator.pop(context); }, child: const Text('Save'))]);
Future<void> pick() async { final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85); if (x != null) setState(() => logo = x.path); } }

class TemplatesPage extends StatelessWidget { const TemplatesPage({super.key}); @override Widget build(BuildContext context) {
  final names = List.generate(30, (i) => store.game == 'BGMI' ? 'Battle Royale Template ${i+1}' : 'Free Fire Clash Template ${i+1}');
  return GridView.builder(padding: const EdgeInsets.all(16), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: .8, crossAxisSpacing: 12, mainAxisSpacing: 12), itemCount: names.length, itemBuilder: (_, i) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: LinearGradient(colors: [i.isEven ? card2 : const Color(0xFF24152B), i.isEven ? const Color(0xFF142A26) : const Color(0xFF2E1837)]), border: Border.all(color: Colors.white10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(i.isEven ? Icons.shield : Icons.local_fire_department, color: i.isEven ? neon : pink, size: 42), const Spacer(), Text(names[i], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 6), const Text('Poster • Table • MVP', style: TextStyle(color: Colors.white60))])));
} }
