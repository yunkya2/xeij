//========================================================================================
//  ByteQueue.java
//    en:Byte queue
//    ja:バイトキュー
//  Copyright (C) 2003-2024 Makoto Kamada
//
//  This file is part of the XEiJ (X68000 Emulator in Java).
//  You can use, modify and redistribute the XEiJ if the conditions are met.
//  Read the XEiJ License for more details.
//  https://stdkmd.net/xeij/
//========================================================================================

package xeij;

public class ByteQueue {

  static final class Block {
    volatile Block p = null;  //前のブロック。先頭のブロックの方向のリンク。null=先頭のブロック
    volatile Block n = null;  //後のブロック。末尾のブロックの方向のリンク。null=末尾のブロック

    final int s = 1 << 12;  //配列のバイト数。2の累乗
    final byte[] a = new byte[s];  //配列
    volatile long w = 0;  //書き込んだバイト数
    volatile long r = w;  //読み出したバイト数
    //  a[(int)w&(s-1)]  書き込む位置
    //  a[(int)r&(s-1)]  読み出す位置
    //  r+s-w            書き込めるバイト数
    //  w-r              読み出せるバイト数
    //  w==r+s           満
    //  r==w             空
    //  0<=w-r<=s
    //  r<=w<=r+s

    //clear ()
    //  空にする。読み飛ばしたバイト数を返す
    int clear () {
      return skip (used ());
    }  //clear

    //data = read ()
    //  1バイト読み出して0x00～0xffの範囲で返す。-1=空
    int read () {
      return r != w ? a[(int) (r++) & (s - 1)] & 0xff : -1;
    }  //read

    //read (array, offset, length)
    //  配列へ読み出す。読み出せたバイト数を返す
    int read (byte[] array, int offset, int length) {
      length = Math.min (length, (int) (w - r));  //読み出せるバイト数
      int offset0 = offset;
      for (;;) {
        int k = Math.min (length, s - ((int) r & (s - 1)));  //読み出す位置から末尾までのバイト数
        if (k == 0) {
          return offset - offset0;
        }
        System.arraycopy (a, (int) r & (s - 1),
                          array, offset,
                          k);
        r += k;
        offset += k;
        length -= k;
      }
    }  //read

    //skip (length)
    //  読み飛ばす。読み飛ばせた長さを返す
    int skip (int length) {
      length = Math.min (length, (int) (w - r));  //読み飛ばせるバイト数
      r += length;
      return length;
    }  //skip

    //length = unused ()
    //  書き込めるバイト数を返す。0=満
    int unused () {
      return (int) (r + s - w);
    }  //unused

    //length = used ()
    //  読み出せるバイト数を返す。0=空
    int used () {
      return (int) (w - r);
    }  //used

    //length = write (data)
    //  1バイト書き込む。書き込めたバイト数を返す
    int write (int data) {
      if (w == r + s) {
        return 0;
      }
      a[(int) (w++) & (s - 1)] = (byte) data;
      return 1;
    }  //write

    //write (array, offset, length)
    //  配列から書き込む。書き込めたバイト数を返す
    int write (byte[] array, int offset, int length) {
      length = Math.min (length, (int) (r + s - w));  //書き込めるバイト数
      int offset0 = offset;
      for (;;) {
        int k = Math.min (length, s - ((int) w & (s - 1)));  //書き込む位置から末尾までのバイト数
        if (k == 0) {
          return offset - offset0;
        }
        System.arraycopy (array, offset,
                          a, (int) w & (s - 1),
                          k);
        w += k;
        offset += k;
        length -= k;
      }
    }  //write

  }  //class Block

  volatile Block h = new Block ();  //先頭のブロック。次に読み出すブロック。h.p==null
  volatile Block t = h;  //末尾のブロック。次に書き込むブロック。t.n==null

  final int s = 0x7fffffff;  //上限のバイト数
  volatile long w = 0;  //書き込んだバイト数
  volatile long r = w;  //読み出したバイト数
  //  r+s-w            書き込めるバイト数
  //  w-r              読み出せるバイト数
  //  w==r+s           満
  //  r==w             空
  //  0<=w-r<=s
  //  r<=w<=r+s

  //clear ()
  //  空にする。読み飛ばしたバイト数を返す
  int clear () {
    return skip (used ());
  }  //clear

  //data = read ()
  //  1バイト読み出して0x00～0xffの範囲で返す。-1=空
  int read () {
    int data = h.read ();
    if (data < 0) {
      if (h == t) {
        return data;
      }
      Block n = h.n;
      n.p = null;
      h.n = null;
      h = n;
      data = h.read ();
    }
    r++;
    return data;
  }  //read

  //read (array, offset, length)
  //  配列へ読み出す。読み出せたバイト数を返す
  int read (byte[] array, int offset, int length) {
    //length = Math.min (length, (int) (w - r));  //読み出せるバイト数
    long r0 = r;
    int k = h.read (array, offset, length);
    r += k;
    offset += k;
    length -= k;
    while (length != 0) {
      if (h == t) {
        return (int) (r - r0);
      }
      Block n = h.n;
      n.p = null;
      h.n = null;
      h = n;
      k = h.read (array, offset, length);
      r += k;
      offset += k;
      length -= k;
    }
    return (int) (r - r0);
  }  //read

  //skip (length)
  //  読み飛ばす。読み飛ばせた長さを返す
  int skip (int length) {
    //length = Math.min (length, (int) (w - r));  //読み出せるバイト数
    long r0 = r;
    int k = h.skip (length);
    r += k;
    length -= k;
    while (length != 0) {
      if (h == t) {
        return (int) (r - r0);
      }
      Block n = h.n;
      n.p = null;
      h.n = null;
      h = n;
      k = h.skip (length);
      r += k;
      length -= k;
    }
    return (int) (r - r0);
  }  //skip

  //length = unused ()
  //  書き込めるバイト数を返す。0=満
  int unused () {
    return (int) (r + s - w);
  }  //unused

  //length = used ()
  //  読み出せるバイト数を返す。0=空
  int used () {
    return (int) (w - r);
  }  //used

  //length = write (data)
  //  1バイト書き込む。書き込めたバイト数を返す
  int write (int data) {
    if (w == r + s) {
      return 0;
    }
    if (t.write (data) == 0) {
      Block n = new Block ();
      n.p = t;
      t.n = n;
      t = n;
      t.write (data);
    }
    w++;
    return 1;
  }  //write

  //write (array, offset, length)
  //  配列から書き込む。書き込めたバイト数を返す
  int write (byte[] array, int offset, int length) {
    length = Math.min (length, (int) (r + s - w));  //書き込めるバイト数
    long w0 = w;
    int k = t.write (array, offset, length);
    w += k;
    offset += k;
    length -= k;
    while (length != 0) {
      Block n = new Block ();
      n.p = t;
      t.n = n;
      t = n;
      k = t.write (array, offset, length);
      w += k;
      offset += k;
      length -= k;
    }
    return (int) (w - w0);
  }  //write

}  //class ByteQueue
