import re, math, json
from PIL import Image
R='/home/claude/violentwave/sidewalk-showdown/'; PR='/home/claude/fxgen/props/'; FX='/home/claude/fxgen/full/'
def lib(f):
    txt=open(R+f).read(); d={}
    for m in re.finditer(r'"(\w+)": \{"path": "res://([^"]+)", "frames": (\d+), "anchor": Vector2\(([\d.]+), ([\d.]+)\), "h_ref": ([\d.]+)',txt):
        d[m.group(1)]=dict(path=R+'game/'+m.group(2),n=int(m.group(3)),ax=float(m.group(4)),ay=float(m.group(5)),h=float(m.group(6)))
    return d
PEG=lib('game/scripts/combat/peggy_clip_library.gd'); RIC=lib('game/scripts/combat/richard_clip_library.gd')
_cache={}
def cel(L,clip,i,flip=False):
    c=L[clip]; key=(c['path'],i,flip)
    if key not in _cache:
        im=Image.open(c['path']).convert('RGBA'); w=im.width//c['n']; i=max(0,min(i,c['n']-1))
        im=im.crop((i*w,0,(i+1)*w,im.height)); s=56/c['h']
        ax,ay=c['ax']*s,c['ay']*s
        im=im.resize((max(1,round(im.width*s)),max(1,round(im.height*s))),Image.NEAREST)
        if flip: im=im.transpose(Image.FLIP_LEFT_RIGHT); ax=im.width-ax
        _cache[key]=(im,ax,ay)
    return _cache[key]
def draw(canvas,L,clip,i,x,y,flip=False,clip_below=None):
    im,ax,ay=cel(L,clip,i,flip); im=im.copy()
    if clip_below is not None:   # hide pixels below a screen y (sewer rim mask)
        cut=int(clip_below-(y-ay))
        if cut<im.height:
            if cut<=0: return
            im=im.crop((0,0,im.width,cut))
    canvas.alpha_composite(im,(int(x-ax),int(y-ay)))
