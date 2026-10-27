#!/usr/bin/env python3
"""Rebuild handwritten SVG sources and exact-size PNGs. Stdlib + system librsvg/cairo.
Run python art/build_assets.py from any directory. No Python dependencies required.
"""
from pathlib import Path
import ctypes as C, ctypes.util, math, json
ROOT=Path(__file__).resolve().parent; OUT=ROOT.parent/'game/assets'; SRC=ROOT/'src'; QA=ROOT/'qa'
for d in [SRC,QA,OUT/'sprites/scenery',OUT/'ui']: d.mkdir(parents=True,exist_ok=True)
cream='#F4EBDD'; terra='#C8643B'; sea='#8FC9B9'; deep='#1F6F8B'; sand='#E8D3A8'; lemon='#F2C14E'; olive='#7A8B4A'
assets=[]
def path(d,f,stroke=None,sw=2,extra=''):
 return f'<path d="{d}" fill="{f}"'+(f' stroke="{stroke}" stroke-width="{sw}"' if stroke else '')+f' {extra}/>'
def ellipse(x,y,rx,ry,f,extra=''): return f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="{f}" {extra}/>'
def rect(x,y,w,h,f,r=0,extra=''): return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{f}" {extra}/>'
def line(d,f=deep,w=2): return path(d,'none',f,w)
def svg(w,h,b): return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}"><g stroke-linecap="round" stroke-linejoin="round">{b}</g></svg>'
rsvg=C.CDLL(ctypes.util.find_library('rsvg-2')); cairo=C.CDLL(ctypes.util.find_library('cairo')); glib=C.CDLL(ctypes.util.find_library('gobject-2.0'))
def bind(lib,name,args,ret):
 fn=getattr(lib,name);fn.argtypes=args;fn.restype=ret;return fn
new=bind(rsvg,'rsvg_handle_new_from_data',[C.c_char_p,C.c_size_t,C.c_void_p],C.c_void_p)
render=bind(rsvg,'rsvg_handle_render_cairo',[C.c_void_p,C.c_void_p],C.c_int)
surface=bind(cairo,'cairo_image_surface_create',[C.c_int,C.c_int,C.c_int],C.c_void_p); context=bind(cairo,'cairo_create',[C.c_void_p],C.c_void_p)
write=bind(cairo,'cairo_surface_write_to_png',[C.c_void_p,C.c_char_p],C.c_int)
dc=bind(cairo,'cairo_destroy',[C.c_void_p],None);ds=bind(cairo,'cairo_surface_destroy',[C.c_void_p],None);unref=bind(glib,'g_object_unref',[C.c_void_p],None)
def raster(text,file,w,h):
 b=text.encode(); handle=new(b,len(b),None); assert handle
 s=surface(0,w,h); c=context(s);assert render(handle,c);assert write(s,str(file).encode())==0;dc(c);ds(s);unref(handle)
def add(name,w,h,b,folder='sprites'):
 text=svg(w,h,b); (SRC/(name+'.svg')).write_text(text); dest=OUT/folder/(name+'.png');raster(text,dest,w,h);assets.append(dict(file=str(dest.relative_to(OUT)),w=w,h=h,body=b))
