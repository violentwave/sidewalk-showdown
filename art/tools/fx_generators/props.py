import sys, math, random, json, os
sys.path.insert(0,'/home/claude/fxgen')
from fx import *
from PIL import Image
O='/home/claude/fxgen/props/'
import importlib.util
spec=importlib.util.spec_from_file_location('p2','/home/claude/fxgen/pilot2.py'); p2=importlib.util.module_from_spec(spec); spec.loader.exec_module(p2)
vnoise=p2.vnoise
# Peggy wood/hardware palette (P-FX + P-ACCENT)
ink=H('#211711'); dk=H('#251913'); dk2=H('#2F1D14'); sh=H('#442C1F'); olive=H('#464834'); rust=H('#70281D')
wood=H('#BF7E4B'); woodM=H('#CD854F'); woodL=H('#DA9259'); woodH=H('#DD965D'); steel=H('#C9D1CC'); hot=H('#FFF2B3')
# Richard palette (R-FX + R-ACCENT)
r_blk=H('#0B0200'); r_ink=H('#28140C'); r_dred=H('#731711'); r_red=H('#89281C'); r_amb=H('#CB8A60'); r_ambL=H('#DDA074')
r_cream=H('#E3CEB4'); r_navy=H('#273645'); r_navyD=H('#1F2B3A'); r_org=H('#F16A2D'); r_yel=H('#FFD34F'); r_core=H('#FFF2DA')

def render(W,Hh,shapes):
    """shapes: list of (local_color_fn, cx, cy, ang, (lx0,ly0,lx1,ly1)) -> inverse-mapped nearest render."""
    im=Image.new('RGBA',(W,Hh),T); px=im.load()
    for fn,cx,cy,ang,(lx0,ly0,lx1,ly1) in shapes:
        ca,sa=math.cos(-ang),math.sin(-ang)
        for y in range(Hh):
            for x in range(W):
                dx,dy=x+0.5-cx,y+0.5-cy
                lx=dx*ca-dy*sa; ly=dx*sa+dy*ca
                if lx0<=lx<lx1 and ly0<=ly<ly1:
                    c=fn(lx,ly)
                    if c: px[x,y]=c
    return im

