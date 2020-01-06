10 GRAPHICS &h2F:CLS
20 SPRITE 0,0,&hB10000
30 SPRITESHOW 0,1
40 FOR v=0 to 31
50    FOR u=0 to 31
60        POKE &hb10000 + v*32 + u,v
70        SETCOLOR 1,v,7*v,0,255-7*v
80    NEXT
90 NEXT
100 x=32:y=32:dx=1:dy=1
110 SPRITEAT 0,x,y
120 x = x + dx:y = y + dy
125 print x,y,dx,dy
130 IF x > 32 AND x < 576 THEN 150
140 dx = 0 - dx
150 IF y > 32 AND y < 416 THEN 170
160 dy = 0 - dy
170 FOR i=1 TO 100:NEXT
180 GOTO 110