# Thin vertical twin-tip; asymmetric heel-side lean, separated knees and hands.
board=path('M47 6 Q51 2 55 6 L55 64 Q51 69 47 64Z',deep,cream,1)+line('M49 9 L49 61',sea,1.5)+rect(47,20,8,5,cream,2)+rect(47,47,8,5,cream,2)+line('M48 13 L54 13 M48 57 L54 57',terra,3)
rider=board+line('M50 22 L36 19 L26 30 M50 49 L36 46 L26 38',sand,4)+line('M48 22 L52 22 M48 49 L52 49',deep,2)+path('M17 25 Q24 22 29 29 L30 38 L19 42 L14 33Z',deep)+path('M18 26 L25 25 L28 33 L18 36Z',sea)+line('M20 39 L28 37',terra,3)+line('M16 29 L12 29',sand,5)+line('M22 26 L28 16 M28 34 L35 23',terra,4)+line('M28 16 L35 20 M35 23 L47 20',sand,2.8)+line('M35 17 L59 17',deep,6)+line('M35 17 L59 17',cream,3)+line('M54 17 L59 17',terra,3)+ellipse(10,29,7,7,sand)+ellipse(9,27,6.5,6.5,lemon)+path('M4 26 Q8 21 13 25','none',cream,1.6)
add('rider',72,72,rider)
add('rider_wipeout',72,72,line('M5 34 Q10 18 29 21 M7 48 Q18 59 32 51 M43 10 Q63 5 68 21',cream,2)+f'<g transform="translate(25 -3) rotate(18 15 36) scale(.65)">{board}</g>'+line('M20 36 L10 44 M25 39 L34 51 M18 31 L7 25 M25 31 L34 24',sand,4)+ellipse(22,35,7,10,deep)+ellipse(20,21,6,6,lemon))
for name,color in [('sunset',terra),('seaglass',sea),('olive',olive),('lemon',lemon)]:
 b=path('M6 58 C13 2 127 2 134 58 C104 39 36 39 6 58Z',color,deep,1.6)
 b+=path('M30 43 Q34 16 47 13 L55 39Z',cream)+path('M85 39 L93 13 Q108 17 110 44Z',cream)
 for x in [28,49,70,91,112]: b+=line(f'M{x} {42 if x!=70 else 39} Q{x} 22 {70+(x-70)*.82} {11+abs(x-70)*.17}',deep,1.2)
 b+=path('M6 58 C38 35 102 35 134 58','none',color,7)+path('M9 55 C40 36 100 36 131 55','none',cream,1.2)
 add('kite_'+name,140,70,b)
add('buoy',40,40,ellipse(20,22,17,16,terra)+path('M4 21 Q20 28 36 21 L35 27 Q20 34 5 27Z',cream)+ellipse(17,14,9,5,'#E58B64')+ellipse(20,10,3,3,deep))
def rocks(big=False):
 w,h=(140,110) if big else (70,60);b=path(f'M3 {h*.55} Q0 {h*.22} {w*.3} {h*.15} Q{w*.6} 0 {w*.85} {h*.3} Q{w+5} {h*.65} {w*.75} {h*.88} Q{w*.43} {h+3} {w*.2} {h*.85}Z',sea,extra='opacity=".42"')
 for x,y,r in ([(46,48,32),(91,58,30),(70,29,20)] if big else [(33,28,24)]):
  b+=path(f'M{x-r} {y+7} L{x-r*.7} {y-r*.6} Q{x} {y-r} {x+r*.7} {y-r*.4} L{x+r} {y+10} L{x+6} {y+r*.7}Z','#ADA88C', '#777C70',1.5)+path(f'M{x-r*.7} {y-r*.6} L{x} {y-r*.5} L{x+4} {y+3} L{x-r} {y+7}Z','#D2C9AC')
 return b
add('rock_small',70,60,rocks());add('rock_big',140,110,rocks(True))
b=ellipse(30,12,8,10,sea)+path('M17 27 Q0 16 7 38 L19 43 M43 27 Q60 16 53 38 L41 43 M19 48 Q7 65 22 60 M41 48 Q53 65 38 60',sea,deep,1.4)+ellipse(30,38,19,25,olive)+path('M30 17 L41 29 L38 45 L30 55 L21 45 L19 29Z','#98A363',deep,1)+line('M20 29 L40 45 M40 29 L20 45 M30 18 L30 56', '#657645',1.2)+line('M25 10 L28 11 M32 11 L35 10',deep,1)
add('turtle',60,70,b)
def hull(w,h,color):
 return path(f'M{w/2} 5 Q{w-4} {h*.2} {w-7} {h*.66} L{w-12} {h-9} Q{w/2} {h+1} 12 {h-9} L7 {h*.66} Q4 {h*.2} {w/2} 5Z',color,deep,2)
