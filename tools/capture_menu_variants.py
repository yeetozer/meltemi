"""Render real Godot menu/variant evidence in an isolated save directory."""
from pathlib import Path
import os,subprocess,shutil
from PIL import Image,ImageDraw
R=Path(__file__).resolve().parents[1];os.chdir(R)
base=['systemd-run','--user','--scope','-p','MemoryMax=3G','timeout','90s','xvfb-run','-a','env','LIBGL_ALWAYS_SOFTWARE=1','XDG_DATA_HOME='+os.environ['TMPDIR']+'/meltemi-menu-save',str(Path.home()/'.local/bin/godot'),'--audio-driver','Dummy','--path','game']
qa=R/'art/qa/menu-v2';qa.mkdir(parents=True,exist_ok=True)
for mode,name,height in [('title','menu_1280',1280),('title','menu_1561',1561),('title','menu_first_launch',1561),('returning','menu_returning_player',1561),('missions','missions_sheet',1561),('settings','settings',1561),('shop','shop',1561),('pause','pause',1561),('game_over','results',1561)]:
 subprocess.run(base+['--resolution',f'720x{height}','--','--capture='+mode],check=True)
 shutil.copy(R/'build/qa'/f'{mode}.png',qa/(name+'.png'))
for v in 'ABC':
 for pose,color in [('ride','sunset'),('left','sunset'),('right','sunset'),('air','sunset'),('ride','seaglass'),('ride','olive'),('ride','lemon')]:
  env=os.environ.copy();env.update(VARIANT=v,POSE=pose,COLORWAY=color)
  subprocess.run(base+['--resolution','720x1280','--script','res://tests/variant_capture.gd'],env=env,check=True)
 folder=R/'art/qa/variants'
 image=Image.open(folder/f'{v}_ride_sunset.png');image.crop((220,430,560,900)).resize((1020,1410)).save(folder/f'{v}_crop_3x.png')
 sheet=Image.new('RGB',(1440,640),'#f4ebdd');d=ImageDraw.Draw(sheet)
 for i,color in enumerate(['sunset','seaglass','olive','lemon']):
  im=Image.open(folder/f'{v}_ride_{color}.png').resize((360,640));sheet.paste(im,(i*360,0));d.text((i*360+12,20),f'{v} — {color}',fill='#183e49')
 sheet.save(folder/f'{v}_colorways.png')
folder=R/'art/qa/variants';sheet=Image.new('RGB',(1440,1500),'#f4ebdd');d=ImageDraw.Draw(sheet)
for i,v in enumerate(['Current','A','B','C']):
 im=Image.open(qa/'menu_1280.png') if v=='Current' else Image.open(folder/f'{v}_ride_sunset.png')
 crop=im.crop((220,350 if v=='Current' else 430,560,820 if v=='Current' else 900))
 sheet.paste(crop,(i*360,60));sheet.paste(crop.resize((340,940)),(i*360,550));d.text((i*360+12,20),v,fill='#183e49')
sheet.save(folder/'variants_compare.png')
