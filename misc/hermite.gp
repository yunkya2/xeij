\\========================================================================================
\\  hermite.gp
\\  Copyright (C) 2003-2019 Makoto Kamada
\\
\\  This file is part of the XEiJ (X68000 Emulator in Java).
\\  You can use, modify and redistribute the XEiJ if the conditions are met.
\\  Read the XEiJ License for more details.
\\  https://stdkmd.net/xeij/
\\========================================================================================

\\エルミート補間
\\p=hermite(a,p,v,x)
\\  x=a[1],...,a[n+1]における位置がp[1],...,p[n+1]速度がv[1],...,v[n+1]のときxにおける位置を求める
hermite(a,p,v,x)={
  my(n=#a-1);
  sum(k=0,n,(1-2*sum(m=0,n,if(m==k,0,1/(a[k+1]-a[m+1])))*(x-a[k+1]))*(prod(m=0,n,if(m==k,1,(x-a[m+1])/(a[k+1]-a[m+1]))))^2*p[k+1])+
    sum(k=0,n,(x-a[k+1])*(prod(m=0,n,if(m==k,1,(x-a[m+1])/(a[k+1]-a[m+1]))))^2*v[k+1])
}
\\p=hermite4(pm,p0,p1,p2,x)
\\  x=-1,0,1,2における位置がpm,p0,p1,p2のとき0<=x<=1における位置を求める
hermite4(pm,p0,p1,p2,x)={
  hermite([0,1],[p0,p1],[(p1-pm)/2,(p2-p0)/2],x)
}
\\hermite_code(s,n)
\\  s   1  モノラル
\\      2  ステレオ
\\  n  16   3906Hz
\\     12   5208Hz
\\      8   7812Hz
\\      6  10416Hz
\\      4  15625Hz
hermite_code(s,n)={
  my(k,d,h,cm,c0,c1,c2,g,e);
  print("        int i = pcmPointer;");
  print("        int mm = pcmDecodedData3;");
  print("        int m0 = pcmDecodedData2;");
  print("        int m1 = pcmDecodedData1;");
  for(j=0,s-1,
      print("        {");
      for(k=1,n,
          d=(2-n%2)*n^3;
          h=hermite4(pm,p0,p1,p2,k/n)*d;
          cm=polcoeff(h,1,pm);
          c0=polcoeff(h,1,p0);
          c1=polcoeff(h,1,p1);
          c2=polcoeff(h,1,p2);
          g=gcd(gcd(gcd(gcd(cm,c0),c1),c2),d);
          cm/=g;
          c0/=g;
          c1/=g;
          c2/=g;
          d/=g;
          e=floor(log(d)/log(2)+0.5);
          if(k==0,
             print1("          //                  "),
             if(k==1&&j==0,
                if(s*n<=10,
                   print1("          pcmBuffer[i    ] = "),
                   print1("          pcmBuffer[i     ] = ")),
                if(s*n<=10,
                   printf("          pcmBuffer[i + %d] = ",s*(k-1)+j),
                   printf("          pcmBuffer[i + %2d] = ",s*(k-1)+j))));
          if(d==1,
             print1("        "),
             if(d==2^e,
                print1("        "),
                print1("(int) ((")));
          if(cm==0,
             print1("          "),
             if(cm==-1,
                print1("       -"),
                printf("%5d * ",cm));
             print1("mm"));
          if(c0==c1,
             printf(" + %4d *      (",c0);
             print1("m0");
             print1(" + ");
             print1("m1");
             print1(")"),
             if(c0==0,
                print1("            "),
                if(cm==0,
                   print1("   "),
                   print1(" + "));
                if(c0==1,
                   print1("       "),
                   printf("%4d * ",c0));
                print1("m0"));
             if(c1==0,
                if(c2!=0,
                   print1("            ")),
                if(cm==0&&c0==0,
                   print1("   "),
                   print1(" + "));
                if(c1==1,
                   print1("       "),
                   printf("%4d * ",c1));
                print1("m1")));
          if(c2==0,
             print1(),
             if(c2==-1,
                print1(" -        "),
                printf(" - %4d * ",-c2));
             print1("m2"));
          if(d==1,
             print1(";"),
             if(d==2^e,
                printf(" >> %2d;",e),
                printf(") * %10dL >> 32);",floor(2^32/d+0.5))));
          print()
          );
      print("        }")
      );
  print("        pcmDecodedData3 = m0;");
  print("        pcmDecodedData2 = m1;");
  print("        pcmDecodedData1 = m2;");
  print("        pcmPointer = i + ",s*n,";")
}
