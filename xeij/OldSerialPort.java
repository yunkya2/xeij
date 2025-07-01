//========================================================================================
//  OldSerialPort.java
//    en:Serial port I/O
//    ja:シリアルポート入出力
//  Copyright (C) 2003-2023 Makoto Kamada
//
//  This file is part of the XEiJ (X68000 Emulator in Java).
//  You can use, modify and redistribute the XEiJ if the conditions are met.
//  Read the XEiJ License for more details.
//  https://stdkmd.net/xeij/
//========================================================================================

package xeij;

import java.io.*;

public class OldSerialPort implements AutoCloseable {

  private long wp;
  private SerialInputStream inputStream;
  private SerialOutputStream outputStream;

  @Override public native void close () throws IOException;
  public native SerialInputStream getInputStream () throws IOException;
  public native SerialOutputStream getOutputStream () throws IOException;
  public native String getPortName () throws IOException;
  public native final void open (String str) throws IOException;
  public native final void open (int vid, int pid) throws IOException;
  public native void speed (String str) throws IOException;

  public class SerialInputStream extends InputStream {
    private long wp;
    @Override public native int available () throws IOException;
    @Override public native void close () throws IOException;
    @Override public native int read () throws IOException;
  }

  public class SerialOutputStream extends OutputStream {
    private long wp;
    @Override public native void close () throws IOException;
    @Override public native void write (int b) throws IOException;
  }

  public OldSerialPort (String str) throws IOException {
    open (str);
  }
  public OldSerialPort (int vid, int pid) throws IOException {
    open (vid, pid);
  }

}
