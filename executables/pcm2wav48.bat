PATH C:\Program Files (x86)\sox-14-4-0;%PATH%
sox -t raw -r 48000 -sLb 16 - %2 < %1