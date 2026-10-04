// Optional integration check: requires Playwright and Chromium in the environment.
import {createRequire} from 'node:module';
const {chromium}=createRequire(import.meta.url)('playwright');
import assert from 'node:assert/strict';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {modules} from '../src/content.js';
import {lessonPool,vocabularyPool} from '../src/engine.js';
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
async function answerCurrent(bank){
 const id=await page.locator('.question').getAttribute('data-question-id');const q=bank.find(q=>q.id===id);assert.ok(q,id);
 if(q.type==='choice')await page.locator('.choices').getByRole('button',{name:q.answer,exact:true}).click();
 else if(q.type==='order'){for(let i=0;i<q.tokens.length;i++)await page.locator(`[data-action="token:${i}"]`).click();}
 else await page.locator('#answer').fill(q.answer);
 await page.locator('#answer-form button[type="submit"]').click();
}
for(let i=0;i<8;i++){await answerCurrent(vocabularyPool(modules[0].mcos[0]));await page.locator('#feedback button').click();}
assert.match(await page.locator('h1').innerText(),/100 %/);
assert.ok(await page.evaluate(()=>JSON.parse(localStorage.getItem('kotoba.progress.v1')).completed.includes('m1-life')));
await page.goto(base+'/#review');await page.getByRole('button',{name:'Réviser maintenant'}).click();await page.getByRole('button',{name:'Retourner la carte'}).click();await page.getByRole('button',{name:'Bien',exact:true}).click();
assert.equal(await page.evaluate(()=>Object.keys(JSON.parse(localStorage.getItem('kotoba.progress.v1')).cards).length),1);
// Seed completed units to verify the entire DS independently of lesson repetition.
const seeded=freshState();seeded.completed=required(modules[0]);
await page.evaluate(s=>localStorage.setItem('kotoba.progress.v1',JSON.stringify(s)),seeded);await page.reload();await page.goto(base+'/#module/m1');await page.getByRole('button',{name:'Passer le DS'}).click();
while(await page.locator('#answer').count()){
 const qs=[...modules[0].lessons.flatMap(l=>lessonPool(l,modules[0])),...modules[0].mcos.flatMap(vocabularyPool)];
 await answerCurrent(qs);assert.equal(await page.locator('#feedback .feedback').count(),0);
}
assert.match(await page.locator('h1').innerText(),/100 %/);
await page.goto(base+'/#module/m2');assert.match(await page.locator('h1').innerText(),/Arabiasūji/);
await page.reload();assert.match(await page.locator('h1').innerText(),/Arabiasūji/);
await page.evaluate(async()=>{await navigator.serviceWorker.ready;});await page.reload();await context.setOffline(true);await page.reload();assert.match(await page.locator('h1').innerText(),/Arabiasūji/);
await page.goto(base+'/#mco/m2/m2-nature');assert.equal(await page.locator('.word-list article').count(),5);await context.setOffline(false);
// Exercise newer grammar with all three interactions, including ordering tiles.
const advanced=freshState();for(const m of modules.slice(0,5)){advanced.exams[m.id]={score:100,at:Date.now()};advanced.completed.push(...required(m));}
await page.evaluate(s=>localStorage.setItem('kotoba.progress.v1',JSON.stringify(s)),advanced);await page.reload();await page.goto(base+'/#lesson/m6/adjectives');await page.getByRole('button',{name:'Commencer les exercices'}).click();
await page.screenshot({path:join(tmpdir(),'kotoba-exercise.png'),fullPage:true});
const grammarBank=lessonPool(modules[5].lessons[0],modules[5]);const types=new Set();
while(await page.locator('#answer').count()){const id=await page.locator('.question').getAttribute('data-question-id');types.add(grammarBank.find(q=>q.id===id).type);await answerCurrent(grammarBank);await page.locator('#feedback button').click();}
assert.ok(types.has('choice')&&types.has('order'));assert.match(await page.locator('h1').innerText(),/100 %/);
await page.setViewportSize({width:1440,height:1000});await page.goto(base+'/#home');await page.screenshot({path:join(tmpdir(),'kotoba-desktop.png'),fullPage:true});
assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));
assert.deepEqual(errors,[]);console.log('Browser checks passed: mobile layout, MCO, SRS, DS, unlocking, persistence, offline, desktop.');
await browser.close();
