/* ═══════════════════════════════════════════════════════════════
   MYSTERY ARTWORK  —  the only place you need to edit

   Put each image between the quotes, in the order the mysteries
   are listed above. It can be a filename ("art/annunciation.jpg"),
   a full web address, or a data: URI. Leave any entry empty and a
   placeholder shows in its place, so you can add them a few at a
   time. Images are cropped to a 4:3 frame, so landscape works best.
   ═══════════════════════════════════════════════════════════════ */
/* light = ivory marble on white; dark = the same marble on near-black.
   Composition is identical, so a theme flick only changes the light. */
const ART_V = '233';
function artUrl(p){
  if(!p) return p;
  return p + (p.indexOf('?')>=0?'&':'?') + 'v=' + ART_V;
}
const ART = {
  light: {
  joyful: [
    "art/light/joyful/mystery-01-annunciation.jpg",   // 1. The Annunciation
    "art/light/joyful/mystery-02-visitation.jpg",   // 2. The Visitation
    "art/light/joyful/mystery-03-birth-of-jesus.jpg",   // 3. The Birth of Jesus
    "art/light/joyful/mystery-04-presentation-of-the-baby-jesus.jpg",   // 4. The Presentation of the Baby Jesus
    "art/light/joyful/mystery-05-finding-of-the-child-jesus-in-the-temple.jpg"   // 5. The Finding of the Child Jesus in the Temple
  ],
  luminous: [
    "art/light/luminous/mystery-01-baptism-of-jesus-in-the-jordan.jpg",   // 1. The Baptism of Jesus in the Jordan
    "art/light/luminous/mystery-02-miracle-at-the-wedding-at-cana.jpg",   // 2. The Miracle at the Wedding at Cana
    "art/light/luminous/mystery-03-proclamation-of-the-kingdom-of-god.jpg",   // 3. The Proclamation of the Kingdom of God
    "art/light/luminous/mystery-04-transfiguration.jpg",   // 4. The Transfiguration
    "art/light/luminous/mystery-05-institution-of-the-holy-eucharist.jpg"   // 5. The Institution of the Holy Eucharist
  ],
  sorrowful: [
    "art/light/sorrowful/mystery-01-agony-in-the-garden.jpg",   // 1. The Agony in the Garden
    "art/light/sorrowful/mystery-02-scourging-at-the-pillar.jpg",   // 2. The Scourging at the Pillar
    "art/light/sorrowful/mystery-03-crowning-with-thorns.jpg",   // 3. The Crowning with Thorns
    "art/light/sorrowful/mystery-04-carrying-of-the-cross.jpg",   // 4. The Carrying of the Cross
    "art/light/sorrowful/mystery-05-crucifixion.jpg"   // 5. The Crucifixion
  ],
  glorious: [
    "art/light/glorious/mystery-01-resurrection.jpg",   // 1. The Resurrection
    "art/light/glorious/mystery-02-ascension.jpg",   // 2. The Ascension
    "art/light/glorious/mystery-03-descent-of-the-holy-spirit.jpg",   // 3. The Descent of the Holy Spirit
    "art/light/glorious/mystery-04-assumption.jpg",   // 4. The Assumption
    "art/light/glorious/mystery-05-coronation.jpg"   // 5. The Coronation
  ]
  },
  dark: {
  joyful: [
    "art/dark/joyful/mystery-01-annunciation.jpg",
    "art/dark/joyful/mystery-02-visitation.jpg",
    "art/dark/joyful/mystery-03-birth-of-jesus.jpg",
    "art/dark/joyful/mystery-04-presentation-of-the-baby-jesus.jpg",
    "art/dark/joyful/mystery-05-finding-of-the-child-jesus-in-the-temple.jpg"
  ],
  luminous: [
    "art/dark/luminous/mystery-01-baptism-of-jesus-in-the-jordan.jpg",
    "art/dark/luminous/mystery-02-miracle-at-the-wedding-at-cana.jpg",
    "art/dark/luminous/mystery-03-proclamation-of-the-kingdom-of-god.jpg",
    "art/dark/luminous/mystery-04-transfiguration.jpg",
    "art/dark/luminous/mystery-05-institution-of-the-holy-eucharist.jpg"
  ],
  sorrowful: [
    "art/dark/sorrowful/mystery-01-agony-in-the-garden.jpg",
    "art/dark/sorrowful/mystery-02-scourging-at-the-pillar.jpg",
    "art/dark/sorrowful/mystery-03-crowning-with-thorns.jpg",
    "art/dark/sorrowful/mystery-04-carrying-of-the-cross.jpg",
    "art/dark/sorrowful/mystery-05-crucifixion.jpg"
  ],
  glorious: [
    "art/dark/glorious/mystery-01-resurrection.jpg",
    "art/dark/glorious/mystery-02-ascension.jpg",
    "art/dark/glorious/mystery-03-descent-of-the-holy-spirit.jpg",
    "art/dark/glorious/mystery-04-assumption.jpg",
    "art/dark/glorious/mystery-05-coronation.jpg"
  ]
  }
};

