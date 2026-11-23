import sys, math, random, os
sys.path.insert(0,'/home/claude/fxgen')
from fx import *
from PIL import Image
import importlib.util
spec=importlib.util.spec_from_file_location('p2','/home/claude/fxgen/pilot2.py'); p2=importlib.util.module_from_spec(spec); spec.loader.exec_module(p2)
P,R,F=p2.P,p2.R,p2.F
OUT='/home/claude/fxgen/full/'; os.makedirs(OUT,exist_ok=True)
def ease(n): return [1-(1-i/(n-1))**2 for i in range(n)]
def fin(im,ink,minpx=2): return outline(despeckle(im,minpx),ink)

# ---------------- PEGGY ----------------
def p_light():
    W=Hh=32; cx,cy=13,16; E=ease(5); fr=[]
    sh=[(-30,1.0,4,1.2),(25,0.9,3.5,1.1)]
    for f in range(5):
        im=Image.new('RGBA',(W,Hh),T); px=im.load(); e=E[f]
        if f==0: star(px,W,Hh,cx,cy,1.5,7,4,0,P['steel']); star(px,W,Hh,cx,cy,1,4.5,4,0,P['hot'])
        if f==1: star(px,W,Hh,cx,cy,1,5,4,math.radians(45),P['ember']); star(px,W,Hh,cx,cy,1,3,4,math.radians(45),P['hot']); ring(px,W,Hh,cx,cy,7,1,P['steel'],sy=0.8,gaps=[(60,120),(240,300)])
        if f>=1:
            for a,v,L,wd in sh:
                ar=math.radians(a); d=4+v*e*10; x=cx+math.cos(ar)*d; y=cy+math.sin(ar)*d+e*e*4
                if f==4 and v<1: continue
                shard(px,W,Hh,x,y,ar+f*0.9,L,wd,P['wood'],P['woodL'])
        if f in (1,2):
            for a in (-40,0,40):
                ar=math.radians(a); r0=6+e*6; line(px,W,Hh,cx+math.cos(ar)*r0,cy+math.sin(ar)*r0,cx+math.cos(ar)*(r0+3),cy+math.sin(ar)*(r0+3),P['hot'])
        fr.append(fin(im,P['ink']))
    return fr

def p_counter():
    W=Hh=40; cx,cy=15,20; E=ease(7); fr=[]
    for f in range(7):
        im=Image.new('RGBA',(W,Hh),T); px=im.load(); e=E[f]
        if f==0: star(px,W,Hh,cx,cy,1.5,7,4,math.radians(45),P['hot'])
        if f in (1,2):
            s=1 if f==1 else 0.8
            star(px,W,Hh,cx,cy,4*s,15*s,4,math.radians(45),P['ember']); star(px,W,Hh,cx,cy,3*s,12*s,4,math.radians(45),P['steel'])
            star(px,W,Hh,cx,cy,2*s,9*s,4,0,P['hot']); disc(px,W,Hh,cx,cy,3*s,P['hot'])
        if f>=2:   # two crossed nails thrown out in an X, spinning
            for a in (-135,-45,45,135):
                ar=math.radians(a); d=6+e*13; x=cx+math.cos(ar)*d; y=cy+math.sin(ar)*d+e*e*5
                ang=ar+f*0.8; x2=x+math.cos(ang)*5; y2=y+math.sin(ang)*5
                line(px,W,Hh,x,y,x2,y2,P['steel']); line(px,W,Hh,x2,y2,x2+math.cos(ang+1.7)*2,y2+math.sin(ang+1.7)*2,P['steel'])
                put(px,W,Hh,x,y,P['olive']); put(px,W,Hh,x+math.cos(ar),y+math.sin(ar),P['olive'])
        if 2<=f<=4: ring(px,W,Hh,cx,cy,9+e*9,1.5 if f<4 else 1,P['ember'] if f==2 else P['steel'],sy=1.0,gaps=None if f==2 else [(20,70),(110,160),(200,250),(290,340)])
        fr.append(fin(im,P['ink']))
    return fr

