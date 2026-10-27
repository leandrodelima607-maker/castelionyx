from pathlib import Path
import numpy as np
import wave

root=Path(__file__).resolve().parents[2]/'assets/cues'
sr=22050
rng=np.random.default_rng(12)
for name,duration in [('click',.075),('arrow',.19),('coin',.28),('breach',.5),('upgrade',.4),('victory',.7)]:
 t=np.arange(int(sr*duration))/sr
 noise=rng.standard_normal(t.size)
 if name=='click': audio=noise*np.exp(-t*90)*.35+np.sin(t*2*np.pi*1800)*np.exp(-t*80)*.15
 elif name=='arrow': audio=np.convolve(noise,np.ones(5)/5,'same')*np.sin(np.pi*t/duration)**2*.45
 elif name=='coin': audio=(np.sin(2*np.pi*2200*t)+.4*np.sin(2*np.pi*3600*t))*np.exp(-t*20)*.2
 elif name=='breach': audio=np.convolve(noise,np.ones(32)/32,'same')*np.exp(-t*7)*.9+np.sin(2*np.pi*(85*t-32*t*t))*np.exp(-t*9)*.35
 elif name=='upgrade': audio=np.sin(2*np.pi*(400*t+1700*t*t))*np.exp(-t*8)*.17+noise*np.exp(-t*15)*.05
 else: audio=np.sin(2*np.pi*(600*t+1000*t*t))*np.exp(-t*8)*.16+noise*np.exp(-t*12)*.04
 audio*=np.minimum(t*sr/50,1)*np.minimum((duration-t)*sr/50,1)
 pcm=(np.clip(audio,-.95,.95)*32767).astype('<i2')
 with wave.open(str(root/f'{name}.wav'),'wb') as w:
  w.setnchannels(1);w.setsampwidth(2);w.setframerate(sr);w.writeframes(pcm.tobytes())
print('Six short event effects written; these are SFX, not music.')