/* Optional 16:9 for the short phone/tablet plate. Leave a slot blank and the square is used. */
const ART_WIDE = {
  light: {
  joyful: [
    "art/light/joyful/mystery-01-annunciation-wide.jpg",
    "art/light/joyful/mystery-02-visitation-wide.jpg",
    "art/light/joyful/mystery-03-birth-of-jesus-wide.jpg",
    "art/light/joyful/mystery-04-presentation-of-the-baby-jesus-wide.jpg",
    "art/light/joyful/mystery-05-finding-of-the-child-jesus-in-the-temple-wide.jpg"
  ],
  luminous: [
    "art/light/luminous/mystery-01-baptism-of-jesus-in-the-jordan-wide.jpg",
    "art/light/luminous/mystery-02-miracle-at-the-wedding-at-cana-wide.jpg",
    "art/light/luminous/mystery-03-proclamation-of-the-kingdom-of-god-wide.jpg",
    "art/light/luminous/mystery-04-transfiguration-wide.jpg",
    "art/light/luminous/mystery-05-institution-of-the-holy-eucharist-wide.jpg"
  ],
  sorrowful: [
    "art/light/sorrowful/mystery-01-agony-in-the-garden-wide.jpg",
    "art/light/sorrowful/mystery-02-scourging-at-the-pillar-wide.jpg",
    "art/light/sorrowful/mystery-03-crowning-with-thorns-wide.jpg",
    "art/light/sorrowful/mystery-04-carrying-of-the-cross-wide.jpg",
    "art/light/sorrowful/mystery-05-crucifixion-wide.jpg"
  ],
  glorious: [
    "art/light/glorious/mystery-01-resurrection-wide.jpg",
    "art/light/glorious/mystery-02-ascension-wide.jpg",
    "art/light/glorious/mystery-03-descent-of-the-holy-spirit-wide.jpg",
    "art/light/glorious/mystery-04-assumption-wide.jpg",
    "art/light/glorious/mystery-05-coronation-wide.jpg"
  ]
  },
  dark: {
  joyful: [
    "art/dark/joyful/mystery-01-annunciation-wide.jpg",
    "art/dark/joyful/mystery-02-visitation-wide.jpg",
    "art/dark/joyful/mystery-03-birth-of-jesus-wide.jpg",
    "art/dark/joyful/mystery-04-presentation-of-the-baby-jesus-wide.jpg",
    "art/dark/joyful/mystery-05-finding-of-the-child-jesus-in-the-temple-wide.jpg"
  ],
  luminous: [
    "art/dark/luminous/mystery-01-baptism-of-jesus-in-the-jordan-wide.jpg",
    "art/dark/luminous/mystery-02-miracle-at-the-wedding-at-cana-wide.jpg",
    "art/dark/luminous/mystery-03-proclamation-of-the-kingdom-of-god-wide.jpg",
    "art/dark/luminous/mystery-04-transfiguration-wide.jpg",
    "art/dark/luminous/mystery-05-institution-of-the-holy-eucharist-wide.jpg"
  ],
  sorrowful: [
    "art/dark/sorrowful/mystery-01-agony-in-the-garden-wide.jpg",
    "art/dark/sorrowful/mystery-02-scourging-at-the-pillar-wide.jpg",
    "art/dark/sorrowful/mystery-03-crowning-with-thorns-wide.jpg",
    "art/dark/sorrowful/mystery-04-carrying-of-the-cross-wide.jpg",
    "art/dark/sorrowful/mystery-05-crucifixion-wide.jpg"
  ],
  glorious: [
    "art/dark/glorious/mystery-01-resurrection-wide.jpg",
    "art/dark/glorious/mystery-02-ascension-wide.jpg",
    "art/dark/glorious/mystery-03-descent-of-the-holy-spirit-wide.jpg",
    "art/dark/glorious/mystery-04-assumption-wide.jpg",
    "art/dark/glorious/mystery-05-coronation-wide.jpg"
  ]
  }
};
const HERO = {
  joyful:{
    light:{wide:"art/hero/hero-joyful-light-wide.jpg",tall:"art/hero/hero-joyful-light-tall.jpg"},
    dark:{wide:"art/hero/hero-joyful-dark-wide.jpg",tall:"art/hero/hero-joyful-dark-tall.jpg"}
  },
  luminous:{
    light:{wide:"art/hero/hero-luminous-light-wide.jpg",tall:"art/hero/hero-luminous-light-tall.jpg"},
    dark:{wide:"art/hero/hero-luminous-dark-wide.jpg",tall:"art/hero/hero-luminous-dark-tall.jpg"}
  },
  sorrowful:{
    light:{wide:"art/hero/hero-sorrowful-light-wide.jpg",tall:"art/hero/hero-sorrowful-light-tall.jpg"},
    dark:{wide:"art/hero/hero-sorrowful-dark-wide.jpg",tall:"art/hero/hero-sorrowful-dark-tall.jpg"}
  },
  glorious:{
    light:{wide:"art/hero/hero-glorious-light-wide.jpg",tall:"art/hero/hero-glorious-light-tall.jpg"},
    dark:{wide:"art/hero/hero-glorious-dark-wide.jpg",tall:"art/hero/hero-glorious-dark-tall.jpg"}
  }
};
/* Average colour of the top of each tall hero, so the phone status bar
   can tint to the painting instead of sitting as a cream band above it. */
