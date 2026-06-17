import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_screen.dart';
import '../../privacy/data/local_privacy_repository.dart';
import '../data/ai_coach_repository.dart';

class AiCoachScreen extends ConsumerStatefulWidget {
  const AiCoachScreen({super.key});

  @override
  ConsumerState<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends ConsumerState<AiCoachScreen> {
  final _question = TextEditingController();
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return GpScreen(
      body: dbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Datenbankfehler: $error')),
        data: (db) {
          final repo = AiCoachRepository(db);
          return FutureBuilder<List<Object>>(
            key: ValueKey(_reload),
            future: Future.wait([
              LocalPrivacyRepository(db).snapshot(),
              repo.listMessages(),
            ]),
            builder: (context, snapshot) {
              final consent = snapshot.data == null
                  ? false
                  : (snapshot.data![0] as LocalPrivacySnapshot)
                        .aiContextAllowed;
              final messages = snapshot.data == null
                  ? <AiCoachMessage>[]
                  : snapshot.data![1] as List<AiCoachMessage>;
              return Column(
                children: [
                  if (!consent)
                    Container(
                      width: double.infinity,
                      color: GpColors.redSurface,
                      padding: const EdgeInsets.all(12),
                      child: const Text(
                        'KI-Kontextfreigabe ist aus. Fragen werden lokal gespeichert, Gesundheitskontext bleibt gesperrt.',
                      ),
                    ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: messages
                          .map(
                            (message) => Align(
                              alignment: message.role == 'user'
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Card(
                                color: message.role == 'user'
                                    ? GpColors.redSurface
                                    : null,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(message.content),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _question,
                            decoration: const InputDecoration(
                              labelText: 'Frage',
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Senden',
                          icon: const Icon(Icons.send_outlined),
                          onPressed: () => _ask(repo),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _ask(AiCoachRepository repo) async {
    final question = _question.text.trim();
    if (question.isEmpty) return;
    await repo.ask(question);
    _question.clear();
    if (mounted) setState(() => _reload++);
  }
}