def p_block():
    W=Hh=32; cx,cy=13,16; E=ease(5); fr=[]
    for f in range(5):
        im=Image.new('RGBA',(W,Hh),T); px=im.load(); e=E[f]
        # deflection arc facing the attacker (left), olive/steel, no hot core
        if f<=3:
            r=6+e*5; ring(px,W,Hh,cx+3,cy,r,2 if f<2 else 1,P['steel'] if f<2 else P['olive'],sy=1.3,gaps=[(-90+360,360),(0,90)] if True else None)
        if f in (0,1):
            star(px,W,Hh,cx,cy,1,3.5 if f==0 else 2.5,4,0,P['steel'])
        if 1<=f<=3:   # duct-tape fleck + two dull sparks
            for a in (-150,150):
                ar=math.radians(a); d=5+e*8; put(px,W,Hh,cx+math.cos(ar)*d,cy+math.sin(ar)*d,P['ember'] if f==1 else P['olive'])
                put(px,W,Hh,cx+math.cos(ar)*(d+1),cy+math.sin(ar)*(d+1),P['olive'])
            x=cx-4-e*5; y=cy-5+e*e*6; poly(px,W,Hh,[(x,y),(x+3,y-1),(x+3,y+1),(x,y+2)],P['olive'])
        fr.append(fin(im,P['ink'],1))
    return fr

def p_special():
    W,Hh=48,32; cx,cy=14,16; E=ease(7); fr=[]
    sh=[(-20,1.0,5,1.5),(10,1.15,6,1.6),(-45,0.8,4,1.2),(35,0.85,4,1.2)]
    for f in range(7):
        im=Image.new('RGBA',(W,Hh),T); px=im.load(); e=E[f]
        if f==0: poly(px,W,Hh,[(cx-3,cy),(cx+8,cy-2),(cx+12,cy),(cx+8,cy+2)],P['hot'])
        if f in (1,2):   # stretched forward burst (peg poke)
            k=1 if f==1 else 0.75
            poly(px,W,Hh,[(cx-5*k,cy),(cx+4,cy-8*k),(cx+26*k,cy),(cx+4,cy+8*k)],P['ember'])
            poly(px,W,Hh,[(cx-3*k,cy),(cx+4,cy-5*k),(cx+20*k,cy),(cx+4,cy+5*k)],P['steel'])
            poly(px,W,Hh,[(cx-1,cy),(cx+4,cy-3*k),(cx+13*k,cy),(cx+4,cy+3*k)],P['hot'])
        if f>=2:
            for a,v,L,wd in sh:
                ar=math.radians(a); d=8+v*e*20; x=cx+math.cos(ar)*d; y=cy+math.sin(ar)*d+e*e*6
                if f==6 and v<1: continue
                shard(px,W,Hh,x,y,ar+(f-2)*0.7,L,wd,P['wood'],P['woodL'])
        if f in (2,3):
            for dy in (-6,0,6):
                x0=cx+14+e*10; line(px,W,Hh,x0,cy+dy,x0+(6 if f==2 else 3),cy+dy,P['hot'] if f==2 else P['ember'])
        fr.append(fin(im,P['ink']))
    return fr

