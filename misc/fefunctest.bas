   10 int n=100000,k,t
   20 float a=0#,b=1#,d,s
   30 t=time():d=(b-a)/n:a=a-d*0.5#:s=0#:for k=1 to n:s=s+atan(a+d*k):next:s=d*s:t=time()-t
   40 print s,t;"sec"
   50 end
   60 func time()
   70   str c$,d$,s$,t$
   80   int y,m,d
   90   d$=date$:t$=time$
  100   repeat
  110     c$=d$:s$=t$
  120     d$=date$:t$=time$
  130   until c$=d$ and s$=t$
  140   y=((atoi(left$(d$,2))+50) mod 100)+1950:m=atoi(mid$(d$,4,2)):d=atoi(right$(d$,2))
  150   if m<3 then { y=y-1:m=m+12 }
  160   c=floor(365.25#*y)+floor(30.59#*(m-2))+d-719501
  170   if -141417<=c then c=c+floor(y/400)-floor(y/100)+2
  180   return(c*86400+(atoi(left$(t$,2))-9)*3600+atoi(mid$(t$,4,2))*60+atoi(right$(t$,2)))
  190 endfunc
  200 func floor(x;float)
  210   int y
  220   y=fix(x):if x<y then y=y-1
  230   return(y)
  240 endfunc
