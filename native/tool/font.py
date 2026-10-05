"""Check bundled Japanese glyphs; --rebuild regenerates the licensed subset."""
from pathlib import Path
import hashlib
import sys
import urllib.request
from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parents[1]
FONT = ROOT / 'assets/fonts/KotobaJapanese.ttf'
SOURCE = ('https://raw.githubusercontent.com/google/fonts/'
          '295d98a7a0c17c68f1341eaeea354e7960ea70d3/'
          'ofl/notosansjp/NotoSansJP%5Bwght%5D.ttf')
SOURCE_SHA256 = 'c2f3b4d463500a2ddcd3849cded1fceeb9fd6d1c32e6cbecd568453ba50fc68f'

def characters():
    paths = [ROOT / 'assets/curriculum.json', ROOT / 'assets/builtin_history.json']
    paths += list((ROOT / 'lib').rglob('*.dart'))
    chars = set(''.join(p.read_text(encoding='utf-8') for p in paths))
    chars.update(chr(i) for i in range(0x3000, 0x3100))
    chars.update(chr(i) for i in range(0x20, 0x100))
    return chars

def verify():
    cmap = TTFont(FONT).getBestCmap()
    required = {c for c in characters() if 0x4e00 <= ord(c) <= 0x9fff
                or 0x3041 <= ord(c) <= 0x3096 or 0x30a1 <= ord(c) <= 0x30fa}
    missing = sorted(c for c in required if ord(c) not in cmap)
    if missing:
        raise SystemExit('Missing Japanese glyphs: ' + ''.join(missing))
    print(f'Japanese font: {len(required)} required glyphs, none missing.')

def rebuild():
    from io import BytesIO
    from fontTools import subset
    from fontTools.varLib.instancer import instantiateVariableFont
    data = urllib.request.urlopen(SOURCE, timeout=60).read()
    if hashlib.sha256(data).hexdigest() != SOURCE_SHA256:
        raise SystemExit('Unexpected upstream font; refusing to rebuild.')
    font = instantiateVariableFont(TTFont(BytesIO(data)), {'wght': 400}, inplace=True)
    options = subset.Options()
    options.layout_features = ['*']
    options.name_IDs = ['*']
    options.name_legacy = True
    options.name_languages = ['*']
    selector = subset.Subsetter(options=options)
    selector.populate(unicodes=[ord(c) for c in characters()])
    selector.subset(font)
    font.save(FONT)

if __name__ == '__main__':
    if '--rebuild' in sys.argv:
        rebuild()
    verify()