def p_ex():
    W=Hh=48; cx,cy=19,24; E=ease(9); fr=[]
    rnd=random.Random(5); sh=[(rnd.uniform(-160,160),rnd.uniform(0.7,1.2),rnd.uniform(4,7),rnd.uniform(1.2,2)) for _ in range(8)]
    nails=[(-30,1.0),(60,0.9),(-110,0.8)]
    for f in range(9):
        im=Image.new('RGBA',(W,Hh),T); px=im.load(); e=E[f]
        if f==0: star(px,W,Hh,cx,cy,2,9,4,math.radians(45),P['steel']); star(px,W,Hh,cx,cy,1,5,4,math.radians(45),P['hot'])
        if f in (1,2):
            s=1 if f==1 else 0.85
            star(px,W,Hh,cx,cy,5*s,20*s,8,0,P['ember']); star(px,W,Hh,cx,cy,4*s,16*s,8,math.radians(22.5),P['steel'])
            star(px,W,Hh,cx,cy,3*s,11*s,8,0,P['hot']); disc(px,W,Hh,cx,cy,5*s,P['hot'])
        if 2<=f<=5: ring(px,W,Hh,cx,cy,10+e*12,2 if f<4 else 1,P['steel'],sy=0.85,gaps=None if f<4 else [(10,60),(130,190),(250,300)])
        if 3<=f<=5: ring(px,W,Hh,cx,cy,6+e*8,1,P['ember'],sy=0.85,gaps=[(0,90),(180,260)])
        if f>=2:
            for a,v,L,wd in sh:
                ar=math.radians(a); d=7+v*e*20; x=cx+math.cos(ar)*d; y=cy+math.sin(ar)*d+e*e*8
                if f>=8 and v<1: continue
                shard(px,W,Hh,x,y,ar+(f-2)*0.8,L*(1 if f<6 else 0.7),wd,P['wood'],P['woodL'])
            for a,v in nails:
                if f>=8: continue
                ar=math.radians(a); d=7+v*e*18; x=cx+math.cos(ar)*d; y=cy+math.sin(ar)*d+e*e*7
                ang=ar+f*1.1; x2=x+math.cos(ang)*4; y2=y+math.sin(ang)*4
                line(px,W,Hh,x,y,x2,y2,P['steel']); line(px,W,Hh,x2,y2,x2+math.cos(ang+1.7)*2,y2+math.sin(ang+1.7)*2,P['steel']); put(px,W,Hh,x,y,P['olive'])
        if f in (2,3,4):
            for a in range(0,360,40):
                ar=math.radians(a); r0=12+e*10; line(px,W,Hh,cx+math.cos(ar)*r0,cy+math.sin(ar)*r0,cx+math.cos(ar)*(r0+4),cy+math.sin(ar)*(r0+4),P['hot'] if f<4 else P['ember'])
        fr.append(fin(im,P['ink']))
    return fr

def smear(W,Hh,cx,cy,r,th,a0,a1,cols,f,n):
    """Crescent swing smear between angles a0..a1 (deg), thinning and fading over n frames."""
    im=Image.new('RGBA',(W,Hh),T); px=im.load()
    span=(a1-a0); head=a0+span*min(1,(f+1)/2)   # sweeps in over 2 frames, then dissolves
    tail=a0+span*max(0,(f-1)/(n-1))
    for y in range(Hh):
        for x in range(W):
            d=math.hypot(x-cx,(y-cy)*1.6); a=math.degrees(math.atan2((y-cy)*1.6,x-cx))
            if tail<=a<=head:
                u=(a-tail)/max(head-tail,1)          # 0 at tail -> 1 at head
                t=th*(0.35+0.65*u)*(1-f/(n+1))
                if r-t<=d<=r:
                    c=cols[0] if d>r-t*0.45 else cols[1]
                    px[x,y]=c
    return im

def p_whoosh():
    W,Hh=48,24; fr=[]
    for f in range(5):
        im=smear(W,Hh,8,25,30,10,-88,-8,(P['steel'],P['wood']),f,5)
        fr.append(fin(im,P['ink'],2))
    return fr

def p_trail():
    W,Hh=64,32; cy=16; fr=[]
    for f in range(7):
        im=Image.new('RGBA',(W,Hh),T); px=im.load()
        head=min(60,10+f*14); tail=max(0,(f-2)*12)
        for x in range(int(tail),int(head)):
            u=(x-tail)/max(head-tail,1); hw=0.6+3.2*u*(1-f/9)
            for y in range(int(cy-hw),int(cy+hw)+1):
                d=abs(y-cy)/max(hw,0.5)
                put(px,W,Hh,x,y,P['hot'] if d<0.3 and u>0.6 else P['steel'] if d<0.65 else P['wood'])
        for k,yy in enumerate((cy-6,cy+6)):   # two separated speed clusters
            x0=tail+8+k*10+f*3
            if f<6: line(px,W,Hh,x0,yy,x0+5-f*0.6,yy,P['steel'])
        fr.append(fin(im,P['ink'],2))
    return fr

