import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'gp_colors.dart';

class GpVoiceNavigation extends StatefulWidget {
  const GpVoiceNavigation({
    super.key,
    required this.content,
    this.title = 'Sprachführung',
    this.locale = 'de-DE',
  });

  final String content;
  final String title;
  final String locale;

  @override
  State<GpVoiceNavigation> createState() => _GpVoiceNavigationState();
}

class _GpVoiceNavigationState extends State<GpVoiceNavigation> {
  late final FlutterTts _tts;
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts()
      ..setCompletionHandler(_markStopped)
      ..setCancelHandler(_markStopped)
      ..setErrorHandler((_) => _markStopped());
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasContent = widget.content.trim().isNotEmpty;
    return Card(
      color: const Color(0xFFEFF6FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFBFDBFE), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              _speaking ? Icons.volume_off_outlined : Icons.volume_up_outlined,
              color: const Color(0xFF2563EB),
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: GpColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _speaking
                        ? 'Vorlesen läuft'
                        : 'Inhalte dieser Seite vorlesen lassen',
                    style: const TextStyle(
                      color: GpColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonalIcon(
              onPressed: hasContent ? _toggleSpeech : null,
              icon: Icon(
                _speaking ? Icons.stop_circle_outlined : Icons.play_arrow,
              ),
              label: Text(_speaking ? 'Stop' : 'Vorlesen'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleSpeech() async {
    if (_speaking) {
      await _tts.stop();
      _markStopped();
      return;
    }

    setState(() => _speaking = true);
    await _tts.setLanguage(widget.locale);
    await _tts.setSpeechRate(0.46);
    await _tts.setPitch(1);
    await _tts.speak(widget.content);
  }

  void _markStopped() {
    if (mounted) {
      setState(() => _speaking = false);
    }
  }
}
