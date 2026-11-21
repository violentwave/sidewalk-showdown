const fs=require("fs");
const hex=h=>[1,3,5].map(i=>parseInt(h.slice(i,i+2),16));
function img(w,h){return {w,h,p:Array(w*h).fill(null)};}
function set(im,x,y,c){if(x>=0&&y>=0&&x<im.w&&y<im.h)im.p[y*im.w+x]=c;}
function save(im,name){let o=`# ImageMagick pixel enumeration: ${im.w},${im.h},255,srgba\n`;for(let y=0;y<im.h;y++)for(let x=0;x<im.w;x++){const c=im.p[y*im.w+x];const v=c?hex(c).concat(255):[0,0,0,0];o+=`${x},${y}: (${v.join(",")})  #000000\n`;}fs.writeFileSync(name+".txt",o);}
function rect(im,x0,y0,x1,y1,c){for(let y=y0;y<=y1;y++)for(let x=x0;x<=x1;x++)set(im,x,y,c);}
function grid(im,x0,y0,rows,map){rows.forEach((r,y)=>[...r].forEach((ch,x)=>{if(map[ch])set(im,x0+x,y0+y,map[ch]);}));}
const O="#1C160D",D="#2A2418",W="#F4EEDC",P1="#F29E26",P1d="#B5641A",P2="#E5473A",P2d="#9C2A22",Y="#F2D13A",Yd="#4A3A12",PK="#FF3D9A",G="#B9B9B9",Gd="#7E7E7E";
// 3x5 font
const F={L:["x..","x..","x..","x..","xxx"],I:["xxx",".x.",".x.",".x.","xxx"],V:["x.x","x.x","x.x","x.x",".x."],E:["xxx","x..","xx.","x..","xxx"],A:[".x.","x.x","xxx","x.x","x.x"],B:["xx.","x.x","xx.","x.x","xx."],X:["x.x","x.x",".x.","x.x","x.x"],Y:["x.x","x.x",".x.",".x.",".x."],
"0":["xxx","x.x","x.x","x.x","xxx"],"1":[".x.","xx.",".x.",".x.","xxx"],"2":["xxx","..x","xxx","x..","xxx"],"3":["xxx","..x",".xx","..x","xxx"],"4":["x.x","x.x","xxx","..x","..x"],"5":["xxx","x..","xxx","..x","xxx"],"6":["xxx","x..","xxx","x.x","xxx"],"7":["xxx","..x",".x.",".x.",".x."],"8":["xxx","x.x","xxx","x.x","xxx"],"9":["xxx","x.x","xxx","..x","xxx"],"'":["x..","x..","...","...","..."],'"':["x.x","x.x","...","...","..."]};
// 3x3 win letters
const L3={K:["x.x","xx.","x.x"],T:["xxx",".x.",".x."],M:["xxx","xxx","x.x"],D:["xx.","x.x","xx."]};
const out=[];
// pips
const sq=(fill,inner)=>{const im=img(5,5);rect(im,0,0,4,4,O);rect(im,1,1,3,3,inner);return im;};
const dia=(inner)=>{const im=img(5,5);grid(im,0,0,["..o..",".oio.","oiiio",".oio.","..o.."],{o:O,i:inner});return im;};
out.push(["hud_pip_square_empty",sq(0,D)],["hud_pip_square_filled",sq(0,P1)],["hud_pip_diamond_empty",dia(D)],["hud_pip_diamond_filled",dia(P2)]);
for(const k of "KTMD"){const s=sq(0,P1);grid(s,1,1,L3[k],{x:W});out.push(["hud_pip_square_"+k.toLowerCase(),s]);
 const d=img(5,5);grid(d,0,0,["..o..",".ooo.","ooooo",".ooo.","..o.."],{o:P2});grid(d,1,1,L3[k],{x:W});grid(d,0,0,["..o..",".x.x.","x...x",".x.x.","..o.."],{o:O,x:O});
 // keep letter inside: redraw letter over interior only
 grid(d,1,1,L3[k],{x:W});set(d,2,0,O);set(d,0,2,O);set(d,4,2,O);set(d,2,4,O);out.push(["hud_pip_diamond_"+k.toLowerCase(),d]);}
