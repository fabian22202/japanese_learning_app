#!/usr/bin/env python3
"""Sample ordered KanjiVG SVG strokes. Requires svgpathtools==1.8.0.
Usage: python tool/stroke_models.py KANJIVG_ARCHIVE [ADDITIONAL_CURRICULUM]
Data derived from KanjiVG (Ulrich Apel), CC BY-SA 3.0.
"""
import json, sys, pathlib, zipfile, xml.etree.ElementTree as ET, math
from svgpathtools import parse_path
ROOT=pathlib.Path(__file__).resolve().parents[1]
REV='70a0b7ae0c18ceb5cb358274b029cce0234a43bc'

def japanese(c):
    n=ord(c)
    return 0x3041 <= n <= 0x3096 or 0x30a1 <= n <= 0x30fc or 0x4e00 <= n <= 0x9fff

def run():
    z=zipfile.ZipFile(sys.argv[1]); prefix=z.namelist()[0].split('/')[0]+'/'
    requested=set()
    for file in [ROOT/'assets/curriculum.json',*map(pathlib.Path,sys.argv[2:])]:
        data=json.loads(file.read_text())
        def visit(value):
            if isinstance(value,str): requested.update(c for c in value if japanese(c))
            elif isinstance(value,dict):
                for v in value.values(): visit(v)
            elif isinstance(value,list):
                for v in value: visit(v)
        visit(data)
    # Include every supported kana, even when absent from current lessons.
    requested.update(chr(n) for n in [*range(0x3041,0x3097),*range(0x30a1,0x30fd)])
    models={}; missing=[]
    for c in sorted(requested):
        file=f'{prefix}kanji/{ord(c):05x}.svg'
        if file not in z.namelist(): missing.append(c); continue
        svg=ET.fromstring(z.read(file)); strokes=[]
        _,_,width,height=map(float,svg.attrib['viewBox'].split())
        for node in svg.iter('{http://www.w3.org/2000/svg}path'):
            if '-s' not in node.attrib.get('id',''):continue
            path=parse_path(node.attrib['d']); points=[]
            for segment in path:
                count=max(2,math.ceil(segment.length(error=1e-5)/1.2))
                points.extend(segment.point(i/count) for i in range(count))
            points.append(path[-1].end)
            strokes.append([[round(p.real/width,5),round(p.imag/height,5)] for p in points])
        if strokes:models[c]=strokes
        else:missing.append(c)
    result={'source':'https://kanjivg.tagaini.net/','revision':REV,
        'license':'CC BY-SA 3.0','characters':models}
    (ROOT/'assets/stroke_models.json').write_text(json.dumps(result,ensure_ascii=False,separators=(',',':')))
    (ROOT/'assets/stroke_models_LICENSE.txt').write_text(
        'Sampled stroke coordinates derived from KanjiVG. Copyright Ulrich Apel.\n'
        'https://kanjivg.tagaini.net/\nRevision: '+REV+'\n'
        'Modifications: ordered SVG curves sampled as normalized polylines.\n'
        'These coordinate data are licensed under CC BY-SA 3.0.\n'
        'https://creativecommons.org/licenses/by-sa/3.0/\n\n'+z.read(prefix+'COPYING').decode())
    print(json.dumps({'models':len(models),'missing':missing},ensure_ascii=False))
if __name__=='__main__':run()
