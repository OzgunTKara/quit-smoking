import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final hasQuitDate = prefs.containsKey('quitDate');
  runApp(MyApp(startIndex: hasQuitDate ? 0 : 2));
}

class MyApp extends StatelessWidget {
  final int startIndex;
  const MyApp({super.key, required this.startIndex});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sigarayı Bırak',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: HomeScreen(initialIndex: startIndex),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, required this.initialIndex});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onSettingsSaved() {
    setState(() => _selectedIndex = 0);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Ayarlar kaydedildi!')));
  }

  late final List<Widget> _pages = [
    const SummaryPage(),
    const HealthPage(),
    SettingsPage(onSettingsSaved: _onSettingsSaved),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (idx) => setState(() => _selectedIndex = idx),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Özet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Sağlık',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
}

/// 1) ÖZET SEKMESİ (Geliştirilmiş Card + RefreshIndicator)
class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});
  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  String _quitDateStr = '';
  int _dailyCount = 0, _cigsPerPack = 1, _smokeTime = 0;
  double _packPrice = 0;
  Duration _elapsed = Duration.zero, _timeSaved = Duration.zero;
  int _unsmokedCigarettes = 0;
  double _moneySaved = 0;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final prefs = await SharedPreferences.getInstance();
    _quitDateStr        = prefs.getString('quitDate') ?? '';
    _dailyCount         = prefs.getInt('dailyCount') ?? 0;
    _cigsPerPack        = prefs.getInt('cigsPerPack') ?? 1;
    _packPrice          = prefs.getDouble('packPrice') ?? 0;
    _smokeTime          = prefs.getInt('smokeTime') ?? 0;

    final quitDate      = DateTime.tryParse(_quitDateStr) ?? DateTime.now();
    _elapsed            = DateTime.now().difference(quitDate);
    final days          = _elapsed.inDays;
    _unsmokedCigarettes = _dailyCount * days;
    _moneySaved         = (_unsmokedCigarettes / _cigsPerPack) * _packPrice;
    _timeSaved          = Duration(minutes: _unsmokedCigarettes * _smokeTime);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final days    = _elapsed.inDays;
    final hours   = _elapsed.inHours.remainder(24);
    final minutes = _elapsed.inMinutes.remainder(60);

    final savedHours   = _timeSaved.inHours;
    final savedMinutes = _timeSaved.inMinutes.remainder(60);

    return Scaffold(
      appBar: AppBar(title: const Text('Özet')),
      body: RefreshIndicator(
        onRefresh: _loadSummary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Bırakma Tarihi'),
                subtitle: Text(_quitDateStr),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.timer),
                title: const Text('Geçen Süre'),
                subtitle: Text('$days gün, $hours saat, $minutes dakika'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.smoke_free),
                title: const Text('İçilmemiş Sigara'),
                subtitle: Text('$_unsmokedCigarettes adet'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.attach_money),
                title: const Text('Kazanılan Para'),
                subtitle: Text('${_moneySaved.toStringAsFixed(2)} ₺'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Kazanılan Süre'),
                subtitle: Text('$savedHours saat, $savedMinutes dakika'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 2) SAĞLIK SEKMESİ (Placeholder)
class HealthPage extends StatelessWidget {
  const HealthPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sağlık')),
      body: const Center(child: Text('Sağlık ekranı yakında gelecek')),
    );
  }
}

/// 3) AYARLAR SEKMESİ
class SettingsPage extends StatefulWidget {
  final VoidCallback onSettingsSaved;
  const SettingsPage({super.key, required this.onSettingsSaved});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _quitDateController           = TextEditingController();
  final _dailyCountController         = TextEditingController();
  final _cigarettesPerPackController  = TextEditingController();
  final _packPriceController          = TextEditingController();
  final _smokeTimeController          = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final prefs = await SharedPreferences.getInstance();
    _quitDateController.text          = prefs.getString('quitDate') ?? '';
    _dailyCountController.text        = (prefs.getInt('dailyCount') ?? 0).toString();
    _cigarettesPerPackController.text = (prefs.getInt('cigsPerPack') ?? 1).toString();
    _packPriceController.text         = (prefs.getDouble('packPrice') ?? 0).toString();
    _smokeTimeController.text         = (prefs.getInt('smokeTime') ?? 0).toString();
    setState(() {});
  }

  @override
  void dispose() {
    _quitDateController.dispose();
    _dailyCountController.dispose();
    _cigarettesPerPackController.dispose();
    _packPriceController.dispose();
    _smokeTimeController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quitDate', _quitDateController.text);
    await prefs.setInt('dailyCount', int.parse(_dailyCountController.text));
    await prefs.setInt('cigsPerPack', int.parse(_cigarettesPerPackController.text));
    await prefs.setDouble('packPrice', double.parse(_packPriceController.text));
    await prefs.setInt('smokeTime', int.parse(_smokeTimeController.text));

    widget.onSettingsSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarları Düzenle')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _quitDateController,
                decoration: const InputDecoration(
                  labelText: 'Bırakma Tarihi (örn: 2025-05-05 10:30)',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Bu alan zorunlu' : null,
              ),
              TextFormField(
                controller: _dailyCountController,
                decoration: const InputDecoration(labelText: 'Günlük içilen sigara sayısı'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Bu alan zorunlu' : null,
              ),
              TextFormField(
                controller: _cigarettesPerPackController,
                decoration: const InputDecoration(labelText: 'Paketteki sigara adedi'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Bu alan zorunlu' : null,
              ),
              TextFormField(
                controller: _packPriceController,
                decoration: const InputDecoration(labelText: 'Paket fiyatı (₺)'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Bu alan zorunlu' : null,
              ),
              TextFormField(
                controller: _smokeTimeController,
                decoration: const InputDecoration(labelText: 'Bir sigarayı içme süresi (dakika)'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Bu alan zorunlu' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
