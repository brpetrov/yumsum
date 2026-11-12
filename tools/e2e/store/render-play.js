// Rebuild the store posters from the supplied captures, without redrawing UI.
// Run from any directory: node tools/e2e/store/render-play.js [slide numbers]
const fs = require('fs');
const path = require('path');
const { pathToFileURL } = require('url');
const { chromium } = require('playwright');
const { renderFeatureGraphic } = require('../feature_shot');

const dir = __dirname;
const root = path.resolve(dir, '../../..');
const url = (name) => pathToFileURL(path.join(dir, name)).href;
// Data URLs keep local canvas pixel reads available for the camera chrome mask.
const png = (name) => `data:image/png;base64,${fs.readFileSync(path.join(dir, name)).toString('base64')}`;
const cameraFeed = () => `data:image/webp;base64,${fs.readFileSync(path.join(root, 'tools/hosting/recipes/chicken-curry.webp')).toString('base64')}`;
const asset = (name) => pathToFileURL(path.join(root, 'assets', name)).href;
const escape = (value) => value.replaceAll('&', '&amp;').replaceAll('<', '&lt;');

const slides = [
  {
    title: ['Log meals', 'in <em>seconds</em>'],
    subtitle: 'Type it, say it, snap it or scan it',
    badge: 'No ads',
    file: 'phone-home-light-matched.png', crop: [0, 30, 430, 850],
    neutralName: [80, 49, 57, 31, 26, 82, 76],
    frameWidth: 662, frameHeight: 1284,
    tilt: -3, food: true,
    detail: { file: 'en-2-quick-log.png', crop: [27, 1395, 1010, 315], x: 47, y: 1100, width: 986, tilt: 2 },
    voice: true,
  },
  {
    title: ['AI counts the', 'calories, <em>free</em>'],
    subtitle: '10 free estimates a day. No ads.',
    badge: '10 a day, free',
    file: 'phone-ai-estimate.png', crop: [0, 302, 510, 796],
    tilt: 3, food: true,
    hero: { file: 'phone-ai-estimate.png', crop: [32, 748, 460, 140], x: 47, y: 1010, width: 986, tilt: -2 },
    detail: { file: 'phone-choice.png', crop: [34, 754, 463, 139], x: 104, y: 1322, width: 872, tilt: 1.5 },
    note: 'Not sure? Tap a portion or an extra.',
  },
  {
    title: ['Snap a <em>photo,</em>', 'get the calories'],
    // These two seven-word headlines are explicitly requested in the revision.
    exactHeadline: true,
    subtitle: 'Point, tap, done',
    badge: 'YumSum Star',
    file: 'en-7-camera-chicken-curry.png', crop: [0, 0, 1080, 1919],
    preview: 'smart-snap-curry.png', tilt: -3,
    frameWidth: 710, frameHeight: 1260,
    ingredients: true,
    note: '550 kcal · 30 g protein',
  },
  {
    title: ['Your day,', 'at a <em>glance</em>'],
    subtitle: 'Calories, protein, carbs, fat and more',
    badge: 'YumSum Star',
    file: 'phone-home-light-matched.png', crop: [0, 30, 430, 850],
    neutralName: [80, 49, 57, 31, 26, 82, 76],
    split: { file: 'phone-home-dark-matched.png', crop: [0, 30, 430, 850] },
    splitCurve: true,
    frameWidth: 630, frameHeight: 1220, frameTop: 600,
    modeLabels: true,
    note: 'Plus your personal AI Coach review',
    noteChip: true,
    tilt: 0, food: true,
  },
  {
    title: ['Scan. Pick', 'your <em>portion.</em>'],
    subtitle: 'A serving or the whole pack',
    badge: 'Free',
    file: 'phone-scanner-camera.png', crop: [0, 30, 358, 680],
    preview: 'scan-peanut-butter.png', previewKind: 'scanner',
    frameWidth: 690, frameHeight: 1290,
    tilt: -3, food: true,
    // Focus the real serving controls and result. The branded product header
    // is completely outside this crop, so neither its name nor photo appears.
    detail: { file: 'phone-scan.png', crop: [32, 585, 466, 283], x: 150, y: 1380, width: 780, tilt: 2 },
  },
  {
    title: ['High-<em>protein</em>', 'recipes'],
    subtitle: 'Log a portion in one tap',
    badge: 'Free',
    file: 'en-4-recipes.png', crop: [0, 160, 1080, 1759],
    food: true, tilt: 3,
  },
  {
    title: ['Smart formula', '<em>adapts</em> to you'],
    subtitle: 'Learns as you weigh in',
    badge: 'YumSum Star',
    file: 'phone-progress-dark.png', crop: [0, 132, 503, 818],
    dark: true, tilt: -3,
  },
  {
    title: ['See your <em>month</em>', 'at a glance'],
    exactHeadline: true,
    subtitle: 'Every on-track day, in green',
    badge: 'Free to use. No ads.',
    file: 'phone-history-stats-dark.png', crop: [0, 175, 501, 895],
    dark: true, tilt: 3, frameTop: 586,
    // Enlarge the complete calendar; the same capture's 68% / 31-of-31
    // stats remain visible below it in the phone. No dates or values are redrawn.
    detail: { file: 'phone-history-stats-dark.png', crop: [24, 175, 465, 449], x: 90, y: 580, width: 900, tilt: -1.5, dark: true },
  },
];

