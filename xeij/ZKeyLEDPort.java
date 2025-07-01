//========================================================================================
//  ZKeyLEDPort.java
//    en:Z keyboard LED port
//    ja:ZキーボードLEDポート
//  Copyright (C) 2003-2023 Makoto Kamada
//
//  This file is part of the XEiJ (X68000 Emulator in Java).
//  You can use, modify and redistribute the XEiJ if the conditions are met.
//  Read the XEiJ License for more details.
//  https://stdkmd.net/xeij/
//========================================================================================

package xeij;

import java.io.*;

public final class ZKeyLEDPort implements AutoCloseable {
  private boolean debugFlag;
  public void setDebugFlag (boolean debugFlag) {
    this.debugFlag = debugFlag;
  }
  private long handle;
  @Override public native void close ();
  public native void hitKey (int vk);
  public native boolean isKeyPressed (int vk);
  public native boolean isKeyToggled (int vk);
  public native void open () throws IOException;
  public native boolean send (long data);
  public ZKeyLEDPort (boolean debugFlag) throws IOException {
    this.debugFlag = debugFlag;
    handle = 0L;
    open ();
  }
}
