import math, random
from PIL import Image
H=lambda s: tuple(int(s[i:i+2],16) for i in (1,3,5))+(255,)
T=(0,0,0,0)

def outline(img, col, diag=False):
    w,h=img.size; px=img.load(); out=img.copy(); o=out.load()
    nb=[(1,0),(-1,0),(0,1),(0,-1)]+([(1,1),(-1,-1),(1,-1),(-1,1)] if diag else [])
    for y in range(h):
        for x in range(w):
            if px[x,y][3]==0:
                for dx,dy in nb:
                    X,Y=x+dx,y+dy
                    if 0<=X<w and 0<=Y<h and px[X,Y][3] and px[X,Y]!=col:
                        o[x,y]=col; break
    return out

def put(px,w,h,x,y,c):
    x=int(round(x)); y=int(round(y))
    if 0<=x<w and 0<=y<h: px[x,y]=c

def line(px,w,h,x0,y0,x1,y1,c):
    n=int(max(abs(x1-x0),abs(y1-y0)))+1
    for i in range(n):
        t=i/max(n-1,1); put(px,w,h,x0+(x1-x0)*t,y0+(y1-y0)*t,c)

def disc(px,w,h,cx,cy,r,c):
    for y in range(int(cy-r)-1,int(cy+r)+2):
        for x in range(int(cx-r)-1,int(cx+r)+2):
            if (x-cx)**2+(y-cy)**2<=r*r: put(px,w,h,x,y,c)

def star(px,w,h,cx,cy,r_in,r_out,n,rot,c):
    # filled star polygon via angle test
    for y in range(int(cy-r_out)-1,int(cy+r_out)+2):
        for x in range(int(cx-r_out)-1,int(cx+r_out)+2):
            dx,dy=x-cx,y-cy; d=math.hypot(dx,dy)
            a=(math.atan2(dy,dx)-rot)%(2*math.pi/n)/(2*math.pi/n)
            lim=r_in+(r_out-r_in)*(1-abs(a-0.5)*2)
            if d<=lim: put(px,w,h,x,y,c)

def sheet(frames):
    w,h=frames[0].size; s=Image.new("RGBA",(w*len(frames),h),T)
    for i,f in enumerate(frames): s.alpha_composite(f,(i*w,0))
    return s

def despeckle(img, min_px=3):
    """Remove 8-connected opaque islands smaller than min_px (kills noisy single pixels)."""
    w,h=img.size; px=img.load(); seen=set(); out=img.copy(); o=out.load()
    for y in range(h):
        for x in range(w):
            if px[x,y][3] and (x,y) not in seen:
                comp=[(x,y)]; seen.add((x,y)); i=0
                while i<len(comp):
                    cx,cy=comp[i]; i+=1
                    for dx in (-1,0,1):
                        for dy in (-1,0,1):
                            X,Y=cx+dx,cy+dy
                            if 0<=X<w and 0<=Y<h and px[X,Y][3] and (X,Y) not in seen:
                                seen.add((X,Y)); comp.append((X,Y))
                if len(comp)<min_px:
                    for p in comp: o[p]=(0,0,0,0)
    return out

def smooth_colors(img, passes=1):
    """Majority filter on colour bands inside the shape: removes 1-px colour noise, keeps silhouette."""
    for _ in range(passes):
        w,h=img.size; px=img.load(); out=img.copy(); o=out.load()
        for y in range(1,h-1):
            for x in range(1,w-1):
                if not px[x,y][3]: continue
                cnt={}
                for dx in (-1,0,1):
                    for dy in (-1,0,1):
                        c=px[x+dx,y+dy]
                        if c[3]: cnt[c]=cnt.get(c,0)+1
                best=max(cnt,key=cnt.get)
                if cnt[best]>=5 and best!=px[x,y]: o[x,y]=best
        img=out
    return img

def poly(px,w,h,pts,c):
    xs=[p[0] for p in pts]; ys=[p[1] for p in pts]
    for y in range(int(min(ys))-1,int(max(ys))+2):
        for x in range(int(min(xs))-1,int(max(xs))+2):
            ins=False; j=len(pts)-1
            for i in range(len(pts)):
                xi,yi=pts[i]; xj,yj=pts[j]
                if (yi>y)!=(yj>y) and x < (xj-xi)*(y-yi)/((yj-yi) or 1e-9)+xi: ins=not ins
                j=i
            if ins: put(px,w,h,x,y,c)

def ring(px,w,h,cx,cy,r,th,c,sy=1.0,gaps=None):
    for y in range(int(cy-r*sy)-2,int(cy+r*sy)+3):
        for x in range(int(cx-r)-2,int(cx+r)+3):
            d=math.hypot(x-cx,(y-cy)/sy)
            if r-th<=d<=r:
                if gaps:
                    a=math.degrees(math.atan2(y-cy,x-cx))%360
                    if any(g0<=a<=g1 for g0,g1 in gaps): continue
                put(px,w,h,x,y,c)

def shard(px,w,h,x,y,ang,L,wid,c,hi):
    """Tapered shard: wide at tail, point at head, 1-px highlight on top edge."""
    cs,sn=math.cos(ang),math.sin(ang); nx,ny=-sn,cs
    tip=(x+cs*L,y+sn*L); a=(x+nx*wid,y+ny*wid); b=(x-nx*wid,y-ny*wid)
    poly(px,w,h,[a,tip,b],c); line(px,w,h,x+nx*wid*0.4,y+ny*wid*0.4,tip[0],tip[1],hi)