function capture(spec, className = '', style = '') {
  return `<canvas class="capture ${className}" data-file="${png(spec.file)}" data-crop='${JSON.stringify(spec.crop)}' data-blur='${JSON.stringify(spec.blur || [])}' data-neutral-name='${JSON.stringify(spec.neutralName || null)}' ${spec.preview ? `data-preview="${png(spec.preview)}" data-preview-kind="${spec.previewKind || 'meal'}" ${spec.previewKind === 'scanner' ? '' : `data-feed="${cameraFeed()}"`}` : ''} style="${style}"></canvas>`;
}

function detailCard(spec, className = '', content = '') {
  return `<div class="detail ${className} ${spec.dark ? 'dark-detail' : ''}" style="left:${spec.x}px;top:${spec.y}px;width:${spec.width}px;transform:rotate(${spec.tilt || 0}deg)">${capture(spec)}${content}</div>`;
}

function markup(slide, index) {
  const detail = slide.detail;
  const ingredientConnections = 'M158 1020 L235 1020 L430 1035 M972 930 L850 930 L710 1025 M128 1222 L238 1222 L331 1135';
  const ingredientMarkers = [[430,1035],[710,1025],[331,1135]];
  return `<!doctype html><html lang="en"><head><meta charset="utf-8"><style>
    @font-face { font-family: Fredoka; src: url('${asset('fonts/Fredoka-SemiBold.ttf')}'); font-weight: 600; }
    @font-face { font-family: Nunito; src: url('${asset('fonts/Nunito-SemiBold.ttf')}'); font-weight: 600; }
    @font-face { font-family: Nunito; src: url('${asset('fonts/Nunito-Bold.ttf')}'); font-weight: 700; }
    * { box-sizing: border-box; }
    html, body { margin: 0; width: 1080px; height: 1920px; overflow: hidden; }
    body { position: relative; color: #2B1F18; background: #FAF2E7; font-family: Nunito; font-weight: 600; }
    .wash { position: absolute; inset: 500px -360px -250px; border-radius: 50%; background: radial-gradient(ellipse, #F6D6BD 0%, #FAF2E700 66%); }
    .food { position: absolute; inset: 550px 0 0; background: linear-gradient(#FAF2E7 0%, #FAF2E700 30%), url('${url('recipe-backdrop.png')}') center bottom / 1150px auto; opacity: .76; filter: blur(2px); transform: scaleX(${index % 2 ? -1 : 1}); }
    header { position: absolute; left: 78px; top: 103px; right: 60px; z-index: 3; }
    h1 { margin: 0; font: 600 112px/1.08 Fredoka; letter-spacing: -1.8px; }
    h1 span { display: block; }
    h1 em { color: #C94D1A; font-style: normal; }
    .subtitle { margin: 27px 0 0; font-size: ${index === 3 ? 43 : 48}px; line-height: 1.25; color: #76665A; letter-spacing: -.55px; white-space: nowrap; }
    .badge { display: inline-block; margin-top: 28px; padding: 16px 31px 18px; border-radius: 99px; background: #C94D1A; color: white; font-size: 38px; line-height: 1.1; font-weight: 700; }
    .brand { position: absolute; width: 90px; height: 90px; right: 70px; top: 65px; border-radius: 24px; }
    .phone { position: absolute; top: ${slide.frameTop || 556}px; left: ${(1080-(slide.frameWidth || 784))/2}px; width: ${slide.frameWidth || 784}px; height: ${slide.frameHeight || 1260}px; padding: 12px; border-radius: 79px; background: #2B211B; box-shadow: 0 42px 70px #4F2D1938, inset 0 0 0 2px #665044; transform: rotate(${slide.tilt || 0}deg); }
    .screen { position: relative; width: 100%; height: 100%; border-radius: 67px; overflow: hidden; background: ${slide.dark ? '#191510' : '#FAF2E7'}; }
    .capture { display: block; width: 100%; height: 100%; object-fit: cover; object-position: center bottom; }
    .split-side { position: absolute; inset: 0; }
    .split-side.light { clip-path: ${slide.splitCurve ? 'none' : 'inset(0 50% 0 0)'}; }
    .split-side.dark { clip-path: ${slide.splitCurve ? 'url(#curved-dark)' : 'inset(0 0 0 50%)'}; }
    .split-divider { display: ${slide.splitCurve ? 'none' : 'block'}; position: absolute; left: calc(50% - 2.5px); width: 5px; top: 0; bottom: 0; background: #FAF2E7; box-shadow: -1px 0 0 #76665A88, 1px 0 0 #FAF2E788; }
    .split-curve { position:absolute; inset:0; width:100%; height:100%; pointer-events:none; }
    .mode-labels { position: absolute; left: 225px; top: 550px; width: 630px; display: flex; font: 700 29px Nunito; color: #2B1F18; }
    .mode-labels span { width: 50%; display: flex; justify-content: center; align-items: center; gap: 12px; }
    .mode-labels span + span { border-left: 1px solid #DCC8B6; }
    .mode-labels svg { width: 27px; height: 27px; flex: none; fill: none; stroke: currentColor; stroke-width: 1.8; stroke-linecap: round; stroke-linejoin: round; }
    .detail { position: absolute; padding: 12px; border-radius: 40px; background: #FFFBF5; box-shadow: 0 24px 56px #4D2C1938, 0 0 0 1px #E6CBB4; z-index: 4; }
    .detail .capture { height: auto; border-radius: 29px; }
    .dark-detail { background: #261F1A; box-shadow: 0 24px 56px #1B140F55, 0 0 0 1px #5B4939; }
    .sparkle { position: absolute; right: -15px; bottom: 0; width: 188px; height: 188px; border-radius: 50%; box-shadow: 0 14px 30px #8A3F2444; }
    .sparkle .capture { border-radius: 50%; height: 100%; }
    .arrow { position: absolute; z-index: 5; right: 40px; top: 943px; width: 135px; height: 200px; transform: rotate(-4deg); }
    .voice { position: absolute; left: 65px; top: 1476px; width: 480px; padding: 22px 22px 17px; border-radius: 38px; background: #FFFBF5; box-shadow: 0 20px 42px #4D2C1938; z-index: 5; transform: rotate(3deg); }
    .voice .caption { color: #76665A; font-size: 32px; margin-bottom: 15px; }
    .voice .capture { height: auto; border-radius: 16px; }
    .bottom { position: absolute; left: 78px; bottom: 28px; color: #76665A; font-size: 34px; }
    .bottom.note-chip { left: 50%; bottom: 19px; transform: translateX(-50%); padding: 13px 25px; border: 1px solid #DCC8B6; border-radius: 99px; background: #FAF2E7; color: #2B1F18; font-weight: 700; font-size: 32px; line-height: 1.2; white-space: nowrap; box-shadow: 0 6px 18px #4F2D191A; }
    .ingredient { position: absolute; z-index: 4; padding: 9px 12px; background: #FAF2E7; color: #2B1F18; font: 700 32px/1.15 Nunito; }
    .ingredient.chicken { left: 18px; top: 990px; }
    .ingredient.rice { right: 22px; top: 900px; }
    .ingredient.sauce { left: 18px; top: 1178px; }
    .ingredient-lines { position: absolute; inset: 0; width: 1080px; height: 1920px; z-index: 3; pointer-events: none; }
    .sequence { position: absolute; right: 78px; bottom: 34px; display: flex; gap: 9px; }
    .dot { height: 7px; width: 7px; border-radius: 50%; background: #DDCDBC; }
    .dot.active { width: 24px; border-radius: 6px; background: #C94D1A; }
  </style></head><body>
    <div class="wash"></div>${slide.food ? '<div class="food"></div>' : ''}
    ${index === 0 ? `<img class="brand" src="${asset('android/play_store_512.png')}" alt="YumSum">` : ''}
    <header><h1><span>${slide.title[0]}</span><span>${slide.title[1]}</span></h1><p class="subtitle">${escape(slide.subtitle)}</p><div class="badge">${escape(slide.badge)}</div></header>
    ${slide.modeLabels ? '<div class="mode-labels"><span><svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="4"/><path d="M12 2V4 M12 20V22 M2 12H4 M20 12H22 M5 5L6.5 6.5 M17.5 17.5L19 19 M5 19L6.5 17.5 M17.5 6.5L19 5"/></svg>Light mode</span><span><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M20.5 14.5A9 9 0 0 1 9.5 3.5 9 9 0 1 0 20.5 14.5Z"/></svg>Dark mode</span></div>' : ''}
    <div class="phone"><div class="screen">${slide.split ? `<div class="split-side light">${capture(slide)}</div><div class="split-side dark">${capture(slide.split)}</div><div class="split-divider"></div>${slide.splitCurve ? '<svg width="0" height="0" aria-hidden="true"><defs><clipPath id="curved-dark" clipPathUnits="objectBoundingBox"><path d="M .64 0 C .64 .28 .28 .38 .38 .64 C .46 .84 .64 .88 .57 1 L 1 1 L 1 0 Z"/></clipPath></defs></svg><svg class="split-curve" viewBox="0 0 606 1196" preserveAspectRatio="none" aria-hidden="true"><path d="M387.84 0 C387.84 334.88 169.68 454.48 230.28 765.44 C278.76 1004.64 387.84 1052.48 345.42 1196" fill="none" stroke="#2B1F18" stroke-opacity=".18" stroke-width="8"/><path d="M387.84 0 C387.84 334.88 169.68 454.48 230.28 765.44 C278.76 1004.64 387.84 1052.48 345.42 1196" fill="none" stroke="#FAF2E7" stroke-width="5"/></svg>' : ''}` : capture(slide)}</div></div>
    ${slide.hero ? detailCard(slide.hero, 'hero') : ''}
    ${detail ? detailCard(detail, '', slide.voice ? `<div class="sparkle">${capture({file:'en-2-quick-log.png', crop:[917,1559,116,116]})}</div>` : '') : ''}
    ${index === 0 ? '<svg class="arrow" viewBox="0 0 135 200"><path d="M25 7 C100 30 111 100 67 174 M52 147 L65 177 L94 163" fill="none" stroke="#C94D1A" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/></svg>' : ''}
    ${slide.voice ? `<div class="voice"><div class="caption">Snap it. Scan it. Say it.</div>${capture({file:'en-1-home.png', crop:[650,1736,385,140]})}</div>` : ''}
    ${slide.ingredients ? `<svg class="ingredient-lines" viewBox="0 0 1080 1920" aria-hidden="true"><g fill="none" stroke-linecap="round" stroke-linejoin="round"><path d="${ingredientConnections}" stroke="#FAF2E7" stroke-width="9"/><path d="${ingredientConnections}" stroke="#176D4A" stroke-width="4.5"/></g><g fill="#FAF2E7" stroke="#FAF2E7" stroke-width="9">${ingredientMarkers.map(([cx,cy])=>`<circle cx="${cx}" cy="${cy}" r="9"/>`).join('')}</g><g fill="#FAF2E7" stroke="#176D4A" stroke-width="4.5">${ingredientMarkers.map(([cx,cy])=>`<circle cx="${cx}" cy="${cy}" r="9"/>`).join('')}</g></svg><span class="ingredient chicken">Chicken</span><span class="ingredient rice">Rice</span><span class="ingredient sauce">Curry<br>sauce</span>` : ''}
    ${slide.note ? `<div class="bottom ${slide.noteChip ? 'note-chip' : ''}">${escape(slide.note)}</div>` : ''}
    <div class="sequence">${slides.map((_, i) => `<i class="dot ${i === index ? 'active' : ''}"></i>`).join('')}</div>
    <script>
      window.ready = (async () => {
        await document.fonts.ready;
        await Promise.all([...document.images].map(img => img.decode()));
        await Promise.all([...document.querySelectorAll('canvas')].map(async canvas => {
          const img = new Image(); img.src = canvas.dataset.file; await img.decode();
          const [x, y, w, h] = JSON.parse(canvas.dataset.crop);
          if (x < 0 || y < 0 || x+w > img.naturalWidth || y+h > img.naturalHeight) throw Error('Crop outside capture: ' + img.src);
          canvas.width = w; canvas.height = h;
          const ctx = canvas.getContext('2d');
          let source = img;
          let sourceScale = 1;
          if (canvas.dataset.preview && canvas.dataset.previewKind !== 'scanner') {
            // Preserve captured camera chrome. Only the preview is replaced;
            // the website-only chooser is below the final 1740px crop.
            const preview = new Image(); preview.src = canvas.dataset.preview; await preview.decode();
            const camera = document.createElement('canvas');
            camera.width = img.naturalWidth; camera.height = img.naturalHeight;
            const cameraCtx = camera.getContext('2d');
            const scale = Math.max(camera.width / preview.width, camera.height / preview.height);
            cameraCtx.drawImage(preview, (camera.width-preview.width*scale)/2, (camera.height-preview.height*scale)/2, preview.width*scale, preview.height*scale);
            // Decorative framing brackets, above the captured guidance card.
            cameraCtx.strokeStyle = 'white'; cameraCtx.lineWidth = 4; cameraCtx.lineCap = 'round';
            cameraCtx.beginPath();
            for (const [bx,by,dx,dy] of [[96,170,1,1],[984,170,-1,1],[96,1190,1,-1],[984,1190,-1,-1]]) {
              cameraCtx.moveTo(bx+90*dx,by); cameraCtx.lineTo(bx,by); cameraCtx.lineTo(bx,by+90*dy);
            }
            cameraCtx.stroke();
            // Recover the translucent card's lettering from the actual capture,
            // against the known original camera feed from photo_screens.js.
            // This replaces the preview underneath the card too, without typing
            // any replacement text or leaving old rice texture over the table.
            const feed = new Image(); feed.src=canvas.dataset.feed; await feed.decode();
            const feedFrame=document.createElement('canvas'); feedFrame.width=720; feedFrame.height=1280;
            const feedCtx=feedFrame.getContext('2d');
            feedCtx.translate(360,640); feedCtx.rotate(Math.PI/2);
            const feedScale=Math.max(1280/feed.width,720/feed.height);
            feedCtx.drawImage(feed,-feed.width*feedScale/2,-feed.height*feedScale/2,feed.width*feedScale,feed.height*feedScale);
            const jpeg=new Image(); jpeg.src=feedFrame.toDataURL('image/jpeg',.92); await jpeg.decode();
            const oldPreview=document.createElement('canvas'); oldPreview.width=camera.width; oldPreview.height=camera.height;
            const oldCtx=oldPreview.getContext('2d');
            const captured=document.createElement('canvas'); captured.width=camera.width; captured.height=camera.height;
            const capturedCtx=captured.getContext('2d'); capturedCtx.drawImage(img,0,0);
            const actualTop=capturedCtx.getImageData(200,200,500,800).data;
            // The supplied web camera capture mirrors and crops the portrait
            // feed by 16:9. Check that transform against unobstructed pixels.
            const feedZoom=16/9;
            oldCtx.save(); oldCtx.translate(540,959.5); oldCtx.scale(-1,1);
            oldCtx.drawImage(jpeg,-540*feedZoom,-960*feedZoom,1080*feedZoom,1920*feedZoom); oldCtx.restore();
            const referenceTop=oldCtx.getImageData(200,200,500,800).data;
            let feedError=0,feedSamples=0;
            for(let p=0;p<actualTop.length;p+=1600) {
              for(let c=0;c<3;c++) feedError+=Math.abs(actualTop[p+c]-referenceTop[p+c]);
              feedSamples+=3;
            }
            window.cameraFeedError=feedError/feedSamples;
            if(window.cameraFeedError>10) throw Error('Original camera preview no longer matches the capture');
            const oldPixels=oldCtx.getImageData(176,1242,728,216).data;
            const letters=capturedCtx.getImageData(176,1242,728,216);
            for(let p=0;p<letters.data.length;p+=4) {
              const alpha=[0,1,2].map(c=>(letters.data[p+c]-.4*oldPixels[p+c])/(255-.4*oldPixels[p+c])).sort((a,b)=>a-b)[1];
              letters.data[p]=255; letters.data[p+1]=255; letters.data[p+2]=255;
              letters.data[p+3]=alpha>.035 ? Math.round(Math.min(1,alpha)*255) : 0;
            }
            const letterMask=document.createElement('canvas'); letterMask.width=728; letterMask.height=216;
            letterMask.getContext('2d').putImageData(letters,0,0);
            cameraCtx.save(); cameraCtx.beginPath(); cameraCtx.roundRect(176,1242,728,216,63); cameraCtx.clip();
            cameraCtx.fillStyle='rgba(0,0,0,.6)'; cameraCtx.fillRect(176,1242,728,216);
            cameraCtx.drawImage(letterMask,176,1242); cameraCtx.restore();
            // Extract the captured white close glyph, without its old preview.
            const close = document.createElement('canvas'); close.width=60; close.height=60;
            const closeCtx = close.getContext('2d'); closeCtx.drawImage(img,55,55,60,60,0,0,60,60);
            const closePixels = closeCtx.getImageData(0,0,60,60);
            for(let p=0;p<closePixels.data.length;p+=4) {
              if(Math.min(closePixels.data[p],closePixels.data[p+1],closePixels.data[p+2])<180) closePixels.data[p+3]=0;
            }
            closeCtx.putImageData(closePixels,0,0); cameraCtx.drawImage(close,55,55);
            // The shutter's captured ring and centre, with the preview showing
            // through its gap. Radii follow the source capture's white pixels.
            cameraCtx.save(); cameraCtx.beginPath();
            cameraCtx.arc(540,1609.5,100,0,Math.PI*2);
            cameraCtx.arc(540,1609.5,89.5,0,Math.PI*2,true);
            cameraCtx.arc(540,1609.5,75.5,0,Math.PI*2);
            cameraCtx.clip('evenodd'); cameraCtx.drawImage(img,0,0); cameraCtx.restore();
            source = camera;
          }
          if(canvas.dataset.previewKind === 'scanner') {
            const preview=new Image(); preview.src=canvas.dataset.preview; await preview.decode();
            // Keep the generated preview sharp at poster size. Captured chrome
            // still uses its own pixels, scaled uniformly with the camera page.
            const scanner=document.createElement('canvas'); scanner.width=img.width*3; scanner.height=img.height*3;
            const scannerCtx=scanner.getContext('2d');
            scannerCtx.scale(3,3);
            const scale=Math.max(img.width/preview.width,img.height/preview.height);
            scannerCtx.drawImage(preview,(img.width-preview.width*scale)/2,(img.height-preview.height*scale)/2,preview.width*scale,preview.height*scale);
            // Copy only the captured rounded scan-box border over the new jar.
            scannerCtx.save(); scannerCtx.beginPath();
            scannerCtx.roundRect(56.5,325,245,141,15);
            scannerCtx.roundRect(58,326.5,242,138,13.5);
            scannerCtx.clip('evenodd'); scannerCtx.drawImage(img,0,0); scannerCtx.restore();
            // Captured close glyph, with all old camera pixels made transparent.
            const glyph=document.createElement('canvas'); glyph.width=20; glyph.height=20;
            const glyphCtx=glyph.getContext('2d'); glyphCtx.drawImage(img,18,54,20,20,0,0,20,20);
            const glyphData=glyphCtx.getImageData(0,0,20,20);
            for(let p=0;p<glyphData.data.length;p+=4) if(Math.min(glyphData.data[p],glyphData.data[p+1],glyphData.data[p+2])<175) glyphData.data[p+3]=0;
            glyphCtx.putImageData(glyphData,0,0); scannerCtx.drawImage(glyph,18,54);
            // Recover the guidance lettering from the flattened capture. A
            // small grayscale opening estimates the background under strokes;
            // the actual captured glyphs supply every letter, never retyping.
            const card=document.createElement('canvas'); card.width=304; card.height=75;
            const cardCtx=card.getContext('2d'); cardCtx.drawImage(img,27,635,304,75,0,0,304,75);
            const letters=cardCtx.getImageData(0,0,304,75);
            const grey=new Float32Array(304*75),eroded=new Float32Array(304*75),background=new Float32Array(304*75);
            for(let p=0;p<grey.length;p++) grey[p]=Math.min(letters.data[p*4],letters.data[p*4+1],letters.data[p*4+2]);
            for(let cy=0;cy<75;cy++) for(let cx=0;cx<304;cx++) {
              let value=255;
              for(let dy=-3;dy<=3;dy++) for(let dx=-3;dx<=3;dx++) value=Math.min(value,grey[Math.max(0,Math.min(74,cy+dy))*304+Math.max(0,Math.min(303,cx+dx))]);
              eroded[cy*304+cx]=value;
            }
            for(let cy=0;cy<75;cy++) for(let cx=0;cx<304;cx++) {
              let value=0;
              for(let dy=-3;dy<=3;dy++) for(let dx=-3;dx<=3;dx++) value=Math.max(value,eroded[Math.max(0,Math.min(74,cy+dy))*304+Math.max(0,Math.min(303,cx+dx))]);
              background[cy*304+cx]=value;
            }
            for(let cy=0;cy<75;cy++) for(let cx=0;cx<304;cx++) {
              const p=cy*304+cx,alpha=(grey[p]-background[p])/(255-background[p]);
              const inText=(cy>=15 && cy<=35 && cx>=67 && cx<=239)||(cy>=40 && cy<=60 && cx>=14 && cx<=290);
              letters.data[p*4]=255; letters.data[p*4+1]=255; letters.data[p*4+2]=255;
              letters.data[p*4+3]=inText && alpha>.08 ? Math.round(Math.min(1,alpha)*255) : 0;
            }
            cardCtx.putImageData(letters,0,0);
            scannerCtx.save(); scannerCtx.beginPath(); scannerCtx.roundRect(27,635,304,75,24); scannerCtx.clip();
            scannerCtx.fillStyle='rgba(0,0,0,.6)'; scannerCtx.fillRect(27,635,304,75);
            scannerCtx.drawImage(card,27,635); scannerCtx.restore();
            source=scanner;
            sourceScale=3;
          }
          canvas.width=w*sourceScale; canvas.height=h*sourceScale;
          ctx.drawImage(source, x*sourceScale, y*sourceScale, w*sourceScale, h*sourceScale, 0, 0, w*sourceScale, h*sourceScale);
          const neutralName=JSON.parse(canvas.dataset.neutralName);
          if(neutralName) {
            const [nx,ny,nw,nh,size,tx,baseline,textColour='#2B1F18']=neutralName;
            const background=ctx.getImageData(nx-x-4,ny-y+4,1,1).data;
            ctx.fillStyle='rgb('+background[0]+','+background[1]+','+background[2]+')';
            ctx.fillRect(nx-x,ny-y,nw,nh);
            ctx.fillStyle=textColour; ctx.font='600 '+size+'px Fredoka';
            ctx.fillText('Sam',tx-x,baseline-y);
          }
          for (const [bx, by, bw, bh] of JSON.parse(canvas.dataset.blur)) {
            ctx.save(); ctx.beginPath(); ctx.rect(bx-x, by-y, bw, bh); ctx.clip();
            ctx.filter = 'blur(13px)';
            ctx.drawImage(img, 0, 0, img.width, img.height, -x, -y, img.width, img.height);
            ctx.restore();
          }
        }));
      })();
    </script>
  </body></html>`;
}

