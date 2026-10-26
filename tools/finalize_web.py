from pathlib import Path
import shutil
p=Path('build/web/index.html'); s=p.read_text(); import re
s=re.sub(r'<meta name="viewport"[^>]*>', '<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover, user-scalable=no">',s)
s=s.replace('</head>','''<meta name="apple-mobile-web-app-capable" content="yes"><link rel="apple-touch-icon" href="apple-touch-icon.png"><style>html,body{background:#F4EBDD!important;margin:0;overflow:hidden;overscroll-behavior:none;touch-action:none;-webkit-user-select:none;user-select:none;-webkit-touch-callout:none}canvas{touch-action:none}</style><script>document.addEventListener('dblclick',e=>e.preventDefault(),{passive:false});document.addEventListener('contextmenu',e=>e.preventDefault());document.addEventListener('pointerdown',()=>{if(window.GodotAudio&&GodotAudio.ctx)GodotAudio.ctx.resume();},{once:true});</script></head>''')
p.write_text(s);shutil.copyfile('game/assets/ui/icon.png','build/web/apple-touch-icon.png')
