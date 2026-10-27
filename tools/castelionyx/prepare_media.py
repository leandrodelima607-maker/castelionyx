from pathlib import Path
from PIL import Image
import subprocess

root=Path(__file__).resolve().parents[2]
# Keep original generated sheets; derive compact runtime atlases using nearest-neighbour only.
for name,rows in [('heroes',2),('enemies',3),('structures',2)]:
    source=root/'assets/combat'/f'{name}.png'
    im=Image.open(source).convert('RGBA')
    target=im.resize((1024,256*rows),Image.Resampling.NEAREST)
    target.save(root/'assets/combat'/f'{name}_runtime.png',optimize=True)
    if name=='structures':
        castle=target.crop((512,256,768,512))
        castle.thumbnail((64,64),Image.Resampling.NEAREST)
        icon=Image.new('RGBA',(64,64))
        icon.alpha_composite(castle,((64-castle.width)//2,(64-castle.height)//2))
        icon.save(root/'assets/share/favicon.png')
# Background ratio remains unchanged.
im=Image.open(root/'assets/kingdom/realm.png')
im.resize((1280,720),Image.Resampling.NEAREST).save(root/'assets/kingdom/realm_runtime.png',optimize=True)
for src,name in [('opening.wav','opening'),('defeat.wav','defeat'),('battle_part_a.wav','battle')]:
    source=root/'dist/production'/src
    if source.exists():
        subprocess.run(['ffmpeg','-y','-hide_banner','-loglevel','error','-i',str(source),'-af','loudnorm=I=-18:TP=-2:LRA=10','-c:a','libvorbis','-q:a','4',str(root/'assets/songs'/f'{name}.ogg')],check=True)
print('Compact runtime atlases, favicon and actual generated songs prepared.')
