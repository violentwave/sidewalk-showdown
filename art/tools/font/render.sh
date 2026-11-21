#!/bin/bash
# render.sh <font> "<text>" <color> <out.png>
f=$1; txt="$2"; col=$3; out=$4
node -e '
const fs=require("fs");const [f,txt]=process.argv.slice(1);const fnt=fs.readFileSync(f+".fnt","utf8");const C={};
for(const l of fnt.split("\n"))if(l.startsWith("char ")){const o={};for(const m of l.matchAll(/(\w+)=(-?\d+)/g))o[m[1]]=+m[2];C[o.id]=o;}
let x=0,ops=[];for(const ch of txt){const c=C[ch.charCodeAt(0)];if(!c)continue;if(c.width)ops.push(`${f}.png[${c.width}x${c.height}+${c.x}+${c.y}] -geometry +${x}+0 -composite`);x+=c.xadvance;}
const h=+(fnt.match(/lineHeight=(\d+)/)[1]);console.log(x+" "+h+"\n"+ops.join(" "));' "$f" "$txt" > /tmp/font/r.txt
read W H < <(head -1 /tmp/font/r.txt); ops=$(tail -1 /tmp/font/r.txt)
eval convert -size ${W}x${H} xc:none $ops /tmp/font/r_raw.png
convert /tmp/font/r_raw.png -fill "$col" -opaque white $out