const HERO_TOP = {
  joyful:    {light:'#FFFCF7', dark:'#010101'},
  luminous:  {light:'#FFFBF9', dark:'#000000'},
  sorrowful: {light:'#F5F5EC', dark:'#0A0907'},
  glorious:  {light:'#F6F7F1', dark:'#050505'}
};

/* Where each painting looks when the plate is tall: faces and gestures,
   not a single global crop. Values are CSS object-position. */
const FOCUS = {
  joyful:   ["50% 30%","50% 30%","50% 32%","50% 34%","50% 36%"],
  luminous: ["50% 38%","50% 34%","50% 32%","50% 0%","50% 34%"],
  sorrowful:["50% 30%","50% 32%","50% 28%","50% 28%","50% 20%"],
  glorious: ["50% 22%","50% 22%","50% 28%","50% 30%","50% 30%"]
};
/* Short phone/tablet cinema band uses the 16:9 files. Y places the face in
   the clear middle of that strip (below the title fade, not clipped). */
const BAND_FOCUS = {
  joyful:   ["50% 51%","50% 51%","50% 56%","50% 58%","50% 58%"],
  luminous: ["50% 58%","50% 58%","50% 56%","50% 0%","50% 58%"],
  sorrowful:["50% 51%","50% 56%","50% 45%","50% 45%","50% 22%"],
  glorious: ["50% 28%","50% 28%","50% 45%","50% 51%","50% 51%"]
};
/* Tall right-hand plate on desktop. Same aim as the phone square so heads
   stay in frame. */
const DESKTOP_FOCUS = {
  joyful:   ["50% 30%","50% 30%","50% 32%","50% 34%","50% 36%"],
  luminous: ["50% 38%","50% 34%","50% 32%","50% 0%","50% 34%"],
  sorrowful:["50% 30%","50% 32%","50% 28%","50% 28%","50% 20%"],
  glorious: ["50% 22%","50% 22%","50% 28%","50% 30%","50% 30%"]
};
