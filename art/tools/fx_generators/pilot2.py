import sys, math, random
sys.path.insert(0,'/home/claude/fxgen')
from fx import *
from PIL import Image
OUT='/home/claude/fxgen/out2/'; import os; os.makedirs(OUT,exist_ok=True)

# timing curve: fast start, slow settle (ease-out), per frame index 0..6
EASE=[0.0,0.18,0.42,0.62,0.78,0.9,1.0]

# ============ PEGGY heavy: hardware impact ============
P=dict(ink=H('#211711'),dk=H('#2F1D14'),brn=H('#442C1F'),wood=H('#BF7E4B'),woodL=H('#DA9259'),
       olive=H('#464834'),steel=H('#C9D1CC'),hot=H('#FFF2B3'),ember=H('#E9822A'))
def peggy_heavy():
    W=Hh=40; cx,cy=15,20  # bigger canvas so debris never clips
    shards=[(-28,1.0,5,1.6),(8,1.15,6,1.8),(38,0.95,5,1.4),(-62,0.8,4,1.2),(70,0.75,4,1.2)]  # deg, speed, len, width
    nails=[(-12,0.9),(52,0.85)]
    sparks=[-45,-15,15,45,80,-80]
    frames=[]
    for f in range(7):
        im=Image.new('RGBA',(W,Hh),T); px=im.load(); e=EASE[f]
        if f==0:   # anticipation pop
            star(px,W,Hh,cx,cy,1.5,6,4,math.radians(45),P['steel']); star(px,W,Hh,cx,cy,1,3.5,4,math.radians(45),P['hot'])
        if f==1:   # the HIT frame: big 8-point burst, layered
            star(px,W,Hh,cx,cy,4,14,8,0,P['ember'])
            star(px,W,Hh,cx,cy,3,11,8,0,P['steel'])
            star(px,W,Hh,cx,cy,2.5,8,4,0,P['hot']); disc(px,W,Hh,cx,cy,3.2,P['hot'])
        if f==2:   # burst collapses to a sharp cross, shockwave ring
            ring(px,W,Hh,cx,cy,10,1.6,P['steel'],sy=0.8)
            star(px,W,Hh,cx,cy,1.5,7,4,0,P['ember']); star(px,W,Hh,cx,cy,1,4.5,4,0,P['hot'])
        if f==3:
            ring(px,W,Hh,cx,cy,14,1.2,P['steel'],sy=0.8,gaps=[(30,80),(150,200),(250,300)])
        if f==4:
            ring(px,W,Hh,cx,cy,16.5,1.0,P['olive'],sy=0.8,gaps=[(0,60),(100,170),(200,330)])
        # speed sparks (frames 2-3): short streaks radiating, biased forward
        if f in (2,3):
            for a in sparks:
                r0=7+e*10; r1=r0+(5 if f==2 else 3); ar=math.radians(a)
                line(px,W,Hh,cx+math.cos(ar)*r0,cy+math.sin(ar)*r0,cx+math.cos(ar)*r1,cy+math.sin(ar)*r1,P['hot'] if f==2 else P['ember'])
        # debris (frames 2-6): chunky shards with highlight, gravity, spin
        if f>=2:
            for a,v,L,wd in shards:
                d=5+v*e*17; ar=math.radians(a)
                x=cx+math.cos(ar)*d; y=cy+math.sin(ar)*d+ (e**2)*7
                spin=ar+ (f-2)*0.9*(1 if a>0 else -1)
                s=1 if f<5 else 0.75
                if f==6 and v<1.0: continue
                shard(px,W,Hh,x,y,spin,L*s,wd*s,P['wood'],P['woodL'])
            for a,v in nails:
                if f>=6: continue
                d=5+v*e*15; ar=math.radians(a); x=cx+math.cos(ar)*d; y=cy+math.sin(ar)*d+(e**2)*6
                ang=ar+(f-2)*1.2; x2=x+math.cos(ang)*3.5; y2=y+math.sin(ang)*3.5
                line(px,W,Hh,x,y,x2,y2,P['steel']); line(px,W,Hh,x2,y2,x2+math.cos(ang+1.7)*1.8,y2+math.sin(ang+1.7)*1.8,P['steel'])
                put(px,W,Hh,x,y,P['olive'])
        if f==5:   # little dust puff left behind
            r=2.5+ (f-5)*1.2
            for (ox2,oy2,rf) in [(-2,1,1.0),(2,-1,0.8),(0,-3,0.6)]:
                disc(px,W,Hh,cx+ox2,cy+oy2,r*rf,P['wood']); disc(px,W,Hh,cx+ox2-0.7,cy+oy2-0.7,r*rf*0.5,P['woodL'])
            if f==6:
                for y in range(Hh):
                    for x in range(W):
                        if px[x,y] in (P['wood'],P['woodL']) and (x+y)%2: px[x,y]=T
        im=despeckle(im,2); frames.append(outline(im,P['ink']))
    return frames

