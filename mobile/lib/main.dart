import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/traveler_profile.dart';
import 'repositories/profile_repository.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/assistant/assistant_screen.dart';
import 'features/market/market_screen.dart';
import 'features/currency/currency_screen.dart';
import 'features/auth/auth_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const CoraApp());
}

class CoraApp extends StatelessWidget {
  const CoraApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'CORA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF007F79)),
          scaffoldBackgroundColor: const Color(0xFFF6F8F4),
          appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF6F8F4), centerTitle: false),
          inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none)),
          filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(minimumSize: const Size(48, 52))),
          cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)))),
      home: const ProfileGate());
}

class ProfileGate extends StatefulWidget {
  const ProfileGate({super.key});
  @override
  State<ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<ProfileGate> {
  final _repository = ProfileRepository();
  TravelerProfile? _profile;
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _repository.load();
      if (mounted) setState(() => _profile = profile);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No pude leer tu perfil. Intenta de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save(TravelerProfile p) async {
    await _repository.save(p);
    if (mounted) setState(() => _profile = p);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
          body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_error!),
        TextButton(onPressed: _load, child: const Text('Reintentar'))
      ])));
    }
    if (FirebaseAuth.instance.currentUser == null) {
      return AuthScreen(onAuthenticated: _load);
    }
    if (_profile == null) return OnboardingScreen(onComplete: _save);
    return TravelHome(
        profile: _profile!,
        onSave: _save,
        onReset: () async {
          await _repository.clear();
          if (mounted) setState(() => _profile = null);
        });
  }
}

class TravelHome extends StatefulWidget {
  final TravelerProfile profile;
  final Future<void> Function(TravelerProfile) onSave;
  final Future<void> Function() onReset;
  const TravelHome(
      {super.key,
      required this.profile,
      required this.onSave,
      required this.onReset});
  @override
  State<TravelHome> createState() => _TravelHomeState();
}

class _TravelHomeState extends State<TravelHome> {
  int _tab = 0;
  void _chat([String? initialMessage]) => Navigator.push(
      context,
      MaterialPageRoute<void>(
          builder: (_) => AssistantScreen(
              profile: widget.profile, initialMessage: initialMessage)));
  Future<void> _edit() async => Navigator.push(
      context,
      MaterialPageRoute<void>(
          builder: (editContext) => OnboardingScreen(
              initial: widget.profile,
              onComplete: (p) async {
                await widget.onSave(p);
                if (editContext.mounted) Navigator.pop(editContext);
              })));
  Future<void> _reset() async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
                title: const Text('¿Borrar tu perfil local?'),
                content: const Text('Volverás a la bienvenida de CORA.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancelar')),
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Borrar'))
                ]));
    if (confirmed != true) return;
    try {
      await widget.onReset();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No pude borrar el perfil. Intenta de nuevo.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: const Text('CORA',
                style:
                    TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3)),
            actions: [
              IconButton(
                  onPressed: _edit,
                  tooltip: 'Editar perfil',
                  icon: const Icon(Icons.person_outline))
            ]),
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: IndexedStack(index: _tab, children: [
                      _home(),
                      MarketScreen(askCora: _chat),
                      const CurrencyScreen(),
                    ])))),
        bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (v) => setState(() => _tab = v),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.explore_outlined), label: 'Mi viaje'),
              NavigationDestination(
                  icon: Icon(Icons.storefront_outlined), label: 'Market'),
              NavigationDestination(
                  icon: Icon(Icons.currency_exchange), label: 'Divisas')
            ]),
      );
  Widget _home() => ListView(padding: const EdgeInsets.all(24), children: [
        const Text('EL SALVADOR · A TU RITMO',
            style: TextStyle(
                fontSize: 10, letterSpacing: 2, color: Color(0xFF007F79))),
        const SizedBox(height: 10),
        Text('¡Hola, ${widget.profile.name}!',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('Tu próxima historia empieza aquí.',
            style: TextStyle(fontSize: 17, color: Color(0xFF53665F))),
        const SizedBox(height: 24),
        Container(
            height: 220,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: const Color(0xFF005F63)),
            child: Stack(children: [
              const Positioned.fill(child: CustomPaint(painter: _Landscape())),
              Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Entre olas\ny volcanes.',
                            style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                                color: Colors.white)),
                        const Spacer(),
                        FilledButton.tonalIcon(
                            onPressed: () => _chat(
                                'Con mi perfil, ¿qué me recomiendas hacer hoy en El Salvador?'),
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text('Inspirarme con CORA')),
                      ])),
            ])),
        const SizedBox(height: 24),
        const Text('¿Qué hacemos hoy?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        _action(Icons.auto_awesome, 'Hablar con CORA',
            'Ideas y consejos pensados para ti', () => _chat()),
        _action(Icons.storefront_outlined, 'Descubrir experiencias',
            'Surf, sabores y rincones locales', () => setState(() => _tab = 1)),
        _action(
            Icons.currency_exchange,
            'Convertir mi moneda',
            'Prepara tu presupuesto en dólares',
            () => setState(() => _tab = 2)),
        const SizedBox(height: 20),
        const Text('TU FORMA DE VIAJAR',
            style: TextStyle(fontSize: 10, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Wrap(
            spacing: 8,
            children: widget.profile.interests
                .map((i) => Chip(label: Text(i)))
                .toList()),
        Text('Presupuesto diario: ${widget.profile.budget} USD'),
        TextButton(
            onPressed: _edit, child: const Text('Ajustar mis preferencias')),
        TextButton(
            onPressed: _reset,
            child: const Text('Borrar mi perfil de este dispositivo',
                style: TextStyle(fontSize: 12))),
      ]);
  Widget _action(
          IconData icon, String title, String subtitle, VoidCallback tap) =>
      Card(
          child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              leading: Icon(icon, color: const Color(0xFF007F79)),
              title: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: tap));
}

class _Landscape extends CustomPainter {
  const _Landscape();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(Offset(size.width * .83, 50), 28,
        Paint()..color = const Color(0xFFF4D68C));
    final mountain = Path()
      ..moveTo(size.width * .30, size.height)
      ..lineTo(size.width * .69, 75)
      ..lineTo(size.width * .78, 95)
      ..lineTo(size.width * .86, 82)
      ..lineTo(size.width * 1.1, size.height)
      ..close();
    canvas.drawPath(mountain, Paint()..color = const Color(0xFF3B9490));
    final wave = Path()
      ..moveTo(0, size.height * .78)
      ..quadraticBezierTo(
          size.width * .45, size.height * .48, size.width, size.height * .82)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(wave, Paint()..color = const Color(0xFF24817D));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
