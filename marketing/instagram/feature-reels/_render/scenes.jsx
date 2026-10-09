// scenes.jsx — standalone reels built on the Seek demo engine.
// Uses globals from animations.jsx (Easing, animate, interpolate, clamp, Sprite,
// TimelineContext) and video-components.jsx / seek-screens.jsx
// (G, Fx, Ico, PhoneFrame, ChatScreenAnimated, SeekMark).

// ─────────────────────────────────────────────────────────────────────────────
// REEL 1 — Chat answer (polished app-demo). Type a feeling → AI streams in
// intro, verses, prayer, AND the worship-song card (the differentiator).
// ─────────────────────────────────────────────────────────────────────────────
function ChatReel() {
  const { localTime, duration } = useSprite();

  const phoneOpacity = animate({ from: 0, to: 1, start: 0, end: 0.6, ease: Easing.easeOutCubic })(localTime);
  const phoneScale   = animate({ from: 0.94, to: 1, start: 0, end: 0.8, ease: Easing.easeOutCubic })(localTime);

  const userBubbleOp = animate({ from: 0, to: 1, start: 0.5, end: 1.0, ease: Easing.easeOutCubic })(localTime);
  const userText = "I'm anxious about a job interview tomorrow.";
  const typeProgress = animate({ from: 0, to: 1, start: 1.0, end: 3.0, ease: Easing.linear })(localTime);
  const userVisibleText = userText.slice(0, Math.floor(typeProgress * userText.length));

  const introBubbleOp = animate({ from: 0, to: 1, start: 3.6, end: 4.2, ease: Easing.easeOutCubic })(localTime);
  const introY        = animate({ from: 16, to: 0, start: 3.6, end: 4.4, ease: Easing.easeOutCubic })(localTime);

  const verse1Op = animate({ from: 0, to: 1, start: 5.0, end: 5.7, ease: Easing.easeOutCubic })(localTime);
  const verse1Y  = animate({ from: 24, to: 0, start: 5.0, end: 5.7, ease: Easing.easeOutCubic })(localTime);

  const verse2Op = animate({ from: 0, to: 1, start: 6.3, end: 7.0, ease: Easing.easeOutCubic })(localTime);
  const verse2Y  = animate({ from: 24, to: 0, start: 6.3, end: 7.0, ease: Easing.easeOutCubic })(localTime);

  const prayerOp = animate({ from: 0, to: 1, start: 7.9, end: 8.6, ease: Easing.easeOutCubic })(localTime);
  const prayerY  = animate({ from: 24, to: 0, start: 7.9, end: 8.6, ease: Easing.easeOutCubic })(localTime);

  const songOp = animate({ from: 0, to: 1, start: 9.3, end: 10.0, ease: Easing.easeOutCubic })(localTime);
  const songY  = animate({ from: 24, to: 0, start: 9.3, end: 10.0, ease: Easing.easeOutCubic })(localTime);

  // No scroll — the response cards stack and stay in frame the whole time.
  const chatScroll = 0;

  // Camera holds steady so the full stack is always visible.
  const camScale = interpolate([0, 4.5, 9, duration], [0.97, 0.99, 1.0, 1.0], Easing.easeInOutCubic)(localTime);
  const camY     = interpolate([0, 4.5, 9, duration], [-30, -34, -42, -42], Easing.easeInOutCubic)(localTime);

  const captionOp = interpolate([0.2, 1.0, 3.4, 3.9], [0, 1, 1, 0], Easing.easeInOutCubic)(localTime);
  const closingCaptionOp = interpolate(
    [duration - 3.0, duration - 2.3, duration - 0.5, duration],
    [0, 1, 1, 0], Easing.easeInOutCubic
  )(localTime);
  const exitOp = animate({ from: 1, to: 0, start: duration - 0.4, end: duration, ease: Easing.easeInCubic })(localTime);

  return (
    <div style={{ position: 'absolute', inset: 0, background: '#F4F1E9', opacity: exitOp }}>
      <div style={{ position: 'absolute', top: 96, left: 0, right: 0, textAlign: 'center', opacity: captionOp }}>
        <div style={{ fontFamily: '-apple-system, sans-serif', fontSize: 30, fontWeight: 600, letterSpacing: '0.18em', textTransform: 'uppercase', color: '#5B7B5E' }}>
          When something&rsquo;s on your heart
        </div>
      </div>

      <div style={{
        position: 'absolute', left: '50%', top: '50%',
        transform: `translate(-50%, calc(-50% + ${camY}px)) scale(${camScale * phoneScale})`,
        opacity: phoneOpacity, transformOrigin: 'center top',
      }}>
        <PhoneFrame x={-360} y={-740} width={720} height={1480}>
          <BigChatScreen
            userText={userVisibleText}
            userBubbleOp={userBubbleOp}
            introOp={introBubbleOp} introY={introY}
            v1Op={verse1Op} v1Y={verse1Y}
            v2Op={verse2Op} v2Y={verse2Y}
            prayerOp={prayerOp} prayerY={prayerY}
            songOp={songOp} songY={songY}
            time={localTime}
            scrollY={chatScroll}
          />
        </PhoneFrame>
      </div>

      <div style={{ position: 'absolute', bottom: 150, left: 60, right: 60, textAlign: 'center', opacity: closingCaptionOp }}>
        <div style={{ fontFamily: 'Georgia, serif', fontSize: 40, fontWeight: 400, fontStyle: 'italic', color: '#1A1A1A', lineHeight: 1.4 }}>
          Scripture, a prayer, and a song &mdash; found for you.
        </div>
      </div>
    </div>
  );
}