def sh(name,i,cellw,cellh):
    s=Image.open((PR if 'plank' in name or 'sewer' in name or 'water' in name or 'fumes' in name or 'sign' in name else FX)+name+'.png').convert('RGBA')
    i=max(0,min(i,s.width//cellw-1)); return s.crop((i*cellw,0,(i+1)*cellw,cellh))
def stage(name):
    b=Image.open(R+f'game/art/stages/{name}/{name}_sky.png').convert('RGBA'); b.alpha_composite(Image.open(R+f'game/art/stages/{name}/{name}_foreground.png').convert('RGBA')); return b
def letterbox(c,dim=True):
    if dim:
        ov=Image.new('RGBA',c.size,(0,0,0,70)); c.alpha_composite(ov)
    ov=Image.new('RGBA',(320,8),(0,0,0,255)); c.alpha_composite(ov,(0,0)); c.alpha_composite(ov,(0,172))

def walk_the_plank():
    bg=stage('gas_n_go'); F=158; px_,vx=120,152; frames=[]
    for t in range(0,210,3):
        c=bg.copy(); letterbox(c)
        # beats (sim frames)
        if t<30:   # METH contact hold: Peggy's peg-leg poke (forward special) hits
            draw(c,PEG,'forward',2,px_,F); draw(c,RIC,'hitstun_stand',0,vx,F,flip=True)
            c.alpha_composite(sh('peggy_ex_hit_sheet',min(t//3,8),48,48),(vx-30,F-60))
        elif t<60:  # knocked down onto the plank
            k=(t-30)//5; c.alpha_composite(sh('plank_base',0,96,32),(vx-40,F-27))
            draw(c,PEG,'forward',min(3+k,5),px_,F); draw(c,RIC,'knockdown',min(k,3),vx,F-4,flip=True)
        elif t<90:  # peg-leg pin (crouch heavy sweep cels)
            k=(t-60)//6; c.alpha_composite(sh('plank_base',0,96,32),(vx-40,F-27))
            draw(c,RIC,'knockdown',3,vx,F-4,flip=True); draw(c,PEG,'crouch_heavy',min(1+k,3),px_+10,F)
            if t==72: c.alpha_composite(sh('peggy_hit_counter_sheet',1,40,40),(vx-26,F-30))
        elif t<120: # peg stomp: plank snaps, sewer opens
            k=(t-90)//4
            c.alpha_composite(sh('sewer_open_sheet',min(k,6),96,64),(vx-48,F-46+2))
            c.alpha_composite(sh('plank_snap_sheet',min(k,6),96,32),(vx-40,F-27))
            draw(c,RIC,'knockdown',3,vx,F-4+k,flip=True,clip_below=F+2)
            draw(c,PEG,'crouch_heavy',3 if k<2 else 4,px_+10,F)
            if k<3: c.alpha_composite(sh('peggy_hit_heavy_sheet',min(k+1,6),40,40),(vx-30,F-30))
        elif t<168: # victim drops through, front rim covers, splash
            k=(t-120)/48
            c.alpha_composite(sh('sewer_open_sheet',6,96,64),(vx-48,F-44))
            draw(c,RIC,'ko_air',int(k*3),vx,F+4+k*k*60,flip=True,clip_below=F+2)
            c.alpha_composite(sh('water_drop_mask_sheet',min(int(k*9),6),96,64),(vx-48,F-44))
            draw(c,PEG,'crouch_heavy',5,px_+10,F)
        else:       # settle; Peggy's confident win pose
            c.alpha_composite(sh('sewer_open_sheet',6,96,64),(vx-48,F-44)); c.alpha_composite(sh('water_drop_mask_sheet',6,96,64),(vx-48,F-44))
            draw(c,PEG,'win',min((t-168)//8,3),px_+10,F)
        frames.append(c)
    return frames

def flaming_belch():
    bg=stage('bus_stop'); F=170; rx,vx=110,142; frames=[]
    for t in range(0,210,3):
        c=bg.copy(); letterbox(c)
        if t<30:
            draw(c,RIC,'neutral',2,rx,F); draw(c,PEG,'hitstun_stand',0,vx,F,flip=True)
            c.alpha_composite(sh('richard_ex_hit_sheet',min(t//3,8),48,48),(vx-30,F-60))
        elif t<90:  # bottle drench, fumes billow across the pair
            k=(t-30)//10
            c.alpha_composite(sh('whiskey_fumes_sheet',min(k,6),128,96),(rx-4,F-90))
            draw(c,RIC,'heavy',min(1+(t-30)//12,3),rx,F); draw(c,PEG,'hitstun_stand',1,vx,F,flip=True)
        elif t<120: # belch ignites the fumes
            k=(t-90)//4
            draw(c,PEG,'hitstun_stand',2,vx,F,flip=True)
            c.alpha_composite(sh('whiskey_fumes_sheet',6,128,96),(rx-4,F-90))
            if k>=2:
                fl=Image.new('RGBA',c.size,(255,211,79,60 if k%2 else 30)); c.alpha_composite(fl)
            draw(c,RIC,'neutral',min(2+k//2,5),rx,F)
            c.alpha_composite(sh('fire_belch_sheet',min(k,6),104,64),(rx+8,F-82))
        elif t<180: # victim launched through the bar sign
            k=(t-120)/60
            sx=vx+70; sy=F-70
            i=min(int(k*12),6)
            if t<150: c.alpha_composite(sh('fictional_bar_sign_base',0,96,48),(sx-48,sy-26))
            else: c.alpha_composite(sh('bar_sign_shatter_back_sheet',min((t-150)//4,6),96,64),(sx-48,sy-26))
            vxx=vx+k*110; vyy=F-k*90+k*k*40
            draw(c,PEG,'ko_air',int(k*3)%3,vxx,vyy,flip=True)
            if t>=150: c.alpha_composite(sh('bar_sign_shatter_front_sheet',min((t-150)//4,6),96,64),(sx-48,sy-26))
            draw(c,RIC,'neutral',5,rx,F)
        else:
            draw(c,RIC,'win',min((t-180)//8,3),rx,F)
        frames.append(c)
    return frames

for name,fn in [('walk_the_plank_animatic',walk_the_plank),('flaming_belch_animatic',flaming_belch)]:
    fr=[f.resize((960,540),Image.NEAREST).convert('RGB') for f in fn()]
    fr[0].save(f'/home/claude/fxgen/props/{name}.gif',save_all=True,append_images=fr[1:],duration=50,loop=0)
    fr[len(fr)//2].save(f'/home/claude/fxgen/props/{name}_mid.png')
print(sorted(PEG)[:5], len(PEG), len(RIC))
