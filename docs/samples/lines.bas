10 REM Demonstrate line drawing
20 GRAPHICS &H0F:REM Turn on bitmap and text-overlay modes
30 BITMAP 0,1,0:REM Display bitmap 0 and use the first CLUT
40 CLS:REM Clear the text screen
50 CLRBITMAP 0:REM Clear the pixmap
60 REM Draw the lines of the figure
70 xl = 300:xr = xl + 250:yt = 40:yb = yt + 250
90 FOR i=0 TO 25
100 LINE 0,xl,yt + i*10,xl + i*10,yb,i*10
110 LINE 0,xr,yt + i*10,xl + i*10,yt,i*10
120 NEXT
130 REM Set up a gradient of colors
140 FOR c=0 to 255
150 SETCOLOR 0,c,c,0,255-c
160 NEXT
170 GOTO 170