// Enlarged chat screen — bigger type, padding, cards and section spacing for
// legibility. Same animation props as ChatScreenAnimated.
function BigChatScreen({ userText, userBubbleOp, introOp, introY, v1Op, v1Y, v2Op, v2Y, prayerOp, prayerY, songOp = 0, songY = 0, time, scrollY = 0 }) {
  const typingDotsOp = (time > 3.0 && time < 3.7) ? 1 : 0;
  const dot1 = Math.sin((time - 3.0) * 8) * 0.5 + 0.5;
  const dot2 = Math.sin((time - 3.0) * 8 - 1) * 0.5 + 0.5;
  const dot3 = Math.sin((time - 3.0) * 8 - 2) * 0.5 + 0.5;
  const cardShadow = '0 4px 16px rgba(0,0,0,0.06)';
  return (
    <div style={{ width: '100%', height: '100%', background: G.bg, position: 'relative', fontFamily: Fx.ui, overflow: 'hidden' }}>
      <StatusBar />
      <div style={{ padding: '6px 32px 16px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', position: 'relative', zIndex: 5, background: G.bg }}>
        <Ico name="plus" size={32} color={G.sage} stroke={2.4} />
        <div style={{ fontSize: 27, fontWeight: 600, color: G.fg1 }}>Chat</div>
        <Ico name="user" size={32} color={G.sage} />
      </div>

      <div style={{ position: 'absolute', top: 150, left: 0, right: 0, bottom: 0, overflow: 'hidden' }}>
        <div style={{ padding: '0 28px', display: 'flex', flexDirection: 'column', gap: 22, transform: `translateY(${scrollY}px)` }}>
          {/* user bubble */}
          <div style={{ alignSelf: 'flex-end', maxWidth: '86%', opacity: userBubbleOp }}>
            <div style={{ background: G.sage, color: '#fff', borderRadius: 26, padding: '20px 28px', fontSize: 29, lineHeight: 1.4, minHeight: 34 }}>
              {userText}<span style={{ opacity: userText.length < 44 ? 0.6 : 0 }}>|</span>
            </div>
          </div>

          {/* typing dots */}
          <div style={{ alignSelf: 'flex-start', opacity: typingDotsOp }}>
            <div style={{ background: G.surfaceAlt, borderRadius: 26, padding: '18px 24px', display: 'flex', gap: 8, alignItems: 'center' }}>
              <span style={{ width: 11, height: 11, borderRadius: 999, background: G.sage, opacity: dot1 }} />
              <span style={{ width: 11, height: 11, borderRadius: 999, background: G.sage, opacity: dot2 }} />
              <span style={{ width: 11, height: 11, borderRadius: 999, background: G.sage, opacity: dot3 }} />
            </div>
          </div>

          {/* AI intro */}
          <div style={{ alignSelf: 'flex-start', maxWidth: '92%', opacity: introOp, transform: `translateY(${introY}px)` }}>
            <div style={{ background: G.surfaceAlt, color: G.fg1, borderRadius: 26, padding: '20px 28px', fontSize: 29, lineHeight: 1.45 }}>
              God meets us in the waiting. Here's scripture for the courage you carry.
            </div>
          </div>

          {/* verse 1 */}
          <div style={{ background: G.surface, borderRadius: 22, padding: 28, boxShadow: cardShadow, opacity: v1Op, transform: `translateY(${v1Y}px)` }}>
            <div style={{ fontSize: 18, fontWeight: 700, color: G.sage, letterSpacing: 1.2, textTransform: 'uppercase' }}>Verse</div>
            <div style={{ fontFamily: Fx.s, fontSize: 31, lineHeight: 1.45, color: G.fg1, marginTop: 14 }}>
              "Do not be anxious about anything, but in every situation, by prayer and petition, present your requests to God."
            </div>
            <div style={{ fontSize: 22, fontWeight: 700, color: G.sage, marginTop: 14 }}>— Philippians 4:6</div>
          </div>

          {/* verse 2 */}
          <div style={{ background: G.surface, borderRadius: 22, padding: 28, boxShadow: cardShadow, opacity: v2Op, transform: `translateY(${v2Y}px)` }}>
            <div style={{ fontSize: 18, fontWeight: 700, color: G.sage, letterSpacing: 1.2, textTransform: 'uppercase' }}>Verse</div>
            <div style={{ fontFamily: Fx.s, fontSize: 31, lineHeight: 1.45, color: G.fg1, marginTop: 14 }}>
              "I can do all things through Christ who strengthens me."
            </div>
            <div style={{ fontSize: 22, fontWeight: 700, color: G.sage, marginTop: 14 }}>— Philippians 4:13</div>
          </div>

          {/* prayer */}
          <div style={{ background: G.goldWash2, borderRadius: 22, padding: 24, opacity: prayerOp, transform: `translateY(${prayerY}px)` }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <Ico name="sparkles" size={20} color={G.gold} stroke={2} />
              <div style={{ fontSize: 17, fontWeight: 700, color: G.gold, letterSpacing: 1.2, textTransform: 'uppercase' }}>Prayer</div>
            </div>
            <div style={{ fontFamily: Fx.s, fontStyle: 'italic', fontSize: 26, lineHeight: 1.5, color: G.fg1, marginTop: 12 }}>
              Lord, quiet my racing thoughts. Replace my fear with the steady knowing that you go before me. Amen.
            </div>
          </div>

          {/* worship song */}
          <div style={{ background: G.sageWash2, borderRadius: 22, padding: 22, opacity: songOp, transform: `translateY(${songY}px)`, display: 'flex', alignItems: 'center', gap: 18 }}>
            <div style={{ width: 76, height: 76, borderRadius: 16, background: 'linear-gradient(135deg, #5B7B5E, #8AAF8D)', display: 'grid', placeItems: 'center', flexShrink: 0 }}>
              <Ico name="music" size={34} color="#fff" stroke={2} />
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 16, fontWeight: 700, color: G.sage, letterSpacing: 1.2, textTransform: 'uppercase' }}>Worship song</div>
              <div style={{ fontSize: 25, fontWeight: 600, color: G.fg1, marginTop: 4, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                Oceans (Where Feet May Fail)
              </div>
              <div style={{ fontSize: 19, color: G.fg2, marginTop: 2 }}>Hillsong United</div>
            </div>
            <div style={{ display: 'flex', gap: 10, flexShrink: 0 }}>
              <div style={{ width: 48, height: 48, borderRadius: 999, background: G.appleMusic, display: 'grid', placeItems: 'center' }}>
                <Ico name="play" size={20} color="#fff" stroke={0} />
              </div>
              <div style={{ width: 48, height: 48, borderRadius: 999, background: G.spotify, display: 'grid', placeItems: 'center' }}>
                <Ico name="play" size={20} color="#fff" stroke={0} />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// REEL 2 — Card-creator flip (punchy). One verse, all 19 templates, snapping by.
// ─────────────────────────────────────────────────────────────────────────────
// Each template carries its own verse so the reel swaps scripture as it flips.
// `ref` = reference text colour; `vtext`/`vref` = the verse + its citation.
const TEMPLATES = [
  // Nature (5)
  { name: 'Ocean',    cat: 'Nature',     grad: ['#1A3A5C','#5B7B5E','#8AAF8D'], text: '#FFFFFF', ref: 'rgba(255,255,255,0.82)', vtext: '“Be still, and know that I am God.”', vref: 'Psalm 46:10' },
  { name: 'Sunrise',  cat: 'Nature',     grad: ['#1A1A2E','#CDA349','#F5C882'], text: '#FFFFFF', ref: 'rgba(255,255,255,0.82)', vtext: '“His mercies are new every morning.”', vref: 'Lamentations 3:23' },
  { name: 'Forest',   cat: 'Nature',     grad: ['#1A2E0A','#2D5016','#4A7A28'], text: '#FFFFFF', ref: 'rgba(255,255,255,0.82)', vtext: '“The Lord is my shepherd; I have all that I need.”', vref: 'Psalm 23:1' },
  { name: 'Mountain', cat: 'Nature',     grad: ['#1F2937','#3B4856','#6B7280'], text: '#FFFFFF', ref: 'rgba(255,255,255,0.82)', vtext: '“I lift up my eyes to the hills.”', vref: 'Psalm 121:1' },
  { name: 'Sky',      cat: 'Nature',     grad: ['#2563EB','#5B9BD5','#93C5FD'], text: '#FFFFFF', ref: 'rgba(255,255,255,0.82)', vtext: '“The heavens declare the glory of God.”', vref: 'Psalm 19:1' },
  // Minimal (5)
  { name: 'Cream',    cat: 'Minimal',    solid: '#FAF7F0', text: '#1A1A1A', ref: '#5B7B5E', vtext: '“Love is patient, love is kind.”', vref: '1 Corinthians 13:4' },
  { name: 'Navy',     cat: 'Minimal',    solid: '#1A2744', text: '#FFFFFF', ref: 'rgba(255,255,255,0.82)', vtext: '“Cast all your anxiety on him, because he cares for you.”', vref: '1 Peter 5:7' },
  { name: 'Sage',     cat: 'Minimal',    solid: '#D4DDD2', text: '#2D3A2D', ref: '#4A6741', vtext: '“Be strong and courageous.”', vref: 'Joshua 1:9' },
  { name: 'Blush',    cat: 'Minimal',    solid: '#F5E6E0', text: '#5C3D3D', ref: '#8B5E5E', vtext: '“I have loved you with an everlasting love.”', vref: 'Jeremiah 31:3' },
  { name: 'Charcoal', cat: 'Minimal',    solid: '#2D2D2D', text: '#FFFFFF', ref: 'rgba(255,255,255,0.82)', vtext: '“The Lord is my light and my salvation.”', vref: 'Psalm 27:1' },
  // Watercolor (4)
  { name: 'Lavender', cat: 'Watercolor', solid: '#E8D5F5', text: '#3D2A52', ref: '#6B4D8A', vtext: '“She is clothed with strength and dignity.”', vref: 'Proverbs 31:25' },
  { name: 'Peach',    cat: 'Watercolor', solid: '#FDDCBD', text: '#5C3A1A', ref: '#8B6840', vtext: '“This is the day the Lord has made.”', vref: 'Psalm 118:24' },
  { name: 'Seafoam',  cat: 'Watercolor', solid: '#C5E8E0', text: '#1A3D35', ref: '#2C5F52', vtext: '“Peace I leave with you; my peace I give you.”', vref: 'John 14:27' },
  { name: 'Rose',     cat: 'Watercolor', solid: '#F5C6D0', text: '#5C1A2A', ref: '#8B3D52', vtext: '“Let all that you do be done in love.”', vref: '1 Corinthians 16:14' },
  // Bold (4)
  { name: 'Midnight', cat: 'Bold',       solid: '#000000', text: '#FFFFFF', ref: '#CDA349', vtext: '“I can do all things through Christ who strengthens me.”', vref: 'Philippians 4:13' },
  { name: 'Royal',    cat: 'Bold',       grad: ['#1E0A3C','#4A1A7A'], text: '#FFFFFF', ref: '#CDA349', vtext: '“The Lord your God is with you, the Mighty Warrior who saves.”', vref: 'Zephaniah 3:17' },
  { name: 'Fire',     cat: 'Bold',       grad: ['#8B0000','#CDA349'], text: '#FFFFFF', ref: 'rgba(255,255,255,0.82)', vtext: '“The joy of the Lord is your strength.”', vref: 'Nehemiah 8:10' },
  { name: 'Gold',     cat: 'Bold',       grad: ['#1A1A1A','#3D3520'], text: '#FFFFFF', ref: '#CDA349', vtext: '“Give thanks to the Lord, for he is good.”', vref: 'Psalm 107:1' },
];

// Auto-size the verse like the app's VerseCardView (tiers off character count).
function flipFontSize(len) {
  if (len < 80) return 104;
  if (len < 150) return 88;
  if (len < 250) return 72;
  return 58;
}

// A single 9:16 verse card face — mirrors VerseCardView (topLeading→bottomTrailing
// gradient, centered Georgia verse, reference, tinted Seek wordmark).
function CardFace({ tpl, w }) {
  const h = w * (16 / 9);
  const s = w / 1080; // scale off the canonical 1080-wide render
  const bg = tpl.grad
    ? `linear-gradient(135deg, ${tpl.grad.join(', ')})`
    : tpl.solid;
  const fs = flipFontSize((tpl.vtext || '').length);
  return (
    <div style={{
      width: w, height: h, borderRadius: 28 * s, overflow: 'hidden',
      background: bg, position: 'relative',
      boxShadow: '0 30px 90px rgba(0,0,0,0.32), 0 8px 24px rgba(0,0,0,0.16)',
      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
    }}>
      <div style={{
        fontFamily: 'Georgia, serif', fontStyle: 'normal', fontSize: fs * s, lineHeight: 1.36,
        color: tpl.text, textAlign: 'center', padding: `0 ${100 * s}px`, letterSpacing: '-0.005em',
      }}>
        {tpl.vtext}
      </div>
      <div style={{
        marginTop: 40 * s, fontFamily: Fx.ui, fontSize: 44 * s, fontWeight: 600, color: tpl.ref,
      }}>
        &mdash; {tpl.vref}
      </div>
      {/* tinted Seek wordmark watermark */}
      <div style={{
        position: 'absolute', bottom: 60 * s, left: 0, right: 0, textAlign: 'center',
        fontFamily: '"Iowan Old Style", Georgia, serif', fontSize: 60 * s, color: tpl.text, opacity: 0.45,
        letterSpacing: '-0.01em',
      }}>
        Seek<span style={{
          display: 'inline-block', width: 7 * s, height: 7 * s, borderRadius: '50%',
          background: '#CDA349', marginLeft: 5 * s, verticalAlign: 'top', marginTop: 10 * s,
        }} />
      </div>
    </div>
  );
}

function CardFlipReel() {
  const { localTime, duration } = useSprite();

  const CARD_W = 600;
  const introEnd = 1.4;
  const perCard = 0.92;            // total time each template is on screen
  const transDur = 0.52;           // slower crossfade between cards
  const beats = TEMPLATES.length - 1;             // Ocean shows in the intro; cycle does the rest
  const settleStart = introEnd + perCard * beats;

  const captionOp = interpolate([0.2, 1.0, settleStart - 0.3, settleStart + 0.2], [0, 1, 1, 0], Easing.easeInOutCubic)(localTime);

  const introScale = animate({ from: 0.9, to: 1, start: 0, end: 0.6, ease: Easing.easeOutBack })(localTime);
  const introOp    = animate({ from: 0, to: 1, start: 0, end: 0.5, ease: Easing.easeOutCubic })(localTime);
  const nextSettleScale = localTime >= settleStart
    ? interpolate([settleStart, settleStart + 0.5], [1, 1.04], Easing.easeOutBack)(localTime)
    : 1;

  // Build the 1–2 cards on screen this frame. During a transition the outgoing
  // card slides out + fades while the incoming card slides in + fades (crossfade).
  let cards, pillIdx;
  if (localTime < introEnd) {
    cards = [{ key: 0, tpl: TEMPLATES[0], x: 0, op: introOp, scale: introScale }];
    pillIdx = 0;
  } else if (localTime >= settleStart) {
    cards = [{ key: 0, tpl: TEMPLATES[0], x: 0, op: 1, scale: nextSettleScale }];
    pillIdx = 0;
  } else {
    const tt = localTime - introEnd;
    const beat = Math.floor(tt / perCard);        // 0..beats-1
    const idxNew = beat + 1;                       // 1..beats  (Sunrise → Gold)
    const idxPrev = beat;                          // 0..beats-1 (Ocean first)
    const frac = tt - beat * perCard;
    if (frac < transDur) {
      const p = Easing.easeInOutCubic(clamp(frac / transDur, 0, 1));
      cards = [
        { key: 'p' + idxPrev, tpl: TEMPLATES[idxPrev], x: -70 * p,       op: 1 - p,         scale: 1 - 0.05 * p },
        { key: 'n' + idxNew,  tpl: TEMPLATES[idxNew],  x: 70 * (1 - p),  op: p,             scale: 0.95 + 0.05 * p },
      ];
      pillIdx = p < 0.5 ? idxPrev : idxNew;
    } else {
      cards = [{ key: idxNew, tpl: TEMPLATES[idxNew], x: 0, op: 1, scale: 1 }];
      pillIdx = idxNew;
    }
  }

  const closingOp = interpolate([settleStart + 0.3, settleStart + 1.0, duration - 0.4, duration], [0, 1, 1, 0], Easing.easeInOutCubic)(localTime);
  const exitOp = animate({ from: 1, to: 0, start: duration - 0.4, end: duration, ease: Easing.easeInCubic })(localTime);

  const pillName = TEMPLATES[pillIdx].name;
  const pillCat = TEMPLATES[pillIdx].cat;

  return (
    <div style={{ position: 'absolute', inset: 0, background: '#F4F1E9', opacity: exitOp, overflow: 'hidden' }}>
      {/* soft brand wash backdrop */}
      <div style={{ position: 'absolute', inset: 0,
        background: 'radial-gradient(120% 80% at 50% 18%, rgba(205,163,73,0.10), transparent 60%), radial-gradient(120% 80% at 50% 100%, rgba(91,123,94,0.10), transparent 55%)' }} />

      {/* top caption */}
      <div style={{ position: 'absolute', top: 110, left: 0, right: 0, textAlign: 'center', opacity: captionOp }}>
        <div style={{ fontFamily: '-apple-system, sans-serif', fontSize: 30, fontWeight: 600, letterSpacing: '0.18em', textTransform: 'uppercase', color: '#5B7B5E' }}>
          A verse for every moment
        </div>
      </div>

      {/* card(s) — crossfade between outgoing and incoming */}
      {cards.map((c) => (
        <div key={c.key} style={{
          position: 'absolute', left: '50%', top: '48%',
          transform: `translate(calc(-50% + ${c.x}px), -50%) scale(${c.scale})`,
          opacity: c.op,
          willChange: 'transform, opacity',
        }}>
          <CardFace tpl={c.tpl} w={CARD_W} />
        </div>
      ))}

      {/* template-name pill */}
      <div style={{ position: 'absolute', bottom: 250, left: 0, right: 0, textAlign: 'center', opacity: captionOp }}>
        <span style={{
          display: 'inline-flex', alignItems: 'center', gap: 12,
          padding: '14px 28px', borderRadius: 999, background: '#FFFFFF',
          boxShadow: '0 6px 20px rgba(0,0,0,0.08)',
          fontFamily: Fx.ui, fontSize: 26, fontWeight: 600, color: '#1A1A1A',
        }}>
          {pillName}
          <span style={{ fontSize: 20, fontWeight: 600, color: '#9CA3AF', letterSpacing: '0.06em', textTransform: 'uppercase' }}>{pillCat}</span>
        </span>
      </div>

      {/* closing caption */}
      <div style={{ position: 'absolute', bottom: 180, left: 60, right: 60, textAlign: 'center', opacity: closingOp }}>
        <div style={{ fontFamily: 'Georgia, serif', fontSize: 44, fontWeight: 400, fontStyle: 'italic', color: '#1A1A1A', lineHeight: 1.4 }}>
          Make any verse yours.
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// REEL 3 — Daily verse + streak (the habit loop). Enlarged Home screen with a
// streak that ticks up, and the daily verse card.
// ─────────────────────────────────────────────────────────────────────────────
function StreakReel() {
  const { localTime, duration } = useSprite();

  const phoneY = animate({ from: 70, to: 0, start: 0, end: 0.8, ease: Easing.easeOutCubic })(localTime);
  const phoneOp = animate({ from: 0, to: 1, start: 0, end: 0.6, ease: Easing.easeOutCubic })(localTime);
  const camScale = interpolate([0, 1.0, 6, duration], [0.97, 0.99, 1.0, 1.0], Easing.easeInOutCubic)(localTime);
  const camY     = interpolate([0, 1.0, 6, duration], [-20, -26, -34, -34], Easing.easeInOutCubic)(localTime);

  // streak ticks 11 -> 12 with a pop
  const streakNum = localTime < 3.0 ? 11 : 12;
  const popT = clamp((localTime - 3.0) / 0.5, 0, 1);
  const flameScale = localTime < 3.0 ? 1 : 1 + Easing.easeOutBack(popT) * 0.35 * (1 - popT) + 0.0;
  const ringOp = interpolate([3.0, 3.1, 3.9], [0, 0.5, 0], Easing.easeOutCubic)(localTime);
  const ringScale = interpolate([3.0, 3.9], [0.7, 1.8], Easing.easeOutCubic)(localTime);

  // verse card highlight
  const verseGlow = interpolate([4.6, 5.3, 7.6, 8.2], [0, 1, 1, 0], Easing.easeInOutCubic)(localTime);

  // toast
  const toastOp = interpolate([3.2, 3.8, 6.2, 6.8], [0, 1, 1, 0], Easing.easeInOutCubic)(localTime);
  const toastY  = interpolate([3.2, 3.8], [-30, 0], Easing.easeOutCubic)(localTime);

  const captionOp = interpolate([0.3, 1.1, 3.0, 3.5], [0, 1, 1, 0], Easing.easeInOutCubic)(localTime);
  const closingOp = interpolate([duration - 3.0, duration - 2.3, duration - 0.5, duration], [0, 1, 1, 0], Easing.easeInOutCubic)(localTime);
  const exitOp = animate({ from: 1, to: 0, start: duration - 0.4, end: duration, ease: Easing.easeInCubic })(localTime);

  return (
    <div style={{ position: 'absolute', inset: 0, background: '#F4F1E9', opacity: exitOp }}>
      <div style={{ position: 'absolute', top: 96, left: 0, right: 0, textAlign: 'center', opacity: captionOp }}>
        <div style={{ fontFamily: '-apple-system, sans-serif', fontSize: 30, fontWeight: 600, letterSpacing: '0.18em', textTransform: 'uppercase', color: '#5B7B5E' }}>
          Start every morning
        </div>
      </div>

      <div style={{
        position: 'absolute', left: '50%', top: '50%',
        transform: `translate(-50%, calc(-50% + ${camY}px + ${phoneY}px)) scale(${camScale})`,
        opacity: phoneOp, transformOrigin: 'center top',
      }}>
        <PhoneFrame x={-360} y={-740} width={720} height={1480}>
          <div style={{ width: '100%', height: '100%', background: G.bg, position: 'relative', fontFamily: Fx.ui, overflow: 'hidden' }}>
            <StatusBar />
            <div style={{ padding: '14px 34px 0' }}>
              {/* greeting + streak */}
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <div>
                  <div style={{ fontSize: 24, color: G.fg2 }}>Good morning,</div>
                  <div style={{ fontSize: 46, fontWeight: 700, color: G.fg1, letterSpacing: -0.5, marginTop: 4 }}>Sarah</div>
                </div>
                <div style={{ position: 'relative' }}>
                  {/* burst ring */}
                  <div style={{ position: 'absolute', inset: -10, borderRadius: 999, border: `4px solid ${G.gold}`, opacity: ringOp, transform: `scale(${ringScale})` }} />
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '14px 22px', borderRadius: 999, background: G.goldWash }}>
                    <span style={{ display: 'inline-flex', transform: `scale(${flameScale})` }}><Ico name="flame" size={28} color={G.gold} /></span>
                    <span style={{ fontSize: 28, fontWeight: 700, color: G.gold }}>{streakNum}</span>
                  </div>
                </div>
              </div>

              <div style={{ marginTop: 38, fontSize: 40, fontWeight: 700, color: G.fg1, letterSpacing: -0.4 }}>What's on your heart?</div>

              {/* daily verse card */}
              <div style={{
                marginTop: 28, background: G.surface, borderRadius: 22, padding: '34px 32px',
                boxShadow: verseGlow > 0 ? `0 8px 30px rgba(205,163,73,${0.10 + 0.18 * verseGlow})` : '0 4px 16px rgba(0,0,0,0.07)',
                borderLeft: `6px solid ${G.gold}`,
              }}>
                <div style={{ fontSize: 19, fontWeight: 700, color: G.gold, letterSpacing: 1.4, textTransform: 'uppercase' }}>Daily verse</div>
                <div style={{ fontFamily: Fx.s, fontSize: 36, lineHeight: 1.45, color: G.fg1, marginTop: 18 }}>
                  "Be still, and know that I am God."
                </div>
                <div style={{ fontSize: 24, fontWeight: 700, color: G.sage, marginTop: 18 }}>— Psalm 46:10</div>
              </div>

              {/* prompt chips, enlarged */}
              <div style={{ marginTop: 26, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
                {[['sun','Joy'],['heart','Gratitude'],['walk','Struggle'],['sparkles','Seeking'],['leaf','Peace'],['flame','Hope']].map(([ic, lb]) => (
                  <div key={lb} style={{ background: G.surface, borderRadius: 16, padding: '20px 20px', display: 'flex', alignItems: 'center', gap: 14, boxShadow: '0 1px 4px rgba(0,0,0,0.04)' }}>
                    <div style={{ width: 42, height: 42, borderRadius: 999, background: G.sageWash, display: 'grid', placeItems: 'center' }}>
                      <Ico name={ic} size={22} color={G.sage} />
                    </div>
                    <div style={{ fontSize: 24, fontWeight: 500, color: G.fg1 }}>{lb}</div>
                  </div>
                ))}
              </div>

              {/* free-text entry */}
              <div style={{ marginTop: 20, background: G.surfaceAlt, borderRadius: 24, padding: '22px 26px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <span style={{ fontSize: 24, color: G.fg3 }}>Or type your own…</span>
                <div style={{ width: 48, height: 48, borderRadius: 999, background: G.sage, display: 'grid', placeItems: 'center' }}>
                  <Ico name="arrowUp" size={26} color="#fff" />
                </div>
              </div>
            </div>

            {/* streak toast — celebratory banner in the lower area */}
            <div style={{ position: 'absolute', top: 1170, left: 0, right: 0, display: 'flex', justifyContent: 'center', opacity: toastOp, transform: `translateY(${toastY}px)` }}>
              <div style={{ display: 'inline-flex', alignItems: 'center', gap: 14, padding: '20px 32px', borderRadius: 999, background: '#FFFFFF', boxShadow: '0 12px 36px rgba(0,0,0,0.14)' }}>
                <Ico name="flame" size={30} color={G.gold} />
                <span style={{ fontSize: 28, fontWeight: 700, color: G.fg1 }}>12-day streak — keep it going</span>
              </div>
            </div>
          </div>
        </PhoneFrame>
      </div>

      <div style={{ position: 'absolute', bottom: 150, left: 60, right: 60, textAlign: 'center', opacity: closingOp }}>
        <div style={{ fontFamily: 'Georgia, serif', fontSize: 40, fontWeight: 400, fontStyle: 'italic', color: '#1A1A1A', lineHeight: 1.4 }}>
          One true thing, before the noise.
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// REEL 4 — Worship-song spotlight. Scripture pairs with a song; cycle a few.
// ─────────────────────────────────────────────────────────────────────────────
// Each verse pairs with a song that answers it; the reel cycles verse + song together.
const PAIRS = [
  { verse: '“When you pass through the waters, I will be with you.”', vref: 'Isaiah 43:2',
    song: { title: 'Oceans (Where Feet May Fail)', artist: 'Hillsong United', g: ['#1A3A5C','#5B7B5E'] } },
  { verse: '“Surely your goodness and unfailing love will follow me all the days of my life.”', vref: 'Psalm 23:6',
    song: { title: 'Goodness of God', artist: 'Bethel Music', g: ['#6B4D8A','#CDA349'] } },
  { verse: '“Unless the Lord builds the house, the builders labor in vain.”', vref: 'Psalm 127:1',
    song: { title: 'Build My Life', artist: 'Pat Barrett', g: ['#2C5F52','#8AAF8D'] } },
  { verse: '“Give thanks in all circumstances.”', vref: '1 Thessalonians 5:18',
    song: { title: 'Gratitude', artist: 'Brandon Lake', g: ['#8B5E5E','#CDA349'] } },
];

function SongCard({ song, w, time }) {
  const s = w / 760;
  // equalizer bars on the album art
  const bars = [0, 1, 2, 3].map((i) => 0.35 + 0.65 * (Math.sin(time * 6 + i * 1.3) * 0.5 + 0.5));
  return (
    <div style={{
      width: w, borderRadius: 28 * s, padding: 30 * s, background: G.sageWash2,
      boxShadow: '0 24px 70px rgba(0,0,0,0.16)', display: 'flex', alignItems: 'center', gap: 26 * s,
      border: '1px solid rgba(91,123,94,0.12)',
    }}>
      <div style={{ width: 150 * s, height: 150 * s, borderRadius: 22 * s, background: `linear-gradient(135deg, ${song.g.join(', ')})`, display: 'flex', alignItems: 'flex-end', justifyContent: 'center', gap: 8 * s, padding: 22 * s, flexShrink: 0 }}>
        {bars.map((b, i) => (
          <div key={i} style={{ width: 12 * s, height: `${b * 70}%`, background: 'rgba(255,255,255,0.9)', borderRadius: 6 * s }} />
        ))}
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 22 * s, fontWeight: 700, color: G.sage, letterSpacing: 1.4 * s, textTransform: 'uppercase' }}>Worship song</div>
        <div style={{ fontSize: 38 * s, fontWeight: 600, color: G.fg1, marginTop: 8 * s, lineHeight: 1.15 }}>{song.title}</div>
        <div style={{ fontSize: 28 * s, color: G.fg2, marginTop: 6 * s }}>{song.artist}</div>
        <div style={{ display: 'flex', gap: 14 * s, marginTop: 20 * s }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 * s, padding: `${12 * s}px ${20 * s}px`, borderRadius: 999, background: G.appleMusic }}>
            <Ico name="play" size={22 * s} color="#fff" stroke={0} /><span style={{ color: '#fff', fontSize: 22 * s, fontWeight: 600 }}>Apple Music</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 * s, padding: `${12 * s}px ${20 * s}px`, borderRadius: 999, background: G.spotify }}>
            <Ico name="play" size={22 * s} color="#fff" stroke={0} /><span style={{ color: '#fff', fontSize: 22 * s, fontWeight: 600 }}>Spotify</span>
          </div>
        </div>
      </div>
    </div>
  );
}

function WorshipReel() {
  const { localTime, duration } = useSprite();
  const CARD_W = 820;
  const introEnd = 2.6;
  const perPair = 2.9;             // longer hold — there's a verse + a song to read
  const transDur = 0.6;
  const beats = PAIRS.length - 1;
  const settleStart = introEnd + perPair * beats;

  const captionOp = interpolate([0.3, 1.1, settleStart + 0.6, settleStart + 1.2], [0, 1, 1, 0], Easing.easeInOutCubic)(localTime);

  const introScale = animate({ from: 0.92, to: 1, start: 0.5, end: 1.4, ease: Easing.easeOutBack })(localTime);
  const introOp    = animate({ from: 0, to: 1, start: 0.4, end: 1.2, ease: Easing.easeOutCubic })(localTime);

  // Build the active verse+song pair(s). During a transition both pairs
  // crossfade together (verse and song move as one unit).
  let cards;
  if (localTime < introEnd) {
    cards = [{ key: 0, pair: PAIRS[0], x: 0, op: introOp, scale: introScale }];
  } else if (localTime >= settleStart) {
    cards = [{ key: beats, pair: PAIRS[beats], x: 0, op: 1, scale: 1 }];
  } else {
    const tt = localTime - introEnd;
    const beat = Math.floor(tt / perPair);
    const idxNew = beat + 1, idxPrev = beat;
    const frac = tt - beat * perPair;
    if (frac < transDur) {
      const p = Easing.easeInOutCubic(clamp(frac / transDur, 0, 1));
      cards = [
        { key: 'p' + idxPrev, pair: PAIRS[idxPrev], x: -55 * p,      op: 1 - p,        scale: 1 - 0.04 * p },
        { key: 'n' + idxNew,  pair: PAIRS[idxNew],  x: 55 * (1 - p), op: p,            scale: 0.96 + 0.04 * p },
      ];
    } else {
      cards = [{ key: idxNew, pair: PAIRS[idxNew], x: 0, op: 1, scale: 1 }];
    }
  }

  const closingOp = interpolate([settleStart + 0.6, settleStart + 1.3, duration - 0.4, duration], [0, 1, 1, 0], Easing.easeInOutCubic)(localTime);
  const exitOp = animate({ from: 1, to: 0, start: duration - 0.4, end: duration, ease: Easing.easeInCubic })(localTime);

  return (
    <div style={{ position: 'absolute', inset: 0, background: '#F4F1E9', opacity: exitOp, overflow: 'hidden' }}>
      <div style={{ position: 'absolute', inset: 0, background: 'radial-gradient(120% 70% at 50% 16%, rgba(205,163,73,0.10), transparent 60%), radial-gradient(120% 80% at 50% 100%, rgba(91,123,94,0.12), transparent 55%)' }} />

      <div style={{ position: 'absolute', top: 120, left: 0, right: 0, textAlign: 'center', opacity: captionOp }}>
        <div style={{ fontFamily: '-apple-system, sans-serif', fontSize: 30, fontWeight: 600, letterSpacing: '0.18em', textTransform: 'uppercase', color: '#5B7B5E' }}>
          A verse, and a song to carry it
        </div>
      </div>

      {/* "paired with" connector (static) */}
      <div style={{ position: 'absolute', top: 800, left: 0, right: 0, textAlign: 'center', opacity: captionOp }}>
        <span style={{ fontFamily: Fx.ui, fontSize: 24, fontWeight: 600, letterSpacing: '0.12em', textTransform: 'uppercase', color: '#9CA3AF' }}>paired with</span>
      </div>

      {/* verse + song, crossfading together per pair */}
      {cards.map((c) => (
        <React.Fragment key={c.key}>
          <div style={{ position: 'absolute', top: 400, left: 80, right: 80, textAlign: 'center', opacity: c.op, transform: `translateX(${c.x}px)`, willChange: 'transform, opacity' }}>
            <div style={{ fontFamily: 'Georgia, serif', fontSize: 52, fontStyle: 'italic', color: '#1A1A1A', lineHeight: 1.4 }}>
              {c.pair.verse}
            </div>
            <div style={{ fontFamily: Fx.ui, fontSize: 32, fontWeight: 700, color: '#5B7B5E', marginTop: 20 }}>— {c.pair.vref}</div>
          </div>
          <div style={{ position: 'absolute', left: '50%', top: '62%', transform: `translate(calc(-50% + ${c.x}px), -50%) scale(${c.scale})`, opacity: c.op, willChange: 'transform, opacity' }}>
            <SongCard song={c.pair.song} w={CARD_W} time={localTime} />
          </div>
        </React.Fragment>
      ))}

      <div style={{ position: 'absolute', bottom: 150, left: 60, right: 60, textAlign: 'center', opacity: closingOp }}>
        <div style={{ fontFamily: 'Georgia, serif', fontSize: 40, fontStyle: 'italic', color: '#1A1A1A', lineHeight: 1.4 }}>
          A verse for your moment &mdash; and a song to carry it.
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { ChatReel, BigChatScreen, CardFlipReel, TEMPLATES, CardFace, StreakReel, WorshipReel, PAIRS, SongCard });
