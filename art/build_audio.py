#!/usr/bin/env python3
"""Deterministic procedural 44.1kHz mono PCM audio; Python stdlib only."""
from pathlib import Path
import random,math,wave,array,json
R=44100;OUT=Path(__file__).resolve().parent.parent/'game/assets/audio';OUT.mkdir(parents=True,exist_ok=True)
rng=random.Random(2451);report=[]
def synth(name,duration,kind):
 n=round(R*duration);data=[];noise=0.;slow=0.;delay=[rng.uniform(-1,1) for _ in range(200)];idx=0
 notes=[220,233.0819,277.1826,293.6648,329.6276,349.2282,415.3047,440]
 for i in range(n):
  t=i/R;u=t/duration;white=rng.uniform(-1,1);noise=.8*noise+.2*white;slow=.995*slow+.005*white
  env=math.sin(math.pi*u)**1.5
  if kind=='ambient':
   # Integer-period swell and deterministic noise; endpoint crossfade below.
   v=noise*(.35+.18*math.sin(math.tau*t/8)) + slow*2.5 + .02*math.sin(math.tau*83*t)
  elif kind=='music':
   step=int(t/.4);local=t%.4;freq=notes[[0,4,7,4,1,4,6,4,3,5,7,5,1,4,6,4][step%16]]
   # Plucked modal marimba/guitar hybrid (damped harmonics).
   v=.5*math.exp(-local*9)*(math.sin(math.tau*freq*local)+.24*math.sin(math.tau*freq*2*local)+.12*math.sin(math.tau*freq*3*local))
   v+=.08*math.sin(math.tau*110*t)*math.sin(math.pi*t/duration)**2
  elif kind=='ding': v=.65*math.exp(-t*19)*(math.sin(math.tau*1174.66*t+.8*math.sin(math.tau*2349.32*t)))
  elif kind=='click': v=math.exp(-t*70)*(.4*math.sin(math.tau*950*t)+.12*noise)
  elif kind=='fanfare':
   v=0
   for j,f in enumerate([440,554.365,659.255,880]):
    q=t-j*.15
    if q>=0:v+=.26*math.exp(-q*7)*math.sin(math.tau*f*q+.35*math.sin(math.tau*f*2*q))
  elif kind in ['clean','bad','splash']:
   v=noise*math.exp(-t*(7 if kind=='clean' else 4))*1.8+.35*math.exp(-t*18)*math.sin(math.tau*(72*t+30*t*t))
   if kind=='clean':v+=.28*math.exp(-t*9)*math.sin(math.tau*1318.51*t)
  else:
   v=noise*env*(1+.4*math.sin(math.tau*(4 if kind=='trick' else 1)*u))
   if kind=='jump':v+=.12*math.sin(math.tau*(220*t+1200*t*t))*env
  data.append(v)
 if kind in ['ambient','music']:
  # Symmetric seam blend: both ends converge to identical samples; slopes flat at join.
  m=int(.12*R)
  for i in range(m):
   a=i/(m-1);weight=.5-.5*math.cos(math.pi*a);mean=(data[i]+data[-m+i])*.5
   data[i]=mean*(1-weight)+data[i]*weight
   data[-m+i]=data[-m+i]*(1-weight)+mean*weight
 # Every file reaches digital zero over 6 ms; loops meet without clicks.
 fade=int(.006*R)
 for i in range(fade):
  gain=.5-.5*math.cos(math.pi*i/fade);data[i]*=gain;data[-1-i]*=gain
 peak=max(abs(v) for v in data);gain=(10**(-1.1/20))/peak
 samples=array.array('h',(round(max(-1,min(1,v*gain))*32767) for v in data))
 import sys
 if sys.byteorder!='little':samples.byteswap()
 with wave.open(str(OUT/name),'wb') as w:w.setparams((1,2,R,0,'NONE','not compressed'));w.writeframes(samples.tobytes())
 with wave.open(str(OUT/name),'rb') as w:
  a=array.array('h');a.frombytes(w.readframes(w.getnframes()));p=max(abs(v) for v in a)/32768
  row={'file':name,'duration_s':w.getnframes()/w.getframerate(),'peak_dbfs':round(20*math.log10(p),3),'rate':w.getframerate(),'channels':w.getnchannels(),'bits':w.getsampwidth()*8,'endpoints':[a[0],a[-1]]};assert p<=10**(-1/20);assert a[0]==a[-1]==0;report.append(row)
for name,d,k in [('sfx_tack',.25,'whoosh'),('sfx_jump',.4,'jump'),('sfx_land_clean',.4,'clean'),('sfx_land_bad',.5,'bad'),('sfx_splash',.8,'splash'),('sfx_shell',.2,'ding'),('sfx_gust',.6,'wind'),('sfx_trick',.3,'trick'),('sfx_click',.08,'click'),('sfx_newbest',1.,'fanfare'),('amb_ocean',8.,'ambient'),('music_loop',19.2,'music')]:synth(name+'.wav',d,k)
(Path(__file__).resolve().parent/'qa/audio_check.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
