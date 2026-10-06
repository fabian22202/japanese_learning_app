import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/handwriting.dart';

List<String> writingCharacters(Iterable<String> texts) => texts
    .expand((text) => text.runes)
    .where(
      (r) =>
          (r >= 0x3041 && r <= 0x3096) ||
          (r >= 0x30a1 && r <= 0x30fc) ||
          (r >= 0x4e00 && r <= 0x9fff),
    )
    .map(String.fromCharCode)
    .toSet()
    .toList();

class WritingPracticePage extends StatefulWidget {
  final List<String> characters;
  const WritingPracticePage({super.key, required this.characters});
  @override
  State<WritingPracticePage> createState() => _WritingPracticeState();
}

class _WritingPracticeState extends State<WritingPracticePage>
    with SingleTickerProviderStateMixin {
  int index = 0;
  bool model = true, loading = true, guidedAttempt = true;
  final List<List<Offset>> strokes = [];
  final Map<String, List<List<Offset>>> models = {};
  WritingResult? result;
  int? activePointer;
  late final AnimationController animation;
  List<List<Offset>> get target => models[widget.characters[index]] ?? [];
  @override
  void initState() {
    super.initState();
    animation = AnimationController(vsync: this)
      ..addListener(() {
        if (mounted) setState(() {});
      });
    loadModels();
  }

  Future<void> loadModels() async {
    try {
      final data = jsonDecode(
        await rootBundle.loadString('assets/stroke_models.json'),
      ) as Map<String, dynamic>;
      final characters = data['characters'] as Map<String, dynamic>;
      for (final entry in characters.entries) {
        models[entry.key] = (entry.value as List)
            .map(
              (s) => (s as List)
                  .map(
                    (p) => Offset(
                      (p[0] as num).toDouble(),
                      (p[1] as num).toDouble(),
                    ),
                  )
                  .toList(),
            )
            .toList();
      }
    } catch (_) {
      // Drawing remains usable; never manufacture a score without a model.
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  void select(int value) {
    animation.stop();
    setState(() {
      index = value;
      if (result != null) model = guidedAttempt;
      strokes.clear();
      result = null;
      activePointer = null;
      animation.value = 0;
    });
  }

  void demonstrate() {
    animation.stop();
    setState(() {
      strokes.clear();
      result = null;
      model = true;
    });
    animation.duration = Duration(milliseconds: target.length * 850);
    animation.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.characters.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exercice d’écriture')),
        body: const Center(
          child: Text('Aucun caractère à pratiquer dans cette leçon.'),
        ),
      );
    }
    final character = widget.characters[index];
    final hasTarget = target.isNotEmpty;
    final busy = activePointer != null || animation.isAnimating;
    return Scaffold(
      appBar: AppBar(title: const Text('Exercice d’écriture')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Observe le tracé, puis écris chaque trait au doigt, au stylet ou à la souris. Un geste correspond à un trait.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: widget.characters
                      .asMap()
                      .entries
                      .map(
                        (e) => ChoiceChip(
                          label: Text(
                            e.value,
                            style: const TextStyle(
                              fontFamily: 'KotobaJapanese',
                              fontSize: 22,
                            ),
                          ),
                          selected: index == e.key,
                          onSelected: (_) => select(e.key),
                        ),
                      )
                      .toList(),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Afficher le modèle'),
                  subtitle: Text(model ? 'Mode guidé' : 'Écriture de mémoire'),
                  value: model,
                  onChanged: busy
                      ? null
                      : (v) => setState(() {
                          model = v;
                          result = null;
                        }),
                ),
                if (loading) const LinearProgressIndicator(),
                if (!loading && !hasTarget)
                  const Text(
                    'Modèle de traits indisponible : comparaison visuelle uniquement, sans score.',
                  ),
                if (hasTarget)
                  OutlinedButton.icon(
                    onPressed: busy ? null : demonstrate,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Voir le tracé animé (efface l’essai)'),
                  ),
                if (animation.isAnimating)
                  Text(
                    'Trait ${math.min(target.length, (animation.value * target.length).floor() + 1)} / ${target.length}',
                  ),
                AspectRatio(
                  aspectRatio: 1,
                  child: LayoutBuilder(
                    builder: (context, bounds) {
                      Offset point(Offset p) => Offset(
                        (p.dx / bounds.maxWidth).clamp(0.0, 1.0),
                        (p.dy / bounds.maxHeight).clamp(0.0, 1.0),
                      );
                      return Semantics(
                        label: 'Zone de dessin pour $character',
                        child: ClipRect(
                          child: Listener(
                            key: const ValueKey('writing-canvas'),
                            behavior: HitTestBehavior.opaque,
                            onPointerDown: (event) {
                              if (activePointer != null ||
                                  animation.isAnimating)
                                return;
                              setState(() {
                                activePointer = event.pointer;
                                result = null;
                                strokes.add([point(event.localPosition)]);
                              });
                            },
                            onPointerMove: (event) {
                              if (activePointer != event.pointer) return;
                              setState(
                                () => strokes.last.add(
                                  point(event.localPosition),
                                ),
                              );
                            },
                            onPointerUp: (event) {
                              if (activePointer == event.pointer)
                                setState(() => activePointer = null);
                            },
                            onPointerCancel: (event) {
                              if (activePointer == event.pointer)
                                setState(() {
                                  activePointer = null;
                                  strokes.removeLast();
                                  result = null;
                                });
                            },
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanStart: (_) {},
                              onPanUpdate: (_) {},
                              child: CustomPaint(
                                painter: WritingPainter(
                                  strokes
                                      .map((s) => List<Offset>.of(s))
                                      .toList(),
                                  reference: model || result != null
                                      ? target
                                      : [],
                                  animationProgress: animation.isAnimating
                                      ? animation.value
                                      : null,
                                  result: result,
                                ),
                                child: Center(
                                  child: IgnorePointer(
                                    child: Text(
                                      model && !hasTarget ? character : '',
                                      style: TextStyle(
                                        fontFamily: 'KotobaJapanese',
                                        fontSize: bounds.maxWidth * .72,
                                        color: const Color(0xff72886d)
                                            .withValues(alpha: .25),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${strokes.length} trait${strokes.length == 1 ? '' : 's'} dessiné${strokes.length == 1 ? '' : 's'}',
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: strokes.isEmpty || busy
                          ? null
                          : () => setState(() {
                              strokes.removeLast();
                              result = null;
                            }),
                      child: const Text('Annuler le dernier trait'),
                    ),
                    OutlinedButton(
                      onPressed: strokes.isEmpty || busy
                          ? null
                          : () => setState(() {
                              strokes.clear();
                              result = null;
                            }),
                      child: const Text('Tout effacer'),
                    ),
                    FilledButton(
                      onPressed: strokes.isEmpty || busy || loading
                          ? null
                          : () => setState(() {
                              guidedAttempt = model;
                              model = true;
                              result = hasTarget
                                  ? evaluateWriting(strokes, target)
                                  : null;
                            }),
                      child: const Text('Comparer au modèle'),
                    ),
                  ],
                ),
                if (result case final r?) ...[
                  const SizedBox(height: 12),
                  Text(guidedAttempt ? 'Essai guidé' : 'Essai de mémoire'),
                  Text(
                    'Fidélité du tracé : ${r.score}/100',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Forme ${r.shape}/100 · Ordre ${r.order}/100 · Sens ${r.direction}/100',
                  ),
                  Text('${r.drawn} traits dessinés / ${r.expected} attendus.'),
                  const Text(
                    'Le modèle vert montre la correction. Les traits orange sont éloignés du modèle ; les numéros indiquent l’ordre attendu.',
                  ),
                  if (r.drawn != r.expected)
                    const Text(
                      'Revois le nombre de traits : chaque trait doit être dessiné en un seul geste.',
                    ),
                  if (r.order < r.shape)
                    const Text(
                      'Observe les numéros pour reprendre les traits dans le bon ordre.',
                    ),
                  if (r.direction < r.shape)
                    const Text(
                      'Rejoue l’animation pour vérifier le sens des gestes.',
                    ),
                  OutlinedButton(
                    onPressed: () => select(index),
                    child: const Text('Réessayer'),
                  ),
                  if (index + 1 < widget.characters.length)
                    FilledButton(
                      onPressed: () => select(index + 1),
                      child: const Text('Caractère suivant'),
                    ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Score indicatif : forme 70 %, ordre 20 %, sens 10 %. Il compare ton dessin au modèle, sans reconnaître ni certifier ton écriture. Il ne valide pas les DS.',
                ),
                TextButton(
                  onPressed: () =>
                      launchUrl(Uri.parse('https://kanjivg.tagaini.net/')),
                  child: const Text(
                    'Tracés : KanjiVG, Ulrich Apel · CC BY-SA 3.0',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WritingPainter extends CustomPainter {
  final List<List<Offset>> strokes, reference;
  final double? animationProgress;
  final WritingResult? result;
  WritingPainter(
    this.strokes, {
    this.reference = const [],
    this.animationProgress,
    this.result,
  });
  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    canvas.drawColor(const Color(0xfffbf7ef), BlendMode.srcOver);
    final grid = Paint()
      ..color = const Color(0xffdedbd1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
      Rect.fromLTWH(.5, .5, size.width - 1, size.height - 1),
      grid,
    );
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      grid,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      grid,
    );
    Offset scaled(Offset p) => Offset(p.dx * size.width, p.dy * size.height);
    void draw(List<Offset> stroke, Color color, double width) {
      if (stroke.isEmpty) return;
      final ink = Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      if (stroke.length == 1) {
        canvas.drawCircle(
          scaled(stroke.first),
          width / 2,
          Paint()..color = color,
        );
        return;
      }
      final path = Path()
        ..moveTo(scaled(stroke.first).dx, scaled(stroke.first).dy);
      for (final p in stroke.skip(1)) {
        final v = scaled(p);
        path.lineTo(v.dx, v.dy);
      }
      canvas.drawPath(path, ink);
    }

    for (int i = 0; i < reference.length; i++) {
      final stroke = reference[i];
      if (stroke.isEmpty) continue;
      draw(
        stroke,
        const Color(0xff72886d).withValues(alpha: result == null ? .25 : .7),
        5,
      );
      if (animationProgress != null) {
        final fraction = (animationProgress! * reference.length - i).clamp(
          0.0,
          1.0,
        );
        if (fraction > 0) {
          final points = resampleStroke(stroke, 100);
          final end = fraction * (points.length - 1);
          final segment = end.floor();
          final partial = points.take(segment + 1).toList();
          if (segment + 1 < points.length)
            partial.add(
              Offset.lerp(points[segment], points[segment + 1], end - segment)!,
            );
          draw(partial, const Color(0xff253d33), 5);
          canvas.drawCircle(
            scaled(partial.last),
            5,
            Paint()..color = const Color(0xffc97632),
          );
        }
      }
      final label = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(color: Color(0xff53684e), fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, scaled(stroke.first) - const Offset(12, 16));
    }
    for (int i = 0; i < strokes.length; i++) {
      final bad =
          result != null &&
          (result!.matches[i] < 0 ||
              result!.errors[i] > .06 ||
              strokeLength(strokes[i]) < .015);
      draw(
        strokes[i],
        bad ? const Color(0xffc97632) : const Color(0xff253d33),
        4,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WritingPainter oldDelegate) => true;
}
