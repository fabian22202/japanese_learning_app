#!/usr/bin/env python3
"""Run standalone geometry checks using a Dart SDK executable argument."""
import sys, subprocess, tempfile
from pathlib import Path
root=Path(__file__).resolve().parents[1]
s=(root/'lib/domain/handwriting.dart').read_text()
# Standalone calculation checks: no Flutter tool, device or network access.
adapter='''
class Offset {
  final double dx, dy;
  const Offset(this.dx,this.dy);
  static const zero=Offset(0,0);
  Offset operator -(Offset p)=>Offset(dx-p.dx,dy-p.dy);
  Offset operator +(Offset p)=>Offset(dx+p.dx,dy+p.dy);
  double get distance=>math.sqrt(dx*dx+dy*dy);
  static Offset? lerp(Offset a,Offset b,double t)=>Offset(a.dx+(b.dx-a.dx)*t,a.dy+(b.dy-a.dy)*t);
}
'''
s=s.replace("import 'dart:ui';", "import 'dart:convert';\nimport 'dart:io';\n"+adapter)
s+='''
void main(List<String> args) {
 int checks=0;
 void check(bool good,String name) {checks++; if(!good) throw StateError(name);}
 final m=[[const Offset(.2,.3),const Offset(.8,.3)],[const Offset(.1,.7),const Offset(.9,.7)]];
 check(evaluateWriting(m,m).score==100,'perfect');
 check(evaluateWriting(m.map((s)=>resampleStroke(s,80)).toList(),m).score==100,'density');
 check(evaluateWriting([],m).score==0,'empty');
 check(evaluateWriting([[const Offset(.2,.3)],[const Offset(.1,.7)]],m).score==0,'taps');
 final swapped=evaluateWriting(m.reversed.toList(),m);
 check(swapped.shape==100 && swapped.order==0 && swapped.direction==100,'order');
 final reversed=evaluateWriting(m.map((s)=>s.reversed.toList()).toList(),m);
 check(reversed.shape==100 && reversed.direction==0,'direction');
 check(evaluateWriting([m.first],m).score<=50,'missing');
 check(evaluateWriting([...m,m.first],m).score<80,'extra');
 final wrong=m.map((s)=>s.map((p)=>p+const Offset(0,.3)).toList()).toList();
 check(evaluateWriting(wrong,m).score<40,'displaced');
 check(evaluateWriting([[m.first.first,m.first.last,m.first.first,m.first.last],m.last],m).score<80,'scribble');
 final data=jsonDecode(File(args.first).readAsStringSync());
 for(final entry in (data['characters'] as Map<String,dynamic>).entries) {
  final strokes=(entry.value as List).map((s)=>(s as List).map((p)=>Offset((p[0] as num).toDouble(),(p[1] as num).toDouble())).toList()).toList();
  check(evaluateWriting(strokes,strokes).score==100,'perfect model '+entry.key);
 }
 print('$checks standalone geometry checks passed (Flutter tests not executed).');
}
'''
with tempfile.TemporaryDirectory() as directory:
    file=Path(directory)/'geometry_check.dart'
    file.write_text(s)
    subprocess.run([sys.argv[1],str(file),str(root/'assets/stroke_models.json')],check=True)
