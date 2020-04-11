10 rem Demonstrate the SID emulation with a chime
20 s=&hAFE400
30 for l=0 to 24:poke s+l,0:next
40 poke s+1,40
50 poke s+5,9
60 poke s+15,20
70 poke s+24,15
80 for l=1 to 5:poke s+4,21
90 for t=1 to 5000:next:poke s+4,20
100 for t=1 to 1000:next:next
110 for t=1 to 1000:next:poke s+24,0