# ---------------- PLANK (side view, lying on the floor) ----------------
PL=80; PT=9   # length, thickness
def plank_fn(seed=1, cut=None, broken_end_left=True, broken_end_right=True):
    """returns colour fn in plank-local coords: x in [0,PL), y in [0,PT). cut=(x0,x1) keeps a sub-range with a jagged break."""
    def jag(y,s): return 2.5*math.sin(y*2.3+s)+1.5*math.sin(y*5.1+s*2)
    def fn(lx,ly):
        x=lx; y=ly
        if broken_end_left and x < 3+jag(y,seed): return None
        if broken_end_right and x > PL-3-jag(y,seed+3): return None
        if cut:
            a,b=cut
            if x<a+ (jag(y,seed+7) if a>0 else 0) or x>b+ (jag(y,seed+9) if b<PL else 0): return None
        # top face (2 px lighter), side (grain)
        if y<3: return woodH if (int(x)//11)%2==0 else woodL
        if y>=PT-1: return sh
        g=vnoise(x*0.18,y*0.9,seed)
        c=woodM if g>0.62 else wood if g>0.3 else sh
        # duct-tape wrap and nails
        if 24<=x<30: return olive if (int(x) in (24,29) or y>=PT-2) else steel
        if int(x) in (12,56,66) and int(y) in (4,5): return olive
        if int(x) in (12,56,66) and int(y)==3: return steel
        if 0.5< (x*0.37+y*1.3)%7 <1.2 and 3<=y<PT-1: return sh
        return c
    return fn

def plank_base():
    W,Hh=96,32
    im=render(W,Hh,[(plank_fn(),8,20,0,(0,0,PL,PT))])
    return outline(im,ink)

def plank_snap():
    W,Hh=96,32; fr=[]; mid=PL/2
    E=[0,0.15,0.35,0.55,0.72,0.86,1.0]
    for f in range(7):
        e=E[f]
        if f==0:
            im=render(W,Hh,[(plank_fn(),8,20,0,(0,0,PL,PT))]); px=im.load()
            for k in range(3): put(px,W,Hh,8+mid-1+k,20+k*2,hot)   # crack flash
            im=outline(im,ink)
        else:
            drop=e*e*26; ang=math.radians(10+e*55)
            # left half pivots on its left end (down-right), right half mirrored
            Lh=[(plank_fn(cut=(0,mid)),8,20+drop*0.4,ang*0.7,(0,0,mid+4,PT))]
            Rh_fn=plank_fn(cut=(mid,PL))
            # right half: rotate about its right end -> place via negative angle
            Rh=[(lambda lx,ly,fn=Rh_fn: fn(lx+mid,ly), 8+mid+ (mid-mid*math.cos(ang*0.7)) , 20+drop*0.4+ mid*math.sin(ang*0.7), -ang*0.7,(-4,0,mid,PT))]
            im=render(W,Hh,Lh+Rh); px=im.load()
            # splinters burst from the break
            if f<=4:
                rnd=random.Random(3)
                for i in range(6):
                    a=math.radians(rnd.uniform(-160,-20)); d=3+e*16*rnd.uniform(0.6,1.2)
                    x=8+mid+math.cos(a)*d; y=22+math.sin(a)*d+e*e*10
                    shard(px,W,Hh,x,y,a+f,rnd.uniform(2.5,4),1.0,wood,woodL)
            if f==1:
                star(px,W,Hh,8+mid,22,1,6,4,math.radians(45),hot)
            im=outline(despeckle(im,2),ink)
        fr.append(im)
    return fr

# ---------------- SEWER OPENING (back layer) + RIM/SPLASH (front layer) ----------------
SW,SH=96,64; ECX,ECY=48,46
def sewer_back():
    fr=[]; widths=[4,14,28,42,54,62,64]
    for f in range(7):
        im=Image.new('RGBA',(SW,SH),T); px=im.load(); rx=widths[f]/2+0.01; ry=max(1.2,rx*0.28)
        for y in range(SH):
            for x in range(SW):
                d=((x-ECX)/rx)**2+((y-ECY)/ry)**2
                if d<=1:
                    if d>0.72 and y<ECY: px[x,y]=olive          # back rim (lit concrete lip)
                    elif d>0.72: px[x,y]=sh
                    else:
                        # inner shaft: darker toward the back, a murky water glint at the bottom
                        px[x,y]=dk if y<ECY-ry*0.2 else ink
        if f>=3:   # faint water glints deep inside
            for gx in (-8,3,11):
                if abs(gx)<rx*0.6: put(px,SW,SH,ECX+gx,ECY+ry*0.25,olive); put(px,SW,SH,ECX+gx+1,ECY+ry*0.25,steel if f>=5 else olive)
        fr.append(outline(im,ink) if f>0 else outline(im,ink))
    return fr

def sewer_front():
    """front rim arc only (draws OVER the victim) plus a murky splash crown when the victim drops in."""
    fr=[]; rx=32; ry=rx*0.28
    splash=[0,0,0.3,1.0,0.8,0.45,0.15]
    for f in range(7):
        im=Image.new('RGBA',(SW,SH),T); px=im.load()
        for y in range(SH):
            for x in range(SW):
                d=((x-ECX)/rx)**2+((y-ECY)/ry)**2
                if y>=ECY-0.5 and 0.72<d<=1.25: px[x,y]=olive if d<1.0 else sh   # front lip
        s=splash[f]
        if s>0:
            # crown: overlapping blobs, tallest in the middle, olive water with steel highlights
            for k in range(-4,5):
                h=s*(20-abs(k)*3.6); x0=ECX+k*5.2
                if h<2: continue
                for t in range(0,int(h),2): disc(px,SW,SH,x0,ECY-2-t,2.2-0.12*abs(k),olive)
                disc(px,SW,SH,x0,ECY-2-h,2.6-0.15*abs(k),olive); put(px,SW,SH,x0-1,ECY-3-h,steel)
            disc(px,SW,SH,ECX,ECY-3,8*s,olive)
        if f>=3:   # droplets flung outward, falling back
            e=(f-3)/3
            for k,(a,v) in enumerate([(-150,1.0),(-120,1.2),(-60,1.2),(-30,1.0),(-90,1.4)]):
                ar=math.radians(a); d=10+v*e*16; x=ECX+math.cos(ar)*d; y=ECY-14+math.sin(ar)*d*0.6+e*e*16
                disc(px,SW,SH,x,y,1.6,olive); put(px,SW,SH,x-0.6,y-0.6,steel)
        fr.append(outline(despeckle(im,2),ink))
    return fr

# ---------------- WHISKEY FUMES (R-FX only, dithered, no partial alpha) ----------------
BAYER=[[0,8,2,10],[12,4,14,6],[3,11,1,9],[15,7,13,5]]
def fumes():
    W,Hh=128,96; ox,oy=10,72; fr=[]
    # puff path from the bottle, billowing up and to the right
    path=[(0.00,0,0,7),(0.12,10,-6,9),(0.24,22,-14,12),(0.36,36,-20,14),(0.48,52,-24,15),(0.6,68,-26,16),(0.72,84,-24,15),(0.84,98,-18,13),(0.92,108,-30,10),(0.55,44,-40,11),(0.7,72,-46,10)]
    grow=[0.18,0.36,0.56,0.76,0.92,1.0,1.0]
    for f in range(7):
        im=Image.new('RGBA',(W,Hh),T); px=im.load(); g=grow[f]
        field={}
        for t0,dx,dy,r in path:
            if t0>g: continue
            k=min(1,(g-t0)/0.25)               # each puff inflates after it spawns
            rr=r*(0.4+0.6*k)*(1.08 if f==6 else 1)
            cx,cy=ox+dx,oy+dy-f*1.5
            for y in range(int(cy-rr)-1,int(cy+rr)+2):
                for x in range(int(cx-rr)-1,int(cx+rr)+2):
                    d=math.hypot(x-cx,y-cy)/rr
                    if d<1: field[(x,y)]=max(field.get((x,y),0),1-d)
        for (x,y),v in field.items():
            if not(0<=x<W and 0<=y<Hh): continue
            n=vnoise(x*0.12+f*0.3,y*0.12,8)
            v=v*(0.85+0.3*n) - (0.18 if f==6 else 0)
            cover=0.35 if v<0.18 else 0.6 if v<0.4 else 0.8      # translucency via ordered dither
            if BAYER[y%4][x%4]/16 >= cover: continue
            c=r_amb
            if v>0.45: c=r_ambL
            if v>0.62 and n>0.5: c=r_cream
            px[x,y]=c
        fr.append(despeckle(im,3))
    return fr

# ---------------- BAR SIGN (generic, no text) ----------------
BW,BH=96,48
def sign_img():
    im=Image.new('RGBA',(BW,BH),T); px=im.load()
    x0,y0,x1,y1=8,10,88,42
    for x in (22,74):  # chains
        for y in range(0,y0):
            put(px,BW,BH,x,y,r_navy if y%3 else r_navyD)
    for y in range(y0,y1):
        for x in range(x0,x1):
            edge=min(x-x0,x1-1-x,y-y0,y1-1-y)
            px[x,y]= r_ink if edge==0 else r_dred if edge<=3 else r_red
    # marquee bulbs around the frame
    for x in range(x0+3,x1-2,5): put(px,BW,BH,x,y0+1,r_yel); put(px,BW,BH,x,y1-2,r_yel)
    for y in range(y0+5,y1-3,5): put(px,BW,BH,x0+1,y,r_yel); put(px,BW,BH,x1-2,y,r_yel)
    # neon cocktail glass icon (generic, no lettering) + neon underline
    gx,gy=48,24
    for i in range(-8,9): put(px,BW,BH,gx+i,gy-6+0,r_org)
    for t in range(9): put(px,BW,BH,gx-8+t,gy-6+t,r_org); put(px,BW,BH,gx+8-t,gy-6+t,r_org)
    for t in range(5): put(px,BW,BH,gx,gy+2+t,r_org)
    for i in range(-4,5): put(px,BW,BH,gx+i,gy+7,r_org)
    disc(px,BW,BH,gx+5,gy-8,1.4,r_yel)   # olive/cherry
    return outline(im,r_blk)

def sign_shatter():
    """Fragments of the sign blown to the right (the victim's travel direction). Returns (back_frames, front_frames)."""
    base=sign_img(); bpx=base.load()
    rnd=random.Random(9)
    # jittered grid -> fragment ids by nearest seed (Voronoi)
    seeds=[(rnd.uniform(10,86),rnd.uniform(11,41)) for _ in range(12)]
    def frag_of(x,y): return min(range(len(seeds)),key=lambda i:(x-seeds[i][0])**2+(y-seeds[i][1])**2)
    motion=[]
    for i,(sx,sy) in enumerate(seeds):
        motion.append(dict(vx=rnd.uniform(0.6,1.6)*(1 if sx>30 else 0.6), vy=rnd.uniform(-1.2,0.4), spin=rnd.uniform(-0.25,0.25),front=(i%2==0)))
    W,Hh=BW,64; back=[]; front=[]
    fid=[[frag_of(x,y) if bpx[x,y][3] else -1 for x in range(BW)] for y in range(BH)]
    for f in range(7):
        t=[0,1,2.2,3.6,5.2,7,9][f]
        layers={True:Image.new('RGBA',(W,Hh),T),False:Image.new('RGBA',(W,Hh),T)}
        lp={k:v.load() for k,v in layers.items()}
        if f==0:
            layers[False].alpha_composite(base,(0,0))
        else:
            for i,(sx,sy) in enumerate(seeds):
                m=motion[i]; ang=m['spin']*t; ca,sa=math.cos(-ang),math.sin(-ang)
                cx=sx+m['vx']*t*4; cy=sy+m['vy']*t*3+0.35*t*t
                for y in range(Hh):
                    for x in range(W):
                        dx,dy=x-cx,y-cy; lx=sx+dx*ca-dy*sa; ly=sy+dx*sa+dy*ca
                        ix,iy=int(round(lx)),int(round(ly))
                        if 0<=ix<BW and 0<=iy<BH and fid[iy][ix]==i:
                            lp[m['front']][x,y]=bpx[ix,iy]
        if f in (1,2):
            p=lp[True]
            star(p,W,Hh,30,26,2,12 if f==1 else 8,4,math.radians(45),r_core)
            for k in range(6):
                a=math.radians(k*60+f*20); d=8+f*6; put(p,W,Hh,30+math.cos(a)*d,26+math.sin(a)*d,r_yel)
        back.append(outline(layers[False],r_blk) if f else layers[False]); front.append(outline(layers[True],r_blk) if f else layers[True])
    return back,front

out={}
def save(name,frames,ticks,anchor,note):
    s=sheet(frames); s.save(O+name+'.png'); out[name]=dict(cell=list(frames[0].size),frames=len(frames),ticks_per_frame=ticks,anchor=anchor,note=note)
pb=plank_base(); pb.save(O+'plank_base.png'); out['plank_base']=dict(cell=[96,32],frames=1,anchor=[8,27],note='plank lies on the floor; anchor = left end at floor contact')
save('plank_snap_sheet',plank_snap(),3,[48,27],'snaps at its middle; halves fall into the sewer opening')
save('sewer_open_sheet',sewer_back(),3,[48,46],'BACK layer: draw behind the victim; anchor = opening centre on the floor line')
save('water_drop_mask_sheet',sewer_front(),2,[48,46],'FRONT layer: front rim + murky splash; draw over the victim; clip the victim below the front rim arc')
save('whiskey_fumes_sheet',fumes(),3,[10,70],'dithered gas, no outline; anchor = bottle mouth; grows up-right')
sign_img().save(O+'fictional_bar_sign_base.png'); out['fictional_bar_sign_base']=dict(cell=[96,48],frames=1,anchor=[48,26],note='generic bar sign, no text; hangs from two chains')
b,fr=sign_shatter()
save('bar_sign_shatter_back_sheet',b,2,[48,26],'BACK layer: rear fragments, draw behind the victim')
save('bar_sign_shatter_front_sheet',fr,2,[48,26],'FRONT layer: front fragments + impact flash, draw over the victim')
json.dump(out,open(O+'props_manifest.json','w'),indent=1)
print(json.dumps({k:(v['cell'],v['frames']) for k,v in out.items()}))
