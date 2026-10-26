#!/usr/bin/env python3
"""Fetch official OFL Fredoka variable font; optional static SemiBold with fontTools."""
from pathlib import Path
from urllib.request import urlopen
ROOT=Path(__file__).resolve().parent.parent/'game/assets/fonts';ROOT.mkdir(parents=True,exist_ok=True)
BASE='https://raw.githubusercontent.com/google/fonts/main/ofl/fredoka/'
for remote,local in [('Fredoka%5Bwdth,wght%5D.ttf','Fredoka-Variable.ttf'),('OFL.txt','OFL.txt')]:
 with urlopen(BASE+remote,timeout=60) as r:(ROOT/local).write_bytes(r.read())
try:
 from fontTools.ttLib import TTFont
 from fontTools.varLib.instancer import instantiateVariableFont
 f=TTFont(ROOT/'Fredoka-Variable.ttf');f=instantiateVariableFont(f,{'wght':600,'wdth':100},inplace=True);f.save(ROOT/'Fredoka-SemiBold.ttf');print('Fredoka-SemiBold.ttf static instance weight 600, width 100.')
except ImportError:print('fontTools unavailable: use official Fredoka-Variable.ttf (OFL).')
