"""Configure generated Flutter platform shells. Safe to run repeatedly."""
from pathlib import Path
import shutil
root = Path(__file__).resolve().parents[1]
p = root / 'android/app/src/main/AndroidManifest.xml'
if p.exists():
    s = p.read_text().replace('android:label="kotoba"', 'android:label="Kotoba"')
    query = '<intent><action android:name="android.intent.action.TTS_SERVICE" /></intent>'
    if query not in s:
        s = s.replace('<queries>', '<queries>' + query) if '<queries>' in s else s.replace('</manifest>', '<queries>' + query + '</queries></manifest>')
    p.write_text(s)
p = root / 'android/app/build.gradle.kts'
if p.exists():
    p.write_text(p.read_text().replace('minSdk = flutter.minSdkVersion', 'minSdk = 24'))
p = root / 'windows/runner/resources/app_icon.ico'
if p.parent.exists(): shutil.copyfile(root / 'assets/app_icon.ico', p)
# Android launcher resource uses the bundled full-resolution icon.
for p in (root / 'android/app/src/main/res').glob('mipmap-*/ic_launcher.png'):
    shutil.copyfile(root / 'assets/app_icon.png', p)
