//========================================================================================
//  NamedPipeInputStream.java
//    en:Input from named pipe
//    ja:名前付きパイプから入力します
//  Copyright (C) 2003-2022 Makoto Kamada
//
//  This file is part of the XEiJ (X68000 Emulator in Java).
//  You can use, modify and redistribute the XEiJ if the conditions are met.
//  Read the XEiJ License for more details.
//  https://stdkmd.net/xeij/
//========================================================================================

package xeij;

import java.io.*;

public abstract class NamedPipeInputStream extends InputStream {

  public static NamedPipeInputStream createInputStream (String name) throws IOException {
    if (XEiJ.prgWindllLoaded) {
      return new NamedPipeInputStream.Win (name);
    }
    throw new IOException ("Unsupported operating system");
  }

  public abstract void cancel () throws IOException;
  public abstract void connect () throws IOException;

  protected static class Win extends NamedPipeInputStream {
    private long wp;
    public Win (String name) throws IOException {
      open (name);
    }
    @Override public native int available () throws IOException;
    @Override public native void cancel () throws IOException;
    @Override public native void close () throws IOException;
    @Override public native void connect () throws IOException;
    public native void open (String name) throws IOException;
    @Override public native int read () throws IOException;
    @Override public native int read (byte[] b) throws IOException;
    @Override public native int read (byte[] b, int off, int len) throws IOException;
    @Override public native int readNBytes (byte[] b, int off, int len) throws IOException;
  }

}
