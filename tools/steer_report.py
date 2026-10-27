#!/usr/bin/env python3
"""Summarize deterministic Godot traces and render dependency-light PNG charts.
Run steer_probe.gd twice with -- <absolute before/after.json>, then this script.
Step target is the accepted anti-runaway lead, NOT the unclipped 120px gesture.
"""
import json, math, pathlib, statistics
from PIL import Image, ImageDraw
ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / 'art/qa/steer'
SPEEDS = [380, 540, 700, 1050]
COLORS = ['#c23b22', '#268a45', '#1867bb', '#8c46aa']
data = {phase: json.loads((OUT / f'{phase}.json').read_text()) for phase in ['before', 'after']}

def metrics(traces, speed):
    step = traces[f'{speed}_step']
    target = step[0][5]
    # 90% of the accepted target displacement, including deadband settling.
    final = step[-1][1]
    t90 = next((r[0] for r in step if r[1] >= 360 + .9*(target-360)), float('inf'))
    jitter = traces[f'{speed}_jitter'][90:]
    release = traces[f'{speed}_release']
    shore = next((r[0]-.2 for r in release[12:] if r[7]), None)
    return dict(target_px=round(target-360,3), t90_s=round(t90,3), overshoot_px=round(max(0,max(r[1] for r in step)-target),4), settle_error_px=round(target-final,3), wobble_px=round(statistics.pstdev(r[1] for r in jitter),4), heading_rms_deg=round(math.degrees(math.sqrt(statistics.mean(r[3]**2 for r in jitter))),4), release_vx=round(release[12][2],3), shore_s=round(shore,3) if shore else None)

report = {phase: {str(s):metrics(traces,s) for s in SPEEDS} for phase,traces in data.items()}
for phase,traces in data.items():
    for track in ['step','sine','jitter','release','gust']:
        image=Image.new('RGB',(1100,900),'white'); draw=ImageDraw.Draw(image)
        draw.text((30,12),f'{phase}: {track} | 60 Hz | red 380, green 540, blue 700, purple 1050 px/s',fill='black')
        for panel,(index,label) in enumerate([(1,'rider x (px)'),(2,'lateral velocity (px/s)'),(3,'physical heading (rad)'),(4,'board rotation (rad)')]):
            values=[r[index] for s in SPEEDS for r in traces[f'{s}_{track}']]
            lo,hi=min(values),max(values)
            if hi-lo<.001: hi=lo+1
            top=50+panel*210; bottom=top+170
            draw.text((12,top),f'{label}: {lo:.3f} .. {hi:.3f}',fill='black')
            draw.line((90,top+20,90,bottom,1060,bottom),fill='#aaaaaa',width=1)
            for tick in range(7):
                xx=90+tick/6*970
                draw.line((xx,top+25,xx,bottom),fill='#eeeeee')
                draw.text((xx-10,bottom+4),f'{tick*.5:.1f}s',fill='#555555')
            for fraction in [0,.5,1]:
                yy=bottom-fraction*140
                draw.text((12,yy-6),f'{lo+fraction*(hi-lo):.2f}',fill='#555555')
            for s,color in zip(SPEEDS,COLORS):
                points=[(90+(r[0]/3)*970,bottom-(r[index]-lo)/(hi-lo)*140) for r in traces[f'{s}_{track}']]
                draw.line(points,fill=color,width=2)
        image.save(OUT/f'{phase}_{track}.png')
text=['# Steering deterministic comparison','', 'All runs 60 Hz, seed 9182. Step t90 uses the accepted target displacement (the anti-runaway lead clips a 60px finger step, not the full 120px gain); deadband residual is explicit. Shore includes automatic shallows and discrete collision, so it is not simply distance / initial vx.', '', '| Speed | Phase | Target px | t90 s | Overshoot px | Settle error px | Wobble SD px | Heading RMS deg | Release vx | Shore s |','|---|---|---|---|---|---|---|---|---|---|']
for s in SPEEDS:
    for phase in ['before','after']:
        m=report[phase][str(s)]
        text.append('| '+' | '.join(map(str,[s,phase,*m.values()]))+' |')
(OUT/'metrics.json').write_text(json.dumps(report,indent=2))
(OUT/'report.md').write_text('\n'.join(text)+'\n')
print('\n'.join(text))
# New behavior acceptance, checked on all recorded frames, not hand-picked summaries.
for s in SPEEDS:
    m=report['after'][str(s)]
    assert m['overshoot_px']==0 and m['heading_rms_deg']<1 and m['t90_s']<=.25, (s,m)
    for track in ['step','sine','jitter']:
        assert max(abs(a[1]-b[1]) for a,b in zip(data['after'][f'{s}_{track}'],data['after'][f'380_{track}']))<.05*24
    assert abs(m['release_vx']-report['after']['380']['release_vx'])<.01
print('PASS deterministic steering acceptance')
