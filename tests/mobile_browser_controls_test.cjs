const {readFileSync} = require('fs');
const vm = require('vm');
const assert = require('assert/strict');
const source = readFileSync(require('path').join(__dirname,'../docs/mobile-controls.js'),'utf8');
class Element {
  constructor(id='') {
    this.id=id; this.events={}; this.dataset={}; this.style={}; this.attrs={};this.classes=new Set();
    this.classList={add:x=>this.classes.add(x),remove:x=>this.classes.delete(x),
      toggle:x=>{if(this.classes.has(x)){this.classes.delete(x);return false;}this.classes.add(x);return true;}};
  }
  addEventListener(name,fn){(this.events[name]??=[]).push(fn);}
  emit(name,props={}){const e={preventDefault(){},currentTarget:this,pointerId:1,...props};for(const fn of this.events[name]||[])fn(e);}
  dispatchEvent(e){this.emit(e.type,e);}
  setAttribute(n,v){this.attrs[n]=v;}
  setPointerCapture(){}
  focus(){}
  getBoundingClientRect(){return {left:24,top:200,width:120,height:120};}
  querySelectorAll(q){if(q==='[data-code]')return this.buttons||[];return (this.buttons||[]).filter(b=>b.classes.has('held'));}
}
function setup(touch=1,loading=false) {
  const all = {}; const keys=[];
  const doc = new Element();doc.readyState='complete';doc.hidden=false;
  doc.head=new Element();doc.head.appendChild=()=>{};
  doc.body=new Element();doc.body.appendChild=root=>{
    all[root.id]=root;root.buttons=[];
    for(const code of ['KeyI','KeyJ','Escape','KeyQ','KeyE','KeyF','ShiftLeft','Space','KeyH']){
      const b=new Element();b.dataset.code=code;root.buttons.push(b);
    }
    for(const id of ['gd-stick','gd-knob','gd-toggle']) all[id]=new Element(id);
  };
  all.canvas=new Element('canvas');
  for(const type of ['keydown','keyup'])all.canvas.addEventListener(type,e=>keys.push([type,e.code,e.key]));
  if(loading)all.status=new Element('status');
  doc.getElementById=id=>all[id]||null;
  doc.createElement=()=>new Element();
  doc.querySelector=()=>null;
  const win=new Element();let observer;
  vm.runInNewContext(source,{navigator:{maxTouchPoints:touch},matchMedia:()=>({matches:false}),
    document:doc,window:win,KeyboardEvent:class{constructor(type,props){this.type=type;Object.assign(this,props)}},
    MutationObserver:class{constructor(fn){observer=fn;}observe(){}disconnect(){}}});
  return {all,keys,doc,win,loaded(){delete all.status;observer();}};
}
assert.equal(setup(0).all['goblinden-touch'],undefined,'desktop must stay unchanged');
const t=setup(1,true), root=t.all['goblinden-touch'];
assert(!root.classes.has('ready'));t.loaded();assert(root.classes.has('ready'));
const button=code=>root.buttons.find(b=>b.dataset.code===code);
const stick=t.all['gd-stick'];
stick.emit('pointerdown',{pointerId:10,clientX:140,clientY:210});
assert.deepEqual(t.keys.slice(-2).map(x=>x[1]),['KeyD','KeyW'],'diagonal movement');
button('Space').emit('pointerdown',{pointerId:11});
assert.equal(t.keys.at(-1)[1],'Space','attack while moving');
button('Space').emit('pointerup',{pointerId:11});
assert(t.keys.some(x=>x[0]==='keyup'&&x[1]==='Space'));
stick.emit('pointercancel',{pointerId:10});
assert.deepEqual(t.keys.slice(-2).map(x=>x[0]),['keyup','keyup'],'cancel releases movement');
for(const code of ['KeyQ','KeyE','KeyF','ShiftLeft','KeyI','KeyJ','Escape','KeyH']) {
  button(code).emit('pointerdown');button(code).emit('pointerup');
  assert.equal(t.keys.at(-2)[1],code);assert.equal(t.keys.at(-1)[0],'keyup');
}
button('Space').emit('pointerdown',{pointerId:1});button('Space').emit('pointerdown',{pointerId:2});
const count=t.keys.length;button('Space').emit('pointerup',{pointerId:1});
assert.equal(t.keys.length,count,'one finger must not release another');
button('Space').emit('lostpointercapture',{pointerId:2});assert.equal(t.keys.at(-1)[0],'keyup');
stick.emit('pointerdown',{pointerId:3,clientX:140,clientY:260});
button('KeyQ').emit('pointerdown',{pointerId:4});t.win.emit('blur');
assert.deepEqual(t.keys.slice(-2).map(x=>x[0]),['keyup','keyup'],'app switch releases all');
t.all['gd-toggle'].emit('click');assert(root.classes.has('folded'));
t.all['gd-toggle'].emit('click');assert(!root.classes.has('folded'));
t.doc.hidden=true;button('Space').emit('pointerdown');t.doc.emit('visibilitychange');
assert.equal(t.keys.at(-1)[0],'keyup');
console.log('PASS: desktop isolation, loading gate, diagonal movement, simultaneous movement/attack, every action, multiple fingers, cancellation, app switching, hide/show, background release.');