b=hull(70,160,cream)+path('M35 16 Q60 49 57 96 L54 141 L16 141 L13 96 Q10 49 35 16Z',terra)+line('M22 45 L48 45 M16 114 L54 114 M17 133 L53 133',sand,4)+rect(21,66,28,33,cream,4)+rect(25,70,20,12,deep,2)+ellipse(24,124,10,14,olive)
for y in range(114,137,5):b+=line(f'M16 {y} L33 {y+3}',sea,1)
b+=line('M51 20 L51 58',deep,2);add('boat_fishing',70,160,b)
add('jetski',44,90,hull(44,90,cream)+path('M22 10 Q37 25 34 55 L10 55 Q7 25 22 10Z',terra)+rect(15,39,14,34,deep,6)+ellipse(22,30,10,7,sea)+line('M9 41 L35 41',deep,3))
add('sailboat',80,180,hull(80,180,cream)+path('M40 14 Q66 47 64 132 L16 132 Q14 47 40 14Z',sand)+rect(26,105,28,41,deep,5)+line('M40 28 L40 156',terra,3)+path('M37 31 L9 112 Q24 123 37 119Z','#FFFFFF',deep,1)+path('M44 40 Q71 74 72 107 L44 114Z',sea,deep,1)+line('M14 155 L66 155',terra,3))
def shell(scale=1):
 return '<g transform="scale('+str(scale)+')">'+path('M7 26 C-5 16 4 5 9 8 C10 0 19 0 21 6 C30 2 37 16 25 26 L22 29 L10 29Z',cream,terra,1.4)+line('M15 25 L7 12 M17 25 L15 6 M19 25 L24 10',terra,1.3)+rect(11,25,11,5,terra,2)+'</g>'
add('shell',32,32,shell());add('icon_shell',48,48,shell(1.5),'ui')
pts=[]
for i in range(10):
 a=-math.pi/2+i*math.pi/5;r=18 if i%2==0 else 8;pts.append(f'{20+math.cos(a)*r:.2f},{20+math.sin(a)*r:.2f}')
add('starfish',40,40,f'<polygon points="{" ".join(pts)}" fill="{terra}" stroke="{lemon}" stroke-width="2" stroke-linejoin="round"/>'+ellipse(19,18,3,3,lemon))
add('gust',80,80,line('M8 29 L53 29 C79 29 72 5 58 14 M14 42 L65 42 C82 42 75 65 63 57 M7 55 L38 55 C56 55 49 73 40 66','#FFFFFF',4)+line('M14 35 L41 35',sea,2))
def wave(gold=False):
 # Rider approaches from +y; crest pivot is (150, 28), not sprite center.
 # Matte falling water, broken whitewater lip and a dissolved trailing toe.
 mid='#F2B93B' if gold else '#49AEAF'
 light='#FFF7D0' if gold else '#BDE9DC'
 shadow='#B97E2E' if gold else '#1F6F8B'
 b=f'<defs><linearGradient id="slope" x1="0" y1="0" x2="0" y2="1"><stop stop-color="{light}"/><stop offset=".38" stop-color="{mid}" stop-opacity=".86"/><stop offset="1" stop-color="{sea}" stop-opacity="0"/></linearGradient><linearGradient id="back" x1="0" y1="0" x2="0" y2="1"><stop stop-color="{deep}" stop-opacity="0"/><stop offset="1" stop-color="{deep}" stop-opacity=".23"/></linearGradient></defs>'
 b+=path('M20 25 Q90 -2 180 10 Q246 5 283 22 L276 32 Q170 19 28 38Z','url(#back)')
 b+=path('M24 24 Q95 18 155 28 Q217 37 273 23 C283 44 280 68 261 84 Q218 93 170 87 Q96 99 48 80 Q18 63 24 24Z','url(#slope)')
 b+=path('M32 87 Q110 97 169 90 Q229 91 267 83','none',deep,5,extra='opacity=".06"')
 if gold: b+=path('M41 58 Q142 74 260 57','none',shadow,8,extra='opacity=".06"')
 for x,y in [(58,31),(89,28),(126,32),(165,36),(202,36),(240,32)]:
  b+=path(f'M{x} {y+5} Q{x-7} {y+22} {x-3} {y+43}','none',light,1.8,extra='opacity=".22"')
 crest='M25 26 Q33 19 41 26 Q48 20 57 25 Q66 20 74 25 Q84 21 94 26 Q103 22 114 27 Q124 23 134 29 Q145 25 155 31 Q166 27 176 33 Q187 29 198 33 Q210 28 220 31 Q232 26 242 29 Q254 22 263 26 Q270 20 277 23'
 if gold: b+=path('M30 31 Q94 24 155 35 Q220 43 274 28','none','#996224',1)
 b+=path(crest,'none','#E0F5E9',9 if gold else 7)
 b+=path(crest,'none','#FFFFFF',4 if gold else 3)
 b+=path('M31 25 Q17 30 25 39 Q36 33 32 48 Q47 40 43 54 M93 27 Q86 35 96 43 L103 35 M201 32 Q194 42 204 48 L212 37','none','#F5FFF7',4)
 b+=path('M22 47 L16 52 M31 60 L25 65 M40 55 L36 60 M19 37 L12 39','none','#F5FFF7',3)
 for x,y in [(47,44),(83,36),(184,38),(232,36)]: b+=ellipse(x,y,2.2,1.4,'#F5FFF7')
 if gold:
  b+=path('M53 19 Q98 18 140 25 M162 25 Q214 31 256 20','none','#FFF7D0',2.5)
  b+=path('M47 35 Q57 31 66 37 Q75 32 85 38 M123 40 Q136 35 147 43 M218 42 Q236 35 252 37','none','#F7FFF2',4)
 return b
