\\========================================================================================
\\  efp.gp
\\  Copyright (C) 2003-2019 Makoto Kamada
\\
\\  This file is part of the XEiJ (X68000 Emulator in Java).
\\  You can use, modify and redistribute the XEiJ if the conditions are met.
\\  Read the XEiJ License for more details.
\\  https://stdkmd.net/xeij/
\\========================================================================================



\\----------------------------------------------------------------------------------------
\\  設定
\\----------------------------------------------------------------------------------------

\\テストプログラム
TEST_S="fputest.s";  \\ソースファイル
TEST_X="fputest.x";  \\実行ファイル
TEST_LOG="fputest.log";  \\ログファイル
TEST_S_TMP=Str(TEST_S,".tmp");
TEST_S_BAK=Str(TEST_S,".bak~");
TEST_COMMENT=1;  \\1=ソースファイルのデータにコメントを付ける
if(type(TEST_HARD_FSGLDIV)=="t_POL",TEST_HARD_FSGLDIV=0);  \\1=MC68882のFSGLDIVのバグを再現する
if(type(TEST_HARD_FSGLMUL)=="t_POL",TEST_HARD_FSGLMUL=0);  \\1=MC68882のFSGLMULのバグを再現する

\\有効桁数
\p 400



\\----------------------------------------------------------------------------------------
\\  定数
\\----------------------------------------------------------------------------------------

\\精度を変更できるように数学定数をコピーしないことにした

LOG_ZERO=1e-99999;  \\abs(x)<=LOG_ZEROのときx≒0と見なしてlog(x)の計算を避ける

\\FPUの種類
MC68881=1<<0;
MC68882=1<<1;
MC68040=1<<2;
FPSP040=1<<3;
MC68060=1<<4;
FPSP060=1<<5;



\\----------------------------------------------------------------------------------------
\\  ファイル操作
\\----------------------------------------------------------------------------------------

\\writef(file,format,args...)
\\  fileへフォーマット出力する
writef(file,format,args[..])=write1(file,call(Strprintf,[format,args]));



\\----------------------------------------------------------------------------------------
\\  数値操作
\\----------------------------------------------------------------------------------------

\\y=realtofrac(x)
\\  実数(t_REAL)xを有理数(t_FRAC)または整数(t_INT)に変換する
\\  現在の精度でx==yになる
\\  分母が2の累乗になるとは限らない
realtofrac(x)=if(type(x)=="t_REAL",bestappr(x,2^default(realbitprecision)),x);

\\y=realnextdown(x)
\\  現在の精度で実数xよりも僅かに小さい数を返す
realnextdown(x)={
  my(y,m);
  if(x<0,return(-realnextup(-x)));
  x*=1.0;
  if(x<LOG_ZERO,return(-LOG_ZERO));
  y=x-2.0^(2+floor(log(x)/log(2))-default(realbitprecision));  \\誤差を考慮して小さめの数を元に数に寄せる
  if(x==y,error("realnextdown(",x,")"));
  m=(x+y)*0.5;
  while((y<m)&&(m<x),  \\通常は1回、2の累乗のときは2回
        y=m;
        m=(x+y)*0.5);
  y
  }

\\y=realnextup(x)
\\  現在の精度で実数xよりも僅かに大きい数を返す
realnextup(x)={
  my(y,m);
  if(x<0,return(-realnextdown(-x)));
  x*=1.0;
  if(x<LOG_ZERO,return(LOG_ZERO));
  y=x+2.0^(2+floor(log(x)/log(2))-default(realbitprecision));  \\誤差を考慮して大きめの数を元の数に寄せる
  if(x==y,error("realnextup(",x,")"));
  m=(x+y)*0.5;
  while((x<m)&&(m<y),  \\通常は1回
        y=m;
        m=(x+y)*0.5);
  y
  }

\\y=log2(x)
\\  二進対数
\\    $ gp -q
\\    ? \p 400
\\    ? default(realbitprecision)
\\    1344
\\    ? log(2^1338)-log(2^1338-4)
\\    2.666771371729126107 E-402
\\    ? log(2^1338)-log(2^1338+4)
\\    2.666771371729126107 E-402
\\  この誤差は都合が悪い
log2(x)={
  my(y,n,m);
  y=log(x)/log(2);
  n=floor(y);
  m=2^n;  \\整数または有理数で表現された厳密な値。xの絶対値が大きいと負荷がかかる
  if(x==m,n,
     x<m,realnextdown(n),  \\大きすぎる
     2*m<=x,n+1,  \\小さすぎる
     y)
  }

\\y=log10(x)
\\  常用対数
log10(x)={
  my(y,n,m);
  y=log(x)/log(10);
  n=floor(y);
  m=10^n;  \\整数または有理数で表現された厳密な値。xの絶対値が大きいと負荷がかかる
  if(x==m,n,
     x<m,realnextdown(n),  \\大きすぎる
     10*m<=x,n+1,  \\小さすぎる
     y)
  }

rint(x)={
  if(frac(x)==1/2,  \\frac(x)=x-floor(x)
     if(0<=x,
        floor(x)+(floor(x)%2),  \\x%y=x-floor(x/y)*y
        ceil(x)-(ceil(x)%2)),
     floor(x+1/2))
  }

trunc(x)=if(0<=x,floor(x),ceil(x));  \\truncate(x)



\\----------------------------------------------------------------------------------------
\\  文字列操作
\\----------------------------------------------------------------------------------------

\\t=strlwr(s)
\\  文字列sを小文字にする
strlwr(s)=Strchr(apply(c->if((65<=c)&&(c<=90),c+32,c),Vec(Vecsmall(s))));

\\t=strupr(s)
\\  文字列sを大文字にする
strupr(s)=Strchr(apply(c->if((97<=c)&&(c<=122),c-32,c),Vec(Vecsmall(s))));

\\x=hex(s)
\\  文字列sを16進数と見なして符号なし整数に変換する
\\  "_"を読み飛ばす
hex(s)=eval(Str("0x",Strchr(select(c->c!=95,Vec(Vecsmall(s))))));  \\"_"を取り除いてから先頭に"0x"を付けてevalにかける

\\x=bin(s)
\\  文字列sを2進数と見なして符号なし整数に変換する
\\  "_"を読み飛ばす
bin(s)=eval(Str("0b",Strchr(select(c->c!=95,Vec(Vecsmall(s))))));  \\"_"を取り除いてから先頭に"0b"を付けてevalにかける

\\x=oct(s)
\\  文字列sを8進数と見なして符号なし整数に変換する
\\  "_"を読み飛ばす
oct(s)={
  my(v,x,c);
  v=Vecsmall(s);
  x=0;
  for(k=1,#v,
      c=v[k];
      if(c!=95,  \\_
         x=(x<<3)+if((48<=c)&&(c<=55),c-48,  \\0-7
                     error("oct(\"",s,"\")"))));
  x
  }

\\s=hexstr(x,n)
\\  整数xの16進数表現の末尾のn桁を文字列で返す
\\  プレフィックスは付けない
\\  printfやStrprintfの書式文字列の"%x"は符号を無視するので負の数をそのまま指定すると64bit単位の補数表現になる
\\  -1は2^64-1、-2^64は2^128-2^64など。桁数が16の倍数でないと"0"が並んだ後に"F"が並ぶことになる
hexstr(x,n)=Strprintf(Str("%0",n,"X"),bitand(x,16^n-1));

\\s=hex1(u)
\\  整数uの末尾の4bitを1桁の16進数の文字列に変換する
hex1(u)=hexstr(u,1);

\\s=hex2(u)
\\  整数uの末尾の8bitを2桁の16進数の文字列に変換する
hex2(u)=hexstr(u,2);

\\s=hex4(u)
\\  整数uの末尾の16bitを4桁の16進数の文字列に変換する
hex4(u)=hexstr(u,4);

\\s=hex8(u)
\\  整数uの末尾の32bitを8桁の16進数の文字列に変換する
hex8(u)=hexstr(u,8);

\\s=hex10(u)
\\  整数uの末尾の40bitを10桁の16進数の文字列に変換する
hex10(u)=hexstr(u,10);

\\s=hex16(u)
\\  整数uの末尾の64bitを16桁の16進数の文字列に変換する
hex16(u)=hexstr(u,16);

\\s=hex18(u)
\\  整数uの末尾の72bitを18桁の16進数の文字列に変換する
hex18(u)=hexstr(u,18);

\\s=hex24(u)
\\  整数uの末尾の96bitを24桁の16進数の文字列に変換する
hex24(u)=hexstr(u,24);

\\s=hex28(u)
\\  整数uの末尾の112bitを28桁の16進数の文字列に変換する
hex28(u)=hexstr(u,28);

\\s=hex32(u)
\\  整数uの末尾の128bitを32桁の16進数の文字列に変換する
hex32(u)=hexstr(u,32);

\\s=hex48(u)
\\  整数uの末尾の192bitを48桁の16進数の文字列に変換する
hex48(u)=hexstr(u,48);

\\s=hex64(u)
\\  整数uの末尾の256bitを64桁の16進数の文字列に変換する
hex64(u)=hexstr(u,64);

\\s=hex1imm(u)
\\  整数uの末尾の4bitを1桁の16進数の文字列に変換する
hex1imm(u)=Str("$",hexstr(u,1));

\\s=hex2imm(u)
\\  整数uの末尾の8bitを2桁の16進数の文字列に変換する
hex2imm(u)=Str("$",hexstr(u,2));

\\s=hex4imm(u)
\\  整数uの末尾の16bitを4桁の16進数の文字列に変換する
hex4imm(u)=Str("$",hexstr(u,4));

\\s=hex8imm(u)
\\  整数uの末尾の32bitを8桁の16進数の文字列に変換する
hex8imm(u)=Str("$",hexstr(u,8));

\\s=hex16imm(u)
\\  整数uの末尾の64bitを2個の8桁の16進数の文字列に変換する
hex16imm(u)=Str("$",hexstr(u>>32,8),",$",hexstr(u,8));

\\s=hex24imm(u)
\\  整数uの末尾の96bitを3個の8桁の16進数の文字列に変換する
hex24imm(u)=Str("$",hexstr(u>>64,8),",$",hexstr(u>>32,8),",$",hexstr(u,8));

\\s=hex32imm(u)
\\  整数uの末尾の128bitを4個の8桁の16進数の文字列に変換する
hex32imm(u)=Str("$",hexstr(u>>96,8),",$",hexstr(u>>64,8),",$",hexstr(u>>32,8),",$",hexstr(u,8));

\\s=hex48imm(u)
\\  整数uの末尾の192bitを6個の8桁の16進数の文字列に変換する
hex48imm(u)=Str("$",hexstr(u>>160,8),",$",hexstr(u>>128,8),",$",hexstr(u>>96,8),",$",hexstr(u>>64,8),",$",hexstr(u>>32,8),",$",hexstr(u,8));

\\s=hex64imm(u)
\\  整数uの末尾の256bitを8個の8桁の16進数の文字列に変換する
hex64imm(u)=Str("$",hexstr(u>>224,8),",$",hexstr(u>>192,8),",$",hexstr(u>>160,8),",$",hexstr(u>>128,8),",$",hexstr(u>>96,8),",$",hexstr(u>>64,8),",$",hexstr(u>>32,8),",$",hexstr(u,8));

\\s=octstr(x,n)
\\  整数xの8進数表現の末尾のn桁を文字列で返す
\\  プレフィックスは付けない
octstr(x,n)=Strprintf(Str("%0",n,"o"),bitand(x,8^n-1));

\\s=binstr(x,n)
\\  整数xの2進数表現の末尾のn桁を文字列で返す
\\  プレフィックスは付けない
\\  printfやStrprintfの書式文字列に"%b"はない
binstr(x,n)=Strchr(vector(n,k,48+bittest(bitand(x,2^n-1),n-k)));

\\s=formatg(x,n)
\\  数値を有効桁数を指定して文字列に変換する
formatg(x,n)={
  my(s,g,v);
  if(type(x)=="t_POL",return(Str(x)));
  if(0<=x,
     s="",
     s="-";
     x=-x);  \\x=abs(x)
  if(n<1,n=1);
  if(x<=LOG_ZERO,  \\x==0のとき。log10(x)を計算できない
     g=0;
     v=vector(n,i,48),  \\0のときは0を並べる
     g=floor(log10(x));  \\x!=0のときの指数
     v=Vecsmall(Str(floor(10^(n-1-g)*x+0.5)));  \\先頭のn桁を整数で取り出して1桁ずつ分解する
     if(#v==n+1,g++));  \\丸めで1桁増えたとき指数部を増やす。vの要素がn+1個あるのでStrchr(v)ではなくStrchr(v[1..n])と書くこと
  if((-3<=g)&&(g<=-2),
     Str(s,"0.",Strchr(vector(-1-g,i,48)),Strchr(v[1..n])),  \\すべて小数部。小数点以下n-g-1桁。先頭に0.0または0.00を付ける。指数形式にしても.e-3で4文字増えることに変わりないので0.00までは指数形式にしない。有効桁数は0以外の数字から数えればよい
     g==-1,
     Str(s,"0.",Strchr(v[1..n])),  \\すべて小数部。小数点以下n桁。先頭に0.を付ける
     (0<=g)&&(g<=n-2),
     Str(s,Strchr(v[1..g+1]),".",Strchr(v[g+2..n])),  \\g+1桁の整数部と小数点とn-g-1桁の小数部
     g==n-1,
     Str(s,Strchr(v[1..n])),  \\すべて整数部
     \\(n<=g)&&(g<=n+3),
     \\Str(s,Strchr(v[1..n]),Strchr(vector(g+1-n,i,48))),  \\すべて整数部。g+1桁。末尾のg+1-n桁は0。0の数が指数部よりも少なければ指数形式と比較して文字数は多くならないが有効桁数がわからなくなるので不採用
     n==1,
     Str(s,Strchr(v[1]),if(0<g,"e+","e"),g),  \\1桁の整数部と指数部
     Str(s,Strchr(v[1]),".",Strchr(v[2..n]),if(0<g,"e+","e"),g))  \\1桁の整数部と小数点とn-1桁の小数部と指数部
  }



\\----------------------------------------------------------------------------------------
\\  配列操作
\\----------------------------------------------------------------------------------------

\\w=append(v...)
\\  多数のベクタv...を連結する
append(v[..])={
  if(#v==0,[],
     #v==1,v[1],
     #v==2,concat(v[1],v[2]),
     concat(call(append,[v[1..#v>>1]]),call(append,[v[(#v>>1)+1..#v]])))
  }

\\t=join(s,v)
\\  区切り文字列sを挟みながらベクタvの要素を連結して1つの文字列にする
join(s,v)={
  if(#v==0,"",
     #v==1,Str(v[1]),
     #v==2,Str(v[1],s,v[2]),
     Str(call(join,[s,v[1..#v>>1]]),s,call(join,[s,v[(#v>>1)+1..#v]])))
  }

\\x=merge(v,w,c)
\\  昇順にソートされたベクタvとベクタwをコンパレータcでマージしたベクタを返す
\\  自然順序のときはcmpを指定する
merge(v,w,c)={
  my(l=#v,m=#w,n=l+m,x=Vec(0,n),i=1,j=1,s,t);
  for(k=1,n,
      if(m<j,x[k]=v[i];i++,  \\gpのi++はCの++iなのでv[i++]は不可
         l<i,x[k]=w[j];j++,
         s=v[i];t=w[j];if(c(s,t)<=0,x[k]=s;i++,x[k]=t;j++)));
  x
  }

\\w=sort(v,c)
\\  ベクタvをコンパレータcで昇順にソートする
\\  自然順序のときはcmpを指定する
sort(v,c)={
  my(n=#v,w=Vec(0,n),l);
  for(k=1,n,w[k]=[v[k]]);  \\ベクタを長さ1のブロックに分割する
  l=1;  \\lは現在のブロックの長さ。最後のブロックの長さは1以上
  while(l+1<=n,  \\ブロックが2個以上ある
        forstep(k=l+1,n,l<<1,  \\kは偶数番目のブロックのインデックス
                w[k-l]=merge(w[k-l],w[k],c));  \\奇数番目のブロックに偶数番目のブロックをマージする
        l<<=1);
  w[1]  \\1番目のブロックを返す
  }

\\w=uniq(v,c)
\\  ベクタvの連続する要素がコンパレータcで等しいとき2番目以降の要素を取り除く
\\  自然順序のときはcmpを指定する
uniq(v,c)={
  my(m=#v,k,w);
  k=1;  \\出力する要素の数
  for(j=2,m,  \\入力インデックス
      if(c(v[j-1],v[j])!=0,k++));  \\直前の要素と等しくなければ出力する
  w=Vec(0,k);w[1]=v[1];  \\先頭の要素は無条件に出力する
  k=1;  \\出力した要素の数
  for(j=2,m,  \\入力インデックス
      if(c(v[j-1],v[j])!=0,k++;w[k]=v[j]));  \\直前の要素と等しくなければ出力する
  w
  }



\\----------------------------------------------------------------------------------------
\\  ビットリーダ/ビットライタ
\\----------------------------------------------------------------------------------------

BLIST=1;
BCODE=2;
BDATA=3;
BFRAC=4;

\\  gpのベクタは変数や引数に代入するとコピーされてしまうので破壊関数を作りにくい
bbox=List();

\\br=bropen(list)
\\  ビットリーダを開く
bropen(list)={
  my(br);
  br=#bbox+1;
  listput(bbox,[list,1,1,0],br);
  br
  }

\\data=brdata(br)
brdata(br)={
  my(data);
  data=bbox[br][BLIST][bbox[br][BDATA]];
  bbox[br][BDATA]++;
  data
  }

\\code=brcode(br,width)
brcode(br,width)={
  my(code);
  code=0;
  while(0<width,
        if(bbox[br][BFRAC]==0,
           bbox[br][BCODE]=bbox[br][BDATA];
           bbox[br][BDATA]++;
           bbox[br][BFRAC]=8);
        if(width<=bbox[br][BFRAC],
           \\足りるとき
           \\  右にfraction-width bitずらして下位width bitを取り出す
           code=bitor(code<<width,
                      bitand(bbox[br][BLIST][bbox[br][BCODE]]>>(bbox[br][BFRAC]-width),(1<<width)-1));
           bbox[br][BFRAC]-=width;
           width=0,
           \\足りないとき
           \\  下位fraction bitをすべて取り出す
           code=bitor(code<<bbox[br][BFRAC],
                      bitand(bbox[br][BLIST][bbox[br][BCODE]],(1<<bbox[br][BFRAC])-1));
           width-=bbox[br][BFRAC];
           bbox[br][BFRAC]=0));
  code
  }

\\brclose(br)
\\  ビットリーダを閉じる
brclose(br)={
  listput(bbox,0,br)
  }

\\bw=bwopen()
\\  ビットライタを開く
bwopen()={
  my(bw);
  bw=#bbox+1;
  listput(bbox,[List(),1,1,0],bw);
  bw
  }

\\bwdata(bw,data)
bwdata(bw,data)={
  listput(bbox[bw][BLIST],bitand(data,255),bbox[bw][BDATA]);
  bbox[bw][BDATA]++
  }

\\bwcode(bw,width,code)
bwcode(bw,width,code)={
  while(0<width,
        if (bbox[bw][BFRAC]==0,
            bbox[bw][BCODE]=bbox[bw][BDATA];
            listput(bbox[bw][BLIST],0,bbox[bw][BDATA]);
            bbox[bw][BDATA]++;
            bbox[bw][BFRAC]=8);
        if(width<=bbox[bw][BFRAC],
           \\入り切るとき
           \\  左にfraction-width bitずらして書き込む
           listput(bbox[bw][BLIST],bitor(bbox[bw][BLIST][bbox[bw][BCODE]],code<<(bbox[bw][BFRAC]-width)),bbox[bw][BCODE]);
           bbox[bw][BFRAC]-=width;
           width=0,
           \\入り切らないとき
           \\  上位fraction bitを右にfraction-width bitずらして書き込む
           listput(bbox[bw][BLIST],bitor(bbox[bw][BLIST][bbox[bw][BCODE]],code>>(width-bbox[bw][BFRAC])),bbox[bw][BCODE]);
           width-=bbox[bw][BFRAC];
           code=bitand(code,(1<<width)-1);
           bbox[bw][BFRAC]=0))
  }

\\list=bwclose(bw)
\\  ビットライタを閉じる
bwclose(bw)={
  my(list);
  list=bbox[bw][BLIST];
  listput(bbox,0,bw);
  list
  }



\\----------------------------------------------------------------------------------------
\\  圧縮/解凍
\\----------------------------------------------------------------------------------------

DICTIONARY_BITS=9;  \\単語辞書の大きさ
DICTIONARY_SIZE=1<<DICTIONARY_BITS;
COMPRESS_PAGE=1;  \\1=単語辞書のページ番号を圧縮する
COMPRESS_CHAR=1;  \\1=文字を圧縮する

\\w=compress(v)
\\  0..255の整数からなるベクタvを圧縮する
compress(inpbuf)={
  my(ptrdic,lendic,chrdic,inplen,bw,inpptr,bstpag,bstlen,pag,len,ptr,equ,wid,tmp,chr);
  ptrdic=vector(DICTIONARY_SIZE);  \\単語辞書。開始位置
  lendic=vector(DICTIONARY_SIZE);  \\単語辞書。長さ
  chrdic=vector(256,n,n-1);  \\文字辞書
  inplen=#inpbuf;  \\入力データの長さ
  bw=bwopen();
  bwdata(bw,inplen>>24);
  bwdata(bw,inplen>>16);
  bwdata(bw,inplen>>8);
  bwdata(bw,inplen);
  inpptr=0;  \\入力ポインタ
  while(inpptr<inplen,
        \\単語辞書から探す
        bstpag=-1;  \\最も長く一致した単語があるページ
        bstlen=0;  \\最も長く一致した単語の長さ
        for(pag=0,DICTIONARY_SIZE-1,
            len=lendic[1+pag];  \\単語辞書にある単語の長さ
            if((bstlen<len)&&(inpptr+len+1<=inplen),  \\これまでより長い、かつ、はみ出さない
               ptr=ptrdic[1+pag];  \\単語辞書にある単語の開始位置
               equ=1;
               for(i=0,len-1,
                   if(inpbuf[1+inpptr+i]!=inpbuf[1+ptr+i],
                      equ=0;
                      break()));
               if(equ,  \\一致した
                  bstpag=pag;
                  bstlen=len)));
        if(bstlen,
           \\単語辞書にある
           bwcode(bw,1,1);
           if(COMPRESS_PAGE,
              \\単語辞書のページ番号を圧縮する
              wid=1;  \\単語辞書のページ番号に2を加えた値の先頭の1を除いたbit数
              tmp=(bstpag+2)>>1;
              while(tmp!=1,
                    wid++;
                    tmp>>=1);
              tmp=(1<<wid)-1;
              bwcode(bw,wid,tmp-1);
              bwcode(bw,wid,bitand(bstpag+2,tmp)),
              \\単語辞書のページ番号を圧縮しない
              bwcode(bw,DICTIONARY_BITS,bstpag)),
           \\単語辞書にない
           bwcode(bw,1,0));
        chr=inpbuf[1+inpptr+bstlen];  \\今回の文字
        if(COMPRESS_CHAR,
           \\文字を圧縮する
           \\文字辞書から探す
           bstpag=-1;  \\文字が一致したページ。必ずある
           for(i=0,255,
               if(chrdic[1+i]==chr,
                  bstpag=i;
                  break()));
           wid=1;  \\文字辞書のページ番号に2を加えた値の先頭の1を除いたbit数
           tmp=(bstpag+2)>>1;
           while(tmp!=1,
                 wid++;
                 tmp>>=1);
           tmp=(1<<wid)-1;
           bwcode(bw,wid,tmp-1);
           bwcode(bw,wid,bitand(bstpag+2,tmp));
           \\今回の文字を文字辞書の先頭に移動させる
           forstep(i=bstpag,1,-1,
                   chrdic[1+i]=chrdic[1+i-1]);
           chrdic[1+0]=chr,
           \\文字を圧縮しない
           bwdata(bw,chr));
        \\1文字伸ばす
        bstlen++;
        \\単語辞書を後ろにずらす
        forstep(i=DICTIONARY_SIZE-1,1,-1,
                ptrdic[1+i]=ptrdic[1+i-1];
                lendic[1+i]=lendic[1+i-1]);
        \\単語辞書の先頭に登録する
        ptrdic[1+0]=inpptr;
        lendic[1+0]=bstlen;
        inpptr+=bstlen);
  Vecsmall(bwclose(bw))
  }

\\v=decompress(w)
\\  0..255の整数からなるベクタwを解凍する
decompress(w)={
  my(ptrdic,lendic,chrdic,outlen,outbuf,outptr,bstlen,wid,pag,ptr,len,chr);
  ptrdic=vector(DICTIONARY_SIZE);  \\単語辞書。ポインタ
  lendic=vector(DICTIONARY_SIZE);  \\単語辞書。長さ
  chrdic=vector(256,n,n-1);  \\文字辞書
  br=bropen(w);
  outlen=brdata(br);
  outlen=(outlen<<8)+brdata(br);
  outlen=(outlen<<8)+brdata(br);
  outlen=(outlen<<8)+brdata(br);
  outbuf=Vecsmall(vector(outlen));
  outptr=0;
  while(outptr<outlen,
        if(brcode(br,1),
           \\単語辞書にある
           if(COMPRESS_PAGE,
              \\単語辞書のページ番号が圧縮されている
              \\単語辞書のページ番号を求める
              wid=1;  \\単語辞書のページ番号に2を加えた値の先頭の1を除いたbit数
              while(brcode(br,1),
                    wid++);
              pag=(1<<wid)+brcode(br,wid)-2,  \\単語辞書のページ番号
              \\単語辞書のページ番号が圧縮されていない
              pag=brcode(br,DICTIONARY_BITS));
           \\単語辞書から取り出す
           ptr=ptrdic[1+pag];
           len=lendic[1+pag];
           for(i=0,len-1,
               outbuf[1+outptr+i]=outbuf[1+ptr+i]);
           bstlen=len,
           \\単語辞書にない
           bstlen=0);
        if(COMPRESS_CHAR,
           \\文字が圧縮されている
           \\文字辞書のページ番号を求める
           wid=1;  \\文字辞書のページ番号に2を加えた値の先頭の1を除いたbit数
           while(brcode(br,1)!=0,
                 wid++);
           bstpag=(1<<wid)+brcode(br,wid)-2;
           \\文字辞書から取り出す
           chr=chrdic[1+bstpag];
           \\取り出した文字を文字辞書の先頭に移動させる
           forstep(i=bstpag,1,-1,
                   chrdic[1+i]=chrdic[1+i-1]);
           chrdic[1+0]=chr,
           \\文字が圧縮されていない
           chr=brdata(br));
        \\文字を出力する
        outbuf[1+outptr+bstlen]=chr;
        \\1文字伸ばす
        bstlen++;
        \\単語辞書を後ろにずらす
        forstep(i=DICTIONARY_SIZE-1,1,-1,
                ptrdic[1+i]=ptrdic[1+i-1];
                lendic[1+i]=lendic[1+i-1]);
        \\単語辞書の先頭に登録する
        ptrdic[1+0]=outptr;
        lendic[1+0]=bstlen;
        outptr+=bstlen);
  brclose(br);
  outbuf
  }

ASM_DECOMPRESS={Str(
"

;--------------------------------------------------------------------------------
;	解凍
;--------------------------------------------------------------------------------

DICTIONARY_BITS	equ	",DICTIONARY_BITS,"
DICTIONARY_SIZE	equ	",DICTIONARY_SIZE,"
COMPRESS_PAGE	equ	",COMPRESS_PAGE,"		;1=単語辞書のページ番号を圧縮する
COMPRESS_CHAR	equ	",COMPRESS_CHAR,"		;1=文字を圧縮する

;----------------------------------------------------------------
;brcode n
;	n bit取り出す
;	n	取り出すbit数。0..25bit
;<d1.l:入力プール。右寄せ
;<d2.w:入力プールの残りbit数
;<a0.l:入力アドレス
;>d0.l:n bitのデータ。0拡張
;>d1.l:入力プール。右寄せ
;>d2.w:入力プールの残りbit数
;>a0.l:入力アドレス
brcode	.macro	n
	sub.w	n,d2
	bpl	@skip
@loop:
	lsl.l	#8,d1
	move.b	(a0)+,d1
	addq.w	#8,d2
	bmi	@loop
@skip:
	move.l	d1,d0
	lsr.l	d2,d0
	lsl.l	d2,d0
	eor.l	d0,d1
	lsr.l	d2,d0
	.endm

;----------------------------------------------------------------
;decompress(in,out)
;	解凍する
;	汎用ではない。エラーチェックを行っていないのでデータが壊れているとクラッシュする
regs		reg	d0-d7/a0-a5
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_a6:	.ds.l	1
_pc:	.ds.l	1
_in:	.ds.l	1			;入力アドレス
_out:	.ds.l	1			;出力アドレス
	.text
	.even
decompress::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
;単語辞書を初期化する
	lea.l	decompress_wdic,a3	;単語辞書
	movea.l	a3,a0
	move.w	#DICTIONARY_SIZE-1,d0
@@:
	clr.l	(a0)+
	clr.l	(a0)+
	dbra	d0,@b
;文字辞書を初期化する
	lea.l	decompress_cdic,a5	;文字辞書
	movea.l	a5,a0
	move.l	#$00010203,d3
	move.l	#$04040404,d4
	moveq.l	#256/4-1,d0
@@:
	move.l	d3,(a0)+
	add.l	d4,d3
	dbra	d0,@b
;
	moveq.l	#0,d1			;入力プール。右寄せ
	moveq.l	#0,d2			;入力プールの残りbit数
	moveq.l	#0,d5			;単語辞書のアドレスのゲタ
	movea.l	(_in,a6),a0		;入力アドレス
	movea.l	(_out,a6),a1		;出力アドレス
	movea.l	a1,a2
	adda.l	(a0)+,a2		;出力バッファの末尾
;解凍ループ
	cmpa.l	a2,a1
	bhs	199f
100:
	brcode	#1			;1bit取り出す
	bne	20f			;単語辞書にある
;単語辞書にない
	moveq.l	#1,d3			;length
	subq.w	#8,d5			;単語辞書のアドレスのゲタをずらす
	and.w	#(DICTIONARY_SIZE-1)<<3,d5
	movem.l	d3/a1,(a3,d5.l)		;単語辞書の先頭に登録する。length,address
	bra	30f

;単語辞書にある
20:
  .if COMPRESS_PAGE
;単語辞書のページ番号が圧縮されている
;単語辞書のページ番号を求める
	moveq.l	#0,d4			;wid。単語辞書のページ番号に2を加えた値の先頭の1を除いたbit数
@@:
	addq.w	#1,d4
	brcode	#1			;brcode(1)
	bne	@b
	brcode	d4			;brcode(wid)
	bset.l	d4,d0			;(1<<wid)+brcode(wid)
	subq.w	#2,d0			;(1<<wid)+brcode(wid)-2。単語辞書のページ番号
  .else
;単語辞書のページ番号が圧縮されていない
	brcode	#DICTIONARY_BITS	;brcode(DICTIONARY_BITS)。単語辞書のページ番号
  .endif
;単語辞書から取り出す
	lsl.l	#3,d0			;ページオフセット
	add.w	d5,d0			;ページオフセットに単語辞書のアドレスのゲタを加える
	and.w	#(DICTIONARY_SIZE-1)<<3,d0
	movem.l	(a3,d0.l),d3/a4		;length,address
;単語辞書のアドレスのゲタをずらす
	subq.l	#8,d5
	and.l	#(DICTIONARY_SIZE-1)<<3,d5
;1文字伸ばす
	addq.l	#1,d3
;単語辞書の先頭に登録する
	movem.l	d3/a1,(a3,d5.l)		;length,address
;単語辞書から取り出した文字を出力する
	subq.l	#1+1,d3
@@:
	move.b	(a4)+,(a1)+
	dbra	d3,@b
30:
  .if COMPRESS_CHAR
;文字が圧縮されている
;文字辞書のページ番号を求める
	moveq.l	#0,d4			;wid。文字辞書のページ番号に2を加えた値の先頭の1を除いたbit数
@@:
	addq.w	#1,d4
	brcode	#1			;brcode(1)
	bne	@b
	brcode	d4			;brcode(wid)
	bset.l	d4,d0			;(1<<wid)+brcode(wid)
	subq.w	#2,d0			;(1<<wid)+brcode(wid)-2。文字辞書のページ番号
;文字辞書から取り出す
	lea.l	(a5,d0.w),a4		;文字辞書のページアドレス
	move.b	(a4),d3
;文字辞書から取り出した文字を出力する
	move.b	d3,(a1)+
;取り出した文字を文字辞書の先頭に移動させる
	bra	2f

1:
	move.b	-(a4),1(a4)
2:
	dbra	d0,1b
	move.b	d3,(a5)
  .else
;文字が圧縮されていない
;入力された文字を出力する
	move.b	(a0)+,(a1)+
  .endif
	cmpa.l	a2,a1
	blo	100b
199:
	movem.l	(_regs,a6),regs
	unlk	a6
	rts

	.bss
	.align	4
decompress_wdic::	.ds.l	2*DICTIONARY_SIZE	;単語辞書。length,address,...
decompress_cdic::	.ds.b	256			;文字辞書。0..255を最近使われた順に並べる
")}



\\----------------------------------------------------------------------------------------
\\  BCD
\\----------------------------------------------------------------------------------------

\\u=encodebcd(x)
\\  整数xをBCDの内部表現を表す符号なし整数に変換する
encodebcd(x)={
  my(v,u);
  if(x<0,error("encodebcd(",x,")"));
  v=Vecsmall(Strprintf("%d",x));
  u=0;
  for(i=1,#v,u=(u<<4)+bitand(v[i],15));
  u
  }

\\x=decodebcd(u)
\\  符号なし整数uをBCDの内部表現と見なして整数に変換する
\\  0..9以外の文字があるとき-1を返す
decodebcd(u)={
  my(x,b,t);
  if(u<0,error("decodebcd(",u,")"));
  x=0;
  b=1;
  while(u,
        t=bitand(u,15);
        if(9<t,return(-1));
        x+=b*t;
        b*=10;
        u>>=4);
  x
  }



\\----------------------------------------------------------------------------------------
\\  特別な数値
\\----------------------------------------------------------------------------------------

\\    Rei   +0
\\    -Rei  -0
\\    Inf   +Inf
\\    -Inf  -Inf
\\    NaN   NaN
\\
\\  type(x)=="t_POL"とx==Reiなどで判別できる。Rei<xは不可
\\  単なる変数なので間違って値を代入しないように注意すること

\\f=iszero(x)
\\  ゼロか
iszero(x)={
  if(x==0,x=Rei);
  if((x==-Rei)||(x==Rei),1,  \\-ReiとReiと0を含む
     0)
  }

\\f=isplus(x)
\\  正か
isplus(x)={
  if(x==0,x=Rei);
  if((x==Rei)||(x==Inf),1,  \\-Reiを含まない。Reiと0を含む
     (x==-Inf)||(x==-Rei)||(x==NaN),0,
     0<x,1,
     0)
  }

\\f=isminus(x)
\\  負か
isminus(x)={
  if(x==0,x=Rei);
  if((x==-Inf)||(x==-Rei),1,  \\-Reiを含む。Reiと0を含まない
     (x==Rei)||(x==Inf)||(x==NaN),0,
     x<0,1,
     0)
  }

\\comparator(x,y)
\\  データをソートするためのコンパレータ。-ReiとReiを区別する
\\  -Inf==-Inf
\\  -Rei==-Rei
\\  Rei==Rei
\\  Inf==Inf
\\  NaN==NaN
\\  -Inf<-1<-Rei<Rei<1<Inf<NaN
comparator(x,y)={
  if(x==0,x=Rei);
  if(y==0,y=Rei);
  if((x==-Inf)&&(y==-Inf),0,
     (x==-Rei)&&(y==-Rei),0,
     (x==Rei)&&(y==Rei),0,
     (x==Inf)&&(y==Inf),0,
     (x==NaN)&&(y==NaN),0,
     x==NaN,1,
     y==NaN,-1,
     x==Inf,1,
     y==Inf,-1,
     x==-Inf,-1,
     y==-Inf,1,
     (x==Rei)&&(y==-Rei),1,
     (x==-Rei)&&(y==Rei),-1,
     (x==Rei)||(x==-Rei),-sign(y),
     (y==Rei)||(y==-Rei),sign(x),
     sign(x-y))
  }

test_comparator()={
  my(v=[-Inf,-1,-Rei,Rei,1,Inf,NaN],f);
  for(y=1,#v,
      for(x=1,#v,
          f=comparator(v[x],v[y]);
          printf("%-10s  ",Str(v[x],if(f<0,"<",f==0,"==",">"),v[y])));
      print())
  }

getexp(x)={
  if(type(x)=="t_POL",
     if(x==-Inf,-Inf,
        x==-Rei,-Rei,
        x==Rei,Rei,
        x==Inf,Inf,
        x==NaN,NaN,
        error("getexp(",x,")")),
     floor(log2(abs(x))))
  }

getman(x)={
  if(type(x)=="t_POL",
     if(x==-Inf,-Inf,
        x==-Rei,-Rei,
        x==Rei,Rei,
        x==Inf,Inf,
        x==NaN,NaN,
        error("getman(",x,")")),
     x/2^floor(log2(abs(x))))
  }



\\----------------------------------------------------------------------------------------
\\  FPSR
\\----------------------------------------------------------------------------------------

fpsr=0;

\\コンディションコードバイト
MI=1<<27;
ZE=1<<26;
IN=1<<25;
NA=1<<24;
\\エクセプションバイト
BS=1<<15;
SN=1<<14;
OE=1<<13;
OF=1<<12;
UF=1<<11;
DZ=1<<10;
X2=1<<9;
X1=1<<8;
\\アクルードエクセプションバイト
AV=1<<7;
AO=1<<6;
AU=1<<5;
AZ=1<<4;
AX=1<<3;

FPSR_MASK_1=[MI,ZE,IN,NA];
FPSR_NAME_1=["MI","ZE","IN","NA"];
FPSR_MASK_2=[BS,SN,OE,OF,UF,DZ,X2,X1,AV,AO,AU,AZ,AX];
FPSR_NAME_2=["BS","SN","OE","OF","UF","DZ","X2","X1","AV","AO","AU","AZ","AX"];

\\s=strfpsr(sr)
\\  fpsrを文字列に変換する
strfpsr(sr)={
  my(s,n);
  if(sr==0,"0",
     s="";
     for(i=1,#FPSR_MASK_1,
         if(bitand(sr,FPSR_MASK_1[i])!=0,
            if(s!="",s=concat(s,"+"));
            s=concat(s,FPSR_NAME_1[i])));
     if(bitand(sr>>23,1)!=0,
        if(s!="",s=concat(s,"+"));
        s=concat(s,Str("(",bitand(sr>>23,1),"<<23)")));
     if(bitand(sr>>16,127)!=0,
        if(s!="",s=concat(s,"+"));
        s=concat(s,Str("(",bitand(sr>>16,127),"<<16)")));
     for(i=1,#FPSR_MASK_2,
         if(bitand(sr,FPSR_MASK_2[i])!=0,
            if(s!="",s=concat(s,"+"));
            s=concat(s,FPSR_NAME_2[i]))));
  s
  }

\\fpsr_update_ccr(x)
\\  fpsrのコンディションコードバイトを更新する
fpsr_update_ccr(x)={
  fpsr=bitand(fpsr,(1<<24)-1);
  if(x==Rei,fpsr=bitor(fpsr,ZE),
     x==-Rei,fpsr=bitor(fpsr,MI+ZE),
     x==Inf,fpsr=bitor(fpsr,IN),
     x==-Inf,fpsr=bitor(fpsr,MI+IN),
     x==NaN,fpsr=bitor(fpsr,NA),
     x<0,fpsr=bitor(fpsr,MI))
  }

\\  fpsrのアクルードエクセプションバイトを更新する
fpsr_update_aer()={
  if(bitand(fpsr,BS+SN+OE)!=0,fpsr=bitor(fpsr,AV));
  if(bitand(fpsr,OF)!=0,fpsr=bitor(fpsr,AO));
  if(bitand(fpsr,UF+X2)==(UF+X2),fpsr=bitor(fpsr,AU));
  if(bitand(fpsr,DZ)!=0,fpsr=bitor(fpsr,AZ));
  if(bitand(fpsr,OF+X2+X1)!=0,fpsr=bitor(fpsr,AX))
  }



\\----------------------------------------------------------------------------------------
\\  FPCR
\\----------------------------------------------------------------------------------------

\\  rp=0..2  丸め桁数
EXD=0;  \\extended 拡張精度
SGL=1;  \\single 単精度
DBL=2;  \\double 倍精度
DBL3=3;  \\double 倍精度

\\  rm=0..3  丸めモード
RN=0;  \\to nearest
RZ=1;  \\toward zero
RM=2;  \\toward minus infinity
RP=3;  \\toward plus infinity
RMSTR=["RN","RZ","RM","RP"];
strrm(rm)=RMSTR[1+rm];
strrmf(rm,s)=Str(RMSTR[1+rm],"(",s,")");

\\  rprm=0..11  丸め桁数と丸めモード
XRN=(EXD<<2)+RN;
XRZ=(EXD<<2)+RZ;
XRM=(EXD<<2)+RM;
XRP=(EXD<<2)+RP;
SRN=(SGL<<2)+RN;
SRZ=(SGL<<2)+RZ;
SRM=(SGL<<2)+RM;
SRP=(SGL<<2)+RP;
DRN=(DBL<<2)+RN;
DRZ=(DBL<<2)+RZ;
DRM=(DBL<<2)+RM;
DRP=(DBL<<2)+RP;

\\s=strrprm(rprm)
\\  rprmを文字列に変換する
STRRPRM=["XRN","XRZ","XRM","XRP","SRN","SRZ","SRM","SRP","DRN","DRZ","DRM","DRP"];
strrprm(rprm)=STRRPRM[1+rprm];

\\  以下は拡張
\\  型変換を行う関数の引数の丸め桁数rpに指定する
\\  FPCRには指定できない
TPL=4;  \\triple 三倍精度
QPL=5;  \\quadruple 四倍精度
SPL=6;  \\sextuple 六倍精度
OPL=7;  \\octuple 八倍精度
XSG=8;  \\xsingle 拡張単精度
XDB=9;  \\xdouble 拡張倍精度
EFP=10;  \\efp efp
BYTE=11;  \\byte バイト
WORD=12;  \\word ワード
LONG=13;  \\long ロング
QUAD=14;  \\quad クワッド



\\----------------------------------------------------------------------------------------
\\  浮動小数点数の内部表現
\\----------------------------------------------------------------------------------------

\\  perl -e "printf qq@%c%c    %9s%5s%5s%4s%4s%4s%5s%7s%8s%8s%8s%7s%5s%5s%5s\n@,92,92,'name','inr','bit','sw','ew','iw','fw','bias','demin','demax','nomin','nomax','dgt','hex','imm';for my$i(['single','sgl',8,0,23,8,'sgh','sgi'],['double','dbl',11,0,52,16,'dbh','dbi'],['extended','exd',15,1,63,24,'exh','exi'],['triple','tpl',15,1,79,24,'tph','tpi'],['quadruple','qpl',15,0,112,32,'qph','qpi'],['sextuple','spl',15,0,176,48,'sph','spi'],['octuple','opl',15,0,240,64,'oph','opi'],['xsingle','xsg',15,1,23,10,'xsh','xsi'],['xdouble','xdb',15,1,52,18,'xdh','xdi'],['efp','efp',16,1,91,28,'efh','efi']){my($name,$inr,$ew,$iw,$fw,$dgt,$hex,$imm)=@$i;my$bias=(1<<($ew-1))-1;my$demin=1-$iw-$bias-$fw;my$demax=-$iw-$bias;my$nomin=1-$iw-$bias;my$nomax=$bias;printf qq@%c%c    %9s%5s%5d%4d%4d%4d%5d%7d%8d%8d%8d%7d%5d%5s%5s\n@,92,92,$name,$inr,1+$ew+$iw+$fw,1,$ew,$iw,$fw,$bias,$demin,$demax,$nomin,$nomax,$dgt,$hex,$imm;}"
\\         name  inr  bit  sw  ew  iw   fw   bias   demin   demax   nomin  nomax  dgt  hex  imm
\\       single  sgl   32   1   8   0   23    127    -149    -127    -126    127    8  sgh  sgi
\\       double  dbl   64   1  11   0   52   1023   -1074   -1023   -1022   1023   16  dbh  dbi
\\     extended  exd   80   1  15   1   63  16383  -16446  -16384  -16383  16383   24  exh  exi
\\       triple  tpl   96   1  15   1   79  16383  -16462  -16384  -16383  16383   24  tph  tpi
\\    quadruple  qpl  128   1  15   0  112  16383  -16494  -16383  -16382  16383   32  qph  qpi
\\     sextuple  spl  192   1  15   0  176  16383  -16558  -16383  -16382  16383   48  sph  spi
\\      octuple  opl  256   1  15   0  240  16383  -16622  -16383  -16382  16383   64  oph  opi
\\      xsingle  xsg   40   1  15   1   23  16383  -16406  -16384  -16383  16383   10  xsh  xsi
\\      xdouble  xdb   69   1  15   1   52  16383  -16435  -16384  -16383  16383   18  xdh  xdi
\\          efp  efp  109   1  16   1   91  32767  -32858  -32768  -32767  32767   28  efh  efi
\\
\\    ew  浮動小数点数の内部表現の指数部のbit数
\\    iw  浮動小数点数の内部表現の整数部のbit数
\\    fw  浮動小数点数の内部表現の小数部のbit数
\\    bias=(1<<(ew-1))-1;  \\指数のバイアス
\\    demin=1-iw-bias-fw;  \\非正規化数の指数の下限
\\    demax=-iw-bias;  \\非正規化数の指数の上限
\\    nomin=1-iw-bias;  \\正規化数の指数の下限
\\    nomax=bias;  \\正規化数の指数の上限
\\

SGLDEMIN=2^-149;             \\0x3F6A8000000000000000 0x00000001 単精度 非正規化数 最小値
SGLDEMAX=2^-126-2^-149;      \\0x3F80FFFFFE0000000000 0x007FFFFF 単精度 非正規化数 最大値
SGLNOMIN=2^-126;             \\0x3F818000000000000000 0x00800000 単精度 正規化数 最小値
SGLNOMAX=2^128-2^104;        \\0x407EFFFFFF0000000000 0x7F7FFFFF 単精度 正規化数 最大値

DBLDEMIN=2^-1074;            \\0x3BCD8000000000000000 0x0000000000000001 倍精度 非正規化数 最小値
DBLDEMAX=2^-1022-2^-1074;    \\0x3C00FFFFFFFFFFFFF000 0x000FFFFFFFFFFFFF 倍精度 非正規化数 最大値
DBLNOMIN=2^-1022;            \\0x3C018000000000000000 0x0010000000000000 倍精度 正規化数 最小値
DBLNOMAX=2^1024-2^971;       \\0x43FEFFFFFFFFFFFFF800 0x7FEFFFFFFFFFFFFF 倍精度 正規化数 最大値

EXDDEMIN=2^-16446;           \\0x00000000000000000001 拡張精度 非正規化数 最小値
EXDDEMAX=2^-16383-2^-16446;  \\0x00007FFFFFFFFFFFFFFF 拡張精度 非正規化数 最大値
EXDNOMIN=2^-16383;           \\0x00008000000000000000 拡張精度 正規化数 最小値
EXDNOMAX=2^16384-2^16320;    \\0x7FFEFFFFFFFFFFFFFFFF 拡張精度 正規化数 最大値

TPLDEMIN=2^-16462;           \\0x000000000000000000000001 三倍精度 非正規化数 最小値
TPLDEMAX=2^-16383-2^-16462;  \\0x00007FFFFFFFFFFFFFFFFFFF 三倍精度 非正規化数 最大値
TPLNOMIN=2^-16383;           \\0x000080000000000000000000 三倍精度 正規化数 最小値
TPLNOMAX=2^16384-2^16304;    \\0x7FFEFFFFFFFFFFFFFFFFFFFF 三倍精度 正規化数 最大値

QPLDEMIN=2^-16494;           \\0x00000000000000000000000000000001 四倍精度 非正規化数 最小値
QPLDEMAX=2^-16382-2^-16494;  \\0x0000FFFFFFFFFFFFFFFFFFFFFFFFFFFF 四倍精度 非正規化数 最大値
QPLNOMIN=2^-16382;           \\0x00010000000000000000000000000000 四倍精度 正規化数 最小値
QPLNOMAX=2^16384-2^16271;    \\0x7FFEFFFFFFFFFFFFFFFFFFFFFFFFFFFF 四倍精度 正規化数 最大値

SPLDEMIN=2^-16558;           \\0x000000000000000000000000000000000000000000000001 六倍精度 非正規化数 最小値
SPLDEMAX=2^-16382-2^-16558;  \\0x0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF 六倍精度 非正規化数 最大値
SPLNOMIN=2^-16382;           \\0x000100000000000000000000000000000000000000000000 六倍精度 正規化数 最小値
SPLNOMAX=2^16384-2^16207;    \\0x7FFEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF 六倍精度 正規化数 最大値

OPLDEMIN=2^-16622;           \\0x0000000000000000000000000000000000000000000000000000000000000001 八倍精度 非正規化数 最小値
OPLDEMAX=2^-16382-2^-16622;  \\0x0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF 八倍精度 非正規化数 最大値
OPLNOMIN=2^-16382;           \\0x0001000000000000000000000000000000000000000000000000000000000000 八倍精度 正規化数 最小値
OPLNOMAX=2^16384-2^16143;    \\0x7FFEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF 八倍精度 正規化数 最大値

XSGDEMIN=2^-16406;           \\0x0000000001 拡張単精度 非正規化数 最小値
XSGDEMAX=2^-16383-2^-16406;  \\0x00007FFFFF 拡張単精度 非正規化数 最大値
XSGNOMIN=2^-16383;           \\0x0000800000 拡張単精度 正規化数 最小値
XSGNOMAX=2^16384-2^16360;    \\0x7FFEFFFFFF 拡張単精度 正規化数 最大値

XDBDEMIN=2^-16435;           \\0x000000000000000001 拡張倍精度 非正規化数 最小値
XDBDEMAX=2^-16383-2^-16435;  \\0x00000FFFFFFFFFFFFF 拡張倍精度 非正規化数 最大値
XDBNOMIN=2^-16383;           \\0x000010000000000000 拡張倍精度 正規化数 最小値
XDBNOMAX=2^16384-2^16331;    \\0x0FFFDFFFFFFFFFFFFF 拡張倍精度 正規化数 最大値

EFPDEMIN=2^-32858;           \\0x0000000000000000000000000001 efp 非正規化数 最小値
EFPDEMAX=2^-32767-2^-32858;  \\0x000007FFFFFFFFFFFFFFFFFFFFFF efp 非正規化数 最大値
EFPNOMIN=2^-32767;           \\0x0000080000000000000000000000 efp 正規化数 最小値
EFPNOMAX=2^32768-2^32676;    \\0x0FFFEFFFFFFFFFFFFFFFFFFFFFFF efp 正規化数 最大値

BYTEMIN=-2^7;    \\0x80 バイト 最小値
BYTEMAX=2^7-1;   \\0x7F バイト 最大値
WORDMIN=-2^15;   \\0x8000 ワード 最小値
WORDMAX=2^15-1;  \\0x7FFF ワード 最大値
LONGMIN=-2^31;   \\0x80000000 ロング 最小値
LONGMAX=2^31-1;  \\0x7FFFFFFF ロング 最大値
QUADMIN=-2^63;   \\0x8000000000000000 クワッド 最小値
QUADMAX=2^63-1;  \\0x7FFFFFFFFFFFFFFF クワッド 最大値


\\x=xxxtonum(u,ew,iw,fw)
\\  (1+ew+iw+fw)bit符号なし整数uを浮動小数点数の内部表現と見なして数値または特別な数値に変換する
\\    x   数値または特別な数値
\\    u   (1+ew+iw+fw)bit符号なし整数
\\    ew  浮動小数点数の内部表現の指数部のbit数
\\    iw  浮動小数点数の内部表現の整数部のbit数
\\    fw  浮動小数点数の内部表現の小数部のbit数
xxxtonum(u,ew,iw,fw)={
  my(eb,sp,ep,ip,fp,sv);
  eb=(1<<(ew-1))-1;  \\指数のバイアス
  sp=u>>(ew+iw+fw);  \\符号部
  ep=bitand(u>>(iw+fw),(1<<ew)-1);  \\指数部
  ip=bitand(u>>fw,(1<<iw)-1);  \\整数部
  fp=bitand(u,(1<<fw)-1);  \\小数部
  sv=if(sp==0,1,-1);  \\符号
  if(ep==((1<<ew)-1),  \\指数部がすべて1
     if(fp==0,sv*Inf,  \\指数部がすべて1で小数部がすべて0ならば±Inf
        NaN),  \\指数部がすべて1で小数部が0でなければNaN
     iw==0,
     \\整数部がないとき(single,double)
     \\  指数部が0でなければ正規化数、指数部が0で小数部が0でなければ非正規化数、指数部が0で小数部も0ならば0
     \\  指数部が1の正規化数と指数部が0の非正規化数は小数点の位置が同じで同じ指数
     if(ep!=0,sv*2^(ep-eb-fw)*((1<<fw)+fp),  \\指数部が0でなければ正規化数
        fp!=0,sv*2^(1-eb-fw)*fp,  \\指数部が0で小数部が0でなければ非正規化数
        sv*Rei),  \\指数部が0で小数部も0ならば±0
     \\整数部があるとき(extended)
     \\  整数部が0でなければ正規化数、指数部と整数部が0で小数部が0でなければ非正規化数、指数部と整数部と小数部が0ならば±0、それ以外はNaN
     \\  指数部が0の正規化数と指数部が0の非正規化数は小数点の位置が同じで同じ指数
     if((ip!=0),sv*2^(ep-eb-fw)*((ip<<fw)+fp),  \\整数部が0でなければ正規化数
        (ep==0)&&(ip==0)&&(fp!=0),sv*2^(0-eb-fw)*fp,  \\指数部と整数部が0で小数部が0でなければ非正規化数
        (ep==0)&&(ip==0)&&(fp==0),sv*Rei,  \\指数部と整数部と小数部が0ならば±0
        NaN))  \\それ以外はNaN
  }

\\x=sgltonum(u)
\\  32bit符号なし整数をsingleの内部表現と見なして数値または特別な数値に変換する
\\    x   数値または特別な数値
\\    u   32bit符号なし整数
sgltonum(u)=xxxtonum(u,8,0,23);

\\x=dbltonum(u)
\\  64bit符号なし整数をdoubleの内部表現と見なして数値または特別な数値に変換する
\\    x   数値または特別な数値
\\    u   64bit符号なし整数
dbltonum(u)=xxxtonum(u,11,0,52);

\\x=exdtonum(u)
\\  96bit符号なし整数をextendedの内部表現と見なして数値または特別な数値に変換する
\\    x   数値または特別な数値
\\    u   96bit符号なし整数
exdtonum(u)={
  \\  |符号部と指数部(16bit)|空き(16bit)|仮数部(64bit)|
  \\                   ↓
  \\  |符号部と指数部(16bit)|仮数部(64bit)|
  u=((bitand(u,(1<<96)-(1<<80))>>16)+  \\符号部と指数部(16bit)
     bitand(u,(1<<64)-(1<<0)));  \\仮数部(64bit)
  xxxtonum(u,15,1,63)
  }

\\x=tpltonum(u)
\\  96bit符号なし整数をtripleの内部表現と見なして数値または特別な数値に変換する
\\    x   数値または特別な数値
\\    u   96bit符号なし整数
tpltonum(u)={
  \\  |符号部と指数部(16bit)|仮数部の下位(16bit)|仮数部の上位(64bit)|
  \\                                ↓
  \\  |符号部と指数部(16bit)|仮数部の上位(64bit)|仮数部の下位(16bit)|
  u=(bitand(u,(1<<96)-(1<<80))+  \\符号部と指数部(16bit)
     (bitand(u,(1<<64)-(1<<0))<<16)+  \\仮数部の上位(64bit)
     (bitand(u,(1<<80)-(1<<64))>>64));  \\仮数部の下位(16bit)
  xxxtonum(u,15,1,79)
  }

\\x=qpltonum(u)
\\  128bit符号なし整数をquadrupleの内部表現と見なして数値または特別な数値に変換する
\\    x   数値または特別な数値
\\    u   128bit符号なし整数
qpltonum(u)=xxxtonum(u,15,0,112);

\\x=spltonum(u)
\\  192bit符号なし整数をsextupleの内部表現と見なして数値または特別な数値に変換する
\\    x   数値または特別な数値
\\    u   192bit符号なし整数
spltonum(u)=xxxtonum(u,15,0,176);

\\x=opltonum(u)
\\  256bit符号なし整数をoctupleの内部表現と見なして数値または特別な数値に変換する
\\    x   数値または特別な数値
\\    u   256bit符号なし整数
opltonum(u)=xxxtonum(u,15,0,240);

\\x=xsgtonum(u)
\\  40bit符号なし整数をxsingleの内部表現と見なして数値または特別な数値に変換する
\\    x   数値または特別な数値
\\    u   40bit符号なし整数
xsgtonum(u)=xxxtonum(u,15,1,23);

\\x=xdbtonum(u)
\\  69bit符号なし整数をxdoubleの内部表現と見なして数値または特別な数値に変換する
\\    x   数値または特別な数値
\\    u   69bit符号なし整数
xdbtonum(u)=xxxtonum(u,15,1,52);

\\x=efptonum(u)
\\  109bit符号なし整数をefpの内部表現と見なして数値または特別な数値に変換する
\\    x   数値または特別な数値
\\    u   109bit符号なし整数
efptonum(u)=xxxtonum(u,16,1,91);


\\x=sghtonum(s)
\\  8桁の16進数の文字列をsingleの内部表現と見なして数値または特別な数値に変換する
\\    s   8桁の16進数の文字列
\\    x   数値または特別な数値
sghtonum(s)=sgltonum(hex(s));

\\x=dbhtonum(s)
\\  16桁の16進数の文字列をdoubleの内部表現と見なして数値または特別な数値に変換する
\\    s   16桁の16進数の文字列
\\    x   数値または特別な数値
dbhtonum(s)=dbltonum(hex(s));

\\x=exhtonum(s)
\\  24桁の16進数の文字列をextendedの内部表現と見なして数値または特別な数値に変換する
\\    s   24桁の16進数の文字列
\\    x   数値または特別な数値
exhtonum(s)=exdtonum(hex(s));

\\x=tphtonum(s)
\\  24桁の16進数の文字列をtripleの内部表現と見なして数値または特別な数値に変換する
\\    s   24桁の16進数の文字列
\\    x   数値または特別な数値
tphtonum(s)=tpltonum(hex(s));

\\x=qphtonum(s)
\\  32桁の16進数の文字列をquadrupleの内部表現と見なして数値または特別な数値に変換する
\\    s   32桁の16進数の文字列
\\    x   数値または特別な数値
qphtonum(s)=qpltonum(hex(s));

\\x=spltonum(s)
\\  48桁の16進数の文字列をsextupleの内部表現と見なして数値または特別な数値に変換する
\\    s   48桁の16進数の文字列
\\    x   数値または特別な数値
sphtonum(s)=spltonum(hex(s));

\\x=opltonum(s)
\\  64桁の16進数の文字列をoctupleの内部表現と見なして数値または特別な数値に変換する
\\    s   64桁の16進数の文字列
\\    x   数値または特別な数値
ophtonum(s)=opltonum(hex(s));

\\x=xshtonum(s)
\\  10桁の16進数の文字列をxsingleの内部表現と見なして数値または特別な数値に変換する
\\    s   10桁の16進数の文字列
\\    x   数値または特別な数値
xshtonum(s)=xsgtonum(hex(s));

\\x=xdhtonum(s)
\\  18桁の16進数の文字列をxdoubleの内部表現と見なして数値または特別な数値に変換する
\\    s   18桁の16進数の文字列
\\    x   数値または特別な数値
xdhtonum(s)=xdbtonum(hex(s));

\\x=efhtonum(s)
\\  28桁の16進数の文字列をefpの内部表現と見なして数値または特別な数値に変換する
\\    s   28桁の16進数の文字列
\\    x   数値または特別な数値
efhtonum(s)=efptonum(hex(s));


\\y=round_fw(x,fw,rm)
\\  数値または特別な数値xを仮数部が(1+fw)bitの数値または特別な数値に丸めモードrmで丸める
\\  指数部は無制限
\\  指数部が無制限なので正規化数と非正規化数の範囲は設定されない
\\  絶対値の大きい数値がオーバーフローして±Infに変化することはない
\\  絶対値の小さい数値がアンダーフローして±0に変化することはない(log2(abs(x))を計算できない場合を除く)
\\  ±Infや±0が丸めモードによって数値に変化することはない
\\     y  仮数部が(1+fw)bitの数値または特別な数値
\\     x  数値または特別な数値
\\    fw  小数部のbit数
\\    rm  丸めモード
\\  fpsr
\\    UF  アンダーフロー。log2(abs(x))を計算できない場合
\\    X2  不正確な結果
round_fw(x,fw,rm)={
  my(a,e,t,m);
  if(type(x)=="t_POL",return(x));  \\特別な数値はそのまま返す
  if(x==0,return(Rei));  \\数値の0はReiに変換する
  a=abs(x);  \\絶対値
  if(a<=LOG_ZERO,  \\0ではないが0に近すぎてlog2(abs(x))を計算できない
     fpsr=bitor(fpsr,UF+X2);  \\アンダーフロー、不正確な結果
     return(if(x<0,-Rei,Rei)));  \\±0
  e=floor(log2(a));  \\指数
  t=a*2^(fw-e);
  m=floor(t);  \\仮数部の先頭(1+fw)bit
  t-=m;  \\仮数部の端数
  if(t!=0,  \\端数がある
     fpsr=bitor(fpsr,X2);  \\不正確な結果
     if(((rm==RN)&&(((1/2)<t)||
                    ((t==(1/2))&&(bitand(m,1)==1))))||  \\RNで端数が1/2より大きいか端数が1/2と等しくて1の位が1
        ((rm==RM)&&(x<0))||  \\端数が0ではなくてRMで-または
        ((rm==RP)&&(0<x)),  \\端数が0ではなくてRPで+
        m++;  \\切り上げる
        if(m==1<<(1+fw),  \\1桁増えた
           m=1<<fw;
           e++)));  \\指数部をインクリメントする
  if((m<2^fw)||(2^(1+fw)<=m),error("round_fw(",x,",",rm,",",fw,")"));
  sign(x)*m*2^(e-fw)
  }

\\y=roundsgl(x,rm)
\\  数値または特別な数値xを仮数部が(1+23)bitの数値または特別な数値に丸めモードrmで丸める
\\  指数部は無制限
\\     y  仮数部が(1+23)bitの数値または特別な数値
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    UF  アンダーフロー。log2(abs(x))を計算できない場合
\\    X2  不正確な結果
roundsgl(x,rm)=round_fw(x,23,rm);

\\y=rounddbl(x,rm)
\\  数値または特別な数値xを仮数部が(1+52)bitの数値または特別な数値に丸めモードrmで丸める
\\  指数部は無制限
\\     y  仮数部が(1+52)bitの数値または特別な数値
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    UF  アンダーフロー。log2(abs(x))を計算できない場合
\\    X2  不正確な結果
rounddbl(x,rm)=round_fw(x,52,rm);

\\y=roundexd(x,rm)
\\  数値または特別な数値xを仮数部が(1+63)bitの数値または特別な数値に丸めモードrmで丸める
\\  指数部は無制限
\\     y  仮数部が(1+63)bitの数値または特別な数値
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    UF  アンダーフロー。log2(abs(x))を計算できない場合
\\    X2  不正確な結果
roundexd(x,rm)=round_fw(x,63,rm);

\\y=roundtpl(x,rm)
\\  数値または特別な数値xを仮数部が(1+79)bitの数値または特別な数値に丸めモードrmで丸める
\\  指数部は無制限
\\     y  仮数部が(1+79)bitの数値または特別な数値
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    UF  アンダーフロー。log2(abs(x))を計算できない場合
\\    X2  不正確な結果
roundtpl(x,rm)=round_fw(x,79,rm);

\\y=roundqpl(x,rm)
\\  数値または特別な数値xを仮数部が(1+112)bitの数値または特別な数値に丸めモードrmで丸める
\\  指数部は無制限
\\     y  仮数部が(1+112)bitの数値または特別な数値
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    UF  アンダーフロー。log2(abs(x))を計算できない場合
\\    X2  不正確な結果
roundqpl(x,rm)=round_fw(x,112,rm);

\\y=roundspl(x,rm)
\\  数値または特別な数値xを仮数部が(1+176)bitの数値または特別な数値に丸めモードrmで丸める
\\  指数部は無制限
\\     y  仮数部が(1+176)bitの数値または特別な数値
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    UF  アンダーフロー。log2(abs(x))を計算できない場合
\\    X2  不正確な結果
roundspl(x,rm)=round_fw(x,176,rm);

\\y=roundopl(x,rm)
\\  数値または特別な数値xを仮数部が(1+240)bitの数値または特別な数値に丸めモードrmで丸める
\\  指数部は無制限
\\     y  仮数部が(1+240)bitの数値または特別な数値
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    UF  アンダーフロー。log2(abs(x))を計算できない場合
\\    X2  不正確な結果
roundopl(x,rm)=round_fw(x,240,rm);

\\y=roundefp(x,rm)
\\  数値または特別な数値xを仮数部が(1+91)bitの数値または特別な数値に丸めモードrmで丸める
\\  指数部は無制限
\\     y  仮数部が(1+91)bitの数値または特別な数値
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    UF  アンダーフロー。log2(abs(x))を計算できない場合
\\    X2  不正確な結果
roundefp(x,rm)=round_fw(x,91,rm);


\\y=roundxxx(x,rp,rm)
\\  数値または特別な数値xを仮数部が丸め桁数rpと同じbit数の数値または特別な数値に丸めモードrmで丸める
\\  指数部は無制限
\\     y  仮数部が丸め桁数rpと同じbit数の数値または特別な数値
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    UF  アンダーフロー。log2(abs(x))を計算できない場合
\\    X2  不正確な結果
roundxxx(x,rp,rm)={
  if(rp==SGL,roundsgl(x,rm),
     (rp==DBL)||(rp==DBL3),rounddbl(x,rm),
     rp==EXD,roundexd(x,rm),
     rp==TPL,roundtpl(x,rm),
     rp==QPL,roundqpl(x,rm),
     rp==SPL,roundspl(x,rm),
     rp==OPL,roundopl(x,rm),
     rp==EFP,roundefp(x,rm),
     error("roundxxx(",x,",",rp,",",rm,")"))
  }


\\u=numtoxxx(x,rm,ew,iw,fw)
\\  数値または特別な数値を浮動小数点数の内部表現の符号なし整数に変換する
\\  数値が特別な数値に変化することがある
\\  絶対値の大きい数値が±Infに変化することがある(オーバーフロー)
\\  絶対値の小さい数値が±0に変化することがある(アンダーフロー)
\\  ±Infや±0が丸めモードによって数値に変化することがある
\\     u  (1+ew+iw+fw)bit符号なし整数
\\     x  数値または特別な数値
\\    rm  丸めモード
\\    ew  浮動小数点数の内部表現の指数部のbit数
\\    iw  浮動小数点数の内部表現の整数部のbit数
\\    fw  浮動小数点数の内部表現の小数部のbit数
\\  fpsr
\\    OF  オーバーフロー
\\        指数部が正規化数の最大値を上回っているときセット
\\        0に近付く方向に丸めて正規化数の最大値になったときもセット
\\    UF  アンダーフロー
\\        singleまたはdoubleの
\\          丸める前の値が0でなくて正規化数の最小値を下回っているときセット
\\          (丸めた結果が正規化数の最小値になったときもセットされる)
\\        extendedまたはxsingle
\\          丸めた結果が非正規化数のときセット
\\    X2  不正確な結果
\\        丸める前の値の端数が0でないときセット
\\        アンダーフローしたときセット
\\        オーバーフローしたときは端数が0でないときだけセット
numtoxxx(x,rm,ew,iw,fw)={
  my(bias,demin,demax,nomin,nomax,a,z,e,o,t,m);
  bias=(1<<(ew-1))-1;  \\指数のバイアス
  demin=1-iw-bias-fw;  \\非正規化数の指数の下限
  demax=-iw-bias;  \\非正規化数の指数の上限
  nomin=1-iw-bias;  \\正規化数の指数の下限
  nomax=bias;  \\正規化数の指数の上限
  if(type(x)=="t_POL",
     return(if(x==Rei,if(rm==RP,1,0),
               x==-Rei,(1<<(ew+iw+fw))+if(rm==RM,1,0),
               x==Inf,(((1<<ew)-1)<<(iw+fw))-if((rm==RZ)||(rm==RM),1,0),
               x==-Inf,(1<<(ew+iw+fw))+(((1<<ew)-1)<<(iw+fw))-if((rm==RZ)||(rm==RP),1,0),
               x==NaN,(1<<(ew+iw+fw))-1,
               error("numtoxxx(",x,",",rm,",",ew,",",iw,",",rw,")"))));
  a=abs(x);  \\絶対値
  z=if(x<0,1<<(ew+iw+fw),0);  \\符号
  if(x==0,return(z));  \\±0
  if(a<=LOG_ZERO,  \\0ではないが0に近すぎる。0に近すぎるとlog2(a)の計算に失敗する
     fpsr=bitor(fpsr,UF+X2);  \\アンダーフロー、不正確な結果
     return(z));  \\±0
  e=floor(log2(a));  \\指数
  \\if(a<2^e,e--);  \\補正する
  if(e<demin-1,  \\指数部が小さすぎる。丸めで繰り上がる場合があるので一旦非正規化数の指数の下限-1まで受け入れる
     fpsr=bitor(fpsr,UF+X2);  \\アンダーフロー、不正確な結果
     \\符号を跨がず±0から遠ざかる方向に丸めるときは±0ではなく絶対値が最小の非正規化数を返す
     return(z+if(((x<0)&&(rm==RM))||((0<x)&&(rm==RP)),1,0)));
  o=if(demax<e,1+fw,e-demax+fw);  \\1+小数部のbit数。正規化数のときo==1+fw、非正規化数のときo<1+fw
  t=a*2^(o-1-e);
  m=floor(t);  \\仮数部の先頭(o)bit
  t-=m;  \\仮数部の端数
  if(if(o==0,m!=0,(m<2^(o-1))||(2^o<=m)),error("numtoxxx(",x,",",rm,",",ew,",",iw,",",fw,")"));
  if(nomax<e,  \\指数部が大きすぎる
     fpsr=bitor(fpsr,OF);  \\オーバーフロー
     if(t!=0,fpsr=bitor(fpsr,X2));  \\不正確な結果
     \\±0に近付く方向に丸めるときは±Infではなく絶対値が最大の正規化数を返す
     return(z+(((1<<ew)-1)<<(iw+fw))-if(((x<0)&&((rm==RZ)||(rm==RP)))||((0<x)&&((rm==RZ)||(rm==RM))),1,0)));
  if(ew<15,  \\singleまたはdoubleのとき
     if(o<1+fw,  \\非正規化数
        fpsr=bitor(fpsr,UF)));  \\アンダーフロー
  if(t!=0,  \\端数が0ではない
     fpsr=bitor(fpsr,X2);  \\不正確な結果
     if(((rm==RN)&&(((1/2)<t)||
                    ((t==(1/2))&&(bitand(m,1)==1))))||  \\RNで端数が1/2より大きいか端数が1/2と等しくて1の位が1
        ((rm==RM)&&(x<0))||  \\端数が0ではなくてRMで-または
        ((rm==RP)&&(0<x)),  \\端数が0ではなくてRPで+のとき
        m++;  \\繰り上げる
        if(m==(1<<o),  \\1桁増えた
           if(o==1+fw,  \\正規化数が溢れた
              m>>=1;
              e++;  \\指数部をインクリメントする
              if(nomax<e,  \\指数部が溢れた
                 fpsr=bitor(fpsr,OF);  \\オーバーフロー
                 \\±0に近付く方向に丸めるときは±Infではなく絶対値が最大の正規化数を返す
                 return(z+(((1<<ew)-1)<<(iw+fw))-if(((x<0)&&((rm==RZ)||(rm==RP)))||((0<x)&&((rm==RZ)||(rm==RM))),1,0))),
              m==(1<<fw),  \\非正規化数が正規化数になった
              e=nomin))));
  if(e<nomin,  \\非正規化数
     fpsr=bitor(fpsr,UF));  \\アンダーフロー
  if(m==0,  \\非正規化数が指数の下限-1から繰り上がらなかった
     \\符号を跨がず±0から遠ざかる方向に丸めるときは±0ではなく絶対値が最小の非正規化数を返す
     return(z+if(((x<0)&&(rm==RM))||((0<x)&&(rm==RP)),1,0)));
  z+(if(0<=bias+e,bias+e,0)<<(iw+fw))+bitand(m,(1<<(iw+fw))-1)
  }
numtoxxx2(x,rm,ew,iw,fw)={
  my(bias,demin,demax,nomin,nomax,a,z,e,o,t,m);
  bias=(1<<(ew-1))-1;  \\指数のバイアス
  demin=1-iw-bias-fw;  \\非正規化数の指数の下限
  demax=-iw-bias;  \\非正規化数の指数の上限
  nomin=1-iw-bias;  \\正規化数の指数の下限
  nomax=bias;  \\正規化数の指数の上限
  if(type(x)=="t_POL",
     return(if(x==Rei,if(rm==RP,1,0),
               x==-Rei,(1<<(ew+iw+fw))+if(rm==RM,1,0),
               x==Inf,(((1<<ew)-1)<<(iw+fw))-if((rm==RZ)||(rm==RM),1,0),
               x==-Inf,(1<<(ew+iw+fw))+(((1<<ew)-1)<<(iw+fw))-if((rm==RZ)||(rm==RP),1,0),
               x==NaN,(1<<(ew+iw+fw))-1,
               error("numtoxxx(",x,",",rm,",",ew,",",iw,",",rw,")"))));
  a=abs(x);  \\絶対値
  z=if(x<0,1<<(ew+iw+fw),0);  \\符号
  if(x==0,return(z));  \\±0
  if(a<=LOG_ZERO,  \\0ではないが0に近すぎる。0に近すぎるとlog2(a)の計算に失敗する
     fpsr=bitor(fpsr,UF+X2);  \\アンダーフロー、不正確な結果
     return(z));  \\±0
  e=floor(log2(a));  \\指数
  \\if(a<2^e,e--);  \\補正する
  if(e<demin-1,  \\指数部が小さすぎる。丸めで繰り上がる場合があるので一旦非正規化数の指数の下限-1まで受け入れる
     fpsr=bitor(fpsr,UF+X2);  \\アンダーフロー、不正確な結果
     \\符号を跨がず±0から遠ざかる方向に丸めるときは±0ではなく絶対値が最小の非正規化数を返す
     return(z+if(((x<0)&&(rm==RM))||((0<x)&&(rm==RP)),1,0)));
  o=if(demax<e,1+fw,e-demax+fw);  \\1+小数部のbit数。正規化数のときo==1+fw、非正規化数のときo<1+fw
  t=a*2^(o-1-e);
  m=floor(t);  \\仮数部の先頭(o)bit
  t-=m;  \\仮数部の端数
  if(if(o==0,m!=0,(m<2^(o-1))||(2^o<=m)),error("numtoxxx(",x,",",rm,",",ew,",",iw,",",fw,")"));
  if(nomax<e,  \\指数部が大きすぎる
     fpsr=bitor(fpsr,OF);  \\オーバーフロー
     if(t!=0,fpsr=bitor(fpsr,X2));  \\不正確な結果
     \\±0に近付く方向に丸めるときは±Infではなく絶対値が最大の正規化数を返す
     return(z+(((1<<ew)-1)<<(iw+fw))-if(((x<0)&&((rm==RZ)||(rm==RP)))||((0<x)&&((rm==RZ)||(rm==RM))),1,0)));
  if(o<1+fw,  \\非正規化数
     fpsr=bitor(fpsr,UF));  \\アンダーフロー
  if(t!=0,  \\端数が0ではない
     fpsr=bitor(fpsr,X2);  \\不正確な結果
     if(((rm==RN)&&(((1/2)<t)||
                    ((t==(1/2))&&(bitand(m,1)==1))))||  \\RNで端数が1/2より大きいか端数が1/2と等しくて1の位が1
        ((rm==RM)&&(x<0))||  \\端数が0ではなくてRMで-または
        ((rm==RP)&&(0<x)),  \\端数が0ではなくてRPで+のとき
        m++;  \\繰り上げる
        if(m==(1<<o),  \\1桁増えた
           if(o==1+fw,  \\正規化数が溢れた
              m>>=1;
              e++;  \\指数部をインクリメントする
              if(nomax<e,  \\指数部が溢れた
                 fpsr=bitor(fpsr,OF);  \\オーバーフロー
                 \\±0に近付く方向に丸めるときは±Infではなく絶対値が最大の正規化数を返す
                 return(z+(((1<<ew)-1)<<(iw+fw))-if(((x<0)&&((rm==RZ)||(rm==RP)))||((0<x)&&((rm==RZ)||(rm==RM))),1,0))),
              m==(1<<fw),  \\非正規化数が正規化数になった
              e=nomin))));
  if(e<nomin,  \\非正規化数
     fpsr=bitor(fpsr,UF));  \\アンダーフロー
  if(m==0,  \\非正規化数が指数の下限-1から繰り上がらなかった
     \\符号を跨がず±0から遠ざかる方向に丸めるときは±0ではなく絶対値が最小の非正規化数を返す
     return(z+if(((x<0)&&(rm==RM))||((0<x)&&(rm==RP)),1,0)));
  z+(if(0<=bias+e,bias+e,0)<<(iw+fw))+bitand(m,(1<<(iw+fw))-1)
  }

\\u=numtosgl(x,rm)
\\  数値または特別な数値をsingleの内部表現の32bit符号なし整数に変換する
\\     u  32bit符号なし整数
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
numtosgl(x,rm)=numtoxxx(x,rm,8,0,23);

\\u=numtodbl(x,rm)
\\  数値または特別な数値をdoubleの内部表現の64bit符号なし整数に変換する
\\     u  64bit符号なし整数
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
numtodbl(x,rm)=numtoxxx(x,rm,11,0,52);

\\u=numtoexd(x,rm)
\\  数値または特別な数値をextendedの内部表現の96bit符号なし整数に変換する
\\     u  96bit符号なし整数
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
numtoexd(x,rm)={
  my(u);
  u=numtoxxx(x,rm,15,1,63);
  \\  |符号部と指数部(16bit)|仮数部(64bit)|
  \\                   ↓
  \\  |符号部と指数部(16bit)|空き(16bit)|仮数部(64bit)|
  ((bitand(u,(1<<80)-(1<<64))<<16)+  \\符号部と指数部(16bit)
   bitand(u,(1<<64)-(1<<0)))  \\仮数部(64bit)
  }
numtoexd2(x,rm)={
  my(u);
  u=numtoxxx2(x,rm,15,1,63);
  \\  |符号部と指数部(16bit)|仮数部(64bit)|
  \\                   ↓
  \\  |符号部と指数部(16bit)|空き(16bit)|仮数部(64bit)|
  ((bitand(u,(1<<80)-(1<<64))<<16)+  \\符号部と指数部(16bit)
   bitand(u,(1<<64)-(1<<0)))  \\仮数部(64bit)
  }

\\u=numtotpl(x,rm)
\\  数値または特別な数値をtripleの内部表現の96bit符号なし整数に変換する
\\     u  96bit符号なし整数
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
numtotpl(x,rm)={
  my(u);
  u=numtoxxx(x,rm,15,1,79);
  \\  |符号部と指数部(16bit)|仮数部の上位(64bit)|仮数部の下位(16bit)|
  \\                                ↓
  \\  |符号部と指数部(16bit)|仮数部の下位(16bit)|仮数部の上位(64bit)|
  (bitand(u,(1<<96)-(1<<80))+  \\符号部と指数部(16bit)
   (bitand(u,(1<<16)-(1<<0))<<64)+  \\仮数部の下位(16bit)
   (bitand(u,(1<<80)-(1<<16))>>16))  \\仮数部の上位(64bit)
  }

\\u=numtoqpl(x,rm)
\\  数値または特別な数値をquadrupleの内部表現の128bit符号なし整数に変換する
\\     u  128bit符号なし整数
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
numtoqpl(x,rm)=numtoxxx(x,rm,15,0,112);

\\u=numtospl(x,rm)
\\  数値または特別な数値をsextupleの内部表現の192bit符号なし整数に変換する
\\     u  192bit符号なし整数
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
numtospl(x,rm)=numtoxxx(x,rm,15,0,176);

\\u=numtoopl(x,rm)
\\  数値または特別な数値をoctupleの内部表現の256bit符号なし整数に変換する
\\     u  256bit符号なし整数
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
numtoopl(x,rm)=numtoxxx(x,rm,15,0,240);

\\u=numtoxsg(x,rm)
\\  数値または特別な数値をxsingleの内部表現の40bit符号なし整数に変換する
\\     u  40bit符号なし整数
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
numtoxsg(x,rm)=numtoxxx(x,rm,15,1,23);

\\u=numtoxdb(x,rm)
\\  数値または特別な数値をxdoubleの内部表現の69bit符号なし整数に変換する
\\     u  69bit符号なし整数
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
numtoxdb(x,rm)=numtoxxx(x,rm,15,1,52);

\\u=numtoefp(x,rm)
\\  数値または特別な数値をefpの内部表現の109bit符号なし整数に変換する
\\     u  109bit符号なし整数
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
numtoefp(x,rm)=numtoxxx(x,rm,16,1,91);


\\s=numtosgh(x,rm)
\\  数値または特別な数値をsingleの内部表現を表す8桁の16進数の文字列に変換する
\\     s  8桁の16進数の文字列
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
numtosgh(x,rm)=hex8(numtosgl(x,rm));

\\s=numtodbh(x,rm)
\\  数値または特別な数値をdoubleの内部表現を表す16桁の16進数の文字列に変換する
\\     s  16桁の16進数の文字列
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
numtodbh(x,rm)=hex16(numtodbl(x,rm));

\\s=numtoexh(x,rm)
\\  数値または特別な数値をextendedの内部表現を表す24桁の16進数の文字列に変換する
\\     s  24桁の16進数の文字列
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
numtoexh(x,rm)=hex24(numtoexd(x,rm));

\\s=numtotph(x,rm)
\\  数値または特別な数値をtripleの内部表現を表す24桁の16進数の文字列に変換する
\\     s  24桁の16進数の文字列
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
numtotph(x,rm)=hex24(numtotpl(x,rm));

\\s=numtoqph(x,rm)
\\  数値または特別な数値をquadrupleの内部表現を表す32桁の16進数の文字列に変換する
\\     s  32桁の16進数の文字列
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
numtoqph(x,rm)=hex32(numtoqpl(x,rm));

\\s=numtosph(x,rm)
\\  数値または特別な数値をsextupleの内部表現を表す48桁の16進数の文字列に変換する
\\     s  48桁の16進数の文字列
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
numtosph(x,rm)=hex48(numtospl(x,rm));

\\s=numtooph(x,rm)
\\  数値または特別な数値をoctupleの内部表現を表す64桁の16進数の文字列に変換する
\\     s  64桁の16進数の文字列
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
numtooph(x,rm)=hex64(numtoopl(x,rm));

\\s=numtoxsh(x,rm)
\\  数値または特別な数値をxsingleの内部表現を表す10桁の16進数の文字列に変換する
\\     s  10桁の16進数の文字列
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
numtoxsh(x,rm)=hex10(numtoxsg(x,rm));

\\s=numtoxdh(x,rm)
\\  数値または特別な数値をxdoubleの内部表現を表す18桁の16進数の文字列に変換する
\\     s  18桁の16進数の文字列
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
numtoxdh(x,rm)=hex18(numtoxdb(x,rm));

\\s=numtoefh(x,rm)
\\  数値または特別な数値をefpの内部表現を表す28桁の16進数の文字列に変換する
\\     s  28桁の16進数の文字列
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
numtoefh(x,rm)=hex28(numtoefp(x,rm));


\\y=sgl(x,rm)
\\  数値または特別な数値をsingleで表現できる数値または特別な数値に丸めモードrmで丸める
\\     y  singleで表現できる数値または特別な数値
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
sgl(x,rm)=sgltonum(numtosgl(x,rm));

\\y=dbl(x,rm)
\\  数値または特別な数値をdoubleで表現できる数値または特別な数値に丸めモードrmで丸める
\\     y  doubleで表現できる数値または特別な数値
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
dbl(x,rm)=dbltonum(numtodbl(x,rm));

\\y=exd(x,rm)
\\  数値または特別な数値をextendedで表現できる数値または特別な数値に丸めモードrmで丸める
\\     y  extendedで表現できる数値または特別な数値
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
exd(x,rm)=exdtonum(numtoexd(x,rm));
exd2(x,rm)=exdtonum(numtoexd2(x,rm));

\\y=tpl(x,rm)
\\  数値または特別な数値をtripleで表現できる数値または特別な数値に丸めモードrmで丸める
\\     y  tripleで表現できる数値または特別な数値
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
tpl(x,rm)=tpltonum(numtotpl(x,rm));

\\y=qpl(x,rm)
\\  数値または特別な数値をquadrupleで表現できる数値または特別な数値に丸めモードrmで丸める
\\     y  quadrupleで表現できる数値または特別な数値
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
qpl(x,rm)=qpltonum(numtoqpl(x,rm));

\\y=spl(x,rm)
\\  数値または特別な数値をsextupleで表現できる数値または特別な数値に丸めモードrmで丸める
\\     y  sextupleで表現できる数値または特別な数値
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
spl(x,rm)=spltonum(numtospl(x,rm));

\\y=opl(x,rm)
\\  数値または特別な数値をoctupleで表現できる数値または特別な数値に丸めモードrmで丸める
\\     y  octupleで表現できる数値または特別な数値
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
opl(x,rm)=opltonum(numtoopl(x,rm));

\\y=xsg(x,rm)
\\  数値または特別な数値をxsingleで表現できる数値または特別な数値に丸めモードrmで丸める
\\     y  xsingleで表現できる数値または特別な数値
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
xsg(x,rm)=xsgtonum(numtoxsg(x,rm));

\\y=xdb(x,rm)
\\  数値または特別な数値をxdoubleで表現できる数値または特別な数値に丸めモードrmで丸める
\\     y  xdoubleで表現できる数値または特別な数値
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
xdb(x,rm)=xdbtonum(numtoxdb(x,rm));

\\y=efp(x,rm)
\\  数値または特別な数値をefpで表現できる数値または特別な数値に丸めモードrmで丸める
\\     y  efpで表現できる数値または特別な数値
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
efp(x,rm)=efptonum(numtoefp(x,rm));


\\y=xxx(x,rp,rm)
\\  数値または特別な数値を丸め桁数rpで表現できる数値または特別な数値に丸めモードrmで丸める
\\     y  数値を丸め桁数rpで表現できる数値または特別な数値
\\     x  数値または特別な数値
\\    rp  丸め桁数
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
xxx(x,rp,rm)={
  if(rp==SGL,sgl(x,rm),
     (rp==DBL)||(rp==DBL3),dbl(x,rm),
     rp==EXD,exd(x,rm),
     rp==TPL,tpl(x,rm),
     rp==QPL,qpl(x,rm),
     rp==SPL,spl(x,rm),
     rp==OPL,opl(x,rm),
     rp==XSG,xsg(x,rm),
     rp==XDB,xdb(x,rm),
     rp==EFP,efp(x,rm),
     error("xxx(",x,",",rp,",",rm,")"))
  }
xxx2(x,rp,rm)={
  if(rp==SGL,sgl(x,rm),
     (rp==DBL)||(rp==DBL3),dbl(x,rm),
     rp==EXD,exd2(x,rm),
     rp==TPL,tpl(x,rm),
     rp==QPL,qpl(x,rm),
     rp==SPL,spl(x,rm),
     rp==OPL,opl(x,rm),
     rp==XSG,xsg(x,rm),
     rp==XDB,xdb(x,rm),
     rp==EFP,efp(x,rm),
     error("xxx(",x,",",rp,",",rm,")"))
  }


\\s=numtosgi(x,rm)
\\  数値または特別な数値をsingleの内部表現を表す1個の8桁の16進数の文字列に変換する
\\     s  singleの内部表現を表す1個の8桁の16進数の文字列
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
numtosgi(x,rm)=hex8imm(numtosgl(x,rm));

\\s=numtodbi(x,rm)
\\  数値または特別な数値をdoubleの内部表現を表す2個の8桁の16進数の文字列に変換する
\\     s  doubleの内部表現を表す2個の8桁の16進数の文字列
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
numtodbi(x,rm)=hex16imm(numtodbl(x,rm));

\\s=numtoexi(x,rm)
\\  数値または特別な数値をextendedのメモリ内部表現を表す3個の8桁の16進数の文字列に変換する
\\     s  extendedの内部表現を表す3個の8桁の16進数の文字列
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
numtoexi(x,rm)=hex24imm(numtoexd(x,rm));

\\s=numtotpi(x,rm)
\\  数値または特別な数値をtripleのメモリ内部表現を表す3個の8桁の16進数の文字列に変換する
\\     s  tripleの内部表現を表す3個の8桁の16進数の文字列
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
numtotpi(x,rm)=hex24imm(numtotpl(x,rm));

\\s=numtoqpi(x,rm)
\\  数値または特別な数値をquadrupleの内部表現を表す4個の8桁の16進数の文字列に変換する
\\     s  quadrupleの内部表現を表す4個の8桁の16進数の文字列
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
numtoqpi(x,rm)=hex32imm(numtoqpl(x,rm));

\\s=numtospi(x,rm)
\\  数値または特別な数値をsextupleの内部表現を表す6個の8桁の16進数の文字列に変換する
\\     s  sextupleの内部表現を表す6個の8桁の16進数の文字列
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
numtospi(x,rm)=hex48imm(numtospl(x,rm));

\\s=numtoopi(x,rm)
\\  数値または特別な数値をoctupleの内部表現を表す8個の8桁の16進数の文字列に変換する
\\     s  octupleの内部表現を表す8個の8桁の16進数の文字列
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
numtoopi(x,rm)=hex64imm(numtoopl(x,rm));

\\s=numtoxsi(x,rm)
\\  数値または特別な数値をxsingleの内部表現を表す2個の8桁の16進数の文字列に変換する
\\     s  xsingleの内部表現を表す2個の8桁の16進数の文字列
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
numtoxsi(x,rm)=hex16imm(numtoxsg(x,rm));

\\s=numtoxdi(x,rm)
\\  数値または特別な数値をxdoubleの内部表現を表す3個の8桁の16進数の文字列に変換する
\\     s  xdoubleの内部表現を表す3個の8桁の16進数の文字列
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
numtoxdi(x,rm)=hex24imm(numtoxdb(x,rm));

\\s=numtoefi(x,rm)
\\  数値または特別な数値をefpの内部表現を表す4個の8桁の16進数の文字列に変換する
\\     s  efpの内部表現を表す4個の8桁の16進数の文字列
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OF  オーバーフロー
\\    UF  アンダーフロー
\\    X2  不正確な結果
numtoefi(x,rm)=hex32imm(numtoefp(x,rm));


\\y=xxxnextdown(x,ew,iw,fw)
\\  数値または特別な数値よりも小さい最大の表現できる数値または特別な数値を返す
\\     y  xよりも小さい最大の表現できる数値または特別な数値
\\     x  数値または特別な数値
\\    ew  浮動小数点数の内部表現の指数部のbit数
\\    iw  浮動小数点数の内部表現の整数部のbit数
\\    fw  浮動小数点数の内部表現の小数部のbit数
xxxnextdown(x,ew,iw,fw)={
  my(bias,demin,demax,nomin,nomax,y);
  bias=(1<<(ew-1))-1;  \\指数のバイアス
  demin=1-iw-bias-fw;  \\非正規化数の指数の下限
  demax=-iw-bias;  \\非正規化数の指数の上限
  nomin=1-iw-bias;  \\正規化数の指数の下限
  nomax=bias;  \\正規化数の指数の上限
  if(type(x)=="t_POL",
     return(if((x==Rei)||(x==-Rei),-2^demin,  \\±0の下は負の非正規化数の最大値
               x==Inf,2^(nomax+1)-2^(nomax+1-(1+fw)),  \\Infの下は正の正規化数の最大値
               x==-Inf,-Inf,  \\負の無限大で飽和する
               x==NaN,NaN,
               error("xxxnextdown(",x,",",ew,",",iw,",",fw,")"))));
  if(x==0,return(-2^demin));  \\±0の下は負の非正規化数の最大値
  if(x==-2^nomin+2^(nomin-fw),  \\負の非正規化数の最小値
     \\if(ew<15,  \\singleまたはdoubleのとき
     \\   fpsr=bitor(fpsr,UF));  \\アンダーフロー
     return(-2^nomin));  \\負の正規化数の最大値
  y=xxxtonum(numtoxxx(x,RM,ew,iw,fw),ew,iw,fw);  \\xと等しいか小さい最大の表現できる数値または特別な数値
  if(y==x,  \\xが表現できる数値だった
     y=xxxtonum(numtoxxx(y-abs(y)*2^-(2+fw),RM,ew,iw,fw),ew,iw,fw));
  y
  }

\\y=sglnextdown(x)
\\y=sglnextnextdown(x)
\\  数値または特別な数値よりも小さい最大のsingleで表現できる数値または特別な数値を返す
\\     y  xよりも小さい最大のsingleで表現できる数値または特別な数値
\\     x  数値または特別な数値
sglnextdown(x)=xxxnextdown(x,8,0,23);
sglnextnextdown(x)=sglnextdown(sglnextdown(x));

\\y=dblnextnextdown(x)
\\  数値または特別な数値よりも小さい最大のdoubleで表現できる数値または特別な数値を返す
\\     y  xよりも小さい最大のdoubleで表現できる数値または特別な数値
\\     x  数値または特別な数値
dblnextdown(x)=xxxnextdown(x,11,0,52);
dblnextnextdown(x)=dblnextdown(dblnextdown(x));

\\y=exdnextdown(x)
\\y=exdnextnextdown(x)
\\  数値または特別な数値よりも小さい最大のextendedで表現できる数値または特別な数値を返す
\\     y  xよりも小さい最大のextendedで表現できる数値または特別な数値
\\     x  数値または特別な数値
exdnextdown(x)=xxxnextdown(x,15,1,63);
exdnextnextdown(x)=exdnextdown(exdnextdown(x));

\\y=tplnextdown(x)
\\y=tplnextnextdown(x)
\\  数値または特別な数値よりも小さい最大のtripleで表現できる数値または特別な数値を返す
\\     y  xよりも小さい最大のtripleで表現できる数値または特別な数値
\\     x  数値または特別な数値
tplnextdown(x)=xxxnextdown(x,15,1,79);
tplnextnextdown(x)=tplnextdown(tplnextdown(x));

\\y=qplnextdown(x)
\\y=qplnextnextdown(x)
\\  数値または特別な数値よりも小さい最大のquadrupleで表現できる数値または特別な数値を返す
\\     y  xよりも小さい最大のquadrupleで表現できる数値または特別な数値
\\     x  数値または特別な数値
qplnextdown(x)=xxxnextdown(x,15,0,112);
qplnextnextdown(x)=qplnextdown(qplnextdown(x));

\\y=splnextdown(x)
\\y=splnextnextdown(x)
\\  数値または特別な数値よりも小さい最大のsextupleで表現できる数値または特別な数値を返す
\\     y  xよりも小さい最大のsextupleで表現できる数値または特別な数値
\\     x  数値または特別な数値
splnextdown(x)=xxxnextdown(x,15,0,176);
splnextnextdown(x)=splnextdown(splnextdown(x));

\\y=otpnextdown(x)
\\y=otpnextnextdown(x)
\\  数値または特別な数値よりも小さい最大のoctupleで表現できる数値または特別な数値を返す
\\     y  xよりも小さい最大のoctupleで表現できる数値または特別な数値
\\     x  数値または特別な数値
oplnextdown(x)=xxxnextdown(x,15,0,240);
oplnextnextdown(x)=oplnextdown(oplnextdown(x));

\\y=xsgnextdown(x)
\\y=xsgnextnextdown(x)
\\  数値または特別な数値よりも小さい最大のxsingleで表現できる数値または特別な数値を返す
\\     y  xよりも小さい最大のxsingleで表現できる数値または特別な数値
\\     x  数値または特別な数値
xsgnextdown(x)=xxxnextdown(x,15,1,23);
xsgnextnextdown(x)=xsgnextdown(xsgnextdown(x));

\\y=xdbnextdown(x)
\\y=xdbnextnextdown(x)
\\  数値または特別な数値よりも小さい最大のxdoubleで表現できる数値または特別な数値を返す
\\     y  xよりも小さい最大のxdoubleで表現できる数値または特別な数値
\\     x  数値または特別な数値
xdbnextdown(x)=xxxnextdown(x,15,1,52);
xdbnextnextdown(x)=efpnextdown(xdbnextdown(x));

\\y=efpnextdown(x)
\\y=efpnextnextdown(x)
\\  数値または特別な数値よりも小さい最大のefpで表現できる数値または特別な数値を返す
\\     y  xよりも小さい最大のefpで表現できる数値または特別な数値
\\     x  数値または特別な数値
efpnextdown(x)=xxxnextdown(x,16,1,91);
efpnextnextdown(x)=efpnextdown(efpnextdown(x));


\\y=nextdown(x,rp)
\\  数値または特別な数値よりも小さい最大の丸め桁数rpで表現できる数値または特別な数値を返す
\\     y  xよりも小さい最大の丸め桁数rpで表現できる数値または特別な数値
\\     x  数値または特別な数値
\\    rp  丸め桁数
nextdown(x,rp)={
  if(rp==SGL,sglnextdown(x),
     (rp==DBL)||(rp==DBL3),dblnextdown(x),
     rp==EXD,exdnextdown(x),
     rp==TPL,tplnextdown(x),
     rp==QPL,qplnextdown(x),
     rp==SPL,splnextdown(x),
     rp==OPL,oplnextdown(x),
     rp==XSG,xsgnextdown(x),
     rp==XDB,xdbnextdown(x),
     rp==EFP,efpnextdown(x),
     error("nextdown(",x,",",rp")"))
  }


\\y=xxxnextup(x,ew,iw,fw)
\\  数値または特別な数値よりも大きい最小の表現できる数値または特別な数値を返す
\\     y  xよりも大きい最小の表現できる数値または特別な数値
\\     x  数値または特別な数値
\\    ew  浮動小数点数の内部表現の指数部のbit数
\\    iw  浮動小数点数の内部表現の整数部のbit数
\\    fw  浮動小数点数の内部表現の小数部のbit数
xxxnextup(x,ew,iw,fw)={
  my(bias,demin,demax,nomin,nomax,y);
  bias=(1<<(ew-1))-1;  \\指数のバイアス
  demin=1-iw-bias-fw;  \\非正規化数の指数の下限
  demax=-iw-bias;  \\非正規化数の指数の上限
  nomin=1-iw-bias;  \\正規化数の指数の下限
  nomax=bias;  \\正規化数の指数の上限
  if(type(x)=="t_POL",
     return(if((x==Rei)||(x==-Rei),2^demin,  \\±0の上は正の非正規化数の最小値
               x==Inf,Inf,  \\正の無限大で飽和する
               x==-Inf,-2^(nomax+1)+2^(nomax+1-(1+fw)),  \\-Infの上は負の正規化数の最小値
               x==NaN,NaN,
               error("xxxnextup(",x,",",ew,",",iw,",",fw,")"))));
  if(x==0,return(2^demin));  \\±0の上は正の非正規化数の最小値
  if(x==2^nomin-2^(nomin-fw),  \\正の非正規化数の最大値
     \\if(ew<15,  \\singleまたはdoubleのとき
     \\   fpsr=bitor(fpsr,UF));  \\アンダーフロー
     return(2^nomin));  \\正の正規化数の最小値
  y=xxxtonum(numtoxxx(x,RP,ew,iw,fw),ew,iw,fw);  \\xと等しいか大きい最小の表現できる数値または特別な数値
  if(y==x,  \\xが表現できる数値だった
     y=xxxtonum(numtoxxx(y+abs(y)*2^-(2+fw),RP,ew,iw,fw),ew,iw,fw));
  y
  }

\\y=sglnextup(x)
\\y=sglnextnextup(x)
\\  数値または特別な数値よりも大きい最小のsingleで表現できる数値または特別な数値を返す
\\     y  xよりも大きい最小のsingleで表現できる数値または特別な数値
\\     x  数値または特別な数値
sglnextup(x)=xxxnextup(x,8,0,23);
sglnextnextup(x)=sglnextup(sglnextup(x));

\\y=dblnextup(x)
\\y=dblnextnextup(x)
\\  数値または特別な数値よりも大きい最小のdoubleで表現できる数値または特別な数値を返す
\\     y  xよりも大きい最小のdoubleで表現できる数値または特別な数値
\\     x  数値または特別な数値
dblnextup(x)=xxxnextup(x,11,0,52);
dblnextnextup(x)=dblnextup(dblnextup(x));

\\y=exdnextup(x)
\\y=exdnextnextup(x)
\\  数値または特別な数値よりも大きい最小のextendedで表現できる数値または特別な数値を返す
\\     y  xよりも大きい最小のextendedで表現できる数値または特別な数値
\\     x  数値または特別な数値
exdnextup(x)=xxxnextup(x,15,1,63);
exdnextnextup(x)=exdnextup(exdnextup(x));

\\y=tplnextup(x)
\\y=tplnextnextup(x)
\\  数値または特別な数値よりも大きい最小のtripleで表現できる数値または特別な数値を返す
\\     y  xよりも大きい最小のtripleで表現できる数値または特別な数値
\\     x  数値または特別な数値
tplnextup(x)=xxxnextup(x,15,1,79);
tplnextnextup(x)=tplnextup(tplnextup(x));

\\y=qplnextup(x)
\\y=qplnextnextup(x)
\\  数値または特別な数値よりも大きい最小のquadrupleで表現できる数値または特別な数値を返す
\\     y  xよりも大きい最小のquadrupleで表現できる数値または特別な数値
\\     x  数値または特別な数値
qplnextup(x)=xxxnextup(x,15,0,112);
qplnextnextup(x)=qplnextup(qplnextup(x));

\\y=splnextup(x)
\\y=splnextnextup(x)
\\  数値または特別な数値よりも大きい最小のsextupleで表現できる数値または特別な数値を返す
\\     y  xよりも大きい最小のsextupleで表現できる数値または特別な数値
\\     x  数値または特別な数値
splnextup(x)=xxxnextup(x,15,0,176);
splnextnextup(x)=splnextup(splnextup(x));

\\y=otpnextup(x)
\\y=otpnextnextup(x)
\\  数値または特別な数値よりも大きい最小のoctupleで表現できる数値または特別な数値を返す
\\     y  xよりも大きい最小のoctupleで表現できる数値または特別な数値
\\     x  数値または特別な数値
oplnextup(x)=xxxnextup(x,15,0,240);
oplnextnextup(x)=oplnextup(oplnextup(x));

\\y=xsgnextup(x)
\\y=xsgnextnextup(x)
\\  数値または特別な数値よりも大きい最小のxsingleで表現できる数値または特別な数値を返す
\\     y  xよりも大きい最小のxsingleで表現できる数値または特別な数値
\\     x  数値または特別な数値
xsgnextup(x)=xxxnextup(x,15,1,23);
xsgnextnextup(x)=xsgnextup(xsgnextup(x));

\\y=xdbnextup(x)
\\y=xdbnextnextup(x)
\\  数値または特別な数値よりも大きい最小のxdoubleで表現できる数値または特別な数値を返す
\\     y  xよりも大きい最小のxdoubleで表現できる数値または特別な数値
\\     x  数値または特別な数値
xdbnextup(x)=xxxnextup(x,15,1,52);
xdbnextnextup(x)=xdbnextup(xdbnextup(x));

\\y=efpnextup(x)
\\y=efpnextnextup(x)
\\  数値または特別な数値よりも大きい最小のefpで表現できる数値または特別な数値を返す
\\     y  xよりも大きい最小のefpで表現できる数値または特別な数値
\\     x  数値または特別な数値
efpnextup(x)=xxxnextup(x,16,1,91);
efpnextnextup(x)=efpnextup(efpnextup(x));


\\y=nextup(x,rp)
\\  数値または特別な数値よりも大きい最小の丸め桁数rpで表現できる数値または特別な数値を返す
\\     y  xよりも大きい最小の丸め桁数rpで表現できる数値または特別な数値
\\     x  数値または特別な数値
\\    rp  丸め桁数
nextup(x,rp)={
  if(rp==SGL,sglnextup(x),
     (rp==DBL)||(rp==DBL3),dblnextup(x),
     rp==EXD,exdnextup(x),
     rp==TPL,tplnextup(x),
     rp==QPL,qplnextup(x),
     rp==SPL,splnextup(x),
     rp==OPL,oplnextup(x),
     rp==XSG,xsgnextup(x),
     rp==XDB,xdbnextup(x),
     rp==EFP,efpnextup(x),
     error("nextup(",x,",",rp")"))
  }


\\u=numtoyyyy(x,rm,iw)
\\  数値または特別な数値を丸めモードrmでiw-bit符号あり整数に丸めて内部表現のiw-bit符号なし整数に変換する
\\     u  iw-bit符号あり整数の内部表現のiw-bit符号なし整数
\\     x  数値または特別な数値
\\    rm  丸めモード
\\    iw  符号あり整数のbit数
\\  fpsr
\\    OE  iw-bit符号あり整数の範囲外、±Inf,NaN
\\    X2  不正確な結果
\\    AV  NaN
numtoyyyy(x,rm,iw)={
  my(y);
  if(type(x)=="t_POL",
     if((x==Rei)||(x==-Rei),return(0),
        fpsr=bitor(fpsr,OE);
        if(x==Inf,return((1<<(iw-1))-1),
           x==-Inf,return(1<<(iw-1)),
           fpsr=bitor(fpsr,AV);
           return((1<<iw)-1))));
  y=if(rm==RN,rint(x),
       rm==RZ,trunc(x),
       rm==RM,floor(x),
       rm==RP,ceil(x),
       error("numtoyyyy(",x,",",rm,",",iw,")"));
  if(y!=x,fpsr=bitor(fpsr,X2));  \\不正確な結果
  if((0<=y)&&(y<1<<(iw-1)),return(y));
  if((-(1<<(iw-1))<=y)&&(y<0),return((1<<iw)+y));
  fpsr=bitor(fpsr,OE);
  if(0<y,
     (1<<(iw-1))-1,
     1<<(iw-1))
  }

\\u=numtobyte(x,rm)
\\  数値または特別な数値を丸めモードrmでbyteに丸めて内部表現の8bit符号なし整数に変換する
\\     u  byteの内部表現の8bit符号なし整数
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OE  byteの範囲外
\\    X2  不正確な結果
numtobyte(x,rm)=numtoyyyy(x,rm,8);

\\u=numtoword(x,rm)
\\  数値または特別な数値を丸めモードrmでwordに丸めて内部表現の16bit符号なし整数に変換する
\\     u  wordの内部表現の16bit符号なし整数
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OE  wordの範囲外
\\    X2  不正確な結果
numtoword(x,rm)=numtoyyyy(x,rm,16);

\\u=numtolong(x,rm)
\\  数値または特別な数値を丸めモードrmでlongに丸めて内部表現の32bit符号なし整数に変換する
\\     u  longの内部表現の32bit符号なし整数
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OE  longの範囲外
\\    X2  不正確な結果
numtolong(x,rm)=numtoyyyy(x,rm,32);

\\u=numtoquad(x,rm)
\\  数値または特別な数値を丸めモードrmでquadに丸めて内部表現の64bit符号なし整数に変換する
\\     u  quadの内部表現の64bit符号なし整数
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OE  quadの範囲外
\\    X2  不正確な結果
numtoquad(x,rm)=numtoyyyy(x,rm,64);


\\x=yyyytonum(u,iw)
\\  iw-bit符号なし整数uをiw-bit符号あり整数の内部表現と見なして数値または特別な数値に変換する
\\     x  数値または特別な数値
\\     u  iw-bit符号あり整数の内部表現のiw-bit符号なし整数
\\    iw  符号あり整数のbit数
yyyytonum(u,iw)={
  u=bitand(u,(1<<iw)-1);
  if(u==0,Rei,
     bittest(u,iw-1),u-(1<<iw),
     u)
  }

\\x=bytetonum(u)
\\  8bit符号なし整数uをbyteの内部表現と見なして数値または特別な数値に変換する
\\     x  数値または特別な数値
\\     u  byteの内部表現の8bit符号なし整数
bytetonum(u)=yyyytonum(u,8);

\\x=wordtonum(u)
\\  16bit符号なし整数uをwordの内部表現と見なして数値または特別な数値に変換する
\\     x  数値または特別な数値
\\     u  wordの内部表現の16bit符号なし整数
wordtonum(u)=yyyytonum(u,16);

\\x=longtonum(u)
\\  32bit符号なし整数uをlongの内部表現と見なして数値または特別な数値に変換する
\\     x  数値または特別な数値
\\     u  longの内部表現の32bit符号なし整数
longtonum(u)=yyyytonum(u,32);

\\x=quadtonum(u)
\\  64bit符号なし整数uをquadの内部表現と見なして数値または特別な数値に変換する
\\     x  数値または特別な数値
\\     u  quadの内部表現の64bit符号なし整数
quadtonum(u)=yyyytonum(u,64);


\\u=numtopkd(x,k,rm)
\\  数値または特別な数値xをk-factor kと丸めモードrmでpackedの内部表現の96bit符号なし整数uに変換する
\\     u  packedの内部表現の96bit符号なし整数
\\     x  数値または特別な数値
\\     k  k-factor。下位7bitが有効。-64..17
\\    rm  丸めモード
\\  fpsr
\\    OE  k-factorまたは指数部が範囲外
\\    X2  誤差がある
numtopkd(x,k,rm)={
  my(a,e,m,v,t,u,w);
  \\k-factorの範囲を確認する
  k=bitand(k,127);  \\k=0..127
  if(64<=k,k-=128);  \\k=-64..63
  if(17<k,
     fpsr=bitor(fpsr,OE);
     k=17);  \\k=-64..17
  \\特別な数値を処理する
  if(type(x)=="t_POL",
     return(if(x==Rei,0,
               x==-Rei,1<<95,
               x==Inf,0x7FFF<<80,
               x==-Inf,0xFFFF<<80,
               (0x7FFF<<80)+0xFFFFFFFFFFFFFFFF)));
  \\仮数部の先頭18桁を取り出す
  a=abs(x);
  if(a<=LOG_ZERO,
     return(if(0<=x,0,1<<95)));
  e=floor(log10(a));  \\小数点を1桁目の右側に置いたときの指数部
  m=floor(a*10^(17-e));  \\仮数部の先頭の18桁
  if(m<10^17,e--;m=floor(a*10^(17-e)),
     10^18<=m,e++;m=floor(a*10^(17-e)));
  t=if(a!=m*10^(e-17),1,0);  \\k+2桁目以降の端数の有無
  v=Vecsmall(Str(m));
  if(#v!=18,error("numtopacked(",x,",",k,")"));
  for(i=1,#v,v[i]=bitand(v[i],15));
  \\固定小数点形式のとき有効桁数を決める
  if(k<=0,
     k=1+e-k;  \\小数点の左側の桁数は1+e、小数点の右側の桁数は-k
     if(k<1,k=1,
        17<k,k=17));  \\k=1..17
  \\丸める
  for(i=k+2,18,t+=v[i]);  \\k+2桁目以降の端数の有無
  if((v[k+1]!=0)||(t!=0),  \\k+1桁目以降に端数がある
     fpsr=bitor(fpsr,X2);  \\誤差がある
     \\  060FPSPはbindecのA12で端数をFINTを使って丸めている
     \\  丸めモードを変更せず丸め桁数だけextendedに変更する処理も書かれているが、
     \\  FINTはsingleまたはdoubleへの丸め処理を行わないのでコメントアウトされている
     if(((rm==RN)&&
         ((5<v[k+1])||  \\k+1桁目以降に端数があってRNでk+1桁目が5より大きいか、
          ((v[k+1]==5)&&((t!=0)||  \\k+1桁目が5でk+2桁目以降に端数があるか、
                         (bitand(v[k],1)!=0)))))||  \\k+1桁目が5でk+2桁目以降に端数がなくてk桁目が奇数または
        ((rm==RM)&&(x<0))||  \\RMで負または
        ((rm==RP)&&(0<=x)),  \\RPで正のとき切り上げる
        forstep(i=k,1,-1,
                if(v[i]<9,
                   v[i]++;
                   break(),
                   v[i]=0));
        if(v[1]==0,
           v[1]=1;
           e++)));
  for(i=k+1,18,v[i]=0);  \\k+1桁目以降を0にする
  \\指数部の範囲を確認する
  if((e<-999)||(999<e),
     fpsr=bitor(fpsr,OE);
     if(e<-9999,return(if(0<=x,0,1<<95)));
     if(9999<e,return(if(0<=x,0x7FFF<<80,0xFFFF<<80))));
  \\packedの内部表現を作る
  u=0;
  if(x<0,u+=1<<95);  \\仮数部の符号
  if(e<0,u+=1<<94);  \\指数部の符号
  w=Vecsmall(Strprintf("%04d",abs(e)%10000));
  for(i=1,#w,w[i]=bitand(w[i],15));
  u+=(w[2]<<88)+(w[3]<<84)+(w[4]<<80)+(w[1]<<76);  \\指数部
  for(i=1,17,u+=v[i]<<(68-4*i));  \\仮数部
  u
  }
numtopkd2(x,k,rm)={
  my(a,e,m,v,t,u,w);
  \\k-factorの範囲を確認する
  k=bitand(k,127);  \\k=0..127
  if(64<=k,k-=128);  \\k=-64..63
  \\特別な数値を処理する
  \\  17<kでもOEはセットされない
  if(type(x)=="t_POL",
     return(if(x==Rei,0,
               x==-Rei,1<<95,
               x==Inf,0x7FFF<<80,
               x==-Inf,0xFFFF<<80,
               (0x7FFF<<80)+0xFFFFFFFFFFFFFFFF)));
  if(17<k,
     fpsr=bitor(fpsr,OE);
     k=17);  \\k=-64..17
  \\仮数部の先頭18桁を取り出す
  a=abs(x);
  if(a<=LOG_ZERO,
     return(if(0<=x,0,1<<95)));
  e=floor(log10(a));  \\小数点を1桁目の右側に置いたときの指数部
  m=floor(a*10^(17-e));  \\仮数部の先頭の18桁
  if(m<10^17,e--;m=floor(a*10^(17-e)),
     10^18<=m,e++;m=floor(a*10^(17-e)));
  t=if(a!=m*10^(e-17),1,0);  \\k+2桁目以降の端数の有無
  v=Vecsmall(Str(m));
  if(#v!=18,error("numtopacked(",x,",",k,")"));
  for(i=1,#v,v[i]=bitand(v[i],15));
  \\固定小数点形式のとき有効桁数を決める
  if(k<=0,
     k=1+e-k;  \\小数点の左側の桁数は1+e、小数点の右側の桁数は-k
     if(k<1,k=1,
        17<k,k=17));  \\k=1..17
  \\丸める
  for(i=k+2,18,t+=v[i]);  \\k+2桁目以降の端数の有無
  if((v[k+1]!=0)||(t!=0),  \\k+1桁目以降に端数がある
     fpsr=bitor(fpsr,X2);  \\誤差がある
     \\  060FPSPはbindecのA12で端数をFINTを使って丸めている
     \\  丸めモードを変更せず丸め桁数だけextendedに変更する処理も書かれているが、
     \\  FINTはsingleまたはdoubleへの丸め処理を行わないのでコメントアウトされている
     if(((rm==RN)&&
         ((5<v[k+1])||  \\k+1桁目以降に端数があってRNでk+1桁目が5より大きいか、
          ((v[k+1]==5)&&((t!=0)||  \\k+1桁目が5でk+2桁目以降に端数があるか、
                         (bitand(v[k],1)!=0)))))||  \\k+1桁目が5でk+2桁目以降に端数がなくてk桁目が奇数または
        ((rm==RM)&&(x<0))||  \\RMで負または
        ((rm==RP)&&(0<=x)),  \\RPで正のとき切り上げる
        forstep(i=k,1,-1,
                if(v[i]<9,
                   v[i]++;
                   break(),
                   v[i]=0));
        if(v[1]==0,
           v[1]=1;
           e++)));
  for(i=k+1,18,v[i]=0);  \\k+1桁目以降を0にする
  \\指数部の範囲を確認する
  if((e<-999)||(999<e),
     fpsr=bitor(fpsr,OE);
     if(e<-9999,return(if(0<=x,0,1<<95)));
     if(9999<e,return(if(0<=x,0x7FFF<<80,0xFFFF<<80))));
  \\packedの内部表現を作る
  u=0;
  if(x<0,u+=1<<95);  \\仮数部の符号
  if(e<0,u+=1<<94);  \\指数部の符号
  w=Vecsmall(Strprintf("%04d",abs(e)%10000));
  for(i=1,#w,w[i]=bitand(w[i],15));
  u+=(w[2]<<88)+(w[3]<<84)+(w[4]<<80)+(w[1]<<76);  \\指数部
  for(i=1,17,u+=v[i]<<(68-4*i));  \\仮数部
  u
  }

\\s=numtopkh(x,k,rm)
\\  数値または特別な数値xをk-factor kと丸めモードrmでpackedの内部表現を表す24桁の16進数の文字列sに変換する
\\     s  packedの内部表現を表す24桁の16進数の文字列
\\     x  数値または特別な数値
\\     k  k-factor。下位7bitが有効。-64..17
\\    rm  丸めモード
\\  fpsr
\\    OE  k-factorまたは指数部が範囲外
\\    X2  誤差がある
numtopkh(x,k,rm)=hex24(numtopkd(x,k,rm));

\\s=numtopki(x,k,rm)
\\  数値または特別な数値xをk-factor kと丸めモードrmでpackedの内部表現を表す3個の8桁の16進数の文字列sに変換する
\\     s  packedの内部表現を表す3個の8桁の16進数の文字列
\\     x  数値または特別な数値
\\     k  k-factor。下位7bitが有効。-64..17
\\    rm  丸めモード
\\  fpsr
\\    OE  k-factorまたは指数部が範囲外
\\    X2  誤差がある
numtopki(x,k,rm)=hex24imm(numtopkd(x,k,rm));


\\x=pkdtonum(u)
\\  96bit符号なし整数uをpackedの内部表現と見なして数値または特別な数値xに変換する
\\  数値は高々1000桁の有理数なので誤差はない
\\     x  数値または特別な数値
\\     u  packedの内部表現の96bit符号なし整数
\\  fpsr
\\    SN  SNaN
pkdtonum(u)={
  my(e,m);
  e=decodebcd(bitand(u>>80,(1<<12)-1));  \\指数部(3桁)
  m=decodebcd(bitand(u,(1<<68)-1));  \\仮数部(17桁)
  if(bittest(u,93)||bittest(u,92)||  \\±Inf,NaN
     e<0||m<0,  \\指数部または仮数部に0..9以外の文字がある
     if(bitand(u,(1<<64)-1)==0,return(if(bittest(u,95),-Inf,Inf)));  \\小数部が0のとき±Inf
     if(bittest(u,62)==0,fpsr=bitor(fpsr,SN));  \\SNaN
     return(NaN));  \\小数部が0でないときNaN
  if(bitand(u,(1<<68)-1)==0,return(if(bittest(u,95),-Rei,Rei)));  \\整数部と小数部が0のとき±Rei
  if(bittest(u,95),-1,1)*10^(if(bittest(u,94),-e,e)-16)*m
  }

\\x=pkdtoxxx(u,rp,rm)
\\  96bit符号なし整数uをpackedの内部表現と見なして丸め桁数rpで表現できる数値または特別な数値xに丸めモードrmで変換する
\\     x  数値または特別な数値
\\     u  packedの内部表現の96bit符号なし整数
\\    rp  丸め桁数
\\    rm  丸めモード
\\  fpsr
\\    SN  SNaN
\\    X1  誤差がある。X2はセットしない
pkdtoxxx(u,rp,rm)={
  my(sr,x);
  sr=fpsr;
  fpsr=0;
  x=pkdtonum(u);
  x=roundexd(x,rm);
  if(bitand(fpsr,SN),sr=bitor(sr,SN));
  if(bitand(fpsr,X2),sr=bitor(sr,X1));
  fpsr=sr;
  if(type(x)!="t_POL",
     x=xxx(x,rp,rm));
  x
  }

\\x=pkdtosgl(u,rm)
\\  96bit符号なし整数uをpackedの内部表現と見なしてsingleで表現できる数値または特別な数値xに丸めモードrmで変換する
\\     x  singleで表現できる数値または特別な数値
\\     u  packedの内部表現の96bit符号なし整数
\\    rm  丸めモード
\\  fpsr
\\    SN  SNaN
\\    X1  誤差がある。X2はセットしない
pkdtosgl(u)=pkdtoxxx(u,SGL,rm);

\\x=pkdtodbl(u,rm)
\\  96bit符号なし整数uをpackedの内部表現と見なしてdoubleで表現できる数値または特別な数値xに丸めモードrmで変換する
\\     x  doubleで表現できる数値または特別な数値
\\     u  packedの内部表現の96bit符号なし整数
\\    rm  丸めモード
\\  fpsr
\\    SN  SNaN
\\    X1  誤差がある。X2はセットしない
pkdtodbl(u)=pkdtoxxx(u,DBL,rm);

\\x=pkdtoexd(u,rm)
\\  96bit符号なし整数uをpackedの内部表現と見なしてextendedで表現できる数値または特別な数値xに丸めモードrmで変換する
\\     x  extendedで表現できる数値または特別な数値
\\     u  packedの内部表現の96bit符号なし整数
\\    rm  丸めモード
\\  fpsr
\\    SN  SNaN
\\    X1  誤差がある。X2はセットしない
pkdtoexd(u)=pkdtoxxx(u,EXD,rm);

\\x=pkdtotpl(u,rm)
\\  96bit符号なし整数uをpackedの内部表現と見なしてtripleで表現できる数値または特別な数値xに丸めモードrmで変換する
\\     x  tripleで表現できる数値または特別な数値
\\     u  packedの内部表現の96bit符号なし整数
\\    rm  丸めモード
\\  fpsr
\\    SN  SNaN
\\    X1  誤差がある。X2はセットしない
pkdtotpl(u)=pkdtoxxx(u,TPL,rm);

\\x=pkdtoqpl(u,rm)
\\  96bit符号なし整数uをpackedの内部表現と見なしてquadrupleで表現できる数値または特別な数値xに丸めモードrmで変換する
\\     x  quadrupleで表現できる数値または特別な数値
\\     u  packedの内部表現の96bit符号なし整数
\\    rm  丸めモード
\\  fpsr
\\    SN  SNaN
\\    X1  誤差がある。X2はセットしない
pkdtoqpl(u)=pkdtoxxx(u,QPL,rm);

\\x=pkdtospl(u,rm)
\\  96bit符号なし整数uをpackedの内部表現と見なしてsextupleで表現できる数値または特別な数値xに丸めモードrmで変換する
\\     x  sextupleで表現できる数値または特別な数値
\\     u  packedの内部表現の96bit符号なし整数
\\    rm  丸めモード
\\  fpsr
\\    SN  SNaN
\\    X1  誤差がある。X2はセットしない
pkdtospl(u)=pkdtoxxx(u,SPL,rm);

\\x=pkdtoopl(u,rm)
\\  96bit符号なし整数uをpackedの内部表現と見なしてoctupleで表現できる数値または特別な数値xに丸めモードrmで変換する
\\     x  octupleで表現できる数値または特別な数値
\\     u  packedの内部表現の96bit符号なし整数
\\    rm  丸めモード
\\  fpsr
\\    SN  SNaN
\\    X1  誤差がある。X2はセットしない
pkdtoopl(u)=pkdtoxxx(u,OPL,rm);

\\x=pkdtoxsg(u,rm)
\\  96bit符号なし整数uをpackedの内部表現と見なしてxsingleで表現できる数値または特別な数値xに丸めモードrmで変換する
\\     x  xsingleで表現できる数値または特別な数値
\\     u  packedの内部表現の96bit符号なし整数
\\    rm  丸めモード
\\  fpsr
\\    SN  SNaN
\\    X1  誤差がある。X2はセットしない
pkdtoxsg(u)=pkdtoxxx(u,XSG,rm);

\\x=pkdtoxdb(u,rm)
\\  96bit符号なし整数uをpackedの内部表現と見なしてxdoubleで表現できる数値または特別な数値xに丸めモードrmで変換する
\\     x  xdoubleで表現できる数値または特別な数値
\\     u  packedの内部表現の96bit符号なし整数
\\    rm  丸めモード
\\  fpsr
\\    SN  SNaN
\\    X1  誤差がある。X2はセットしない
pkdtoxdb(u)=pkdtoxxx(u,XDB,rm);

\\x=pkdtoefp(u,rm)
\\  96bit符号なし整数uをpackedの内部表現と見なしてefpで表現できる数値または特別な数値xに丸めモードrmで変換する
\\     x  efpで表現できる数値または特別な数値
\\     u  packedの内部表現の96bit符号なし整数
\\    rm  丸めモード
\\  fpsr
\\    SN  SNaN
\\    X1  誤差がある。X2はセットしない
pkdtoefp(u)=pkdtoxxx(u,EFP,rm);


\\y=pkd(x,rm)
\\  数値または特別な数値xを丸めモードrmでpackedで表現できる数値または特別な数値yに変換する
\\  yは高々1000桁の有理数なので誤差はない
\\     y  packedで表現できる数値または特別な数値
\\     x  数値または特別な数値
\\    rm  丸めモード
\\  fpsr
\\    OE  指数部が範囲外
\\    X2  誤差がある
pkd(x,rm)={
  my(u);
  u=numtopkd(x,17,rm);
  if(bitand(u,0xF<<76)!=0,  \\指数部の1000の位が0でないときは元に戻せない
     if(bittest(u,95),
        if(bittest(u,94),-Rei,-Inf),
        if(bittest(u,94),Rei,Inf)),
     pkdtonum(u))
  }



\\----------------------------------------------------------------------------------------
\\  グラフ
\\----------------------------------------------------------------------------------------

\\graph(f)
\\  関数fのグラフを表示する
graph(f)={
  my(reso=10000,m,r,c,i,x,y);
  m=matrix(41,81,r,c,
           if(r%20==1,
              if(c%10==1,"+","-"),
              c%40==1,
              if(r%5==1,"+","|"),
              " "
              )
           );
  for(i=-4*reso,4*reso,
      x=i/reso;
      iferr(y=f(x);
            if(imag(y)==0,
               r=21-round(y*5);
               if(1<=r&&r<=41,
                  c=41+round(x*10);
                  m[r,c]="*"
                  )
               ),
            ERR,
            0
            )
      );
  for(r=1,41,
      print1("    //    ");
      for(c=1,81,
          print1(m[r,c])
          );
      print()
      )
}



\\----------------------------------------------------------------------------------------
\\  Javaコード生成
\\----------------------------------------------------------------------------------------

\\s=efpnew(x,rm)
\\  数値または特別な数値xを丸めモードrmでefpで表現できる数値または特別な数値に変換してインスタンスを生成するコードsを返す
\\     s  インスタンスを生成するコード
\\     x  数値または特別な数値
\\    rm  丸めモード
efpnew(x,rm)={
  my(e,m);
  if(x==0,x=Rei);
  if(type(x)=="t_POL",
     if(x==-Inf,"new EFP (M | I, 0, 0L, 0L)",
        x==-Rei,"new EFP (M | Z, 0, 0L, 0L)",
        x==Rei,"new EFP ()",
        x==Inf,"new EFP (P | I, 0, 0L, 0L)",
        x==NaN,"new EFP (N, 0, 0L, 0L)",
        error("efpnew(",x,",",rm,")")),
     x=roundefp(x,rm);
     e=getexp(x);
     m=abs(getman(x))*2^91;
     Strprintf("new EFP (%s, %6d, 0x%016xL, 0x%07xL << 36)",
               if(x<0,"M","P"),e,m>>28,bitand(m,(1<<28)-1)))
  }

\\efpmem([x,rm,c],…)
\\  インスタンスを生成するコードを出力する
\\     x  数値または特別な数値または式を表す文字列
\\    rm  丸めモード
\\     c  式を表す文字列
efpmem(aa[..])={
  my(vv,xx,rm,cc,rr);
  for(ii=1,#aa,
      vv=aa[ii];
      if((type(vv)!="t_VEC")||(#vv<1),error("efpmem(",vv,")"));
      xx=vv[1];
      rm=if(#vv<2,RN,vv[2]);
      cc=if(#vv<3,"",vv[3]);
      if(xx==0,xx=Rei);
      if(type(xx)=="t_STR",
         cc=xx;
         xx=eval(xx));
      if(cc!="",cc=Str(cc,"="));
      rr=roundefp(xx,rm);
      printf("    %s,  //%s%s%s\n",
             efpnew(xx,rm),if(type(rr)=="t_POL","=",rr<xx,"<",rr==xx,"=",">"),cc,formatg(xx,30)))
  }

\\efppub([id,x,rm,c],…)
\\  定数宣言のコードを出力する
\\    id  識別子
\\     x  数値または特別な数値または式を表す文字列
\\    rm  丸めモード
\\     c  式を表す文字列
efppub(aa[..])={
  my(vv,id,xx,rm,cc,rr);
  for(ii=1,#aa,
      vv=aa[ii];
      if((type(vv)!="t_VEC")||(#vv<2),error("efppub(",vv,")"));
      id=vv[1];
      xx=vv[2];
      rm=if(#vv<3,RN,vv[3]);
      cc=if(#vv<4,"",vv[4]);
      if(xx==0,xx=Rei);
      if(type(xx)=="t_STR",
         cc=xx;
         xx=eval(xx));
      if(cc!="",cc=Str(cc,"="));
      rr=roundefp(xx,rm);
      printf("  public final EFP %12s = %s;  //%s%s%s\n",
             id,efpnew(xx,rm),if(type(rr)=="t_POL","=",rr<xx,"<",rr==xx,"=",">"),cc,formatg(xx,30)))
  }

\\efppub2([id,x,rm,c],…)
\\  定数宣言のコードを2倍の精度で出力する
\\    id  識別子
\\     x  数値または特別な数値または式を表す文字列
\\    rm  丸めモード
\\     c  式を表す文字列
efppub2(aa[..])={
  my(vv,id,xx,rm,cc,rr);
  for(ii=1,#aa,
      vv=aa[ii];
      if((type(vv)!="t_VEC")||(#vv<2),error("efppub2(",vv,")"));
      id=vv[1];
      xx=vv[2];
      rm=if(#vv<3,RN,vv[3]);
      cc=if(#vv<4,"",vv[4]);
      if(xx==0,xx=Rei);
      if(type(xx)=="t_STR",
         cc=xx;
         xx=eval(xx));
      if(cc!="",cc=Str(cc,"="));
      rr=roundefp(xx,rm);
      printf("  public final EFP %12s = %s;  //%s%s%s\n",
             id,efpnew(xx,rm),if(type(rr)=="t_POL","=",rr<xx,"<",rr==xx,"=",">"),cc,formatg(xx,30));
      if(type(xx)!="t_POL",xx=xx-rr);
      rr=roundefp(xx,rm);
      printf("  public final EFP %11sA = %s;  //%s%s\n",
             id,efpnew(xx,rm),if(type(rr)=="t_POL","=",rr<xx,"<",rr==xx,"=",">"),formatg(xx,30)))
  }



\\----------------------------------------------------------------------------------------
\\  チェビシェフ展開
\\----------------------------------------------------------------------------------------

\\g=enunit(f,x,a,b)
\\  変数変換
\\  定義域[a,b]の関数f(x)を定義域[-1,1]の関数g(x)に写す
enunit(f,x,a,b)=f((b-a)/2*x+(a+b)/2);

\\q=deunit(p,x,a,b)
\\  変数変換
\\  定義域[-1,1]の多項式p(x)を定義域[a,b]の多項式q(x)に写す
deunit(p,x,a,b)=subst(p,x,2/(b-a)*x-(a+b)/(b-a));

\\p=chebyshev(f,a,b,n)
\\  定義域[a,b]の関数f(x)をn次チェビシェフ展開した多項式p(x)を作る
chebyshev(f,a,b,n)=deunit(sum(k=0,n,if(k==0,1,2)/Pi*intnum(t=0,Pi,cos(k*t)*enunit(f,cos(t),a,b))*polchebyshev(k)),x,a,b);

\\q=efpcoeff(p)
\\  多項式pの係数をefpに丸めた多項式qを返す
\\   q  係数をefpに丸めた多項式
\\   p  多項式
efpcoeff(p)={
  my(c);
  sum(n=0,poldegree(p),
      c=polcoeff(p,n);
      if(abs(c)<1e-300,0,efp(c,RN)*x^n))  \\1e-300未満は切り捨てる
  }

\\c=closeness(f,p,a,b,n)
\\  関数f(x)と多項式p(x)を定義域[a,b]をn等分したn+1箇所すべてで比較して一致しているbit数の最小値を返す
closeness(ff,pp,aa,bb,nn)={
  my(ww,rr,x,ffx,ppx);
  ww=bb-aa;
  rr=1e999;
  for(kk=0,nn,
      x=(aa+ww*kk/nn)*1.0;
      ffx=ff(x);
      ppx=eval(pp);
      if(ffx!=ppx,rr=min(rr,abs(if(abs(ppx)<abs(ffx),ffx,ppx)/(ffx-ppx)))));
  if(rr<1,0,log2(rr))
  }

\\efpclose(f,p,a,b)
\\  関数f(x)と多項式p(x)を定義域[a,b]をn等分したn+1箇所すべてで比較して一致しているbit数の最小値を出力する
efpclose(f,p,a,b)=printf("  //  %.2fbit\n",closeness(f,p,a,b,10000));

\\efppoly(id,f,p,a,b)
\\  定義域[a,b]の関数f(x)の近似多項式p(x)の係数の定数宣言を出力する
efppoly(id,f,p,a,b)={
  for(k=0,poldegree(p),
      c=polcoeff(p,k);
      if(1e-300<=abs(c),
         efppub([Str(id,k),c,RN])));
  efpclose(f,p,a,b)
  }

\\s=efpchebyshev(id,f,a,b,n)
\\  定義域[a,b]の関数f(x)をn次チェビシェフ展開した多項式p(x)の係数の定数宣言を出力する
efpchebyshev(id,f,a,b,n)=efppoly(id,f,efpcoeff(chebyshev(f,a,b,n)),a,b);



\\----------------------------------------------------------------------------------------
\\  数式文字列
\\  数式を表す文字列
\\----------------------------------------------------------------------------------------

\\t=negexpr(s)
\\  数式文字列sの符号を反転する
\\  "NaN"はそのまま
\\  先頭が"+"または"-"でないとき、先頭に"+"を付ける
\\  "("～")"の外側の先頭または"^"以外の文字の後に"+"または"-"があるとき、"+"を"-"に、"-"を"+"にする
\\  先頭が"+"のとき、先頭の"+"を取り除く
negexpr(s)={
  my(v,d,p,c);
  if(s=="NaN",return(s));  \\NaNはそのまま
  v=Vecsmall(s);
  if((v[1]!=43)&&(v[1]!=45),  \\先頭が"+"または"-"でないとき
     v=concat(Vecsmall([43]),v));  \\先頭に"+"を付ける
  d=0;  \\"("～")"の深さ
  p=0;  \\直前の文字
  for(k=1,#v,
      c=v[k];  \\k番目の文字
      if(c==40,d++,  \\"("
         c==41,d--,  \\")"
         (d==0)&&(p!=94)&&((c==43)||(c==45)),  \\"("～")"の外側の先頭または"^"以外の文字の後に"+"または"-"があるとき
         v[k]=43+45-c);  \\"+"を"-"に、"-"を"+"にする
      p=c);
  if(v[1]==43,  \\先頭が"+"のとき
     v=v[2..#v]);  \\先頭の"+"を取り除く
  Strchr(v)
  }

\\w=bothsign(v)
\\  数式文字列を並べたベクタvに符号を反転した数式文字列を加える
bothsign(v)=concat(v,vector(#v,n,negexpr(v[n])));



\\----------------------------------------------------------------------------------------
\\  ソースファイルの操作
\\----------------------------------------------------------------------------------------

asm_list=List();

asm_open()={
  system(Str("rm -f ",TEST_S_TMP));
  asm_list=List()
  }

asm(a[..])={
  for(i=1,#a,listput(asm_list,a[i]));
  if(50000<=#asm_list,
     write1(TEST_S_TMP,join("",Vec(asm_list)));
     asm_list=List())
  }

asmln(a[..])={
  for(i=1,#a,listput(asm_list,a[i]));
  listput(asm_list,"\n");
  if(50000<=#asm_list,
     write1(TEST_S_TMP,join("",Vec(asm_list)));
     asm_list=List())
  }

asmf(f,a[..])={
  listput(asm_list,call(Strprintf,[f,a]));
  if(50000<=#asm_list,
     write1(TEST_S_TMP,join("",Vec(asm_list)));
     asm_list=List())
  }

asm_close()={
  write1(TEST_S_TMP,join("",Vec(asm_list)));
  system(Str("mv ",TEST_S," ",TEST_S_BAK));
  system(Str("mv ",TEST_S_TMP," ",TEST_S));
  print(TEST_S," was updated")
  }



\\----------------------------------------------------------------------------------------
\\  間接データ
\\----------------------------------------------------------------------------------------

indirect_list=0;
indirect_buffer=0;
indirect_offset=0;

indirect_start()={
  indirect_list=List([]);
  indirect_offset=List([]);
  indirect_buffer=List([]);
  }

indirect_end()={
  my(v,w);
  print1("compressing indirect data ... ");
  v=Vecsmall(indirect_buffer);
  w=compress(v);
  print(#w,"/",#v);
  \\if(decompress(w)!=v,error());
  asm(
"
;--------------------------------------------------------------------------------
;	indirect data
;--------------------------------------------------------------------------------

	.text
	.even
indirect_start::
	pea.l	indirect_decompressed
	pea.l	indirect_compressed
	jbsr	decompress
	addq.l	#8,sp
	rts

	.align	4
indirect_compressed::
");
  for(i=1,#w,
      if(i%16==1,asm("	.dc.b	"),
         asm(","));
      asm("$",hex2(w[i]));
      if((i==#w)||(i%16==0),asm("\n")));
  asm(
"
	.bss
	.align	4
indirect_decompressed::
	.ds.b	",#indirect_buffer,"
")
  }



\\----------------------------------------------------------------------------------------
\\  圧縮
\\----------------------------------------------------------------------------------------

push_buffer=0;
push_max_length=0;

push_start()={
  push_buffer=List()
  }

push(b,u)={
  u=bitand(u,(1<<(b<<3))-1);
  forstep(i=b-1,0,-1,
          listput(push_buffer,bitand(u>>(i<<3),255)))
  }

push_indirect(b,u)={
  my(u1);
  u=bitand(u,(1<<(b<<3))-1);
  u1=bitor(1<<(b<<3),u);  \\サイズを区別するために上位に1を付け足す
  for(n=1,#indirect_list,
      if(indirect_list[n]==u1,
         push(4,indirect_offset[n]);
         return()));
  listput(indirect_list,u1);
  listput(indirect_offset,#indirect_buffer);
  forstep(i=b-1,0,-1,
          listput(indirect_buffer,bitand(u>>(i<<3),255)));
  push(4,indirect_offset[#indirect_offset])
  }

push_end()={
  my(v,w);
  if(push_max_length<#push_buffer,
     push_max_length=#push_buffer);
  print1("compressing data ... ");
  v=Vecsmall(push_buffer);
  w=compress(v);
  print(#w,"/",#v);
  \\if(decompress(w)!=v,error());
  push_buffer=0;
  for(i=1,#w,
      if(i%16==1,asm("	.dc.b	"),
         asm(","));
      asm("$",hex2(w[i]));
      if((i==#w)||(i%16==0),asm("\n")));
}



\\----------------------------------------------------------------------------------------
\\  テストプログラムを作る
\\----------------------------------------------------------------------------------------

make_test(a[..])={
  my(mnemmap,all,cmd);
  mnemmap=Map();
  for(i=1,#a,mapput(mnemmap,strlwr(a[i]),1));
  all=#a==0||mapisdefined(mnemmap,"all");
  asm_open();
  asm(
";========================================================================================
;  ",TEST_S,"
;  Copyright (C) 2003-2019 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

	.include	doscall.mac
	.include	iocscall.mac

	.cpu	68000


;--------------------------------------------------------------------------------
;	定数
;--------------------------------------------------------------------------------

MI	equ	1<<27
ZE	equ	1<<26
IN	equ	1<<25
NA	equ	1<<24
BS	equ	1<<15
SN	equ	1<<14
OE	equ	1<<13
OF	equ	1<<12
UF	equ	1<<11
DZ	equ	1<<10
X2	equ	1<<9
X1	equ	1<<8
AV	equ	1<<7
AO	equ	1<<6
AU	equ	1<<5
AZ	equ	1<<4
AX	equ	1<<3


;--------------------------------------------------------------------------------
;	マクロ
;--------------------------------------------------------------------------------

leamsg	.macro	p0,an
	.data
@msg:
	.dc.b	p0,0
	.text
	lea.l	@msg,an
	.endm

peamsg	.macro	p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,q0,q1,q2,q3,q4,q5,q6,q7,q8,q9
	.data
@msg:
	.dc.b	p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,q0,q1,q2,q3,q4,q5,q6,q7,q8,q9,0
	.text
	pea.l	@msg
	.endm

putmsg	.macro	p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,q0,q1,q2,q3,q4,q5,q6,q7,q8,q9
	peamsg	p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,q0,q1,q2,q3,q4,q5,q6,q7,q8,q9
	jbsr	printstr
	addq.l	#4,sp
	.endm

putstr	.macro	p0
	move.l	p0,-(sp)
	jbsr	printstr
	addq.l	#4,sp
	.endm

putchr	.macro	p0
	move.b	p0,-(sp)
	jbsr	printchr
	addq.l	#2,sp
	.endm

putlong	.macro	p0
	move.l	p0,-(sp)
	jbsr	printlong
	addq.l	#4,sp
	.endm

putdec	.macro	p0
	move.l	p0,-(sp)
	jbsr	printdec
	addq.l	#4,sp
	.endm

putdecz2	.macro	p0
	pea.l	2.w
	move.l	p0,-(sp)
	jbsr	printdecz
	addq.l	#8,sp
	.endm

putdecz4	.macro	p0
	pea.l	4.w
	move.l	p0,-(sp)
	jbsr	printdecz
	addq.l	#8,sp
	.endm

putfix	.macro	p0,p1
	move.b	p1,-(sp)
	move.l	p0,-(sp)
	jbsr	printfix
	addq.l	#6,sp
	.endm

puthex2	.macro	p0
	move.b	p0,-(sp)
	jbsr	printhex2
	addq.l	#2,sp
	.endm

puthex4	.macro	p0
	move.w	p0,-(sp)
	jbsr	printhex4
	addq.l	#2,sp
	.endm

puthex8	.macro	p0
	move.l	p0,-(sp)
	jbsr	printhex8
	addq.l	#4,sp
	.endm

puthex16	.macro	p0,p1
	puthex8	p0
	putchr	#','
	puthex8	p1
	.endm

puthex24	.macro	p0,p1,p2
	puthex8	p0
	putchr	#','
	puthex8	p1
	putchr	#','
	puthex8	p2
	.endm

putcrlf	.macro
	jbsr	printcrlf
	.endm

putdate	.macro
	jbsr	printdate
	.endm


;--------------------------------------------------------------------------------
;	メイン
;--------------------------------------------------------------------------------
	.text
	.even
main::
;------------------------------------------------
;bssが確保されているか確認する
	lea.l	(16,a0),a0
	suba.l	a0,a1
	movem.l	a0-a1,-(sp)
	DOS	_SETBLOCK
	addq.l	#8,sp
	tst.l	d0
	bmi	exit
;------------------------------------------------
;スタックエリアを設定する
	lea.l	stack_area_end,sp	;スタックエリアの末尾
;------------------------------------------------
;FPUの種類を確認する
	jbsr	fpu_check
	beq	exit
;------------------------------------------------
;コマンドラインをコピーする
	pea.l	1(a2)
	jbsr	option_start
	addq.l	#4,sp
	beq	exit
;------------------------------------------------
;アボートの準備をする
	move.l	sp,abort_sp
	move.w	#_CTRLVC,-(sp)
	DOS	_INTVCG
	addq.l	#2,sp
	move.l	d0,abort_ctrlvc		;元の_CTRLVC
	move.w	#_ERRJVC,-(sp)
	DOS	_INTVCG
	addq.l	#2,sp
	move.l	d0,abort_errjvc		;元の_ERRJVC
	pea.l	abort
	move.w	#_CTRLVC,-(sp)
	DOS	_INTVCS
	addq.l	#6,sp
	pea.l	abort
	move.w	#_ERRJVC,-(sp)
	DOS	_INTVCS
	addq.l	#6,sp
;------------------------------------------------
;ベクタを変更する
	pea.l	trapv_routine		;TRAPV/TRAPcc/FTRAPccルーチン
	move.w	#7,-(sp)
	DOS	_INTVCS
	addq.l	#6,sp
	move.l	d0,trapv_vector		;元のTRAPV/TRAPcc/FTRAPccベクタ
;------------------------------------------------
;ロギングを開始する
	jbsr	logging_start
	beq	exit
;------------------------------------------------
;統計を開始する
	jbsr	statistics_start
;------------------------------------------------
;開始メッセージ
	putmsg	'begin: '
	putdate
	putcrlf
;------------------------------------------------
;圧縮された間接データを展開する
	jbsr	indirect_start
;------------------------------------------------
;全体ループ開始
loop::
;------------------------------------------------
;引数を確認する
	jbsr	option_loop
	beq	loopend
;------------------------------------------------
;テストを実行する
");
  if(all||mapisdefined(mnemmap,"fabs"),asmln("	jbsr	fabs_test"));
  if(all||mapisdefined(mnemmap,"facos"),asmln("	jbsr	facos_test"));
  if(all||mapisdefined(mnemmap,"fadd"),asmln("	jbsr	fadd_test"));
  if(all||mapisdefined(mnemmap,"fasin"),asmln("	jbsr	fasin_test"));
  if(all||mapisdefined(mnemmap,"fatan"),asmln("	jbsr	fatan_test"));
  if(all||mapisdefined(mnemmap,"fatanh"),asmln("	jbsr	fatanh_test"));
  if(all||mapisdefined(mnemmap,"fbccl"),
     asmln("	jbsr	fbccl060_test");
     asmln("	jbsr	fbccl88x_test"));
  if(all||mapisdefined(mnemmap,"fbccw"),
     asmln("	jbsr	fbccw060_test");
     asmln("	jbsr	fbccw88x_test"));
  if(all||mapisdefined(mnemmap,"fcmp"),asmln("	jbsr	fcmp_test"));
  if(all||mapisdefined(mnemmap,"fcos"),asmln("	jbsr	fcos_test"));
  if(all||mapisdefined(mnemmap,"fcosh"),asmln("	jbsr	fcosh_test"));
  if(all||mapisdefined(mnemmap,"fdabs"),asmln("	jbsr	fdabs_test"));
  if(all||mapisdefined(mnemmap,"fdadd"),asmln("	jbsr	fdadd_test"));
  if(all||mapisdefined(mnemmap,"fdbcc"),
     asmln("	jbsr	fdbcc060_test");
     asmln("	jbsr	fdbcc88x_test"));
  if(all||mapisdefined(mnemmap,"fddiv"),asmln("	jbsr	fddiv_test"));
  if(all||mapisdefined(mnemmap,"fdiv"),asmln("	jbsr	fdiv_test"));
  if(all||mapisdefined(mnemmap,"fdmove"),asmln("	jbsr	fdmove_test"));
  if(all||mapisdefined(mnemmap,"fdmul"),asmln("	jbsr	fdmul_test"));
  if(all||mapisdefined(mnemmap,"fdneg"),asmln("	jbsr	fdneg_test"));
  if(all||mapisdefined(mnemmap,"fdsqrt"),asmln("	jbsr	fdsqrt_test"));
  if(all||mapisdefined(mnemmap,"fdsub"),asmln("	jbsr	fdsub_test"));
  if(all||mapisdefined(mnemmap,"fetox"),asmln("	jbsr	fetox_test"));
  if(all||mapisdefined(mnemmap,"fetoxm1"),asmln("	jbsr	fetoxm1_test"));
  if(all||mapisdefined(mnemmap,"fgetexp"),asmln("	jbsr	fgetexp_test"));
  if(all||mapisdefined(mnemmap,"fgetman"),asmln("	jbsr	fgetman_test"));
  if(all||mapisdefined(mnemmap,"fint"),asmln("	jbsr	fint_test"));
  if(all||mapisdefined(mnemmap,"fintrz"),asmln("	jbsr	fintrz_test"));
  if(all||mapisdefined(mnemmap,"flog10"),asmln("	jbsr	flog10_test"));
  if(all||mapisdefined(mnemmap,"flog2"),asmln("	jbsr	flog2_test"));
  if(all||mapisdefined(mnemmap,"flogn"),asmln("	jbsr	flogn_test"));
  if(all||mapisdefined(mnemmap,"flognp1"),asmln("	jbsr	flognp1_test"));
  if(all||mapisdefined(mnemmap,"fmod"),asmln("	jbsr	fmod_test"));
  if(all||mapisdefined(mnemmap,"fmoveb"),
     asmln("	jbsr	fmovebregto_test");
     asmln("	jbsr	fmovebtoreg_test"));
  if(all||mapisdefined(mnemmap,"fmoved"),
     asmln("	jbsr	fmovedregto_test");
     asmln("	jbsr	fmovedtoreg_test"));
  if(all||mapisdefined(mnemmap,"fmovel"),
     asmln("	jbsr	fmovelregto_test");
     asmln("	jbsr	fmoveltoreg_test"));
  if(all||mapisdefined(mnemmap,"fmovep"),
     asmln("	jbsr	fmovepregto_test");
     asmln("	jbsr	fmoveptoreg_test"));
  if(all||mapisdefined(mnemmap,"fmoves"),
     asmln("	jbsr	fmovesregto_test");
     asmln("	jbsr	fmovestoreg_test"));
  if(all||mapisdefined(mnemmap,"fmovew"),
     asmln("	jbsr	fmovewregto_test");
     asmln("	jbsr	fmovewtoreg_test"));
  if(all||mapisdefined(mnemmap,"fmovex"),
     asmln("	jbsr	fmovexregto_test");
     asmln("	jbsr	fmovextoreg_test"));
  if(all||mapisdefined(mnemmap,"fmovecr"),
     asmln("	jbsr	fmovecr881_test");
     asmln("	jbsr	fmovecr882_test"));
  \\if(all||mapisdefined(mnemmap,"fmoveml"),
  \\   asmln("	jbsr	fmovemlregto_test");
  \\   asmln("	jbsr	fmovemltoreg_test"));
  \\if(all||mapisdefined(mnemmap,"fmovemx"),
  \\   asmln("	jbsr	fmovemxregto_test");
  \\   asmln("	jbsr	fmovemxtoreg_test"));
  if(all||mapisdefined(mnemmap,"fmul"),asmln("	jbsr	fmul_test"));
  if(all||mapisdefined(mnemmap,"fneg"),asmln("	jbsr	fneg_test"));
  if(all||mapisdefined(mnemmap,"frem"),asmln("	jbsr	frem_test"));
  \\if(all||mapisdefined(mnemmap,"frestore"),asmln("	jbsr	frestore_test"));
  if(all||mapisdefined(mnemmap,"fsabs"),asmln("	jbsr	fsabs_test"));
  if(all||mapisdefined(mnemmap,"fsadd"),asmln("	jbsr	fsadd_test"));
  \\if(all||mapisdefined(mnemmap,"fsave"),asmln("	jbsr	fsave_test"));
  if(all||mapisdefined(mnemmap,"fscale"),asmln("	jbsr	fscale_test"));
  if(all||mapisdefined(mnemmap,"fscc"),
     asmln("	jbsr	fscc060_test");
     asmln("	jbsr	fscc88x_test"));
  if(all||mapisdefined(mnemmap,"fsdiv"),asmln("	jbsr	fsdiv_test"));
  if(all||mapisdefined(mnemmap,"fsgldiv"),
     asmln("	jbsr	fsgldiv060_test");
     asmln("	jbsr	fsgldiv88x_test"));
  if(all||mapisdefined(mnemmap,"fsglmul"),
     asmln("	jbsr	fsglmul060_test");
     asmln("	jbsr	fsglmul88x_test"));
  if(all||mapisdefined(mnemmap,"fsin"),asmln("	jbsr	fsin_test"));
  if(all||mapisdefined(mnemmap,"fsincos"),asmln("	jbsr	fsincos_test"));
  if(all||mapisdefined(mnemmap,"fsinh"),asmln("	jbsr	fsinh_test"));
  if(all||mapisdefined(mnemmap,"fsmove"),asmln("	jbsr	fsmove_test"));
  if(all||mapisdefined(mnemmap,"fsmul"),asmln("	jbsr	fsmul_test"));
  if(all||mapisdefined(mnemmap,"fsneg"),asmln("	jbsr	fsneg_test"));
  if(all||mapisdefined(mnemmap,"fsqrt"),asmln("	jbsr	fsqrt_test"));
  if(all||mapisdefined(mnemmap,"fssqrt"),asmln("	jbsr	fssqrt_test"));
  if(all||mapisdefined(mnemmap,"fssub"),asmln("	jbsr	fssub_test"));
  if(all||mapisdefined(mnemmap,"fsub"),asmln("	jbsr	fsub_test"));
  if(all||mapisdefined(mnemmap,"ftan"),asmln("	jbsr	ftan_test"));
  if(all||mapisdefined(mnemmap,"ftanh"),asmln("	jbsr	ftanh_test"));
  if(all||mapisdefined(mnemmap,"ftentox"),asmln("	jbsr	ftentox_test"));
  if(all||mapisdefined(mnemmap,"ftrapcc"),
     asmln("	jbsr	ftrapcc060_test");
     asmln("	jbsr	ftrapcc88x_test"));
  if(all||mapisdefined(mnemmap,"ftrapccl"),
     asmln("	jbsr	ftrapccl060_test");
     asmln("	jbsr	ftrapccl88x_test"));
  if(all||mapisdefined(mnemmap,"ftrapccw"),
     asmln("	jbsr	ftrapccw060_test");
     asmln("	jbsr	ftrapccw88x_test"));
  if(all||mapisdefined(mnemmap,"ftst"),asmln("	jbsr	ftst_test"));
  if(all||mapisdefined(mnemmap,"ftwotox"),asmln("	jbsr	ftwotox_test"));
  asm(
"
;------------------------------------------------
;次の引数に進む
	jbsr	option_next
	jbra	loop

;------------------------------------------------
;全体ループ終了
loopend::
;------------------------------------------------
;アボート処理
abort::
	movea.l	abort_sp,sp
	move.l	abort_ctrlvc,-(sp)	;元の_CTRLVC
	move.w	#_CTRLVC,-(sp)
	DOS	_INTVCS
	addq.l	#6,sp
	move.l	abort_errjvc,-(sp)	;元の_ERRJVC
	move.w	#_ERRJVC,-(sp)
	DOS	_INTVCS
	addq.l	#6,sp
;------------------------------------------------
;ベクタを復元する
	move.l	trapv_vector,d0		;元のTRAPV/TRAPcc/FTRAPccベクタ
	beq	@f
	move.l	d0,-(sp)
	move.w	#7,-(sp)
	DOS	_INTVCS
	addq.l	#6,sp
@@:
;------------------------------------------------
;統計を終了する
	jbsr	statistics_end
;------------------------------------------------
;終了メッセージ
	putmsg	'end: '
	putdate
	putcrlf
	putcrlf
;------------------------------------------------
;ロギングを終了する
	jbsr	logging_end
;------------------------------------------------
;プログラムを終了する
exit::
	DOS	_EXIT

;------------------------------------------------
;アボート処理
	.data
	.align	4
abort_sp::		.dc.l	0	;アボートするときのスタックポインタ
abort_ctrlvc::		.dc.l	0	;元の_CTRLVC
abort_errjvc::		.dc.l	0	;元の_ERRJVC

;------------------------------------------------
;スタックエリア
	.bss
	.align	4
stack_area::	.ds.b	1024*64		;スタックエリア
stack_area_end::			;スタックエリアの末尾


;--------------------------------------------------------------------------------
;	TRAPV/TRAPcc/FTRAPcc
;--------------------------------------------------------------------------------

;TRAPV/TRAPcc/FTRAPccルーチン
	.text
	.even
trapv_routine::
	addq.l	#1,trapv_occurred	;TRAPV/TRAPcc/FTRAPccが発生した
	rte

	.data
	.align	4
trapv_vector::		.dc.l	0	;元のTRAPV/TRAPcc/FTRAPccベクタ
trapv_occurred::	.dc.l	0	;0=TRAPV/TRAPcc/FTRAPccは発生していない,1=TRAPV/TRAPcc/FTRAPccが発生した


;--------------------------------------------------------------------------------
;	FPUの種類
;--------------------------------------------------------------------------------

MC68881		equ	1<<0
MC68882		equ	1<<1
MC68040		equ	1<<2
FPSP040		equ	1<<3
MC68060		equ	1<<4
FPSP060		equ	1<<5

;----------------------------------------------------------------
;successful=fpu_check()
;	FPUの種類を確認する
;>d0.l:0=failed,1=successful
;------------------------------------------------
	.cpu	68030
	.text
	.even
fpu_check::
	movem.l	d1-d2/a1,-(sp)
	lea.l	$0CBD.w,a1		;FPUの有無
	IOCS	_B_BPEEK
	tst.b	d0
	beq	80f			;FPUなし
	lea.l	$0CBC.w,a1		;MPUの種類
	IOCS	_B_BPEEK
	move.l	#MC68060,d2
	cmp.b	#6,d0
	beq	@f
	move.l	#MC68040,d2
	cmp.b	#4,d0
	beq	@f
	move.l	#MC68882,d2
	fmove.l	#0,fpcr
	fmovecr.x	#1,fp0
	fmove.x	fp0,-(sp)
	move.l	(sp)+,d0
	or.l	(sp)+,d0
	or.l	(sp)+,d0
	bne	@f
	move.l	#MC68881,d2
@@:
	move.l	d2,fpu_type		;FPUの種類
	move.l	#-1,fpu_last		;前回のFPUの種類
	moveq.l	#1,d0
99:
	movem.l	(sp)+,d1-d2/a1
	rts

80:
	putmsg	'no floating point unit',13,10
	moveq.l	#0,d0
	bra	99b
	.cpu	68000

	.bss
	.align	4
fpu_type::		.ds.l	1	;FPUの種類
fpu_last::		.ds.l	1	;前回のFPUの種類


;--------------------------------------------------------------------------------
;	動作モード
;--------------------------------------------------------------------------------

OPTION_MARGIN_DEFAULT	equ	1	;超越関数の許容誤差
OPTION_MARGIN_LIMIT	equ	11
OPTION_MARGIN_MASK	equ	$F
OPTION_MAXIMUM_DEFAULT	equ	100	;テスト毎の出力される結果の最大数
OPTION_MAXIMUM_LIMIT	equ	1000000
OPTION_MAXIMUM_MASK	equ	$FFFFF
OPTION_MAXIMUM_SHIFT	equ	4
OPTION_DESTINATION	equ	1<<24	;デスティネーションオペランドを調べる
OPTION_FAILED		equ	1<<25	;失敗したテストの結果を出力する
OPTION_NANS		equ	1<<26	;NaNの仮数部を調べる
OPTION_FPSP		equ	1<<27	;浮動小数点ソフトウェアパッケージで処理される命令をテストする
OPTION_STATUS		equ	1<<28	;ステータスレジスタを調べる
OPTION_SUCCESSFUL	equ	1<<29	;成功したテストの結果を出力する
OPTION_DEFAULT		equ	OPTION_STATUS+OPTION_FAILED+OPTION_DESTINATION+(OPTION_MAXIMUM_DEFAULT<<OPTION_MAXIMUM_SHIFT)+OPTION_MARGIN_DEFAULT

;----------------------------------------------------------------
;successful=option_start(cmdl)
;	全体ループの開始前に呼び出す
;	コマンドラインをコピーする
;	引数がひとつもないとき使用法を表示する
;	全体ループの準備をする
;<4(sp).l:コマンドライン
;>d0.l:0=failed,1=successful
;------------------------------------------------
	.offsym	0,_a6
_size:
regs	reg	d1-d2/a0-a2
_regs:	.ds.l	.sizeof.(regs)
_a6:	.ds.l	1
_pc:	.ds.l	1
_cmdl:	.ds.l	1
;------------------------------------------------
	.text
	.even
option_start::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
;------------------------------------------------
;コマンドラインをコピーする
	movea.l	(_cmdl,a6),a0		;コマンドライン
	lea.l	option_args,a1		;単語列バッファ
	lea.l	option_argsend,a2	;単語列バッファの末尾
	bra	2f			;単語の間の空白を読み飛ばす

;単語が終わった
1:
	cmpa.l	a2,a1
	bcc	11f			;バッファが溢れた
	clr.b	(a1)+			;単語の末尾の0
;単語の間の空白を読み飛ばす
2:
	move.b	(a0)+,d0
	beq	10f			;単語が始まる前にコマンドラインが終わった
	cmp.b	#' ',d0
	bls	2b			;単語の間の空白を読み飛ばす
	cmp.b	#$22,d0
	beq	6f			;$22～$22の中の次の文字を読み出す
	cmp.b	#$27,d0
	beq	8f			;'～'の中の次の文字を読み出す
	cmp.b	#'a',d0
	blo	3f			;文字をバッファに書き込む
	cmp.b	#'z',d0
	bhi	3f			;文字をバッファに書き込む
	and.b	#$DF,d0			;大文字にする
;文字をバッファに書き込む
3:
	cmpa.l	a2,a1
	bcc	11f			;バッファが溢れた
	move.b	d0,(a1)+
;次の文字を読み出す
4:
	move.b	(a0)+,d0
	beq	9f			;単語の途中でコマンドラインが終わった
	cmp.b	#' ',d0
	bls	1b			;単語が終わった
	cmp.b	#$22,d0
	beq	6f			;$22～$22の中の次の文字を読み出す
	cmp.b	#$27,d0
	beq	8f			;'～'の中の次の文字を読み出す
	cmp.b	#'a',d0
	blo	3b			;文字をバッファに書き込む
	cmp.b	#'z',d0
	bhi	3b			;文字をバッファに書き込む
	and.b	#$DF,d0			;大文字にする
	bra	3b			;文字をバッファに書き込む

;$22～$22の中の文字をバッファに書き込む
5:
	cmpa.l	a2,a1
	bcc	11f			;バッファが溢れた
	move.b	d0,(a1)+
;$22～$22の中の次の文字を読み出す
6:
	move.b	(a0)+,d0
	beq	9f			;単語の途中でコマンドラインが終わった
	cmp.b	#$22,d0
	beq	4b			;次の文字を読み出す
	cmp.b	#'a',d0
	blo	5b			;$22～$22の中の文字をバッファに書き込む
	cmp.b	#'z',d0
	bhi	5b			;$22～$22の中の文字をバッファに書き込む
	and.b	#$DF,d0			;大文字にする
	bra	5b			;$22～$22の中の文字をバッファに書き込む

;'～'の中の文字をバッファに書き込む
7:
	cmpa.l	a2,a1
	bcc	11f			;バッファが溢れた
	move.b	d0,(a1)+
;'～'の中の次の文字を読み出す
8:
	move.b	(a0)+,d0
	beq	9f			;単語の途中でコマンドラインが終わった
	cmp.b	#$27,d0
	beq	4b			;次の文字を読み出す
	cmp.b	#'a',d0
	blo	7b			;'～'の中の文字をバッファに書き込む
	cmp.b	#'z',d0
	bhi	7b			;'～'の中の文字をバッファに書き込む
	and.b	#$DF,d0			;大文字にする
	bra	7b			;'～'の中の文字をバッファに書き込む

;単語の途中でコマンドラインが終わった
9:
	cmpa.l	a2,a1
	bcc	11f			;バッファが溢れた
	clr.b	(a1)+			;単語の末尾の0
;単語が始まる前にコマンドラインが終わった
10:
	cmpa.l	a2,a1
	bcc	11f			;バッファが溢れた
	clr.b	(a1)			;バッファの末尾の0
	bra	12f

;バッファが溢れた
11:
	putmsg	'too long command line',13,10
	moveq.l	#0,d0
	bra	99f

12:
;------------------------------------------------
;引数がひとつもないとき使用法を表示する
	tst.b	option_args
	bne	@f
	putstr	#option_usage
	moveq.l	#0,d0
	bra	99f

@@:
;------------------------------------------------
;全体ループの準備をする
	lea.l	option_args,a1		;単語列バッファ
	move.l	a1,option_word		;次の単語
	move.l	#OPTION_DEFAULT,option_mode	;動作モード
	move.l	#-1,option_lastmode	;前回の動作モード
	lea.l	option_donestart,a1	;実行済みのテストのIDと動作モードのリストの先頭
	move.l	a1,option_donepointer	;実行済みのテストのIDと動作モードのリストの末尾
;------------------------------------------------
98:
	moveq.l	#1,d0
99:
	movem.l	(_regs,a6),regs
	unlk	a6
	rts

;------------------------------------------------
;使用法
	.text
option_usage::
	.dc.b	'usage: ",TEST_X," <mnemonic or option> ...',13,10
	.dc.b	'  FABS FACOS FADD ... -- Run tests selected by the first few letters of a mnemonic.',13,10
	.dc.b	'  all -- Run all tests.',13,10
	.dc.b	'  destination=0..[1] -- Check the destination operand.',13,10
	.dc.b	'  easy -- It',39,'s the same as margin=1 nans=0.',13,10
	.dc.b	'  failed=0..[1] -- Output the results of failed tests.',13,10
	.dc.b	'  fpsp=[0]..1 -- Test the instructions processed by the software package.',13,10
	.dc.b	'  hard -- It',39,'s the same as margin=0 nans=1.',13,10
	.dc.b	'  logging=0..[1] -- Output the results to ',34,'",TEST_LOG,"',34,'.',13,10
	.dc.b	'  margin=0..[1]..11 -- The acceptable margin of error in transcendental functions.',13,10
	.dc.b	'  maximum=0..[100]..1000000 -- The maximum number of results outputted for each test.',13,10
	.dc.b	'  nans=[0]..1 -- Check the mantissa of NaNs.',13,10
	.dc.b	'  status=0..[1] -- Check the status register.',13,10
	.dc.b	'  stdout=0..[1] -- Output the results to the standard output.',13,10
	.dc.b	'  successful=[0]..1 -- Output the results of successful tests.',13,10
	.dc.b	0

;----------------------------------------------------------------
;option_loop()
;	全体ループの先頭で呼び出す
;	次の単語がなければ全体ループを終了する
;	次の単語によって動作モードを変更する
	.text
	.even
option_loop::
	movea.l	option_word,a2		;次の単語
	move.l	option_mode,d2		;動作モード
	bra	20f

;次の単語に進む
10:
	tst.b	(a2)+
	bne	10b
;------------------------------------------------
;次の単語がなければ全体ループを終了する
20:
	tst.b	(a2)
	beq	80f			;全体ループを終了する
;------------------------------------------------
;次の単語によって動作モードを更新する
;--------------------------------
;destination=0..1
	leamsg	'DESTINATION',a0
	movea.l	a2,a1
	bsr	option_stringstartwith
	bne	2f
	lea.l	(.sizeof.('DESTINATION'),a2),a0
	moveq.l	#1,d0
	jbsr	option_equal_n
	bmi	2f
	and.l	#.not.(OPTION_DESTINATION),d2
	neg.l	d0
	and.l	#OPTION_DESTINATION,d0
	or.l	d0,d2			;destination
	bra	10b			;次の単語に進む

2:
;--------------------------------
;easy=1
	leamsg	'EASY',a0
	movea.l	a2,a1
	bsr	option_stringequals
	bne	2f
	and.l	#.not.(OPTION_NANS+OPTION_MARGIN_MASK),d2
	or.l	#1,d2			;margin=1 nans=0
	bra	10b			;次の単語に進む

2:
;--------------------------------
;failed=0..1
	leamsg	'FAILED',a0
	movea.l	a2,a1
	bsr	option_stringstartwith
	bne	2f
	lea.l	(.sizeof.('FAILED'),a2),a0
	moveq.l	#1,d0
	jbsr	option_equal_n
	bmi	2f
	and.l	#.not.(OPTION_FAILED),d2
	neg.l	d0
	and.l	#OPTION_FAILED,d0
	or.l	d0,d2			;failed
	bra	10b			;次の単語に進む

2:
;--------------------------------
;fpsp=0..1
	leamsg	'FPSP',a0
	movea.l	a2,a1
	bsr	option_stringstartwith
	bne	2f
	lea.l	(.sizeof.('FPSP'),a2),a0
	moveq.l	#1,d0
	jbsr	option_equal_n
	bmi	2f
	bne	1f
	and.l	#.not.(OPTION_FPSP),d2	;fpsp=0
	cmpi.l	#FPSP040,fpu_type
	bne	@f
	move.l	#MC68040,fpu_type
	bra	10b			;次の単語に進む

@@:
	cmpi.l	#FPSP060,fpu_type
	bne	10b			;次の単語に進む
	move.l	#MC68060,fpu_type
	bra	10b			;次の単語に進む

1:
	or.l	#OPTION_FPSP,d2		;fpsp=1
	cmpi.l	#MC68040,fpu_type
	bne	@f
	move.l	#FPSP040,fpu_type
	bra	10b			;次の単語に進む

@@:
	cmpi.l	#MC68060,fpu_type
	bne	10b			;次の単語に進む
	move.l	#FPSP060,fpu_type
	bra	10b			;次の単語に進む

2:
;--------------------------------
;hard=1
	leamsg	'HARD',a0
	movea.l	a2,a1
	bsr	option_stringequals
	bne	2f
	and.l	#.not.(OPTION_NANS+OPTION_MARGIN_MASK),d2
	or.l	#OPTION_NANS+0,d2	;margin=0 nans=1
	bra	10b			;次の単語に進む

2:
;--------------------------------
;logging=0..1
	leamsg	'LOGGING',a0
	movea.l	a2,a1
	bsr	option_stringstartwith
	bne	2f
	lea.l	(.sizeof.('LOGGING'),a2),a0
	moveq.l	#1,d0
	jbsr	option_equal_n
	bmi	2f
	sne.b	logging_logging
	bra	10b			;次の単語に進む

2:
;--------------------------------
;margin=0..OPTION_MARGIN_LIMIT
	leamsg	'MARGIN=',a0
	movea.l	a2,a1
	bsr	option_stringstartwith
	bne	2f
	lea.l	(.sizeof.('MARGIN'),a2),a0
	moveq.l	#OPTION_MARGIN_LIMIT,d0
	jbsr	option_equal_n
	bmi	2f
	and.l	#.not.(OPTION_MARGIN_MASK),d2
	or.l	d0,d2			;margin
	bra	10b			;次の単語に進む

2:
;--------------------------------
;maxmum=0..OPTION_MAXIMUM_LIMIT
	leamsg	'MAXIMUM=',a0
	movea.l	a2,a1
	bsr	option_stringstartwith
	bne	2f
	lea.l	(.sizeof.('MAXIMUM'),a2),a0
	move.l	#OPTION_MAXIMUM_LIMIT,d0
	jbsr	option_equal_n
	bmi	2f
	and.l	#.not.(OPTION_MAXIMUM_MASK<<OPTION_MAXIMUM_SHIFT),d2
	lsl.l	#OPTION_MAXIMUM_SHIFT,d0
	or.l	d0,d2			;maximum
	bra	10b			;次の単語に進む

2:
;--------------------------------
;nans=0..1
	leamsg	'NANS',a0
	movea.l	a2,a1
	bsr	option_stringstartwith
	bne	2f
	lea.l	(.sizeof.('NANS'),a2),a0
	moveq.l	#1,d0
	jbsr	option_equal_n
	bmi	2f
	and.l	#.not.(OPTION_NANS),d2
	neg.l	d0
	and.l	#OPTION_NANS,d0
	or.l	d0,d2			;nans
	bra	10b			;次の単語に進む

2:
;--------------------------------
;successful=0..1
	leamsg	'SUCCESSFUL',a0
	movea.l	a2,a1
	bsr	option_stringstartwith
	bne	2f
	lea.l	(.sizeof.('SUCCESSFUL'),a2),a0
	moveq.l	#1,d0
	jbsr	option_equal_n
	bmi	2f
	and.l	#.not.(OPTION_SUCCESSFUL),d2
	neg.l	d0
	and.l	#OPTION_SUCCESSFUL,d0
	or.l	d0,d2			;successful
	bra	10b			;次の単語に進む

2:
;--------------------------------
;status=0..1
	leamsg	'STATUS',a0
	movea.l	a2,a1
	bsr	option_stringstartwith
	bne	2f
	lea.l	(.sizeof.('STATUS'),a2),a0
	moveq.l	#1,d0
	jbsr	option_equal_n
	bmi	2f
	and.l	#.not.(OPTION_STATUS),d2
	neg.l	d0
	and.l	#OPTION_STATUS,d0
	or.l	d0,d2			;status
	bra	10b			;次の単語に進む

2:
;--------------------------------
;stdout=0..1
	leamsg	'STDOUT',a0
	movea.l	a2,a1
	bsr	option_stringstartwith
	bne	2f
	lea.l	(.sizeof.('STDOUT'),a2),a0
	moveq.l	#1,d0
	jbsr	option_equal_n
	bmi	2f
	sne.b	logging_stdout
	bra	10b			;次の単語に進む

2:
;--------------------------------
	move.l	d2,option_mode		;動作モード
	move.l	a2,option_word		;次の単語
;
	bra	98f

;全体ループを終了する
80:
	moveq.l	#0,d0
	bra	99f

98:
	moveq.l	#1,d0
99:
	rts

;----------------------------------------------------------------
;mnemonic_start(mnemonic,fpu)
;	個々のテストの開始前に呼び出す
;	ニモニックを確認する
;	FPUを確認する
;	実行済みかどうか確認する
;	ニモニックのカウンタをクリアする
;	初回または動作モードが変更されたとき動作モードを表示する
;	バックグラウンドスレッドを回す
;<(sp).l:復帰アドレス。テストのIDとして使う
;<4(sp).l:テストのニモニックの条件
;<8(sp).l:テストのFPUの条件
;>d0.l:0=失敗,1=成功
;>eq=失敗,ne=成功
;------------------------------------------------
	.offsym	0,_a6
_size:
regs	reg	d1-d2/a0-a2
_regs:	.ds.l	.sizeof.(regs)
_a6:	.ds.l	1
_pc:	.ds.l	1
_mnem:	.ds.l	1
_fpu:	.ds.l	1
;------------------------------------------------
	.text
	.even
mnemonic_start::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
;------------------------------------------------
;ニモニックを確認する
	leamsg	'ALL',a0
	movea.l	option_word,a1		;次の単語
	bsr	option_stringequals
	beq	@f			;allはすべてのニモニックと一致する
	movea.l	option_word,a0		;次の単語
	movea.l	(_mnem,a6),a1		;テストのニモニックの条件
	bsr	option_stringstartwith
	bne	97f			;ニモニックが一致しなかった。失敗
@@:
;------------------------------------------------
;FPUを確認する
	move.l	(_fpu,a6),d0		;テストのFPUの条件
	and.l	fpu_type,d0	;FPUの種類
	beq	97f			;FPUが一致しなかった。失敗
;------------------------------------------------
;実行済みかどうか確認する
	move.l	(_pc,a6),d0		;テストのID
	move.l	option_mode,d1		;動作モード
	lea.l	option_donestart,a0	;実行済みのテストのIDと動作モードのリストの先頭
	movea.l	option_donepointer,a1	;実行済みのテストのIDと動作モードのリストの末尾
	bra	3f

1:
	cmp.l	(a0),d0			;テストのID
	bne	2f
	cmp.l	4(a0),d1		;動作モード
	beq	97f			;実行済みだった。失敗
2:
	addq.l	#8,a0
3:
	cmpa.l	a1,a0
	blo	1b
;実行済みではなかった
	move.l	d0,(a1)+		;実行済みのテストのID
	move.l	d1,(a1)+		;実行済みの動作モード
	move.l	a1,option_donepointer
;------------------------------------------------
;ニモニックのカウンタをクリアする
	clr.l	mnemonic_counter
	clr.l	statistics_tested
	clr.l	statistics_failed
;------------------------------------------------
;初回はFPUの種類を表示する
	move.l	fpu_type,d2	;FPUの種類
	cmp.l	fpu_last,d2	;前回のFPUの種類
	beq	3f
	move.l	d2,fpu_last
	putmsg	'fpu: '
;
	move.l	#MC68881,d0
	and.l	d2,d0
	beq	1f
	leamsg	'MC68881',a0
	bra	2f

1:
	move.l	#MC68882,d0
	and.l	d2,d0
	beq	1f
	leamsg	'MC68882',a0
	bra	2f

1:
	move.l	#MC68040,d0
	and.l	d2,d0
	beq	1f
	leamsg	'MC68040',a0
	bra	2f

1:
	move.l	#FPSP040,d0
	and.l	d2,d0
	beq	1f
	leamsg	'040FPSP',a0
	bra	2f

1:
	move.l	#MC68060,d0
	and.l	d2,d0
	beq	1f
	leamsg	'MC68060',a0
	bra	2f

1:
	move.l	#FPSP060,d0
	and.l	d2,d0
	beq	1f
	leamsg	'060FPSP',a0
	bra	2f

1:
	leamsg	'???',a0
2:
	putstr	a0
	putcrlf
3:
;------------------------------------------------
;初回または動作モードが変更されたとき動作モードを表示する
	move.l	option_mode,d2		;動作モード
	cmp.l	option_lastmode,d2	;前回の動作モード
	beq	3f
	move.l	d2,option_lastmode
	putmsg	'option:'
;--------------------------------
	putmsg	' destination'
	move.l	d2,d0
	and.l	#OPTION_DESTINATION,d0
	bne	@f
	putmsg	'=0'
@@:
;--------------------------------
	move.l	d2,d0
	and.l	#OPTION_NANS+OPTION_MARGIN_MASK,d0
	cmp.l	#1,d0			;margin=1 nans=0
	bne	@f
	putmsg	' easy'
@@:
;--------------------------------
	putmsg	' failed'
	move.l	d2,d0
	and.l	#OPTION_FAILED,d0
	bne	@f
	putmsg	'=0'
@@:
;--------------------------------
	putmsg	' fpsp'
	move.l	d2,d0
	and.l	#OPTION_FPSP,d0
	bne	@f
	putmsg	'=0'
@@:
;--------------------------------
	move.l	d2,d0
	and.l	#OPTION_NANS+OPTION_MARGIN_MASK,d0
	cmp.l	#OPTION_NANS+0,d0	;margin=0 nans=1
	bne	@f
	putmsg	' hard'
@@:
;--------------------------------
	putmsg	' margin='
	move.l	d2,d0
	and.l	#OPTION_MARGIN_MASK,d0
	putdec	d0
;--------------------------------
	putmsg	' maximum='
	move.l	d2,d0
	lsr.l	#OPTION_MAXIMUM_SHIFT,d0
	and.l	#OPTION_MAXIMUM_MASK,d0
	putdec	d0
;--------------------------------
	putmsg	' nans'
	move.l	d2,d0
	and.l	#OPTION_NANS,d0
	bne	@f
	putmsg	'=0'
@@:
;--------------------------------
	putmsg	' status'
	move.l	d2,d0
	and.l	#OPTION_STATUS,d0
	bne	@f
	putmsg	'=0'
@@:
;--------------------------------
	putmsg	' successful'
	move.l	d2,d0
	and.l	#OPTION_SUCCESSFUL,d0
	bne	@f
	putmsg	'=0'
@@:
;------------------------------------------------
	putcrlf
3:
;------------------------------------------------
;バックグラウンドスレッドを回す
	move.l	fpu_type,d0	;FPUの種類
	and.l	#MC68881+MC68882+MC68040+FPSP040+MC68060+FPSP060,d0
	beq	@f
	.cpu	68030
	fnop
	.cpu	68000
@@:
	DOS	_CHANGE_PR
;------------------------------------------------
;成功
98:
	moveq.l	#1,d0
99:
	movem.l	(_regs,a6),regs
	unlk	a6
	rts

;失敗
97:
	moveq.l	#0,d0
	bra	99b

	.data
	.align	4
mnemonic_counter::	.dc.l	1	;ニモニックのカウンタ

;----------------------------------------------------------------
;mnemonic_end()
;	ニモニックの成績を表示する
;	ニモニックの成績を総合成績に加える
	.text
	.even
mnemonic_end::
	movem.l	d0-d1,-(sp)
	move.l	statistics_tested,d0
	move.l	statistics_failed,d1
	putmsg	'score: '
	movem.l	d0-d1,-(sp)
	jbsr	statistics_output
	addq.l	#8,sp
	add.l	d0,statistics_ttl_tested
	add.l	d1,statistics_ttl_failed
	movem.l	(sp)+,d0-d1
	rts

;----------------------------------------------------------------
;option_next()
;	全体ループの末尾で呼び出す
;	次の単語に進む
	.text
	.even
option_next::
	move.l	a0,-(sp)
;------------------------------------------------
;次の単語に進む
	movea.l	option_word,a0		;次の単語
@@:
	tst.b	(a0)+
	bne	@b
	move.l	a0,option_word		;次の単語
;------------------------------------------------
	movea.l	(sp)+,a0
	rts

;----------------------------------------------------------------
;	文字列比較
;<a0.l:文字列
;<a1.l:文字列
;>eq=一致,ne=不一致
	.text
	.even
option_stringequals::
1:
	tst.b	(a0)
	beq	2f
	cmpm.b	(a1)+,(a0)+
	beq	1b
	rts

2:
	tst.b	(a1)
	rts

;----------------------------------------------------------------
;	先頭文字列比較
;<a0.l:先頭文字列
;<a1.l:文字列
;>eq=一致,ne=不一致
	.text
	.even
option_stringstartwith::
1:
	tst.b	(a0)
	beq	2f
	cmpm.b	(a1)+,(a0)+
	beq	1b
2:
	rts

;----------------------------------------------------------------
;	'=N'を読み取る
;<d0.l:上限
;<a0.l:'='の位置
;>d0.l:N。'='がないとき1。エラーのとき-1
	.text
	.even
option_equal_n::
	movem.l	d1-d2/a0,-(sp)
	move.l	d0,d2
	moveq.l	#1,d0
	tst.b	(a0)
	beq	9f			;最初に文字がない
	cmpi.b	#'=',(a0)+
	bne	8f			;最初の文字が'='でない
	move.b	(a0)+,d0
	beq	8f			;'='の後に文字がない
	sub.b	#'0',d0
	blo	8f			;'='の後の文字が数字でない
	cmp.b	#9,d0
	bhi	8f			;'='の後の文字が数字でない
1:
	moveq.l	#0,d1
	move.b	(a0)+,d1
	beq	2f			;次の文字がない
	sub.b	#'0',d1
	blo	8f			;次の文字が数字でない
	cmp.b	#9,d1
	bhi	8f			;次の文字が数字でない
	add.l	d0,d0
	add.l	d0,d1
	lsl.l	#2,d0
	add.l	d1,d0
	bra	1b

2:
	cmp.l	d2,d0
	bls	9f
8:
	moveq.l	#-1,d0
9:
	movem.l	(sp)+,d1-d2/a0
	tst.l	d0
	rts

;----------------------------------------------------------------

	.bss
option_args::		.ds.b	4096	;単語列バッファ。単語,0,単語,0,…,単語,0,0
option_argsend::

	.bss
	.align	4
option_word::		.ds.l	1	;次の単語
option_mode::		.ds.l	1	;動作モード
option_lastmode::	.ds.l	1	;動作モード

	.bss
	.align	4
option_donepointer::	.ds.l	1	;実行済みのテストのIDと動作モードの書き込み位置
option_donestart::	.ds.l	2*1024*32	;実行済みのテストのIDと動作モードのリスト
option_doneend::


;--------------------------------------------------------------------------------
;	logging
;--------------------------------------------------------------------------------

;------------------------------------------------
;logging_start()
;>d0.l:0=failed,1=successful
	.text
	.even
logging_start::
	move.l	d1,-(sp)
;
	st.b	logging_logging
	st.b	logging_stdout
;open log file
	move.w	#2,-(sp)		;read and write
	peamsg	'",TEST_LOG,"'		;log file name
	DOS	_OPEN
	addq.l	#6,sp
	tst.l	d0
	bpl	@f
	move.w	#$0020,-(sp)		;file
	peamsg	'",TEST_LOG,"'		;log file name
	DOS	_CREATE
	addq.l	#6,sp
	tst.l	d0
	bpl	@f
	putmsg	'cannot open ",TEST_LOG," to write'
	moveq.l	#0,d0
	bra	99f

@@:
	move.w	d0,d1			;log file handle
	move.w	d1,logging_file_handle
;check device type
	move.w	d1,-(sp)		;log file handle
	clr.w	-(sp)			;device information
	DOS	_IOCTRL
	addq.l	#4,sp
	tst.b	d0
	bmi	1f			;character device
;block device or remote device
;seek end
	move.w	#2,-(sp)		;SEEK_END
	clr.l	-(sp)
	move.w	d1,-(sp)		;log file handle
	DOS	_SEEK
	addq.l	#8,sp
	bra	2f

;character device
1:
;check output status
	move.w	d1,-(sp)		;log file handle
	move.w	#7,-(sp)		;output status
	DOS	_IOCTRL
	addq.l	#4,sp
	tst.l	d0
	bne	@f
	putmsg	'cannot output to ",TEST_LOG,"'
	moveq.l	#0,d0
	bra	99f

@@:
2:
	move.l	#logging_cache_start,logging_cache_pointer
;
98:
	moveq.l	#1,d0
99:
	move.l	(sp)+,d1
	tst.l	d0
	rts

;------------------------------------------------
;logging_write(buffer,length)
;<4(sp).l:buffer
;<8(sp).l:length
regs		reg	d0-d3/a0-a3
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_a6:	.ds.l	1
_pc:	.ds.l	1
_buff:	.ds.l	1
_leng:	.ds.l	1
	.text
	.even
logging_write::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
;ログファイルに出力する
	tst.b	logging_logging
	beq	19f
	move.w	logging_file_handle,d1	;log file handle
	bmi	19f
;出力データをキャッシュにコピーする
	move.l	(_leng,a6),d2		;出力データの残りのバイト数
	movea.l	(_buff,a6),a0		;出力データの読み出し位置
	movea.l	logging_cache_pointer,a1	;キャッシュの書き込み位置
	lea.l	logging_cache_end,a3	;キャッシュの終了アドレス。固定
	bra	17f

10:
	move.l	a3,d3			;キャッシュの終了アドレス
	sub.l	a1,d3			;キャッシュの残りのバイト数。キャッシュの終了アドレス-キャッシュの書き込み位置
	cmp.l	d2,d3			;キャッシュの残りのバイト数<=>出力データの残りのバイト数
	blo	11f
	move.l	d2,d3			;出力データの残りのバイト数
11:
;<d3.l:出力データをキャッシュにコピーするバイト数。出力データの残りのバイト数とキャッシュの残りのバイト数の少ない方。0ではない
	move.l	d3,d0			;出力データをキャッシュにコピーするバイト数
	subq.l	#1,d0
	swap.w	d0
12:
	swap.w	d0
13:
	move.b	(a0)+,(a1)+		;出力データの読み出し位置からキャッシュの書き込み位置へ
	dbra	d0,13b
	swap.w	d0
	dbra	d0,12b
	cmpa.l	a3,a1			;キャッシュの書き込み位置<=>キャッシュの終了アドレス
	blo	14f
;キャッシュが一杯になった
	lea.l	logging_cache_start,a1	;キャッシュの開始アドレス
	movea.l	a3,a2			;キャッシュの終了アドレス
	suba.l	a1,a2			;キャッシュの全体のバイト数
	movem.l	a1-a2,-(sp)
	move.w	d1,-(sp)		;log file handle
	DOS	_WRITE
	lea.l	10(sp),sp
14:
	move.l	a1,logging_cache_pointer	;キャッシュの書き込み位置
	sub.l	d3,d2			;出力データの残りのバイト数
17:
	tst.l	d2			;出力データの残りのバイト数
	bne	10b
19:
;標準出力に出力する
	tst.b	logging_stdout
	beq	29f
	move.l	(_leng,a6),-(sp)	;length
	move.l	(_buff,a6),-(sp)	;buffer
	move.w	#1,-(sp)		;stdout
	DOS	_WRITE
	lea.l	10(sp),sp
29:
	movem.l	(_regs,a6),regs
	unlk	a6
	rts

;------------------------------------------------
;logging_end()
logging_end::
	movem.l	d0-d1/a1-a2,-(sp)
;close log file
	move.w	logging_file_handle,d1	;log file handle
	bmi	19f
	lea.l	logging_cache_start,a1	;キャッシュの開始アドレス
	movea.l	logging_cache_pointer,a2	;キャッシュの書き込み位置
	suba.l	a1,a2			;キャッシュの現在のバイト数
	move.l	a2,d0
	beq	11f
	movem.l	a1-a2,-(sp)
	move.w	d1,-(sp)		;log file handle
	DOS	_WRITE
	lea.l	10(sp),sp
11:
	move.l	a1,logging_cache_pointer	;キャッシュの書き込み位置
	move.w	d1,-(sp)		;log file handle
	DOS	_CLOSE
	addq.l	#2,sp
	move.w	#-1,logging_file_handle
19:
;
	sf.b	logging_logging
	st.b	logging_stdout
;
	movem.l	(sp)+,d0-d1/a1-a2
	rts

;------------------------------------------------

	.data
logging_logging::	.dc.b	0	;ファイルに出力する
logging_stdout::	.dc.b	-1	;標準出力に出力する
	.even
logging_file_handle::	.dc.w	-1	;log file handle

	.bss
	.align	4
logging_cache_pointer::	.ds.l	1	;キャッシュの書き込み位置
logging_cache_start::	.ds.b	1024*64	;キャッシュ
logging_cache_end::


;--------------------------------------------------------------------------------
;	statistics
;--------------------------------------------------------------------------------

;--------------------------------------------------------------------------------
	.text
	.even
statistics_start::
	clr.l	statistics_ttl_tested
	clr.l	statistics_ttl_failed
	rts

;--------------------------------------------------------------------------------
;statistics_update()
;<(4,sp).l:0=failed,1=successful
;>d0.l:0=not output,1=output
	.text
	.even
statistics_update::
	addq.l	#1,statistics_tested
	tst.l	(4,sp)
	bne	1f			;successful
;failed
	addq.l	#1,statistics_failed
	move.l	#OPTION_FAILED,d0
	bra	2f

;successful
1:
	move.l	#OPTION_SUCCESSFUL,d0
2:
	and.l	option_mode,d0
	beq	8f			;not output
	addq.l	#1,mnemonic_counter
	move.l	option_mode,d0
	lsr.l	#OPTION_MAXIMUM_SHIFT,d0
	and.l	#OPTION_MAXIMUM_MASK,d0
	cmp.l	mnemonic_counter,d0
	blo	8f			;not output
;output
	move.l	mnemonic_counter,d0
	putdec	d0
	putmsg	': ',
	moveq.l	#1,d0
9:
	rts

;not output
8:
	moveq.l	#0,d0
	bra	9b

;--------------------------------------------------------------------------------
	.text
	.even
statistics_end::
	putmsg	'total: '
	move.l	statistics_ttl_failed,-(sp)
	move.l	statistics_ttl_tested,-(sp)
	jbsr	statistics_output
	addq.l	#8,sp
	rts

;--------------------------------------------------------------------------------
;<(4,sp).l:tested
;<(8,sp).l:failed
	.text
	.even
statistics_output::
	movem.l	d0-d6,-(sp)
	move.l	(4*7+4,sp),d6		;d6=tested
	move.l	(4*7+8,sp),d4		;d4=failed
	putmsg	'tested='
	move.l	d6,d5			;tested
	sub.l	d4,d5			;d5=successful=tested-failed
	putdec	d6			;tested
	tst.l	d6			;tested
	beq	8f			;no tests were performed
	move.l	#10000,d0
	move.l	d5,d1			;successful
	jbsr	mull			;d0:d1=10000*successful
	moveq.l	#0,d2
	move.l	d6,d3			;d2:d3=tested
	jbsr	divq			;d1=10000*successful/tested
	move.l	#10000,d0
	sub.l	d1,d0			;d0=10000-10000*successful/tested
	putmsg	' failed='
	putdec	d4			;failed
	putchr	#'('
	putfix	d0,#2			;10000-10000*successful/tested
	putmsg	'%) successful='
	putdec	d5			;successful
	putchr	#'('
	putfix	d1,#2			;10000*successful/tested
	putmsg	'%)'
8:
	putcrlf
	movem.l	(sp)+,d0-d6
	rts

	.bss

	.align	4
statistics_tested::	.ds.l	1	;number of tests
statistics_failed::	.ds.l	1	;number of failed tests
statistics_ttl_tested::	.ds.l	1	;number of total tests
statistics_ttl_failed::	.ds.l	1	;number of total failed tests


;--------------------------------------------------------------------------------
;	結果を比較する
;--------------------------------------------------------------------------------

;--------------------------------------------------------------------------------
;successful=test_status()
;	statusを比較する
;<(4,sp).l:actual status
;<(8,sp).l:expected status
;>d0.l:0=failed,1=successful
	.cpu	68030
	.offsym	0,_a6
_size:
_a6:	.ds.l	1
_pc:	.ds.l	1
_asta:	.ds.l	1	;actual status
_esta:	.ds.l	1	;expected status
	.text
	.even
test_status::
	link.w	a6,#_size
;------------------------------------------------
;status
	move.l	option_mode,d0
	and.l	#OPTION_STATUS,d0
	beq	19f			;statusをテストしない。statusが一致
;statusをテストする
	move.l	(_asta,a6),d0		;actual status
	cmp.l	(_esta,a6),d0		;expected status
	bne	97f			;statusが一致しない。失敗
;statusが一致
19:
;------------------------------------------------
;成功
98:
	moveq.l	#1,d0
99:
	unlk	a6
	rts

;失敗
97:
	moveq.l	#0,d0
	bra	99b
	.cpu	68000

;--------------------------------------------------------------------------------
;successful=test_single()
;	singleの結果を比較する。誤差は許容しない
;<(4,sp).s:actual result
;<(8,sp).l:actual status
;<(12,sp).s:expected result
;<(16,sp).l:expected status
;>d0.l:0=failed,1=successful
	.cpu	68030
	.offsym	0,_a6
_size:
_a6:	.ds.l	1
_pc:	.ds.l	1
_ares:	.ds.s	1	;actual result
_asta:	.ds.l	1	;actual status
_eres:	.ds.s	1	;expected result
_esta:	.ds.l	1	;expected status
	.text
	.even
test_single::
	link.w	a6,#_size
;------------------------------------------------
;status
	move.l	option_mode,d0
	and.l	#OPTION_STATUS,d0
	beq	19f			;statusをテストしない。statusが一致
;statusをテストする
	move.l	(_asta,a6),d0		;actual status
	cmp.l	(_esta,a6),d0		;expected status
	bne	97f			;statusが一致しない。失敗
;statusが一致
19:
;------------------------------------------------
;result
	move.l	option_mode,d0
	and.l	#OPTION_DESTINATION,d0
	beq	39f			;resultをテストしない。resultが一致
;resultをテストする
	move.l	(_ares,a6),d0		;actual result
	cmp.l	(_eres,a6),d0		;expected result
	bne	97f			;resultが一致しない。失敗
;resultが一致
39:
;------------------------------------------------
;成功
98:
	moveq.l	#1,d0
99:
	unlk	a6
	rts

;失敗
97:
	moveq.l	#0,d0
	bra	99b
	.cpu	68000

;--------------------------------------------------------------------------------
;successful=test_double()
;	doubleの結果を比較する。誤差は許容しない
;<(4,sp).d:actual result
;<(12,sp).l:actual status
;<(16,sp).d:expected result
;<(24,sp).l:expected status
;>d0.l:0=failed,1=successful
	.cpu	68030
	.offsym	0,_a6
_size:
_a6:	.ds.l	1
_pc:	.ds.l	1
_ares:	.ds.d	1	;actual result
_asta:	.ds.l	1	;actual status
_eres:	.ds.d	1	;expected result
_esta:	.ds.l	1	;expected status
	.text
	.even
test_double::
	link.w	a6,#_size
;------------------------------------------------
;status
	move.l	option_mode,d0
	and.l	#OPTION_STATUS,d0
	beq	19f			;statusをテストしない。statusが一致
;statusをテストする
	move.l	(_asta,a6),d0		;actual status
	cmp.l	(_esta,a6),d0		;expected status
	bne	97f			;statusが一致しない。失敗
;statusが一致
19:
;------------------------------------------------
;result
	move.l	option_mode,d0
	and.l	#OPTION_DESTINATION,d0
	beq	39f			;resultをテストしない。resultが一致
;resultをテストする
	move.l	(_ares,a6),d0		;actual result 1st
	cmp.l	(_eres,a6),d0		;expected result 1st
	bne	97f			;resultが一致しない。失敗
	move.l	(4+_ares,a6),d0		;actual result 2nd
	cmp.l	(4+_eres,a6),d0		;expected result 2nd
	bne	97f			;resultが一致しない。失敗
;resultが一致
39:
;------------------------------------------------
;成功
98:
	moveq.l	#1,d0
99:
	unlk	a6
	rts

;失敗
97:
	moveq.l	#0,d0
	bra	99b
	.cpu	68000

;--------------------------------------------------------------------------------
;successful=test_packed()
;	packedの結果を比較する。誤差は許容しない
;<(4,sp).p:actual result
;<(12,sp).l:actual status
;<(16,sp).p:expected result
;<(24,sp).l:expected status
;>d0.l:0=failed,1=successful
	.cpu	68030
	.offsym	0,_a6
_size:
_a6:	.ds.l	1
_pc:	.ds.l	1
_ares:	.ds.p	1	;actual result
_asta:	.ds.l	1	;actual status
_eres:	.ds.p	1	;expected result
_esta:	.ds.l	1	;expected status
	.text
	.even
test_packed::
	link.w	a6,#_size
;------------------------------------------------
;status
	move.l	option_mode,d0
	and.l	#OPTION_STATUS,d0
	beq	19f			;statusをテストしない。statusが一致
;statusをテストする
	move.l	(_asta,a6),d0		;actual status
	cmp.l	(_esta,a6),d0		;expected status
	bne	97f			;statusが一致しない。失敗
;statusが一致
19:
;------------------------------------------------
;result
	move.l	option_mode,d0
	and.l	#OPTION_DESTINATION,d0
	beq	39f			;resultをテストしない。resultが一致
;resultをテストする
	move.l	(_ares,a6),d0		;actual result 1st
	cmp.l	(_eres,a6),d0		;expected result 1st
	bne	97f			;resultが一致しない。失敗
	move.l	(4+_ares,a6),d0		;actual result 2nd
	cmp.l	(4+_eres,a6),d0		;expected result 2nd
	bne	97f			;resultが一致しない。失敗
	move.l	(8+_ares,a6),d0		;actual result 3rd
	cmp.l	(8+_eres,a6),d0		;expected result 3rd
	bne	97f			;resultが一致しない。失敗
;resultが一致
39:
;------------------------------------------------
;成功
98:
	moveq.l	#1,d0
99:
	unlk	a6
	rts

;失敗
97:
	moveq.l	#0,d0
	bra	99b
	.cpu	68000

;--------------------------------------------------------------------------------
;successful=test_extended()
;	extendedの結果を比較する。誤差を許容する
;<(4,sp).x:actual result
;<(16,sp).l:actual status
;<(20,sp).x:expected result
;<(32,sp).l:expected status
;<(36,sp).l:fpcr(rp<<6,-1=strict)
;>d0.l:0=failed,1=successful
	.cpu	68030
regs		reg	d1-d6
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp2
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
_ares:	.ds.x	1	;actual result
_asta:	.ds.l	1	;actual status
_eres:	.ds.x	1	;expected result
_esta:	.ds.l	1	;expected status
_fpcr:	.ds.l	1	;fpcr(rp<<6,-1=strict)
	.text
	.even
test_extended::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;----------------------------------------------------------------
;status
	move.l	option_mode,d0
	and.l	#OPTION_STATUS,d0
	beq	19f			;statusをテストしない。statusが一致
;statusをテストする
	move.l	(_asta,a6),d0		;actual status
	cmp.l	(_esta,a6),d0		;expected status
	bne	97f			;statusが一致しない。失敗
;statusが一致
19:
;----------------------------------------------------------------
;result
	move.l	option_mode,d0
	and.l	#OPTION_DESTINATION,d0
	beq	39f			;resultをテストしない。resultが一致
;resultをテストする
	fmove.l	#0,fpcr
;------------------------------------------------
;expected resultが正規化数または非正規化数か調べる
	move.l	(_eres,a6),d0		;expected result 1st
	and.l	#$7FFF0000,d0
	cmp.l	#$7FFF0000,d0
	beq	30f			;expected resultが±InfまたはNaN。完全に一致しなければならない
	or.l	(4+_eres,a6),d0		;expected result 2nd
	or.l	(8+_eres,a6),d0		;expected result 3rd
	beq	30f			;expected resultが±0。完全に一致しなければならない
;expected resultは正規化数または非正規化数
;------------------------------------------------
;1ulpを求める
	move.l	(_fpcr,a6),d0		;fpcr(rp<<6,-1=strict)
	cmp.l	#-1,d0
	beq	30f			;strict。完全に一致しなければならない
	move.l	#$00000000,d4		;extendedの1ulp
	move.l	#$00000001,d5
	lsr.b	#6,d0			;rounding precision
	beq	49f			;extended
;singleまたはdouble
	subq.b	#2,d0
	bcc	43f			;double
;--------------------------------
;single
	move.l	#$00000100,d4		;singleの1ulp
	move.l	#$00000000,d5
	movem.l	(_ares,a6),d1-d3	;actual result
	and.l	#$7FFF0000,d1
	cmp.l	#$7FFF0000,d1
	beq	49f			;actual resultが±InfまたはNaN
;actual resultが±0または非正規化数または正規化数
	move.l	d2,d0
	or.l	d3,d0
	beq	49f			;actual resultが±0
;actual resultが非正規化数または正規化数
;actual resultがsingleに丸められていることを確認する
	tst.l	d2
	bmi	42f			;actual resultが正規化数
;actual resultが非正規化数
41:
	add.l	d3,d3
	addx.l	d2,d2
	bpl	41b			;actual resultが非正規化数
;actual resultが正規化数
42:
	and.l	#$000000FF,d2
	or.l	d3,d2
	bne	97f			;actual resultがsingleに丸められていない。失敗
	bra	49f

;--------------------------------
;double
43:
	move.l	#$00000000,d4		;doubleの1ulp
	move.l	#$00000800,d5
	movem.l	(_ares,a6),d1-d3	;actual result
	and.l	#$7FFF0000,d1
	cmp.l	#$7FFF0000,d1
	beq	49f			;actual resultが±InfまたはNaN
;actual resultが±0または非正規化数または正規化数
	move.l	d2,d0
	or.l	d3,d0
	beq	49f			;actual resultが±0
;actual resultが非正規化数または正規化数
;actual resultがdoubleに丸められていることを確認する
	tst.l	d2
	bmi	45f			;actual resultが正規化数
;actual resultが非正規化数
44:
	add.l	d3,d3
	addx.l	d2,d2
	bpl	44b			;actual resultが非正規化数
;actual resultが正規化数
45:
	and.l	#$000007FF,d3
	bne	97f			;actual resultがdoubleに丸められていない。失敗
49:
;<d4-d5:1ulp
;------------------------------------------------
;マージンを求める
	move.l	option_mode,d0
	and.l	#OPTION_MARGIN_MASK,d0	;margin
	bne	1f
	moveq.l	#0,d4
	moveq.l	#0,d5
	bra	2f

1:
	subq.w	#1,d0
	lsl.l	d0,d4			;extended,single,doubleのいずれも下位ワードが1bit立っているだけなのでこれだけでよい
	lsl.l	d0,d5
2:
;<d4-d5:マージン
;------------------------------------------------
;許容範囲の絶対値の下限を求める
	movem.l	(_eres,a6),d1-d3	;expected result
	tst.l	d2
	bpl	22f			;非正規化数
;正規化数
	sub.l	d5,d3
	subx.l	d4,d2
	bmi	23f			;指数部が変わらない
	move.l	d1,d0
	and.l	#$7FFF0000,d0
	beq	23f			;指数部が0のときは正規化数が非正規化数になる
	sub.l	#$00010000,d1		;指数部を1減らす
	add.l	d3,d3			;仮数部を左にずらす
	addx.l	d2,d2
	bra	23f

;非正規化数
22:
	sub.l	d5,d3
	subx.l	d4,d2
	bpl	23f
	and.l	#$80000000,d1		;引けなかったとき許容範囲の絶対値の下限は0
	move.l	#$00000000,d2
	move.l	#$00000000,d3
23:
	movem.l	d1-d3,-(sp)
	fmove.x	(sp)+,fp1		;許容範囲の絶対値の下限
;<fp1.x:許容範囲の絶対値の下限
;------------------------------------------------
;許容範囲の絶対値の上限を求める
	movem.l	(_eres,a6),d1-d3	;expected result
	tst.l	d2
	bpl	25f			;非正規化数
;正規化数
	add.l	d5,d3
	addx.l	d4,d2
	bmi	26f			;指数部が変わらない
	move.l	d1,d0
	and.l	#$7FFF0000,d0
	cmp.l	#$7FFE0000,d0
	beq	24f			;指数部が$7FFEのときは±Infになる
	add.l	#$00010000,d1		;指数部を1増やす
	roxr.l	#1,d2			;仮数部を右にずらす
	roxr.l	#1,d3
	or.l	#$80000000,d2
	bra	26f

24:
	or.l	#$7FFF0000,d1
	moveq.l	#0,d2
	moveq.l	#0,d3
	bra	26f

;非正規化数
25:
	add.l	d5,d3			;仮数部にマージンを加える。非正規化数が正規化数になる場合がある
	addx.l	d4,d2
26:
	movem.l	d1-d3,-(sp)
	fmove.x	(sp)+,fp2		;許容範囲の絶対値の上限
;<fp2.x:許容範囲の絶対値の上限
;------------------------------------------------
;下限<=上限にする。マージンが0のときは下限==上限になる。下限と上限は範囲に含まれる
	fcmp.x	fp1,fp2
	fbge	27f
	fmove.x	fp2,fp0
	fmove.x	fp1,fp2
	fmove.x	fp0,fp1
27:
;<fp1.x:許容範囲の下限
;<fp2.x:許容範囲の上限
;------------------------------------------------
;比較する
	fmove.x	(_ares,a6),fp0		;actual result
	fcmp.x	fp1,fp0
	fbult	97f			;actual resultがNaNまたは小さすぎる。失敗
	fcmp.x	fp2,fp0
	fbugt	97f			;actual resultがNaNまたは大きすぎる。失敗
	bra	98f			;成功

;------------------------------------------------
;完全に一致しなければならない
30:
	movem.l	(_eres,a6),d1-d3	;expected result
	movem.l	(_ares,a6),d4-d6	;actual result
	move.l	#OPTION_NANS,d0
	and.l	option_mode,d0
	bne	35f			;NaNの仮数部を比較する
;NaNの仮数部を無視する
;------------------------------------------------
;expected resultがNaNのとき仮数をすべて1にする
	move.l	d1,d0
	and.l	#$7FFF0000,d0
	cmp.l	#$7FFF0000,d0
	bne	32f			;±InfまたはNaNではない
	tst.l	d2
	bne	31f			;NaN
	tst.l	d3
	beq	32f			;±Inf
;NaN
31:
	move.l	#$FFFFFFFF,d2		;NaNの仮数部をすべて1にする
	move.l	#$FFFFFFFF,d3
32:
;------------------------------------------------
;actual resultがNaNのとき仮数をすべて1にする
	move.l	d4,d0
	and.l	#$7FFF0000,d0
	cmp.l	#$7FFF0000,d0
	bne	34f			;±InfまたはNaNではない
	tst.l	d5
	bne	33f			;NaN
	tst.l	d6
	beq	34f			;±Inf
;NaN
33:
	move.l	#$FFFFFFFF,d5		;NaNの仮数部をすべて1にする
	move.l	#$FFFFFFFF,d6
34:
;------------------------------------------------
;比較する
35:
	cmp.l	d1,d4
	bne	97f			;resultが一致しない。失敗
	cmp.l	d2,d5
	bne	97f			;resultが一致しない。失敗
	cmp.l	d3,d6
	bne	97f			;resultが一致しない。失敗
;resultが一致
39:
;------------------------------------------------
;成功
98:
	moveq.l	#1,d0
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts

;失敗
97:
	moveq.l	#0,d0
	bra	99b
	.cpu	68000


;--------------------------------------------------------------------------------
;	結果を出力する
;--------------------------------------------------------------------------------

;--------------------------------------------------------------------------------
;output_status()
;	output status
;<(4,sp).l:actual status
;<(8,sp).l:expected status
;<(12,sp).l:0=failed,1=successful
	.cpu	68030
regs		reg	d3-d4/a3
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_a6:	.ds.l	1
_pc:	.ds.l	1
_asta:	.ds.l	1	;actual status
_esta:	.ds.l	1	;expected status
_succ:	.ds.l	1	;0=failed,1=successful
	.text
	.even
output_status::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	movea.l	(_esta,a6),a3		;expected status
	move.l	(_asta,a6),d3		;actual status
;successfulかどうかに関わらず完全に一致しているときだけexpectedを省略する
	moveq.l	#1,d4			;0=完全に一致してはいない,1=完全に一致している
	cmp.l	a3,d3
	beq	2f
	moveq.l	#0,d4			;0=完全に一致してはいない,1=完全に一致している
;expected
	putchr	#9
	move.l	a3,-(sp)
	jbsr	printfpsr
	addq.l	#4,sp
	putmsg	9,';expected',13,10
2:
;actual
	putchr	#9
	move.l	d3,-(sp)
	jbsr	printfpsr
	addq.l	#4,sp
	tst.l	d4
	beq	3f			;完全に一致してはいない
;完全に一致している
	putmsg	9,';'
	bra	4f

3:
;完全に一致してはいない
	putmsg	9,';actual ... '
4:
	tst.l	(_succ,a6)
	beq	5f			;failed
;successful
	putmsg	'OK',13,10
	bra	6f

5:
;failed
	putmsg	'ERROR',13,10
6:
;
99:
	movem.l	(_regs,a6),regs
	unlk	a6
	rts
	.cpu	68000

;--------------------------------------------------------------------------------
;output_single()
;	output result and status
;<(4,sp).s:actual result
;<(8,sp).l:actual status
;<(12,sp).s:expected result
;<(16,sp).l:expected status
;<(20,sp).l:0=failed,1=successful
	.cpu	68030
regs		reg	d0/d3-d4/a0/a3
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_a6:	.ds.l	1
_pc:	.ds.l	1
_ares:	.ds.s	1	;actual result
_asta:	.ds.l	1	;actual status
_eres:	.ds.s	1	;expected result
_esta:	.ds.l	1	;expected status
_succ:	.ds.l	1	;0=failed,1=successful
	.text
	.even
output_single::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	movea.l	(_eres,a6),a0		;expected result
	movea.l	(_esta,a6),a3		;expected status
	move.l	(_ares,a6),d0		;actual result
	move.l	(_asta,a6),d3		;actual status
;successfulかどうかに関わらず完全に一致しているときだけexpectedを省略する
	moveq.l	#1,d4			;0=完全に一致してはいない,1=完全に一致している
	cmp.l	a0,d0
	bne	1f
	cmp.l	a3,d3
	beq	2f
1:
	moveq.l	#0,d4			;0=完全に一致してはいない,1=完全に一致している
;expected
	putchr	#9
	puthex8	a0
	putchr	#','
	move.l	a3,-(sp)
	jbsr	printfpsr
	addq.l	#4,sp
	putmsg	9,';expected',13,10
2:
;actual
	putchr	#9
	puthex8	d0
	putchr	#','
	move.l	d3,-(sp)
	jbsr	printfpsr
	addq.l	#4,sp
	tst.l	d4
	beq	3f			;完全に一致してはいない
;完全に一致している
	putmsg	9,';'
	bra	4f

3:
;完全に一致してはいない
	putmsg	9,';actual ... '
4:
	tst.l	(_succ,a6)
	beq	5f			;failed
;successful
	putmsg	'OK',13,10
	bra	6f

5:
;failed
	putmsg	'ERROR',13,10
6:
;
99:
	movem.l	(_regs,a6),regs
	unlk	a6
	rts
	.cpu	68000

;--------------------------------------------------------------------------------
;output_double()
;	output result and status
;<(4,sp).d:actual result
;<(12,sp).l:actual status
;<(16,sp).d:expected result
;<(24,sp).l:expected status
;<(28,sp).l:0=failed,1=successful
	.cpu	68030
regs		reg	d0-d1/d3-d4/a0-a1/a3
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_a6:	.ds.l	1
_pc:	.ds.l	1
_ares:	.ds.d	1	;actual result
_asta:	.ds.l	1	;actual status
_eres:	.ds.d	1	;expected result
_esta:	.ds.l	1	;expected status
_succ:	.ds.l	1	;0=failed,1=successful
	.text
	.even
output_double::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	movem.l	(_eres,a6),a0-a1	;expected result
	movea.l	(_esta,a6),a3		;expected status
	movem.l	(_ares,a6),d0-d1	;actual result
	move.l	(_asta,a6),d3		;actual status
;successfulかどうかに関わらず完全に一致しているときだけexpectedを省略する
	moveq.l	#1,d4			;0=完全に一致してはいない,1=完全に一致している
	cmp.l	a0,d0
	bne	1f
	cmp.l	a1,d1
	bne	1f
	cmp.l	a3,d3
	beq	2f
1:
	moveq.l	#0,d4			;0=完全に一致してはいない,1=完全に一致している
;expected
	putchr	#9
	puthex16	a0,a1
	putchr	#','
	move.l	a3,-(sp)
	jbsr	printfpsr
	addq.l	#4,sp
	putmsg	9,';expected',13,10
2:
;actual
	putchr	#9
	puthex16	d0,d1
	putchr	#','
	move.l	d3,-(sp)
	jbsr	printfpsr
	addq.l	#4,sp
	tst.l	d4
	beq	3f			;完全に一致してはいない
;完全に一致している
	putmsg	9,';'
	bra	4f

3:
;完全に一致してはいない
	putmsg	9,';actual ... '
4:
	tst.l	(_succ,a6)
	beq	5f			;failed
;successful
	putmsg	'OK',13,10
	bra	6f

5:
;failed
	putmsg	'ERROR',13,10
6:
;
	movem.l	(_regs,a6),regs
	unlk	a6
	rts
	.cpu	68000

;--------------------------------------------------------------------------------
;output_packed()
;	output result and status
;<(4,sp).p:actual result
;<(16,sp).l:actual status
;<(20,sp).p:expected result
;<(32,sp).l:expected status
;<(36,sp).l:0=failed,1=successful
	.cpu	68030
regs		reg	d0-d4/a0-a3
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_a6:	.ds.l	1
_pc:	.ds.l	1
_ares:	.ds.p	1	;actual result
_asta:	.ds.l	1	;actual status
_eres:	.ds.p	1	;expected result
_esta:	.ds.l	1	;expected status
_succ:	.ds.l	1	;0=failed,1=successful
	.text
	.even
output_packed::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	movem.l	(_eres,a6),a0-a2	;expected result
	movea.l	(_esta,a6),a3		;expected status
	movem.l	(_ares,a6),d0-d2	;actual result
	move.l	(_asta,a6),d3		;actual status
;successfulかどうかに関わらず完全に一致しているときだけexpectedを省略する
	moveq.l	#1,d4			;0=完全に一致してはいない,1=完全に一致している
	cmp.l	a0,d0
	bne	1f
	cmp.l	a1,d1
	bne	1f
	cmp.l	a2,d2
	bne	1f
	cmp.l	a3,d3
	beq	2f
1:
	moveq.l	#0,d4			;0=完全に一致してはいない,1=完全に一致している
;expected
	putchr	#9
	puthex24	a0,a1,a2
	putchr	#','
	move.l	a3,-(sp)
	jbsr	printfpsr
	addq.l	#4,sp
	putmsg	9,';expected',13,10
2:
;actual
	putchr	#9
	puthex24	d0,d1,d2
	putchr	#','
	move.l	d3,-(sp)
	jbsr	printfpsr
	addq.l	#4,sp
	tst.l	d4
	beq	3f			;完全に一致してはいない
;完全に一致している
	putmsg	9,';'
	bra	4f

3:
;完全に一致してはいない
	putmsg	9,';actual ... '
4:
	tst.l	(_succ,a6)
	beq	5f			;failed
;successful
	putmsg	'OK',13,10
	bra	6f

5:
;failed
	putmsg	'ERROR',13,10
6:
;
	movem.l	(_regs,a6),regs
	unlk	a6
	rts
	.cpu	68000

;--------------------------------------------------------------------------------
;output_extended()
;	output result and status
;<(4,sp).x:actual result
;<(16,sp).l:actual status
;<(20,sp).x:expected result
;<(32,sp).l:expected status
;<(36,sp).l:0=failed,1=successful
	.cpu	68030
regs		reg	d0-d4/a0-a3
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_a6:	.ds.l	1
_pc:	.ds.l	1
_ares:	.ds.x	1	;actual result
_asta:	.ds.l	1	;actual status
_eres:	.ds.x	1	;expected result
_esta:	.ds.l	1	;expected status
_succ:	.ds.l	1	;0=failed,1=successful
	.text
	.even
output_extended::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	movem.l	(_eres,a6),a0-a2	;expected result
	movea.l	(_esta,a6),a3		;expected status
	movem.l	(_ares,a6),d0-d2	;actual result
	move.l	(_asta,a6),d3		;actual status
;successfulかどうかに関わらず完全に一致しているときだけexpectedを省略する
	moveq.l	#1,d4			;0=完全に一致してはいない,1=完全に一致している
	cmp.l	a0,d0
	bne	1f
	cmp.l	a1,d1
	bne	1f
	cmp.l	a2,d2
	bne	1f
	cmp.l	a3,d3
	beq	2f
1:
	moveq.l	#0,d4			;0=完全に一致してはいない,1=完全に一致している
;expected
	putchr	#9
	puthex24	a0,a1,a2
	putchr	#','
	move.l	a3,-(sp)
	jbsr	printfpsr
	addq.l	#4,sp
	putmsg	9,';expected',13,10
2:
;actual
	putchr	#9
	puthex24	d0,d1,d2
	putchr	#','
	move.l	d3,-(sp)
	jbsr	printfpsr
	addq.l	#4,sp
	tst.l	d4
	beq	3f			;完全に一致してはいない
;完全に一致している
	putmsg	9,';'
	bra	4f

3:
;完全に一致してはいない
	putmsg	9,';actual ... '
4:
	tst.l	(_succ,a6)
	beq	5f			;failed
;successful
	putmsg	'OK',13,10
	bra	6f

5:
;failed
	putmsg	'ERROR',13,10
6:
;
	movem.l	(_regs,a6),regs
	unlk	a6
	rts
	.cpu	68000


;--------------------------------------------------------------------------------
;	出力サブルーチン
;--------------------------------------------------------------------------------

;----------------------------------------------------------------
;printfpcrrprm(fpcr)
;<(4,sp).l:fpcr
	.text
	.even
printfpcrrprm::
	movem.l	d0/a0,-(sp)
	move.l	(4*2+4,sp),d0		;fpcr
	and.w	#$00F0,d0		;rp,rm
	lsr.w	#4-2,d0
	lea.l	(10f,pc,d0.w),a0
	putstr	a0
	movem.l	(sp)+,d0/a0
	rts

	.align	4
10:
	.dc.l	'XRN'<<8|0
	.dc.l	'XRZ'<<8|0
	.dc.l	'XRM'<<8|0
	.dc.l	'XRP'<<8|0
	.dc.l	'SRN'<<8|0
	.dc.l	'SRZ'<<8|0
	.dc.l	'SRM'<<8|0
	.dc.l	'SRP'<<8|0
	.dc.l	'DRN'<<8|0
	.dc.l	'DRZ'<<8|0
	.dc.l	'DRM'<<8|0
	.dc.l	'DRP'<<8|0
	.dc.l	'DRN'<<8|0
	.dc.l	'DRZ'<<8|0
	.dc.l	'DRM'<<8|0
	.dc.l	'DRP'<<8|0

;----------------------------------------------------------------
;printfpsr
;<4(sp).l:fpsr
	.text
	.even
printfpsr::
	movem.l	d0/a0,-(sp)
	move.l	(4*2+4,sp),d0		;fpsr
	lea.l	(-128,sp),sp
	movea.l	sp,a0
	jbsr	fpsrstr
	putstr	sp
	lea.l	(128,sp),sp
	movem.l	(sp)+,d0/a0
	rts

;----------------------------------------------------------------
;fpsrstr
;<d0.l:fpsr
;<a0.l:buffer
;>a0.l:buffer
	.text
	.even
fpsrstr::
	movem.l	d0-d5/a1,-(sp)
	move.l	d0,d5			;fpsr
	sf.b	d4
;condition code byte
	lea.l	(10f,pc),a1
	moveq.l	#27,d1
1:
	move.b	(a1)+,d2
	move.b	(a1)+,d3
	btst.l	d1,d5
	beq	2f
	move.b	d2,(a0)+
	move.b	d3,(a0)+
	move.b	#'+',(a0)+
	st.b	d4
2:
	subq.w	#1,d1
	cmp.w	#24,d1
	bhs	1b
;quotient byte
	btst.l	#23,d5
	beq	1f
	move.b	#'(',(a0)+
	move.b	#'1',(a0)+
	move.b	#'<',(a0)+
	move.b	#'<',(a0)+
	move.b	#'2',(a0)+
	move.b	#'3',(a0)+
	move.b	#')',(a0)+
	move.b	#'+',(a0)+
	st.b	d4
1:
	move.l	d5,d0
	and.l	#$007F0000,d0
	beq	2f
	swap.w	d0
	move.b	#'(',(a0)+
	jbsr	decstr
	move.b	#'<',(a0)+
	move.b	#'<',(a0)+
	move.b	#'1',(a0)+
	move.b	#'6',(a0)+
	move.b	#')',(a0)+
	move.b	#'+',(a0)+
	st.b	d4
2:
;exception byte, accrued exception byte
	lea.l	(11f,pc),a1
	moveq.l	#15,d1
1:
	move.b	(a1)+,d2
	move.b	(a1)+,d3
	btst.l	d1,d5
	beq	2f
	move.b	d2,(a0)+
	move.b	d3,(a0)+
	move.b	#'+',(a0)+
	st.b	d4
2:
	subq.w	#1,d1
	cmp.w	#3,d1
	bhs	1b
	tst.b	d4
	beq	3f
	clr.b	-(a0)			;remove unnecessary '+'
	bra	8f

3:
	move.b	#'0',(a0)+
	clr.b	(a0)
8:
	movem.l	(sp)+,d0-d5/a1
	rts

10:
;		 27   26   25   24
	.dc.b	'MI','ZE','IN','NA'
11:
;		 15   14   13   12   11   10    9    8    7    6    5    4    3
	.dc.b	'BS','SN','OE','OF','UF','DZ','X2','X1','AV','AO','AU','AZ','AX'

;----------------------------------------------------------------
;printdate
;	yyyy-mm-ddThh:mm:ss+09:00
	.text
	.even
printdate::
	move.l	a0,-(sp)
	lea.l	(-28,sp),sp
	movea.l	sp,a0
	jbsr	datestr
	putstr	sp
	lea.l	(28,sp),sp
	movea.l	(sp)+,a0
	rts

;----------------------------------------------------------------
;datestr
;	yyyy-mm-ddThh:mm:ss+09:00
	.text
	.even
datestr::
	movem.l	d0-d3,-(sp)
;get date and time
	DOS	_GETDATE
	move.l	d0,d2
;<d2.l:date((dayofweek(0=sunday)<<16)+((year-1980)<<9)+(month<<5)+dayofmonth)
	DOS	_GETTIM2
	move.l	d0,d3
;<d3.l:time((hour<<16)+(minute<<8)+second)
;year
					;........ .....www yyyyyyym mmmddddd
	rol.w	#7,d2			;........ .....www mmmmdddd dyyyyyyy
	moveq.l	#$7F,d0			;________ ________ ________ _1111111
	and.w	d2,d0			;________ ________ ________ _yyyyyyy
	add.w	#1980,d0
	move.l	#4,d1
	jbsr	deczstr
	move.b	#'-',(a0)+
;month
	rol.w	#4,d2			;........ .....www dddddyyy yyyymmmm
	moveq.l	#$0F,d0			;________ ________ ________ ____1111
	and.w	d2,d0			;________ ________ ________ ____mmmm
	move.l	#2,d1
	jbsr	deczstr
	move.b	#'-',(a0)+
;dayofmonth
	rol.w	#5,d2			;........ .....www yyyyyyym mmmddddd
	moveq.l	#$1F,d0			;________ ________ ________ ___11111
	and.w	d2,d0			;________ ________ ________ ___ddddd
;	move.l	#2,d1
	jbsr	deczstr
	move.b	#'T',(a0)+
;hour
					;........ ...hhhhh ..mmmmmm ..ssssss
	swap.w	d3			;..mmmmmm ..ssssss ........ ...hhhhh
	moveq.l	#$1F,d0			;________ ________ ________ ___11111
	and.w	d3,d0			;________ ________ ________ ___hhhhh
;	move.l	#2,d1
	jbsr	deczstr
	move.b	#':',(a0)+
;minute
	rol.l	#8,d3			;..ssssss ........ ...hhhhh ..mmmmmm
	moveq.l	#$3F,d0			;________ ________ ________ __111111
	and.w	d3,d0			;________ ________ ________ __mmmmmm
;	move.l	#2,d1
	jbsr	deczstr
	move.b	#':',(a0)+
;second
	rol.l	#8,d3			;........ ...hhhhh ..mmmmmm ..ssssss
	moveq.l	#$3F,d0			;________ ________ ________ __111111
	and.w	d3,d0			;________ ________ ________ __ssssss
;	move.l	#2,d1
	jbsr	deczstr
	move.b	#'+',(a0)+
	move.b	#'0',(a0)+
	move.b	#'9',(a0)+
	move.b	#':',(a0)+
	move.b	#'0',(a0)+
	move.b	#'0',(a0)+
	clr.b	(a0)
	movem.l	(sp)+,d0-d3
	rts

;----------------------------------------------------------------
;printlong(number)
;	%d
;<(4,sp).l:number
	.text
	.even
printlong::
	move.l	(4,sp),-(sp)
	bpl	@f
	putchr	#'-'
	neg.l	(sp)
@@:
	jbsr	printdec
	addq.l	#4,sp
	rts

;----------------------------------------------------------------
;printdec(number)
;	%u
;<(4,sp).l:number
	.text
	.even
printdec::
	movem.l	d0/a0,-(sp)
	move.l	(4*2+4,sp),d0		;number
	lea.l	(-12,sp),sp
	movea.l	sp,a0
	jbsr	decstr
	putstr	sp
	lea.l	(12,sp),sp
	movem.l	(sp)+,d0/a0
	rts

;----------------------------------------------------------------
;printdecs(number,digits)
;	%*u
;<(4,sp).l:number
;<(8,sp).l:digits
	.text
	.even
printdecs::
	movem.l	d0-d2/a0,-(sp)
	movem.l	(4*4+4,sp),d0-d1	;number,digits
	moveq.l	#4,d2
	add.l	d1,d2
	and.w	#-4,d2
	suba.l	d2,sp
	movea.l	sp,a0
	jbsr	decsstr
	putstr	sp
	adda.l	d2,sp
	movem.l	(sp)+,d0-d2
	rts

;----------------------------------------------------------------
;printdecz(number,digits)
;	%0*u
;<(4,sp).l:number
;<(8,sp).l:digits
	.text
	.even
printdecz::
	movem.l	d0-d2/a0,-(sp)
	movem.l	(4*4+4,sp),d0-d1	;number,digits
	moveq.l	#4,d2
	add.l	d1,d2
	and.w	#-4,d2
	suba.l	d2,sp
	movea.l	sp,a0
	jbsr	deczstr
	putstr	sp
	adda.l	d2,sp
	movem.l	(sp)+,d0-d2
	rts

;----------------------------------------------------------------
;decstr
;	%u
;<d0.l:number
;<a0.l:buffer
;>a0.l:buffer
	.text
	.even
decstr::
	movem.l	d0-d2/a1,-(sp)
	tst.l	d0
	bne	1f
	move.b	#'0',(a0)+
	bra	5f

1:
	lea.l	baseten,a1
2:
	move.l	(a1)+,d1
	cmp.l	d1,d0
	blo	2b
3:
	moveq.l	#'0'-1,d2
4:
	addq.b	#1,d2
	sub.l	d1,d0
	bhs	4b
	add.l	d1,d0
	move.b	d2,(a0)+
	move.l	(a1)+,d1
	bne	3b
5:
	clr.b	(a0)
	movem.l	(sp)+,d0-d2/a1
	rts

;----------------------------------------------------------------
;decsstr
;	%*u
;<d0.l:number
;<d1.l:digits
;<a0.l:buffer
;>a0.l:buffer
	.text
	.even
decsstr::
	movem.l	d0-d2/a1-a2,-(sp)
	lea.l	baseten+4*10,a1
	movea.l	a1,a2
;remove zero digits
	tst.l	d1
	bne	@f
	moveq.l	#1,d1
@@:
;remove 11 or more digits
	cmp.l	#11,d1
	blo	3f
	sub.l	#11,d1
	swap.w	d1
1:
	swap.w	d1
2:
	move.b	#' ',(a0)+
	dbra	d1,2b
	swap.w	d1
	dbra	d1,1b
	moveq.l	#10,d1
3:
	lsl.w	#2,d1
	suba.w	d1,a2			;specified start point
;calculate minimum digits
	tst.l	d0
	beq	2f
	lea.l	(-4*10,a1),a1
1:
	cmp.l	(a1)+,d0
	blo	1b
2:
	subq.l	#4,a1			;required start point
;fill
	cmpa.l	a1,a2
	bhs	2f
1:
	move.b	#' ',(a0)+
	addq.l	#4,a2
	cmpa.l	a1,a2
	blo	1b
2:
;print decimal number
	move.l	(a1)+,d1
1:
	moveq.l	#'0'-1,d2
2:
	addq.b	#1,d2
	sub.l	d1,d0
	bhs	2b
	add.l	d1,d0
	move.b	d2,(a0)+
	move.l	(a1)+,d1
	bne	1b
	move.b	d1,(a0)			;0
	movem.l	(sp)+,d0-d2/a1-a2
	rts

;----------------------------------------------------------------
;deczstr
;	%0*u
;<d0.l:number
;<d1.l:digits
;<a0.l:buffer
;>a0.l:buffer
	.text
	.even
deczstr::
	movem.l	d0-d2/a1-a2,-(sp)
	lea.l	baseten+4*10,a1
	movea.l	a1,a2
;remove zero digits
	tst.l	d1
	bne	@f
	moveq.l	#1,d1
@@:
;remove 11 or more digits
	cmp.l	#11,d1
	blo	3f
	sub.l	#11,d1
	swap.w	d1
1:
	swap.w	d1
2:
	move.b	#'0',(a0)+
	dbra	d1,2b
	swap.w	d1
	dbra	d1,1b
	moveq.l	#10,d1
3:
	lsl.w	#2,d1
	suba.w	d1,a2			;specified start point
;calculate minimum digits
	tst.l	d0
	beq	2f
	lea.l	(-4*10,a1),a1
1:
	cmp.l	(a1)+,d0
	blo	1b
2:
	subq.l	#4,a1			;required start point
;fill
	cmpa.l	a1,a2
	bhs	2f
1:
	move.b	#'0',(a0)+
	addq.l	#4,a2
	cmpa.l	a1,a2
	blo	1b
2:
;print decimal number
	move.l	(a1)+,d1
1:
	moveq.l	#'0'-1,d2
2:
	addq.b	#1,d2
	sub.l	d1,d0
	bhs	2b
	add.l	d1,d0
	move.b	d2,(a0)+
	move.l	(a1)+,d1
	bne	1b
	move.b	d1,(a0)			;0
	movem.l	(sp)+,d0-d2/a1-a2
	rts

;----------------------------------------------------------------
;printfix(number,digits)
;	print fixed point decimal number
;<4(sp).l:number. fixed point decimal number * 10^(number of digits after decimal point)
;<8(sp).b:digits. number of digits after decimal point
regs		reg	d0-d4/a0-a1
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_a6:	.ds.l	1
_pc:	.ds.l	1
_numb:	.ds.l	1
_digi:	.ds.w	1
	.text
	.even
printfix::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	moveq.l	#0,d3
	move.b	(_digi,a6),d3
;<d3.l:number of digits after decimal point
	move.l	d3,d4
	addq.w	#3,d4
	and.w	#-4,d4			;round up to multiples of four
	add.w	#12,d4			;12 bytes for integer part and decimal point
;<d4.l:buffer size
	suba.l	d4,sp
;<sp.l:buffer
	movea.l	sp,a0
	move.l	(_numb,a6),d0		;fixed point decimal number * 10^(number of digits after decimal point)
	bne	20f			;non-zero
;zero
	move.b	#'0',(a0)+
	move.w	d3,d2			;number of digits after decimal point
	beq	13f			;omit decimal point
	move.b	#'.',(a0)+
	bra	12f

11:
	move.b	#'0',(a0)+
12:
	dbra	d2,11b
13:
	bra	80f			;print

20:
;non-zero
;<d0.l:fixed point decimal number * 10^(number of digits after decimal point)
	lea.l	baseten,a1
;zero suppression
21:
	move.l	(a1)+,d1
	cmp.l	d1,d0
	blo	21b
;convert to decimal number
22:
	moveq.l	#'0'-1,d2
23:
	addq.b	#1,d2
	sub.l	d1,d0
	bcc	23b
	add.l	d1,d0
	move.b	d2,(a0)+
	move.l	(a1)+,d1
	bne	22b
;
	move.l	a0,d2
	sub.l	sp,d2
;<d2.l:actual number of digits
	cmp.w	d3,d2
	bls	40f
;actual number of digits > number of digits after decimal point
;integer part exists
;insert '.'
	move.w	d3,d2			;number of digits after decimal point
	beq	33f			;omit decimal point
	movea.l	a0,a1
	addq.l	#1,a0
	bra	32f

31:
	move.b	-(a1),1(a1)
32:
	dbra	d2,31b
	move.b	#'.',(a1)
33:
	bra	80f			;print

40:
;actual number of digits <= number of digits after decimal point
;no integer part exists
;insert '0.00...'
	move.w	d3,d0			;number of digits after decimal point
	sub.w	d2,d0			;number of zeros after decimal point
	movea.l	a0,a1
	lea.l	2(a0,d0.w),a0
	bra	42f

41:
	move.b	-(a1),2(a1,d0.w)
42:
	dbra	d2,41b
	movea.l	sp,a1
	move.b	#'0',(a1)+
	move.b	#'.',(a1)+
	bra	44f

43:
	move.b	#'0',(a1)+
44:
	dbra	d0,43b

;print
80:
	suba.l	sp,a0
	move.l	a0,-(sp)		;length
	pea.l	4(sp)			;buffer
	jbsr	logging_write
;	addq.l	#8,sp
;	adda.l	d4,sp
	movem.l	(_regs,a6),regs
	unlk	a6
	rts

;----------------------------------------------------------------
	.text
	.align	4
baseten::
	.dc.l	1000000000
	.dc.l	100000000
	.dc.l	10000000
	.dc.l	1000000
	.dc.l	100000
	.dc.l	10000
	.dc.l	1000
	.dc.l	100
	.dc.l	10
	.dc.l	1
	.dc.l	0

;----------------------------------------------------------------
;printhex2(number)
;	print hexadecimal number $XX
;<4(sp).b:number
	.text
	.even
printhex2::
	movem.l	d0-d2/a0,-(sp)
	move.b	4*4+4(sp),d0		;number
	subq.l	#4,sp			;buffer
	movea.l	sp,a0
	move.b	#'$',(a0)+
	moveq.l	#2-1,d2
2:
	rol.b	#4,d0
	moveq.l	#15,d1
	and.w	d0,d1
	move.b	10f(pc,d1.w),(a0)+
	dbra	d2,2b
	pea.l	1+2.w			;length
	pea.l	4(sp)			;buffer
	jbsr	logging_write
	lea.l	8+4(sp),sp
	movem.l	(sp)+,d0-d2/a0
	rts

10:
	.dc.b	'0123456789ABCDEF'

;----------------------------------------------------------------
;printhex4(number)
;	print hexadecimal number $XXXX
;<4(sp).w:number
	.text
	.even
printhex4::
	movem.l	d0-d2/a0,-(sp)
	move.w	4*4+4(sp),d0		;number
	subq.l	#6,sp			;buffer
	movea.l	sp,a0
	move.b	#'$',(a0)+
	moveq.l	#4-1,d2
2:
	rol.w	#4,d0
	moveq.l	#15,d1
	and.w	d0,d1
	move.b	10f(pc,d1.w),(a0)+
	dbra	d2,2b
	pea.l	1+4.w			;length
	pea.l	4(sp)			;buffer
	jbsr	logging_write
	lea.l	8+6(sp),sp
	movem.l	(sp)+,d0-d2/a0
	rts

10:
	.dc.b	'0123456789ABCDEF'

;----------------------------------------------------------------
;printhex8(number)
;	print hexadecimal number $XXXXXXXX
;<4(sp).l:number
	.text
	.even
printhex8::
	movem.l	d0-d2/a0,-(sp)
	move.l	4*4+4(sp),d0		;number
	lea.l	-10(sp),sp		;buffer
	movea.l	sp,a0
	move.b	#'$',(a0)+
	moveq.l	#8-1,d2
2:
	rol.l	#4,d0
	moveq.l	#15,d1
	and.w	d0,d1
	move.b	10f(pc,d1.w),(a0)+
	dbra	d2,2b
	pea.l	1+8.w			;length
	pea.l	4(sp)			;buffer
	jbsr	logging_write
	lea.l	8+10(sp),sp
	movem.l	(sp)+,d0-d2/a0
	rts

10:
	.dc.b	'0123456789ABCDEF'

;----------------------------------------------------------------
;printcrlf()
;	print CR and LF
	.text
	.even
printcrlf::
	move.l	d0,-(sp)
	pea.l	2.w			;length
	pea.l	10f(pc)			;buffer
	jbsr	logging_write
	addq.l	#8,sp
	move.l	(sp)+,d0
	rts

10:
	.dc.b	13,10

;----------------------------------------------------------------
;printchr(character)
;	print character
;<4(sp).b:character
	.text
	.even
printchr::
	move.l	d0,-(sp)
	pea.l	1.w			;length
	pea.l	4+4+4(sp)		;character
	jbsr	logging_write
	addq.l	#8,sp
	move.l	(sp)+,d0
	rts

;----------------------------------------------------------------
;printstr(string)
;	print string
;<4(sp).l:string
	.text
	.even
printstr::
	movem.l	d0/a0-a1,-(sp)
	movea.l	4*3+4(sp),a0		;string
	movea.l	a0,a1
@@:
	tst.b	(a1)+
	bne	@b
	subq.l	#1,a1
	suba.l	a0,a1			;length
	movem.l	a0-a1,-(sp)		;length, string
	jbsr	logging_write
	addq.l	#8,sp
	movem.l	(sp)+,d0/a0-a1
	rts


;--------------------------------------------------------------------------------
;	計算サブルーチン
;--------------------------------------------------------------------------------

;----------------------------------------------------------------
;mull
;	unsigned multiplication. long*long
;<d0.l:multiplicand
;<d1.l:multiplier
;>d0:d1.q:product
	.text
	.even
mull::
	cmp.l	#$0000FFFF,d0
	bhi	10f
	cmp.l	#$0000FFFF,d1
	bhi	10f
	mulu.w	d0,d1
	moveq.l	#0,d0
	rts

10:
	movem.l	d2-d4,-(sp)
					;    d0      d1      d2      d3      d4
					;   A   B   C   D   .   .   .   .   .   .
	move.l	d1,d2			;                   C   D
	move.l	d1,d3			;                           C   D
	swap.w	d2			;                   D   C
	move.l	d2,d4			;                                   D   C
	mulu.w	d0,d1			;            B*D
	mulu.w	d0,d4			;                                    B*C
	swap.w	d0			;   B   A
	mulu.w	d0,d3			;                            A*D
	mulu.w	d2,d0			;    A*C
					;  ACh ACl BDh BDl
	move.w	d1,d2			;                  --- BDl
	move.w	d0,d1			;      ---     ACl
	swap.w	d1			;          ACl BDh
	swap.w	d0			;  --- ACh
	add.l	d3,d1			;            +AD
	clr.w	d3
	addx.w	d3,d0
	add.l	d4,d1			;            +BC
	addx.w	d3,d0
	swap.w	d0			;  ACh ---
	swap.w	d1			;          BDh ACl
	move.w	d1,d0			;      ACl     ---
	move.w	d2,d1			;              BDl
	movem.l	(sp)+,d2-d4
	rts

;----------------------------------------------------------------
;divq
;	unsigned division. quad/quad
;<d0:d1.q:dividend
;<d2:d3.q:divisor
;>d0:d1.q:quotient
;>d2:d3.q:remainder
;>x:0
;>n:1=quotient is negative
;>z:1=quotient is zero
;>v:0
;>c:1=divide by zero. d0:d1 and d2:d3 are not changed. z=0,n=0
	.text
	.even
divq::
	tst.l	d2
	bne	20f			;$FFFFFFFF<divisor
;divisor<=$FFFFFFFF
	tst.l	d3
	beq	40f			;divisor==0
	tst.l	d0
	bne	50f			;$FFFFFFFF<dividend && divisor<=$FFFFFFFF
;dividend<=$FFFFFFFF && divisor<=$FFFFFFFF
	cmp.l	d3,d1
	bls	60f			;dividend<=divisor
;divisor<dividend
10:
	movem.l	d5-d6,-(sp)
	move.l	d3,d5
	moveq.l	#0,d3
	moveq.l	#31,d6
1:
	add.l	d1,d1
	addx.l	d3,d3
	cmp.l	d5,d3
	blo	2f
	addq.b	#1,d1
	sub.l	d5,d3
2:
	dbra	d6,1b
	subq.w	#1,d6			;$0000FFFF->$0000FFFE. x=0
	or.l	d0,d6			;n=*,z=0,v=0,c=0
	movem.l	(sp)+,d5-d6
	rts

;$FFFFFFFF<divisor
20:
	cmp.l	d2,d0
	bhi	30f			;divisor<dividend
	blo	70f			;dividend<divisor
	cmp.l	d3,d1
	bls	60f			;dividend<=divisor
;divisor<dividend
30:
	movem.l	d4-d6,-(sp)
	move.l	d2,d4
	move.l	d3,d5
	moveq.l	#0,d2
	move.l	d0,d3
	move.l	d1,d0
	moveq.l	#0,d1
	moveq.l	#31,d6
1:
	add.l	d1,d1
	addx.l	d0,d0
	addx.l	d3,d3
	addx.l	d2,d2
  .if 1
	cmp.l	d4,d2
	blo	3f
	bhi	2f
	cmp.l	d5,d3
	blo	3f
2:
	sub.l	d5,d3
	subx.l	d4,d2
	addq.b	#1,d1
3:
  .else
	addq.b	#1,d1
	sub.l	d5,d3
	subx.l	d4,d2
	bhs	2f
	subq.b	#1,d1
	add.l	d5,d3
	addx.l	d4,d2
2:
  .endif
	dbra	d6,1b
	subq.w	#1,d6			;$0000FFFF->$0000FFFE. x=0
	or.l	d0,d6			;n=*,z=0,v=0,c=0
	movem.l	(sp)+,d4-d6
	rts

;divisor==0
40:
	move.w	#%00001,ccr		;x=0,n=0,z=0,v=0,c=1
	rts

;$FFFFFFFF<dividend && divisor<=$FFFFFFFF
50:
	movem.l	d5-d6,-(sp)
	move.l	d3,d5
	moveq.l	#0,d3
	moveq.l	#63,d6
1:
	add.l	d1,d1
	addx.l	d0,d0
	addx.l	d3,d3
	cmp.l	d5,d3
	blo	2f
	addq.b	#1,d1
	sub.l	d5,d3
2:
	dbra	d6,1b
	subq.w	#1,d6			;$0000FFFF->$0000FFFE. x=0
	or.l	d0,d6			;n=*,z=0,v=0,c=0
	movem.l	(sp)+,d5-d6
	rts

;dividend<=divisor
60:
	beq	80f			;dividend==divisor
;dividend<divisor
70:
	move.l	d0,d2			;remainder=dividend
	move.l	d1,d3
	sub.l	d0,d0			;quotient=0. x=0
	moveq.l	#0,d1			;n=0,z=1,v=0,c=0
	rts

;dividend==divisor
80:
	moveq.l	#0,d2			;remainder=0
	moveq.l	#0,d3
	sub.l	d0,d0			;quotient=1. x=0
	moveq.l	#1,d1			;n=0,z=0,v=0,c=0
	rts

  .if 0
	movem.l	d4-d6,-(sp)
	move.l	d2,d4
	move.l	d3,d5
	moveq.l	#0,d2
	moveq.l	#0,d3
	moveq.l	#63,d6
1:
	add.l	d1,d1
	addx.l	d0,d0
	addx.l	d3,d3
	addx.l	d2,d2
	addq.b	#1,d1
	sub.l	d5,d3
	subx.l	d4,d2
	bcc	2f
	subq.b	#1,d1
	add.l	d5,d3
	addx.l	d4,d2
2:
	dbra	d6,1b
	movem.l	(sp)+,d4-d6
	rts
  .endif
");
  \\圧縮された間接データを展開するサブルーチンを出力する
  asm(ASM_DECOMPRESS);
  \\間接データの構築を開始する
  indirect_start();
  \\テストルーチンを出力する
  if(all||mapisdefined(mnemmap,"fabs"),make_fabs());
  if(all||mapisdefined(mnemmap,"facos"),make_facos());
  if(all||mapisdefined(mnemmap,"fadd"),make_fadd());
  if(all||mapisdefined(mnemmap,"fasin"),make_fasin());
  if(all||mapisdefined(mnemmap,"fatan"),make_fatan());
  if(all||mapisdefined(mnemmap,"fatanh"),make_fatanh());
  if(all||mapisdefined(mnemmap,"fbccl"),
     make_fbccl060();
     make_fbccl88x());
  if(all||mapisdefined(mnemmap,"fbccw"),
     make_fbccw060();
     make_fbccw88x());
  if(all||mapisdefined(mnemmap,"fcmp"),make_fcmp());
  if(all||mapisdefined(mnemmap,"fcos"),make_fcos());
  if(all||mapisdefined(mnemmap,"fcosh"),make_fcosh());
  if(all||mapisdefined(mnemmap,"fdabs"),make_fdabs());
  if(all||mapisdefined(mnemmap,"fdadd"),make_fdadd());
  if(all||mapisdefined(mnemmap,"fdbcc"),
     make_fdbcc060();
     make_fdbcc88x());
  if(all||mapisdefined(mnemmap,"fddiv"),make_fddiv());
  if(all||mapisdefined(mnemmap,"fdiv"),make_fdiv());
  if(all||mapisdefined(mnemmap,"fdmove"),make_fdmove());
  if(all||mapisdefined(mnemmap,"fdmul"),make_fdmul());
  if(all||mapisdefined(mnemmap,"fdneg"),make_fdneg());
  if(all||mapisdefined(mnemmap,"fdsqrt"),make_fdsqrt());
  if(all||mapisdefined(mnemmap,"fdsub"),make_fdsub());
  if(all||mapisdefined(mnemmap,"fetox"),make_fetox());
  if(all||mapisdefined(mnemmap,"fetoxm1"),make_fetoxm1());
  if(all||mapisdefined(mnemmap,"fgetexp"),make_fgetexp());
  if(all||mapisdefined(mnemmap,"fgetman"),make_fgetman());
  if(all||mapisdefined(mnemmap,"fint"),make_fint());
  if(all||mapisdefined(mnemmap,"fintrz"),make_fintrz());
  if(all||mapisdefined(mnemmap,"flog10"),make_flog10());
  if(all||mapisdefined(mnemmap,"flog2"),make_flog2());
  if(all||mapisdefined(mnemmap,"flogn"),make_flogn());
  if(all||mapisdefined(mnemmap,"flognp1"),make_flognp1());
  if(all||mapisdefined(mnemmap,"fmod"),make_fmod());
  if(all||mapisdefined(mnemmap,"fmoveb"),
     make_fmovebregto();
     make_fmovebtoreg());
  if(all||mapisdefined(mnemmap,"fmoved"),
     make_fmovedregto();
     make_fmovedtoreg());
  if(all||mapisdefined(mnemmap,"fmovel"),
     make_fmovelregto();
     make_fmoveltoreg());
  if(all||mapisdefined(mnemmap,"fmovep"),
     make_fmovepregto();
     make_fmoveptoreg());
  if(all||mapisdefined(mnemmap,"fmoves"),
     make_fmovesregto();
     make_fmovestoreg());
  if(all||mapisdefined(mnemmap,"fmovew"),
     make_fmovewregto();
     make_fmovewtoreg());
  if(all||mapisdefined(mnemmap,"fmovex"),
     make_fmovexregto();
     make_fmovextoreg());
  if(all||mapisdefined(mnemmap,"fmovecr"),
     make_fmovecr881();
     make_fmovecr882());
  \\if(all||mapisdefined(mnemmap,"fmoveml"),
  \\   make_fmovemlregto();
  \\   make_fmovemltoreg());
  \\if(all||mapisdefined(mnemmap,"fmovemx"),
  \\   make_fmovemxregto();
  \\   make_fmovemxtoreg());
  if(all||mapisdefined(mnemmap,"fmul"),make_fmul());
  if(all||mapisdefined(mnemmap,"fneg"),make_fneg());
  if(all||mapisdefined(mnemmap,"frem"),make_frem());
  \\if(all||mapisdefined(mnemmap,"frestore"),make_frestore());
  if(all||mapisdefined(mnemmap,"fsabs"),make_fsabs());
  if(all||mapisdefined(mnemmap,"fsadd"),make_fsadd());
  \\if(all||mapisdefined(mnemmap,"fsave"),make_fsave());
  if(all||mapisdefined(mnemmap,"fscale"),make_fscale());
  if(all||mapisdefined(mnemmap,"fscc"),
     make_fscc060();
     make_fscc88x());
  if(all||mapisdefined(mnemmap,"fsdiv"),make_fsdiv());
  if(all||mapisdefined(mnemmap,"fsgldiv"),
     make_fsgldiv060();
     make_fsgldiv88x());
  if(all||mapisdefined(mnemmap,"fsglmul"),
     make_fsglmul060();
     make_fsglmul88x());
  if(all||mapisdefined(mnemmap,"fsin"),make_fsin());
  if(all||mapisdefined(mnemmap,"fsincos"),make_fsincos());
  if(all||mapisdefined(mnemmap,"fsinh"),make_fsinh());
  if(all||mapisdefined(mnemmap,"fsmove"),make_fsmove());
  if(all||mapisdefined(mnemmap,"fsmul"),make_fsmul());
  if(all||mapisdefined(mnemmap,"fsneg"),make_fsneg());
  if(all||mapisdefined(mnemmap,"fsqrt"),make_fsqrt());
  if(all||mapisdefined(mnemmap,"fssqrt"),make_fssqrt());
  if(all||mapisdefined(mnemmap,"fssub"),make_fssub());
  if(all||mapisdefined(mnemmap,"fsub"),make_fsub());
  if(all||mapisdefined(mnemmap,"ftan"),make_ftan());
  if(all||mapisdefined(mnemmap,"ftanh"),make_ftanh());
  if(all||mapisdefined(mnemmap,"ftentox"),make_ftentox());
  if(all||mapisdefined(mnemmap,"ftrapcc"),
     make_ftrapcc060();
     make_ftrapcc88x());
  if(all||mapisdefined(mnemmap,"ftrapccl"),
     make_ftrapccl060();
     make_ftrapccl88x());
  if(all||mapisdefined(mnemmap,"ftrapccw"),
     make_ftrapccw060();
     make_ftrapccw88x());
  if(all||mapisdefined(mnemmap,"ftst"),make_ftst());
  if(all||mapisdefined(mnemmap,"ftwotox"),make_ftwotox());
  \\条件の文字列を出力する
  asm(
"
	.text
	.align	4
uppercase_cc::
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
	.dc.l	uppercase_cc_&cc
  .endm
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
uppercase_cc_&cc::
	.dc.b	'&cc',0
  .endm
");
  \\間接データの構築を終了する
  indirect_end();
  asm(
"
	.bss
	.align	4
push_decompressed::
	.ds.b	",push_max_length,"


;--------------------------------------------------------------------------------
;	end
;--------------------------------------------------------------------------------
	.end	main
");
  asm_close()
  }



\\----------------------------------------------------------------------------------------
\\  共通データ
\\----------------------------------------------------------------------------------------

\\  表現できる値に丸められ、重複する値は取り除かれる
DATA_SPECIAL=[Rei, Inf];
DATA_EXTENDED={[
  EXDDEMIN, exdnextup(EXDDEMIN),
  exdnextdown(EXDNOMIN/2), EXDNOMIN/2, exdnextup(EXDNOMIN/2),
  exdnextdown(EXDDEMAX), EXDDEMAX,
  EXDNOMIN, exdnextup(EXDNOMIN),
  exdnextdown(EXDNOMIN*2), EXDNOMIN*2, exdnextup(EXDNOMIN*2),
  exdnextdown(EXDNOMAX/2), EXDNOMAX/2, exdnextup(EXDNOMAX/2),
  exdnextdown(EXDNOMAX), EXDNOMAX,
  \\
  exdnextdown(DBLDEMIN), DBLDEMIN,
  DBLDEMAX, exdnextup(DBLDEMAX),
  exdnextdown(DBLNOMIN), DBLNOMIN,
  DBLNOMAX, exdnextup(DBLNOMAX),
  \\
  exdnextdown(SGLDEMIN), SGLDEMIN,
  SGLDEMAX, exdnextup(SGLDEMAX),
  exdnextdown(SGLNOMIN), SGLNOMIN,
  SGLNOMAX, exdnextup(SGLNOMAX)
  ]};
DATA_DOUBLE={[
  DBLDEMIN, dblnextup(DBLDEMIN),
  dblnextdown(DBLNOMIN/2), DBLNOMIN/2, dblnextup(DBLNOMIN/2),
  dblnextdown(DBLDEMAX), DBLDEMAX,
  DBLNOMIN, dblnextup(DBLNOMIN),
  dblnextdown(DBLNOMIN*2), DBLNOMIN*2, dblnextup(DBLNOMIN*2),
  dblnextdown(DBLNOMAX/2), DBLNOMAX/2, dblnextup(DBLNOMAX/2),
  dblnextdown(DBLNOMAX), DBLNOMAX,
  \\
  dblnextdown(SGLDEMIN), SGLDEMIN,
  SGLDEMAX, dblnextup(SGLDEMAX),
  dblnextdown(SGLNOMIN), SGLNOMIN,
  SGLNOMAX, dblnextup(SGLNOMAX)
  ]};
DATA_SINGLE={[
  SGLDEMIN, sglnextup(SGLDEMIN),
  sglnextdown(SGLNOMIN/2), SGLNOMIN/2, sglnextup(SGLNOMIN/2),
  sglnextdown(SGLDEMAX), SGLDEMAX,
  SGLNOMIN, sglnextup(SGLNOMIN),
  sglnextdown(SGLNOMIN*2), SGLNOMIN*2, sglnextup(SGLNOMIN*2),
  sglnextdown(SGLNOMAX/2), SGLNOMAX/2, sglnextup(SGLNOMAX/2),
  sglnextdown(SGLNOMAX), SGLNOMAX
  ]};
DATA_FLOAT={append(
  DATA_EXTENDED,
  DATA_DOUBLE,
  DATA_SINGLE
  )};
DATA_BYTE=vector(256,n,n-1);
DATA_WORD={
  vector(256,n,
         (bitand(n-1,0x80)<<(15-7))*0x01+  \\a  11111100_00000000
         (bitand(n-1,0x40)<<(14-6))*0x01+  \\b  54321098_76543210
         (bitand(n-1,0x20)<<( 9-5))*0x1F+  \\c  abcccccd_efffffgh
         (bitand(n-1,0x10)<<( 8-4))*0x01+  \\d           abcdefgh
         (bitand(n-1,0x08)<<( 7-3))*0x01+  \\e
         (bitand(n-1,0x04)<<( 2-2))*0x1F+  \\f
         (bitand(n-1,0x02)<<( 1-1))*0x01+  \\g
         (bitand(n-1,0x01)<<( 0-0))*0x01)  \\h
    };
DATA_LONG={
  vector(256,n,
         (bitand(n-1,0x80)<<(31-7))*0x01+  \\a  33222222_22221111_11111100_00000000
         (bitand(n-1,0x40)<<(30-6))*0x01+  \\b  10987654_32109876_54321098_76543210
         (bitand(n-1,0x20)<<(24-5))*0x3F+  \\c  abcccccc_dddddddd_eeeeeeee_ffffffgh
         (bitand(n-1,0x10)<<(16-4))*0xFF+  \\d                             abcdefgh
         (bitand(n-1,0x08)<<( 8-3))*0xFF+  \\e
         (bitand(n-1,0x04)<<( 2-2))*0x3F+  \\f
         (bitand(n-1,0x02)<<( 1-1))*0x01+  \\g
         (bitand(n-1,0x01)<<( 0-0))*0x01)  \\h
    };
DATA_PACKED={[
  2^56*10^27,  \\extendedとpackedの両方で正確に表現できる最大の整数
  exdnextdown(1), 1, exdnextup(1),
  exdnextdown(9), 9, exdnextup(9),
  exdnextdown(10), 10, exdnextup(10),
  exdnextdown(90), 90, exdnextup(90),
  exdnextdown(10^9), 10^9, exdnextup(10^9),
  exdnextdown(9*10^9), 9*10^9, exdnextup(9*10^9),
  exdnextdown(10^10), 10^10, exdnextup(10^10),
  exdnextdown(9*10^10), 9*10^10, exdnextup(9*10^10),
  exdnextdown(1e+90), exdnextup(1e+90),
  exdnextdown(9e+90), exdnextup(9e+90),
  exdnextdown(1e+100), exdnextup(1e+100),
  exdnextdown(9e+100), exdnextup(9e+100),
  exdnextdown(1e+900), exdnextup(1e+900),
  exdnextdown(9e+900), exdnextup(9e+900),
  exdnextdown(1e+1000), exdnextup(1e+1000),
  exdnextdown(1e+4932), exdnextup(1e+4932),
  exdnextdown(0.1), exdnextup(0.1),
  exdnextdown(0.9), exdnextup(0.9),
  exdnextdown(1e-9), exdnextup(1e-9),
  exdnextdown(9e-9), exdnextup(9e-9),
  exdnextdown(1e-10), exdnextup(1e-10),
  exdnextdown(9e-10), exdnextup(9e-10),
  exdnextdown(1e-90), exdnextup(1e-90),
  exdnextdown(9e-90), exdnextup(9e-90),
  exdnextdown(1e-100), exdnextup(1e-100),
  exdnextdown(9e-100), exdnextup(9e-100),
  exdnextdown(1e-900), exdnextup(1e-900),
  exdnextdown(9e-900), exdnextup(9e-900),
  exdnextdown(1e-1000), exdnextup(1e-1000),
  exdnextdown(1e-4932), exdnextup(1e-4932),
  exdnextdown(0.0999999999999999995), exdnextup(0.0999999999999999995),
  exdnextdown(0.9999999999999995), exdnextup(0.9999999999999995),
  exdnextdown(9.9999999999995), exdnextup(9.9999999999995),
  exdnextdown(99.9999999995), exdnextup(99.9999999995),
  exdnextdown(999.9999995), exdnextup(999.9999995),
  exdnextdown(9999.9995), exdnextup(9999.9995),
  exdnextdown(999995/10), 999995/10, exdnextup(999995/10),
  exdnextdown(999500), 999500, exdnextup(999500),
  exdnextdown(9.9999999995e+99), exdnextup(9.9999999995e+99),
  exdnextdown(9.9999999995e-99), exdnextup(9.9999999995e-99),
  exdnextdown(9.999999999995e-999), exdnextup(9.999999999995e-999),
  exdnextdown(9.999999999995e+999), exdnextup(9.999999999995e+999)
  ]};
DATA_BASIC={append(
  vector(120,n,exdnextdown(n/12)),vector(120,n,n/12),vector(120,n,exdnextup(n/12)),  \\0..10付近
  vector(129,n,2^(n-65)),  \\2^-64..2^64
  vector(30,n,exdnextdown(10^(n^(5/2)))),vector(30,n,10^(n^(5/2))),vector(30,n,exdnextup(10^(n^(5/2))))  \\大域
  )};
DATA_ZERO_PLUS=vector(30,n,10^-(n^(5/2)));  \\ε
DATA_ONE_MINUS=vector(19,n,1-(5/2)^(-5/2*n));  \\1-ε
DATA_ONE_PLUS=vector(19,n,1+(5/2)^(-5/2*n));  \\1+ε
DATA_TRIGONOMETRIC={append(
  vector(19,n,Pi/2-(5/2)^(-5/2*n)),  \\π/2-ε
  vector(19,n,Pi/2+(5/2)^(-5/2*n)),  \\π/2+ε
  vector(19,n,Pi-(5/2)^(-5/2*n)),  \\π-ε
  vector(19,n,Pi+(5/2)^(-5/2*n)),  \\π+ε
  vector(19,n,3/2*Pi-(5/2)^(-5/2*n)),  \\3/2*π-ε
  vector(19,n,3/2*Pi+(5/2)^(-5/2*n)),  \\3/2*π+ε
  vector(19,n,2*Pi-(5/2)^(-5/2*n)),  \\2*π-ε
  vector(19,n,2*Pi+(5/2)^(-5/2*n))  \\2*π+ε
  )};
DATA_ROUND={append(
  vector(9,n,exdnextdown(2^7+(n-5)/4)),vector(9,n,2^7+(n-5)/4),vector(9,n,exdnextup(2^7+(n-5)/4)),  \\2^7付近
  vector(9,n,exdnextdown(2^8+(n-5)/4)),vector(9,n,2^8+(n-5)/4),vector(9,n,exdnextup(2^8+(n-5)/4)),  \\2^8付近
  vector(9,n,exdnextdown(2^15+(n-5)/4)),vector(9,n,2^15+(n-5)/4),vector(9,n,exdnextup(2^15+(n-5)/4)),  \\2^15付近
  vector(9,n,exdnextdown(2^16+(n-5)/4)),vector(9,n,2^16+(n-5)/4),vector(9,n,exdnextup(2^16+(n-5)/4)),  \\2^16付近
  vector(9,n,exdnextdown(2^23+(n-5)/4)),vector(9,n,2^23+(n-5)/4),vector(9,n,exdnextup(2^23+(n-5)/4)),  \\2^23付近
  vector(9,n,exdnextdown(2^24+(n-5)/4)),vector(9,n,2^24+(n-5)/4),vector(9,n,exdnextup(2^24+(n-5)/4)),  \\2^24付近
  vector(9,n,exdnextdown(2^31+(n-5)/4)),vector(9,n,2^31+(n-5)/4),vector(9,n,exdnextup(2^31+(n-5)/4)),  \\2^31付近
  vector(9,n,exdnextdown(2^32+(n-5)/4)),vector(9,n,2^32+(n-5)/4),vector(9,n,exdnextup(2^32+(n-5)/4)),  \\2^32付近
  vector(9,n,exdnextdown(2^52+(n-5)/4)),vector(9,n,2^52+(n-5)/4),vector(9,n,exdnextup(2^52+(n-5)/4)),  \\2^52付近
  vector(9,n,exdnextdown(2^53+(n-5)/4)),vector(9,n,2^53+(n-5)/4),vector(9,n,exdnextup(2^53+(n-5)/4)),  \\2^53付近
  vector(9,n,exdnextdown(2^63+(n-5)/4)),vector(9,n,2^63+(n-5)/4),vector(9,n,exdnextup(2^63+(n-5)/4)),  \\2^63付近
  vector(9,n,exdnextdown(2^64+(n-5)/4)),vector(9,n,2^64+(n-5)/4),vector(9,n,exdnextup(2^64+(n-5)/4))  \\2^64付近
  )};
DATA_BINARY={append(
  vector(12,n,exdnextdown(n/6)), vector(12,n,n/6), vector(12,n,exdnextup(n/6)),  \\0..2付近
  vector(3,n,2^23-2+n),  \\2^23付近
  vector(3,n,2^24-2+n),  \\2^24付近
  vector(3,n,2^31-2+n),  \\2^31付近
  vector(3,n,2^32-2+n),  \\2^32付近
  vector(3,n,2^52-2+n),  \\2^52付近
  vector(3,n,2^53-2+n),  \\2^53付近
  vector(3,n,2^63-2+n),  \\2^63付近
  vector(3,n,2^64-2+n)  \\2^64付近
  )};



\\----------------------------------------------------------------------------------------
\\  原点を傾き1で通る関数で原点付近の入力と出力の大小関係に矛盾が生じていたら修正する
\\----------------------------------------------------------------------------------------
originLowerLower(y,x,rp,rm)={
  if((type(y)!="t_POL")&&(type(x)!="t_POL")&&(abs(x)<2^-16),
     if(x<0,
        if((rp!=SGL)&&(rp!=DBL)&&(x<y),y=x);
        if((rm==RM)&&(x<=y),y=nextdown(x,rp)),
        if((rp!=SGL)&&(rp!=DBL)&&(x<y),y=x);
        if(((rm==RZ)||(rm==RM))&&(x<=y),y=nextdown(x,rp))));
  y
  }
originLowerUpper(y,x,rp,rm)={
  if((type(y)!="t_POL")&&(type(x)!="t_POL")&&(abs(x)<2^-16),
     if(x<0,
        if((rp!=SGL)&&(rp!=DBL)&&(x<y),y=x);
        if((rm==RM)&&(x<=y),y=nextdown(x,rp)),
        if((rp!=SGL)&&(rp!=DBL)&&(y<x),y=x);
        if((rm==RP)&&(y<=x),y=nextup(x,rp))));
  y
  }
originUpperLower(y,x,rp,rm)={
  if((type(y)!="t_POL")&&(type(x)!="t_POL")&&(abs(x)<2^-16),
     if(x<0,
        if((rp!=SGL)&&(rp!=DBL)&&(y<x),y=x);
        if(((rm==RZ)||(rm==RP))&&(y<=x),y=nextup(x,rp)),
        if((rp!=SGL)&&(rp!=DBL)&&(x<y),y=x);
        if(((rm==RZ)||(rm==RM))&&(x<=y),y=nextdown(x,rp))));
  y
  }
originUpperUpper(y,x,rp,rm)={
  if((type(y)!="t_POL")&&(type(x)!="t_POL")&&(abs(x)<2^-16),
     if(x<0,
        if((rp!=SGL)&&(rp!=DBL)&&(y<x),y=x);
        if(((rm==RZ)||(rm==RP))&&(y<=x),y=nextup(x,rp)),
        if((rp!=SGL)&&(rp!=DBL)&&(y<x),y=x);
        if((rm==RP)&&(y<=x),y=nextup(x,rp))));
  y
  }

\\  非正規化数のときUFをセット、正規化数のときUFをクリアする
correctUnderflow(y,rp)={
  if(type(y)!="t_POL",
     if(abs(y)<if(rp==SGL,SGLNOMIN,
                  rp==DBL,DBLNOMIN,
                  EXDNOMIN),  \\非正規化数のとき
        fpsr=bitor(fpsr,UF),  \\UFをセット
        \\正規化数のとき
        fpsr=bitand(fpsr,bitneg(UF))));  \\UFをクリア
  y
  }



fputocpu(fpu)={
  if(bitand(fpu,MC68881+MC68882),"68030",
     bitand(fpu,MC68040+FPSP040),"68040",
     bitand(fpu,MC68060+FPSP060),"68060",
     error())
  }



\\----------------------------------------------------------------------------------------
\\  Fop.X FPn
\\----------------------------------------------------------------------------------------
make_fop1to0(name,fop,frp,fpu,a,func)={
  my(FOP,cpu,x,rp,rm,sr);
  FOP=strupr(fop);
  print("making ",name);
  cpu=fputocpu(fpu);
  a=vector(#a,n,exd(a[n],RN));
  a=uniq(sort(append(a,vector(#a,n,-a[n]),[NaN]),comparator),comparator);
  asm(
"
;--------------------------------------------------------------------------------
;	",FOP,".X FPn
;--------------------------------------------------------------------------------
	.cpu	",cpu,"
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
",name,"_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#",fpu,",-(sp)
	peamsg	'",FOP,".X FPN'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: ",FOP,".X FPn',13,10
;------------------------------------------------
;	d1	fpcr=(XRN..DRP)<<4
;	d3	0=failed,1=successful
;	d5	expected status
;	d7	actual status
;	a2	source handle,...
;	a4	expected status,...
;	fp2	source
;------------------------------------------------
	lea.l	push_decompressed,a0
;decompress data
	move.l	a0,-(sp)
	pea.l	",name,"_data_compressed
	jbsr	decompress
	addq.l	#8,sp
;relocate decompressed handle
	move.l	#indirect_decompressed,d0
	movea.l	a0,a2			;source handle,...
@@:
	add.l	d0,(a0)+		;source handle
	tst.l	(a0)
	bpl	@b
	addq.l	#4,a0			;-1
	movea.l	a0,a4			;expected status,...
;
22:
	move.l	#",XRN<<4,",d1		;fpcr=(XRN..DRP)<<4
11:
;FPn
	fmove.l	#0,fpcr
	fmove.x	([a2]),fp2		;source
	fmove.l	d1,fpcr			;fpcr
	fmove.l	#0,fpsr
					;source
	",fop,".x	fp2		;EXECUTE
					;actual result
	fmove.l	fpsr,d7			;actual status
	fmove.l	#0,fpcr
;
	move.l	(a4),d5			;expected status
;
	move.l	",if(frp==-2,"d1",frp==-1,"#-1",Str("#",frp<<6)),",-(sp)	;fpcr(rp<<6,-1=strict)
	move.l	d5,-(sp)		;expected status
	move.l	d7,-(sp)		;actual status
	jbsr	test_status
	lea.l	(12,sp),sp
	move.l	d0,d3			;0=failed,1=successful
;
	move.l	d3,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'",FOP,".X FPn='
	puthex24	([a2]),(4,[a2]),(8,[a2])	;source
	putmsg	' @'
	move.l	d1,-(sp)
	jbsr	printfpcrrprm
	addq.l	#4,sp
	putcrlf
	move.l	d3,-(sp)		;0=failed,1=successful
	move.l	d5,-(sp)		;expected status
	move.l	d7,-(sp)		;actual status
	jbsr	output_status
	lea.l	(12,sp),sp
@@:
;
	addq.l	#4,a4			;expected status,...
;
	add.w	#1<<4,d1		;rprm++
	cmp.w	#",DRP<<4,",d1		;fpcr=(XRN..DRP)<<4
	bls	11b
;
	addq.l	#4,a2			;source handle,...
	tst.l	(a2)			;source handle,...
	bpl	22b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts
	.cpu	68000

	.align	4
",name,"_data_compressed::
");
  push_start();
  for(i=1,#a,
      x=a[i];  \\ソース
      push_indirect(12,numtoexd(x,RN)));
  push(4,-1);
  for(i=1,#a,
      x=a[i];  \\ソース
      for(rprm=XRN,DRP,  \\(rp<<2)+rm。丸め桁数と丸めモード
          rp=bitand(rprm>>2,3);  \\丸め桁数
          rm=bitand(rprm,3);  \\丸めモード
          fpsr=0;
          func(x,rp,rm);
          fpsr_update_aer();
          sr=fpsr;
          push(4,sr)));
  push_end()
  }



\\----------------------------------------------------------------------------------------
\\  Fop.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fop1to1(name,fop,frp,fpu,a,func)={
  my(FOP,cpu,x,y,rp,rm,sr);
  FOP=strupr(fop);
  print("making ",name);
  cpu=fputocpu(fpu);
  a=vector(#a,n,exd(a[n],RN));
  a=uniq(sort(append(a,vector(#a,n,-a[n]),[NaN]),comparator),comparator);
  asm(
"
;--------------------------------------------------------------------------------
;	",FOP,".X FPm,FPn
;--------------------------------------------------------------------------------
	.cpu	",cpu,"
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
",name,"_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#",fpu,",-(sp)
	peamsg	'",FOP,".X FPM,FPN'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: ",FOP,".X FPm,FPn',13,10
;------------------------------------------------
;	d1	fpcr=(XRN..DRP)<<4
;	d3	0=failed,1=successful
;	d5	expected status
;	d7	actual status
;	a2	source handle,...
;	a4	expected result handle,expected status,...
;	fp2	source
;	fp5	expected result
;	fp7	actual result
;------------------------------------------------
	lea.l	push_decompressed,a0
;decompress data
	move.l	a0,-(sp)
	pea.l	",name,"_data_compressed
	jbsr	decompress
	addq.l	#8,sp
;relocate decompressed handle
	move.l	#indirect_decompressed,d0
@@:
	add.l	d0,(a0)+		;source handle
	tst.l	(a0)
	bpl	@b
	addq.l	#4,a0			;-1
@@:
	add.l	d0,(a0)+		;expected result handle
	addq.l	#4,a0			;expected status
	tst.l	(a0)
	bpl	@b
;	addq.l	#4,a0			;-1
;
	lea.l	push_decompressed,a2	;source handle,...
	lea.l	(4*",#a,"+4,a2),a4	;expected result handle,expected status,...
22:
	move.l	#",XRN<<4,",d1		;fpcr=(XRN..DRP)<<4
11:
;FPn,FPn
	fmove.l	#0,fpcr
	fmove.x	([a2]),fp2		;source
	fmove.x	fp2,fp7			;source
	fmove.l	d1,fpcr			;fpcr
	fmove.l	#0,fpsr
					;source
	",fop,".x	fp7,fp7		;EXECUTE
					;actual result
	fmove.l	fpsr,d7			;actual status
	fmove.l	#0,fpcr
;
	fmove.x	([a4]),fp5		;expected result
	move.l	(4,a4),d5		;expected status
;
	move.l	",if(frp==-2,"d1",frp==-1,"#-1",Str("#",frp<<6)),",-(sp)	;fpcr(rp<<6,-1=strict)
	move.l	d5,-(sp)		;expected status
	fmove.x	fp5,-(sp)		;expected result
	move.l	d7,-(sp)		;actual status
	fmove.x	fp7,-(sp)		;actual result
	jbsr	test_extended
	lea.l	36(sp),sp
	move.l	d0,d3			;0=failed,1=successful
;
	move.l	d3,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'",FOP,".X FPn='
	puthex24	([a2]),(4,[a2]),(8,[a2])	;source
	putmsg	',FPn @'
	move.l	d1,-(sp)
	jbsr	printfpcrrprm
	addq.l	#4,sp
	putcrlf
	move.l	d3,-(sp)		;0=failed,1=successful
	move.l	d5,-(sp)		;expected status
	fmove.x	fp5,-(sp)		;expected result
	move.l	d7,-(sp)		;actual status
	fmove.x	fp7,-(sp)		;actual result
	jbsr	output_extended
	lea.l	36(sp),sp
@@:
;
	addq.l	#8,a4			;expected result handle,expected status,...
;
	add.w	#1<<4,d1		;rprm++
	cmp.w	#",DRP<<4,",d1		;fpcr=(XRN..DRP)<<4
	bls	11b
;
	addq.l	#4,a2			;source handle,...
	tst.l	(a2)			;source handle,...
	bpl	22b
;
	lea.l	push_decompressed,a2	;source handle,...
	lea.l	(4*",#a,"+4,a2),a4	;expected result handle,expected status,...
22:
	move.l	#",XRN<<4,",d1		;fpcr=(XRN..DRP)<<4
11:
;FPm,FPn
	fmove.l	#0,fpcr
	fmove.x	([a2]),fp2		;source
	fmove.s	#$7FFFFFFF,fp7		;fill=NaN
	fmove.l	d1,fpcr			;fpcr
	fmove.l	#0,fpsr
					;source
	",fop,".x	fp2,fp7		;EXECUTE
					;actual result
	fmove.l	fpsr,d7			;actual status
	fmove.l	#0,fpcr
;
	fmove.x	([a4]),fp5		;expected result
	move.l	(4,a4),d5		;expected status
;
	move.l	",if(frp==-2,"d1",frp==-1,"#-1",Str("#",frp<<6)),",-(sp)	;fpcr(rp<<6,-1=strict)
	move.l	d5,-(sp)		;expected status
	fmove.x	fp5,-(sp)		;expected result
	move.l	d7,-(sp)		;actual status
	fmove.x	fp7,-(sp)		;actual result
	jbsr	test_extended
	lea.l	36(sp),sp
	move.l	d0,d3			;0=failed,1=successful
;
	move.l	d3,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'",FOP,".X FPm='
	puthex24	([a2]),(4,[a2]),(8,[a2])	;source
	putmsg	',FPn @'
	move.l	d1,-(sp)
	jbsr	printfpcrrprm
	addq.l	#4,sp
	putcrlf
	move.l	d3,-(sp)		;0=failed,1=successful
	move.l	d5,-(sp)		;expected status
	fmove.x	fp5,-(sp)		;expected result
	move.l	d7,-(sp)		;actual status
	fmove.x	fp7,-(sp)		;actual result
	jbsr	output_extended
	lea.l	36(sp),sp
@@:
;
	addq.l	#8,a4			;expected result handle,expected status,...
;
	add.w	#1<<4,d1		;rprm++
	cmp.w	#",DRP<<4,",d1		;fpcr=(XRN..DRP)<<4
	bls	11b
;
	addq.l	#4,a2			;source handle,...
	tst.l	(a2)			;source handle,...
	bpl	22b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts
	.cpu	68000

	.align	4
",name,"_data_compressed::
");
  push_start();
  for(i=1,#a,
      x=a[i];  \\ソース
      push_indirect(12,numtoexd(x,RN)));
  push(4,-1);
  for(i=1,#a,
      x=a[i];  \\ソース
      for(rprm=XRN,DRP,  \\(rp<<2)+rm。丸め桁数と丸めモード
          rp=bitand(rprm>>2,3);  \\丸め桁数
          rm=bitand(rprm,3);  \\丸めモード
          fpsr=0;
          y=func(x,rp,rm);
          fpsr_update_ccr(y);
          fpsr_update_aer();
          sr=fpsr;
          push_indirect(12,numtoexd(y,RN));
          push(4,sr)));
  push(4,-1);
  push_end()
  }



\\----------------------------------------------------------------------------------------
\\  Fop.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fop2to0(name,fop,frp,fpu,a,func)={
  my(FOP,cpu,x,y,rp,rm,sr);
  FOP=strupr(fop);
  print("making ",name);
  cpu=fputocpu(fpu);
  a=vector(#a,n,exd(a[n],RN));
  a=uniq(sort(append(a,vector(#a,n,-a[n]),[NaN]),comparator),comparator);
  asm(
"
;--------------------------------------------------------------------------------
;	",FOP,".X FPm,FPn
;--------------------------------------------------------------------------------
	.cpu	",cpu,"
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
",name,"_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#",fpu,",-(sp)
	peamsg	'",FOP,".X FPM,FPN'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: ",FOP,".X FPm,FPn',13,10
;------------------------------------------------
;	d1	fpcr=(XRN..XRP)<<4
;	d3	0=failed,1=successful
;	d5	expected status
;	d7	actual status
;	a2	source handle,...
;	a3	destination handle,...
;	a4	expected status,...
;	fp2	source
;------------------------------------------------
	lea.l	push_decompressed,a0
;decompress data
	move.l	a0,-(sp)
	pea.l	",name,"_data_compressed
	jbsr	decompress
	addq.l	#8,sp
;relocate decompressed handle
	move.l	#indirect_decompressed,d0
@@:
	add.l	d0,(a0)+		;destination handle
	tst.l	(a0)
	bpl	@b
	addq.l	#4,a0			;-1
	movea.l	a0,a4			;expected status,...
;
	lea.l	push_decompressed,a3	;destination handle,...
33:
	move.l	#",XRN<<4,",d1		;fpcr=(XRN..XRP)<<4
11:
;FPn,FPn
	fmove.l	#0,fpcr
	fmove.x	([a3]),fp3		;destination
	fmove.l	d1,fpcr			;fpcr
	fmove.l	#0,fpsr
					;source
	",fop,".x	fp3,fp3		;EXECUTE
					;actual result
	fmove.l	fpsr,d7			;actual status
	fmove.l	#0,fpcr
;
	move.l	(a4),d5			;expected status
;
	move.l	",if(frp==-2,"d1",frp==-1,"#-1",Str("#",frp<<6)),",-(sp)	;fpcr(rp<<6,-1=strict)
	move.l	d5,-(sp)		;expected status
	move.l	d7,-(sp)		;actual status
	jbsr	test_status
	lea.l	(12,sp),sp
	move.l	d0,d3			;0=failed,1=successful
;
	move.l	d3,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'",FOP,".X FPn='
	puthex24	([a3]),(4,[a3]),(8,[a3])	;source
	putmsg	',FPn='
	puthex24	([a3]),(4,[a3]),(8,[a3])	;destination
	putmsg	' @'
	move.l	d1,-(sp)
	jbsr	printfpcrrprm
	addq.l	#4,sp
	putcrlf
	move.l	d3,-(sp)		;0=failed,1=successful
	move.l	d5,-(sp)		;expected status
	move.l	d7,-(sp)		;actual status
	jbsr	output_status
	lea.l	(12,sp),sp
@@:
;
	addq.l	#4,a4			;expected status,...
;
	add.w	#1<<4,d1		;rprm++
	cmp.w	#",XRP<<4,",d1		;fpcr=(XRN..XRP)<<4
	bls	11b
;
	addq.l	#4,a3			;destination handle,...
	tst.l	(a3)			;destination handle,...
	bpl	33b
;
	lea.l	push_decompressed,a3	;destination handle,...
33:
	lea.l	push_decompressed,a2	;source handle,...
22:
	move.l	#",XRN<<4,",d1		;fpcr=(XRN..XRP)<<4
11:
;FPm,FPn
	fmove.l	#0,fpcr
	fmove.x	([a2]),fp2		;source
	fmove.x	([a3]),fp3		;destination
	fmove.l	d1,fpcr			;fpcr
	fmove.l	#0,fpsr
					;source
	",fop,".x	fp2,fp3		;EXECUTE
					;actual result
	fmove.l	fpsr,d7			;actual status
	fmove.l	#0,fpcr
;
	move.l	(a4),d5			;expected status
;
	move.l	",if(frp==-2,"d1",frp==-1,"#-1",Str("#",frp<<6)),",-(sp)	;fpcr(rp<<6,-1=strict)
	move.l	d5,-(sp)		;expected status
	move.l	d7,-(sp)		;actual status
	jbsr	test_status
	lea.l	(12,sp),sp
	move.l	d0,d3			;0=failed,1=successful
;
	move.l	d3,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'",FOP,".X FPm='
	puthex24	([a2]),(4,[a2]),(8,[a2])	;source
	putmsg	',FPn='
	puthex24	([a3]),(4,[a3]),(8,[a3])	;destination
	putmsg	' @'
	move.l	d1,-(sp)
	jbsr	printfpcrrprm
	addq.l	#4,sp
	putcrlf
	move.l	d3,-(sp)		;0=failed,1=successful
	move.l	d5,-(sp)		;expected status
	move.l	d7,-(sp)		;actual status
	jbsr	output_status
	lea.l	(12,sp),sp
@@:
;
	addq.l	#4,a4			;expected status,...
;
	add.w	#1<<4,d1		;rprm++
	cmp.w	#",XRP<<4,",d1		;fpcr=(XRN..XRP)<<4
	bls	11b
;
	addq.l	#4,a2			;source handle,...
	tst.l	(a2)			;source handle,...
	bpl	22b
;
	addq.l	#4,a3			;destination handle,...
	tst.l	(a3)			;destination handle,...
	bpl	33b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts
	.cpu	68000

	.align	4
",name,"_data_compressed::
");
  push_start();
  for(i=1,#a,
      x=a[i];  \\ソース,デスティネーション
      push_indirect(12,numtoexd(x,RN)));
  push(4,-1);
  for(i=1,#a,
      x=a[i];  \\ソース,デスティネーション
      for(rprm=XRN,XRP,  \\(rp<<2)+rm。丸め桁数と丸めモード。extendedのみ
          rp=bitand(rprm>>2,3);  \\丸め桁数
          rm=bitand(rprm,3);  \\丸めモード
          fpsr=0;
          func(x,x,rp,rm);
          fpsr_update_aer();
          sr=fpsr;
          push(4,sr)));
  for(i=1,#a,
      x=a[i];  \\デスティネーション
      for(j=1,#a,
          y=a[j];  \\ソース
          for(rprm=XRN,XRP,  \\(rp<<2)+rm。丸め桁数と丸めモード。extendedのみ
              rp=bitand(rprm>>2,3);  \\丸め桁数
              rm=bitand(rprm,3);  \\丸めモード
              fpsr=0;
              func(x,y,rp,rm);
              fpsr_update_aer();
              sr=fpsr;
              push(4,sr))));
  push_end()
  }



\\----------------------------------------------------------------------------------------
\\  Fop.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fop2to1(name,fop,frp,fpu,a,func)={
  my(FOP,cpu,x,y,z,rp,rm,sr);
  FOP=strupr(fop);
  print("making ",name);
  cpu=fputocpu(fpu);
  a=vector(#a,n,exd(a[n],RN));
  a=uniq(sort(append(a,vector(#a,n,-a[n]),[NaN]),comparator),comparator);
  asm(
"
;--------------------------------------------------------------------------------
;	",FOP,".X FPm,FPn
;--------------------------------------------------------------------------------
	.cpu	",cpu,"
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
",name,"_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#",fpu,",-(sp)
	peamsg	'",FOP,".X FPM,FPN'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: ",FOP,".X FPm,FPn',13,10
;------------------------------------------------
;	d1	fpcr=(XRN..XRP)<<4
;	d3	0=failed,1=successful
;	d5	expected status
;	d7	actual status
;	a2	source handle,...
;	a3	destination handle,...
;	a4	expected result handle,expected status,...
;	fp2	source
;	fp3	destination
;	fp5	expected result
;	fp7	actual result
;------------------------------------------------
	lea.l	push_decompressed,a0
;decompress data
	move.l	a0,-(sp)
	pea.l	",name,"_data_compressed
	jbsr	decompress
	addq.l	#8,sp
;relocate decompressed handle
	move.l	#indirect_decompressed,d0
@@:
	add.l	d0,(a0)+		;destination handle
	tst.l	(a0)
	bpl	@b
	addq.l	#4,a0			;-1
	movea.l	a0,a4			;expected result handle,expected status,...
@@:
	add.l	d0,(a0)+		;expected result handle
	addq.l	#4,a0			;expected status
	tst.l	(a0)
	bpl	@b
;	addq.l	#4,a0			;-1
;
	lea.l	push_decompressed,a3	;destination handle,...
33:
	move.l	#",XRN<<4,",d1		;fpcr=(XRN..XRP)<<4
11:
;FPn,FPn
	fmove.l	#0,fpcr
	fmove.x	([a3]),fp3		;destination
	fmove.x	fp3,fp7			;actual result=destination
	fmove.l	d1,fpcr			;fpcr
	fmove.l	#0,fpsr
					;source
	",fop,".x	fp7,fp7		;EXECUTE
					;actual result
	fmove.l	fpsr,d7			;actual status
	fmove.l	#0,fpcr
;
	fmove.x	([a4]),fp5		;expected result
	move.l	(4,a4),d5		;expected status
;
	move.l	",if(frp==-2,"d1",frp==-1,"#-1",Str("#",frp<<6)),",-(sp)	;fpcr(rp<<6,-1=strict)
	move.l	d5,-(sp)		;expected status
	fmove.x	fp5,-(sp)		;expected result
	move.l	d7,-(sp)		;actual status
	fmove.x	fp7,-(sp)		;actual result
	jbsr	test_extended
	lea.l	36(sp),sp
	move.l	d0,d3			;0=failed,1=successful
;
	move.l	d3,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'",FOP,".X FPn='
	puthex24	([a3]),(4,[a3]),(8,[a3])	;source
	putmsg	',FPn='
	puthex24	([a3]),(4,[a3]),(8,[a3])	;destination
	putmsg	' @'
	move.l	d1,-(sp)
	jbsr	printfpcrrprm
	addq.l	#4,sp
	putcrlf
	move.l	d3,-(sp)		;0=failed,1=successful
	move.l	d5,-(sp)		;expected status
	fmove.x	fp5,-(sp)		;expected result
	move.l	d7,-(sp)		;actual status
	fmove.x	fp7,-(sp)		;actual result
	jbsr	output_extended
	lea.l	36(sp),sp
@@:
;
	addq.l	#8,a4			;expected result handle,expected status,...
;
	add.w	#1<<4,d1		;rprm++
	cmp.w	#",XRP<<4,",d1		;fpcr=(XRN..XRP)<<4
	bls	11b
;
	addq.l	#4,a3			;destination handle,...
	tst.l	(a3)			;destination handle,...
	bpl	33b
;
	lea.l	push_decompressed,a3	;destination handle,...
33:
	lea.l	push_decompressed,a2	;source handle,...
22:
	move.l	#",XRN<<4,",d1		;fpcr=(XRN..XRP)<<4
11:
;FPm,FPn
	fmove.l	#0,fpcr
	fmove.x	([a2]),fp2		;source
	fmove.x	([a3]),fp3		;destination
	fmove.x	fp3,fp7			;actual result=destination
	fmove.l	d1,fpcr			;fpcr
	fmove.l	#0,fpsr
					;source
	",fop,".x	fp2,fp7		;EXECUTE
					;actual result
	fmove.l	fpsr,d7			;actual status
	fmove.l	#0,fpcr
;
	fmove.x	([a4]),fp5		;expected result
	move.l	(4,a4),d5		;expected status
;
	move.l	",if(frp==-2,"d1",frp==-1,"#-1",Str("#",frp<<6)),",-(sp)	;fpcr(rp<<6,-1=strict)
	move.l	d5,-(sp)		;expected status
	fmove.x	fp5,-(sp)		;expected result
	move.l	d7,-(sp)		;actual status
	fmove.x	fp7,-(sp)		;actual result
	jbsr	test_extended
	lea.l	36(sp),sp
	move.l	d0,d3			;0=failed,1=successful
;
	move.l	d3,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'",FOP,".X FPm='
	puthex24	([a2]),(4,[a2]),(8,[a2])	;source
	putmsg	',FPn='
	puthex24	([a3]),(4,[a3]),(8,[a3])	;destination
	putmsg	' @'
	move.l	d1,-(sp)
	jbsr	printfpcrrprm
	addq.l	#4,sp
	putcrlf
	move.l	d3,-(sp)		;0=failed,1=successful
	move.l	d5,-(sp)		;expected status
	fmove.x	fp5,-(sp)		;expected result
	move.l	d7,-(sp)		;actual status
	fmove.x	fp7,-(sp)		;actual result
	jbsr	output_extended
	lea.l	36(sp),sp
@@:
;
	addq.l	#8,a4			;expected result handle,expected status,...
;
	add.w	#1<<4,d1		;rprm++
	cmp.w	#",XRP<<4,",d1		;fpcr=(XRN..XRP)<<4
	bls	11b
;
	addq.l	#4,a2			;source handle,...
	tst.l	(a2)			;source handle,...
	bpl	22b
;
	addq.l	#4,a3			;destination handle,...
	tst.l	(a3)			;destination handle,...
	bpl	33b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts
	.cpu	68000

	.align	4
",name,"_data_compressed::
");
  push_start();
  for(i=1,#a,
      x=a[i];  \\ソース,デスティネーション
      push_indirect(12,numtoexd(x,RN)));
  push(4,-1);
  for(i=1,#a,
      x=a[i];  \\ソース,デスティネーション
      for(rprm=XRN,XRP,  \\(rp<<2)+rm。丸め桁数と丸めモード。extendedのみ
          rp=bitand(rprm>>2,3);  \\丸め桁数
          rm=bitand(rprm,3);  \\丸めモード
          fpsr=0;
          z=func(x,x,rp,rm);
          fpsr_update_ccr(z);
          fpsr_update_aer();
          sr=fpsr;
          push_indirect(12,numtoexd(z,RN));
          push(4,sr)));
  for(i=1,#a,
      x=a[i];  \\デスティネーション
      for(j=1,#a,
          y=a[j];  \\ソース
          for(rprm=XRN,XRP,  \\(rp<<2)+rm。丸め桁数と丸めモード。extendedのみ
              rp=bitand(rprm>>2,3);  \\丸め桁数
              rm=bitand(rprm,3);  \\丸めモード
              fpsr=0;
              z=func(x,y,rp,rm);
              fpsr_update_ccr(z);
              fpsr_update_aer();
              sr=fpsr;
              push_indirect(12,numtoexd(z,RN));
              push(4,sr))));
  push(4,-1);
  push_end()
  }



\\----------------------------------------------------------------------------------------
\\  Fop.X FPm,FPc:FPs
\\----------------------------------------------------------------------------------------
make_fop1to2(name,fop,frp,fpu,a,funcc,funcs)={
  my(FOP,cpu,x,ys,yc,rp,rm,sr);
  FOP=strupr(fop);
  print("making ",name);
  cpu=fputocpu(fpu);
  a=vector(#a,n,exd(a[n],RN));
  a=uniq(sort(append(a,vector(#a,n,-a[n]),[NaN]),comparator),comparator);
  asm(
"
;--------------------------------------------------------------------------------
;	",FOP,".X FPm,FPc:FPs
;--------------------------------------------------------------------------------
	.cpu	",cpu,"
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
",name,"_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#",fpu,",-(sp)
	peamsg	'",FOP,".X FPM,FPC:FPS'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: ",FOP,".X FPm,FPc:FPs',13,10
;------------------------------------------------
;	d1	fpcr=(XRN..DRP)<<4
;	d2	0=failed,1=successful upper
;	d3	0=failed,1=successful lower
;	d5	expected status
;	d7	actual status
;	a2	source handle,...
;	a4	expected result upper handle,expected status upper,expected result lower handle,expected status lower,...
;	fp2	source
;	fp4	expected result upper
;	fp5	expected result lower
;	fp6	actual result upper
;	fp7	actual result lower
;------------------------------------------------
	lea.l	push_decompressed,a0
;decompress data
	move.l	a0,-(sp)
	pea.l	",name,"_data_compressed
	jbsr	decompress
	addq.l	#8,sp
;relocate decompressed handle
	move.l	#indirect_decompressed,d0
@@:
	add.l	d0,(a0)+		;source handle
	tst.l	(a0)
	bpl	@b
	addq.l	#4,a0			;-1
@@:
	add.l	d0,(a0)+		;expected result upper handle
	addq.l	#4,a0			;expected status upper
	add.l	d0,(a0)+		;expected result lower handle
	addq.l	#4,a0			;expected status lower
	tst.l	(a0)
	bpl	@b
;	addq.l	#4,a0			;-1
;
	lea.l	push_decompressed,a2	;source handle,...
	lea.l	(4*",#a,"+4,a2),a4	;expected result upper handle,expected status upper,expected result lower handle,expected status lower,...
22:
	move.l	#",XRN<<4,",d1		;fpcr=(XRN..DRP)<<4
11:
;FPn,FPn:FPn
	fmove.l	#0,fpcr
	fmove.x	([a2]),fp2		;source
	fmove.x	fp2,fp7			;source
	fmove.l	d1,fpcr			;fpcr
	fmove.l	#0,fpsr
					;source
	",fop,".x	fp7,fp7:fp7	;EXECUTE
					;actual result upper
					;actual result lower
	fmove.l	fpsr,d7			;actual status
	fmove.l	#0,fpcr
;
	fmove.x	([8,a4]),fp5		;expected result lower
	move.l	(12,a4),d5		;expected status lower
;
	move.l	",if(frp==-2,"d1",frp==-1,"#-1",Str("#",frp<<6)),",-(sp)	;fpcr(rp<<6,-1=strict)
	move.l	d5,-(sp)		;expected status
	fmove.x	fp5,-(sp)		;expected result lower
	move.l	d7,-(sp)		;actual status
	fmove.x	fp7,-(sp)		;actual result lower
	jbsr	test_extended
	lea.l	36(sp),sp
	move.l	d0,d3			;0=failed,1=successful lower
;
	move.l	d3,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'",FOP,".X FPn='
	puthex24	([a2]),(4,[a2]),(8,[a2])	;source
	putmsg	',FPn:FPn @'
	move.l	d1,-(sp)
	jbsr	printfpcrrprm
	addq.l	#4,sp
	putcrlf
	move.l	d3,-(sp)		;0=failed,1=successful lower
	move.l	d5,-(sp)		;expected status
	fmove.x	fp5,-(sp)		;expected result lower
	move.l	d7,-(sp)		;actual status
	fmove.x	fp7,-(sp)		;actual result lower
	jbsr	output_extended
	lea.l	36(sp),sp
@@:
;
	lea.l	16(a4),a4		;expected result upper handle,expected status upper,expected result lower handle,expected status lower,...
;
	add.w	#1<<4,d1		;rprm++
	cmp.w	#",DRP<<4,",d1		;fpcr=(XRN..DRP)<<4
	bls	11b
;
	addq.l	#4,a2			;source handle,...
	tst.l	(a2)			;source handle,...
	bpl	22b
;
	lea.l	push_decompressed,a2	;source handle,...
	lea.l	(4*",#a,"+4,a2),a4	;expected result upper handle,expected status upper,expected result lower handle,expected status lower,...
22:
	move.l	#",XRN<<4,",d1		;fpcr=(XRN..DRP)<<4
11:
;FPm,FPc:FPs
	fmove.l	#0,fpcr
	fmove.x	([a2]),fp2		;source
	fmove.s	#$7FFFFFFF,fp6		;fill upper=NaN
	fmove.s	#$7FFFFFFF,fp7		;fill lower=NaN
	fmove.l	d1,fpcr			;fpcr
	fmove.l	#0,fpsr
					;source
	",fop,".x	fp2,fp6:fp7	;EXECUTE
					;actual result upper
					;actual result lower
	fmove.l	fpsr,d7			;actual status
	fmove.l	#0,fpcr
;
	fmove.x	([a4]),fp4		;expected result upper
	move.l	(4,a4),d4		;expected status upper
	fmove.x	([8,a4]),fp5		;expected result lower
	move.l	(12,a4),d5		;expected status lower
;
	move.l	",if(frp==-2,"d1",frp==-1,"#-1",Str("#",frp<<6)),",-(sp)	;fpcr(rp<<6,-1=strict)
	clr.l	-(sp)			;dummy status
	fmove.x	fp4,-(sp)		;expected result upper
	clr.l	-(sp)			;dummy status
	fmove.x	fp6,-(sp)		;actual result upper
	jbsr	test_extended
	lea.l	36(sp),sp
	move.l	d0,d2			;0=failed,1=successful upper
;
	move.l	",if(frp==-2,"d1",frp==-1,"#-1",Str("#",frp<<6)),",-(sp)	;fpcr(rp<<6,-1=strict)
	move.l	d5,-(sp)		;expected status
	fmove.x	fp5,-(sp)		;expected result lower
	move.l	d7,-(sp)		;actual status
	fmove.x	fp7,-(sp)		;actual result lower
	jbsr	test_extended
	lea.l	36(sp),sp
	move.l	d0,d3			;0=failed,1=successful lower
;
	move.l	d2,d0			;0=failed,1=successful upper
	and.l	d3,d0			;0=failed,1=successful lower
					;0=failed,1=successful
	move.l	d0,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'",FOP,".X FPm='
	puthex24	([a2]),(4,[a2]),(8,[a2])	;source
	putmsg	',FPc:FPs @'
	move.l	d1,-(sp)
	jbsr	printfpcrrprm
	addq.l	#4,sp
	putcrlf
	move.l	d2,-(sp)		;0=failed,1=successful upper
	clr.l	-(sp)			;dummy status
	fmove.x	fp4,-(sp)		;expected result upper
	clr.l	-(sp)			;dummy status
	fmove.x	fp6,-(sp)		;actual result upper
	jbsr	output_extended
	lea.l	36(sp),sp
	move.l	d3,-(sp)		;0=failed,1=successful lower
	move.l	d5,-(sp)		;expected status
	fmove.x	fp5,-(sp)		;expected result lower
	move.l	d7,-(sp)		;actual status
	fmove.x	fp7,-(sp)		;actual result lower
	jbsr	output_extended
	lea.l	36(sp),sp
@@:
;
	lea.l	16(a4),a4		;expected result upper handle,expected status upper,expected result lower handle,expected status lower,...
;
	add.w	#1<<4,d1		;rprm++
	cmp.w	#",DRP<<4,",d1		;fpcr=(XRN..DRP)<<4
	bls	11b
;
	addq.l	#4,a2			;source handle,...
	tst.l	(a2)			;source handle,...
	bpl	22b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts
	.cpu	68000

	.align	4
",name,"_data_compressed::
");
  push_start();
  for(i=1,#a,
      x=a[i];  \\ソース
      push_indirect(12,numtoexd(x,RN)));
  push(4,-1);
  for(i=1,#a,
      x=a[i];  \\ソース
      for(rprm=XRN,DRP,  \\(rp<<2)+rm。丸め桁数と丸めモード
          rp=bitand(rprm>>2,3);  \\丸め桁数
          rm=bitand(rprm,3);  \\丸めモード
          yc=funcc(x,rp,rm);  \\upper
          fpsr=0;
          ys=funcs(x,rp,rm);  \\lower
          fpsr_update_ccr(ys);
          fpsr_update_aer();
          sr=fpsr;
          push_indirect(12,numtoexd(yc,RN));  \\upper
          push(4,0);
          push_indirect(12,numtoexd(ys,RN));  \\lower
          push(4,sr)));
  push(4,-1);
  push_end()
  }



\\  frp
\\    -2  デフォルトで1ulpまでの誤差を許容するもの
\\        FACOS  FASIN  FATAN  FATANH  FCOS  FCOSH  FETOX  FETOXM1
\\        FLOG10  FLOG2  FLOGN  FLOGNP1
\\        FMOVE.P <mem>,FPn
\\        FSIN  FSINCOS  FSINH  FTAN  FTANH  FTENTOX  FTWOTOX
\\    -1  常にstrictになるもの
\\        FABS  FADD  FCMP  FDABS  FDADD  FDDIV  FDIV  FDMOVE  FDMUL  FDNEG  FDSQRT  FDSUB
\\        FGETEXP  FGETMAN  FINT  FINTRZ  FMOD
\\        FMOVE(FMOVE.P <mem>,FPn以外)
\\        FMOVECR  FMUL  FNEG  FREM
\\        FSABS  FSCALE  FSDIV  FSGLDIV  FSGLMUL  FSMOVE  FSMUL  FSNEG  FSQRT  FSSQRT  FSSUB  FSUB  FTST



\\----------------------------------------------------------------------------------------
\\  FABS.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fabs()={
  make_fop1to1("fabs",
               "fabs",
               -1,
               MC68881+MC68882+MC68040+FPSP040+MC68060+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,Inf,  \\abs(-Inf)=+Inf
                                x==-Rei,Rei,  \\abs(-0)=+0
                                x==Rei,Rei,  \\abs(+0)=+0
                                x==Inf,Inf,  \\abs(+Inf)=+Inf
                                NaN),
                             xxx(abs(x),rp,rm)))
  }


\\----------------------------------------------------------------------------------------
\\  FACOS.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_facos()={
  make_fop1to1("facos",
               "facos",
               -2,
               MC68881+MC68882+FPSP040+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND,
                      DATA_ZERO_PLUS,
                      DATA_ONE_MINUS),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,fpsr=bitor(fpsr,OE);NaN,  \\acos(-Inf)=NaN,OE
                                x==-Rei,fpsr=bitor(fpsr,X2);xxx(Pi/2,rp,rm),  \\acos(-0)=π/2,X2
                                x==Rei,fpsr=bitor(fpsr,X2);xxx(Pi/2,rp,rm),  \\acos(+0)=π/2,X2
                                x==Inf,fpsr=bitor(fpsr,OE);NaN,  \\acos(+Inf)=NaN,OE
                                NaN),
                             x<-1,fpsr=bitor(fpsr,OE);NaN,  \\acos(x<-1)=NaN,OE
                             x==-1,fpsr=bitor(fpsr,X2);xxx(Pi,rp,rm),  \\acos(-1)=π,X2
                             x==1,Rei,  \\acos(+1)=+0
                             1<x,fpsr=bitor(fpsr,OE);NaN,  \\acos(1<x)=NaN,OE
                             fpsr=bitor(fpsr,X2);
                             xxx(acos(x),rp,rm)))
  }


\\----------------------------------------------------------------------------------------
\\  FADD.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fadd()={
  my(z);
  make_fop2to1("fadd",
               "fadd",
               -1,
               MC68881+MC68882+MC68040+FPSP040+MC68060+FPSP060,
               append(DATA_SPECIAL,
                      DATA_EXTENDED,
                      DATA_BINARY),
               (x,y,rp,rm)->if((x==NaN)||(y==NaN),NaN,
                               (x==Inf)&&(y==-Inf),fpsr=bitor(fpsr,OE);NaN,  \\(+Inf)+(-Inf)=NaN,OE
                               (x==-Inf)&&(y==Inf),fpsr=bitor(fpsr,OE);NaN,  \\(-Inf)+(+Inf)=NaN,OE
                               (x==Rei)&&(y==Rei),Rei,  \\(+0)+(+0)=+0
                               (x==-Rei)&&(y==-Rei),-Rei,  \\(-0)+(-0)=-0
                               (x==Rei)&&(y==-Rei),if(rm==RM,-Rei,Rei),  \\(+0)+(-0)=±0
                               (x==-Rei)&&(y==Rei),if(rm==RM,-Rei,Rei),  \\(-0)+(+0)=±0
                               (y==Inf)||(y==-Inf),y,  \\(±x)+(±Inf)=±Inf
                               (x==Inf)||(x==-Inf),x,  \\(±Inf)+(±y)=±Inf
                               z=xxx(if((x==Rei)||(x==-Rei),0,x)+
                                     if((y==Rei)||(y==-Rei),0,y),rp,rm);  \\(±x)+(±0)=(±x),(±0)+(±y)=±y
                               if((z==Rei)||(z==-Rei),z=if(rm==RM,-Rei,Rei));
                               z))
  }


\\----------------------------------------------------------------------------------------
\\  FASIN.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fasin()={
  my(y);
  make_fop1to1("fasin",
               "fasin",
               -2,
               MC68881+MC68882+FPSP040+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND,
                      DATA_ZERO_PLUS,
                      DATA_ONE_MINUS),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,fpsr=bitor(fpsr,OE);NaN,  \\asin(-Inf)=NaN,OE
                                x==-Rei,-Rei,  \\asin(-0)=-0
                                x==Rei,Rei,  \\asin(+0)=+0
                                x==Inf,fpsr=bitor(fpsr,OE);NaN,  \\asin(+Inf)=NaN,OE
                                NaN),
                             x<-1,fpsr=bitor(fpsr,OE);NaN,  \\asin(x<-1)=NaN,OE
                             x==-1,fpsr=bitor(fpsr,X2);xxx(-Pi/2,rp,rm),  \\asin(-1)=-π/2,X2
                             x==1,fpsr=bitor(fpsr,X2);xxx(Pi/2,rp,rm),  \\asin(1)=π/2,X2
                             1<x,fpsr=bitor(fpsr,OE);NaN,  \\asin(1<x)=NaN,OE
                             fpsr=bitor(fpsr,X2);
                             y=roundxxx(asin(x),rp,rm);
                             y=originLowerUpper(y,x,rp,rm);
                             y=xxx(y,rp,rm);
                             correctUnderflow(y,rp)))
  }


\\----------------------------------------------------------------------------------------
\\  FATAN.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fatan()={
  my(y);
  make_fop1to1("fatan",
               "fatan",
               -2,
               MC68881+MC68882+FPSP040+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND,
                      DATA_ZERO_PLUS),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,fpsr=bitor(fpsr,X2);xxx(-Pi/2,rp,rm),  \\atan(-Inf)=-π/2,X2
                                x==-Rei,-Rei,  \\atan(-0)=-0
                                x==Rei,Rei,  \\atan(+0)=+0
                                x==Inf,fpsr=bitor(fpsr,X2);xxx(Pi/2,rp,rm),  \\atan(+Inf)=π/2,X2
                                NaN),
                             fpsr=bitor(fpsr,X2);
                             y=roundxxx(atan(x),rp,rm);
                             y=originUpperLower(y,x,rp,rm);
                             y=xxx(y,rp,rm);
                             correctUnderflow(y,rp)))
  }


\\----------------------------------------------------------------------------------------
\\  FATANH.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fatanh()={
  my(y);
  make_fop1to1("fatanh",
               "fatanh",
               -2,
               MC68881+MC68882+FPSP040+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND,
                      DATA_ZERO_PLUS,
                      DATA_ONE_MINUS),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,fpsr=bitor(fpsr,OE);NaN,  \\atanh(-Inf)=NaN,OE
                                x==-Rei,-Rei,  \\atanh(-0)=-0
                                x==Rei,Rei,  \\atanh(+0)=+0
                                x==Inf,fpsr=bitor(fpsr,OE);NaN,  \\atanh(+Inf)=NaN,OE
                                NaN),
                             x<-1,fpsr=bitor(fpsr,OE);NaN,  \\atanh(x<-1)=NaN,OE
                             x==-1,fpsr=bitor(fpsr,DZ);-Inf,  \\atanh(-1)=-Inf,DZ
                             x==1,fpsr=bitor(fpsr,DZ);Inf,  \\atanh(1)=+Inf,DZ
                             1<x,fpsr=bitor(fpsr,OE);NaN,  \\atanh(1<x)=NaN,OE
                             fpsr=bitor(fpsr,X2);
                             y=roundxxx(atanh(x),rp,rm);
                             y=originLowerUpper(y,x,rp,rm);
                             y=xxx(y,rp,rm);
                             correctUnderflow(y,rp)))
  }


\\----------------------------------------------------------------------------------------
\\  FBcc.L <label>
\\----------------------------------------------------------------------------------------
make_fbccl060()={
  my(m,z,n,a);
  print("making fbccl060");
  asm(
"
;--------------------------------------------------------------------------------
;	FBcc.L <label>
;--------------------------------------------------------------------------------
	.cpu	68030
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
fbccl060_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#MC68060+FPSP060,-(sp)
	peamsg	'FBCC.L <LABEL>'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: FBcc.L <label>',13,10
;------------------------------------------------
;	d1	actual result
;	d4	actual status
;	d5	cc=0..31
;	d6	fpsr=(mzin=0..15)<<24
;	d7	0=failed,1=successful
;	a0	expected result,expected status,...
;	a1	expected result
;	a4	expected status
;------------------------------------------------
	lea.l	push_decompressed,a0	;expected result,expected status,...
;decompress data
	move.l	a0,-(sp)
	pea.l	fbccl060_expected_compressed
	jbsr	decompress
	addq.l	#8,sp
	move.l	#0<<24,d6		;fpsr=(mzin=0..15)<<24
66:
	moveq.l	#0,d5			;cc=0..31
55:
;FBcc.L <forward-label>
	fmove.l	#0,fpcr
	fmove.l	d6,fpsr			;fpsr
	jsr	([fbccl060_execute_forward,za0,d5.l*4])	;EXECUTE
					;actual result
	fmove.l	fpsr,d4			;actual status
;
	movea.l	(a0),a1			;expected result
	movea.l	(4,a0),a4		;expected status
;
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	test_single
	lea.l	16(sp),sp
	move.l	d0,d7			;0=failed,1=successful
;
	move.l	d7,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FB'
	putstr	(uppercase_cc,za0,d5.l*4)
	putmsg	'.L <forward-label> @'
	move.l	d6,-(sp)		;fpsr
	jbsr	printfpsr
	addq.l	#4,sp
	putcrlf
	move.l	d7,-(sp)		;0=failed,1=successful
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	output_single
	lea.l	20(sp),sp
@@:
;
;FBcc.L <backward-label>
	fmove.l	#0,fpcr
	fmove.l	d6,fpsr			;fpsr
	jsr	([fbccl060_execute_backward,za0,d5.l*4])	;EXECUTE
					;actual result
	fmove.l	fpsr,d4			;actual status
;
	movea.l	(a0),a1			;expected result
	movea.l	(4,a0),a4		;expected status
;
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	test_single
	lea.l	16(sp),sp
	move.l	d0,d7			;0=failed,1=successful
;
	move.l	d7,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FB'
	putstr	(uppercase_cc,za0,d5.l*4)
	putmsg	'.L <backward-label> @'
	move.l	d6,-(sp)		;fpsr
	jbsr	printfpsr
	addq.l	#4,sp
	putcrlf
	move.l	d7,-(sp)		;0=failed,1=successful
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	output_single
	lea.l	20(sp),sp
@@:
;
	addq.l	#8,a0			;expected result
;
	addq.w	#1,d5			;cc++
	cmp.w	#31,d5			;cc=0..31
	bls	55b
;
	add.l	#1<<24,d6		;mzin++
	cmp.l	#15<<24,d6		;fpsr=(mzin=0..15)<<24
	bls	66b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts

	.align	4
fbccl060_execute_forward::
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
	.dc.l	fbccl060_execute_forward_&cc
  .endm
fbccl060_execute_backward::
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
	.dc.l	fbccl060_execute_backward_&cc
  .endm
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
fbccl060_execute_forward_&cc::
	moveq.l	#2,d1			;actual result. 2=too long
	FB&cc.L	@f			;EXECUTE
	moveq.l	#0,d1			;actual result. 0=not taken
	rts

	subq.l	#2,d1			;actual result. -1=too short(forward)/too long(backward)
@@:
	subq.l	#1,d1			;actual result. 1=taken
	rts

fbccl060_execute_backward_&cc::
	moveq.l	#2,d1			;actual result. 2=too short
	FB&cc.L	@b			;EXECUTE
	moveq.l	#0,d1			;actual result. 0=not taken
	rts
  .endm
	.cpu	68000

	.align	4
fbccl060_expected_compressed::
");
  push_start();
  for(mzin=0,15,
      m=bitand(mzin>>3,1);
      z=bitand(mzin>>2,1);
      n=bitand(mzin>>0,1);
      a=[
        0,           \\000000  F
        z,           \\000001  EQ
        !(n||z||m),  \\000010  OGT
        z||!(n||m),  \\000011  OGE
        m&&!(n||z),  \\000100  OLT
        z||(m&&!n),  \\000101  OLE
        !(n||z),     \\000110  OGL
        !n,          \\000111  OR
        n,           \\001000  UN
        n||z,        \\001001  UEQ
        n||!(m||z),  \\001010  UGT
        n||(z||!m),  \\001011  UGE
        n||(m&&!z),  \\001100  ULT
        n||z||m,     \\001101  ULE
        !z,          \\001110  NE
        1            \\001111  T
        ];
      for(cc=0,15,
          push(4,a[1+cc]);
          push(4,mzin<<24));
      for(cc=16,31,
          push(4,a[1+cc-16]);
          push(4,(mzin<<24)+if(n,BS+AV,0))));
  push_end()
  }
make_fbccl88x()={
  my(m,z,n,a);
  print("making fbccl88x");
  asm(
"
;--------------------------------------------------------------------------------
;	FBcc.L <label>
;--------------------------------------------------------------------------------
	.cpu	68030
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
fbccl88x_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#MC68881+MC68882+MC68040+FPSP040,-(sp)
	peamsg	'FBCC.L <LABEL>'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: FBcc.L <label>',13,10
;------------------------------------------------
;	d1	actual result
;	d4	actual status
;	d5	cc=0..31
;	d6	fpsr=(mzin=0..15)<<24
;	d7	0=failed,1=successful
;	a0	expected result,expected status,...
;	a1	expected result
;	a4	expected status
;------------------------------------------------
	lea.l	push_decompressed,a0	;expected result,expected status,...
;decompress data
	move.l	a0,-(sp)
	pea.l	fbccl88x_expected_compressed
	jbsr	decompress
	addq.l	#8,sp
	move.l	#0<<24,d6		;fpsr=(mzin=0..15)<<24
66:
	moveq.l	#0,d5			;cc=0..31
55:
;FBcc.L <forward-label>
	fmove.l	#0,fpcr
	fmove.l	d6,fpsr			;fpsr
	jsr	([fbccl88x_execute_forward,za0,d5.l*4])	;EXECUTE
					;actual result
	fmove.l	fpsr,d4			;actual status
;
	movea.l	(a0),a1			;expected result
	movea.l	(4,a0),a4		;expected status
;
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	test_single
	lea.l	16(sp),sp
	move.l	d0,d7			;0=failed,1=successful
;
	move.l	d7,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FB'
	putstr	(uppercase_cc,za0,d5.l*4)
	putmsg	'.L <forward-label> @'
	move.l	d6,-(sp)		;fpsr
	jbsr	printfpsr
	addq.l	#4,sp
	putcrlf
	move.l	d7,-(sp)		;0=failed,1=successful
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	output_single
	lea.l	20(sp),sp
@@:
;
;FBcc.L <backward-label>
	fmove.l	#0,fpcr
	fmove.l	d6,fpsr			;fpsr
	jsr	([fbccl88x_execute_backward,za0,d5.l*4])	;EXECUTE
					;actual result
	fmove.l	fpsr,d4			;actual status
;
	movea.l	(a0),a1			;expected result
	movea.l	(4,a0),a4		;expected status
;
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	test_single
	lea.l	16(sp),sp
	move.l	d0,d7			;0=failed,1=successful
;
	move.l	d7,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FB'
	putstr	(uppercase_cc,za0,d5.l*4)
	putmsg	'.L <backward-label> @'
	move.l	d6,-(sp)		;fpsr
	jbsr	printfpsr
	addq.l	#4,sp
	putcrlf
	move.l	d7,-(sp)		;0=failed,1=successful
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	output_single
	lea.l	20(sp),sp
@@:
;
	addq.l	#8,a0			;expected result
;
	addq.w	#1,d5			;cc++
	cmp.w	#31,d5			;cc=0..31
	bls	55b
;
	add.l	#1<<24,d6		;mzin++
	cmp.l	#15<<24,d6		;fpsr=(mzin=0..15)<<24
	bls	66b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts

	.align	4
fbccl88x_execute_forward::
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
	.dc.l	fbccl88x_execute_forward_&cc
  .endm
fbccl88x_execute_backward::
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
	.dc.l	fbccl88x_execute_backward_&cc
  .endm
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
fbccl88x_execute_forward_&cc::
	moveq.l	#2,d1			;actual result. 2=too long
	FB&cc.L	@f			;EXECUTE
	moveq.l	#0,d1			;actual result. 0=not taken
	rts

	subq.l	#2,d1			;actual result. -1=too short(forward)/too long(backward)
@@:
	subq.l	#1,d1			;actual result. 1=taken
	rts

fbccl88x_execute_backward_&cc::
	moveq.l	#2,d1			;actual result. 2=too short
	FB&cc.L	@b			;EXECUTE
	moveq.l	#0,d1			;actual result. 0=not taken
	rts
  .endm
	.cpu	68000

	.align	4
fbccl88x_expected_compressed::
");
  push_start();
  for(mzin=0,15,
      m=bitand(mzin>>3,1);
      z=bitand(mzin>>2,1);
      n=bitand(mzin>>0,1);
      a=[
        0,           \\000000  F
        z,           \\000001  EQ
        !(n||z||m),  \\000010  OGT
        z||!(n||m),  \\000011  OGE
        m&&!(n||z),  \\000100  OLT
        z||(m&&!n),  \\000101  OLE
        !(n||z),     \\000110  OGL
        z||!n,       \\000111  OR
        n,           \\001000  UN
        n||z,        \\001001  UEQ
        n||!(m||z),  \\001010  UGT
        n||(z||!m),  \\001011  UGE
        n||(m&&!z),  \\001100  ULT
        n||z||m,     \\001101  ULE
        n||!z,       \\001110  NE
        1            \\001111  T
        ];
      for(cc=0,15,
          push(4,a[1+cc]);
          push(4,mzin<<24));
      for(cc=16,31,
          push(4,a[1+cc-16]);
          push(4,(mzin<<24)+if(n,BS+AV,0))));
  push_end()
  }


\\----------------------------------------------------------------------------------------
\\  FBcc.W <label>
\\----------------------------------------------------------------------------------------
make_fbccw060()={
  my(m,z,n,a);
  print("making fbccw060");
  asm(
"
;--------------------------------------------------------------------------------
;	FBcc.W <label>
;--------------------------------------------------------------------------------
	.cpu	68030
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
fbccw060_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#MC68060+FPSP060,-(sp)
	peamsg	'FBCC.W <LABEL>'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: FBcc.W <label>',13,10
;------------------------------------------------
;	d1	actual result
;	d4	actual status
;	d5	cc=0..31
;	d6	fpsr=(mzin=0..15)<<24
;	d7	0=failed,1=successful
;	a0	expected result,expected status,...
;	a1	expected result
;	a4	expected status
;------------------------------------------------
	lea.l	push_decompressed,a0	;expected result,expected status,...
;decompress data
	move.l	a0,-(sp)
	pea.l	fbccw060_expected_compressed
	jbsr	decompress
	addq.l	#8,sp
	move.l	#0<<24,d6		;fpsr=(mzin=0..15)<<24
66:
	moveq.l	#0,d5			;cc=0..31
55:
;FBcc.W <forward-label>
	fmove.l	#0,fpcr
	fmove.l	d6,fpsr			;fpsr
	jsr	([fbccw060_execute_forward,za0,d5.l*4])	;EXECUTE
					;actual result
	fmove.l	fpsr,d4			;actual status
;
	movea.l	(a0),a1			;expected result
	movea.l	(4,a0),a4		;expected status
;
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	test_single
	lea.l	16(sp),sp
	move.l	d0,d7			;0=failed,1=successful
;
	move.l	d7,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FB'
	putstr	(uppercase_cc,za0,d5.l*4)
	putmsg	'.W <forward-label> @'
	move.l	d6,-(sp)		;fpsr
	jbsr	printfpsr
	addq.l	#4,sp
	putcrlf
	move.l	d7,-(sp)		;0=failed,1=successful
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	output_single
	lea.l	20(sp),sp
@@:
;
;FBcc.W <backward-label>
	fmove.l	#0,fpcr
	fmove.l	d6,fpsr			;fpsr
	jsr	([fbccw060_execute_backward,za0,d5.l*4])	;EXECUTE
					;actual result
	fmove.l	fpsr,d4			;actual status
;
	movea.l	(a0),a1			;expected result
	movea.l	(4,a0),a4		;expected status
;
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	test_single
	lea.l	16(sp),sp
	move.l	d0,d7			;0=failed,1=successful
;
	move.l	d7,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FB'
	putstr	(uppercase_cc,za0,d5.l*4)
	putmsg	'.W <backward-label> @'
	move.l	d6,-(sp)		;fpsr
	jbsr	printfpsr
	addq.l	#4,sp
	putcrlf
	move.l	d7,-(sp)		;0=failed,1=successful
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	output_single
	lea.l	20(sp),sp
@@:
;
	addq.l	#8,a0			;expected result
;
	addq.w	#1,d5			;cc++
	cmp.w	#31,d5			;cc=0..31
	bls	55b
;
	add.l	#1<<24,d6		;mzin++
	cmp.l	#15<<24,d6		;fpsr=(mzin=0..15)<<24
	bls	66b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts

	.align	4
fbccw060_execute_forward::
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
	.dc.l	fbccw060_execute_forward_&cc
  .endm
fbccw060_execute_backward::
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
	.dc.l	fbccw060_execute_backward_&cc
  .endm
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
fbccw060_execute_forward_&cc::
	moveq.l	#2,d1			;actual result. 2=too long
	FB&cc.W	@f			;EXECUTE
	moveq.l	#0,d1			;actual result. 0=not taken
	rts

	subq.l	#2,d1			;actual result. -1=too short(forward)/too long(backward)
@@:
	subq.l	#1,d1			;actual result. 1=taken
	rts

fbccw060_execute_backward_&cc::
	moveq.l	#2,d1			;actual result. 2=too short
	FB&cc.W	@b			;EXECUTE
	moveq.l	#0,d1			;actual result. 0=not taken
	rts
  .endm
	.cpu	68000

	.align	4
fbccw060_expected_compressed::
");
  push_start();
  for(mzin=0,15,
      m=bitand(mzin>>3,1);
      z=bitand(mzin>>2,1);
      n=bitand(mzin>>0,1);
      a=[
        0,           \\000000  F
        z,           \\000001  EQ
        !(n||z||m),  \\000010  OGT
        z||!(n||m),  \\000011  OGE
        m&&!(n||z),  \\000100  OLT
        z||(m&&!n),  \\000101  OLE
        !(n||z),     \\000110  OGL
        !n,          \\000111  OR
        n,           \\001000  UN
        n||z,        \\001001  UEQ
        n||!(m||z),  \\001010  UGT
        n||(z||!m),  \\001011  UGE
        n||(m&&!z),  \\001100  ULT
        n||z||m,     \\001101  ULE
        !z,          \\001110  NE
        1            \\001111  T
        ];
      for(cc=0,15,
          push(4,a[1+cc]);
          push(4,mzin<<24));
      for(cc=16,31,
          push(4,a[1+cc-16]);
          push(4,(mzin<<24)+if(n,BS+AV,0))));
  push_end()
  }
make_fbccw88x()={
  my(m,z,n,a);
  print("making fbccw88x");
  asm(
"
;--------------------------------------------------------------------------------
;	FBcc.W <label>
;--------------------------------------------------------------------------------
	.cpu	68030
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
fbccw88x_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#MC68881+MC68882+MC68040+FPSP040,-(sp)
	peamsg	'FBCC.W <LABEL>'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: FBcc.W <label>',13,10
;------------------------------------------------
;	d1	actual result
;	d4	actual status
;	d5	cc=0..31
;	d6	fpsr=(mzin=0..15)<<24
;	d7	0=failed,1=successful
;	a0	expected result,expected status,...
;	a1	expected result
;	a4	expected status
;------------------------------------------------
	lea.l	push_decompressed,a0	;expected result,expected status,...
;decompress data
	move.l	a0,-(sp)
	pea.l	fbccw88x_expected_compressed
	jbsr	decompress
	addq.l	#8,sp
	move.l	#0<<24,d6		;fpsr=(mzin=0..15)<<24
66:
	moveq.l	#0,d5			;cc=0..31
55:
;FBcc.W <forward-label>
	fmove.l	#0,fpcr
	fmove.l	d6,fpsr			;fpsr
	jsr	([fbccw88x_execute_forward,za0,d5.l*4])	;EXECUTE
					;actual result
	fmove.l	fpsr,d4			;actual status
;
	movea.l	(a0),a1			;expected result
	movea.l	(4,a0),a4		;expected status
;
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	test_single
	lea.l	16(sp),sp
	move.l	d0,d7			;0=failed,1=successful
;
	move.l	d7,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FB'
	putstr	(uppercase_cc,za0,d5.l*4)
	putmsg	'.W <forward-label> @'
	move.l	d6,-(sp)		;fpsr
	jbsr	printfpsr
	addq.l	#4,sp
	putcrlf
	move.l	d7,-(sp)		;0=failed,1=successful
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	output_single
	lea.l	20(sp),sp
@@:
;
;FBcc.W <backward-label>
	fmove.l	#0,fpcr
	fmove.l	d6,fpsr			;fpsr
	jsr	([fbccw88x_execute_backward,za0,d5.l*4])	;EXECUTE
					;actual result
	fmove.l	fpsr,d4			;actual status
;
	movea.l	(a0),a1			;expected result
	movea.l	(4,a0),a4		;expected status
;
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	test_single
	lea.l	16(sp),sp
	move.l	d0,d7			;0=failed,1=successful
;
	move.l	d7,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FB'
	putstr	(uppercase_cc,za0,d5.l*4)
	putmsg	'.W <backward-label> @'
	move.l	d6,-(sp)		;fpsr
	jbsr	printfpsr
	addq.l	#4,sp
	putcrlf
	move.l	d7,-(sp)		;0=failed,1=successful
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	output_single
	lea.l	20(sp),sp
@@:
;
	addq.l	#8,a0			;expected result
;
	addq.w	#1,d5			;cc++
	cmp.w	#31,d5			;cc=0..31
	bls	55b
;
	add.l	#1<<24,d6		;mzin++
	cmp.l	#15<<24,d6		;fpsr=(mzin=0..15)<<24
	bls	66b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts

	.align	4
fbccw88x_execute_forward::
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
	.dc.l	fbccw88x_execute_forward_&cc
  .endm
fbccw88x_execute_backward::
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
	.dc.l	fbccw88x_execute_backward_&cc
  .endm
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
fbccw88x_execute_forward_&cc::
	moveq.l	#2,d1			;actual result. 2=too long
	FB&cc.W	@f			;EXECUTE
	moveq.l	#0,d1			;actual result. 0=not taken
	rts

	subq.l	#2,d1			;actual result. -1=too short(forward)/too long(backward)
@@:
	subq.l	#1,d1			;actual result. 1=taken
	rts

fbccw88x_execute_backward_&cc::
	moveq.l	#2,d1			;actual result. 2=too short
	FB&cc.W	@b			;EXECUTE
	moveq.l	#0,d1			;actual result. 0=not taken
	rts
  .endm
	.cpu	68000

	.align	4
fbccw88x_expected_compressed::
");
  push_start();
  for(mzin=0,15,
      m=bitand(mzin>>3,1);
      z=bitand(mzin>>2,1);
      n=bitand(mzin>>0,1);
      a=[
        0,           \\000000  F
        z,           \\000001  EQ
        !(n||z||m),  \\000010  OGT
        z||!(n||m),  \\000011  OGE
        m&&!(n||z),  \\000100  OLT
        z||(m&&!n),  \\000101  OLE
        !(n||z),     \\000110  OGL
        z||!n,       \\000111  OR
        n,           \\001000  UN
        n||z,        \\001001  UEQ
        n||!(m||z),  \\001010  UGT
        n||(z||!m),  \\001011  UGE
        n||(m&&!z),  \\001100  ULT
        n||z||m,     \\001101  ULE
        n||!z,       \\001110  NE
        1            \\001111  T
        ];
      for(cc=0,15,
          push(4,a[1+cc]);
          push(4,mzin<<24));
      for(cc=16,31,
          push(4,a[1+cc-16]);
          push(4,(mzin<<24)+if(n,BS+AV,0))));
  push_end()
  }


\\----------------------------------------------------------------------------------------
\\  FCMP.X FPm,FPn
\\----------------------------------------------------------------------------------------
fcmp_func(x,y,rp,rm)={
  fpsr=bitor(fpsr,if((x==NaN)||(y==NaN),NA,  \\どちらかがNaN
                     x==y,if((x==-Rei)||(x==-Inf),MI+ZE,
                             (x==Rei)||(x==Inf),ZE,
                             x<0,MI+ZE,
                             ZE),  \\-0==-0,+0==+0,-Inf==-Inf,+Inf==+Inf,±x==±y
                     (x==-Rei)&&(y==Rei),MI+ZE,  \\-0==+0
                     (x==Rei)&&(y==-Rei),ZE,  \\+0==-0
                     (x==-Inf)||(y==Inf),MI,  \\-Inf<±y,±x<Inf
                     (x==Inf)||(y==-Inf),0,  \\+Inf>±y,±x>-Inf
                     if((x==Rei)||(x==-Rei),0,x)<if((y==Rei)||(y==-Rei),0,y),MI,  \\±x<±y
                     0))  \\±x>±y
  }
make_fcmp()={
  make_fop2to0("fcmp",
               "fcmp",
               -1,
               MC68881+MC68882+MC68040+FPSP040+MC68060+FPSP060,
               append(DATA_SPECIAL,
                      DATA_EXTENDED,
                      DATA_BINARY),
               fcmp_func)
  }


\\----------------------------------------------------------------------------------------
\\  FCOS.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fcos()={
  my(y);
  make_fop1to1("fcos",
               "fcos",
               -2,
               MC68881+MC68882+FPSP040+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND,
                      DATA_ZERO_PLUS,
                      DATA_TRIGONOMETRIC),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,fpsr=bitor(fpsr,OE);NaN,  \\cos(-Inf)=NaN,OE
                                x==-Rei,1,  \\cos(-0)=1
                                x==Rei,1,  \\cos(+0)=1
                                x==Inf,fpsr=bitor(fpsr,OE);NaN,  \\cos(+Inf)=NaN,OE
                                NaN),
                             fpsr=bitor(fpsr,X2);
                             y=roundxxx(cos(x),rp,rm);
                             if(type(y)!="t_POL",
                                if(y==1,if((rm==RZ)||(rm==RM),y=nextdown(1,rp)));
                                if(y==-1,if((rm==RZ)||(rm==RP),y=nextup(1,rp))));
                             xxx(y,rp,rm)))
  }


\\----------------------------------------------------------------------------------------
\\  FCOSH.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fcosh()={
  my(y);
  make_fop1to1("fcosh",
               "fcosh",
               -2,
               MC68881+MC68882+FPSP040+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND,
                      DATA_ZERO_PLUS),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,Inf,  \\cosh(-Inf)=Inf
                                x==-Rei,1,  \\cosh(-0)=1
                                x==Rei,1,  \\cosh(+0)=1
                                x==Inf,Inf,  \\cosh(+Inf)=Inf
                                NaN),
                             fpsr=bitor(fpsr,X2);
                             if(x<=-65536,fpsr=bitor(fpsr,OF);xxx(Inf,rp,rm),  \\cosh(-big)=+Inf,OF
                                65536<=x,fpsr=bitor(fpsr,OF);xxx(Inf,rp,rm),  \\cosh(+big)=+Inf,OF
                                y=roundxxx(cosh(x),rp,rm);
                                if(type(x)!="t_POL",
                                   if(rm==RP,if(y==1,y=nextup(1,rp))));
                                xxx(y,rp,rm))))
  }


\\----------------------------------------------------------------------------------------
\\  FDABS.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fdabs()={
  make_fop1to1("fdabs",
               "fdabs",
               -1,
               MC68040+FPSP040+MC68060+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,Inf,  \\dabs(-Inf)=+Inf
                                x==-Rei,Rei,  \\dabs(-0)=+0
                                x==Rei,Rei,  \\dabs(+0)=+0
                                x==Inf,Inf,  \\dabs(+Inf)=+Inf
                                NaN),
                             dbl(abs(x),rm)))
  }


\\----------------------------------------------------------------------------------------
\\  FDADD.X FPm,FPn
\\----------------------------------------------------------------------------------------
fdadd_func(x,y,rp,rm)={
  my(z);
  if(x==0,x=Rei);
  if(y==0,y=Rei);
  if((x==NaN)||(y==NaN),NaN,
     (x==Inf)&&(y==-Inf),fpsr=bitor(fpsr,OE);NaN,  \\(+Inf)+(-Inf)=NaN,OE
     (x==-Inf)&&(y==Inf),fpsr=bitor(fpsr,OE);NaN,  \\(-Inf)+(+Inf)=NaN,OE
     (x==Rei)&&(y==Rei),Rei,  \\(+0)+(+0)=+0
     (x==-Rei)&&(y==-Rei),-Rei,  \\(-0)+(-0)=-0
     (x==Rei)&&(y==-Rei),if(rm==RM,-Rei,Rei),  \\(+0)+(-0)=±0
     (x==-Rei)&&(y==Rei),if(rm==RM,-Rei,Rei),  \\(-0)+(+0)=±0
     (y==Inf)||(y==-Inf),y,  \\(±x)+(±Inf)=±Inf
     (x==Inf)||(x==-Inf),x,  \\(±Inf)+(±y)=±Inf
     (y==Rei)||(y==-Rei),dbl(x,rm),  \\(±x)+(±0)=(±x)
     (x==Rei)||(x==-Rei),dbl(y,rm),  \\(±0)+(±y)=±y
     z=x+y;
     if(z==0,
        if(rm==RM,-Rei,Rei),
        dbl(z,rm)))
  }
make_fdadd()={
  make_fop2to1("fdadd",
               "fdadd",
               -1,
               MC68040+FPSP040+MC68060+FPSP060,
               append(DATA_SPECIAL,
                      DATA_EXTENDED,
                      DATA_BINARY),
               fdadd_func)
  }


\\----------------------------------------------------------------------------------------
\\  FDBcc Dr,<label>
\\----------------------------------------------------------------------------------------
make_fdbcc060()={
  my(m,z,n,a,hh,ll);
  print("making fdbcc060");
  asm(
"
;--------------------------------------------------------------------------------
;	FDBcc Dr,<label>
;--------------------------------------------------------------------------------
	.cpu	68030
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
fdbcc060_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#FPSP060,-(sp)
	peamsg	'FDBCC DR,<LABEL>'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: FDBcc Dr,<label>',13,10
;------------------------------------------------
;	d1	actual result
;	d2	actual count
;	d3	actual status
;	d4	source count
;	d5	cc=0..31
;	d6	fpsr=(mzin=0..15)<<24
;	d7	0=failed,1=successful
;	a0	expected result,expected count,expected status,...
;	a1	expected result
;	a2	expected count
;	a3	expected status
;	a4	source count,...
;------------------------------------------------
	lea.l	push_decompressed,a3
;decompress data
	move.l	a3,-(sp)
	pea.l	fdbcc060_data_compressed
	jbsr	decompress
	addq.l	#8,sp
@@:
	addq.l	#4,a3			;source count
	tst.l	(a3)
	bne	@b
	addq.l	#4,a3			;0
	movea.l	a3,a0			;expected result,expected count,expected status,...
;
	move.l	#0<<24,d6		;fpsr=(mzin=0..15)<<24
66:
	moveq.l	#0,d5			;cc=0..31
55:
	lea.l	push_decompressed,a4	;source count,...
44:
;FDBcc Dr=count,<forward-label>
	fmove.l	#0,fpcr
	fmove.l	d6,fpsr			;fpsr
	move.l	(a4),d4			;source count
	move.l	d4,d2			;actual count
	jsr	([fdbcc060_execute_forward,za0,d5.l*4])	;EXECUTE
					;actual result
					;actual count
	fmove.l	fpsr,d3			;actual status
;
	movem.l	(a0),a1-a3		;expected result,expected count,expected status
;
	movem.l	d1-d3/a1-a3,-(sp)	;actual result,actual count,actual status,expected result,expected count,expected status
	jbsr	test_double
	lea.l	24(sp),sp
	move.l	d0,d7			;0=failed,1=successful
;
	move.l	d7,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FDB'
	putstr	(uppercase_cc,za0,d5.l*4)
	putmsg	' Dr='
	puthex8	d4			;source count
	putmsg	',<forward-label> @'
	move.l	d6,-(sp)		;fpsr
	jbsr	printfpsr
	addq.l	#4,sp
	putcrlf
	move.l	d7,-(sp)		;0=failed,1=successful
	movem.l	d1-d3/a1-a3,-(sp)	;actual result,actual count,actual status,expected result,expected count,expected status
	jbsr	output_double
	lea.l	28(sp),sp
@@:
;
;FDBcc Dr=count,<backward-label>
	fmove.l	#0,fpcr
	fmove.l	d6,fpsr			;fpsr
	move.l	(a4),d4			;source count
	move.l	d4,d2			;actual count
	jsr	([fdbcc060_execute_backward,za0,d5.l*4])	;EXECUTE
					;actual result
					;actual count
	fmove.l	fpsr,d3			;actual status
;
	movem.l	(a0),a1-a3		;expected result,expected count,expected status
;
	movem.l	d1-d3/a1-a3,-(sp)	;actual result,actual count,actual status,expected result,expected count,expected status
	jbsr	test_double
	lea.l	24(sp),sp
	move.l	d0,d7			;0=failed,1=successful
;
	move.l	d7,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FDB'
	putstr	(uppercase_cc,za0,d5.l*4)
	putmsg	' Dr='
	puthex8	d4			;source count
	putmsg	',<backward-label> @'
	move.l	d6,-(sp)		;fpsr
	jbsr	printfpsr
	addq.l	#4,sp
	putcrlf
	move.l	d7,-(sp)		;0=failed,1=successful
	movem.l	d1-d3/a1-a3,-(sp)	;actual result,actual count,actual status,expected result,expected count,expected status
	jbsr	output_double
	lea.l	28(sp),sp
@@:
;
	lea.l	(12,a0),a0		;expected result,expected count,expected status,...
;
	addq.l	#4,a4			;source count
	tst.l	(a4)			;source count,...
	bne	44b
;
	addq.w	#1,d5			;cc++
	cmp.w	#31,d5			;cc=0..31
	bls	55b
;
	add.l	#1<<24,d6		;mzin++
	cmp.l	#15<<24,d6		;fpsr=(mzin=0..15)<<24
	bls	66b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts

	.align	4
fdbcc060_execute_forward::
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
	.dc.l	fdbcc060_execute_forward_&cc
  .endm
fdbcc060_execute_backward::
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
	.dc.l	fdbcc060_execute_backward_&cc
  .endm
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
fdbcc060_execute_forward_&cc::
	moveq.l	#2,d1			;actual result. 2=too long
	FDB&cc	d2,@f			;EXECUTE
	moveq.l	#0,d1			;actual result. 0=not taken
	rts

	subq.l	#2,d1			;actual result. -1=too short(forward)/too long(backward)
@@:
	subq.l	#1,d1			;actual result. 1=taken
	rts

fdbcc060_execute_backward_&cc::
	moveq.l	#2,d1			;actual result. 2=too short
	FDB&cc	d2,@b			;EXECUTE
	moveq.l	#0,d1			;actual result. 0=not taken
	rts
  .endm
	.cpu	68000

	.align	4
fdbcc060_data_compressed::
");
  push_start();
  \\source count,...
  for(h=0,5,
      hh=if(h<2,h,h<5,0x7FFD+h,0xFFFF);  \\$0000,$0001,$7FFF,$8000,$8001,$FFFF
      for(l=0,5,
          ll=if(l<2,l,l<5,0x7FFD+l,0xFFFF);  \\$0000,$0001,$7FFF,$8000,$8001,$FFFF
          push(4,(hh<<16)+ll)));
  push(4,0);
  \\expected result,expected count,expected status,...
  for(mzin=0,15,
      m=bitand(mzin>>3,1);
      z=bitand(mzin>>2,1);
      n=bitand(mzin>>0,1);
      a=[
        0,           \\000000  F
        z,           \\000001  EQ
        !(n||z||m),  \\000010  OGT
        z||!(n||m),  \\000011  OGE
        m&&!(n||z),  \\000100  OLT
        z||(m&&!n),  \\000101  OLE
        !(n||z),     \\000110  OGL
        !n,          \\000111  OR
        n,           \\001000  UN
        n||z,        \\001001  UEQ
        n||!(m||z),  \\001010  UGT
        n||(z||!m),  \\001011  UGE
        n||(m&&!z),  \\001100  ULT
        n||z||m,     \\001101  ULE
        !z,          \\001110  NE
        1            \\001111  T
        ];
      for(cc=0,15,
          for(h=0,5,
              hh=if(h<2,h,h<5,0x7FFD+h,0xFFFF);  \\$0000,$0001,$7FFF,$8000,$8001,$FFFF
              for(l=0,5,
                  ll=if(l<2,l,l<5,0x7FFD+l,0xFFFF);  \\$0000,$0001,$7FFF,$8000,$8001,$FFFF
                  push(4,!a[1+cc]&&(ll!=0));  \\expected result. 0=not taken,1=taken
                  push(4,(hh<<16)+if(a[1+cc],ll,bitand(0xFFFF,ll-1)));  \\expected count
                  push(4,mzin<<24))));  \\expected status
      for(cc=16,31,
          for(h=0,5,
              hh=if(h<2,h,h<5,0x7FFD+h,0xFFFF);  \\$0000,$0001,$7FFF,$8000,$8001,$FFFF
              for(l=0,5,
                  ll=if(l<2,l,l<5,0x7FFD+l,0xFFFF);  \\$0000,$0001,$7FFF,$8000,$8001,$FFFF
                  push(4,!a[1+cc-16]&&(ll!=0));  \\expected result. 0=not taken,1=taken
                  push(4,(hh<<16)+if(a[1+cc-16],ll,bitand(0xFFFF,ll-1)));  \\expected count
                  push(4,(mzin<<24)+if(n,BS+AV,0))))));  \\expected status
  push(4,-1);
  push_end()
  }
make_fdbcc88x()={
  my(m,z,n,a,hh,ll);
  print("making fdbcc88x");
  asm(
"
;--------------------------------------------------------------------------------
;	FDBcc Dr,<label>
;--------------------------------------------------------------------------------
	.cpu	68030
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
fdbcc88x_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#MC68881+MC68882+MC68040+FPSP040,-(sp)
	peamsg	'FDBCC DR,<LABEL>'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: FDBcc Dr,<label>',13,10
;------------------------------------------------
;	d1	actual result
;	d2	actual count
;	d3	actual status
;	d4	source count
;	d5	cc=0..31
;	d6	fpsr=(mzin=0..15)<<24
;	d7	0=failed,1=successful
;	a0	expected result,expected count,expected status,...
;	a1	expected result
;	a2	expected count
;	a3	expected status
;	a4	source count,...
;------------------------------------------------
	lea.l	push_decompressed,a3
;decompress data
	move.l	a3,-(sp)
	pea.l	fdbcc88x_data_compressed
	jbsr	decompress
	addq.l	#8,sp
@@:
	addq.l	#4,a3			;source count
	tst.l	(a3)
	bne	@b
	addq.l	#4,a3			;0
	movea.l	a3,a0			;expected result,expected count,expected status,...
;
	move.l	#0<<24,d6		;fpsr=(mzin=0..15)<<24
66:
	moveq.l	#0,d5			;cc=0..31
55:
	lea.l	push_decompressed,a4	;source count,...
44:
;FDBcc Dr,<forward-label>
	fmove.l	#0,fpcr
	fmove.l	d6,fpsr			;fpsr
	move.l	(a4),d4			;source count
	move.l	d4,d2			;actual count
	jsr	([fdbcc88x_execute_forward,za0,d5.l*4])	;EXECUTE
					;actual result
					;actual count
	fmove.l	fpsr,d3			;actual status
;
	movem.l	(a0),a1-a3		;expected result,expected count,expected status
;
	movem.l	d1-d3/a1-a3,-(sp)	;actual result,actual count,actual status,expected result,expected count,expected status
	jbsr	test_double
	lea.l	24(sp),sp
	move.l	d0,d7			;0=failed,1=successful
;
	move.l	d7,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FDB'
	putstr	(uppercase_cc,za0,d5.l*4)
	putmsg	' Dr='
	puthex8	d4			;source count
	putmsg	',<forward-label> @'
	move.l	d6,-(sp)		;fpsr
	jbsr	printfpsr
	addq.l	#4,sp
	putcrlf
	move.l	d7,-(sp)		;0=failed,1=successful
	movem.l	d1-d3/a1-a3,-(sp)	;actual result,actual count,actual status,expected result,expected count,expected status
	jbsr	output_double
	lea.l	28(sp),sp
@@:
;
;FDBcc Dr,<backward-label>
	fmove.l	#0,fpcr
	fmove.l	d6,fpsr			;fpsr
	move.l	(a4),d4			;source count
	move.l	d4,d2			;actual count
	jsr	([fdbcc88x_execute_backward,za0,d5.l*4])	;EXECUTE
					;actual result
					;actual count
	fmove.l	fpsr,d3			;actual status
;
	movem.l	(a0),a1-a3		;expected result,expected count,expected status
;
	movem.l	d1-d3/a1-a3,-(sp)	;actual result,actual count,actual status,expected result,expected count,expected status
	jbsr	test_double
	lea.l	24(sp),sp
	move.l	d0,d7			;0=failed,1=successful
;
	move.l	d7,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FDB'
	putstr	(uppercase_cc,za0,d5.l*4)
	putmsg	' Dr='
	puthex8	d4			;source count
	putmsg	',<backward-label> @'
	move.l	d6,-(sp)		;fpsr
	jbsr	printfpsr
	addq.l	#4,sp
	putcrlf
	move.l	d7,-(sp)		;0=failed,1=successful
	movem.l	d1-d3/a1-a3,-(sp)	;actual result,actual count,actual status,expected result,expected count,expected status
	jbsr	output_double
	lea.l	28(sp),sp
@@:
;
	lea.l	(12,a0),a0		;expected result,expected count,expected status,...
;
	addq.l	#4,a4			;source count
	tst.l	(a4)			;source count,...
	bne	44b
;
	addq.w	#1,d5			;cc++
	cmp.w	#31,d5			;cc=0..31
	bls	55b
;
	add.l	#1<<24,d6		;mzin++
	cmp.l	#15<<24,d6		;fpsr=(mzin=0..15)<<24
	bls	66b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts

	.align	4
fdbcc88x_execute_forward::
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
	.dc.l	fdbcc88x_execute_forward_&cc
  .endm
fdbcc88x_execute_backward::
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
	.dc.l	fdbcc88x_execute_backward_&cc
  .endm
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
fdbcc88x_execute_forward_&cc::
	moveq.l	#2,d1			;actual result. 2=too long
	FDB&cc	d2,@f			;EXECUTE
	moveq.l	#0,d1			;actual result. 0=not taken
	rts

	subq.l	#2,d1			;actual result. -1=too short(forward)/too long(backward)
@@:
	subq.l	#1,d1			;actual result. 1=taken
	rts

fdbcc88x_execute_backward_&cc::
	moveq.l	#2,d1			;actual result. 2=too short
	FDB&cc	d2,@b			;EXECUTE
	moveq.l	#0,d1			;actual result. 0=not taken
	rts
  .endm
	.cpu	68000

	.align	4
fdbcc88x_data_compressed::
");
  push_start();
  \\source count,...
  for(h=0,5,
      hh=if(h<2,h,h<5,0x7FFD+h,0xFFFF);  \\$0000,$0001,$7FFF,$8000,$8001,$FFFF
      for(l=0,5,
          ll=if(l<2,l,l<5,0x7FFD+l,0xFFFF);  \\$0000,$0001,$7FFF,$8000,$8001,$FFFF
          push(4,(hh<<16)+ll)));
  push(4,0);
  \\expected result,expected count,expected status,...
  for(mzin=0,15,
      m=bitand(mzin>>3,1);
      z=bitand(mzin>>2,1);
      n=bitand(mzin>>0,1);
      a=[
        0,           \\000000  F
        z,           \\000001  EQ
        !(n||z||m),  \\000010  OGT
        z||!(n||m),  \\000011  OGE
        m&&!(n||z),  \\000100  OLT
        z||(m&&!n),  \\000101  OLE
        !(n||z),     \\000110  OGL
        z||!n,       \\000111  OR
        n,           \\001000  UN
        n||z,        \\001001  UEQ
        n||!(m||z),  \\001010  UGT
        n||(z||!m),  \\001011  UGE
        n||(m&&!z),  \\001100  ULT
        n||z||m,     \\001101  ULE
        n||!z,       \\001110  NE
        1            \\001111  T
        ];
      for(cc=0,15,
          for(h=0,5,
              hh=if(h<2,h,h<5,0x7FFD+h,0xFFFF);  \\$0000,$0001,$7FFF,$8000,$8001,$FFFF
              for(l=0,5,
                  ll=if(l<2,l,l<5,0x7FFD+l,0xFFFF);  \\$0000,$0001,$7FFF,$8000,$8001,$FFFF
                  push(4,!a[1+cc]&&(ll!=0));  \\expected result. 0=not taken,1=taken
                  push(4,(hh<<16)+if(a[1+cc],ll,bitand(0xFFFF,ll-1)));  \\expected count
                  push(4,mzin<<24))));  \\expected status
      for(cc=16,31,
          for(h=0,5,
              hh=if(h<2,h,h<5,0x7FFD+h,0xFFFF);  \\$0000,$0001,$7FFF,$8000,$8001,$FFFF
              for(l=0,5,
                  ll=if(l<2,l,l<5,0x7FFD+l,0xFFFF);  \\$0000,$0001,$7FFF,$8000,$8001,$FFFF
                  push(4,!a[1+cc-16]&&(ll!=0));  \\expected result. 0=not taken,1=taken
                  push(4,(hh<<16)+if(a[1+cc-16],ll,bitand(0xFFFF,ll-1)));  \\expected count
                  push(4,(mzin<<24)+if(n,BS+AV,0))))));  \\expected status
  push(4,-1);
  push_end()
  }


\\----------------------------------------------------------------------------------------
\\  FDDIV.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fddiv()={
  make_fop2to1("fddiv",
               "fddiv",
               -1,
               MC68040+FPSP040+MC68060+FPSP060,
               append(DATA_SPECIAL,
                      DATA_EXTENDED,
                      DATA_BINARY),
               (x,y,rp,rm)->if((x==NaN)||(y==NaN),NaN,
                               ((x==Rei)||(x==-Rei))&&((y==Rei)||(y==-Rei)),fpsr=bitor(fpsr,OE);NaN,  \\(±0)/(±0)=NaN,OE
                               ((x==Inf)||(x==-Inf))&&((y==Inf)||(y==-Inf)),fpsr=bitor(fpsr,OE);NaN,  \\(±Inf)/(±Inf)=NaN,OE
                               ((x==Inf)||(x==-Inf))&&((y==Rei)||(y==-Rei)),if(x==Inf,1,-1)*if(y==Rei,1,-1)*Inf,  \\(±Inf)/(±0)=±Inf,non-DZ
                               ((x==Rei)||(x==-Rei))&&((y==Inf)||(y==-Inf)),if(x==Rei,1,-1)*if(y==Inf,1,-1)*Rei,  \\(±0)/(±Inf)=±0
                               (y==Rei)||(y==-Rei),fpsr=bitor(fpsr,DZ);sign(x)*if(y==Rei,1,-1)*Inf,  \\(±x)/(±0)=±Inf,DZ
                               (y==Inf)||(y==-Inf),sign(x)*if(y==Inf,1,-1)*Rei,  \\(±x)/(±Inf)=±0
                               (x==Rei)||(x==-Rei),if(x==Rei,1,-1)*sign(y)*Rei,  \\(±0)/(±y)=±0
                               (x==Inf)||(x==-Inf),if(x==Inf,1,-1)*sign(y)*Inf,  \\(±Inf)/(±y)=±Inf
                               dbl(x/y,rm)))
  }


\\----------------------------------------------------------------------------------------
\\  FDIV.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fdiv()={
  make_fop2to1("fdiv",
               "fdiv",
               -1,
               MC68881+MC68882+MC68040+FPSP040+MC68060+FPSP060,
               append(DATA_SPECIAL,
                      DATA_EXTENDED,
                      DATA_BINARY),
               (x,y,rp,rm)->if((x==NaN)||(y==NaN),NaN,
                               ((x==Rei)||(x==-Rei))&&((y==Rei)||(y==-Rei)),fpsr=bitor(fpsr,OE);NaN,  \\(±0)/(±0)=NaN,OE
                               ((x==Inf)||(x==-Inf))&&((y==Inf)||(y==-Inf)),fpsr=bitor(fpsr,OE);NaN,  \\(±Inf)/(±Inf)=NaN,OE
                               ((x==Inf)||(x==-Inf))&&((y==Rei)||(y==-Rei)),if(x==Inf,1,-1)*if(y==Rei,1,-1)*Inf,  \\(±Inf)/(±0)=±Inf,non-DZ
                               ((x==Rei)||(x==-Rei))&&((y==Inf)||(y==-Inf)),if(x==Rei,1,-1)*if(y==Inf,1,-1)*Rei,  \\(±0)/(±Inf)=±0
                               (y==Rei)||(y==-Rei),fpsr=bitor(fpsr,DZ);sign(x)*if(y==Rei,1,-1)*Inf,  \\(±x)/(±0)=±Inf,DZ
                               (y==Inf)||(y==-Inf),sign(x)*if(y==Inf,1,-1)*Rei,  \\(±x)/(±Inf)=±0
                               (x==Rei)||(x==-Rei),if(x==Rei,1,-1)*sign(y)*Rei,  \\(±0)/(±y)=±0
                               (x==Inf)||(x==-Inf),if(x==Inf,1,-1)*sign(y)*Inf,  \\(±Inf)/(±y)=±Inf
                               xxx2(x/y,rp,rm)))
  }


\\----------------------------------------------------------------------------------------
\\  FDMOVE.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fdmove()={
  make_fop1to1("fdmove",
               "fdmove",
               -1,
               MC68040+FPSP040+MC68060+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,-Inf,  \\dmove(-Inf)=-Inf
                                x==-Rei,-Rei,  \\dmove(-0)=-0
                                x==Rei,Rei,  \\dmove(+0)=+0
                                x==Inf,Inf,  \\dmove(+Inf)=+Inf
                                NaN),
                             dbl(x,rm)))
  }


\\----------------------------------------------------------------------------------------
\\  FDMUL.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fdmul()={
  make_fop2to1("fdmul",
               "fdmul",
               -1,
               MC68040+FPSP040+MC68060+FPSP060,
               append(DATA_SPECIAL,
                      DATA_EXTENDED,
                      DATA_BINARY),
               (x,y,rp,rm)->if((x==NaN)||(y==NaN),NaN,
                               ((x==Rei)||(x==-Rei))&&((y==Inf)||(y==-Inf)),fpsr=bitor(fpsr,OE);NaN,  \\(±0)*(±Inf)=NaN,OE
                               ((x==Inf)||(x==-Inf))&&((y==Rei)||(y==-Rei)),fpsr=bitor(fpsr,OE);NaN,  \\(±Inf)*(±0)=NaN,OE
                               ((x==Rei)||(x==-Rei))&&((y==Rei)||(y==-Rei)),if(x==Rei,1,-1)*if(y==Rei,1,-1)*Rei,  \\(±0)*(±0)=±0
                               ((x==Inf)||(x==-Inf))&&((y==Inf)||(y==-Inf)),if(x==Inf,1,-1)*if(y==Inf,1,-1)*Inf,  \\(±Inf)*(±Inf)=±Inf
                               (y==Rei)||(y==-Rei),sign(x)*if(y==Rei,1,-1)*Rei,  \\(±x)*(±0)=±0
                               (y==Inf)||(y==-Inf),sign(x)*if(y==Inf,1,-1)*Inf,  \\(±x)*(±Inf)=±Inf
                               (x==Rei)||(x==-Rei),if(x==Rei,1,-1)*sign(y)*Rei,  \\(±0)*(±y)=±0
                               (x==Inf)||(x==-Inf),if(x==Inf,1,-1)*sign(y)*Inf,  \\(±Inf)*(±y)=±Inf
                               dbl(x*y,rm)));
  }


\\----------------------------------------------------------------------------------------
\\  FDNEG.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fdneg()={
  make_fop1to1("fdneg",
               "fdneg",
               -1,
               MC68040+FPSP040+MC68060+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,Inf,  \\dneg(-Inf)=+Inf
                                x==-Rei,Rei,  \\dneg(-0)=+0
                                x==Rei,-Rei,  \\dneg(+0)=-0
                                x==Inf,-Inf,  \\dneg(+Inf)=-Inf
                                NaN),
                             dbl(-x,rm)))
  }


\\----------------------------------------------------------------------------------------
\\  FDSQRT.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fdsqrt()={
  my(y);
  make_fop1to1("fdsqrt",
               "fdsqrt",
               -1,
               MC68040+FPSP040+MC68060+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND,
                      DATA_ZERO_PLUS,
                      DATA_ONE_MINUS,
                      DATA_ONE_PLUS),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,fpsr=bitor(fpsr,OE);NaN,  \\dsqrt(-Inf)=NaN,OE
                                x==-Rei,-Rei,  \\dsqrt(-0)=-0
                                x==Rei,Rei,  \\dsqrt(+0)=+0
                                x==Inf,Inf,  \\dsqrt(+Inf)=+Inf
                                NaN),
                             if(x<0,fpsr=bitor(fpsr,OE);NaN,  \\dsqrt(-x)=NaN,OE
                                y=dbl(sqrt(x),rm);
                                if(y^2!=x,fpsr=bitor(fpsr,X2));
                                y)))
  }


\\----------------------------------------------------------------------------------------
\\  FDSUB.X FPm,FPn
\\----------------------------------------------------------------------------------------
fdsub_func(x,y,rp,rm)={
  my(z);
  if(x==0,x=Rei);
  if(y==0,y=Rei);
  if((x==NaN)||(y==NaN),NaN,
     (x==Inf)&&(y==Inf),fpsr=bitor(fpsr,OE);NaN,  \\(+Inf)-(+Inf)=NaN,OE
     (x==-Inf)&&(y==-Inf),fpsr=bitor(fpsr,OE);NaN,  \\(-Inf)-(-Inf)=NaN,OE
     (x==Rei)&&(y==-Rei),Rei,  \\(+0)-(-0)=+0
     (x==-Rei)&&(y==Rei),-Rei,  \\(-0)-(+0)=-0
     (x==Rei)&&(y==Rei),if(rm==RM,-Rei,Rei),  \\(+0)-(+0)=±0
     (x==-Rei)&&(y==-Rei),if(rm==RM,-Rei,Rei),  \\(-0)-(-0)=±0
     (y==Inf)||(y==-Inf),-y,  \\(±x)-(±Inf)=∓Inf
     (x==Inf)||(x==-Inf),x,  \\(±Inf)-(±y)=±Inf
     (y==Rei)||(y==-Rei),dbl(x,rm),  \\(±x)-(±0)=(±x)
     (x==Rei)||(x==-Rei),dbl(-y,rm),  \\(±0)-(±y)=∓y
     z=x-y;
     if(z==0,
        if(rm==RM,-Rei,Rei),
        dbl(z,rm)))
  }
make_fdsub()={
  make_fop2to1("fdsub",
               "fdsub",
               -1,
               MC68040+FPSP040+MC68060+FPSP060,
               append(DATA_SPECIAL,
                      DATA_EXTENDED,
                      DATA_BINARY),
               fdsub_func)
  }


\\----------------------------------------------------------------------------------------
\\  FETOX.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fetox()={
  my(y);
  make_fop1to1("fetox",
               "fetox",
               -2,
               MC68881+MC68882+FPSP040+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND,
                      DATA_ZERO_PLUS),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,Rei,  \\etox(-Inf)=+0
                                x==-Rei,1,  \\etox(-0)=1
                                x==Rei,1,  \\etox(+0)=1
                                x==Inf,Inf,  \\etox(+Inf)=+Inf
                                NaN),
                             fpsr=bitor(fpsr,X2);
                             if(x<=-65536,fpsr=bitor(fpsr,UF);xxx(Rei,rp,rm),  \\etox(-big)=+0,UF
                                65536<x,fpsr=bitor(fpsr,OF);xxx(Inf,rp,rm),  \\etox(+big)=+Inf,OF
                                xxx(exp(x),rp,rm))))
  }


\\----------------------------------------------------------------------------------------
\\  FETOXM1.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fetoxm1()={
  my(y);
  make_fop1to1("fetoxm1",
               "fetoxm1",
               -2,
               MC68881+MC68882+FPSP040+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND,
                      DATA_ZERO_PLUS),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,-1,  \\etoxm1(-Inf)=-1
                                x==-Rei,-Rei,  \\etoxm1(-0)=-0
                                x==Rei,Rei,  \\etoxm1(+0)=+0
                                x==Inf,Inf,  \\etoxm1(+Inf)=+Inf
                                NaN),
                             fpsr=bitor(fpsr,X2);
                             if(x<=-256,if((rm==RZ)||(rm==RP),nextup(-1,rp),-1),  \\etoxm1(-big)=-1
                                65536<=x,fpsr=bitor(fpsr,OF);xxx(Inf,rp,rm),  \\etoxm1(+big)=+INf,OF
                                y=roundxxx(expm1(x),rp,rm);
                                y=originUpperUpper(y,x,rp,rm);
                                y=xxx(y,rp,rm);
                                correctUnderflow(y,rp))))
  }


\\----------------------------------------------------------------------------------------
\\  FGETEXP.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fgetexp()={
  make_fop1to1("fgetexp",
               "fgetexp",
               -1,
               MC68881+MC68882+FPSP040+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND,
                      DATA_ZERO_PLUS),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,fpsr=bitor(fpsr,OE);NaN,  \\getexp(-Inf)=NaN,OE
                                x==-Rei,-Rei,  \\getexp(-0)=-0
                                x==Rei,Rei,  \\getexp(+0)=+0
                                x==Inf,fpsr=bitor(fpsr,OE);NaN,  \\getexp(+Inf)=NaN,OE
                                NaN),
                             exd(floor(log2(abs(x))),RN)))
  }


\\----------------------------------------------------------------------------------------
\\  FGETMAN.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fgetman()={
  make_fop1to1("fgetman",
               "fgetman",
               -1,
               MC68881+MC68882+FPSP040+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND,
                      DATA_ZERO_PLUS),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,fpsr=bitor(fpsr,OE);NaN,  \\getman(-Inf)=NaN,OE
                                x==-Rei,-Rei,  \\getman(-0)=-0
                                x==Rei,Rei,  \\getman(+0)=+0
                                x==Inf,fpsr=bitor(fpsr,OE);NaN,  \\getman(+Inf)=NaN,OE
                                NaN),
                             exd(2^-floor(log2(abs(x)))*x,RN)))
  }


\\----------------------------------------------------------------------------------------
\\  FINT.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fint()={
  my(y);
  make_fop1to1("fint",
               "fint",
               -1,
               MC68881+MC68882+FPSP040+MC68060+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,-Inf,  \\int(-Inf)=-Inf
                                x==-Rei,-Rei,  \\int(-0)=-0
                                x==Rei,Rei,  \\int(+0)=+0
                                x==Inf,Inf,  \\int(+Inf)=+Inf
                                NaN),
                             y=if(rm==RN,rint(x),
                                  rm==RZ,trunc(x),
                                  rm==RM,floor(x),
                                  rm==RP,ceil(x),
                                  error());
                             if(y!=x,fpsr=bitor(fpsr,X2));
                             if(y==0,y=if(x<0,-Rei,Rei));
                             \\FINTはsingleとdoubleの丸め処理を行わない
                             y))
  }


\\----------------------------------------------------------------------------------------
\\  FINTRZ.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fintrz()={
  my(y);
  make_fop1to1("fintrz",
               "fintrz",
               -1,
               MC68881+MC68882+FPSP040+MC68060+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,-Inf,  \\intrz(-Inf)=-Inf
                                x==-Rei,-Rei,  \\intrz(-0)=-0
                                x==Rei,Rei,  \\intrz(+0)=+0
                                x==Inf,Inf,  \\intrz(+Inf)=+Inf
                                NaN),
                             y=trunc(x);
                             if(y!=x,fpsr=bitor(fpsr,X2));
                             if(y==0,y=if(x<0,-Rei,Rei));
                             \\FINTRZはsingleとdoubleの丸め処理を行わない
                             y))
  }


\\----------------------------------------------------------------------------------------
\\  FLOG10.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_flog10()={
  make_fop1to1("flog10",
               "flog10",
               -2,
               MC68881+MC68882+FPSP040+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND,
                      DATA_ZERO_PLUS,
                      DATA_ONE_MINUS,
                      DATA_ONE_PLUS),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,fpsr=bitor(fpsr,OE);NaN,  \\log10(-Inf)=NaN,OE
                                x==-Rei,fpsr=bitor(fpsr,DZ);-Inf,  \\log10(-0)=-Inf,DZ
                                x==Rei,fpsr=bitor(fpsr,DZ);-Inf,  \\log10(+0)=-Inf,DZ
                                x==Inf,Inf,  \\log10(+Inf)=+Inf
                                NaN),
                             x<0,fpsr=bitor(fpsr,OE);NaN,  \\log10(x<0)=NaN,OE
                             x==1,if(rm==RM,-Rei,Rei),  \\log10(1)=±0
                             fpsr=bitor(fpsr,X2);
                             xxx(log10(x),rp,rm)))
  }


\\----------------------------------------------------------------------------------------
\\  FLOG2.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_flog2()={
  make_fop1to1("flog2",
               "flog2",
               -2,
               MC68881+MC68882+FPSP040+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND,
                      DATA_ZERO_PLUS,
                      DATA_ONE_MINUS,
                      DATA_ONE_PLUS),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,fpsr=bitor(fpsr,OE);NaN,  \\log2(-Inf)=NaN,OE
                                x==-Rei,fpsr=bitor(fpsr,DZ);-Inf,  \\log2(-0)=-Inf,DZ
                                x==Rei,fpsr=bitor(fpsr,DZ);-Inf,  \\log2(+0)=-Inf,DZ
                                x==Inf,Inf,  \\log2(+Inf)=+Inf
                                NaN),
                             x<0,fpsr=bitor(fpsr,OE);NaN,  \\log2(x<0)=NaN,OE
                             x==1,if(rm==RM,-Rei,Rei),  \\log2(1)=±0
                             fpsr=bitor(fpsr,X2);
                             xxx(log2(x),rp,rm)))
  }


\\----------------------------------------------------------------------------------------
\\  FLOGN.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_flogn()={
  make_fop1to1("flogn",
               "flogn",
               -2,
               MC68881+MC68882+FPSP040+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND,
                      DATA_ZERO_PLUS,
                      DATA_ONE_MINUS,
                      DATA_ONE_PLUS),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,fpsr=bitor(fpsr,OE);NaN,  \\logn(-Inf)=NaN,OE
                                x==-Rei,fpsr=bitor(fpsr,DZ);-Inf,  \\logn(-0)=-Inf,DZ
                                x==Rei,fpsr=bitor(fpsr,DZ);-Inf,  \\logn(+0)=-Inf,DZ
                                x==Inf,Inf,  \\logn(+Inf)=+Inf
                                NaN),
                             x<0,fpsr=bitor(fpsr,OE);NaN,  \\logn(x<0)=NaN,OE
                             x==1,if(rm==RM,-Rei,Rei),  \\logn(1)=±0
                             fpsr=bitor(fpsr,X2);
                             xxx(log(x),rp,rm)))
  }


\\----------------------------------------------------------------------------------------
\\  FLOGNP1.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_flognp1()={
  my(y);
  make_fop1to1("flognp1",
               "flognp1",
               -2,
               MC68881+MC68882+FPSP040+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND,
                      DATA_ZERO_PLUS,
                      DATA_ONE_MINUS),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,fpsr=bitor(fpsr,OE);NaN,  \\lognp1(-Inf)=NaN,OE
                                x==-Rei,-Rei,  \\lognp1(-0)=-0
                                x==Rei,Rei,  \\lognp1(+0)=+0
                                x==Inf,Inf,  \\lognp1(+Inf)=+Inf
                                NaN),
                             x<-1,fpsr=bitor(fpsr,OE);NaN,  \\lognp1(x<-1)=NaN,OE
                             x==-1,fpsr=bitor(fpsr,DZ);-Inf,  \\lognp1(-1)=-Inf,DZ
                             fpsr=bitor(fpsr,X2);
                             y=roundxxx(log(1+x),rp,rm);
                             y=originLowerLower(y,x,rp,rm);
                             y=xxx(y,rp,rm);
                             correctUnderflow(y,rp)))
  }


\\----------------------------------------------------------------------------------------
\\  FMOD.X FPm,FPn
\\----------------------------------------------------------------------------------------
fmod_func(x,y,rp,rm)={
  my(q,z);
  fpsr=bitand(fpsr,0xFF00FFFF);  \\quotient byteをクリアする
  if((x==NaN)||(y==NaN),NaN,
     (x==Inf)||(x==-Inf),fpsr=bitor(fpsr,OE);NaN,  \\(±Inf)%(±y)=NaN,OE
     (y==Rei)||(y==-Rei),fpsr=bitor(fpsr,OE);NaN,  \\(±x)%(±0)=NaN,OE
     fpsr=bitor(fpsr,bitxor(isminus(x),isminus(y))<<23);  \\商の符号
     if((x==Rei)||(x==-Rei),x,  \\(±0)%(±y)=±0,商は±0
        (y==Inf)||(y==-Inf),xxx(x,rp,rm),  \\(±x)%(±Inf)=±x,商は±0。xが非正規化数のときUFをセットする
        q=trunc(x/y);
        fpsr=bitor(fpsr,bitand(abs(q),127)<<16);  \\商の絶対値の下位7bit
        z=xxx(x-q*y,rp,rm);
        if((z==Rei)||(z==-Rei),z=sign(x)*Rei);  \\余りが0のときは0にxの符号を付ける
        z))
  }
make_fmod()={
  make_fop2to1("fmod",
               "fmod",
               -1,
               MC68881+MC68882+FPSP040+FPSP060,
               append(DATA_SPECIAL,
                      DATA_EXTENDED,
                      DATA_BINARY),
               fmod_func)
  }


\\----------------------------------------------------------------------------------------
\\  FMOVE.B FPn,Dr
\\  FMOVE.B FPn,<mem>
\\----------------------------------------------------------------------------------------
make_fmovebregto()={
  my(a,x,u,rp,rm,sr);
  print("making fmovebregto");
  a=append(DATA_SPECIAL,
           DATA_FLOAT,
           DATA_BASIC,
           DATA_ROUND);
  a=vector(#a,n,exd(a[n],RN));
  a=uniq(sort(append(a,vector(#a,n,-a[n]),[NaN]),comparator),comparator);
  asm(
"
;--------------------------------------------------------------------------------
;	FMOVE.B FPn,Dr
;	FMOVE.B FPn,<mem>
;--------------------------------------------------------------------------------
	.cpu	68030
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
fmovebregto_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#MC68881+MC68882+MC68040+FPSP040+MC68060+FPSP060,-(sp)
	peamsg	'FMOVE.B FPN,<EA>'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: FMOVE.B FPn,<ea>',13,10
;------------------------------------------------
;	d1	actual result
;	d3	fill=$00000000,$FFFFFFFF
;	d4	actual status
;	d6	fpcr=(XRN..DRP)<<4
;	d7	0=failed,1=successful
;	a0	expected result,expected status,...
;	a1	expected result
;	a4	expected status
;	a5	source handle,...
;	fp5	source
;------------------------------------------------
	lea.l	push_decompressed,a3
;decompress data
	move.l	a3,-(sp)
	pea.l	fmovebregto_data_compressed
	jbsr	decompress
	addq.l	#8,sp
;relocate decompressed handle
	move.l	#indirect_decompressed,d0
	movea.l	a3,a5			;source handle,...
@@:
	add.l	d0,(a3)+		;source handle
	tst.l	(a3)
	bpl	@b
	addq.l	#4,a3			;-1
	movea.l	a3,a0			;expected result,expected status,...
;
55:
	move.l	#",XRN<<4,",d6		;fpcr=(XRN..DRP)<<4
66:
;FPn,Dr=fill
	moveq.l	#$00000000,d3		;fill=$00000000,$FFFFFFFF
33:
	fmove.l	#0,fpcr
	fmove.x	([a5]),fp5		;source
	fmove.l	d6,fpcr			;fpcr
	fmove.l	#0,fpsr
	move.l	d3,d1			;fill
					;source
	fmove.b	fp5,d1			;EXECUTE
					;actual result
	fmove.l	fpsr,d4			;actual status
	fmove.l	#0,fpcr
;
	movea.l	(a0),a1			;expected result
	movea.l	(4,a0),a4		;expected status
;
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	test_single
	lea.l	16(sp),sp
	move.l	d0,d7			;0=failed,1=successful
;
	move.l	d7,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FMOVE.B FPn='
	puthex24	([a5]),(4,[a5]),(8,[a5])	;source
	putmsg	',Dr='
	puthex8	d3			;fill
	putmsg	' @'
	move.l	d6,-(sp)		;fpcr
	jbsr	printfpcrrprm
	addq.l	#4,sp
	putcrlf
	move.l	d7,-(sp)		;0=failed,1=successful
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	output_single
	lea.l	20(sp),sp
@@:
;
	addq.l	#8,a0			;expected result,expected status,...
;
	not.l	d3			;fill
	bne	33b
;FPn,<mem>=fill
	moveq.l	#$00000000,d3		;fill=$00000000,$FFFFFFFF
33:
	fmove.l	#0,fpcr
	fmove.x	([a5]),fp5		;source
	fmove.l	d6,fpcr			;fpcr
	fmove.l	#0,fpsr
	move.l	d3,-(sp)		;fill
					;source
	fmove.b	fp5,(sp)		;EXECUTE
	move.l	(sp)+,d1		;actual result
	fmove.l	fpsr,d4			;actual status
	fmove.l	#0,fpcr
;
	movea.l	(a0),a1			;expected result
	movea.l	(4,a0),a4		;expected status
;
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	test_single
	lea.l	16(sp),sp
	move.l	d0,d7			;0=failed,1=successful
;
	move.l	d7,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FMOVE.B FPn='
	puthex24	([a5]),(4,[a5]),(8,[a5])	;source
	putmsg	',<mem>='
	puthex8	d3			;fill
	putmsg	' @'
	move.l	d6,-(sp)		;fpcr
	jbsr	printfpcrrprm
	addq.l	#4,sp
	putcrlf
	move.l	d7,-(sp)		;0=failed,1=successful
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	output_single
	lea.l	20(sp),sp
@@:
;
	addq.l	#8,a0			;expected result,expected status,...
;
	not.l	d3			;fill
	bne	33b
;
	add.w	#1<<4,d6		;rprm++
	cmp.w	#",DRP<<4,",d6		;fpcr=(XRN..DRP)<<4
	bls	66b
;
	addq.l	#4,a5			;source handle
	tst.l	(a5)			;source handle
	bpl	55b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts
	.cpu	68000

	.align	4
fmovebregto_data_compressed::
");
  push_start();
  for(i=1,#a,
      x=a[i];  \\ソース
      push_indirect(12,numtoexd(x,RN)));
  push(4,-1);
  for(i=1,#a,
      x=a[i];  \\ソース
      for(rprm=XRN,DRP,  \\(rp<<2)+rm。丸め桁数と丸めモード
          rp=bitand(rprm>>2,3);  \\丸め桁数
          rm=bitand(rprm,3);  \\丸めモード
          fpsr=0;
          u=numtobyte(x,rm);  \\byteに変換する
          fpsr_update_aer();
          sr=fpsr;
          push(4,0x00000000+u);
          push(4,sr);
          push(4,0xFFFFFF00+u);
          push(4,sr);
          push(4,(u<<24)+0x000000);
          push(4,sr);
          push(4,(u<<24)+0xFFFFFF);
          push(4,sr)));
  push_end()
  }


\\----------------------------------------------------------------------------------------
\\  FMOVE.B Dr,FPn
\\  FMOVE.B <mem>,FPn
\\----------------------------------------------------------------------------------------
make_fmovebtoreg()={
  my(a,u,y,rp,rm,sr);
  print("making fmovebtoreg");
  a=DATA_BYTE;
  asm(
"
;--------------------------------------------------------------------------------
;	FMOVE.B Dr,FPn
;	FMOVE.B <mem>,FPn
;--------------------------------------------------------------------------------
	.cpu	68030
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
fmovebtoreg_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#MC68881+MC68882+MC68040+FPSP040+MC68060+FPSP060,-(sp)
	peamsg	'FMOVE.B <EA>,FPN'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: FMOVE.B <ea>,FPn',13,10
;------------------------------------------------
;	d1	fpcr=(XRN..DRP)<<4
;	d2	source
;	d3	0=failed,1=successful
;	d5	expected status
;	d7	actual status
;	a2	source,...
;	a4	expected result handle,expected status,...
;	fp5	expected result
;	fp7	actual result
;------------------------------------------------
	lea.l	push_decompressed,a0
;decompress data
	move.l	a0,-(sp)
	pea.l	fmovebtoreg_data_compressed
	jbsr	decompress
	addq.l	#8,sp
;relocate decompressed handle
	move.l	#indirect_decompressed,d0
	movea.l	a0,a2			;source,...
@@:
	addq.l	#4,a0			;source
	tst.l	(a0)
	bne	@b
	addq.l	#4,a0			;0
	movea.l	a0,a4			;expected result handle,expected status,...
@@:
	add.l	d0,(a0)+		;expected result handle
	addq.l	#4,a0			;expected status
	tst.l	(a0)
	bpl	@b
;	addq.l	#4,a0			;-1
;
22:
	move.l	#",XRN<<4,",d1		;fpcr=(XRN..DRP)<<4
11:
;Dr,FPn
	fmove.l	#0,fpcr
	moveq.l	#0,d2
	move.b	(a2),d2			;source
	fmove.s	#$7FFFFFFF,fp7		;fill=NaN
	fmove.l	d1,fpcr			;fpcr
	fmove.l	#0,fpsr
					;source
	fmove.b	d2,fp7			;EXECUTE
					;actual result
	fmove.l	fpsr,d7			;actual status
	fmove.l	#0,fpcr
;
	fmove.x	([a4]),fp5		;expected result
	move.l	(4,a4),d5		;expected status
;
	move.l	#-1,-(sp)		;fpcr(rp<<6,-1=strict)
	move.l	d5,-(sp)		;expected status
	fmove.x	fp5,-(sp)		;expected result
	move.l	d7,-(sp)		;actual status
	fmove.x	fp7,-(sp)		;actual result
	jbsr	test_extended
	lea.l	36(sp),sp
	move.l	d0,d3			;0=failed,1=successful
;
	move.l	d3,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FMOVE.B Dr='
	puthex2	d2			;source
	putmsg	',FPn @'
	move.l	d1,-(sp)
	jbsr	printfpcrrprm
	addq.l	#4,sp
	putcrlf
	move.l	d3,-(sp)		;0=failed,1=successful
	move.l	d5,-(sp)		;expected status
	fmove.x	fp5,-(sp)		;expected result
	move.l	d7,-(sp)		;actual status
	fmove.x	fp7,-(sp)		;actual result
	jbsr	output_extended
	lea.l	36(sp),sp
@@:
;
;<mem>,FPn
	fmove.l	#0,fpcr
	moveq.l	#0,d2
	move.b	(a2),d2			;source
	fmove.s	#$7FFFFFFF,fp7		;fill=NaN
	fmove.l	d1,fpcr			;fpcr
	fmove.l	#0,fpsr
	move.b	d2,-(sp)		;source
	fmove.b	(sp)+,fp7		;EXECUTE
					;actual result
	fmove.l	fpsr,d7			;actual status
	fmove.l	#0,fpcr
;
	fmove.x	([a4]),fp5		;expected result
	move.l	(4,a4),d5		;expected status
;
	move.l	#-1,-(sp)		;fpcr(rp<<6,-1=strict)
	move.l	d5,-(sp)		;expected status
	fmove.x	fp5,-(sp)		;expected result
	move.l	d7,-(sp)		;actual status
	fmove.x	fp7,-(sp)		;actual result
	jbsr	test_extended
	lea.l	36(sp),sp
	move.l	d0,d3			;0=failed,1=successful
;
	move.l	d3,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FMOVE.B <mem>='
	puthex2	d2			;source
	putmsg	',FPn @'
	move.l	d1,-(sp)
	jbsr	printfpcrrprm
	addq.l	#4,sp
	putcrlf
	move.l	d3,-(sp)		;0=failed,1=successful
	move.l	d5,-(sp)		;expected status
	fmove.x	fp5,-(sp)		;expected result
	move.l	d7,-(sp)		;actual status
	fmove.x	fp7,-(sp)		;actual result
	jbsr	output_extended
	lea.l	36(sp),sp
@@:
;
	addq.l	#8,a4			;expected result
;
	add.w	#1<<4,d1		;rprm++
	cmp.w	#",DRP<<4,",d1		;fpcr=(XRN..DRP)<<4
	bls	11b
;
	addq.l	#4,a2			;source
	tst.l	(a2)			;source
	bne	22b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts
	.cpu	68000

	.align	4
fmovebtoreg_data_compressed::
");
  push_start();
  for(i=1,#a,
      u=a[i];  \\ソース
      push(1,u);
      push(3,0));
  push(4,0);
  for(i=1,#a,
      u=a[i];  \\ソース
      for(rprm=XRN,DRP,  \\(rp<<2)+rm。丸め桁数と丸めモード
          rp=bitand(rprm>>2,3);  \\丸め桁数
          rm=bitand(rprm,3);  \\丸めモード
          fpsr=0;
          y=bytetonum(u);
          y=roundxxx(y,rp,rm);
          fpsr_update_ccr(y);
          fpsr_update_aer();
          sr=fpsr;
          push_indirect(12,numtoexd(y,RN));
          push(4,sr)));
  push(4,-1);
  push_end()
  }


\\----------------------------------------------------------------------------------------
\\  FMOVE.D FPn,<mem>
\\----------------------------------------------------------------------------------------
make_fmovedregto()={
  my(a,x,u,rp,rm,sr);
  print("making fmovedregto");
  a=append(DATA_SPECIAL,
           DATA_FLOAT,
           DATA_BASIC,
           DATA_ROUND);
  a=vector(#a,n,exd(a[n],RN));
  a=uniq(sort(append(a,vector(#a,n,-a[n]),[NaN]),comparator),comparator);
  asm(
"
;--------------------------------------------------------------------------------
;	FMOVE.D FPn,<mem>
;--------------------------------------------------------------------------------
	.cpu	68030
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
fmovedregto_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#MC68881+MC68882+MC68040+FPSP040+MC68060+FPSP060,-(sp)
	peamsg	'FMOVE.D FPN,<EA>'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: FMOVE.D FPn,<ea>',13,10
;------------------------------------------------
;	d1-d2	actual result
;	d4	actual status
;	d6	fpcr=(XRN..DRP)<<4
;	d7	0=failed,1=successful
;	a0	expected result handle,expected status,...
;	a1-a2	expected result
;	a4	expected status
;	a5	source handle,...
;	fp5	source
;------------------------------------------------
	lea.l	push_decompressed,a3
;decompress data
	move.l	a3,-(sp)
	pea.l	fmovedregto_data_compressed
	jbsr	decompress
	addq.l	#8,sp
;relocate decompressed handle
	move.l	#indirect_decompressed,d0
	movea.l	a3,a5			;source handle,...
@@:
	add.l	d0,(a3)+		;source handle
	tst.l	(a3)
	bpl	@b
	addq.l	#4,a3			;-1
	movea.l	a3,a0			;expected result handle,expected status,...
@@:
	add.l	d0,(a3)+		;expected result handle
	addq.l	#4,a3			;expected status
	tst.l	(a3)
	bpl	@b
;	addq.l	#4,a3			;-1
;
55:
	move.l	#",XRN<<4,",d6		;fpcr=(XRN..DRP)<<4
66:
;FPn,<mem>
	fmove.l	#0,fpcr
	fmove.x	([a5]),fp5		;source
	fmove.l	d6,fpcr			;fpcr
	fmove.l	#0,fpsr
	move.l	#-1,-(sp)		;fill=-1
	move.l	#-1,-(sp)
					;source
	fmove.d	fp5,(sp)		;EXECUTE
	movem.l	(sp)+,d1-d2		;actual result
	fmove.l	fpsr,d4			;actual status
	fmove.l	#0,fpcr
;
	movem.l	([a0]),a1-a2		;expected result
	movea.l	(4,a0),a4		;expected status
;
	movem.l	d1-d2/d4/a1-a2/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	test_double
	lea.l	24(sp),sp
	move.l	d0,d7			;0=failed,1=successful
;
	move.l	d7,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FMOVE.D FPn='
	puthex24	([a5]),(4,[a5]),(8,[a5])	;source
	putmsg	',<mem> @'
	move.l	d6,-(sp)		;fpcr
	jbsr	printfpcrrprm
	addq.l	#4,sp
	putcrlf
	move.l	d7,-(sp)		;0=failed,1=successful
	movem.l	d1-d2/d4/a1-a2/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	output_double
	lea.l	28(sp),sp
@@:
;
	addq.l	#8,a0			;expected
;
	add.w	#1<<4,d6		;rprm++
	cmp.w	#",DRP<<4,",d6		;fpcr=(XRN..DRP)<<4
	bls	66b
;
	addq.l	#4,a5			;source handle
	tst.l	(a5)			;source handle
	bpl	55b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts
	.cpu	68000

	.align	4
fmovedregto_data_compressed::
");
  push_start();
  for(i=1,#a,
      x=a[i];  \\ソース
      push_indirect(12,numtoexd(x,RN)));
  push(4,-1);
  for(i=1,#a,
      x=a[i];  \\ソース
      for(rprm=XRN,DRP,  \\(rp<<2)+rm。丸め桁数と丸めモード
          rp=bitand(rprm>>2,3);  \\丸め桁数
          rm=bitand(rprm,3);  \\丸めモード
          fpsr=0;
          u=numtodbl(x,if(type(x)=="t_POL",RN,rm));  \\doubleに変換する
          fpsr_update_aer();
          sr=fpsr;
          push_indirect(8,u);
          push(4,sr)));
  push(4,-1);
  push_end()
  }


\\----------------------------------------------------------------------------------------
\\  FMOVE.D <mem>,FPn
\\----------------------------------------------------------------------------------------
make_fmovedtoreg()={
  my(a,u,y,rp,rm,sr);
  print("making fmovedtoreg");
  a=append(DATA_SPECIAL,
           DATA_DOUBLE,
           DATA_BASIC,
           DATA_ROUND);
  a=vector(#a,n,dbl(a[n],RN));
  a=uniq(sort(append(a,vector(#a,n,-a[n]),[NaN]),comparator),comparator);
  asm(
"
;--------------------------------------------------------------------------------
;	FMOVE.D <mem>,FPn
;--------------------------------------------------------------------------------
	.cpu	68030
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
fmovedtoreg_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#MC68881+MC68882+MC68040+FPSP040+MC68060+FPSP060,-(sp)
	peamsg	'FMOVE.D <EA>,FPN'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: FMOVE.D <ea>,FPn',13,10
;------------------------------------------------
;	d1	fpcr=(XRN..DRP)<<4
;	d3	0=failed,1=successful
;	d5	expected status
;	d7	actual status
;	a2	source handle,...
;	a4	expected result handle,expected status,...
;	fp5	expected result
;	fp7	actual result
;------------------------------------------------
	lea.l	push_decompressed,a0
;decompress data
	move.l	a0,-(sp)
	pea.l	fmovedtoreg_data_compressed
	jbsr	decompress
	addq.l	#8,sp
;relocate decompressed handle
	move.l	#indirect_decompressed,d0
	movea.l	a0,a2			;source handle,...
@@:
	add.l	d0,(a0)+		;source handle
	tst.l	(a0)
	bpl	@b
	addq.l	#4,a0			;-1
	movea.l	a0,a4			;expected result handle,expected status,...
@@:
	add.l	d0,(a0)+		;expected result handle
	addq.l	#4,a0			;expected status
	tst.l	(a0)
	bpl	@b
;	addq.l	#4,a0			;-1
;
22:
	move.l	#",XRN<<4,",d1		;fpcr=(XRN..DRP)<<4
11:
;<mem>,FPn
	fmove.l	#0,fpcr
	fmove.s	#$7FFFFFFF,fp7		;fill=NaN
	fmove.l	d1,fpcr			;fpcr
	fmove.l	#0,fpsr
					;source
	fmove.d	([a2]),fp7		;EXECUTE
					;actual result
	fmove.l	fpsr,d7			;actual status
	fmove.l	#0,fpcr
;
	fmove.x	([a4]),fp5		;expected result
	move.l	(4,a4),d5		;expected status
;
	move.l	#-1,-(sp)		;fpcr(rp<<6,-1=strict)
	move.l	d5,-(sp)		;expected status
	fmove.x	fp5,-(sp)		;expected result
	move.l	d7,-(sp)		;actual status
	fmove.x	fp7,-(sp)		;actual result
	jbsr	test_extended
	lea.l	36(sp),sp
	move.l	d0,d3			;0=failed,1=successful
;
	move.l	d3,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FMOVE.D <mem>='
	puthex16	([a2]),(4,[a2])	;source
	putmsg	',FPn @'
	move.l	d1,-(sp)
	jbsr	printfpcrrprm
	addq.l	#4,sp
	putcrlf
	move.l	d3,-(sp)		;0=failed,1=successful
	move.l	d5,-(sp)		;expected status
	fmove.x	fp5,-(sp)		;expected result
	move.l	d7,-(sp)		;actual status
	fmove.x	fp7,-(sp)		;actual result
	jbsr	output_extended
	lea.l	36(sp),sp
@@:
;
	addq.l	#8,a4			;expected result
;
	add.w	#1<<4,d1		;rprm++
	cmp.w	#",DRP<<4,",d1		;fpcr=(XRN..DRP)<<4
	bls	11b
;
	addq.l	#4,a2			;source handle,...
	tst.l	(a2)			;source handle,...
	bpl	22b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts
	.cpu	68000

	.align	4
fmovedtoreg_data_compressed::
");
  push_start();
  for(i=1,#a,
      u=numtodbl(a[i],RN);  \\ソース
      push_indirect(8,u));
  push(4,-1);
  for(i=1,#a,
      u=numtodbl(a[i],RN);  \\ソース
      for(rprm=XRN,DRP,  \\(rp<<2)+rm。丸め桁数と丸めモード
          rp=bitand(rprm>>2,3);  \\丸め桁数
          rm=bitand(rprm,3);  \\丸めモード
          fpsr=0;
          y=dbltonum(u);
          if((rp==DBL)&&
             ((bitand(u,0x7FF0000000000000)==0)&&
              (bitand(u,0x000FFFFFFFFFFFFF)!=0)),
             fpsr=bitor(fpsr,UF));  \\丸め桁数がdoubleで非正規化数のときUFをセットする
          if(rp==SGL,
             if(type(y)!="t_POL",
                y=xxx(y,rp,rm)),
             y=roundxxx(y,rp,rm));
          fpsr_update_ccr(y);
          fpsr_update_aer();
          sr=fpsr;
          push_indirect(12,numtoexd(y,RN));
          push(4,sr)));
  push(4,-1);
  push_end()
  }


\\----------------------------------------------------------------------------------------
\\  FMOVE.L FPn,Dr
\\  FMOVE.L FPn,<mem>
\\----------------------------------------------------------------------------------------
make_fmovelregto()={
  my(a,x,u,rp,rm,sr);
  print("making fmovelregto");
  a=append(DATA_SPECIAL,
           DATA_FLOAT,
           DATA_BASIC,
           DATA_ROUND);
  a=vector(#a,n,exd(a[n],RN));
  a=uniq(sort(append(a,vector(#a,n,-a[n]),[NaN]),comparator),comparator);
  asm(
"
;--------------------------------------------------------------------------------
;	FMOVE.L FPn,Dr
;	FMOVE.L FPn,<mem>
;--------------------------------------------------------------------------------
	.cpu	68030
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
fmovelregto_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#MC68881+MC68882+MC68040+FPSP040+MC68060+FPSP060,-(sp)
	peamsg	'FMOVE.L FPN,<EA>'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: FMOVE.L FPn,<ea>',13,10
;------------------------------------------------
;	d1	actual result
;	d4	actual status
;	d6	fpcr=(XRN..DRP)<<4
;	d7	0=failed,1=successful
;	a0	expected result,expected status,...
;	a1	expected result
;	a4	expected status
;	a5	source handle,...
;	fp5	source
;------------------------------------------------
	lea.l	push_decompressed,a3
;decompress data
	move.l	a3,-(sp)
	pea.l	fmovelregto_data_compressed
	jbsr	decompress
	addq.l	#8,sp
;relocate decompressed handle
	move.l	#indirect_decompressed,d0
	movea.l	a3,a5			;source handle,...
@@:
	add.l	d0,(a3)+		;source handle
	tst.l	(a3)
	bpl	@b
	addq.l	#4,a3			;-1
	movea.l	a3,a0			;expected result,expected status,...
;
55:
	move.l	#",XRN<<4,",d6		;fpcr=(XRN..DRP)<<4
66:
;FPn,Dr
	fmove.l	#0,fpcr
	fmove.x	([a5]),fp5		;source
	fmove.l	d6,fpcr			;fpcr
	fmove.l	#0,fpsr
	move.l	#-1,d1			;fill=-1
					;source
	fmove.l	fp5,d1			;EXECUTE
					;actual result
	fmove.l	fpsr,d4			;actual status
	fmove.l	#0,fpcr
;
	movea.l	(a0),a1			;expected result
	movea.l	(4,a0),a4		;expected status
;
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	test_single
	lea.l	16(sp),sp
	move.l	d0,d7			;0=failed,1=successful
;
	move.l	d7,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FMOVE.L FPn='
	puthex24	([a5]),(4,[a5]),(8,[a5])	;source
	putmsg	',Dr @'
	move.l	d6,-(sp)		;fpcr
	jbsr	printfpcrrprm
	addq.l	#4,sp
	putcrlf
	move.l	d7,-(sp)		;0=failed,1=successful
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	output_single
	lea.l	20(sp),sp
@@:
;
	addq.l	#8,a0			;expected result,expected status,...
;FPn,<mem>
	fmove.l	#0,fpcr
	fmove.x	([a5]),fp5		;source
	fmove.l	d6,fpcr			;fpcr
	fmove.l	#0,fpsr
	move.l	#-1,-(sp)		;fill=-1
					;source
	fmove.l	fp5,(sp)		;EXECUTE
	move.l	(sp)+,d1		;actual result
	fmove.l	fpsr,d4			;actual status
	fmove.l	#0,fpcr
;
	movea.l	(a0),a1			;expected result
	movea.l	(4,a0),a4		;expected status
;
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	test_single
	lea.l	16(sp),sp
	move.l	d0,d7			;0=failed,1=successful
;
	move.l	d7,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FMOVE.L FPn='
	puthex24	([a5]),(4,[a5]),(8,[a5])	;source
	putmsg	',<mem> @'
	move.l	d6,-(sp)		;fpcr
	jbsr	printfpcrrprm
	addq.l	#4,sp
	putcrlf
	move.l	d7,-(sp)		;0=failed,1=successful
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	output_single
	lea.l	20(sp),sp
@@:
;
	addq.l	#8,a0			;expected result,expected status,...
;
	add.w	#1<<4,d6		;rprm++
	cmp.w	#",DRP<<4,",d6		;fpcr=(XRN..DRP)<<4
	bls	66b
;
	addq.l	#4,a5			;source handle
	tst.l	(a5)			;source handle
	bpl	55b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts
	.cpu	68000

	.align	4
fmovelregto_data_compressed::
");
  push_start();
  for(i=1,#a,
      x=a[i];  \\ソース
      push_indirect(12,numtoexd(x,RN)));
  push(4,-1);
  for(i=1,#a,
      x=a[i];  \\ソース
      for(rprm=XRN,DRP,  \\(rp<<2)+rm。丸め桁数と丸めモード
          rp=bitand(rprm>>2,3);  \\丸め桁数
          rm=bitand(rprm,3);  \\丸めモード
          fpsr=0;
          u=numtolong(x,rm);  \\longに変換する
          fpsr_update_aer();
          sr=fpsr;
          push(4,u);
          push(4,sr);
          push(4,u);
          push(4,sr)));
  push_end()
  }


\\----------------------------------------------------------------------------------------
\\  FMOVE.L Dr,FPn
\\  FMOVE.L <mem>,FPn
\\----------------------------------------------------------------------------------------
make_fmoveltoreg()={
  my(a,u,y,rp,rm,sr);
  print("making fmoveltoreg");
  a=DATA_LONG;
  asm(
"
;--------------------------------------------------------------------------------
;	FMOVE.L Dr,FPn
;	FMOVE.L <mem>,FPn
;--------------------------------------------------------------------------------
	.cpu	68030
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
fmoveltoreg_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#MC68881+MC68882+MC68040+FPSP040+MC68060+FPSP060,-(sp)
	peamsg	'FMOVE.L <EA>,FPN'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: FMOVE.L <ea>,FPn',13,10
;------------------------------------------------
;	d1	fpcr=(XRN..DRP)<<4
;	d2	source
;	d3	0=failed,1=successful
;	d5	expected status
;	d7	actual status
;	a2	source,...
;	a4	expected result handle,expected status,...
;	fp5	expected result
;	fp7	actual result
;------------------------------------------------
	lea.l	push_decompressed,a0
;decompress data
	move.l	a0,-(sp)
	pea.l	fmoveltoreg_data_compressed
	jbsr	decompress
	addq.l	#8,sp
;relocate decompressed handle
	move.l	#indirect_decompressed,d0
	movea.l	a0,a2			;source,...
@@:
	addq.l	#4,a0			;source
	tst.l	(a0)
	bne	@b
	addq.l	#4,a0			;0
	movea.l	a0,a4			;expected result handle,expected status,...
@@:
	add.l	d0,(a0)+		;expected result handle
	addq.l	#4,a0			;expected status
	tst.l	(a0)
	bpl	@b
;	addq.l	#4,a0			;-1
;
22:
	move.l	#",XRN<<4,",d1		;fpcr=(XRN..DRP)<<4
11:
;Dr,FPn
	fmove.l	#0,fpcr
	move.l	(a2),d2			;source
	fmove.s	#$7FFFFFFF,fp7		;fill=NaN
	fmove.l	d1,fpcr			;fpcr
	fmove.l	#0,fpsr
					;source
	fmove.l	d2,fp7			;EXECUTE
					;actual result
	fmove.l	fpsr,d7			;actual status
	fmove.l	#0,fpcr
;
	fmove.x	([a4]),fp5		;expected result
	move.l	(4,a4),d5		;expected status
;
	move.l	#-1,-(sp)		;fpcr(rp<<6,-1=strict)
	move.l	d5,-(sp)		;expected status
	fmove.x	fp5,-(sp)		;expected result
	move.l	d7,-(sp)		;actual status
	fmove.x	fp7,-(sp)		;actual result
	jbsr	test_extended
	lea.l	36(sp),sp
	move.l	d0,d3			;0=failed,1=successful
;
	move.l	d3,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FMOVE.L Dr='
	puthex8	d2			;source
	putmsg	',FPn @'
	move.l	d1,-(sp)
	jbsr	printfpcrrprm
	addq.l	#4,sp
	putcrlf
	move.l	d3,-(sp)		;0=failed,1=successful
	move.l	d5,-(sp)		;expected status
	fmove.x	fp5,-(sp)		;expected result
	move.l	d7,-(sp)		;actual status
	fmove.x	fp7,-(sp)		;actual result
	jbsr	output_extended
	lea.l	36(sp),sp
@@:
;
;<mem>,FPn
	fmove.l	#0,fpcr
	move.l	(a2),d2			;source
	fmove.s	#$7FFFFFFF,fp7		;fill=NaN
	fmove.l	d1,fpcr			;fpcr
	fmove.l	#0,fpsr
	move.l	d2,-(sp)		;source
	fmove.l	(sp)+,fp7		;EXECUTE
					;actual result
	fmove.l	fpsr,d7			;actual status
	fmove.l	#0,fpcr
;
	fmove.x	([a4]),fp5		;expected result
	move.l	(4,a4),d5		;expected status
;
	move.l	#-1,-(sp)		;fpcr(rp<<6,-1=strict)
	move.l	d5,-(sp)		;expected status
	fmove.x	fp5,-(sp)		;expected result
	move.l	d7,-(sp)		;actual status
	fmove.x	fp7,-(sp)		;actual result
	jbsr	test_extended
	lea.l	36(sp),sp
	move.l	d0,d3			;0=failed,1=successful
;
	move.l	d3,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FMOVE.L <mem>='
	puthex8	d2			;source
	putmsg	',FPn @'
	move.l	d1,-(sp)
	jbsr	printfpcrrprm
	addq.l	#4,sp
	putcrlf
	move.l	d3,-(sp)		;0=failed,1=successful
	move.l	d5,-(sp)		;expected status
	fmove.x	fp5,-(sp)		;expected result
	move.l	d7,-(sp)		;actual status
	fmove.x	fp7,-(sp)		;actual result
	jbsr	output_extended
	lea.l	36(sp),sp
@@:
;
	addq.l	#8,a4			;expected result
;
	add.w	#1<<4,d1		;rprm++
	cmp.w	#",DRP<<4,",d1		;fpcr=(XRN..DRP)<<4
	bls	11b
;
	addq.l	#4,a2			;source
	tst.l	(a2)			;source
	bne	22b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts
	.cpu	68000

	.align	4
fmoveltoreg_data_compressed::
");
  push_start();
  for(i=1,#a,
      u=a[i];  \\ソース
      push(4,u));
  push(4,0);
  for(i=1,#a,
      u=a[i];  \\ソース
      for(rprm=XRN,DRP,  \\(rp<<2)+rm。丸め桁数と丸めモード
          rp=bitand(rprm>>2,3);  \\丸め桁数
          rm=bitand(rprm,3);  \\丸めモード
          fpsr=0;
          y=longtonum(u);
          y=roundxxx(y,rp,rm);
          fpsr_update_ccr(y);
          fpsr_update_aer();
          sr=fpsr;
          push_indirect(12,numtoexd(y,RN));
          push(4,sr)));
  push(4,-1);
  push_end()
  }


\\----------------------------------------------------------------------------------------
\\  FMOVE.P FPn,<mem>{#k}
\\  FMOVE.P FPn,<mem>{Dk}
\\----------------------------------------------------------------------------------------
make_fmovepregto()={
  my(name="fmovepregto",a,x,u,rp,rm,sr);
  print("making ",name);
  a=append(DATA_SPECIAL,
           DATA_FLOAT,
           DATA_BASIC,
           DATA_PACKED);
  a=vector(#a,n,exd(a[n],RN));
  a=uniq(sort(append(a,vector(#a,n,-a[n]),[NaN]),comparator),comparator);
  asm(
"
;--------------------------------------------------------------------------------
;	FMOVE.P FPn,<mem>{#k}
;	FMOVE.P FPn,<mem>{Dk}
;--------------------------------------------------------------------------------
	.cpu	68030
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
",name,"_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#MC68881+MC68882+FPSP040+FPSP060,-(sp)
	peamsg	'FMOVE.P FPN,<EA>'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: FMOVE.P FPn,<ea>',13,10
;------------------------------------------------
;	d1-d3	actual result
;	d4	actual status
;	d5	0=failed,1=successful
;	d6	fpcr=(XRN..XRP)<<4
;	d7	k-factor=-18..18
;	a0	expected result handle,expected status,...
;	a1-a3	expected result
;	a4	expected status
;	a5	source handle,...
;	fp5	source
;------------------------------------------------
	lea.l	push_decompressed,a3
;decompress data
	move.l	a3,-(sp)
	pea.l	",name,"_data_compressed
	jbsr	decompress
	addq.l	#8,sp
;relocate decompressed handle
	move.l	#indirect_decompressed,d0
	movea.l	a3,a5			;source handle,...
@@:
	add.l	d0,(a3)+		;source handle
	tst.l	(a3)
	bpl	@b
	addq.l	#4,a3			;-1
	movea.l	a3,a0			;expected result handle,expected status,...
@@:
	add.l	d0,(a3)+		;expected result handle
	addq.l	#4,a3			;expected status
	tst.l	(a3)
	bpl	@b
;	addq.l	#4,a3			;-1
;
55:
	move.l	#",XRN<<4,",d6		;fpcr=(XRN..XRP)<<4
66:
	moveq.l	#-18,d7			;k-factor=-18..18
77:
;FPn,<mem>{#k}
	fmove.l	#0,fpcr
	fmove.x	([a5]),fp5		;source
	fmove.l	d6,fpcr			;fpcr
	fmove.l	#0,fpsr
	move.l	#-1,-(sp)		;fill=-1
	move.l	#-1,-(sp)
	move.l	#-1,-(sp)
					;k-factor
					;execute
	jsr	(",name,"_execute+18*8,pc,d7.l*8)	;EXECUTE
	movem.l	(sp)+,d1-d3		;actual result
	fmove.l	fpsr,d4			;actual status
	fmove.l	#0,fpcr
;
	movem.l	([a0]),a1-a3		;expected result
	movea.l	(4,a0),a4		;expected status
;
	movem.l	d1-d4/a1-a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	test_packed
	lea.l	32(sp),sp
	move.l	d0,d5			;0=failed,1=successful
;
	move.l	d5,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FMOVE.P FPn='
	puthex24	([a5]),(4,[a5]),(8,[a5])	;source
	putmsg	',<mem>{#'
	putlong	d7			;k-factor
	putmsg	'} @'
	move.l	d6,-(sp)		;fpcr
	jbsr	printfpcrrprm
	addq.l	#4,sp
	putcrlf
	move.l	d5,-(sp)		;0=failed,1=successful
	movem.l	d1-d4/a1-a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	output_packed
	lea.l	36(sp),sp
@@:
;
;FPn,<mem>{Dk}
	fmove.l	#0,fpcr
	fmove.x	([a5]),fp5		;source
	fmove.l	d6,fpcr			;fpcr
	fmove.l	#0,fpsr
	move.l	#-1,-(sp)		;fill=-1
	move.l	#-1,-(sp)
	move.l	#-1,-(sp)
					;source
	fmove.p	fp5,(sp){d7}		;EXECUTE
	movem.l	(sp)+,d1-d3		;actual result
	fmove.l	fpsr,d4			;actual status
	fmove.l	#0,fpcr
;
	movem.l	([a0]),a1-a3		;expected result
	movea.l	(4,a0),a4		;expected status
;
	movem.l	d1-d4/a1-a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	test_packed
	lea.l	32(sp),sp
	move.l	d0,d5			;0=failed,1=successful
;
	move.l	d5,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FMOVE.P FPn='
	puthex24	([a5]),(4,[a5]),(8,[a5])	;source
	putmsg	',<mem>{Dr='
	putlong	d7			;k-factor
	putmsg	'} @'
	move.l	d6,-(sp)		;fpcr
	jbsr	printfpcrrprm
	addq.l	#4,sp
	putcrlf
	move.l	d5,-(sp)		;0=failed,1=successful
	movem.l	d1-d4/a1-a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	output_packed
	lea.l	36(sp),sp
@@:
;
	addq.l	#8,a0			;expected result handle,expected status,...
;
	addq.l	#1,d7			;k-factor++
	cmp.l	#18,d7			;k-factor=-18..18
	ble	77b			;signed
;
	add.w	#1<<4,d6		;rprm++
	cmp.w	#",XRP<<4,",d6		;fpcr=(XRN..XRP)<<4
	bls	66b
;
	addq.l	#4,a5			;source handle,...
	tst.l	(a5)			;source handle,...
	bpl	55b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts

",name,"_execute::
");
  for(k=-18,18,  \\k-factor
      asmln("	fmove.p	fp5,(4,sp){#",k,"}");
      asmln("	rts"));
  asm(
"	.cpu	68000

	.align	4
",name,"_data_compressed::
");
  push_start();
  for(i=1,#a,
      x=a[i];  \\ソース
      push_indirect(12,numtoexd(x,RN)));
  push(4,-1);
  for(i=1,#a,
      x=a[i];  \\ソース
      for(rprm=XRN,XRP,  \\(rp<<2)+rm。丸め桁数と丸めモード。extendedのみ
          rp=bitand(rprm>>2,3);  \\丸め桁数
          rm=bitand(rprm,3);  \\丸めモード
          for(k=-18,18,  \\k-factor
              fpsr=0;
              u=numtopkd2(x,k,rm);  \\packedに変換する
              fpsr_update_aer();
              sr=fpsr;
              push_indirect(12,u);
              push(4,sr))));
  push(4,-1);
  push_end()
  }


\\----------------------------------------------------------------------------------------
\\  FMOVE.P <mem>,FPn
\\----------------------------------------------------------------------------------------
make_fmoveptoreg()={
  my(a,u,y,rp,rm,sr);
  print("making fmoveptoreg");
  a=append(DATA_SPECIAL,
           DATA_FLOAT,
           DATA_BASIC,
           DATA_ROUND,
           DATA_PACKED);
  a=vector(#a,n,pkd(a[n]));
  a=uniq(sort(append(a,vector(#a,n,-a[n]),[NaN]),comparator),comparator);
  asm(
"
;--------------------------------------------------------------------------------
;	FMOVE.P <mem>,FPn
;--------------------------------------------------------------------------------
	.cpu	68030
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
fmoveptoreg_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#MC68881+MC68882+FPSP040+FPSP060,-(sp)
	peamsg	'FMOVE.P <EA>,FPN'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: FMOVE.P <ea>,FPn',13,10
;------------------------------------------------
;	d1	fpcr=(XRN..DRP)<<4
;	d3	0=failed,1=successful
;	d5	expected status
;	d7	actual status
;	a2	source handle,...
;	a4	expected result handle,expected status,...
;	fp5	expected result
;	fp7	actual result
;------------------------------------------------
	lea.l	push_decompressed,a0
;decompress data
	move.l	a0,-(sp)
	pea.l	fmoveptoreg_data_compressed
	jbsr	decompress
	addq.l	#8,sp
;relocate decompressed handle
	move.l	#indirect_decompressed,d0
	movea.l	a0,a2			;source handle,...
@@:
	add.l	d0,(a0)+		;source handle
	tst.l	(a0)
	bpl	@b
	addq.l	#4,a0			;-1
	movea.l	a0,a4			;expected result handle,expected status,...
@@:
	add.l	d0,(a0)+		;expected result handle
	addq.l	#4,a0			;expected status
	tst.l	(a0)
	bpl	@b
;	addq.l	#4,a0			;-1
;
22:
	move.l	#",XRN<<4,",d1		;fpcr=(XRN..DRP)<<4
11:
;<mem>,FPn
	fmove.l	#0,fpcr
	fmove.s	#$7FFFFFFF,fp7		;fill=NaN
	fmove.l	d1,fpcr			;fpcr
	fmove.l	#0,fpsr
					;source
	fmove.p	([a2]),fp7		;EXECUTE
					;actual result
	fmove.l	fpsr,d7			;actual status
	fmove.l	#0,fpcr
;
	fmove.x	([a4]),fp5		;expected result
	move.l	(4,a4),d5		;expected status
;
	move.l	d1,-(sp)		;fpcr(rp<<6,-1=strict)
	move.l	d5,-(sp)		;expected status
	fmove.x	fp5,-(sp)		;expected result
	move.l	d7,-(sp)		;actual status
	fmove.x	fp7,-(sp)		;actual result
	jbsr	test_extended
	lea.l	36(sp),sp
	move.l	d0,d3			;0=failed,1=successful
;
	move.l	d3,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FMOVE.P <mem>='
	puthex24	([a2]),(4,[a2]),(8,[a2])	;source
	putmsg	',FPn @'
	move.l	d1,-(sp)
	jbsr	printfpcrrprm
	addq.l	#4,sp
	putcrlf
	move.l	d3,-(sp)		;0=failed,1=successful
	move.l	d5,-(sp)		;expected status
	fmove.x	fp5,-(sp)		;expected result
	move.l	d7,-(sp)		;actual status
	fmove.x	fp7,-(sp)		;actual result
	jbsr	output_extended
	lea.l	36(sp),sp
@@:
;
	addq.l	#8,a4			;expected result
;
	add.w	#1<<4,d1		;rprm++
	cmp.w	#",DRP<<4,",d1		;fpcr=(XRN..DRP)<<4
	bls	11b
;
	addq.l	#4,a2			;source handle,...
	tst.l	(a2)			;source handle,...
	bpl	22b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts
	.cpu	68000

	.align	4
fmoveptoreg_data_compressed::
");
  push_start();
  for(i=1,#a,
      u=numtopkd(a[i],17,RN);  \\ソース
      push_indirect(12,u));
  push(4,-1);
  for(i=1,#a,
      u=numtopkd(a[i],17,RN);  \\ソース
      for(rprm=XRN,DRP,  \\(rp<<2)+rm。丸め桁数と丸めモード
          rp=bitand(rprm>>2,3);  \\丸め桁数
          rm=bitand(rprm,3);  \\丸めモード
          fpsr=0;
          y=pkdtoxxx(u,rp,rm);
          fpsr_update_ccr(y);
          fpsr_update_aer();
          sr=fpsr;
          push_indirect(12,numtoexd(y,RN));
          push(4,sr)));
  push(4,-1);
  push_end()
  }


\\----------------------------------------------------------------------------------------
\\  FMOVE.S FPn,Dr
\\  FMOVE.S FPn,<mem>
\\----------------------------------------------------------------------------------------
make_fmovesregto()={
  my(a,x,u,rp,rm,sr);
  print("making fmovesregto");
  a=append(DATA_SPECIAL,
           DATA_FLOAT,
           DATA_BASIC,
           DATA_ROUND);
  a=vector(#a,n,exd(a[n],RN));
  a=uniq(sort(append(a,vector(#a,n,-a[n]),[NaN]),comparator),comparator);
  asm(
"
;--------------------------------------------------------------------------------
;	FMOVE.S FPn,Dr
;	FMOVE.S FPn,<mem>
;--------------------------------------------------------------------------------
	.cpu	68030
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
fmovesregto_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#MC68881+MC68882+MC68040+FPSP040+MC68060+FPSP060,-(sp)
	peamsg	'FMOVE.S FPN,<EA>'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: FMOVE.S FPn,<ea>',13,10
;------------------------------------------------
;	d1	actual result
;	d4	actual status
;	d6	fpcr=(XRN..DRP)<<4
;	d7	0=failed,1=successful
;	a0	expected result,expected status,...
;	a1	expected result
;	a4	expected status
;	a5	source handle,...
;	fp5	source
;------------------------------------------------
	lea.l	push_decompressed,a3
;decompress data
	move.l	a3,-(sp)
	pea.l	fmovesregto_data_compressed
	jbsr	decompress
	addq.l	#8,sp
;relocate decompressed handle
	move.l	#indirect_decompressed,d0
	movea.l	a3,a5			;source handle,...
@@:
	add.l	d0,(a3)+		;source handle
	tst.l	(a3)
	bpl	@b
	addq.l	#4,a3			;-1
	movea.l	a3,a0			;expected result,expected status,...
;
55:
	move.l	#",XRN<<4,",d6		;fpcr=(XRN..DRP)<<4
66:
;FPn,Dr
	fmove.l	#0,fpcr
	fmove.x	([a5]),fp5		;source
	fmove.l	d6,fpcr			;fpcr
	fmove.l	#0,fpsr
	move.l	#-1,d1			;fill=-1
					;source
	fmove.s	fp5,d1			;EXECUTE
					;actual result
	fmove.l	fpsr,d4			;actual status
	fmove.l	#0,fpcr
;
	movea.l	(a0),a1			;expected result
	movea.l	(4,a0),a4		;expected status
;
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	test_single
	lea.l	16(sp),sp
	move.l	d0,d7			;0=failed,1=successful
;
	move.l	d7,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FMOVE.S FPn='
	puthex24	([a5]),(4,[a5]),(8,[a5])	;source
	putmsg	',Dr @'
	move.l	d6,-(sp)		;fpcr
	jbsr	printfpcrrprm
	addq.l	#4,sp
	putcrlf
	move.l	d7,-(sp)		;0=failed,1=successful
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	output_single
	lea.l	20(sp),sp
@@:
;
;FPn,<mem>
	fmove.l	#0,fpcr
	fmove.x	([a5]),fp5		;source
	fmove.l	d6,fpcr			;fpcr
	fmove.l	#0,fpsr
	move.l	#-1,-(sp)		;fill=-1
					;source
	fmove.s	fp5,(sp)		;EXECUTE
	move.l	(sp)+,d1		;actual result
	fmove.l	fpsr,d4			;actual status
	fmove.l	#0,fpcr
;
	movea.l	(a0),a1			;expected result
	movea.l	(4,a0),a4		;expected status
;
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	test_single
	lea.l	16(sp),sp
	move.l	d0,d7			;0=failed,1=successful
;
	move.l	d7,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FMOVE.S FPn='
	puthex24	([a5]),(4,[a5]),(8,[a5])	;source
	putmsg	',<mem> @'
	move.l	d6,-(sp)		;fpcr
	jbsr	printfpcrrprm
	addq.l	#4,sp
	putcrlf
	move.l	d7,-(sp)		;0=failed,1=successful
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	output_single
	lea.l	20(sp),sp
@@:
;
	addq.l	#8,a0			;expected
;
	add.w	#1<<4,d6		;rprm++
	cmp.w	#",DRP<<4,",d6		;fpcr=(XRN..DRP)<<4
	bls	66b
;
	addq.l	#4,a5			;source handle
	tst.l	(a5)			;source handle
	bpl	55b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts
	.cpu	68000

	.align	4
fmovesregto_data_compressed::
");
  push_start();
  for(i=1,#a,
      x=a[i];  \\ソース
      push_indirect(12,numtoexd(x,RN)));
  push(4,-1);
  for(i=1,#a,
      x=a[i];  \\ソース
      for(rprm=XRN,DRP,  \\(rp<<2)+rm。丸め桁数と丸めモード
          rp=bitand(rprm>>2,3);  \\丸め桁数
          rm=bitand(rprm,3);  \\丸めモード
          fpsr=0;
          u=numtosgl(x,if(type(x)=="t_POL",RN,rm));  \\singleに変換する
          fpsr_update_aer();
          sr=fpsr;
          push(4,u);
          push(4,sr)));
  push_end()
  }


\\----------------------------------------------------------------------------------------
\\  FMOVE.S Dr,FPn
\\  FMOVE.S <mem>,FPn
\\----------------------------------------------------------------------------------------
make_fmovestoreg()={
  my(a,u,y,rp,rm,sr);
  print("making fmovestoreg");
  a=append(DATA_SPECIAL,
           DATA_SINGLE,
           DATA_BASIC,
           DATA_ROUND);
  a=vector(#a,n,sgl(a[n],RN));
  a=uniq(sort(append(a,vector(#a,n,-a[n]),[NaN]),comparator),comparator);
  asm(
"
;--------------------------------------------------------------------------------
;	FMOVE.S Dr,FPn
;	FMOVE.S <mem>,FPn
;--------------------------------------------------------------------------------
	.cpu	68030
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
fmovestoreg_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#MC68881+MC68882+MC68040+FPSP040+MC68060+FPSP060,-(sp)
	peamsg	'FMOVE.S <EA>,FPN'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: FMOVE.S <ea>,FPn',13,10
;------------------------------------------------
;	d1	fpcr=(XRN..DRP)<<4
;	d2	source
;	d3	0=failed,1=successful
;	d5	expected status
;	d7	actual status
;	a2	source,...
;	a4	expected result handle,expected status,...
;	fp5	expected result
;	fp7	actual result
;------------------------------------------------
	lea.l	push_decompressed,a0
;decompress data
	move.l	a0,-(sp)
	pea.l	fmovestoreg_data_compressed
	jbsr	decompress
	addq.l	#8,sp
;relocate decompressed handle
	move.l	#indirect_decompressed,d0
	movea.l	a0,a2			;source,...
@@:
	addq.l	#4,a0			;source
	cmpi.l	#$FF800000,(a0)		;-Inf
	bne	@b
	addq.l	#4,a0			;0
	movea.l	a0,a4			;expected result handle,expected status,...
@@:
	add.l	d0,(a0)+		;expected result handle
	addq.l	#4,a0			;expected status
	tst.l	(a0)
	bpl	@b
;	addq.l	#4,a0			;-1
;
22:
	move.l	#",XRN<<4,",d1		;fpcr=(XRN..DRP)<<4
11:
;Dr,FPn
	fmove.l	#0,fpcr
	move.l	(a2),d2			;source
	fmove.s	#$7FFFFFFF,fp7		;fill=NaN
	fmove.l	d1,fpcr			;fpcr
	fmove.l	#0,fpsr
					;source
	fmove.s	d2,fp7			;EXECUTE
					;actual result
	fmove.l	fpsr,d7			;actual status
	fmove.l	#0,fpcr
;
	fmove.x	([a4]),fp5		;expected result
	move.l	(4,a4),d5		;expected status
;
	move.l	#-1,-(sp)		;fpcr(rp<<6,-1=strict)
	move.l	d5,-(sp)		;expected status
	fmove.x	fp5,-(sp)		;expected result
	move.l	d7,-(sp)		;actual status
	fmove.x	fp7,-(sp)		;actual result
	jbsr	test_extended
	lea.l	36(sp),sp
	move.l	d0,d3			;0=failed,1=successful
;
	move.l	d3,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FMOVE.S Dr='
	puthex8	d2			;source
	putmsg	',FPn @'
	move.l	d1,-(sp)
	jbsr	printfpcrrprm
	addq.l	#4,sp
	putcrlf
	move.l	d3,-(sp)		;0=failed,1=successful
	move.l	d5,-(sp)		;expected status
	fmove.x	fp5,-(sp)		;expected result
	move.l	d7,-(sp)		;actual status
	fmove.x	fp7,-(sp)		;actual result
	jbsr	output_extended
	lea.l	36(sp),sp
@@:
;
;<mem>,FPn
	fmove.l	#0,fpcr
	move.l	(a2),d2			;source
	fmove.s	#$7FFFFFFF,fp7		;fill=NaN
	fmove.l	d1,fpcr			;fpcr
	fmove.l	#0,fpsr
	move.l	d2,-(sp)		;source
	fmove.s	(sp)+,fp7		;EXECUTE
					;actual result
	fmove.l	fpsr,d7			;actual status
	fmove.l	#0,fpcr
;
	fmove.x	([a4]),fp5		;expected result
	move.l	(4,a4),d5		;expected status
;
	move.l	#-1,-(sp)		;fpcr(rp<<6,-1=strict)
	move.l	d5,-(sp)		;expected status
	fmove.x	fp5,-(sp)		;expected result
	move.l	d7,-(sp)		;actual status
	fmove.x	fp7,-(sp)		;actual result
	jbsr	test_extended
	lea.l	36(sp),sp
	move.l	d0,d3			;0=failed,1=successful
;
	move.l	d3,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FMOVE.S <mem>='
	puthex8	d2			;source
	putmsg	',FPn @'
	move.l	d1,-(sp)
	jbsr	printfpcrrprm
	addq.l	#4,sp
	putcrlf
	move.l	d3,-(sp)		;0=failed,1=successful
	move.l	d5,-(sp)		;expected status
	fmove.x	fp5,-(sp)		;expected result
	move.l	d7,-(sp)		;actual status
	fmove.x	fp7,-(sp)		;actual result
	jbsr	output_extended
	lea.l	36(sp),sp
@@:
;
	addq.l	#8,a4			;expected result
;
	add.w	#1<<4,d1		;rprm++
	cmp.w	#",DRP<<4,",d1		;fpcr=(XRN..DRP)<<4
	bls	11b
;
	addq.l	#4,a2			;source,...
	cmpi.l	#$FF800000,(a2)		;source,.... -Inf
	bne	22b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts
	.cpu	68000

	.align	4
fmovestoreg_data_compressed::
");
  push_start();
  for(i=1,#a,
      u=numtosgl(a[i],RN);  \\ソース
      push(4,u));
  push(4,0xFF800000);  \\-Inf。昇順にソートされているので途中に出てくる0を番兵にできない。先頭は-Infなので-Infを番兵にする
  for(i=1,#a,
      u=numtosgl(a[i],RN);  \\ソース
      for(rprm=XRN,DRP,  \\(rp<<2)+rm。丸め桁数と丸めモード
          rp=bitand(rprm>>2,3);  \\丸め桁数
          rm=bitand(rprm,3);  \\丸めモード
          fpsr=0;
          y=sgltonum(u);
          if((rp==SGL)&&
             ((bitand(u,0x7F800000)==0)&&
              (bitand(u,0x007FFFFF)!=0)),
             fpsr=bitor(fpsr,UF));  \\丸め桁数がsingleで非正規化数のときUFをセットする
          y=roundxxx(y,rp,rm);
          fpsr_update_ccr(y);
          fpsr_update_aer();
          sr=fpsr;
          push_indirect(12,numtoexd(y,RN));
          push(4,sr)));
  push(4,-1);
  push_end()
  }


\\----------------------------------------------------------------------------------------
\\  FMOVE.W FPn,Dr
\\  FMOVE.W FPn,<mem>
\\----------------------------------------------------------------------------------------
make_fmovewregto()={
  my(a,x,u,rp,rm,sr);
  print("making fmovewregto");
  a=append(DATA_SPECIAL,
           DATA_FLOAT,
           DATA_BASIC,
           DATA_ROUND);
  a=vector(#a,n,exd(a[n],RN));
  a=uniq(sort(append(a,vector(#a,n,-a[n]),[NaN]),comparator),comparator);
  asm(
"
;--------------------------------------------------------------------------------
;	FMOVE.W FPn,Dr
;	FMOVE.W FPn,<mem>
;--------------------------------------------------------------------------------
	.cpu	68030
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
fmovewregto_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#MC68881+MC68882+MC68040+FPSP040+MC68060+FPSP060,-(sp)
	peamsg	'FMOVE.W FPN,<EA>'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: FMOVE.W FPn,<ea>',13,10
;------------------------------------------------
;	d1	actual result
;	d3	fill=$00000000,$FFFFFFFF
;	d4	actual status
;	d6	fpcr=(XRN..DRP)<<4
;	d7	0=failed,1=successful
;	a0	expected result,expected status,...
;	a1	expected result
;	a4	expected status
;	a5	source handle,...
;	fp5	source
;------------------------------------------------
	lea.l	push_decompressed,a3
;decompress data
	move.l	a3,-(sp)
	pea.l	fmovewregto_data_compressed
	jbsr	decompress
	addq.l	#8,sp
;relocate decompressed handle
	move.l	#indirect_decompressed,d0
	movea.l	a3,a5			;source handle,...
@@:
	add.l	d0,(a3)+		;source handle
	tst.l	(a3)
	bpl	@b
	addq.l	#4,a3			;-1
	movea.l	a3,a0			;expected result,expected status,...
;
55:
	move.l	#",XRN<<4,",d6		;fpcr=(XRN..DRP)<<4
66:
;FPn,Dr=fill
	moveq.l	#$00000000,d3		;fill=$00000000,$FFFFFFFF
33:
	fmove.l	#0,fpcr
	fmove.x	([a5]),fp5		;source
	fmove.l	d6,fpcr			;fpcr
	fmove.l	#0,fpsr
	move.l	d3,d1			;fill
					;source
	fmove.w	fp5,d1			;EXECUTE
					;actual result
	fmove.l	fpsr,d4			;actual status
	fmove.l	#0,fpcr
;
	movea.l	(a0),a1			;expected result
	movea.l	(4,a0),a4		;expected status
;
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	test_single
	lea.l	16(sp),sp
	move.l	d0,d7			;0=failed,1=successful
;
	move.l	d7,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FMOVE.W FPn='
	puthex24	([a5]),(4,[a5]),(8,[a5])	;source
	putmsg	',Dr='
	puthex8	d3			;fill
	putmsg	' @'
	move.l	d6,-(sp)		;fpcr
	jbsr	printfpcrrprm
	addq.l	#4,sp
	putcrlf
	move.l	d7,-(sp)		;0=failed,1=successful
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	output_single
	lea.l	20(sp),sp
@@:
;
	addq.l	#8,a0			;expected result,expected status,...
;
	not.l	d3			;fill
	bne	33b
;FPn,<mem>=fill
	moveq.l	#$00000000,d3		;fill=$00000000,$FFFFFFFF
33:
	fmove.l	#0,fpcr
	fmove.x	([a5]),fp5		;source
	fmove.l	d6,fpcr			;fpcr
	fmove.l	#0,fpsr
	move.l	d3,-(sp)		;fill
					;source
	fmove.w	fp5,(sp)		;EXECUTE
	move.l	(sp)+,d1		;actual result
	fmove.l	fpsr,d4			;actual status
	fmove.l	#0,fpcr
;
	movea.l	(a0),a1			;expected result
	movea.l	(4,a0),a4		;expected status
;
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	test_single
	lea.l	16(sp),sp
	move.l	d0,d7			;0=failed,1=successful
;
	move.l	d7,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FMOVE.W FPn='
	puthex24	([a5]),(4,[a5]),(8,[a5])	;source
	putmsg	',<mem>='
	puthex8	d3			;fill
	putmsg	' @'
	move.l	d6,-(sp)		;fpcr
	jbsr	printfpcrrprm
	addq.l	#4,sp
	putcrlf
	move.l	d7,-(sp)		;0=failed,1=successful
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	output_single
	lea.l	20(sp),sp
@@:
;
	addq.l	#8,a0			;expected result,expected status,...
;
	not.l	d3			;fill
	bne	33b
;
	add.w	#1<<4,d6		;rprm++
	cmp.w	#",DRP<<4,",d6		;fpcr=(XRN..DRP)<<4
	bls	66b
;
	addq.l	#4,a5			;source handle
	tst.l	(a5)			;source handle
	bpl	55b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts
	.cpu	68000

	.align	4
fmovewregto_data_compressed::
");
  push_start();
  for(i=1,#a,
      x=a[i];  \\ソース
      push_indirect(12,numtoexd(x,RN)));
  push(4,-1);
  for(i=1,#a,
      x=a[i];  \\ソース
      for(rprm=XRN,DRP,  \\(rp<<2)+rm。丸め桁数と丸めモード
          rp=bitand(rprm>>2,3);  \\丸め桁数
          rm=bitand(rprm,3);  \\丸めモード
          fpsr=0;
          u=numtoword(x,rm);  \\wordに変換する
          fpsr_update_aer();
          sr=fpsr;
          push(4,0x00000000+u);
          push(4,sr);
          push(4,0xFFFF0000+u);
          push(4,sr);
          push(4,(u<<16)+0x0000);
          push(4,sr);
          push(4,(u<<16)+0xFFFF);
          push(4,sr)));
  push_end()
  }


\\----------------------------------------------------------------------------------------
\\  FMOVE.W Dr,FPn
\\  FMOVE.W <mem>,FPn
\\----------------------------------------------------------------------------------------
make_fmovewtoreg()={
  my(a,u,y,rp,rm,sr);
  print("making fmovewtoreg");
  a=DATA_WORD;
  asm(
"
;--------------------------------------------------------------------------------
;	FMOVE.W Dr,FPn
;	FMOVE.W <mem>,FPn
;--------------------------------------------------------------------------------
	.cpu	68030
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
fmovewtoreg_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#MC68881+MC68882+MC68040+FPSP040+MC68060+FPSP060,-(sp)
	peamsg	'FMOVE.W <EA>,FPN'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: FMOVE.W <ea>,FPn',13,10
;------------------------------------------------
;	d1	fpcr=(XRN..DRP)<<4
;	d2	source
;	d3	0=failed,1=successful
;	d5	expected status
;	d7	actual status
;	a2	source,...
;	a4	expected result handle,expected status,...
;	fp5	expected result
;	fp7	actual result
;------------------------------------------------
	lea.l	push_decompressed,a0
;decompress data
	move.l	a0,-(sp)
	pea.l	fmovewtoreg_data_compressed
	jbsr	decompress
	addq.l	#8,sp
;relocate decompressed handle
	move.l	#indirect_decompressed,d0
	movea.l	a0,a2			;source,...
@@:
	addq.l	#4,a0			;source
	tst.l	(a0)
	bne	@b
	addq.l	#4,a0			;0
	movea.l	a0,a4			;expected result handle,expected status,...
@@:
	add.l	d0,(a0)+		;expected result handle
	addq.l	#4,a0			;expected status
	tst.l	(a0)
	bpl	@b
;	addq.l	#4,a0			;-1
;
22:
	move.l	#",XRN<<4,",d1		;fpcr=(XRN..DRP)<<4
11:
;Dr,FPn
	fmove.l	#0,fpcr
	moveq.l	#0,d2
	move.w	(a2),d2			;source
	fmove.s	#$7FFFFFFF,fp7		;fill=NaN
	fmove.l	d1,fpcr			;fpcr
	fmove.l	#0,fpsr
					;source
	fmove.w	d2,fp7			;EXECUTE
					;actual result
	fmove.l	fpsr,d7			;actual status
	fmove.l	#0,fpcr
;
	fmove.x	([a4]),fp5		;expected result
	move.l	(4,a4),d5		;expected status
;
	move.l	d1,-(sp)		;fpcr
	move.l	d5,-(sp)		;expected status
	fmove.x	fp5,-(sp)		;expected result
	move.l	d7,-(sp)		;actual status
	fmove.x	fp7,-(sp)		;actual result
	jbsr	test_extended
	lea.l	36(sp),sp
	move.l	d0,d3			;0=failed,1=successful
;
	move.l	d3,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FMOVE.W Dr='
	puthex4	d2			;source
	putmsg	',FPn @'
	move.l	d1,-(sp)
	jbsr	printfpcrrprm
	addq.l	#4,sp
	putcrlf
	move.l	d3,-(sp)		;0=failed,1=successful
	move.l	d5,-(sp)		;expected status
	fmove.x	fp5,-(sp)		;expected result
	move.l	d7,-(sp)		;actual status
	fmove.x	fp7,-(sp)		;actual result
	jbsr	output_extended
	lea.l	36(sp),sp
@@:
;
;<mem>,FPn
	fmove.l	#0,fpcr
	moveq.l	#0,d2
	move.w	(a2),d2			;source
	fmove.s	#$7FFFFFFF,fp7		;fill=NaN
	fmove.l	d1,fpcr			;fpcr
	fmove.l	#0,fpsr
	move.w	d2,-(sp)		;source
	fmove.w	(sp)+,fp7		;EXECUTE
					;actual result
	fmove.l	fpsr,d7			;actual status
	fmove.l	#0,fpcr
;
	fmove.x	([a4]),fp5		;expected result
	move.l	(4,a4),d5		;expected status
;
	move.l	#-1,-(sp)		;fpcr(rp<<6,-1=strict)
	move.l	d5,-(sp)		;expected status
	fmove.x	fp5,-(sp)		;expected result
	move.l	d7,-(sp)		;actual status
	fmove.x	fp7,-(sp)		;actual result
	jbsr	test_extended
	lea.l	36(sp),sp
	move.l	d0,d3			;0=failed,1=successful
;
	move.l	d3,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FMOVE.W <mem>='
	puthex4	d2			;source
	putmsg	',FPn @'
	move.l	d1,-(sp)
	jbsr	printfpcrrprm
	addq.l	#4,sp
	putcrlf
	move.l	d3,-(sp)		;0=failed,1=successful
	move.l	d5,-(sp)		;expected status
	fmove.x	fp5,-(sp)		;expected result
	move.l	d7,-(sp)		;actual status
	fmove.x	fp7,-(sp)		;actual result
	jbsr	output_extended
	lea.l	36(sp),sp
@@:
;
	addq.l	#8,a4			;expected result
;
	add.w	#1<<4,d1		;rprm++
	cmp.w	#",DRP<<4,",d1		;fpcr=(XRN..DRP)<<4
	bls	11b
;
	addq.l	#4,a2			;source
	tst.l	(a2)			;source
	bne	22b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts
	.cpu	68000

	.align	4
fmovewtoreg_data_compressed::
");
  push_start();
  for(i=1,#a,
      u=a[i];  \\ソース
      push(2,u);
      push(2,0));
  push(4,0);
  for(i=1,#a,
      u=a[i];  \\ソース
      for(rprm=XRN,DRP,  \\(rp<<2)+rm。丸め桁数と丸めモード
          rp=bitand(rprm>>2,3);  \\丸め桁数
          rm=bitand(rprm,3);  \\丸めモード
          fpsr=0;
          y=wordtonum(u);
          y=roundxxx(y,rp,rm);
          fpsr_update_ccr(y);
          fpsr_update_aer();
          sr=fpsr;
          push_indirect(12,numtoexd(y,RN));
          push(4,sr)));
  push(4,-1);
  push_end()
  }


\\----------------------------------------------------------------------------------------
\\  FMOVE.X FPn,<mem>
\\----------------------------------------------------------------------------------------
make_fmovexregto()={
  my(a,x,u,rp,rm,sr);
  print("making fmovexregto");
  a=append(DATA_SPECIAL,
           DATA_FLOAT,
           DATA_BASIC,
           DATA_ROUND);
  a=vector(#a,n,exd(a[n],RN));
  a=uniq(sort(append(a,vector(#a,n,-a[n]),[NaN]),comparator),comparator);
  asm(
"
;--------------------------------------------------------------------------------
;	FMOVE.X FPn,<mem>
;--------------------------------------------------------------------------------
	.cpu	68030
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
fmovexregto_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#MC68881+MC68882+MC68040+FPSP040+MC68060+FPSP060,-(sp)
	peamsg	'FMOVE.X FPN,<EA>'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: FMOVE.X FPn,<ea>',13,10
;------------------------------------------------
;	d1-d3	actual result
;	d4	actual status
;	d6	fpcr=(XRN..DRP)<<4
;	d7	0=failed,1=successful
;	a0	expected result handle,expected status,...
;	a1-a3	expected result
;	a4	expected status
;	a5	source handle,...
;	fp5	source
;------------------------------------------------
	lea.l	push_decompressed,a3
;decompress data
	move.l	a3,-(sp)
	pea.l	fmovexregto_data_compressed
	jbsr	decompress
	addq.l	#8,sp
;relocate decompressed handle
	move.l	#indirect_decompressed,d0
	movea.l	a3,a5			;source handle,...
@@:
	add.l	d0,(a3)+		;source handle
	tst.l	(a3)
	bpl	@b
	addq.l	#4,a3			;-1
	movea.l	a3,a0			;expected result handle,expected status,...
@@:
	add.l	d0,(a3)+		;expected result handle
	addq.l	#4,a3			;expected status
	tst.l	(a3)
	bpl	@b
;	addq.l	#4,a3			;-1
;
55:
	move.l	#",XRN<<4,",d6		;fpcr=(XRN..DRP)<<4
66:
;FPn,<mem>
	fmove.l	#0,fpcr
	fmove.x	([a5]),fp5		;source
	fmove.l	d6,fpcr			;fpcr
	fmove.l	#0,fpsr
	move.l	#-1,-(sp)		;fill=-1
	move.l	#-1,-(sp)
	move.l	#-1,-(sp)
					;source
	fmove.x	fp5,(sp)		;EXECUTE
	movem.l	(sp)+,d1-d3		;actual result
	fmove.l	fpsr,d4			;actual status
	fmove.l	#0,fpcr
;
	movem.l	([a0]),a1-a3		;expected result
	movea.l	(4,a0),a4		;expected status
;
	movem.l	d1-d4/a1-a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	test_packed
	lea.l	32(sp),sp
	move.l	d0,d7			;0=failed,1=successful
;
	move.l	d7,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FMOVE.X FPn='
	puthex24	([a5]),(4,[a5]),(8,[a5])	;source
	putmsg	',<mem> @'
	move.l	d6,-(sp)		;fpcr
	jbsr	printfpcrrprm
	addq.l	#4,sp
	putcrlf
	move.l	d7,-(sp)		;0=failed,1=successful
	movem.l	d1-d4/a1-a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	output_packed
	lea.l	36(sp),sp
@@:
;
	addq.l	#8,a0			;expected
;
	add.w	#1<<4,d6		;rprm++
	cmp.w	#",DRP<<4,",d6		;fpcr=(XRN..DRP)<<4
	bls	66b
;
	addq.l	#4,a5			;source handle,...
	tst.l	(a5)			;source handle,...
	bpl	55b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts
	.cpu	68000

	.align	4
fmovexregto_data_compressed::
");
  push_start();
  for(i=1,#a,
      x=a[i];  \\ソース
      push_indirect(12,numtoexd(x,RN)));
  push(4,-1);
  for(i=1,#a,
      x=a[i];  \\ソース
      for(rprm=XRN,DRP,  \\(rp<<2)+rm。丸め桁数と丸めモード
          rp=bitand(rprm>>2,3);  \\丸め桁数
          rm=bitand(rprm,3);  \\丸めモード
          fpsr=0;
          u=numtoexd(x,if(type(x)=="t_POL",RN,rm));  \\extendedに変換する
          fpsr_update_aer();
          sr=fpsr;
          push_indirect(12,u);
          push(4,sr)));
  push(4,-1);
  push_end()
  }


\\----------------------------------------------------------------------------------------
\\  FMOVE.X <mem>,FPn
\\----------------------------------------------------------------------------------------
make_fmovextoreg()={
  my(a,u,y,rp,rm,sr);
  print("making fmovextoreg");
  a=append(DATA_SPECIAL,
           DATA_EXTENDED,
           DATA_BASIC,
           DATA_ROUND);
  a=vector(#a,n,exd(a[n],RN));
  a=uniq(sort(append(a,vector(#a,n,-a[n]),[NaN]),comparator),comparator);
  asm(
"
;--------------------------------------------------------------------------------
;	FMOVE.X <mem>,FPn
;--------------------------------------------------------------------------------
	.cpu	68030
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
fmovextoreg_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#MC68881+MC68882+MC68040+FPSP040+MC68060+FPSP060,-(sp)
	peamsg	'FMOVE.X <EA>,FPN'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: FMOVE.X <ea>,FPn',13,10
;------------------------------------------------
;	d1	fpcr=(XRN..DRP)<<4
;	d3	0=failed,1=successful
;	d5	expected status
;	d7	actual status
;	a2	source handle,...
;	a4	expected result handle,expected status,...
;	fp5	expected result
;	fp7	actual result
;------------------------------------------------
	lea.l	push_decompressed,a0
;decompress data
	move.l	a0,-(sp)
	pea.l	fmovextoreg_data_compressed
	jbsr	decompress
	addq.l	#8,sp
;relocate decompressed handle
	move.l	#indirect_decompressed,d0
	movea.l	a0,a2			;source handle,...
@@:
	add.l	d0,(a0)+		;source handle
	tst.l	(a0)
	bpl	@b
	addq.l	#4,a0			;-1
	movea.l	a0,a4			;expected result handle,expected status,...
@@:
	add.l	d0,(a0)+		;expected result handle
	addq.l	#4,a0			;expected status
	tst.l	(a0)
	bpl	@b
;	addq.l	#4,a0			;-1
;
22:
	move.l	#",XRN<<4,",d1		;fpcr=(XRN..DRP)<<4
11:
;<mem>,FPn
	fmove.l	#0,fpcr
	fmove.s	#$7FFFFFFF,fp7		;fill=NaN
	fmove.l	d1,fpcr			;fpcr
	fmove.l	#0,fpsr
					;source
	fmove.x	([a2]),fp7		;EXECUTE
					;actual result
	fmove.l	fpsr,d7			;actual status
	fmove.l	#0,fpcr
;
	fmove.x	([a4]),fp5		;expected result
	move.l	(4,a4),d5		;expected status
;
	move.l	#-1,-(sp)		;fpcr(rp<<6,-1=strict)
	move.l	d5,-(sp)		;expected status
	fmove.x	fp5,-(sp)		;expected result
	move.l	d7,-(sp)		;actual status
	fmove.x	fp7,-(sp)		;actual result
	jbsr	test_extended
	lea.l	36(sp),sp
	move.l	d0,d3			;0=failed,1=successful
;
	move.l	d3,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FMOVE.X <mem>='
	puthex24	([a2]),(4,[a2]),(8,[a2])	;source
	putmsg	',FPn @'
	move.l	d1,-(sp)
	jbsr	printfpcrrprm
	addq.l	#4,sp
	putcrlf
	move.l	d3,-(sp)		;0=failed,1=successful
	move.l	d5,-(sp)		;expected status
	fmove.x	fp5,-(sp)		;expected result
	move.l	d7,-(sp)		;actual status
	fmove.x	fp7,-(sp)		;actual result
	jbsr	output_extended
	lea.l	36(sp),sp
@@:
;
	addq.l	#8,a4			;expected result
;
	add.w	#1<<4,d1		;rprm++
	cmp.w	#",DRP<<4,",d1		;fpcr=(XRN..DRP)<<4
	bls	11b
;
	addq.l	#4,a2			;source handle,...
	tst.l	(a2)			;source handle,...
	bpl	22b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts
	.cpu	68000

	.align	4
fmovextoreg_data_compressed::
");
  push_start();
  for(i=1,#a,
      u=numtoexd(a[i],RN);  \\ソース
      push_indirect(12,u));
  push(4,-1);
  for(i=1,#a,
      u=numtoexd(a[i],RN);  \\ソース
      for(rprm=XRN,DRP,  \\(rp<<2)+rm。丸め桁数と丸めモード
          rp=bitand(rprm>>2,3);  \\丸め桁数
          rm=bitand(rprm,3);  \\丸めモード
          fpsr=0;
          y=exdtonum(u);
          if((rp==EXD)&&
             ((bitand(u,0x7FFF00008000000000000000)==0)&&
              (bitand(u,0x000000007FFFFFFFFFFFFFFF)!=0)),
             fpsr=bitor(fpsr,UF));  \\丸め桁数がextendedで非正規化数のときUFをセットする
          if(type(y)!="t_POL",
             y=xxx(y,rp,rm));
          fpsr_update_ccr(y);
          fpsr_update_aer();
          sr=fpsr;
          push_indirect(12,numtoexd(y,RN));
          push(4,sr)));
  push(4,-1);
  push_end()
  }


\\----------------------------------------------------------------------------------------
\\  FMOVECR.X #ccc,FPn
\\----------------------------------------------------------------------------------------
MC68881ROM={[
  Pi,  \\0x00
  0,  \\0x01
  0,  \\0x02
  0,  \\0x03
  0,  \\0x04
  0,  \\0x05
  0,  \\0x06
  0,  \\0x07
  0,  \\0x08
  0,  \\0x09
  0,  \\0x0A
  log10(2),  \\0x0B
  exp(1),  \\0x0C
  log2(exp(1)),  \\0x0D
  log10(exp(1)),  \\0x0E
  0,  \\0x0F
  0,  \\0x10
  0,  \\0x11
  0,  \\0x12
  0,  \\0x13
  0,  \\0x14
  0,  \\0x15
  0,  \\0x16
  0,  \\0x17
  0,  \\0x18
  0,  \\0x19
  0,  \\0x1A
  0,  \\0x1B
  0,  \\0x1C
  0,  \\0x1D
  0,  \\0x1E
  0,  \\0x1F
  0,  \\0x20
  0,  \\0x21
  0,  \\0x22
  0,  \\0x23
  0,  \\0x24
  0,  \\0x25
  0,  \\0x26
  0,  \\0x27
  0,  \\0x28
  0,  \\0x29
  0,  \\0x2A
  0,  \\0x2B
  0,  \\0x2C
  0,  \\0x2D
  0,  \\0x2E
  0,  \\0x2F
  log(2),  \\0x30
  log(10),  \\0x31
  1,  \\0x32
  10,  \\0x33
  10^2,  \\0x34
  10^4,  \\0x35
  10^8,  \\0x36
  10^16,  \\0x37
  10^32,  \\0x38
  10^64,  \\0x39
  10^128,  \\0x3A
  10^256,  \\0x3B
  10^512,  \\0x3C
  10^1024,  \\0x3D
  10^2048,  \\0x3E
  10^4096  \\0x3F
  ]}
make_fmovecr881()={
  my(x,y,rp,rm,sr);
  print("making fmovecr881");
  asm(
"
;--------------------------------------------------------------------------------
;	FMOVECR.X #ccc,FPn
;--------------------------------------------------------------------------------
	.cpu	68030
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
fmovecr881_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#MC68881+FPSP040+FPSP060,-(sp)
	peamsg	'FMOVECR.X #CCC,FPN'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: FMOVECR.X #ccc,FPn',13,10
;------------------------------------------------
;	d1-d3	actual result
;	d4	actual status
;	d5	0=failed,1=successful
;	d6	fpcr=(XRN..XRP)<<4
;	d7	ccc=0..63
;	a0	expected result handle,expected status,...
;	a1-a3	expected result
;	a4	expected status
;	fp7	actual result
;------------------------------------------------
	lea.l	push_decompressed,a3
;decompress data
	move.l	a3,-(sp)
	pea.l	fmovecr881_expected_compressed
	jbsr	decompress
	addq.l	#8,sp
;relocate decompressed handle
	move.l	#indirect_decompressed,d0
	movea.l	a3,a0			;expected result handle,expected status,...
@@:
	add.l	d0,(a3)+		;expected result handle
	addq.l	#4,a3			;expected status
	tst.l	(a3)
	bpl	@b
;	addq.l	#4,a3			;-1
;
	moveq.l	#0,d7			;ccc=0..63
77:
	move.l	#",XRN<<4,",d6		;fpcr=(XRN..DRP)<<4
66:
;#ccc,FPn
	fmove.l	#0,fpcr
	fmove.s	#$7FFFFFFF,fp7		;fill=NaN
	fmove.l	d6,fpcr			;fpcr
	fmove.l	#0,fpsr
					;ccc
	jsr	([fmovecr881_execute,za0,d7.l*4])	;EXECUTE
	fmove.l	fpsr,d4			;actual status
	fmove.l	#0,fpcr
	fmove.x	fp7,-(sp)
	movem.l	(sp)+,d1-d3		;actual result
;
	movem.l	([a0]),a1-a3		;expected result
	movea.l	(4,a0),a4		;expected status
;
	move.l	#-1,-(sp)		;fpcr(rp<<6,-1=strict)
	movem.l	d1-d4/a1-a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	test_extended
	lea.l	36(sp),sp
	move.l	d0,d5			;0=failed,1=successful
;
	move.l	d5,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FMOVECR.X #'
	puthex2	d7			;ccc
	putmsg	',FPn @'
	move.l	d6,-(sp)		;fpcr
	jbsr	printfpcrrprm
	addq.l	#4,sp
	putcrlf
	move.l	d5,-(sp)		;0=failed,1=successful
	movem.l	d1-d4/a1-a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	output_extended
	lea.l	36(sp),sp
@@:
;
	addq.l	#8,a0			;expected result handle,expected status,...
;
	add.w	#1<<4,d6		;rprm++
	cmp.w	#",DRP<<4,",d6		;fpcr=(XRN..DRP)<<4
	bls	66b
;
	addq.w	#1,d7			;ccc++
	cmp.w	#63,d7			;ccc=0..63
	bls	77b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts

	.align	4
fmovecr881_execute::
");
  for(ccc=0,63,
      asm(
"	.dc.l	fmovecr881_execute_",ccc,"
");
      );
  for(ccc=0,63,
      asm(
"fmovecr881_execute_",ccc,"::
	fmovecr.x	#",ccc,",fp7
	rts
")
      );
  asm(
"	.cpu	68000

	.align	4
fmovecr881_expected_compressed::
");
  push_start();
  for(ccc=0,63,
      x=MC68881ROM[1+ccc];
      for(rprm=XRN,DRP,  \\(rp<<2)+rm。丸め桁数と丸めモード
          rp=bitand(rprm>>2,3);  \\丸め桁数
          rm=bitand(rprm,3);  \\丸めモード
          if((ccc==0x0B)&&(rprm==XRN),
             push_indirect(12,0x3FFD00009A209A84FBCFF798);
             push(4,X2+AX),
             (ccc==0x0C)&&(rprm==XRN),
             push_indirect(12,0x40000000ADF85458A2BB4A9A);
             push(4,X2+AX),
             (ccc==0x0E)&&((rprm==XRN)||(rprm==XRZ)||(rprm==XRM)||(rprm==XRP)),
             push_indirect(12,0x3FFD0000DE5BD8A937287195);
             push(4,0),
             fpsr=0;
             y=roundxxx(x,rp,rm);
             fpsr_update_ccr(y);
             fpsr_update_aer();
             sr=fpsr;
             push_indirect(12,numtoexd(y,RN));
             push(4,sr))));
  push(4,-1);
  push_end()
  }
MC68882ROM={[
  Pi,  \\0x00
  exdtonum(0x40010000FE00068200000000),  \\0x01
  exdtonum(0x40010000FFC0050380000000),  \\0x02
  exdtonum(0x200000007FFFFFFF00000000),  \\0x03
  exdtonum(0x00000000FFFFFFFFFFFFFFFF),  \\0x04
  exdtonum(0x3C000000FFFFFFFFFFFFF800),  \\0x05
  exdtonum(0x3F800000FFFFFF0000000000),  \\0x06
  exdtonum(0x00010000F65D8D9C00000000),  \\0x07
  exdtonum(0x7FFF0000401E000000000000),  \\0x08
  exdtonum(0x43F30000E000000000000000),  \\0x09
  exdtonum(0x40720000C000000000000000),  \\0x0A
  log10(2),  \\0x0B
  exp(1),  \\0x0C
  log2(exp(1)),  \\0x0D
  log10(exp(1)),  \\0x0E
  0,  \\0x0F
  0,  \\0x10
  0,  \\0x11
  0,  \\0x12
  0,  \\0x13
  0,  \\0x14
  0,  \\0x15
  0,  \\0x16
  0,  \\0x17
  0,  \\0x18
  0,  \\0x19
  0,  \\0x1A
  0,  \\0x1B
  0,  \\0x1C
  0,  \\0x1D
  0,  \\0x1E
  0,  \\0x1F
  0,  \\0x20
  0,  \\0x21
  0,  \\0x22
  0,  \\0x23
  0,  \\0x24
  0,  \\0x25
  0,  \\0x26
  0,  \\0x27
  0,  \\0x28
  0,  \\0x29
  0,  \\0x2A
  0,  \\0x2B
  0,  \\0x2C
  0,  \\0x2D
  0,  \\0x2E
  0,  \\0x2F
  log(2),  \\0x30
  log(10),  \\0x31
  1,  \\0x32
  10,  \\0x33
  10^2,  \\0x34
  10^4,  \\0x35
  10^8,  \\0x36
  10^16,  \\0x37
  10^32,  \\0x38
  10^64,  \\0x39
  10^128,  \\0x3A
  10^256,  \\0x3B
  10^512,  \\0x3C
  10^1024,  \\0x3D
  10^2048,  \\0x3E
  10^4096  \\0x3F
  ]}
make_fmovecr882()={
  my(x,y,rp,rm,sr);
  print("making fmovecr882");
  asm(
"
;--------------------------------------------------------------------------------
;	FMOVECR.X #ccc,FPn
;--------------------------------------------------------------------------------
	.cpu	68030
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
fmovecr882_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#MC68882,-(sp)
	peamsg	'FMOVECR.X #CCC,FPN'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: FMOVECR.X #ccc,FPn',13,10
;------------------------------------------------
;	d1-d3	actual result
;	d4	actual status
;	d5	0=failed,1=successful
;	d6	fpcr=(XRN..XRP)<<4
;	d7	ccc=0..63
;	a0	expected result handle,expected status,...
;	a1-a3	expected result
;	a4	expected status
;	fp7	actual result
;------------------------------------------------
	lea.l	push_decompressed,a3
;decompress data
	move.l	a3,-(sp)
	pea.l	fmovecr882_expected_compressed
	jbsr	decompress
	addq.l	#8,sp
;relocate decompressed handle
	move.l	#indirect_decompressed,d0
	movea.l	a3,a0			;expected result handle,expected status,...
@@:
	add.l	d0,(a3)+		;expected result handle
	addq.l	#4,a3			;expected status
	tst.l	(a3)
	bpl	@b
;	addq.l	#4,a3			;-1
;
	moveq.l	#0,d7			;ccc=0..63
77:
	move.l	#",XRN<<4,",d6		;fpcr=(XRN..DRP)<<4
66:
;#ccc,FPn
	fmove.l	#0,fpcr
	fmove.s	#$7FFFFFFF,fp7		;fill=NaN
	fmove.l	d6,fpcr			;fpcr
	fmove.l	#0,fpsr
					;ccc
	jsr	([fmovecr882_execute,za0,d7.l*4])	;EXECUTE
	fmove.l	fpsr,d4			;actual status
	fmove.l	#0,fpcr
	fmove.x	fp7,-(sp)
	movem.l	(sp)+,d1-d3		;actual result
;
	movem.l	([a0]),a1-a3		;expected result
	movea.l	(4,a0),a4		;expected status
;
	move.l	#-1,-(sp)		;fpcr(rp<<6,-1=strict)
	movem.l	d1-d4/a1-a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	test_extended
	lea.l	36(sp),sp
	move.l	d0,d5			;0=failed,1=successful
;
	move.l	d5,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FMOVECR.X #'
	puthex2	d7			;ccc
	putmsg	',FPn @'
	move.l	d6,-(sp)		;fpcr
	jbsr	printfpcrrprm
	addq.l	#4,sp
	putcrlf
	move.l	d5,-(sp)		;0=failed,1=successful
	movem.l	d1-d4/a1-a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	output_extended
	lea.l	36(sp),sp
@@:
;
	addq.l	#8,a0			;expected result handle,expected status,...
;
	add.w	#1<<4,d6		;rprm++
	cmp.w	#",DRP<<4,",d6		;fpcr=(XRN..DRP)<<4
	bls	66b
;
	addq.w	#1,d7			;ccc++
	cmp.w	#63,d7			;ccc=0..63
	bls	77b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts

	.align	4
fmovecr882_execute::
");
  for(ccc=0,63,
      asm(
"	.dc.l	fmovecr882_execute_",ccc,"
");
      );
  for(ccc=0,63,
      asm(
"fmovecr882_execute_",ccc,"::
	fmovecr.x	#",ccc,",fp7
	rts
")
      );
  asm(
"	.cpu	68000

	.align	4
fmovecr882_expected_compressed::
");
  push_start();
  for(ccc=0,63,
      x=MC68882ROM[1+ccc];
      for(rprm=XRN,DRP,  \\(rp<<2)+rm。丸め桁数と丸めモード
          rp=bitand(rprm>>2,3);  \\丸め桁数
          rm=bitand(rprm,3);  \\丸めモード
          if((ccc==0x01)&&((rprm==SRN)||(rprm==SRZ)||(rprm==SRM)),
             push_indirect(12,0x40010000FE00068000000000);
             push(4,X2+AX),
             (ccc==0x02)&&(rprm==SRP),
             push_indirect(12,0x40010000FFC0058000000000);
             push(4,X2+AX),
             (ccc==0x03)&&((rprm==SRN)||(rprm==SRP)),
             push_indirect(12,0x200000008000000000000000);
             push(4,IN+X2+AX),
             (ccc==0x03)&&((rprm==SRZ)||(rprm==SRM)),
             push_indirect(12,0x200000007FFFFF0000000000);
             push(4,NA+X2+AX),
             ccc==0x03,
             push_indirect(12,0x200000007FFFFFFF00000000);
             push(4,NA),
             (ccc==0x07)&&((rprm==SRN)||(rprm==SRZ)||(rprm==SRM)),
             push_indirect(12,0x00010000F65D8D8000000000);
             push(4,NA+X2+AX),
             (ccc==0x07)&&(rprm==SRP),
             push_indirect(12,0x00010000F65D8E0000000000);
             push(4,NA+X2+AX),
             ccc==0x07,
             push_indirect(12,0x00010000F65D8D9C00000000);
             push(4,NA),
             ccc==0x08,
             push_indirect(12,0x7FFF0000401E000000000000);
             push(4,NA),
             (ccc==0x0B)&&(rprm==XRN),
             push_indirect(12,0x3FFD00009A209A84FBCFF798);
             push(4,X2+AX),
             (ccc==0x0C)&&(rprm==XRN),
             push_indirect(12,0x40000000ADF85458A2BB4A9A);
             push(4,X2+AX),
             (ccc==0x0E)&&((rprm==XRN)||(rprm==XRZ)||(rprm==XRM)||(rprm==XRP)),
             push_indirect(12,0x3FFD0000DE5BD8A937287195);
             push(4,0),
             fpsr=0;
             y=roundxxx(x,rp,rm);
             fpsr_update_ccr(y);
             fpsr_update_aer();
             sr=fpsr;
             push_indirect(12,numtoexd(y,RN));
             push(4,sr))));
  push(4,-1);
  push_end()
  }

/*
\\----------------------------------------------------------------------------------------
\\  FMOVEM.L <list>,<ea>
\\----------------------------------------------------------------------------------------
make_fmovemlregto()={
  }


\\----------------------------------------------------------------------------------------
\\  FMOVEM.L <ea>,<list>
\\----------------------------------------------------------------------------------------
make_fmovemltoreg()={
  }


\\----------------------------------------------------------------------------------------
\\  FMOVEM.X #<data>,<ea>
\\  FMOVEM.X <list>,<ea>
\\  FMOVEM.X Dl,<ea>
\\----------------------------------------------------------------------------------------
make_fmovemxregto()={
  }


\\----------------------------------------------------------------------------------------
\\  FMOVEM.X <ea>,#<data>
\\  FMOVEM.X <ea>,<list>
\\  FMOVEM.X <ea>,Dl
\\----------------------------------------------------------------------------------------
make_fmovemxtoreg()={
  }
*/


\\----------------------------------------------------------------------------------------
\\  FMUL.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fmul()={
  make_fop2to1("fmul",
               "fmul",
               -1,
               MC68881+MC68882+MC68040+FPSP040+MC68060+FPSP060,
               append(DATA_SPECIAL,
                      DATA_EXTENDED,
                      DATA_BINARY),
               (x,y,rp,rm)->if((x==NaN)||(y==NaN),NaN,
                               ((x==Rei)||(x==-Rei))&&((y==Inf)||(y==-Inf)),fpsr=bitor(fpsr,OE);NaN,  \\(±0)*(±Inf)=NaN,OE
                               ((x==Inf)||(x==-Inf))&&((y==Rei)||(y==-Rei)),fpsr=bitor(fpsr,OE);NaN,  \\(±Inf)*(±0)=NaN,OE
                               ((x==Rei)||(x==-Rei))&&((y==Rei)||(y==-Rei)),if(x==Rei,1,-1)*if(y==Rei,1,-1)*Rei,  \\(±0)*(±0)=±0
                               ((x==Inf)||(x==-Inf))&&((y==Inf)||(y==-Inf)),if(x==Inf,1,-1)*if(y==Inf,1,-1)*Inf,  \\(±Inf)*(±Inf)=±Inf
                               (y==Rei)||(y==-Rei),sign(x)*if(y==Rei,1,-1)*Rei,  \\(±x)*(±0)=±0
                               (y==Inf)||(y==-Inf),sign(x)*if(y==Inf,1,-1)*Inf,  \\(±x)*(±Inf)=±Inf
                               (x==Rei)||(x==-Rei),if(x==Rei,1,-1)*sign(y)*Rei,  \\(±0)*(±y)=±0
                               (x==Inf)||(x==-Inf),if(x==Inf,1,-1)*sign(y)*Inf,  \\(±Inf)*(±y)=±Inf
                               xxx2(x*y,rp,rm)));
  }


\\----------------------------------------------------------------------------------------
\\  FNEG.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fneg()={
  make_fop1to1("fneg",
               "fneg",
               -1,
               MC68881+MC68882+MC68040+FPSP040+MC68060+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,Inf,  \\neg(-Inf)=+Inf
                                x==-Rei,Rei,  \\neg(-0)=+0
                                x==Rei,-Rei,  \\neg(+0)=-0
                                x==Inf,-Inf,  \\neg(+Inf)=-Inf
                                NaN),
                             xxx(-x,rp,rm)))
  }


\\----------------------------------------------------------------------------------------
\\  FREM.X FPm,FPn
\\----------------------------------------------------------------------------------------
frem_func(x,y,rp,rm)={
  my(q,z);
  fpsr=bitand(fpsr,0xFF00FFFF);  \\quotient byteをクリアする
  if((x==NaN)||(y==NaN),NaN,
     (x==Inf)||(x==-Inf),fpsr=bitor(fpsr,OE);NaN,  \\(±Inf)%(±y)=NaN,OE
     (y==Rei)||(y==-Rei),fpsr=bitor(fpsr,OE);NaN,  \\(±x)%(±0)=NaN,OE
     fpsr=bitor(fpsr,bitxor(isminus(x),isminus(y))<<23);  \\商の符号
     if((x==Rei)||(x==-Rei),x,  \\(±0)%(±y)=±0,商は±0
        (y==Inf)||(y==-Inf),xxx(x,rp,rm),  \\(±x)%(±Inf)=±x,商は±0。xが非正規化数のときUFをセットする
        q=rint(x/y);
        fpsr=bitor(fpsr,bitand(abs(q),127)<<16);  \\商の絶対値の下位7bit
        z=xxx(x-q*y,rp,rm);
        if((z==Rei)||(z==-Rei),z=sign(x)*Rei);  \\余りが0のときは0にxの符号を付ける
        z))
  }
make_frem()={
  make_fop2to1("frem",
               "frem",
               -1,
               MC68881+MC68882+FPSP040+FPSP060,
               append(DATA_SPECIAL,
                      DATA_EXTENDED,
                      DATA_BINARY),
               frem_func)
  }

/*
\\----------------------------------------------------------------------------------------
\\  FRESTORE <ea>
\\----------------------------------------------------------------------------------------
make_frestore()={
  }
*/


\\----------------------------------------------------------------------------------------
\\  FSABS.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fsabs()={
  make_fop1to1("fsabs",
               "fsabs",
               -1,
               MC68040+FPSP040+MC68060+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,Inf,  \\sabs(-Inf)=+Inf
                                x==-Rei,Rei,  \\sabs(-0)=+0
                                x==Rei,Rei,  \\sabs(+0)=+0
                                x==Inf,Inf,  \\sabs(+Inf)=+Inf
                                NaN),
                             sgl(abs(x),rm)))
  }


\\----------------------------------------------------------------------------------------
\\  FSADD.X FPm,FPn
\\----------------------------------------------------------------------------------------
fsadd_func(x,y,rp,rm)={
  my(z);
  if(x==0,x=Rei);
  if(y==0,y=Rei);
  if((x==NaN)||(y==NaN),NaN,
     (x==Inf)&&(y==-Inf),fpsr=bitor(fpsr,OE);NaN,  \\(+Inf)+(-Inf)=NaN,OE
     (x==-Inf)&&(y==Inf),fpsr=bitor(fpsr,OE);NaN,  \\(-Inf)+(+Inf)=NaN,OE
     (x==Rei)&&(y==Rei),Rei,  \\(+0)+(+0)=+0
     (x==-Rei)&&(y==-Rei),-Rei,  \\(-0)+(-0)=-0
     (x==Rei)&&(y==-Rei),if(rm==RM,-Rei,Rei),  \\(+0)+(-0)=±0
     (x==-Rei)&&(y==Rei),if(rm==RM,-Rei,Rei),  \\(-0)+(+0)=±0
     (y==Inf)||(y==-Inf),y,  \\(±x)+(±Inf)=±Inf
     (x==Inf)||(x==-Inf),x,  \\(±Inf)+(±y)=±Inf
     (y==Rei)||(y==-Rei),sgl(x,rm),  \\(±x)+(±0)=(±x)
     (x==Rei)||(x==-Rei),sgl(y,rm),  \\(±0)+(±y)=±y
     z=x+y;
     if(z==0,
        if(rm==RM,-Rei,Rei),
        sgl(z,rm)))
  }
make_fsadd()={
  make_fop2to1("fsadd",
               "fsadd",
               SGL,
               MC68040+FPSP040+MC68060+FPSP060,
               append(DATA_SPECIAL,
                      DATA_EXTENDED,
                      DATA_BINARY),
               fsadd_func)
  }


/*
\\----------------------------------------------------------------------------------------
\\  FSAVE <ea>
\\----------------------------------------------------------------------------------------
make_fsave()={
  }
*/


\\----------------------------------------------------------------------------------------
\\  FSCALE.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fscale()={
  make_fop2to1("fscale",
               "fscale",
               -1,
               MC68881+MC68882+FPSP040+FPSP060,
               append(DATA_SPECIAL,
                      DATA_EXTENDED,
                      DATA_BINARY),
               (x,y,rp,rm)->if((x==NaN)||(y==NaN),NaN,  \\NaNと±InfのときOEはセットされない
                               (y==Inf)||(y==-Inf),fpsr=bitor(fpsr,OE);NaN,  \\scale(±x,±Inf)=NaN,OE
                               (x==Inf)||(x==-Inf),x,  \\scale(±Inf,±y)=±Inf
                               (x==Rei)||(x==-Rei),x,  \\scale(±0,±y)=±0
                               (y==Rei)||(y==-Rei),xxx(x,rp,rm),  \\scale(±x,±0)=±x
                               y<-2^14,fpsr=bitor(fpsr,UF+X2);xxx(if(x<0,-Rei,Rei),rp,rm),  \\scale(±x,small)=±0,UF+X2
                               2^14<=y,fpsr=bitor(fpsr,OF);xxx(if(x<0,-Inf,Inf),rp,rm),  \\scale(±x,big)=±Inf,OF
                               xxx2(x*2^trunc(y),rp,rm)))
  }


\\----------------------------------------------------------------------------------------
\\  FScc.B <ea>
\\----------------------------------------------------------------------------------------
make_fscc060()={
  my(m,z,n,a);
  print("making fscc060");
  asm(
"
;--------------------------------------------------------------------------------
;	FScc.B Dr
;	FScc.B <mem>
;--------------------------------------------------------------------------------
	.cpu	68030
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
fscc060_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#FPSP060,-(sp)
	peamsg	'FSCC.B <EA>'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: FScc.B <ea>',13,10
;------------------------------------------------
;	d1	actual result
;	d3	fill=$00000000,$FFFFFFFF
;	d4	actual status
;	d5	cc=0..31
;	d6	fpsr=(mzin=0..15)<<24
;	d7	0=failed,1=successful
;	a0	expected result,expected status,...
;	a1	expected result
;	a4	expected status
;------------------------------------------------
	lea.l	push_decompressed,a0	;expected result,expected status,...
;decompress data
	move.l	a0,-(sp)
	pea.l	fscc060_expected_compressed
	jbsr	decompress
	addq.l	#8,sp
	move.l	#0<<24,d6		;fpsr=(mzin=0..15)<<24
66:
	moveq.l	#0,d5			;cc=0..31
55:
;FScc.B Dr=fill
	moveq.l	#$00000000,d3		;fill=$00000000,$FFFFFFFF
33:
	fmove.l	#0,fpcr
	fmove.l	d6,fpsr			;fpsr
	move.l	d3,d1			;fill
	jsr	([fscc060_execute_dr,za0,d5.l*4])	;EXECUTE
					;actual result
	fmove.l	fpsr,d4			;actual status
;
	movea.l	(a0),a1			;expected result
	movea.l	(4,a0),a4		;expected status
;
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	test_single
	lea.l	16(sp),sp
	move.l	d0,d7			;0=failed,1=successful
;
	move.l	d7,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FS'
	putstr	(uppercase_cc,za0,d5.l*4)
	putmsg	'.B Dr='
	puthex8	d3			;fill
	putmsg	' @'
	move.l	d6,-(sp)		;fpsr
	jbsr	printfpsr
	addq.l	#4,sp
	putcrlf
	move.l	d7,-(sp)		;0=failed,1=successful
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	output_single
	lea.l	20(sp),sp
@@:
;
	addq.l	#8,a0			;expected result
;
	not.l	d3			;fill
	bne	33b
;FScc.B <mem>=fill
	moveq.l	#$00000000,d3		;fill=$00000000,$FFFFFFFF
33:
	fmove.l	#0,fpcr
	fmove.l	d6,fpsr			;fpsr
	move.l	d3,-(sp)		;fill
	jsr	([fscc060_execute_mem,za0,d5.l*4])	;EXECUTE
	move.l	(sp)+,d1		;actual result
	fmove.l	fpsr,d4			;actual status
;
	movea.l	(a0),a1			;expected result
	movea.l	(4,a0),a4		;expected status
;
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	test_single
	lea.l	16(sp),sp
	move.l	d0,d7			;0=failed,1=successful
;
	move.l	d7,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FS'
	putstr	(uppercase_cc,za0,d5.l*4)
	putmsg	'.B <mem>='
	puthex8	d3			;fill
	putmsg	' @'
	move.l	d6,-(sp)		;fpsr
	jbsr	printfpsr
	addq.l	#4,sp
	putcrlf
	move.l	d7,-(sp)		;0=failed,1=successful
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	output_single
	lea.l	20(sp),sp
@@:
;
	addq.l	#8,a0			;expected result
;
	not.l	d3			;fill
	bne	33b
;
	addq.w	#1,d5			;cc++
	cmp.w	#31,d5			;cc=0..31
	bls	55b
;
	add.l	#1<<24,d6		;mzin++
	cmp.l	#15<<24,d6		;fpsr=(mzin=0..15)<<24
	bls	66b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts

	.align	4
fscc060_execute_dr::
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
	.dc.l	fscc060_execute_dr_&cc
  .endm
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
fscc060_execute_dr_&cc::
	FS&cc.B	d1			;EXECUTE
					;actual result
	rts
  .endm
fscc060_execute_mem::
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
	.dc.l	fscc060_execute_mem_&cc
  .endm
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
fscc060_execute_mem_&cc::
	FS&cc.B	(4,sp)			;EXECUTE
					;actual result
	rts
  .endm
	.cpu	68000

	.align	4
fscc060_expected_compressed::
");
  push_start();
  for(mzin=0,15,
      m=bitand(mzin>>3,1);
      z=bitand(mzin>>2,1);
      n=bitand(mzin>>0,1);
      a=[
        0xFF*(0),           \\000000  F
        0xFF*(z),           \\000001  EQ
        0xFF*(!(n||z||m)),  \\000010  OGT
        0xFF*(z||!(n||m)),  \\000011  OGE
        0xFF*(m&&!(n||z)),  \\000100  OLT
        0xFF*(z||(m&&!n)),  \\000101  OLE
        0xFF*(!(n||z)),     \\000110  OGL
        0xFF*(!n),          \\000111  OR
        0xFF*(n),           \\001000  UN
        0xFF*(n||z),        \\001001  UEQ
        0xFF*(n||!(m||z)),  \\001010  UGT
        0xFF*(n||(z||!m)),  \\001011  UGE
        0xFF*(n||(m&&!z)),  \\001100  ULT
        0xFF*(n||z||m),     \\001101  ULE
        0xFF*(!z),          \\001110  NE
        0xFF*(1)            \\001111  T
        ];
      for(cc=0,15,
          push(4,0x00000000+a[1+cc]);
          push(4,mzin<<24);
          push(4,0xFFFFFF00+a[1+cc]);
          push(4,mzin<<24);
          push(4,(a[1+cc]<<24)+0x000000);
          push(4,mzin<<24);
          push(4,(a[1+cc]<<24)+0xFFFFFF);
          push(4,mzin<<24));
      for(cc=16,31,
          push(4,0x00000000+a[1+cc-16]);
          push(4,(mzin<<24)+if(n,BS+AV,0));
          push(4,0xFFFFFF00+a[1+cc-16]);
          push(4,(mzin<<24)+if(n,BS+AV,0));
          push(4,(a[1+cc-16]<<24)+0x000000);
          push(4,(mzin<<24)+if(n,BS+AV,0));
          push(4,(a[1+cc-16]<<24)+0xFFFFFF);
          push(4,(mzin<<24)+if(n,BS+AV,0))));
  push_end()
  }
make_fscc88x()={
  my(m,z,n,a);
  print("making fscc88x");
  asm(
"
;--------------------------------------------------------------------------------
;	FScc.B Dr
;	FScc.B <mem>
;--------------------------------------------------------------------------------
	.cpu	68030
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
fscc88x_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#MC68881+MC68882+FPSP040,-(sp)
	peamsg	'FSCC.B <EA>'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: FScc.B <ea>',13,10
;------------------------------------------------
;	d1	actual result
;	d3	fill=$00000000,$FFFFFFFF
;	d4	actual status
;	d5	cc=0..31
;	d6	fpsr=(mzin=0..15)<<24
;	d7	0=failed,1=successful
;	a0	expected result,expected status,...
;	a1	expected result
;	a4	expected status
;------------------------------------------------
	lea.l	push_decompressed,a0	;expected result,expected status,...
;decompress data
	move.l	a0,-(sp)
	pea.l	fscc88x_expected_compressed
	jbsr	decompress
	addq.l	#8,sp
	move.l	#0<<24,d6		;fpsr=(mzin=0..15)<<24
66:
	moveq.l	#0,d5			;cc=0..31
55:
;FScc.B Dr=fill
	moveq.l	#$00000000,d3		;fill=$00000000,$FFFFFFFF
33:
	fmove.l	#0,fpcr
	fmove.l	d6,fpsr			;fpsr
	move.l	d3,d1			;fill
	jsr	([fscc88x_execute_dr,za0,d5.l*4])	;EXECUTE
					;actual result
	fmove.l	fpsr,d4			;actual status
;
	movea.l	(a0),a1			;expected result
	movea.l	(4,a0),a4		;expected status
;
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	test_single
	lea.l	16(sp),sp
	move.l	d0,d7			;0=failed,1=successful
;
	move.l	d7,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FS'
	putstr	(uppercase_cc,za0,d5.l*4)
	putmsg	'.B Dr='
	puthex8	d3			;fill
	putmsg	' @'
	move.l	d6,-(sp)		;fpsr
	jbsr	printfpsr
	addq.l	#4,sp
	putcrlf
	move.l	d7,-(sp)		;0=failed,1=successful
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	output_single
	lea.l	20(sp),sp
@@:
;
	addq.l	#8,a0			;expected result
;
	not.l	d3			;fill
	bne	33b
;FScc.B <mem>=fill
	moveq.l	#$00000000,d3		;fill=$00000000,$FFFFFFFF
33:
	fmove.l	#0,fpcr
	fmove.l	d6,fpsr			;fpsr
	move.l	d3,-(sp)		;fill
	jsr	([fscc88x_execute_mem,za0,d5.l*4])	;EXECUTE
	move.l	(sp)+,d1		;actual result
	fmove.l	fpsr,d4			;actual status
;
	movea.l	(a0),a1			;expected result
	movea.l	(4,a0),a4		;expected status
;
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	test_single
	lea.l	16(sp),sp
	move.l	d0,d7			;0=failed,1=successful
;
	move.l	d7,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FS'
	putstr	(uppercase_cc,za0,d5.l*4)
	putmsg	'.B <mem>='
	puthex8	d3			;fill
	putmsg	' @'
	move.l	d6,-(sp)		;fpsr
	jbsr	printfpsr
	addq.l	#4,sp
	putcrlf
	move.l	d7,-(sp)		;0=failed,1=successful
	movem.l	d1/d4/a1/a4,-(sp)	;actual result,actual status,expected result,expected status
	jbsr	output_single
	lea.l	20(sp),sp
@@:
;
	addq.l	#8,a0			;expected result
;
	not.l	d3			;fill
	bne	33b
;
	addq.w	#1,d5			;cc++
	cmp.w	#31,d5			;cc=0..31
	bls	55b
;
	add.l	#1<<24,d6		;mzin++
	cmp.l	#15<<24,d6		;fpsr=(mzin=0..15)<<24
	bls	66b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts

	.align	4
fscc88x_execute_dr::
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
	.dc.l	fscc88x_execute_dr_&cc
  .endm
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
fscc88x_execute_dr_&cc::
	FS&cc.B	d1			;EXECUTE
					;actual result
	rts
  .endm
fscc88x_execute_mem::
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
	.dc.l	fscc88x_execute_mem_&cc
  .endm
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
fscc88x_execute_mem_&cc::
	FS&cc.B	(4,sp)			;EXECUTE
					;actual result
	rts
  .endm
	.cpu	68000

	.align	4
fscc88x_expected_compressed::
");
  push_start();
  for(mzin=0,15,
      m=bitand(mzin>>3,1);
      z=bitand(mzin>>2,1);
      n=bitand(mzin>>0,1);
      a=[
        0xFF*(0),           \\000000  F
        0xFF*(z),           \\000001  EQ
        0xFF*(!(n||z||m)),  \\000010  OGT
        0xFF*(z||!(n||m)),  \\000011  OGE
        0xFF*(m&&!(n||z)),  \\000100  OLT
        0xFF*(z||(m&&!n)),  \\000101  OLE
        0xFF*(!(n||z)),     \\000110  OGL
        0xFF*(z||!n),       \\000111  OR
        0xFF*(n),           \\001000  UN
        0xFF*(n||z),        \\001001  UEQ
        0xFF*(n||!(m||z)),  \\001010  UGT
        0xFF*(n||(z||!m)),  \\001011  UGE
        0xFF*(n||(m&&!z)),  \\001100  ULT
        0xFF*(n||z||m),     \\001101  ULE
        0xFF*(n||!z),       \\001110  NE
        0xFF*(1)            \\001111  T
        ];
      for(cc=0,15,
          push(4,0x00000000+a[1+cc]);
          push(4,mzin<<24);
          push(4,0xFFFFFF00+a[1+cc]);
          push(4,mzin<<24);
          push(4,(a[1+cc]<<24)+0x000000);
          push(4,mzin<<24);
          push(4,(a[1+cc]<<24)+0xFFFFFF);
          push(4,mzin<<24));
      for(cc=16,31,
          push(4,0x00000000+a[1+cc-16]);
          push(4,(mzin<<24)+if(n,BS+AV,0));
          push(4,0xFFFFFF00+a[1+cc-16]);
          push(4,(mzin<<24)+if(n,BS+AV,0));
          push(4,(a[1+cc-16]<<24)+0x000000);
          push(4,(mzin<<24)+if(n,BS+AV,0));
          push(4,(a[1+cc-16]<<24)+0xFFFFFF);
          push(4,(mzin<<24)+if(n,BS+AV,0))));
  push_end()
  }


\\----------------------------------------------------------------------------------------
\\  FSDIV.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fsdiv()={
  make_fop2to1("fsdiv",
               "fsdiv",
               -1,
               MC68040+FPSP040+MC68060+FPSP060,
               append(DATA_SPECIAL,
                      DATA_EXTENDED,
                      DATA_BINARY),
               (x,y,rp,rm)->if((x==NaN)||(y==NaN),NaN,
                               ((x==Rei)||(x==-Rei))&&((y==Rei)||(y==-Rei)),fpsr=bitor(fpsr,OE);NaN,  \\(±0)/(±0)=NaN,OE
                               ((x==Inf)||(x==-Inf))&&((y==Inf)||(y==-Inf)),fpsr=bitor(fpsr,OE);NaN,  \\(±Inf)/(±Inf)=NaN,OE
                               ((x==Inf)||(x==-Inf))&&((y==Rei)||(y==-Rei)),if(x==Inf,1,-1)*if(y==Rei,1,-1)*Inf,  \\(±Inf)/(±0)=±Inf,non-DZ
                               ((x==Rei)||(x==-Rei))&&((y==Inf)||(y==-Inf)),if(x==Rei,1,-1)*if(y==Inf,1,-1)*Rei,  \\(±0)/(±Inf)=±0
                               (y==Rei)||(y==-Rei),fpsr=bitor(fpsr,DZ);sign(x)*if(y==Rei,1,-1)*Inf,  \\(±x)/(±0)=±Inf,DZ
                               (y==Inf)||(y==-Inf),sign(x)*if(y==Inf,1,-1)*Rei,  \\(±x)/(±Inf)=±0
                               (x==Rei)||(x==-Rei),if(x==Rei,1,-1)*sign(y)*Rei,  \\(±0)/(±y)=±0
                               (x==Inf)||(x==-Inf),if(x==Inf,1,-1)*sign(y)*Inf,  \\(±Inf)/(±y)=±Inf
                               sgl(x/y,rm)))
  }


\\----------------------------------------------------------------------------------------
\\  FSGLDIV.X FPm,FPn
\\----------------------------------------------------------------------------------------
fsgldiv060_func(x,y,rp,rm)={
  my(z);
  \\引数の仮数部を24bitに切り捨てない
  x=roundexd(x,RZ);
  y=roundexd(y,RZ);
  if((x==NaN)||(y==NaN),NaN,
     ((x==Rei)||(x==-Rei))&&((y==Rei)||(y==-Rei)),fpsr=bitor(fpsr,OE);NaN,  \\(±0)/(±0)=NaN,OE
     ((x==Inf)||(x==-Inf))&&((y==Inf)||(y==-Inf)),fpsr=bitor(fpsr,OE);NaN,  \\(±Inf)/(±Inf)=NaN,OE
     ((x==Inf)||(x==-Inf))&&((y==Rei)||(y==-Rei)),if(x==Inf,1,-1)*if(y==Rei,1,-1)*Inf,  \\(±Inf)/(±0)=±Inf,non-DZ
     ((x==Rei)||(x==-Rei))&&((y==Inf)||(y==-Inf)),if(x==Rei,1,-1)*if(y==Inf,1,-1)*Rei,  \\(±0)/(±Inf)=±0
     (y==Rei)||(y==-Rei),fpsr=bitor(fpsr,DZ);sign(x)*if(y==Rei,1,-1)*Inf,  \\(±x)/(±0)=±Inf,DZ
     (y==Inf)||(y==-Inf),sign(x)*if(y==Inf,1,-1)*Rei,  \\(±x)/(±Inf)=±0
     (x==Rei)||(x==-Rei),if(x==Rei,1,-1)*sign(y)*Rei,  \\(±0)/(±y)=±0
     (x==Inf)||(x==-Inf),if(x==Inf,1,-1)*sign(y)*Inf,  \\(±Inf)/(±y)=±Inf
     z=xsg(x/y,rm);
     \\オーバーフローしたときの返却値を調整する
     \\  アンダーフローしたときの返却値は±XSGDEMINだが、
     \\  オーバーフローしたときの返却値は±EXDNOMAXになる
     \\  このときだけ仮数部が24bitで表現できない値を返す
     if(bitand(fpsr,OF),
        if(abs(z)==XSGNOMAX,
           z=sign(z)*EXDNOMAX));
     z)
  }
make_fsgldiv060()={
  make_fop2to1("fsgldiv060",
               "fsgldiv",
               -1,  \\仮数部が24bitで表現できない値を返す場合があるのでSGLは不可
               MC68060+FPSP060,
               append(DATA_SPECIAL,
                      DATA_EXTENDED,
                      DATA_BINARY),
               fsgldiv060_func)
  }
fsgldiv88x_func(x,y,rp,rm)={
  my(z);
  \\引数の仮数部を24bitに切り捨てない
  x=roundexd(x,RZ);
  y=roundexd(y,RZ);
  if((x==NaN)||(y==NaN),NaN,
     ((x==Rei)||(x==-Rei))&&((y==Rei)||(y==-Rei)),fpsr=bitor(fpsr,OE);NaN,  \\(±0)/(±0)=NaN,OE
     ((x==Inf)||(x==-Inf))&&((y==Inf)||(y==-Inf)),fpsr=bitor(fpsr,OE);NaN,  \\(±Inf)/(±Inf)=NaN,OE
     ((x==Inf)||(x==-Inf))&&((y==Rei)||(y==-Rei)),if(x==Inf,1,-1)*if(y==Rei,1,-1)*Inf,  \\(±Inf)/(±0)=±Inf,non-DZ
     ((x==Rei)||(x==-Rei))&&((y==Inf)||(y==-Inf)),if(x==Rei,1,-1)*if(y==Inf,1,-1)*Rei,  \\(±0)/(±Inf)=±0
     (y==Rei)||(y==-Rei),fpsr=bitor(fpsr,DZ);sign(x)*if(y==Rei,1,-1)*Inf,  \\(±x)/(±0)=±Inf,DZ
     (y==Inf)||(y==-Inf),sign(x)*if(y==Inf,1,-1)*Rei,  \\(±x)/(±Inf)=±0
     (x==Rei)||(x==-Rei),if(x==Rei,1,-1)*sign(y)*Rei,  \\(±0)/(±y)=±0
     (x==Inf)||(x==-Inf),if(x==Inf,1,-1)*sign(y)*Inf,  \\(±Inf)/(±y)=±Inf
     z=xsg(x/y,rm);
     if(TEST_HARD_FSGLDIV,
        \\アンダーフローしたときの返却値を調整する
        \\  RPまたはRMなのに絶対値が切り上げられず、不正確な結果なのにX2がセットされないことがある
        \\    RP,0x000000000000000000000001,0x3ffd00008000000000000000
        \\       0x000000000000000000000000,ZE+UF	;expected
        \\    RP,0x000000000000000000000001,0x3ffe00008000000000000000
        \\       0x000000000000000000000000,ZE+UF	;expected
        \\    RP,0x000000000000000000000001,0x3fff00008000000000000000
        \\       0x000000000000000000000000,ZE+UF	;expected
        \\    RP,0x000000000000000000000001,0x400000008000000000000000
        \\       0x000000000000000000000000,ZE+UF	;expected
        \\    RP,0x000000000000000000000001,0x400100008000000000000000
        \\       0x000000000000000000000000,ZE+UF	;expected
        \\!!! テストした範囲のみ
        if(bitand(fpsr,UF),
           \\FSGLMULと異なり、3/4,3/2,3は含まれない
           if((abs(x)==EXDDEMIN)&&((abs(y)==1/4)||(abs(y)==1/2)||(abs(y)==1)||(abs(y)==2)||(abs(y)==4)),
              z=if(x*y<0,-Rei,Rei);
              fpsr=UF)));
     \\オーバーフローしたときの返却値を調整する
     \\  アンダーフローしたときの返却値は±XSGDEMINだが、
     \\  オーバーフローしたときの返却値は±EXDNOMAXになる
     \\  このときだけ仮数部が24bitで表現できない値を返す
     if(bitand(fpsr,OF),
        if(abs(z)==XSGNOMAX,
           z=sign(z)*EXDNOMAX));
     z)
  }
make_fsgldiv88x()={
  make_fop2to1("fsgldiv88x",
               "fsgldiv",
               -1,  \\仮数部が24bitで表現できない値を返す場合があるのでSGLは不可
               MC68881+MC68882+FPSP040,
               append(DATA_SPECIAL,
                      DATA_EXTENDED,
                      DATA_BINARY),
               fsgldiv88x_func)
  }


\\----------------------------------------------------------------------------------------
\\  FSGLMUL.X FPm,FPn
\\----------------------------------------------------------------------------------------
fsglmul060_func(x,y,rp,rm)={
  my(z);
  \\引数の仮数部を24bitに切り捨てる
  \\  このときEXDDEMINをReiにしてはならない
  \\  Inf*EXDDEMIN=Infであり、Inf*Rei=NaN,OEではない
  x=roundsgl(x,RZ);
  y=roundsgl(y,RZ);
  fpsr=0;
  if((x==NaN)||(y==NaN),NaN,
     ((x==Rei)||(x==-Rei))&&((y==Inf)||(y==-Inf)),fpsr=bitor(fpsr,OE);NaN,  \\(±0)*(±Inf)=NaN,OE
     ((x==Inf)||(x==-Inf))&&((y==Rei)||(y==-Rei)),fpsr=bitor(fpsr,OE);NaN,  \\(±Inf)*(±0)=NaN,OE
     ((x==Rei)||(x==-Rei))&&((y==Rei)||(y==-Rei)),if(x==Rei,1,-1)*if(y==Rei,1,-1)*Rei,  \\(±0)*(±0)=±0
     ((x==Inf)||(x==-Inf))&&((y==Inf)||(y==-Inf)),if(x==Inf,1,-1)*if(y==Inf,1,-1)*Inf,  \\(±Inf)*(±Inf)=±Inf
     (y==Rei)||(y==-Rei),sign(x)*if(y==Rei,1,-1)*Rei,  \\(±x)*(±0)=±0
     (y==Inf)||(y==-Inf),sign(x)*if(y==Inf,1,-1)*Inf,  \\(±x)*(±Inf)=±Inf
     (x==Rei)||(x==-Rei),if(x==Rei,1,-1)*sign(y)*Rei,  \\(±0)*(±y)=±0
     (x==Inf)||(x==-Inf),if(x==Inf,1,-1)*sign(y)*Inf,  \\(±Inf)*(±y)=±Inf
     z=xsg(x*y,rm);
     \\オーバーフローしたときの返却値を調整する
     \\  アンダーフローしたときの返却値は±XSGDEMINだが、
     \\  オーバーフローしたときの返却値は±EXDNOMAXになる
     \\  このときだけ仮数部が24bitで表現できない値を返す
     if(bitand(fpsr,OF),
        if(abs(z)==XSGNOMAX,
           z=sign(z)*EXDNOMAX));
     z)
  }
make_fsglmul060()={
  make_fop2to1("fsglmul060",
               "fsglmul",
               -1,  \\仮数部が24bitで表現できない値を返す場合があるのでSGLは不可
               MC68060+FPSP060,
               append(DATA_SPECIAL,
                      DATA_EXTENDED,
                      DATA_BINARY),
               fsglmul060_func)
  }
fsglmul88x_func(x,y,rp,rm)={
  my(z);
  \\引数の仮数部を24bitに切り捨てる
  \\  このときEXDDEMINをReiにしてはならない
  \\  Inf*EXDDEMIN=Infであり、Inf*Rei=NaN,OEではない
  x=roundsgl(x,RZ);
  y=roundsgl(y,RZ);
  fpsr=0;
  if((x==NaN)||(y==NaN),NaN,
     ((x==Rei)||(x==-Rei))&&((y==Inf)||(y==-Inf)),fpsr=bitor(fpsr,OE);NaN,  \\(±0)*(±Inf)=NaN,OE
     ((x==Inf)||(x==-Inf))&&((y==Rei)||(y==-Rei)),fpsr=bitor(fpsr,OE);NaN,  \\(±Inf)*(±0)=NaN,OE
     ((x==Rei)||(x==-Rei))&&((y==Rei)||(y==-Rei)),if(x==Rei,1,-1)*if(y==Rei,1,-1)*Rei,  \\(±0)*(±0)=±0
     ((x==Inf)||(x==-Inf))&&((y==Inf)||(y==-Inf)),if(x==Inf,1,-1)*if(y==Inf,1,-1)*Inf,  \\(±Inf)*(±Inf)=±Inf
     (y==Rei)||(y==-Rei),sign(x)*if(y==Rei,1,-1)*Rei,  \\(±x)*(±0)=±0
     (y==Inf)||(y==-Inf),sign(x)*if(y==Inf,1,-1)*Inf,  \\(±x)*(±Inf)=±Inf
     (x==Rei)||(x==-Rei),if(x==Rei,1,-1)*sign(y)*Rei,  \\(±0)*(±y)=±0
     (x==Inf)||(x==-Inf),if(x==Inf,1,-1)*sign(y)*Inf,  \\(±Inf)*(±y)=±Inf
     z=xsg(x*y,rm);
     if(TEST_HARD_FSGLMUL,
        \\アンダーフローしたときの返却値を調整する
        \\  RPまたはRMなのに絶対値が切り上げられず、不正確な結果なのにX2がセットされないことがある
        \\    RP,0x000000000000000000000001,0x000000000000000000000001
        \\       0x000000000000010000000000,UF+X2+AU+AX	;expected
        \\    RP,0x000000000000000000000001,0x3bcd00008000000000000000
        \\       0x000000000000010000000000,UF+X2+AU+AX	;expected
        \\    RP,0x000000000000000000000001,0x3ffd00008000000000000000
        \\       0x000000000000000000000000,ZE+UF	;expected
        \\    RP,0x000000000000000000000001,0x3ffe00008000000000000000
        \\       0x000000000000000000000000,ZE+UF	;expected
        \\    RP,0x000000000000000000000001,0x3fff00008000000000000000
        \\       0x000000000000000000000000,ZE+UF	;expected
        \\    RP,0x000000000000000000000001,0x400000008000000000000000
        \\       0x000000000000000000000000,ZE+UF	;expected
        \\    RP,0x000000000000000000000001,0x400100008000000000000000
        \\       0x000000000000000000000000,ZE+UF	;expected
        \\!!! テストした範囲のみ
        if(bitand(fpsr,UF),
           \\FSGLDIVと異なり、3/4,3/2,3が含まれる
           if(((abs(x)==EXDDEMIN)&&((abs(y)==1/4)||(abs(y)==1/2)||(abs(y)==1)||(abs(y)==2)||(abs(y)==4)||
                                    (abs(y)==3/4)||(abs(y)==3/2)||(abs(y)==3)))||
              ((abs(y)==EXDDEMIN)&&((abs(x)==1/4)||(abs(x)==1/2)||(abs(x)==1)||(abs(x)==2)||(abs(x)==4)||
                                    (abs(x)==3/4)||(abs(x)==3/2)||(abs(x)==3))),
              z=if(x*y<0,-Rei,Rei);
              fpsr=UF)));
     \\オーバーフローしたときの返却値を調整する
     \\  アンダーフローしたときの返却値は±XSGDEMINだが、
     \\  オーバーフローしたときの返却値は±EXDNOMAXになる
     \\  このときだけ仮数部が24bitで表現できない値を返す
     if(bitand(fpsr,OF),
        if(abs(z)==XSGNOMAX,
           z=sign(z)*EXDNOMAX));
     z)
  }
make_fsglmul88x()={
  make_fop2to1("fsglmul88x",
               "fsglmul",
               -1,  \\仮数部が24bitで表現できない値を返す場合があるのでSGLは不可
               MC68881+MC68882+FPSP040,
               append(DATA_SPECIAL,
                      DATA_EXTENDED,
                      DATA_BINARY),
               fsglmul88x_func)
  }


\\----------------------------------------------------------------------------------------
\\  FSIN.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fsin()={
  my(y);
  make_fop1to1("fsin",
               "fsin",
               -2,
               MC68881+MC68882+FPSP040+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND,
                      DATA_ZERO_PLUS,
                      DATA_TRIGONOMETRIC),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,fpsr=bitor(fpsr,OE);NaN,  \\sin(-Inf)=NaN,OE
                                x==-Rei,-Rei,  \\sin(-0)=-0
                                x==Rei,Rei,  \\sin(+0)=+0
                                x==Inf,fpsr=bitor(fpsr,OE);NaN,  \\sin(+Inf)=NaN,OE
                                NaN),
                             fpsr=bitor(fpsr,X2);
                             y=roundxxx(sin(x),rp,rm);
                             y=originUpperLower(y,x,rp,rm);
                             y=xxx(y,rp,rm);
                             correctUnderflow(y,rp)))
  }


\\----------------------------------------------------------------------------------------
\\  FSINCOS.X FPm,FPc:FPs
\\----------------------------------------------------------------------------------------
make_fsincos()={
  my(y);
  make_fop1to2("fsincos",
               "fsincos",
               -2,
               MC68881+MC68882+FPSP040+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND,
                      DATA_ZERO_PLUS,
                      DATA_TRIGONOMETRIC),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,fpsr=bitor(fpsr,OE);NaN,  \\cos(-Inf)=NaN,OE
                                x==-Rei,1,  \\cos(-0)=1
                                x==Rei,1,  \\cos(+0)=1
                                x==Inf,fpsr=bitor(fpsr,OE);NaN,  \\cos(+Inf)=NaN,OE
                                NaN),
                             fpsr=bitor(fpsr,X2);
                             y=roundxxx(cos(x),rp,rm);
                             if(type(y)!="t_POL",
                                if(y==1,if((rm==RZ)||(rm==RM),y=nextdown(1,rp)));
                                if(y==-1,if((rm==RZ)||(rm==RP),y=nextup(1,rp))));
                             xxx(y,rp,rm)),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,fpsr=bitor(fpsr,OE);NaN,  \\sin(-Inf)=NaN,OE
                                x==-Rei,-Rei,  \\sin(-0)=-0
                                x==Rei,Rei,  \\sin(+0)=+0
                                x==Inf,fpsr=bitor(fpsr,OE);NaN,  \\sin(+Inf)=NaN,OE
                                NaN),
                             fpsr=bitor(fpsr,X2);
                             y=roundxxx(sin(x),rp,rm);
                             y=originUpperLower(y,x,rp,rm);
                             y=xxx(y,rp,rm);
                             correctUnderflow(y,rp)))
  }


\\----------------------------------------------------------------------------------------
\\  FSINH.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fsinh()={
  my(y);
  make_fop1to1("fsinh",
               "fsinh",
               -2,
               MC68881+MC68882+FPSP040+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND,
                      DATA_ZERO_PLUS),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,-Inf,  \\sinh(-Inf)=-Inf
                                x==-Rei,-Rei,  \\sinh(-0)=-0
                                x==Rei,Rei,  \\sinh(+0)=+0
                                x==Inf,Inf,  \\sinh(+Inf)=+Inf
                                NaN),
                             fpsr=bitor(fpsr,X2);
                             if(x<=-65536,fpsr=bitor(fpsr,OF);xxx(-Inf,rp,rm),  \\sinh(-big)=-Inf,OF
                                65536<=x,fpsr=bitor(fpsr,OF);xxx(Inf,rp,rm),  \\sinh(+big)=+Inf,OF
                                y=roundxxx(sinh(x),rp,rm);
                                y=originLowerUpper(y,x,rp,rm);
                                y=xxx(y,rp,rm);
                                correctUnderflow(y,rp))))
  }


\\----------------------------------------------------------------------------------------
\\  FSMOVE.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fsmove()={
  make_fop1to1("fsmove",
               "fsmove",
               -1,
               MC68040+FPSP040+MC68060+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,-Inf,  \\smove(-Inf)=-Inf
                                x==-Rei,-Rei,  \\smove(-0)=-0
                                x==Rei,Rei,  \\smove(+0)=+0
                                x==Inf,Inf,  \\smove(+Inf)=+Inf
                                NaN),
                             sgl(x,rm)))
  }


\\----------------------------------------------------------------------------------------
\\  FSMUL.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fsmul()={
  make_fop2to1("fsmul",
               "fsmul",
               -1,
               MC68040+FPSP040+MC68060+FPSP060,
               append(DATA_SPECIAL,
                      DATA_EXTENDED,
                      DATA_BINARY),
               (x,y,rp,rm)->if((x==NaN)||(y==NaN),NaN,
                               ((x==Rei)||(x==-Rei))&&((y==Inf)||(y==-Inf)),fpsr=bitor(fpsr,OE);NaN,  \\(±0)*(±Inf)=NaN,OE
                               ((x==Inf)||(x==-Inf))&&((y==Rei)||(y==-Rei)),fpsr=bitor(fpsr,OE);NaN,  \\(±Inf)*(±0)=NaN,OE
                               ((x==Rei)||(x==-Rei))&&((y==Rei)||(y==-Rei)),if(x==Rei,1,-1)*if(y==Rei,1,-1)*Rei,  \\(±0)*(±0)=±0
                               ((x==Inf)||(x==-Inf))&&((y==Inf)||(y==-Inf)),if(x==Inf,1,-1)*if(y==Inf,1,-1)*Inf,  \\(±Inf)*(±Inf)=±Inf
                               (y==Rei)||(y==-Rei),sign(x)*if(y==Rei,1,-1)*Rei,  \\(±x)*(±0)=±0
                               (y==Inf)||(y==-Inf),sign(x)*if(y==Inf,1,-1)*Inf,  \\(±x)*(±Inf)=±Inf
                               (x==Rei)||(x==-Rei),if(x==Rei,1,-1)*sign(y)*Rei,  \\(±0)*(±y)=±0
                               (x==Inf)||(x==-Inf),if(x==Inf,1,-1)*sign(y)*Inf,  \\(±Inf)*(±y)=±Inf
                               sgl(x*y,rm)));
  }


\\----------------------------------------------------------------------------------------
\\  FSNEG.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fsneg()={
  make_fop1to1("fsneg",
               "fsneg",
               -1,
               MC68040+FPSP040+MC68060+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,Inf,  \\sneg(-Inf)=+Inf
                                x==-Rei,Rei,  \\sneg(-0)=+0
                                x==Rei,-Rei,  \\sneg(+0)=-0
                                x==Inf,-Inf,  \\sneg(+Inf)=-Inf
                                NaN),
                             sgl(-x,rm)))
  }


\\----------------------------------------------------------------------------------------
\\  FSQRT.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fsqrt()={
  my(y);
  make_fop1to1("fsqrt",
               "fsqrt",
               -1,
               MC68881+MC68882+MC68040+FPSP040+MC68060+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND,
                      DATA_ZERO_PLUS,
                      DATA_ONE_MINUS,
                      DATA_ONE_PLUS),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,fpsr=bitor(fpsr,OE);NaN,  \\sqrt(-Inf)=NaN,OE
                                x==-Rei,-Rei,  \\sqrt(-0)=-0
                                x==Rei,Rei,  \\sqrt(+0)=+0
                                x==Inf,Inf,  \\sqrt(+Inf)=+Inf
                                NaN),
                             if(x<0,fpsr=bitor(fpsr,OE);NaN,  \\sqrt(-x)=NaN,OE
                                y=xxx(sqrt(x),rp,rm);
                                if(y^2!=x,fpsr=bitor(fpsr,X2));
                                y)))
  }


\\----------------------------------------------------------------------------------------
\\  FSSQRT.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fssqrt()={
  my(y);
  make_fop1to1("fssqrt",
               "fssqrt",
               -1,
               MC68040+FPSP040+MC68060+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND,
                      DATA_ZERO_PLUS,
                      DATA_ONE_MINUS,
                      DATA_ONE_PLUS),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,fpsr=bitor(fpsr,OE);NaN,  \\ssqrt(-Inf)=NaN,OE
                                x==-Rei,-Rei,  \\ssqrt(-0)=-0
                                x==Rei,Rei,  \\ssqrt(+0)=+0
                                x==Inf,Inf,  \\ssqrt(+Inf)=+Inf
                                NaN),
                             if(x<0,fpsr=bitor(fpsr,OE);NaN,  \\ssqrt(-x)=NaN,OE
                                y=sgl(sqrt(x),rm);
                                if(y^2!=x,fpsr=bitor(fpsr,X2));
                                y)))
  }


\\----------------------------------------------------------------------------------------
\\  FSSUB.X FPm,FPn
\\----------------------------------------------------------------------------------------
fssub_func(x,y,rp,rm)={
  my(z);
  if(x==0,x=Rei);
  if(y==0,y=Rei);
  if((x==NaN)||(y==NaN),NaN,
     (x==Inf)&&(y==Inf),fpsr=bitor(fpsr,OE);NaN,  \\(+Inf)-(+Inf)=NaN,OE
     (x==-Inf)&&(y==-Inf),fpsr=bitor(fpsr,OE);NaN,  \\(-Inf)-(-Inf)=NaN,OE
     (x==Rei)&&(y==-Rei),Rei,  \\(+0)-(-0)=+0
     (x==-Rei)&&(y==Rei),-Rei,  \\(-0)-(+0)=-0
     (x==Rei)&&(y==Rei),if(rm==RM,-Rei,Rei),  \\(+0)-(+0)=±0
     (x==-Rei)&&(y==-Rei),if(rm==RM,-Rei,Rei),  \\(-0)-(-0)=±0
     (y==Inf)||(y==-Inf),-y,  \\(±x)-(±Inf)=∓Inf
     (x==Inf)||(x==-Inf),x,  \\(±Inf)-(±y)=±Inf
     (y==Rei)||(y==-Rei),sgl(x,rm),  \\(±x)-(±0)=(±x)
     (x==Rei)||(x==-Rei),sgl(-y,rm),  \\(±0)-(±y)=∓y
     z=x-y;
     if(z==0,
        if(rm==RM,-Rei,Rei),
        sgl(z,rm)))
  }
make_fssub()={
  make_fop2to1("fssub",
               "fssub",
               -1,
               MC68040+FPSP040+MC68060+FPSP060,
               append(DATA_SPECIAL,
                      DATA_EXTENDED,
                      DATA_BINARY),
               fssub_func)
  }


\\----------------------------------------------------------------------------------------
\\  FSUB.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_fsub()={
  my(z);
  make_fop2to1("fsub",
               "fsub",
               -1,
               MC68881+MC68882+MC68040+FPSP040+MC68060+FPSP060,
               append(DATA_SPECIAL,
                      DATA_EXTENDED,
                      DATA_BINARY),
               (x,y,rp,rm)->if((x==NaN)||(y==NaN),NaN,
                               (x==Inf)&&(y==Inf),fpsr=bitor(fpsr,OE);NaN,  \\(+Inf)-(+Inf)=NaN,OE
                               (x==-Inf)&&(y==-Inf),fpsr=bitor(fpsr,OE);NaN,  \\(-Inf)-(-Inf)=NaN,OE
                               (x==Rei)&&(y==-Rei),Rei,  \\(+0)-(-0)=+0
                               (x==-Rei)&&(y==Rei),-Rei,  \\(-0)-(+0)=-0
                               (x==Rei)&&(y==Rei),if(rm==RM,-Rei,Rei),  \\(+0)-(+0)=±0
                               (x==-Rei)&&(y==-Rei),if(rm==RM,-Rei,Rei),  \\(-0)-(-0)=±0
                               (y==Inf)||(y==-Inf),-y,  \\(±x)-(±Inf)=∓Inf
                               (x==Inf)||(x==-Inf),x,  \\(±Inf)-(±y)=±Inf
                               z=xxx(if((x==Rei)||(x==-Rei),0,x)-
                                     if((y==Rei)||(y==-Rei),0,y),rp,rm);  \\(±x)-(±0)=±x,(±0)-(±y)=∓y
                               if((z==Rei)||(z==-Rei),z=if(rm==RM,-Rei,Rei));
                               z))
  }


\\----------------------------------------------------------------------------------------
\\  FTAN.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_ftan()={
  my(y);
  make_fop1to1("ftan",
               "ftan",
               -2,
               MC68881+MC68882+FPSP040+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND,
                      DATA_ZERO_PLUS,
                      DATA_TRIGONOMETRIC),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,fpsr=bitor(fpsr,OE);NaN,  \\tan(-Inf)=NaN,OE
                                x==-Rei,-Rei,  \\tan(-0)=-0
                                x==Rei,Rei,  \\tan(+0)=+0
                                x==Inf,fpsr=bitor(fpsr,OE);NaN,  \\tan(+Inf)=NaN,OE
                                NaN),
                             fpsr=bitor(fpsr,X2);
                             y=roundxxx(tan(x),rp,rm);
                             y=originLowerUpper(y,x,rp,rm);
                             y=xxx(y,rp,rm);
                             correctUnderflow(y,rp)))
  }


\\----------------------------------------------------------------------------------------
\\  FTANH.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_ftanh()={
  my(y);
  make_fop1to1("ftanh",
               "ftanh",
               -2,
               MC68881+MC68882+FPSP040+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND,
                      DATA_ZERO_PLUS),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,-1,  \\tanh(-Inf)=-1
                                x==-Rei,-Rei,  \\tanh(-0)=-0
                                x==Rei,Rei,  \\tanh(+0)=+0
                                x==Inf,1,  \\tanh(+Inf)=+1
                                NaN),
                             fpsr=bitor(fpsr,X2);
                             if(x<=-256,if((rm==RZ)||(rm==RP),nextup(-1,rp),-1),  \\tanh(-big)=-1
                                256<=x,if((rm==RZ)||(rm==RM),nextdown(1,rp),1),  \\tanh(+big)=+1
                                y=roundxxx(tanh(x),rp,rm);
                                y=originUpperLower(y,x,rp,rm);
                                y=xxx(y,rp,rm);
                                correctUnderflow(y,rp))))
  }


\\----------------------------------------------------------------------------------------
\\  FTENTOX.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_ftentox()={
  make_fop1to1("ftentox",
               "ftentox",
               -2,
               MC68881+MC68882+FPSP040+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND,
                      DATA_ZERO_PLUS),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,Rei,  \\tentox(-Inf)=+0
                                x==-Rei,1,  \\tentox(-0)=1
                                x==Rei,1,  \\tentox(+0)=1
                                x==Inf,Inf,  \\tentox(+Inf)=+Inf
                                NaN),
                             fpsr=bitor(fpsr,X2);
                             if(x<=-65536,fpsr=bitor(fpsr,UF);xxx(Rei,rp,rm),  \\tentox(-big)=+0,UF
                                65536<x,fpsr=bitor(fpsr,OF);xxx(Inf,rp,rm),  \\tentox(+big)=+Inf,OF
                                xxx(10^x,rp,rm))))
  }


\\----------------------------------------------------------------------------------------
\\  FTRAPcc
\\----------------------------------------------------------------------------------------
make_ftrapcc060()={
  my(m,z,n,a);
  print("making ftrapcc060");
  asm(
"
;--------------------------------------------------------------------------------
;	FTRAPcc
;--------------------------------------------------------------------------------
	.cpu	68030
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
ftrapcc060_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#FPSP060,-(sp)
	peamsg	'FTRAPCC'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: FTRAPcc',13,10
;------------------------------------------------
;	d1	actual result upper
;	d2	actual result lower
;	d3	actual status
;	d5	cc=0..31
;	d6	fpsr=(mzin=0..15)<<24
;	d7	0=failed,1=successful
;	a0	expected result upper,expected result lower,expected status,...
;	a1	expected result upper
;	a2	expected result lower
;	a3	expected status
;------------------------------------------------
	lea.l	push_decompressed,a0	;expected result upper,expected result lower,expected status,...
;decompress data
	move.l	a0,-(sp)
	pea.l	ftrapcc060_expected_compressed
	jbsr	decompress
	addq.l	#8,sp
	move.l	#0<<24,d6		;fpsr=(mzin=0..15)<<24
66:
	moveq.l	#0,d5			;cc=0..31
55:
;FTRAPcc
	fmove.l	#0,fpcr
	fmove.l	d6,fpsr			;fpsr
	clr.l	trapv_occurred		;actual result upper
	jsr	([ftrapcc060_execute,za0,d5.l*4])	;EXECUTE
					;actual result lower
	move.l	trapv_occurred,d2	;actual result upper
	fmove.l	fpsr,d3			;actual status
;
	movem.l	(a0),a1-a3		;expected result upper,expected result lower,expected status
;
	movem.l	d1-d3/a1-a3,-(sp)	;actual result upper,actual result lower,actual status,expected result upper,expected result lower,expected status
	jbsr	test_double
	lea.l	24(sp),sp
	move.l	d0,d7			;0=failed,1=successful
;
	move.l	d7,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FTRAP'
	putstr	(uppercase_cc,za0,d5.l*4)
	putmsg	' @'
	move.l	d6,-(sp)		;fpsr
	jbsr	printfpsr
	addq.l	#4,sp
	putcrlf
	move.l	d7,-(sp)		;0=failed,1=successful
	movem.l	d1-d3/a1-a3,-(sp)	;actual result upper,actual result lower,actual status,expected result upper,expected result lower,expected status
	jbsr	output_double
	lea.l	28(sp),sp
@@:
;
	lea.l	(12,a0),a0		;expected result upper,expected result lower,expected status,...
;
	addq.w	#1,d5			;cc++
	cmp.w	#31,d5			;cc=0..31
	bls	55b
;
	add.l	#1<<24,d6		;mzin++
	cmp.l	#15<<24,d6		;fpsr=(mzin=0..15)<<24
	bls	66b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts

	.align	4
ftrapcc060_execute::
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
	.dc.l	ftrapcc060_execute_&cc
  .endm
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
ftrapcc060_execute_&cc::
	moveq.l	#3,d1			;actual result upper. 3=too long
	FTRAP&cc			;EXECUTE
	subq.l	#1,d1			;actual result upper. 0=ok
	subq.l	#1,d1			;actual result upper. 1=too long
	subq.l	#1,d1			;actual result upper. 2=too long
	rts
  .endm
	.cpu	68000

	.align	4
ftrapcc060_expected_compressed::
");
  push_start();
  for(mzin=0,15,
      m=bitand(mzin>>3,1);
      z=bitand(mzin>>2,1);
      n=bitand(mzin>>0,1);
      a=[
        0,           \\000000  F
        z,           \\000001  EQ
        !(n||z||m),  \\000010  OGT
        z||!(n||m),  \\000011  OGE
        m&&!(n||z),  \\000100  OLT
        z||(m&&!n),  \\000101  OLE
        !(n||z),     \\000110  OGL
        !n,          \\000111  OR
        n,           \\001000  UN
        n||z,        \\001001  UEQ
        n||!(m||z),  \\001010  UGT
        n||(z||!m),  \\001011  UGE
        n||(m&&!z),  \\001100  ULT
        n||z||m,     \\001101  ULE
        !z,          \\001110  NE
        1            \\001111  T
        ];
      for(cc=0,15,
          push(4,0);
          push(4,a[1+cc]);
          push(4,mzin<<24));
      for(cc=16,31,
          push(4,0);
          push(4,a[1+cc-16]);
          push(4,(mzin<<24)+if(n,BS+AV,0))));
  push_end()
  }
make_ftrapcc88x()={
  my(m,z,n,a);
  print("making ftrapcc88x");
  asm(
"
;--------------------------------------------------------------------------------
;	FTRAPcc
;--------------------------------------------------------------------------------
	.cpu	68030
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
ftrapcc88x_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#MC68881+MC68882+MC68040+FPSP040,-(sp)
	peamsg	'FTRAPCC'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: FTRAPcc',13,10
;------------------------------------------------
;	d1	actual result upper
;	d2	actual result lower
;	d3	actual status
;	d5	cc=0..31
;	d6	fpsr=(mzin=0..15)<<24
;	d7	0=failed,1=successful
;	a0	expected result upper,expected result lower,expected status,...
;	a1	expected result upper
;	a2	expected result lower
;	a3	expected status
;------------------------------------------------
	lea.l	push_decompressed,a0	;expected result upper,expected result lower,expected status,...
;decompress data
	move.l	a0,-(sp)
	pea.l	ftrapcc88x_expected_compressed
	jbsr	decompress
	addq.l	#8,sp
	move.l	#0<<24,d6		;fpsr=(mzin=0..15)<<24
66:
	moveq.l	#0,d5			;cc=0..31
55:
;FTRAPcc
	fmove.l	#0,fpcr
	fmove.l	d6,fpsr			;fpsr
	clr.l	trapv_occurred		;actual result lower
	jsr	([ftrapcc88x_execute,za0,d5.l*4])	;EXECUTE
					;actual result upper
	move.l	trapv_occurred,d2	;actual result lower
	fmove.l	fpsr,d3			;actual status
;
	movem.l	(a0),a1-a3		;expected result upper,expected result lower,expected status
;
	movem.l	d1-d3/a1-a3,-(sp)	;actual result upper,actual result lower,actual status,expected result upper,expected result lower,expected status
	jbsr	test_double
	lea.l	24(sp),sp
	move.l	d0,d7			;0=failed,1=successful
;
	move.l	d7,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FTRAP'
	putstr	(uppercase_cc,za0,d5.l*4)
	putmsg	' @'
	move.l	d6,-(sp)		;fpsr
	jbsr	printfpsr
	addq.l	#4,sp
	putcrlf
	move.l	d7,-(sp)		;0=failed,1=successful
	movem.l	d1-d3/a1-a3,-(sp)	;actual result upper,actual result lower,actual status,expected result upper,expected result lower,expected status
	jbsr	output_double
	lea.l	28(sp),sp
@@:
;
	lea.l	(12,a0),a0		;expected result upper,expected result lower,expected status,...
;
	addq.w	#1,d5			;cc++
	cmp.w	#31,d5			;cc=0..31
	bls	55b
;
	add.l	#1<<24,d6		;mzin++
	cmp.l	#15<<24,d6		;fpsr=(mzin=0..15)<<24
	bls	66b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts

	.align	4
ftrapcc88x_execute::
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
	.dc.l	ftrapcc88x_execute_&cc
  .endm
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
ftrapcc88x_execute_&cc::
	moveq.l	#3,d1			;actual result upper. 3=too long
	FTRAP&cc			;EXECUTE
	subq.l	#1,d1			;actual result upper. 0=ok
	subq.l	#1,d1			;actual result upper. 1=too long
	subq.l	#1,d1			;actual result upper. 2=too long
	rts
  .endm
	.cpu	68000

	.align	4
ftrapcc88x_expected_compressed::
");
  push_start();
  for(mzin=0,15,
      m=bitand(mzin>>3,1);
      z=bitand(mzin>>2,1);
      n=bitand(mzin>>0,1);
      a=[
        0,           \\000000  F
        z,           \\000001  EQ
        !(n||z||m),  \\000010  OGT
        z||!(n||m),  \\000011  OGE
        m&&!(n||z),  \\000100  OLT
        z||(m&&!n),  \\000101  OLE
        !(n||z),     \\000110  OGL
        z||!n,       \\000111  OR
        n,           \\001000  UN
        n||z,        \\001001  UEQ
        n||!(m||z),  \\001010  UGT
        n||(z||!m),  \\001011  UGE
        n||(m&&!z),  \\001100  ULT
        n||z||m,     \\001101  ULE
        n||!z,       \\001110  NE
        1            \\001111  T
        ];
      for(cc=0,15,
          push(4,0);
          push(4,a[1+cc]);
          push(4,mzin<<24));
      for(cc=16,31,
          push(4,0);
          push(4,a[1+cc-16]);
          push(4,(mzin<<24)+if(n,BS+AV,0))));
  push_end()
  }


\\----------------------------------------------------------------------------------------
\\  FTRAPcc.L #<data>
\\----------------------------------------------------------------------------------------
make_ftrapccl060()={
  my(m,z,n,a);
  print("making ftrapccl060");
  asm(
"
;--------------------------------------------------------------------------------
;	FTRAPcc.L #<data>
;--------------------------------------------------------------------------------
	.cpu	68030
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
ftrapccl060_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#FPSP060,-(sp)
	peamsg	'FTRAPCC.L #<DATA>'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: FTRAPcc.L #<data>',13,10
;------------------------------------------------
;	d1	actual result upper
;	d2	actual result lower
;	d3	actual status
;	d5	cc=0..31
;	d6	fpsr=(mzin=0..15)<<24
;	d7	0=failed,1=successful
;	a0	expected result upper,expected result lower,expected status,...
;	a1	expected result upper
;	a2	expected result lower
;	a3	expected status
;------------------------------------------------
	lea.l	push_decompressed,a0	;expected result upper,expected result lower,expected status,...
;decompress data
	move.l	a0,-(sp)
	pea.l	ftrapccl060_expected_compressed
	jbsr	decompress
	addq.l	#8,sp
	move.l	#0<<24,d6		;fpsr=(mzin=0..15)<<24
66:
	moveq.l	#0,d5			;cc=0..31
55:
;FTRAPcc.L #<data>
	fmove.l	#0,fpcr
	fmove.l	d6,fpsr			;fpsr
	clr.l	trapv_occurred		;actual result upper
	jsr	([ftrapccl060_execute,za0,d5.l*4])	;EXECUTE
					;actual result lower
	move.l	trapv_occurred,d2	;actual result upper
	fmove.l	fpsr,d3			;actual status
;
	movem.l	(a0),a1-a3		;expected result upper,expected result lower,expected status
;
	movem.l	d1-d3/a1-a3,-(sp)	;actual result upper,actual result lower,actual status,expected result upper,expected result lower,expected status
	jbsr	test_double
	lea.l	24(sp),sp
	move.l	d0,d7			;0=failed,1=successful
;
	move.l	d7,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FTRAP'
	putstr	(uppercase_cc,za0,d5.l*4)
	putmsg	'.L #<data> @'
	move.l	d6,-(sp)		;fpsr
	jbsr	printfpsr
	addq.l	#4,sp
	putcrlf
	move.l	d7,-(sp)		;0=failed,1=successful
	movem.l	d1-d3/a1-a3,-(sp)	;actual result upper,actual result lower,actual status,expected result upper,expected result lower,expected status
	jbsr	output_double
	lea.l	28(sp),sp
@@:
;
	lea.l	(12,a0),a0		;expected result upper,expected result lower,expected status,...
;
	addq.w	#1,d5			;cc++
	cmp.w	#31,d5			;cc=0..31
	bls	55b
;
	add.l	#1<<24,d6		;mzin++
	cmp.l	#15<<24,d6		;fpsr=(mzin=0..15)<<24
	bls	66b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts

	.align	4
ftrapccl060_execute::
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
	.dc.l	ftrapccl060_execute_&cc
  .endm
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
ftrapccl060_execute_&cc::
	moveq.l	#3,d1			;actual result upper. 3=too long
	FTRAP&cc.L	#$53815381	;EXECUTE. $5381=subq.l #1,d1. -2=too short. -1=too short
	subq.l	#1,d1			;actual result upper. 0=ok
	subq.l	#1,d1			;actual result upper. 1=too long
	subq.l	#1,d1			;actual result upper. 2=too long
	rts
  .endm
	.cpu	68000

	.align	4
ftrapccl060_expected_compressed::
");
  push_start();
  for(mzin=0,15,
      m=bitand(mzin>>3,1);
      z=bitand(mzin>>2,1);
      n=bitand(mzin>>0,1);
      a=[
        0,           \\000000  F
        z,           \\000001  EQ
        !(n||z||m),  \\000010  OGT
        z||!(n||m),  \\000011  OGE
        m&&!(n||z),  \\000100  OLT
        z||(m&&!n),  \\000101  OLE
        !(n||z),     \\000110  OGL
        !n,          \\000111  OR
        n,           \\001000  UN
        n||z,        \\001001  UEQ
        n||!(m||z),  \\001010  UGT
        n||(z||!m),  \\001011  UGE
        n||(m&&!z),  \\001100  ULT
        n||z||m,     \\001101  ULE
        !z,          \\001110  NE
        1            \\001111  T
        ];
      for(cc=0,15,
          push(4,0);
          push(4,a[1+cc]);
          push(4,mzin<<24));
      for(cc=16,31,
          push(4,0);
          push(4,a[1+cc-16]);
          push(4,(mzin<<24)+if(n,BS+AV,0))));
  push_end()
  }
make_ftrapccl88x()={
  my(m,z,n,a);
  print("making ftrapccl88x");
  asm(
"
;--------------------------------------------------------------------------------
;	FTRAPcc.L #<data>
;--------------------------------------------------------------------------------
	.cpu	68030
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
ftrapccl88x_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#MC68881+MC68882+MC68040+FPSP040,-(sp)
	peamsg	'FTRAPCC.L #<DATA>'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: FTRAPcc.L #<data>',13,10
;------------------------------------------------
;	d1	actual result upper
;	d2	actual result lower
;	d3	actual status
;	d5	cc=0..31
;	d6	fpsr=(mzin=0..15)<<24
;	d7	0=failed,1=successful
;	a0	expected result upper,expected result lower,expected status,...
;	a1	expected result upper
;	a2	expected result lower
;	a3	expected status
;------------------------------------------------
	lea.l	push_decompressed,a0	;expected result upper,expected result lower,expected status,...
;decompress data
	move.l	a0,-(sp)
	pea.l	ftrapccl88x_expected_compressed
	jbsr	decompress
	addq.l	#8,sp
	move.l	#0<<24,d6		;fpsr=(mzin=0..15)<<24
66:
	moveq.l	#0,d5			;cc=0..31
55:
;FTRAPcc.L #<data>
	fmove.l	#0,fpcr
	fmove.l	d6,fpsr			;fpsr
	clr.l	trapv_occurred		;actual result lower
	jsr	([ftrapccl88x_execute,za0,d5.l*4])	;EXECUTE
					;actual result upper
	move.l	trapv_occurred,d2	;actual result lower
	fmove.l	fpsr,d3			;actual status
;
	movem.l	(a0),a1-a3		;expected result upper,expected result lower,expected status
;
	movem.l	d1-d3/a1-a3,-(sp)	;actual result upper,actual result lower,actual status,expected result upper,expected result lower,expected status
	jbsr	test_double
	lea.l	24(sp),sp
	move.l	d0,d7			;0=failed,1=successful
;
	move.l	d7,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FTRAP'
	putstr	(uppercase_cc,za0,d5.l*4)
	putmsg	'.L #<data> @'
	move.l	d6,-(sp)		;fpsr
	jbsr	printfpsr
	addq.l	#4,sp
	putcrlf
	move.l	d7,-(sp)		;0=failed,1=successful
	movem.l	d1-d3/a1-a3,-(sp)	;actual result upper,actual result lower,actual status,expected result upper,expected result lower,expected status
	jbsr	output_double
	lea.l	28(sp),sp
@@:
;
	lea.l	(12,a0),a0		;expected result upper,expected result lower,expected status,...
;
	addq.w	#1,d5			;cc++
	cmp.w	#31,d5			;cc=0..31
	bls	55b
;
	add.l	#1<<24,d6		;mzin++
	cmp.l	#15<<24,d6		;fpsr=(mzin=0..15)<<24
	bls	66b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts

	.align	4
ftrapccl88x_execute::
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
	.dc.l	ftrapccl88x_execute_&cc
  .endm
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
ftrapccl88x_execute_&cc::
	moveq.l	#3,d1			;actual result upper. 3=too long
	FTRAP&cc.L	#$53815381	;EXECUTE. $5381=subq.l #1,d1. -2=too short. -1=too short
	subq.l	#1,d1			;actual result upper. 0=ok
	subq.l	#1,d1			;actual result upper. 1=too long
	subq.l	#1,d1			;actual result upper. 2=too long
	rts
  .endm
	.cpu	68000

	.align	4
ftrapccl88x_expected_compressed::
");
  push_start();
  for(mzin=0,15,
      m=bitand(mzin>>3,1);
      z=bitand(mzin>>2,1);
      n=bitand(mzin>>0,1);
      a=[
        0,           \\000000  F
        z,           \\000001  EQ
        !(n||z||m),  \\000010  OGT
        z||!(n||m),  \\000011  OGE
        m&&!(n||z),  \\000100  OLT
        z||(m&&!n),  \\000101  OLE
        !(n||z),     \\000110  OGL
        z||!n,       \\000111  OR
        n,           \\001000  UN
        n||z,        \\001001  UEQ
        n||!(m||z),  \\001010  UGT
        n||(z||!m),  \\001011  UGE
        n||(m&&!z),  \\001100  ULT
        n||z||m,     \\001101  ULE
        n||!z,       \\001110  NE
        1            \\001111  T
        ];
      for(cc=0,15,
          push(4,0);
          push(4,a[1+cc]);
          push(4,mzin<<24));
      for(cc=16,31,
          push(4,0);
          push(4,a[1+cc-16]);
          push(4,(mzin<<24)+if(n,BS+AV,0))));
  push_end()
  }


\\----------------------------------------------------------------------------------------
\\  FTRAPcc.W #<data>
\\----------------------------------------------------------------------------------------
make_ftrapccw060()={
  my(m,z,n,a);
  print("making ftrapccw060");
  asm(
"
;--------------------------------------------------------------------------------
;	FTRAPcc.W #<data>
;--------------------------------------------------------------------------------
	.cpu	68030
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
ftrapccw060_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#FPSP060,-(sp)
	peamsg	'FTRAPCC.W #<DATA>'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: FTRAPcc.W #<data>',13,10
;------------------------------------------------
;	d1	actual result upper
;	d2	actual result lower
;	d3	actual status
;	d5	cc=0..31
;	d6	fpsr=(mzin=0..15)<<24
;	d7	0=failed,1=successful
;	a0	expected result upper,expected result lower,expected status,...
;	a1	expected result upper
;	a2	expected result lower
;	a3	expected status
;------------------------------------------------
	lea.l	push_decompressed,a0	;expected result upper,expected result lower,expected status,...
;decompress data
	move.l	a0,-(sp)
	pea.l	ftrapccw060_expected_compressed
	jbsr	decompress
	addq.l	#8,sp
	move.l	#0<<24,d6		;fpsr=(mzin=0..15)<<24
66:
	moveq.l	#0,d5			;cc=0..31
55:
;FTRAPcc.W #<data>
	fmove.l	#0,fpcr
	fmove.l	d6,fpsr			;fpsr
	clr.l	trapv_occurred		;actual result upper
	jsr	([ftrapccw060_execute,za0,d5.l*4])	;EXECUTE
					;actual result lower
	move.l	trapv_occurred,d2	;actual result upper
	fmove.l	fpsr,d3			;actual status
;
	movem.l	(a0),a1-a3		;expected result upper,expected result lower,expected status
;
	movem.l	d1-d3/a1-a3,-(sp)	;actual result upper,actual result lower,actual status,expected result upper,expected result lower,expected status
	jbsr	test_double
	lea.l	24(sp),sp
	move.l	d0,d7			;0=failed,1=successful
;
	move.l	d7,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FTRAP'
	putstr	(uppercase_cc,za0,d5.l*4)
	putmsg	'.W #<data> @'
	move.l	d6,-(sp)		;fpsr
	jbsr	printfpsr
	addq.l	#4,sp
	putcrlf
	move.l	d7,-(sp)		;0=failed,1=successful
	movem.l	d1-d3/a1-a3,-(sp)	;actual result upper,actual result lower,actual status,expected result upper,expected result lower,expected status
	jbsr	output_double
	lea.l	28(sp),sp
@@:
;
	lea.l	(12,a0),a0		;expected result upper,expected result lower,expected status,...
;
	addq.w	#1,d5			;cc++
	cmp.w	#31,d5			;cc=0..31
	bls	55b
;
	add.l	#1<<24,d6		;mzin++
	cmp.l	#15<<24,d6		;fpsr=(mzin=0..15)<<24
	bls	66b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts

	.align	4
ftrapccw060_execute::
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
	.dc.l	ftrapccw060_execute_&cc
  .endm
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
ftrapccw060_execute_&cc::
	moveq.l	#3,d1			;actual result upper. 3=too long
	FTRAP&cc.W	#$5381		;EXECUTE. $5381=subq.l #1,d1. -1=too short
	subq.l	#1,d1			;actual result upper. 0=ok
	subq.l	#1,d1			;actual result upper. 1=too long
	subq.l	#1,d1			;actual result upper. 2=too long
	rts
  .endm
	.cpu	68000

	.align	4
ftrapccw060_expected_compressed::
");
  push_start();
  for(mzin=0,15,
      m=bitand(mzin>>3,1);
      z=bitand(mzin>>2,1);
      n=bitand(mzin>>0,1);
      a=[
        0,           \\000000  F
        z,           \\000001  EQ
        !(n||z||m),  \\000010  OGT
        z||!(n||m),  \\000011  OGE
        m&&!(n||z),  \\000100  OLT
        z||(m&&!n),  \\000101  OLE
        !(n||z),     \\000110  OGL
        !n,          \\000111  OR
        n,           \\001000  UN
        n||z,        \\001001  UEQ
        n||!(m||z),  \\001010  UGT
        n||(z||!m),  \\001011  UGE
        n||(m&&!z),  \\001100  ULT
        n||z||m,     \\001101  ULE
        !z,          \\001110  NE
        1            \\001111  T
        ];
      for(cc=0,15,
          push(4,0);
          push(4,a[1+cc]);
          push(4,mzin<<24));
      for(cc=16,31,
          push(4,0);
          push(4,a[1+cc-16]);
          push(4,(mzin<<24)+if(n,BS+AV,0))));
  push_end()
  }
make_ftrapccw88x()={
  my(m,z,n,a);
  print("making ftrapccw88x");
  asm(
"
;--------------------------------------------------------------------------------
;	FTRAPcc.W #<data>
;--------------------------------------------------------------------------------
	.cpu	68030
regs		reg	d0-d7/a0-a5
cregs		reg	fpcr/fpsr/fpiar
fregs		reg	fp0-fp7
	.offsym	0,_a6
_size:
_regs:	.ds.b	.sizeof.(regs)
_fregs:	.ds.b	.sizeof.(fregs)
_cregs:	.ds.b	.sizeof.(cregs)
_a6:	.ds.l	1
_pc:	.ds.l	1
	.text
	.even
ftrapccw88x_test::
	link.w	a6,#_size
	movem.l	regs,(_regs,a6)
	fmovem.l	cregs,(_cregs,a6)
	fmovem.x	fregs,(_fregs,a6)
;
	move.l	#MC68881+MC68882+MC68040+FPSP040,-(sp)
	peamsg	'FTRAPCC.W #<DATA>'
	jbsr	mnemonic_start
	addq.l	#8,sp
	beq	99f
	putmsg	'test: FTRAPcc.W #<data>',13,10
;------------------------------------------------
;	d1	actual result upper
;	d2	actual result lower
;	d3	actual status
;	d5	cc=0..31
;	d6	fpsr=(mzin=0..15)<<24
;	d7	0=failed,1=successful
;	a0	expected result upper,expected result lower,expected status,...
;	a1	expected result upper
;	a2	expected result lower
;	a3	expected status
;------------------------------------------------
	lea.l	push_decompressed,a0	;expected result upper,expected result lower,expected status,...
;decompress data
	move.l	a0,-(sp)
	pea.l	ftrapccw88x_expected_compressed
	jbsr	decompress
	addq.l	#8,sp
	move.l	#0<<24,d6		;fpsr=(mzin=0..15)<<24
66:
	moveq.l	#0,d5			;cc=0..31
55:
;FTRAPcc.W #<data>
	fmove.l	#0,fpcr
	fmove.l	d6,fpsr			;fpsr
	clr.l	trapv_occurred		;actual result lower
	jsr	([ftrapccw88x_execute,za0,d5.l*4])	;EXECUTE
					;actual result upper
	move.l	trapv_occurred,d2	;actual result lower
	fmove.l	fpsr,d3			;actual status
;
	movem.l	(a0),a1-a3		;expected result upper,expected result lower,expected status
;
	movem.l	d1-d3/a1-a3,-(sp)	;actual result upper,actual result lower,actual status,expected result upper,expected result lower,expected status
	jbsr	test_double
	lea.l	24(sp),sp
	move.l	d0,d7			;0=failed,1=successful
;
	move.l	d7,-(sp)		;0=failed,1=successful
	jbsr	statistics_update
	addq.l	#4,sp
	beq	@f			;not output
;output
	putmsg	'FTRAP'
	putstr	(uppercase_cc,za0,d5.l*4)
	putmsg	'.W #<data> @'
	move.l	d6,-(sp)		;fpsr
	jbsr	printfpsr
	addq.l	#4,sp
	putcrlf
	move.l	d7,-(sp)		;0=failed,1=successful
	movem.l	d1-d3/a1-a3,-(sp)	;actual result upper,actual result lower,actual status,expected result upper,expected result lower,expected status
	jbsr	output_double
	lea.l	28(sp),sp
@@:
;
	lea.l	(12,a0),a0		;expected result upper,expected result lower,expected status,...
;
	addq.w	#1,d5			;cc++
	cmp.w	#31,d5			;cc=0..31
	bls	55b
;
	add.l	#1<<24,d6		;mzin++
	cmp.l	#15<<24,d6		;fpsr=(mzin=0..15)<<24
	bls	66b
;
	jbsr	mnemonic_end
99:
	fmovem.x	(_fregs,a6),fregs
	fmovem.l	(_cregs,a6),cregs
	movem.l	(_regs,a6),regs
	unlk	a6
	rts

	.align	4
ftrapccw88x_execute::
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
	.dc.l	ftrapccw88x_execute_&cc
  .endm
  .irp cc,F,EQ,OGT,OGE,OLT,OLE,OGL,OR,UN,UEQ,UGT,UGE,ULT,ULE,NE,T,SF,SEQ,GT,GE,LT,LE,GL,GLE,NGLE,NGL,NLE,NLT,NGE,NGT,SNE,ST
ftrapccw88x_execute_&cc::
	moveq.l	#3,d1			;actual result upper. 3=too long
	FTRAP&cc.W	#$5381		;EXECUTE. $5381=subq.l #1,d1. -1=too short
	subq.l	#1,d1			;actual result upper. 0=ok
	subq.l	#1,d1			;actual result upper. 1=too long
	subq.l	#1,d1			;actual result upper. 2=too long
	rts
  .endm
	.cpu	68000

	.align	4
ftrapccw88x_expected_compressed::
");
  push_start();
  for(mzin=0,15,
      m=bitand(mzin>>3,1);
      z=bitand(mzin>>2,1);
      n=bitand(mzin>>0,1);
      a=[
        0,           \\000000  F
        z,           \\000001  EQ
        !(n||z||m),  \\000010  OGT
        z||!(n||m),  \\000011  OGE
        m&&!(n||z),  \\000100  OLT
        z||(m&&!n),  \\000101  OLE
        !(n||z),     \\000110  OGL
        z||!n,       \\000111  OR
        n,           \\001000  UN
        n||z,        \\001001  UEQ
        n||!(m||z),  \\001010  UGT
        n||(z||!m),  \\001011  UGE
        n||(m&&!z),  \\001100  ULT
        n||z||m,     \\001101  ULE
        n||!z,       \\001110  NE
        1            \\001111  T
        ];
      for(cc=0,15,
          push(4,0);
          push(4,a[1+cc]);
          push(4,mzin<<24));
      for(cc=16,31,
          push(4,0);
          push(4,a[1+cc-16]);
          push(4,(mzin<<24)+if(n,BS+AV,0))));
  push_end()
  }


\\----------------------------------------------------------------------------------------
\\  FTST.X FPm,FPn
\\----------------------------------------------------------------------------------------
ftst_func(x,rp,rm)={
  fpsr=bitor(fpsr,if(x==-Inf,MI+IN,
                     x==-Rei,MI+ZE,
                     x==Rei,ZE,
                     x==Inf,IN,
                     x==NaN,NA,
                     x<0,MI,
                     0))
  }
make_ftst()={
  make_fop1to0("ftst",
               "ftst",
               -1,
               MC68881+MC68882+MC68040+FPSP040+MC68060+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND),
               ftst_func)
  }


\\----------------------------------------------------------------------------------------
\\  FTWOTOX.X FPm,FPn
\\----------------------------------------------------------------------------------------
make_ftwotox()={
  make_fop1to1("ftwotox",
               "ftwotox",
               -2,
               MC68881+MC68882+FPSP040+FPSP060,
               append(DATA_SPECIAL,
                      DATA_FLOAT,
                      DATA_BASIC,
                      DATA_ROUND,
                      DATA_ZERO_PLUS),
               (x,rp,rm)->if(type(x)=="t_POL",
                             if(x==-Inf,Rei,  \\twotox(-Inf)=+0
                                x==-Rei,1,  \\twotox(-0)=1
                                x==Rei,1,  \\twotox(+0)=1
                                x==Inf,Inf,  \\twotox(+Inf)=+Inf
                                NaN),
                             fpsr=bitor(fpsr,X2);
                             if(x<=-65536,fpsr=bitor(fpsr,UF);xxx(Rei,rp,rm),  \\twotox(-big)=+0,UF
                                65536<x,fpsr=bitor(fpsr,OF);xxx(Inf,rp,rm),  \\twotox(+big)=+Inf,OF
                                xxx(2^x,rp,rm))))
  }



1;
