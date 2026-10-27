"""Build separate, owner-review-only top-down rider and kite SVG/PNG layers."""
from pathlib import Path
import cairosvg
ROOT=Path(__file__).resolve().parent
COLORS={'sunset':'#c8643b','seaglass':'#8fc9b9','olive':'#788451','lemon':'#f2c14e'}
def svg(body,w=96,h=96):
 return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{body}</svg>'
def build():
 for v in 'ABC':
  src=ROOT/'src'/'variants'/v; out=ROOT/'variants'/v
  src.mkdir(parents=True,exist_ok=True);out.mkdir(parents=True,exist_ok=True)
  stroke= '#183e49'; thick=5 if v=='B' else 3
  parts={
   'board':svg(f'<rect x="6" y="53" width="84" height="20" rx="9" fill="{stroke}" stroke="#f4ebdd" stroke-width="3"/><path d="M28 55v16M68 55v16" stroke="#c8643b" stroke-width="5"/>'),
   'body':svg(f'<path d="M39 43L29 50L29 63M56 43L67 51L67 63" fill="none" stroke="{stroke}" stroke-width="{9 if v=="B" else 7}" stroke-linecap="round"/><path d="M37 26Q48 20 59 27L56 45H40Z" fill="{stroke}"/><ellipse cx="48" cy="20" rx="{10 if v=="B" else 7}" ry="8" fill="#c8643b"/><path d="M42 16h12" stroke="#f4ebdd" stroke-width="2"/>'),
   'arms':svg(f'<path d="M38 29L27 21L32 8M58 29L69 21L64 8" fill="none" stroke="{stroke}" stroke-width="{thick+2}" stroke-linecap="round"/><path d="M27 7H69" stroke="#f4ebdd" stroke-width="5"/><path d="M48 7v8q-5 6 0 7q5-1 0-7" fill="none" stroke="{stroke}" stroke-width="2"/>')}
  for name,color in COLORS.items():
   width=12 if v=='B' else 7
   body=f'<path d="M8 79Q15 8 90 8Q165 8 172 79Q148 39 90 39Q32 39 8 79Z" fill="{color}" stroke="{stroke}" stroke-width="2"/>'
   if v!='C':
    for x in [40,65,115,140]: body+=f'<path d="M{x} 18L{x-7 if x<90 else x+7} 52" stroke="#f4ebdd" stroke-width="{9 if v=="B" else 3}" opacity=".8"/>'
   body+=f'<path d="M8 79Q15 8 90 8Q165 8 172 79" fill="none" stroke="{stroke if v!= "C" else color}" stroke-width="{width}" stroke-linecap="round"/>'
   parts['kite_'+name]=svg(body,180,90)
  for name,data in parts.items():
   (src/(name+'.svg')).write_text(data)
   cairosvg.svg2png(bytestring=data.encode(),write_to=str(out/(name+'.png')))
if __name__=='__main__':build()