add('wave',300,104,wave());add('wave_gold',300,116,wave(True))
b=ellipse(48,49,30,23,'#FFFFFF','opacity=".65"')
for i in range(11):
 a=i*math.tau/11;x=48+math.cos(a)*34;y=48+math.sin(a)*34;b+=ellipse(x,y,4,7,'#FFFFFF',f'transform="rotate({i*360/11+90} {x} {y})"')
b+=path('M22 48 Q35 29 47 42 Q62 22 74 47 Q67 67 48 63 Q27 70 22 48Z','#FFFFFF')
add('splash',96,96,b);add('spray',16,16,ellipse(8,8,6,6,'#FFFFFF','opacity=".65"')+ellipse(6,6,3,3,'#FFFFFF'))
add('sparkle',16,16,path('M8 0 L10 6 L16 8 L10 10 L8 16 L6 10 L0 8 L6 6Z','#FFFFFF'))
# Shore contours are periodic in y; both value and tangent match at tile boundaries.
shore=path('M0 0 L129 0 C129 64 105 64 105 128 S129 192 129 256 S105 320 105 384 S129 448 129 512 L0 512Z',sea,extra='opacity=".65"')+path('M0 0 L119 0 C119 64 95 64 95 128 S119 192 119 256 S95 320 95 384 S119 448 119 512 L0 512Z',sand)+path('M119 0 C119 64 95 64 95 128 S119 192 119 256 S95 320 95 384 S119 448 119 512','none',cream,4)+path('M0 0 L85 0 C85 64 73 64 73 128 S85 192 85 256 S73 320 73 384 S85 448 85 512 L0 512Z',cream,extra='opacity=".35"')
for x,y in [(20,40),(55,160),(32,315),(67,435)]:shore+=ellipse(x,y,2,1.5,'#CDBA91')
add('shore_left',160,512,shore,'sprites/scenery');add('shore_right',160,512,'<g transform="translate(160 0) scale(-1 1)">'+shore+'</g>','sprites/scenery')
add('house_white',90,90,rect(8,8,70,70,cream,2)+rect(14,14,58,58,'#FFFFFF',1)+line('M12 12 L74 12 L74 74 L12 74Z',sand,2)+rect(43,22,22,16,deep,1)+rect(45,24,18,12,sea,1)+line('M54 24 L54 36',cream,1.5)+ellipse(28,51,11,11,sand)+ellipse(27,49,8,8,cream)+ellipse(27,49,4,4,'#FFFFFF')+rect(17,17,9,11,cream,1)+line('M34 64 L62 64 M34 68 L62 68',sand,1.3),'sprites/scenery')
b=rect(12,15,67,65,'#AD9F81',6)+rect(7,8,68,65,terra,5)+path('M7 8 L40 5 L75 8 L75 40 L7 40Z','#D57B53')+line('M7 40 L75 40',cream,3)
for y in [17,27,52,63]: b+=line(f'M12 {y} L69 {y}','#A85032',1.2)
for x in [20,35,50,65]:b+=line(f'M{x} 10 L{x} 36 M{x-4} 44 L{x-4} 70','#E49A71',1)
add('house_terracotta',90,90,b,'sprites/scenery')
b=ellipse(42,44,32,29,'#556A3D')
for x,y,r in [(26,28,18),(49,24,19),(24,48,19),(51,47,22),(39,35,24)]:b+=ellipse(x,y,r,r,olive)
for x,y in [(24,21),(41,18),(53,38),(26,43),(39,55)]: b+=path(f'M{x-7} {y} q7 -7 13 0 q-7 6 -13 0', '#A5AF75')
add('olive_tree',80,80,b,'sprites/scenery')
b=ellipse(28,28,25,25,cream)
for i in range(8):
 a=i*math.tau/8; aa=a+math.tau/8;x=28+25*math.cos(a);y=28+25*math.sin(a);xx=28+25*math.cos(aa);yy=28+25*math.sin(aa)
 b+=path(f'M28 28 L{x} {y} A25 25 0 0 1 {xx} {yy}Z',terra if i%2==0 else cream)