# ---------------- RICHARD ----------------
td=p2.teardrop
def r_light():
    W=Hh=32; cx,cy=13,16; E=ease(5); fr=[]
    drops=[(-80,0.9,1.7),(-30,1.0,1.9),(20,0.8,1.5)]
    for f in range(5):
        im=Image.new('RGBA',(W,Hh),T); px=im.load(); e=E[f]
        if f==0: disc(px,W,Hh,cx,cy,3,R['yel']); disc(px,W,Hh,cx,cy,1.6,R['core'])
        if f==1: disc(px,W,Hh,cx,cy,4.5,R['org']); disc(px,W,Hh,cx-1,cy-1,3,R['yel']); disc(px,W,Hh,cx-1,cy-1,1.4,R['core'])
        if f>=1:
            for a,v,r in drops:
                ar=math.radians(a); d=5+v*e*9; x=cx+math.cos(ar)*d; y=cy+math.sin(ar)*d+e*e*7
                if f==4 and r<1.8: continue
                vy=math.sin(ar)+e*1.5; td(px,W,Hh,x,y,math.atan2(vy,math.cos(ar)),r*(1 if f<3 else 0.8),R['org'],R['yel'])
        im=fin(im,R['ink']); px=im.load()
        if f in (1,2):
            x,y=cx+7+e*4,cy-6-e*3
            for i in (-2,-1,1,2): put(px,W,Hh,x+i,y,R['core']); put(px,W,Hh,x,y+i,R['core'])
        fr.append(im)
    return fr

def glass(px,W,Hh,x,y,rot,s,tw):
    pts=[(x+math.cos(rot)*3*s,y+math.sin(rot)*3*s),(x+math.cos(rot+2.3)*2*s,y+math.sin(rot+2.3)*2*s),(x+math.cos(rot+4)*2.2*s,y+math.sin(rot+4)*2.2*s)]
    poly(px,W,Hh,pts,R['navy']); put(px,W,Hh,pts[0][0],pts[0][1],R['core'])
    if tw:
        for i in (-2,-1,1,2): put(px,W,Hh,x+i,y,R['core']); put(px,W,Hh,x,y+i,R['core'])

def r_counter():
    W=Hh=40; cx,cy=15,20; E=ease(7); fr=[]
    for f in range(7):
        im=Image.new('RGBA',(W,Hh),T); px=im.load(); e=E[f]
        if f==0: disc(px,W,Hh,cx,cy,4,R['yel']); disc(px,W,Hh,cx,cy,2,R['core'])
        if f in (1,2):
            s=1 if f==1 else 0.8
            disc(px,W,Hh,cx,cy,8*s,R['org']); disc(px,W,Hh,cx-1,cy-1,5.5*s,R['yel']); disc(px,W,Hh,cx-1,cy-1,3*s,R['core'])
        if 2<=f<=4: ring(px,W,Hh,cx,cy,9+e*9,2 if f==2 else 1,R['org'],gaps=None if f==2 else [(30,80),(120,170),(210,260),(300,350)])
        if f>=1:
            for k,a in enumerate((-90,0,90,180)):
                if f==1: continue
                ar=math.radians(a); d=6+e*12; x=cx+math.cos(ar)*d; y=cy+math.sin(ar)*d+e*e*4
                if f==6 and k%2: continue
                td(px,W,Hh,x,y,ar,1.8,R['org'],R['yel'])
        im=fin(im,R['ink']); px=im.load()
        if 1<=f<=5:   # crossed glass glints (the counter "X")
            for a in (-135,-45,45,135):
                ar=math.radians(a); d=5+e*12; glass(px,W,Hh,cx+math.cos(ar)*d,cy+math.sin(ar)*d,ar+f,1.3,f in (1,3,5))
        fr.append(im)
    return fr

