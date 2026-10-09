const fs=require('fs'),path=require('path');const {chromium}=require('playwright');const {serve,EXEC,ROOT}=require('./lib');
function arg(n,d){const i=process.argv.indexOf('--'+n);return i>-1?process.argv[i+1]:d;}
const scene=arg('scene','chat'),dur=parseFloat(arg('dur','15')),fps=parseInt(arg('fps','30'),10),outDir=arg('out','frames/'+scene);
(async()=>{
 fs.mkdirSync(path.join(ROOT,outDir),{recursive:true});
 const server=await serve();const port=server.address().port;
 const b=await chromium.launch({executablePath:EXEC,args:['--no-sandbox','--disable-setuid-sandbox','--force-color-profile=srgb']});
 const p=await b.newPage({viewport:{width:1080,height:1920},deviceScaleFactor:1});
 p.on('pageerror',e=>console.error('PAGEERR:',e.message));
 await p.goto(`http://127.0.0.1:${port}/frame.html?scene=${scene}&dur=${dur}`,{waitUntil:'networkidle'});
 await p.waitForFunction('window.__ready===true',{timeout:30000});
 await p.evaluate(async()=>{await document.fonts.ready;});
 await p.waitForTimeout(400);
 const total=Math.round(dur*fps);const FROM=parseInt(arg('from','0'),10);const TO=parseInt(arg('to',String(total)),10);const stage=await p.$('#stage');
 for(let f=FROM;f<=TO;f++){const t=f/fps;await p.evaluate(tt=>window.__setT(tt),t);await p.evaluate(()=>new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r))));await stage.screenshot({path:path.join(ROOT,outDir,String(f).padStart(5,'0')+'.png')});if(f%30===0)process.stdout.write(`\r${scene}: ${f}/${total}`);}
 process.stdout.write(`\r${scene}: ${total} frames done\n`);
 await b.close();server.close();
})();