// METH skull 8x8, 2 frames
const sk1=["..oooo..",".owwwwo.","owwwwwwo","opwwwpwo","owwowwwo",".owwwwo.","..owowo.","..ooooo."];
const sk2=["..oooo..",".owwwwo.","owwwwwwo","owpwwwpo","owwwowwo",".owwwwo.",".owowow.","..ooooo."];
for(const [n,r] of [["hud_meth_skull_f1",sk1],["hud_meth_skull_f2",sk2]]){const im=img(8,8);grid(im,0,0,r,{o:O,w:W,p:PK});out.push([n,im]);}
// timer digits: 7-seg 8x12, strip 88x12 (0-9, inf)
const segs={0:"abcdef",1:"bc",2:"abged",3:"abgcd",4:"fgbc",5:"afgcd",6:"afgedc",7:"abc",8:"abcdefg",9:"abcdfg"};
function seg(im,ox,on){const S={a:[[1,0],[6,1]],d:[[1,10],[6,11]],g:[[1,5],[6,6]],f:[[0,1],[1,5]],b:[[6,1],[7,5]],e:[[0,6],[1,10]],c:[[6,6],[7,10]]};
 for(const [k,[[x0,y0],[x1,y1]]] of Object.entries(S))rect(im,ox+x0,y0,ox+x1,y1,on.includes(k)?Y:Yd);}
const strip=img(88,12);for(let i=0;i<10;i++)seg(strip,i*8,segs[i]);
grid(strip,80,0,["........","........","........","........",".yy..yy.","y..yy..y","y..yy..y",".yy..yy.","........","........","........","........"],{y:Y});
out.push(["hud_timer_digits",strip]);
for(let i=0;i<10;i++){const im=img(8,12);seg(im,0,segs[i]);out.push(["hud_timer_digit_"+i,im]);}
// LIVE tag 24x7
const lv=img(24,7);rect(lv,0,0,23,6,O);rect(lv,1,1,22,5,P2);grid(lv,2,2,[".x.","xxx",".x."],{x:W});let x=6;for(const ch of "LIVE"){grid(lv,x,1,F[ch],{x:W});x+=4;}out.push(["stream_live_tag",lv]);
// input glyphs 9x9
const key=img(9,9);grid(key,0,0,[".ooooooo.","oGGGGGGGo","oGgggggGo","oGgggggGo","oGgggggGo","oGgggggGo","oGGGGGGGo","oddddddDo",".ooooooo."],{o:O,G:"#D9CDB0",g:"#EFE6CF",d:"#9C8F70",D:"#9C8F70"});out.push(["ui_glyph_key_blank",key]);
const circ=["..ooooo..",".occcccо.","occcccccо","occcccccо","occcccccо","occcccccо","occcccccо",".occcccо.","..ooooo.."].map(r=>r.replace(/о/g,"o"));
for(const [ch,col] of [["A","#3FA34D"],["B","#E5473A"],["X","#3D7DE0"],["Y","#F2D13A"]]){const im=img(9,9);grid(im,0,0,circ,{o:O,c:col});grid(im,3,2,F[ch],{x:ch=="Y"?O:W});out.push(["ui_glyph_pad_"+ch.toLowerCase(),im]);}
const dp=img(9,9);grid(dp,0,0,["..ooooo..","..oGGGo..","oooGgGooo","oGGGgGGGo","oGggggGGo".replace("oGggggGGo","oGgggggGo"),"oGGGgGGGo","oooGgGooo","..oGGGo..","..ooooo.."],{o:O,G:"#5A5A5A",g:"#8A8A8A"});out.push(["ui_glyph_dpad",dp]);
// lit slat 66x7
const sl=img(66,7);rect(sl,0,0,65,6,"#B8860B");rect(sl,1,1,64,5,Y);rect(sl,1,1,64,1,"#FFF2A0");out.push(["menu_price_slat_lit",sl]);
// mugshot height-chart bg 320x180
const bg=img(320,180);let seed=7;const rnd=()=>{seed=(seed*1103515245+12345)&0x7fffffff;return seed/0x7fffffff;};
for(let y=0;y<180;y++)for(let x=0;x<320;x++)set(bg,x,y,rnd()<0.06?"#33433F":(rnd()<0.03?"#4A5C57":"#3C4E49"));
for(let y=10;y<170;y+=8){const major=((y-10)/8)%3==0;rect(bg,major?0:0,y,major?319:22,y,major?"#9FB3A6":"#7E918A");}
let ft=7;for(let y=10;y<170;y+=24){const lab=ft+"'";let lx=4;for(const ch of lab){grid(bg,lx,y+2,F[ch],{x:"#E8E2C8"});lx+=4;}ft--;}
for(let i=0;i<40;i++){const sx=Math.floor(rnd()*318),sy=Math.floor(rnd()*178);set(bg,sx,sy,"#2B3734");set(bg,sx+1,sy,"#2B3734");}
out.push(["select_mugshot_bg",bg]);
for(const [n,im] of out)save(im,n);console.log(out.length);