b+=ellipse(28,28,4,4,lemon);add('umbrella',56,56,b,'sprites/scenery')
add('lighthouse',90,90,ellipse(46,47,35,35,sand)+ellipse(43,43,30,30,cream)+ellipse(43,43,24,24,terra)+ellipse(43,43,19,19,'#FFFFFF')+ellipse(43,43,12,12,deep)+ellipse(40,40,6,6,sea)+line('M19 24 L26 29 M63 24 L57 29 M23 63 L28 57 M64 63 L58 57',sand,3),'sprites/scenery')
b=rect(15,2,90,316,deep,5)+rect(12,0,90,312,'#AE8862',4)
for y in range(5,311,14):b+=line(f'M16 {y} L98 {y}',sand,2)
for x in [17,97]:
 for y in [17,98,183,292]: b+=ellipse(x,y,6,7,'#795F49')+ellipse(x-1,y-2,3,3,sand)
add('pier',120,320,b,'sprites/scenery')
add('sandbar',200,90,path('M5 50 Q12 19 52 22 Q86 2 128 14 Q193 12 195 47 Q180 72 140 69 Q91 92 53 74 Q9 78 5 50Z',sea,extra='opacity=".35"')+path('M22 47 Q37 24 71 30 Q100 12 139 28 Q181 25 176 50 Q141 72 110 62 Q65 79 22 47Z',sand,extra='opacity=".55"')+path('M31 43 Q60 20 125 24 Q173 25 165 45 Q100 70 31 43Z',cream,extra='opacity=".6"'),'sprites/scenery')
# UI glyphs, quiet cream plates and hand-drawn geometric wordmark (no font dependency).
add('icon_pause',64,64,rect(19,14,9,36,cream,4)+rect(36,14,9,36,cream,4),'ui')
speaker=path('M12 26 L23 26 L36 15 L36 49 L23 38 L12 38Z',cream)
add('icon_sound_on',64,64,speaker+line('M43 23 Q52 32 43 41 M49 15 Q64 32 49 49',cream,3),'ui')
add('icon_sound_off',64,64,speaker+line('M44 25 L57 39 M57 25 L44 39',cream,3),'ui')
add('btn_bg',96,96,rect(0,0,96,96,'#D7C5A5',24)+rect(0,0,96,91,cream,24)+line('M25 5 L71 5','#FFFFFF',2),'ui')
letters={'M':'M0 55 V0 L18 25 L36 0 V55','E':'M33 0 H0 V55 H33 M0 27 H27','L':'M0 0 V55 H32','T':'M0 0 H40 M20 0 V55','I':'M4 0 H30 M17 0 V55 M4 55 H30'}
b='<g transform="translate(91 149)" stroke="'+cream+'" stroke-width="12" fill="none">'
x=0
for c in 'MELTEMI':b+='<path d="'+letters[c]+'" transform="translate('+str(x)+' 0)"/>';x+=58
b+='</g><g transform="translate(230 24)">'+assets[2]['body']+'</g>'+path('M277 84 Q280 113 308 127 M322 83 Q315 110 308 127','none',sea,2)
b+=line('M122 224 Q300 248 478 224',terra,6)
add('logo',600,260,b,'ui')
icon=rect(0,0,1024,1024,sea)+ellipse(300,230,600,600,cream)+path('M0 650 Q256 470 512 650 T1024 650 V1024 H0Z','#4FB3BF')+path('M0 730 Q256 550 512 730 T1024 730','none','#FFFFFF',24)+'<g transform="translate(122 185) scale(5.6)">'+assets[2]['body']+'</g>'+line('M330 510 Q350 670 480 750 M705 510 Q670 680 480 750',deep,8)+path('M390 821 Q485 777 592 821 Q485 862 390 821Z',terra)
add('icon',1024,1024,icon,'ui')
# All sprites at exact 1x on both mandated backgrounds. Large icon has its own 1x row.
rows=[]; y=35
for a in assets:
 h=max(a['h']+38,92);rows.append(rect(0,y,1100,h,'#4FB3BF')+rect(1100,y,1100,h,sand)+f'<text x="8" y="{y+17}" fill="{deep}" font-size="14">{a["file"]} · {a["w"]}×{a["h"]}</text>'+f'<text x="1108" y="{y+17}" fill="{deep}" font-size="14">{a["file"]}</text>'+f'<g transform="translate(30 {y+28})">{a["body"]}</g>'+f'<g transform="translate(1130 {y+28})">{a["body"]}</g>');y+=h+4