def r_block():
    W=Hh=32; cx,cy=13,16; E=ease(5); fr=[]
    for f in range(5):
        im=Image.new('RGBA',(W,Hh),T); px=im.load(); e=E[f]
        if f<=3:
            r=6+e*5; ring(px,W,Hh,cx+3,cy,r,2 if f<2 else 1,R['org'] if f<2 else R['dred'],sy=1.3,gaps=[(270,360),(0,90)])
        if f in (0,1): disc(px,W,Hh,cx,cy,2.2 if f==0 else 1.6,R['yel'])
        if 1<=f<=3:
            x=cx-3-e*5; y=cy-4+e*e*7; td(px,W,Hh,x,y,math.radians(150+e*60),1.4,R['org'],R['yel'])
        im=fin(im,R['ink'],1); px=im.load()
        if f==1: glass(px,W,Hh,cx-2,cy+6,0.5,1,False)
        fr.append(im)
    return fr

def mini_flame(W,Hh,ox,oy,L,f,seed,maxr=9):
    im=Image.new('RGBA',(W,Hh),T); px=im.load()
    for y in range(Hh):
        for x in range(W):
            u=(x-ox)/max(L,1)
            if u<0 or u>1.05: continue
            rad=1.5+maxr*math.sin(min(u,1)*math.pi*0.65)
            top=1+0.3*max(0,math.sin(u*10-f*2))**2
            dy=y-(oy-3*u); rr=rad*(top if dy<0 else 1)
            n=p2.vnoise(x*0.12-f*1.5,y*0.12,seed)
            edge=abs(dy)/rr+(u**3)*0.85+(n-0.5)*0.4
            if edge<1:
                heat=(1-edge)*(1.05-0.45*u)
                px[x,y]=R['core'] if heat>0.62 else R['yel'] if heat>0.42 else R['org'] if heat>0.22 else R['dred']
    return im

def r_special():
    W,Hh=48,32; Ls=[10,26,40,42,36,26,14]; fr=[]
    for f in range(7):
        im=mini_flame(W,Hh,3,18,Ls[f],f,6)
        if f>=4:   # flame lifts off and curls up
            im2=Image.new('RGBA',(W,Hh),T); im2.alpha_composite(im,(0,-(f-3)*2)); im=im2
        fr.append(outline(smooth_colors(despeckle(im,3)),R['ink']))
    return fr

def r_ex():
    W=Hh=48; cx,cy=19,24; E=ease(9); fr=[]
    drops=[(a,v,r) for a,v,r in [(-110,0.8,2.4),(-70,1.0,2.7),(-35,1.0,2.3),(0,0.9,2.5),(35,0.8,2.0),(-150,0.7,2.0),(70,0.6,1.8)]]
    gl=[(-55,1.0),(25,0.9),(-125,0.85),(80,0.7)]
    for f in range(9):
        im=Image.new('RGBA',(W,Hh),T); px=im.load(); e=E[f]
        if f==0: disc(px,W,Hh,cx,cy,5,R['yel']); disc(px,W,Hh,cx,cy,2.8,R['core'])
        if f in (1,2):
            s=1 if f==1 else 0.85
            for k in range(10):
                a=math.radians(k*36); disc(px,W,Hh,cx+math.cos(a)*10*s,cy+math.sin(a)*9*s,3.2*s,R['org'])
            disc(px,W,Hh,cx,cy,10*s,R['org']); disc(px,W,Hh,cx-1,cy-1,7*s,R['yel']); disc(px,W,Hh,cx-1,cy-1,4*s,R['core'])
        if 2<=f<=5: ring(px,W,Hh,cx,cy,12+e*10,2 if f<4 else 1,R['org'],sy=0.85,gaps=None if f<4 else [(20,70),(140,200),(260,310)])
        if f>=3:
            for a,v,r in drops:
                ar=math.radians(a); d=9+v*e*14; x=cx+math.cos(ar)*d; y=cy+math.sin(ar)*d+e*e*10
                if f==8 and r<2.3: continue
                vy=math.sin(ar)+e*1.6; td(px,W,Hh,x,y,math.atan2(vy,math.cos(ar)),r*(1 if f<6 else 0.75),R['org'],R['yel'])
        im=fin(im,R['ink']); px=im.load()
        if 2<=f<=7:
            for a,v in gl:
                ar=math.radians(a); d=8+v*e*16; glass(px,W,Hh,cx+math.cos(ar)*d,cy+math.sin(ar)*d+e*e*6,ar+f*1.1,1.4,f in (2,4,6))
        fr.append(im)
    return fr

