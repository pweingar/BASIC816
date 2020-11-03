10 CLS:GRAPHICS &h27:REM Sprites with text overlay
12 SETCOLOR 0,1,128,128,0:REM A dull yellow
14 REM Define sprite image (just a yellow square)
16 FOR x%=0 TO 1024:POKE &hb00000+x%,1:NEXT
18 SPRITE 0,1,&hb00000:REM Set up sprite #0
20 SPRITESHOW 0,1:REM Make sprite 0 visible
22 SPRITEAT 0,100,100:REM Position sprite 0 to 100,100
