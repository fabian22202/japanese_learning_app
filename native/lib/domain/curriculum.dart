import 'dart:convert';
import 'models.dart';
import 'engine.dart';

/// All authoring data stays in JSON; validation completes before installation.
class Curriculum {
  final Json document;
  final List<LearningModule> modules;
  Curriculum._(this.document, this.modules);
  String encode() => const JsonEncoder.withIndent('  ').convert(document);
  static Curriculum parse(String source) {
    if (utf8.encode(source).length > 4000000) {
      throw const FormatException('Programme trop volumineux (maximum 4 Mo).');
    }
    dynamic raw;
    try { raw = jsonDecode(source); } catch (_) {
      throw const FormatException('Le fichier ne contient pas un JSON valide.');
    }
    final Json doc;
    if (raw is List) {
      doc = {'format': 'kotoba.curriculum', 'version': 1, 'modules': raw};
    } else {
      doc = _map(raw, 'programme');
      if (doc['format'] != 'kotoba.curriculum' || doc['version'] != 1) {
        throw const FormatException('Format attendu : kotoba.curriculum, version 1.');
      }
    }
    final modules = _list(doc['modules'], 'modules', 1, 50);
    final ids = <String>{}, wordIds = <String>{};
    void unique(Json value, String path, Set<String> seen) {
      final id = _text(value['id'], '$path.id');
      if (!RegExp(r'^[a-zA-Z0-9_-]{1,80}$').hasMatch(id) || !seen.add(id)) {
        throw FormatException('$path.id : identifiant unique attendu (lettres, chiffres, tirets).');
      }
    }
    for (var mi = 0; mi < modules.length; mi++) {
      final path = 'modules[$mi]', m = _map(modules[mi], 'modules[$mi]');
      unique(m, path, ids);
      for (final field in ['title', 'subtitle', 'symbol', 'color']) {
        _text(m[field], '$path.$field');
      }
      final lessons = _list(m['lessons'], '$path.lessons', 1, 50);
      final mcos = _list(m['mcos'], '$path.mcos', 2, 4);
      for (final collection in {'lessons': lessons, 'mcos': mcos}.entries) {
        for (var i = 0; i < collection.value.length; i++) {
          final p = '$path.${collection.key}[$i]', u = _map(collection.value[i], '$path.${collection.key}[$i]');
          unique(u, p, ids); _text(u['title'], '$p.title');
          _strings(u['paragraphs'], '$p.paragraphs');
          for (final row in _optionalList(u['table'], '$p.table')) {
            _strings(row, '$p.table', minimum: 2);
          }
          final words = _optionalList(u['words'], '$p.words');
          if (collection.key == 'mcos' && (words.isEmpty || words.length > 10)) {
            throw FormatException('$p.words : un MCO contient de 1 à 10 mots.');
          }
          if (collection.key == 'lessons' && words.isNotEmpty) {
            throw FormatException('$p : place le vocabulaire dans un MCO.');
          }
          for (final word in words) {
            final w = _map(word, '$p.words'); unique(w, '$p.words', wordIds);
            for (final f in ['writing', 'reading', 'meaning']) { _text(w[f], '$p.words.$f'); }
            _strings(w['readingAlternatives'], '$p.words.readingAlternatives');
            _strings(w['usage'], '$p.words.usage');
            for(final info in _optionalList(w['kanji'], '$p.words.kanji')) {
              final k=_map(info,'$p.words.kanji');
              final character=_text(k['character'],'$p.words.kanji.character');
              _strings(k['kunyomi'],'$p.words.kanji.kunyomi');
              _strings(k['onyomi'],'$p.words.kanji.onyomi');
              if(k['note']!=null) _text(k['note'],'$p.words.kanji.note');
              for(final illustration in _optionalList(k['examples'],'$p.words.kanji.examples')) {
                final e=_map(illustration,'$p.words.kanji.examples');
                for(final field in ['writing','reading','meaning']) { _text(e[field],'$p.words.kanji.examples.$field'); }
                if(!['kun','on'].contains(e['kind'])||!(e['writing'] as String).contains(character)) {
                  throw FormatException('$p.words.kanji.examples : exemple kun/on contenant le caractère attendu.');
                }
              }
            }
          }
          for (final resource in _optionalList(u['resources'], '$p.resources')) {
            final r = _map(resource, '$p.resources'); _text(r['title'], '$p.resources.title');
            final uri = Uri.tryParse(_text(r['url'], '$p.resources.url'));
            if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
              throw FormatException('$p.resources.url : lien HTTPS attendu.');
            }
          }
          for (final section in _optionalList(u['sections'], '$p.sections')) {
            final s = _map(section, '$p.sections'); _text(s['title'], '$p.sections.title');
            _strings(s['paragraphs'], '$p.sections.paragraphs');
            if (s['note'] != null) _text(s['note'], '$p.sections.note');
            for (final example in _optionalList(s['examples'], '$p.sections.examples')) {
              final e = _map(example, '$p.sections.examples');
              for (final f in ['jp','reading','fr']) { _text(e[f], '$p.sections.examples.$f'); }
            }
          }
          for (final fact in _optionalList(u['questions'], '$p.questions')) {
            final q = _map(fact, '$p.questions');
            for (final f in ['prompt','answer','explanation']) { _text(q[f], '$p.questions.$f'); }
            _strings(q['alternatives'], '$p.questions.alternatives');
          }
          final exerciseIds = <String>{};
          for (final exercise in _optionalList(u['exercises'], '$p.exercises')) {
            final e = _map(exercise, '$p.exercises'); unique(e, '$p.exercises', exerciseIds);
            for (final f in ['prompt','answer','explanation']) { _text(e[f], '$p.exercises.$f'); }
            _strings(e['alternatives'], '$p.exercises.alternatives');
            if (!['input','choice','order'].contains(e['type'])) throw FormatException('$p.exercises.type : input, choice ou order attendu.');
            if (e['type'] == 'choice') {
              _strings(e['choices'], '$p.exercises.choices', minimum: 2);
              final choices = strings(e['choices']);
              if (choices.toSet().length != choices.length || !choices.contains(e['answer'])) throw FormatException('$p.exercises.choices : choix distincts incluant la réponse attendus.');
            }
            if (e['type'] == 'order') {
              _strings(e['tokens'], '$p.exercises.tokens', minimum: 2);
              final q = Question(id: '', conceptId: '', type: 'order', prompt: '', answer: e['answer'], explanation: '', alternatives: strings(e['alternatives']));
              if (!correct(q, strings(e['tokens']).join())) throw FormatException('$p.exercises.tokens : les éléments doivent reconstruire la réponse.');
            }
          }
          if (u['generator'] != null) {
            final g = _map(u['generator'], '$p.generator');
            switch (g['kind']) {
              case 'kana':
                _list(u['table'], '$p.table', 1, 200);
                break;
              case 'numbers':
                if (g['min'] is! int || g['max'] is! int || g['min'] < 0 || g['max'] > 99 || g['min'] > g['max']) throw FormatException('$p.generator : min/max entiers entre 0 et 99 attendus.');
                break;
              case 'kanji': break;
              case 'frames':
                for (final frame in _list(g['frames'], '$p.generator.frames', 1, 50)) {
                  final f = _map(frame, '$p.generator.frames');
                  _strings(f['tokens'], '$p.generator.tokens', minimum: 1);
                  for (final key in ['french','explanation']) { _text(f[key], '$p.generator.$key'); }
                  final tokens = strings(f['tokens']);
                  if (f['focus'] is! int || f['focus'] < 0 || f['focus'] >= tokens.length) throw FormatException('$p.generator.focus : index de token invalide.');
                  final domains = _map(f['domains'], '$p.generator.domains');
                  var combinations = 1;
                  for (final d in domains.entries) {
                    for (final word in _list(d.value, '$p.generator.domains.${d.key}', 1, 100)) {
                      final w = _map(word, '$p.generator.domains'); _text(w['jp'], '$p.generator.jp'); _text(w['fr'], '$p.generator.fr');
                    }
                    combinations *= (d.value as List).length;
                    if (combinations > 500) throw FormatException('$p.generator : maximum 500 combinaisons par modèle.');
                  }
                  for (final t in [...tokens, f['french'] as String]) {
                    for (final match in RegExp(r'\{([^}]+)\}').allMatches(t)) {
                      if (!domains.containsKey(match[1])) throw FormatException('$p.generator : domaine ${match[1]} manquant.');
                    }
                  }
                }
                break;
              default: throw FormatException('$p.generator.kind : générateur inconnu.');
            }
          }
          if (collection.key == 'lessons' && u['generator'] == null && _optionalList(u['questions'], p).isEmpty && _optionalList(u['exercises'], p).isEmpty) {
            throw FormatException('$p : ajoute au moins un exercice ou un générateur.');
          }
        }
      }
    }
    final parsed = modules.map((m) => LearningModule.fromJson(_map(m,'module'))).toList();
    var count = 0;
    for (final m in parsed) {
      for (final u in m.units) {
        final pool = u.isVocabulary ? vocabularyPool(u) : lessonPool(u,m);
        if (pool.isEmpty) throw FormatException('${u.id} : aucun exercice disponible.');
        count += pool.length;
        if (count > 30000) throw const FormatException('Programme trop volumineux : maximum 30 000 variantes.');
      }
    }
    return Curriculum._(doc, parsed);
  }

  /// Import one lesson without having to rewrite the rest of the programme.
  Curriculum withLesson(String source) {
    dynamic decoded;
    try { decoded = jsonDecode(source); } catch (_) { throw const FormatException('JSON invalide.'); }
    final patch = _map(decoded, 'leçon');
    if (patch['format'] != 'kotoba.lesson' || patch['version'] != 1) throw const FormatException('Format attendu : kotoba.lesson, version 1.');
    final next = object(jsonDecode(encode()));
    final modules = objects(next['modules']);
    final index = modules.indexWhere((m) => m['id'] == patch['moduleId']);
    if (index < 0) throw const FormatException('Le module de destination n’existe pas.');
    final lesson = _map(patch['lesson'], 'lesson');
    final lessons = objects(modules[index]['lessons']);
    final li = lessons.indexWhere((u) => u['id'] == lesson['id']);
    if (li < 0) { lessons.add(lesson); } else { lessons[li] = lesson; }
    modules[index]['lessons'] = lessons; next['modules'] = modules;
    return Curriculum.parse(jsonEncode(next));
  }
}
Json _map(dynamic value,String path) { if (value is! Map<String,dynamic>) throw FormatException('$path : objet JSON attendu.'); return value; }
String _text(dynamic value,String path) { if (value is! String || value.trim().isEmpty || value.length > 12000) throw FormatException('$path : texte non vide attendu (12 000 caractères maximum).'); return value; }
List<dynamic> _list(dynamic value,String path,int min,int max) { if (value is! List || value.length < min || value.length > max) throw FormatException('$path : liste de $min à $max éléments attendue.'); return value; }
List<dynamic> _optionalList(dynamic value,String path) => value == null ? [] : _list(value,path,0,1000);
void _strings(dynamic value,String path,{int minimum=0}) { if (value == null && minimum == 0) return; for (final item in _list(value,path,minimum,1000)) { _text(item,path); } }
String canonical(dynamic value) => jsonEncode(_ordered(value));
dynamic _ordered(dynamic value) { if (value is Map) { final keys=value.keys.cast<String>().toList()..sort(); return {for(final k in keys) k:_ordered(value[k])}; } if(value is List) return value.map(_ordered).toList(); return value; }
