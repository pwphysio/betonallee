#!/usr/bin/env bash
# Baut die Reels zu "Orange" (Betonallee) neu. Benötigt: ffmpeg mit libass, curl.
# Aufruf: ./build.sh /pfad/zum/song.mp3
set -euo pipefail
SONG="$1"; HERE="$(cd "$(dirname "$0")" && pwd)"; OUT="$HERE/../videos"; W="$(mktemp -d)"
cd "$W"
dl(){ curl -sL -o "$1.mp4" "https://www.pexels.com/download/video/$1/"; }
for id in 4729764 4941678 4729804 8379233 8379207 5562787 15065909 32013508 3568022 10971521 8942020; do dl $id; done
ffmpeg -loglevel error -y -ss 205 -t 29 -i "$SONG" -af "afade=t=in:d=0.3" -c:a aac -b:a 256k c.m4a
seg(){ echo "[$1:v]trim=start=$2:duration=$3,setpts=PTS-STARTPTS,fps=30,scale=-2:1920:flags=lanczos,crop=1080:1920:'min(max(iw*$4-540,0),iw-1080)':0,setsar=1${6:+,$6}[v$5];"; }
GRADE="eq=saturation=1.08:contrast=1.04,colorbalance=rm=0.04:bm=-0.04:rh=0.03:bh=-0.03,vignette=PI/5"
ENC="-t 29 -c:v libx264 -preset slow -crf 18 -profile:v high -r 30 -c:a aac -b:a 256k -movflags +faststart"
SERIF=/usr/share/fonts/truetype/freefont/FreeSerifItalic.ttf; SANS=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf

# V1 (Steg) – Basis
V1="$(seg 0 0 5.41 0.5 1)$(seg 1 0.5 2.79 0.62 2)$(seg 0 7.0 5.59 0.5 3)$(seg 1 4.0 2.79 0.66 4)$(seg 0 20.0 5.60 0.5 5)$(seg 2 12.0 6.82 0.5 6)[v1][v2][v3][v4][v5][v6]concat=n=6:v=1:a=0,$GRADE"
# V1 mit Text am Ende
ffmpeg -loglevel error -y -i 4729764.mp4 -i 4941678.mp4 -i 4729804.mp4 -i c.m4a -filter_complex "$V1,drawtext=fontfile=$SERIF:text='Der Horizont scheint orange':fontsize=84:fontcolor=white:shadowcolor=black@0.45:shadowx=2:shadowy=2:x=(w-tw)/2:y=h*0.30:alpha='if(lt(t,22.6),0,if(lt(t,23.8),(t-22.6)/1.2,if(lt(t,27.2),1,max(0,(28.4-t)/1.2))))',fade=t=in:st=0:d=0.6,fade=t=out:st=27.4:d=1.6,format=yuv420p[v];[3:a]afade=t=out:st=27.0:d=2.0[a]" -map "[v]" -map "[a]" $ENC "$OUT/orange_reel_v1_steg.mp4"
# V1 Karaoke
cp "$HERE/karaoke.ass" k.ass
ffmpeg -loglevel error -y -i 4729764.mp4 -i 4941678.mp4 -i 4729804.mp4 -i c.m4a -filter_complex "$V1,ass=k.ass,fade=t=in:st=0:d=0.6,fade=t=out:st=27.8:d=1.2,format=yuv420p[v];[3:a]afade=t=out:st=27.0:d=2.0[a]" -map "[v]" -map "[a]" $ENC "$OUT/orange_reel_v1_karaoke.mp4"

# V2 (Grau ins Orange)
A1="alpha='if(lt(t,22.6),0,if(lt(t,23.6),(t-22.6),if(lt(t,26.0),1,max(0,(26.8-t)/0.8))))'"
A2="alpha='if(lt(t,26.6),0,if(lt(t,27.4),(t-26.6)/0.8,1))'"
T="fontcolor=white:shadowcolor=black@0.45:shadowx=2:shadowy=2:x=(w-tw)/2"
FC="$(seg 0 0 2.81 0.5 1 'eq=saturation=0.75')$(seg 1 2 2.60 0.28 2)$(seg 2 2 2.79 0.47 3)$(seg 3 18.5 2.77 0.35 4)$(seg 4 0 2.82 0.5 5)$(seg 5 4 2.79 0.58 6)$(seg 6 3 2.79 0.5 7)$(seg 4 3.4 2.81 0.5 8)$(seg 7 0.5 6.82 0.40 9)"
FC+="[v1][v2][v3][v4][v5][v6][v7][v8][v9]concat=n=9:v=1:a=0,eq=saturation=1.06:contrast=1.04,colorbalance=rm=0.04:bm=-0.04:rh=0.03:bh=-0.03,vignette=PI/5,"
FC+="drawtext=fontfile=$SERIF:text='so schön,':fontsize=88:$T:y=h*0.26:$A1,drawtext=fontfile=$SERIF:text='der horizont scheint orange':fontsize=88:$T:y=h*0.26+110:$A1,"
FC+="drawtext=fontfile=$SANS:text='B E T O N A L L E E':fontsize=64:$T:y=h*0.28:$A2,drawtext=fontfile=$SERIF:text='Orange':fontsize=96:fontcolor=0xFFB36B:shadowcolor=black@0.45:shadowx=2:shadowy=2:x=(w-tw)/2:y=h*0.28+95:$A2,"
FC+="fade=t=in:st=0:d=0.5,fade=t=out:st=28.0:d=1.0,format=yuv420p[v];[8:a]afade=t=out:st=27.0:d=2.0[a]"
ffmpeg -loglevel error -y -i 8379233.mp4 -i 8379207.mp4 -i 5562787.mp4 -i 15065909.mp4 -i 32013508.mp4 -i 3568022.mp4 -i 10971521.mp4 -i 8942020.mp4 -i c.m4a -filter_complex "$FC" -map "[v]" -map "[a]" $ENC "$OUT/orange_reel_v2_grau-ins-orange.mp4"
echo "Fertig: $OUT"
