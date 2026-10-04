import 'package:flutter/material.dart';

List<String> writingCharacters(Iterable<String> texts) => texts
    .expand((text) => text.runes)
    .where((r) => (r >= 0x3041 && r <= 0x3096) ||
        (r >= 0x30a1 && r <= 0x30fa) || (r >= 0x4e00 && r <= 0x9fff))
    .map(String.fromCharCode).toSet().toList();

class WritingPracticePage extends StatefulWidget {
  final List<String> characters;
  const WritingPracticePage({super.key, required this.characters});
  @override State<WritingPracticePage> createState() => _WritingPracticeState();
}
class _WritingPracticeState extends State<WritingPracticePage> {
  int index = 0;
  bool model = true;
  final List<List<Offset>> strokes = [];
  int? activePointer;
  void select(int value) => setState(() {index = value; strokes.clear(); activePointer = null;});
  @override Widget build(BuildContext context) {
    if (widget.characters.isEmpty) {
      return Scaffold(appBar: AppBar(title: const Text('Atelier d’écriture')),
        body: const Center(child: Text('Aucun caractère à pratiquer dans cette leçon.')));
    }
    final character = widget.characters[index];
    return Scaffold(appBar: AppBar(title: const Text('Atelier d’écriture')), body: Center(
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(padding: const EdgeInsets.all(20), children: [
          const Text('Trace au doigt, au stylet ou à la souris. Masque le modèle pour écrire de mémoire, puis compare.'),
          const SizedBox(height: 12),
          Wrap(spacing: 6, runSpacing: 6, children: widget.characters.asMap().entries.map((e) => ChoiceChip(
            label: Text(e.value, style: const TextStyle(fontFamily: 'KotobaJapanese', fontSize: 22)),
            selected: index == e.key, onSelected: (_) => select(e.key))).toList()),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Afficher le modèle'),
            value: model, onChanged: (v) => setState(() => model = v)),
          AspectRatio(aspectRatio: 1, child: LayoutBuilder(builder: (context, bounds) {
            Offset point(Offset p) => Offset((p.dx / bounds.maxWidth).clamp(0.0, 1.0),
                (p.dy / bounds.maxHeight).clamp(0.0, 1.0));
            return Semantics(label: 'Zone de dessin pour $character', child: ClipRect(child: Listener(
              key: const ValueKey('writing-canvas'), behavior: HitTestBehavior.opaque,
              onPointerDown: (event) {
                if (activePointer != null) return;
                setState(() {activePointer = event.pointer; strokes.add([point(event.localPosition)]);});
              },
              onPointerMove: (event) {
                if (activePointer != event.pointer) return;
                setState(() => strokes.last.add(point(event.localPosition)));
              },
              onPointerUp: (event) {if (activePointer == event.pointer) activePointer = null;},
              onPointerCancel: (event) {if (activePointer == event.pointer) activePointer = null;},
              child: GestureDetector(behavior: HitTestBehavior.opaque,
                // Claim drags so the surrounding list does not scroll while writing.
                onPanStart: (_) {}, onPanUpdate: (_) {},
                child: CustomPaint(painter: WritingPainter(strokes.map((s) => List<Offset>.of(s)).toList()),
                  child: Center(child: IgnorePointer(child: Text(model ? character : '',
                    style: TextStyle(fontFamily: 'KotobaJapanese', fontSize: bounds.maxWidth * .72,
                      color: const Color(0xff72886d).withValues(alpha: .25))))))))));
          })),
          const SizedBox(height: 12),
          Text('${strokes.length} trait${strokes.length == 1 ? '' : 's'} dessiné${strokes.length == 1 ? '' : 's'}'),
          Wrap(spacing: 8, children: [
            OutlinedButton(onPressed: strokes.isEmpty ? null : () => setState(() {strokes.removeLast(); activePointer = null;}), child: const Text('Annuler le dernier trait')),
            OutlinedButton(onPressed: strokes.isEmpty ? null : () => setState(() {strokes.clear(); activePointer = null;}), child: const Text('Tout effacer')),
            FilledButton(onPressed: strokes.isEmpty ? null : () => setState(() => model = true), child: const Text('Comparer au modèle')),
          ]),
          const SizedBox(height: 12),
          const Text('Compare la forme, les proportions et les espaces entre les traits. Le modèle typographique ne montre pas l’ordre des traits. Cet atelier ne corrige pas automatiquement le dessin et ne valide pas les DS.'),
        ]))));
  }
}
class WritingPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  WritingPainter(this.strokes);
  @override void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    canvas.drawColor(const Color(0xfffbf7ef), BlendMode.srcOver);
    final grid = Paint()..color = const Color(0xffdedbd1)..strokeWidth = 1;
    canvas.drawRect(Rect.fromLTWH(.5, .5, size.width-1, size.height-1), grid..style = PaintingStyle.stroke);
    canvas.drawLine(Offset(size.width/2, 0), Offset(size.width/2, size.height), grid);
    canvas.drawLine(Offset(0, size.height/2), Offset(size.width, size.height/2), grid);
    final ink = Paint()..color = const Color(0xff253d33)..strokeWidth = 5
      ..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..style = PaintingStyle.stroke;
    Offset scaled(Offset p) => Offset(p.dx * size.width, p.dy * size.height);
    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {canvas.drawCircle(scaled(stroke.first), 2.5, Paint()..color = ink.color); continue;}
      final path = Path()..moveTo(scaled(stroke.first).dx, scaled(stroke.first).dy);
      for (final p in stroke.skip(1)) {final v = scaled(p); path.lineTo(v.dx, v.dy);}
      canvas.drawPath(path, ink);
    }
  }
  @override bool shouldRepaint(covariant WritingPainter oldDelegate) => true;
}