# ============ RICHARD heavy: whiskey splash + bottle glass ============
R=dict(ink=H('#731711'),dred=H('#89281C'),org=H('#F16A2D'),yel=H('#FFD34F'),cream=H('#E3CEB4'),
       core=H('#FFF2DA'),navy=H('#273645'),navyL=H('#1F2B3A'))
def teardrop(px,W,Hh,x,y,ang,r,c,hi):
    disc(px,W,Hh,x,y,r,c); tx=x-math.cos(ang)*r*2.2; ty=y-math.sin(ang)*r*2.2
    nx,ny=-math.sin(ang),math.cos(ang)
    poly(px,W,Hh,[(x+nx*r*0.9,y+ny*r*0.9),(tx,ty),(x-nx*r*0.9,y-ny*r*0.9)],c)
    put(px,W,Hh,x+math.cos(ang)*r*0.3-0.6,y-0.8,hi)
def richard_heavy():
    W=Hh=40; cx,cy=15,20
    drops=[(-105,0.8,2.2),(-65,0.95,2.5),(-30,0.95,2.1),(5,0.85,2.3),(35,0.7,1.8),(-140,0.6,1.8)]
    glass=[(-55,1.05),(30,0.95),(-20,1.3)]
    frames=[]
    for f in range(7):
        im=Image.new('RGBA',(W,Hh),T); px=im.load(); e=EASE[f]
        if f==0:
            disc(px,W,Hh,cx,cy,3.6,R['yel']); disc(px,W,Hh,cx,cy,2,R['core'])
        if f==1:   # HIT frame: splash body + white core flash
            for k in range(8):
                a=math.radians(-90+(k-3.5)*26); disc(px,W,Hh,cx+math.cos(a)*7,cy+math.sin(a)*6.2,2.8,R['org'])
            disc(px,W,Hh,cx,cy,7,R['org']); disc(px,W,Hh,cx-1,cy-1,5,R['yel']); disc(px,W,Hh,cx-1,cy-1,2.6,R['core'])
        if f==2:   # crown opens into a ring of liquid
            ring(px,W,Hh,cx,cy,9,2.4,R['org'],sy=0.85,gaps=[(60,120)])
            ring(px,W,Hh,cx,cy,9,1,R['yel'],sy=0.85,gaps=[(0,200),(340,360)])
            disc(px,W,Hh,cx,cy,2.5,R['org'])
        if f>=2:   # teardrops flying, then falling
            for a,v,r in drops:
                ar=math.radians(a); d=7+v*e*11; x=cx+math.cos(ar)*d; y=cy+math.sin(ar)*d+(e**2)*9
                vx=math.cos(ar); vy=math.sin(ar)+e*1.6; ang=math.atan2(vy,vx)
                rr=r*(1.0 if f<4 else 0.8 if f<6 else 0.6)
                if f==6 and r<2.0: continue
                teardrop(px,W,Hh,x,y,ang,rr,R['org'],R['yel'])
        im=despeckle(im,2); im=outline(im,R['ink']); px=im.load()
        if 2<=f<=5:  # glass shards: small navy triangles with cream glint, drawn crisp on top
            for a,v in glass:
                ar=math.radians(a); d=6+v*e*14; x=cx+math.cos(ar)*d; y=cy+math.sin(ar)*d+(e**2)*5
                rot=ar+f*1.1
                pts=[(x+math.cos(rot)*3,y+math.sin(rot)*3),(x+math.cos(rot+2.3)*2,y+math.sin(rot+2.3)*2),(x+math.cos(rot+4)*2.2,y+math.sin(rot+4)*2.2)]
                poly(px,W,Hh,pts,R['navy']); put(px,W,Hh,pts[0][0],pts[0][1],R['core'])
                if f in (2,4):   # twinkle
                    for i in (-2,-1,1,2): put(px,W,Hh,x+i,y,R['core']); put(px,W,Hh,x,y+i,R['core'])
        frames.append(im)
    return frames

