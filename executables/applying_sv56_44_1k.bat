
PATH C:\Program Files (x86)\sox-14-4-0;%PATH%
sox %1 -t raw temp1.pcm
sv56demo.exe -q -lev -26 -sf 44100 temp1.pcm temp2.pcm
sox -t raw -r 44100 -sLb 16 - "%2" < temp2.pcm