async function main() {
  const selected = process.argv.slice(2).map(Number);
  const browser = await chromium.launch();
  try {
    const page = await browser.newPage({ viewport: { width: 1080, height: 1920 }, deviceScaleFactor: 1 });
    for (let i = 0; i < slides.length; i++) {
      if (selected.length && !selected.includes(i+1)) continue;
      const words = slides[i].title.join(' ').replace(/<[^>]+>/g, '').split(/\s+/).length;
      if (words > 5 && !slides[i].exactHeadline) throw Error(`Slide ${i+1}: headline exceeds five words`);
      const htmlPath = path.join(dir, '.play-render.html');
      fs.writeFileSync(htmlPath, markup(slides[i], i));
      await page.goto(pathToFileURL(htmlPath).href);
      await page.evaluate(() => window.ready);
      if (slides[i].preview && slides[i].previewKind !== 'scanner') console.log('Camera mask reference mean error:', await page.evaluate(() => window.cameraFeedError.toFixed(2)));
      if (!await page.evaluate(() => document.fonts.check('600 112px Fredoka') && document.fonts.check('600 48px Nunito'))) throw Error('Brand fonts did not load');
      const layout = await page.evaluate(() => {
        const title = document.querySelector('h1');
        const subtitle = document.querySelector('.subtitle');
        return { title: title.scrollWidth, available: title.clientWidth, subtitle: subtitle.scrollWidth };
      });
      if (layout.title > layout.available || layout.subtitle > layout.available) throw Error(`Slide ${i+1}: text overflow ${JSON.stringify(layout)}`);
      const name = `play-${i+1}.png`;
      await page.screenshot({ path: path.join(dir, name) });
      const bytes = fs.statSync(path.join(dir, name)).size;
      if (bytes >= 8 * 1024 * 1024) throw Error(`${name} exceeds 8 MB`);
      console.log(`${name}: 1080 x 1920, ${(bytes / 1024).toFixed(0)} KB`);
    }
    if (!selected.length) {
      const contact = `<html><style>*{box-sizing:border-box}html,body{margin:0;background:#FAF2E7}body{display:flex;gap:10px;padding:10px}img{width:270px;height:480px;display:block}</style><body>${slides.map((_,i)=>`<img src="${url(`play-${i+1}.png`)}">`).join('')}</body></html>`;
      const contactPath = path.join(dir, '.play-render.html');
      fs.writeFileSync(contactPath, contact);
      await page.setViewportSize({width:2250,height:500});
      await page.goto(pathToFileURL(contactPath).href);
      await page.evaluate(() => Promise.all([...document.images].map(img=>img.decode())));
      await page.screenshot({path:path.join(dir,'play-contact.png')});
      console.log('play-contact.png: 2250 x 500');
      await renderFeatureGraphic(page);
    }
    fs.unlinkSync(path.join(dir, '.play-render.html'));
  } finally {
    const temporaryPage = path.join(dir, '.play-render.html');
    if (fs.existsSync(temporaryPage)) fs.unlinkSync(temporaryPage);
    await browser.close();
  }
}
if (require.main === module) main().catch(error => { console.error(error); process.exitCode = 1; });
module.exports = { slides, markup, capture };
