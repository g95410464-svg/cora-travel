import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/traveler_profile.dart';

class OnboardingScreen extends StatefulWidget {
  final Future<void> Function(TravelerProfile) onComplete;
  final TravelerProfile? initial;
  const OnboardingScreen({super.key, required this.onComplete, this.initial});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _name = TextEditingController(), _country = TextEditingController();
  final _form = GlobalKey<FormState>();
  int _step = 0;
  String _language = 'es', _budget = '30–70';
  final _interests = <String>{};
  bool _saving = false;
  String? _error;
  static const _questions = [
    '¡Hola! Soy CORA. ¿Cómo te llamas?',
    '¿De qué país vienes?',
    '¿En qué idioma prefieres conversar?',
    '¿Cuánto quieres gastar al día?',
    '¿Qué te gustaría vivir en El Salvador?'
  ];
  static const _hints = [
    'Vamos a preparar un viaje que se sienta tuyo.',
    'Me ayudará a conocer un poco más de ti.',
    'Usaré este idioma cuando hablemos.',
    'Un aproximado en dólares, por persona. Puedes cambiarlo después.',
    'Elige una o varias opciones. Yo te ayudo a descubrir el resto.'
  ];
  static const interests = [
    'Aventura',
    'Gastronomía',
    'Cultura',
    'Naturaleza',
    'Playa',
    'Surf',
    'Vida nocturna',
    'Relajación'
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    if (p != null) {
      _name.text = p.name;
      _country.text = p.country;
      _language = p.language;
      _budget = p.budget;
      _interests.addAll(p.interests);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _country.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (!(_form.currentState?.validate() ?? true)) return;
    if (_step < 4) {
      setState(() {
        _step++;
        _error = null;
      });
      return;
    }
    if (_interests.isEmpty) {
      setState(() => _error = 'Elige al menos una experiencia.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onComplete(TravelerProfile(
          id: widget.initial?.id ?? FirebaseAuth.instance.currentUser!.uid,
          name: _name.text.trim(),
          country: _country.text.trim(),
          language: _language,
          budget: _budget,
          interests: _interests.toList()));
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No pude guardar tu perfil. Intenta de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('CORA'), actions: [
        Padding(
            padding: const EdgeInsets.all(16), child: Text('${_step + 1} / 5'))
      ]),
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: ListView(key: ValueKey(_step), padding: const EdgeInsets.all(24), children: [
                    LinearProgressIndicator(
                        value: (_step + 1) / 5,
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(8)),
                    const SizedBox(height: 32),
                    const Align(
                        alignment: Alignment.centerLeft,
                        child: CircleAvatar(
                            radius: 32,
                            backgroundColor: Color(0xFF007F79),
                            child: Icon(Icons.auto_awesome,
                                color: Colors.white, size: 30))),
                    const SizedBox(height: 24),
                    Text(_questions[_step],
                        style: const TextStyle(
                            fontSize: 29,
                            fontWeight: FontWeight.w700,
                            height: 1.15)),
                    const SizedBox(height: 12),
                    Text(_hints[_step],
                        style: const TextStyle(
                            fontSize: 16, color: Color(0xFF53665F))),
                    const SizedBox(height: 28),
                    Form(
                        key: _form,
                        child: switch (_step) {
                          0 => TextFormField(
                              key: const ValueKey('name'),
                              controller: _name,
                              maxLength: 60,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                  labelText: 'Tu nombre',
                                  hintText: 'Por ejemplo, Alex'),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Escribe tu nombre.'
                                  : null),
                          1 => TextFormField(
                              key: const ValueKey('country'),
                              controller: _country,
                              maxLength: 80,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                  labelText: 'País de origen'),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Escribe tu país.'
                                  : null),
                          2 => Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: {
                                'es': 'Español',
                                'en': 'English',
                                'pt': 'Português',
                                'fr': 'Français'
                              }
                                  .entries
                                  .map((e) => ChoiceChip(
                                      label: Text(e.value),
                                      selected: _language == e.key,
                                      onSelected: (_) =>
                                          setState(() => _language = e.key)))
                                  .toList()),
                          3 => Column(
                                children: [
                              'Menos de 30',
                              '30–70',
                              '70–150',
                              'Más de 150'
                            ]
                                    .map((b) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 10),
                                        child: ListTile(
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16)),
                                            tileColor: _budget == b
                                                ? const Color(0xFFDCEEE6)
                                                : Colors.white,
                                            title: Text('$b USD'),
                                            trailing: Icon(_budget == b
                                                ? Icons.check_circle
                                                : Icons.circle_outlined),
                                            onTap: () =>
                                                setState(() => _budget = b))))
                                    .toList()),
                          _ => Wrap(
                              spacing: 8,
                              runSpacing: 10,
                              children: interests
                                  .map((i) => FilterChip(
                                      label: Text(i),
                                      selected: _interests.contains(i),
                                      onSelected: (v) => setState(() {
                                            v
                                                ? _interests.add(i)
                                                : _interests.remove(i);
                                          })))
                                  .toList()),
                        }),
                    const SizedBox(height: 30),
                    if (_error != null)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(_error!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error))),
                    FilledButton(
                        onPressed: _saving ? null : _next,
                        child: Text(_saving
                            ? 'Guardando…'
                            : _step == 4
                                ? 'Empezar mi viaje'
                                : 'Continuar')),
                    if (_step > 0)
                      TextButton(
                          onPressed: _saving
                              ? null
                              : () => setState(() {
                                    _step--;
                                    _error = null;
                                  }),
                          child: const Text('Atrás')),
                    const SizedBox(height: 14),
                    const Text(
                        'Tu perfil se guarda en este dispositivo. Al conversar, CORA lo usa para personalizar sus respuestas.',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF53665F))),
                  ])))));
}
