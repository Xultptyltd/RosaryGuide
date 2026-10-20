(function(){
  // A stored choice wins across visits; otherwise follow the phone.
  var KEY = 'rosary-theme';
  var chosen = null;                      // persisted override, or null to follow system
  var painted = false;
  var easeTimer = 0;
  var DUSK_MS = 950;
  function reduced(){
    try{ return window.matchMedia('(prefers-reduced-motion: reduce)').matches; }
    catch(e){ return false; }
  }
  function paintIcons(t){
    var light = t === 'light';
    var v = '3';
    var tag = light ? '-light' : '';
    function setHref(sel, file){
      var el = document.querySelector(sel);
      if(el) el.setAttribute('href', file + tag + '.png?v=' + v);
    }
    setHref('link[rel="icon"][sizes="16x16"]', 'favicon-16');
    setHref('link[rel="icon"][sizes="32x32"]', 'favicon-32');
    setHref('link[rel="icon"][sizes="192x192"]', 'icon-192');
    setHref('link[rel="apple-touch-icon"]', 'apple-touch-icon');
  }
  function apply(t, ease){
    var html = document.documentElement;
    var next = t === 'light' ? 'light' : 'dark';
    if(ease && painted && !reduced()){
      html.classList.add('theme-ease');
      clearTimeout(easeTimer);
      easeTimer = setTimeout(function(){ html.classList.remove('theme-ease'); }, DUSK_MS + 80);
    } else {
      html.classList.remove('theme-ease');
    }
    html.setAttribute('data-theme', next);
    paintIcons(next);
    // the colours drawn from the paintings differ by theme, so re-derive them
    if(window.__swapArt) window.__swapArt();
    if(window.__repaintPaper) window.__repaintPaper();
    if(window.__paintChrome) window.__paintChrome();
    else {
      var c = next === 'light' ? '#F4F1EB' : '#0C0D0F';
      html.style.setProperty('--chrome', c);
      var m = document.querySelector('meta[name=theme-color]');
      if(m) m.setAttribute('content', c);
    }
  }
  var mq = window.matchMedia ? window.matchMedia('(prefers-color-scheme: light)') : null;
  function system(){ return (mq && mq.matches) ? 'light' : 'dark'; }
  try{
    var stored = localStorage.getItem(KEY);
    if(stored === 'light' || stored === 'dark') chosen = stored;
  }catch(e){}
  apply(chosen || system());
  painted = true;
  // follow the phone live only while there is no stored choice
  if(mq && mq.addEventListener){
    mq.addEventListener('change', function(e){ if(chosen === null) apply(e.matches ? 'light' : 'dark', true); });
  }
  window.__theme = function(t){
    chosen = t === 'light' ? 'light' : 'dark';
    try{ localStorage.setItem(KEY, chosen); }catch(e){}
    apply(chosen, true);
  };
})();