def r_whoosh():
    W,Hh=48,24; fr=[]
    for f in range(5):
        im=smear(W,Hh,8,25,30,10,-88,-8,(R['yel'],R['org']),f,5)
        fr.append(fin(im,R['ink'],2))
    return fr

def r_trail():
    W,Hh=64,32; cy=16; fr=[]
    for f in range(7):
        im=Image.new('RGBA',(W,Hh),T); px=im.load()
        head=min(60,10+f*14); tail=max(0,(f-2)*12)
        for x in range(int(tail),int(head)):
            u=(x-tail)/max(head-tail,1); hw=0.6+3.0*u*(1-f/9); wob=math.sin(x*0.35-f*1.4)*2.2*u
            for y in range(int(cy+wob-hw),int(cy+wob+hw)+1):
                d=abs(y-cy-wob)/max(hw,0.5)
                put(px,W,Hh,x,y,R['core'] if d<0.3 and u>0.7 else R['yel'] if d<0.6 else R['org'])
        fr.append(fin(im,R['ink'],2))
    return fr

# ---------------- shared dust ----------------
D=dict(ink=H('#211711'),d1=H('#442C1F'),d2=H('#BF7E4B'),d3=H('#DA9259'))
def dust():
    W,Hh=64,32; cx,base=32,29; fr=[]
    lobes=[(-1,0.3,3.0,0),(-1,0.62,2.6,1),(-1,0.95,2.1,0),(1,0.3,3.0,1),(1,0.62,2.6,0),(1,0.95,2.1,1),(0,0,3.2,0)]
    E=[0.12,0.4,0.66,0.86,1.0]; shrink=[1,1,1,0.7,0.45]
    for f in range(5):
        im=Image.new('RGBA',(W,Hh),T); px=im.load(); e=E[f]
        for sgn,v,r,bob in lobes:
            if f==4 and v==0: continue
            x=cx+sgn*(3+v*e*24); rr=r*(1+0.6*e)*shrink[f]; y=base-rr-e*(2+bob*2)-(f>=3)*(f-2)*1.5
            for yy in range(int(y-rr),int(y+rr)+1):
                for xx in range(int(x-rr*1.3),int(x+rr*1.3)+1):
                    if ((xx-x)/1.3)**2+(yy-y)**2<=rr*rr: put(px,W,Hh,xx,yy,D['d2'])
            disc(px,W,Hh,x-sgn*0.6,y-rr*0.4,rr*0.5,D['d3'])
        fr.append(outline(despeckle(im,3),D['ink']))
    return fr

ALL={
 'peggy_hit_light_sheet':p_light,'peggy_hit_heavy_sheet':p2.peggy_heavy,'peggy_hit_counter_sheet':p_counter,'peggy_block_sheet':p_block,
 'peggy_special_hit_sheet':p_special,'peggy_ex_hit_sheet':p_ex,'peggy_heavy_whoosh_sheet':p_whoosh,'peggy_special_trail_sheet':p_trail,
 'richard_hit_light_sheet':r_light,'richard_hit_heavy_sheet':p2.richard_heavy,'richard_hit_counter_sheet':r_counter,'richard_block_sheet':r_block,
 'richard_special_hit_sheet':r_special,'richard_ex_hit_sheet':r_ex,'richard_heavy_whoosh_sheet':r_whoosh,'richard_special_trail_sheet':r_trail,
 'landing_dust_sheet':dust,'fire_belch_sheet':p2.fire_belch}
import json; meta={}
for name,fn in ALL.items():
    fr=fn(); s=sheet(fr); s.save(OUT+name+'.png')
    meta[name]={'cell':list(fr[0].size),'frames':len(fr),'ticks_per_frame':3 if name=='landing_dust_sheet' else 2}
json.dump(meta,open(OUT+'fx_manifest.json','w'),indent=1)
print(json.dumps(meta))