text=svg(2200,y,''.join(rows));(QA/'contact_sheet.svg').write_text(text);raster(text,QA/'contact_sheet.png',2200,y)
# Additional compact overview to inspect small silhouettes without a very tall image.
b='';xx=0;yy=0
for a in assets:
 if a['h']>320 or a['w']>256:continue
 if xx+a['w']+25>900:xx=0;yy+=220
 b+=f'<g transform="translate({xx+8} {yy+26})">{a["body"]}</g>'+f'<text x="{xx+6}" y="{yy+17}" fill="{cream}" font-size="11">{Path(a["file"]).stem}</text>';xx+=max(95,a['w']+25)
raster(svg(920,yy+225,rect(0,0,920,yy+225,'#4FB3BF')+b),QA/'overview.png',920,yy+225)
def get(n):return next(a for a in assets if Path(a['file']).stem==n)
def put(n,x,y,scale=1):return f'<g transform="translate({x} {y}) scale({scale})">{get(n)["body"]}</g>'
b=rect(0,0,1000,1580,'#4FB3BF')
for i in range(3):b+=put('wave',200+i*256,60)+put('wave_gold',200+i*256,150)+put('shore_left',0,i*512)+put('shore_right',840,i*512)
raster(svg(1000,1580,b),QA/'tiled_tests.png',1000,1580)
b=rect(0,0,720,1280,'#4FB3BF')
for i in range(3):b+=put('shore_left',-45,i*512)+put('shore_right',605,i*512)
for n,x,y in [('house_white',3,130),('olive_tree',10,280),('umbrella',30,400),('house_terracotta',633,240),('olive_tree',639,400),('lighthouse',638,790),('umbrella',15,920),('house_white',4,1080),('sandbar',470,1020),('boat_fishing',470,280),('rock_small',186,470),('turtle',455,855),('buoy',200,990),('shell',302,417),('shell',335,325),('shell',363,235),('kite_sunset',250,540),('rider',325,745)]:b+=put(n,x,y)
b+=line('M274 595 L348 758 M367 595 L376 758',deep,2.8)+line('M274 595 L348 758 M367 595 L376 758',cream,1.3)+line('M357 814 Q326 940 385 1040','#FFFFFF',4)+put('wave',125,1130)+put('wave',381,1130)
raster(svg(720,1280,b),QA/'mock_gameplay.png',720,1280)
(ROOT/'manifest.json').write_text(json.dumps([{k:v for k,v in a.items() if k!='body'} for a in assets],indent=2))
print(f'Built {len(assets)} PNGs and editable SVGs; QA contact sheet, overview, 3x tiling and gameplay composite.')
