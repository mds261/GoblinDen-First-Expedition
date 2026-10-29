/* Touch-only browser controls using GoblinDen's existing keyboard bindings. */
(() => {
  'use strict';
  if (!(navigator.maxTouchPoints > 0 || matchMedia('(pointer: coarse)').matches)) return;
  function mount() {
    const canvas = document.getElementById('canvas');
    if (!canvas || document.getElementById('goblinden-touch')) return;
    const viewport = document.querySelector('meta[name="viewport"]');
    if (viewport) viewport.content = 'width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover';
    const style = document.createElement('style');
    style.textContent = `
      #goblinden-touch {position:fixed;inset:0;z-index:10;pointer-events:none;display:none;color:#f1e8cd;font:600 12px system-ui,sans-serif;--button:clamp(40px,11vh,64px);-webkit-user-select:none;user-select:none}
      #goblinden-touch.ready {display:block}
      #goblinden-touch button {pointer-events:auto;touch-action:none;-webkit-touch-callout:none;border:1px solid #bca576aa;background:#1a292be0;color:inherit;border-radius:12px;font:inherit;min-width:40px;min-height:36px;padding:6px 10px}
      #goblinden-touch button.held {background:#907344ee;border-color:#ffe0a0}
      #gd-toolbar {position:absolute;right:max(10px,env(safe-area-inset-right));top:max(8px,env(safe-area-inset-top));display:flex;gap:5px}
      #gd-stick {position:absolute;pointer-events:auto;touch-action:none;left:max(24px,env(safe-area-inset-left));bottom:max(28px,env(safe-area-inset-bottom));width:clamp(96px,27vh,150px);aspect-ratio:1;border-radius:50%;border:2px solid #c2cfb577;background:#14272977;box-sizing:border-box}
      #gd-stick::before {content:'MOVE';position:absolute;top:8px;width:100%;text-align:center;font-size:10px;color:#e0e9ceaa}
      #gd-knob {position:absolute;left:28%;top:28%;width:44%;height:44%;border-radius:50%;background:#71926ebd;border:1px solid #d2dfbb99;box-sizing:border-box;pointer-events:none}
      #gd-actions {position:absolute;right:max(16px,env(safe-area-inset-right));bottom:max(22px,env(safe-area-inset-bottom));display:grid;grid-template-columns:repeat(3,var(--button));gap:8px;align-items:center}
      #gd-actions button {width:var(--button);height:var(--button);padding:2px;border-radius:50%;font-size:11px}
      #gd-actions button[data-code="Space"] {background:#713e2bdd;border-color:#d0a26c}
      #gd-hint {position:absolute;top:52px;left:0;right:0;text-align:center;font-weight:400;font-size:11px;color:#e7ddc5;pointer-events:none}
      #goblinden-touch.folded #gd-stick,#goblinden-touch.folded #gd-actions {display:none}
      @media (orientation:landscape) {#gd-hint {display:none}}
    `;
    document.head.appendChild(style);
    const root = document.createElement('div');
    root.id = 'goblinden-touch';
    root.setAttribute('aria-label', 'Touch game controls');
    root.innerHTML = `<div id="gd-toolbar"><button data-code="KeyI" aria-label="Inventory">Bag</button><button data-code="KeyJ" aria-label="Expedition journal">Journal</button><button data-code="Escape" aria-label="Close game menu">Back</button><button id="gd-toggle" aria-label="Hide touch controls" aria-expanded="true">Hide</button></div><div id="gd-hint">Turn your phone sideways for more room</div><div id="gd-stick" aria-label="Movement joystick"><div id="gd-knob"></div></div><div id="gd-actions"><button data-code="KeyQ">SKILL</button><button data-code="KeyE">USE</button><button data-code="KeyF">HEAL</button><button data-code="ShiftLeft">ROLL</button><button data-code="Space">ATK</button><button data-code="KeyH">TOOLS</button></div>`;
    document.body.appendChild(root);
    const keyNames = {KeyW:'w',KeyA:'a',KeyS:'s',KeyD:'d',KeyQ:'q',KeyE:'e',KeyF:'f',KeyH:'h',KeyI:'i',KeyJ:'j',Space:' ',ShiftLeft:'Shift',Escape:'Escape'};
    const held = new Map();
    const pointers = new Map();
    const stick = document.getElementById('gd-stick');
    const knob = document.getElementById('gd-knob');
    let stickPointer = null;
    let stickKeys = new Set();
    function send(code, pressed) {
      canvas.dispatchEvent(new KeyboardEvent(pressed ? 'keydown' : 'keyup', {
        code, key:keyNames[code], location:code === 'ShiftLeft' ? 1 : 0,
        shiftKey:code === 'ShiftLeft' && pressed, bubbles:true, cancelable:true
      }));
    }
    function press(code) {
      const count = held.get(code) || 0;
      held.set(code, count + 1);
      if (!count) send(code, true);
    }
    function release(code) {
      const count = held.get(code) || 0;
      if (count > 1) held.set(code, count - 1);
      else if (count) {held.delete(code); send(code, false);}
    }
    function clearStick() {
      stickKeys.forEach(release);
      stickKeys.clear(); stickPointer = null; knob.style.transform = '';
    }
    function releaseAll() {
      for (const code of held.keys()) send(code, false);
      held.clear(); pointers.clear(); stickKeys.clear(); stickPointer = null;
      knob.style.transform = '';
      root.querySelectorAll('.held').forEach(el => el.classList.remove('held'));
    }
    function moveStick(event) {
      const rect = stick.getBoundingClientRect();
      const radius = rect.width * .38;
      let x = (event.clientX - rect.left - rect.width / 2) / radius;
      let y = (event.clientY - rect.top - rect.height / 2) / radius;
      const distance = Math.hypot(x,y);
      if (distance > 1) {x /= distance; y /= distance;}
      knob.style.transform = `translate(${x * radius}px,${y * radius}px)`;
      const next = new Set();
      if (x < -.26) next.add('KeyA');
      if (x > .26) next.add('KeyD');
      if (y < -.26) next.add('KeyW');
      if (y > .26) next.add('KeyS');
      stickKeys.forEach(code => {if (!next.has(code)) release(code);});
      next.forEach(code => {if (!stickKeys.has(code)) press(code);});
      stickKeys = next;
    }
    stick.addEventListener('pointerdown', event => {
      if (stickPointer !== null) return;
      event.preventDefault(); canvas.focus({preventScroll:true});
      stickPointer = event.pointerId; stick.setPointerCapture(event.pointerId); moveStick(event);
    });
    stick.addEventListener('pointermove', event => {
      if (event.pointerId === stickPointer) {event.preventDefault(); moveStick(event);}
    });
    for (const type of ['pointerup','pointercancel','lostpointercapture']) stick.addEventListener(type, event => {
      if (event.pointerId === stickPointer) clearStick();
    });
    root.querySelectorAll('[data-code]').forEach(button => {
      button.addEventListener('pointerdown', event => {
        event.preventDefault(); canvas.focus({preventScroll:true});
        button.setPointerCapture(event.pointerId);
        pointers.set(event.pointerId, button.dataset.code); press(button.dataset.code);
        button.classList.add('held');
      });
      const finish = event => {
        const code = pointers.get(event.pointerId);
        if (!code) return;
        pointers.delete(event.pointerId); release(code);
        if (![...pointers.values()].includes(code)) button.classList.remove('held');
      };
      for (const type of ['pointerup','pointercancel','lostpointercapture']) button.addEventListener(type,finish);
      button.addEventListener('contextmenu', event => event.preventDefault());
    });
    document.getElementById('gd-toggle').addEventListener('click', event => {
      releaseAll(); const folded = root.classList.toggle('folded');
      event.currentTarget.textContent = folded ? 'Controls' : 'Hide';
      event.currentTarget.setAttribute('aria-expanded',String(!folded));
      event.currentTarget.setAttribute('aria-label',folded ? 'Show touch controls' : 'Hide touch controls');
    });
    window.addEventListener('blur',releaseAll);
    window.addEventListener('pagehide',releaseAll);
    window.addEventListener('resize',releaseAll);
    document.addEventListener('visibilitychange', () => {if (document.hidden) releaseAll();});
    function ready() {
      if (!document.getElementById('status')) {root.classList.add('ready'); observer.disconnect();}
    }
    const observer = new MutationObserver(ready);
    observer.observe(document.body,{childList:true}); ready();
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded',mount,{once:true});
  else mount();
})();