# ============ FIRE BELCH: clean flame tongues ============
F=dict(ink=H('#731711'),red=H('#89281C'),org=H('#F16A2D'),yel=H('#FFD34F'),core=H('#FFF2DA'),smk=H('#273645'),smk2=H('#1F2B3A'))
def vnoise(x,y,seed):
    def r(i,j):
        n=(i*374761393+j*668265263+seed*144665)&0xffffffff; n=(n^(n>>13))*1274126177&0xffffffff
        return (n&0xffff)/65535
    i,j=int(math.floor(x)),int(math.floor(y)); fx,fy=x-i,y-j
    fx=fx*fx*(3-2*fx); fy=fy*fy*(3-2*fy)
    a=r(i,j)*(1-fx)+r(i+1,j)*fx; b=r(i,j+1)*(1-fx)+r(i+1,j+1)*fx
    return a*(1-fy)+b*fy
def fire_belch():
    W,Hh=104,64; ox,oy=3,36
    L=[18,48,82,96,96,84,66]; detach=[0,0,0,0,0.18,0.42,0.7]
    frames=[]
    for f in range(7):
        im=Image.new('RGBA',(W,Hh),T); px=im.load()
        for y in range(Hh):
            for x in range(W):
                u=(x-ox)/L[f]
                if u<0 or u>1.08: continue
                env=math.sin(min(u,1)*math.pi*0.6)**0.8          # flare
                rad=2.5+20*env
                # tongues: travelling bumps on the top edge, smaller on bottom
                top=1+0.32*max(0,math.sin(u*14-f*2.2))**2
                bot=1+0.12*max(0,math.sin(u*11-f*1.7+1))**2
                cyl=oy-5*u                                        # rises slightly
                dy=(y-cyl); rr=rad*(top if dy<0 else bot)
                n=vnoise(x*0.09-f*1.4,y*0.09,4)
                edge=abs(dy)/rr + (u**3)*0.85 + (n-0.5)*0.45
                if detach[f] and u<detach[f]: edge+= (detach[f]-u)*3.5   # flame leaves the mouth
                if edge<1:
                    heat=(1-edge)*(1.05-0.45*u)
                    c=F['core'] if heat>0.62 else F['yel'] if heat>0.42 else F['org'] if heat>0.22 else F['red']
                    px[x,y]=c
        # smoke puffs trailing above the tail in late frames
        if f>=4:
            for k,(sx,sy,sr) in enumerate([(0.75,-0.55,4),(0.92,-0.35,5),(0.55,-0.7,3)]):
                if f-4<k: continue
                x=ox+L[f]*sx; y=oy-5*sx+sy*22-(f-4)*3
                for yy in range(int(y-sr),int(y+sr)+1):
                    for xx in range(int(x-sr),int(x+sr)+1):
                        if (xx-x)**2+(yy-y)**2<=sr*sr and not px[xx,yy][3] if 0<=xx<W and 0<=yy<Hh else False:
                            put(px,W,Hh,xx,yy,F['smk2'] if (yy-y)>sr*0.2 else F['smk'])
        im=smooth_colors(im,1); im=despeckle(im,4); frames.append(outline(im,F['ink']))
    return frames

for name,fr in [('peggy_hit_heavy_sheet',peggy_heavy()),('richard_hit_heavy_sheet',richard_heavy()),('fire_belch_sheet',fire_belch())]:
    s=sheet(fr); s.save(OUT+name+'.png'); s.resize((s.width*4,s.height*4),Image.NEAREST).save(OUT+name+'_4x.png')
print('done')
