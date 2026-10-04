// Optional integration check: requires Playwright and Chromium in the environment.
import {createRequire} from 'node:module';
const {chromium}=createRequire(import.meta.url)('playwright');
import assert from 'node:assert/strict';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {modules} from '../src/content.js';
import {freshState,required,wordQuestions} from '../src/core.js';
const browser=await chromium.launch({headless:true,executablePath:process.env.KOTOBA_CHROMIUM_PATH||undefined,args:['--no-sandbox']});
const context=await browser.newContext({viewport:{width:390,height:844}});
const page=await context.newPage();const errors=[];page.on('pageerror',e=>errors.push(e.message));
const base=process.env.KOTOBA_TEST_URL||'http://127.0.0.1:8080';
await page.goto(base);await page.screenshot({path:join(tmpdir(),'kotoba-mobile.png'),fullPage:true});
assert.ok(await page.locator('h1').innerText());
await page.evaluate(()=>document.fonts.ready);
assert.ok(await page.evaluate(()=>document.fonts.check('20px KotobaJapanese','日本語')));
assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));
await page.goto(base+'/#module/m2');assert.match(await page.locator('h1').innerText(),/attend/);
await page.goto(base+'/#mco/m1/m1-life');await page.getByRole('button',{name:'Commencer les exercices'}).click();
for(let i=0;i<8;i++){
 const prompt=await page.locator('.question-prompt').innerText();const q=wordQuestions(modules[0].mcos[0]).find(q=>q.prompt===prompt);assert.ok(q);
 await page.locator('#answer').fill(q.answer);await page.locator('#answer-form button').click();await page.locator('#feedback button').click();
}
assert.match(await page.locator('h1').innerText(),/100 %/);
assert.ok(await page.evaluate(()=>JSON.parse(localStorage.getItem('kotoba.progress.v1')).completed.includes('m1-life')));
await page.goto(base+'/#review');await page.getByRole('button',{name:'Réviser maintenant'}).click();await page.getByRole('button',{name:'Retourner la carte'}).click();await page.getByRole('button',{name:'Bien',exact:true}).click();
assert.equal(await page.evaluate(()=>Object.keys(JSON.parse(localStorage.getItem('kotoba.progress.v1')).cards).length),1);
// Seed completed units to verify the entire DS independently of lesson repetition.
const seeded=freshState();seeded.completed=required(modules[0]);
await page.evaluate(s=>localStorage.setItem('kotoba.progress.v1',JSON.stringify(s)),seeded);await page.reload();await page.goto(base+'/#module/m1');await page.getByRole('button',{name:'Passer le DS'}).click();
while(await page.locator('#answer').count()){
 const prompt=await page.locator('.question-prompt').innerText();const qs=[...modules[0].lessons.flatMap(l=>l.questions),...modules[0].mcos.flatMap(wordQuestions)];const q=qs.find(q=>q.prompt===prompt);assert.ok(q);
 await page.locator('#answer').fill(q.answer);await page.locator('#answer-form button').click();assert.equal(await page.locator('#feedback .feedback').count(),0);
}
assert.match(await page.locator('h1').innerText(),/100 %/);
await page.goto(base+'/#module/m2');assert.match(await page.locator('h1').innerText(),/Arabiasūji/);
await page.reload();assert.match(await page.locator('h1').innerText(),/Arabiasūji/);
await page.evaluate(async()=>{await navigator.serviceWorker.ready;});await page.reload();await context.setOffline(true);await page.reload();assert.match(await page.locator('h1').innerText(),/Arabiasūji/);
await page.goto(base+'/#mco/m2/m2-nature');assert.equal(await page.locator('.word-list article').count(),5);await context.setOffline(false);
await page.setViewportSize({width:1440,height:1000});await page.goto(base+'/#home');await page.screenshot({path:join(tmpdir(),'kotoba-desktop.png'),fullPage:true});
assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));
assert.deepEqual(errors,[]);console.log('Browser checks passed: mobile layout, MCO, SRS, DS, unlocking, persistence, offline, desktop.');
await browser.close();
