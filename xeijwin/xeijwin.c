//========================================================================================
//  xeijwin.c
//  Copyright (C) 2003-2025 Makoto Kamada
//
//  This file is part of the XEiJ (X68000 Emulator in Java).
//  You can use, modify and redistribute the XEiJ if the conditions are met.
//  Read the XEiJ License for more details.
//  https://stdkmd.net/xeij/
//========================================================================================

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <windows.h>
#include <winreg.h>
#include <hidsdi.h>
#include <setupapi.h>

#include <jni.h>

#define VERSION 20250416
#define PACKAGE_PREFIX "xeij/"

#if 0
#define DEBUG(args...) {  \
  fprintf (stderr, "%s:%d:", __FILE__, __LINE__);  \
  fprintf (stderr, args);  \
  fflush (stderr);  \
}
#else
#define DEBUG(args...)
#endif



//========================================================================

static void throwIllegalArgumentException (JNIEnv *env, char *mes);
static void throwIndexOutOfBoundsException (JNIEnv *env, char *mes);
static void throwIOException (JNIEnv *env, char *mes);
static void throwNullPointerException (JNIEnv *env, char *mes);

//--------------------------------------------------------------------------------
//void throwIllegalArgumentException (env, mes)
//  IllegalArgumentExceptionをthrowする
//  ThrowNewは直ちにアボートしないのでreturnで明示的に中断させること
static void throwIllegalArgumentException (JNIEnv *env, char *mes) {
  (*env)->ThrowNew (env, (*env)->FindClass (env, "java/lang/IllegalArgumentException"), mes);
}  //throwIllegalArgumentException

//------------------------------------------------------------------------
//void throwIndexOutOfBoundsException (env, mes)
//  IndexOutOfBoundsExceptionをthrowする
//  ThrowNewは直ちにアボートしないのでreturnで明示的に中断させること
static void throwIndexOutOfBoundsException (JNIEnv *env, char *mes) {
  (*env)->ThrowNew (env, (*env)->FindClass (env, "java/lang/IndexOutOfBoundsException"), mes);
}  //throwIndexOutOfBoundsException

//------------------------------------------------------------------------
//void throwIOException (env, mes)
//  IOExceptionをthrowする
//  ThrowNewは直ちにアボートしないのでreturnで明示的に中断させること
static void throwIOException (JNIEnv *env, char *mes) {
  (*env)->ThrowNew (env, (*env)->FindClass (env, "java/io/IOException"), mes);
}  //throwIOException

//------------------------------------------------------------------------
//void throwNullPointerException (env, mes)
//  NullPointerExceptionをthrowする
//  ThrowNewは直ちにアボートしないのでreturnで明示的に中断させること
static void throwNullPointerException (JNIEnv *env, char *mes) {
  (*env)->ThrowNew (env, (*env)->FindClass (env, "java/lang/NullPointerException"), mes);
}  //throwNullPointerException



//========================================================================
//  WinDLL
//========================================================================

#include "xeij_WinDLL.h"

//------------------------------------------------------------------------
//v = version ()
//  バージョンを返す
JNIEXPORT jint JNICALL Java_xeij_WinDLL_version (JNIEnv *env, jclass cls) {
  return VERSION;
}  //version



//========================================================================
//  NamedPipeInputStream.Win
//========================================================================

#include "xeij_NamedPipeInputStream_Win.h"

#define BUFFER_SIZE 8192

typedef struct {
  char *path;  //名前付きパイプのパス。プレフィックス"\\\\.\\pipe\\"を含む
  HANDLE handle;  //ハンドル
} workarea_t;

//------------------------------------------------------------------------
//length = available ()
//  ブロックせずに入力できる長さを返す
JNIEXPORT jint JNICALL Java_xeij_NamedPipeInputStream_00024Win_available (JNIEnv *env, jobject obj) {
  //変数を取り出す
  jclass cls = (*env)->GetObjectClass (env, obj);
  jfieldID wpid = (*env)->GetFieldID (env, cls, "wp", "J");
  workarea_t *wp = (workarea_t *) (*env)->GetLongField (env, obj, wpid);
  //閉じていたら失敗
  if (wp == NULL || wp->handle == INVALID_HANDLE_VALUE) {
    throwIOException (env, "named pipe not open");
    return 0;
  }
  //ブロックせずに入力できる長さを求める
  jint t = 0;
  //  https://learn.microsoft.com/ja-jp/windows/win32/api/namedpipeapi/nf-namedpipeapi-peeknamedpipe
  if (!PeekNamedPipe (wp->handle, NULL, 0, NULL, (LPDWORD) &t, NULL)) {
    //  https://learn.microsoft.com/en-us/windows/win32/debug/system-error-codes
    jint error = GetLastError ();
    if (error == ERROR_BAD_PIPE ||  //230 パイプの状態が無効。誰も開いていない
        error == ERROR_BROKEN_PIPE) {  //109 パイプが終了した。誰かが開いて閉じた
      t = 0;
    } else {
      char mes[256];
      sprintf (mes, "PeekNamedPipe returned error code %ld", error);
      throwIOException (env, mes);
      return -1;
    }
  }
  //ブロックせずに入力できる長さを返す
  return t;
}  //available

//------------------------------------------------------------------------
//cancel ()
//  操作を取り消す
JNIEXPORT void JNICALL Java_xeij_NamedPipeInputStream_00024Win_cancel (JNIEnv *env, jobject obj) {
  //変数を取り出す
  jclass cls = (*env)->GetObjectClass (env, obj);
  jfieldID wpid = (*env)->GetFieldID (env, cls, "wp", "J");
  workarea_t *wp = (workarea_t *) (*env)->GetLongField (env, obj, wpid);
  //閉じていたら何もしない
  if (wp == NULL) {
    return;
  }
  HANDLE handle = wp->handle;
  if (handle == INVALID_HANDLE_VALUE) {
    return;
  }
  //操作を取り消す
  //  CancelIoExで取り消された操作はERROR_OPERATION_ABORTEDが返る
  //  https://learn.microsoft.com/ja-jp/windows/win32/fileio/cancelioex-func
  if (!CancelIoEx (handle, NULL)) {
    //jint error = GetLastError ();
    //if (error == ERROR_NOT_FOUND) {  //1168 取り消す操作がない
    //}
    //char mes[256];
    //sprintf (mes, "CancelIoEx returned error code %ld", error);
  }
}  //cancel

//------------------------------------------------------------------------
//close ()
//  名前付きパイプを閉じる
JNIEXPORT void JNICALL Java_xeij_NamedPipeInputStream_00024Win_close (JNIEnv *env, jobject obj) {
  //変数を取り出す
  jclass cls = (*env)->GetObjectClass (env, obj);
  jfieldID wpid = (*env)->GetFieldID (env, cls, "wp", "J");
  workarea_t *wp = (workarea_t *) (*env)->GetLongField (env, obj, wpid);
  //閉じていたら何もしない
  if (wp == NULL || wp->handle == INVALID_HANDLE_VALUE) {
    return;
  }
  //名前付きパイプを閉じる
  //  https://learn.microsoft.com/ja-jp/windows/win32/api/handleapi/nf-handleapi-closehandle
  if (!CloseHandle (wp->handle)) {
    //jint error = GetLastError ();
    //char mes[256];
    //sprintf (mes, "CloseHandle returned error code %ld", error);
    //wp->handle = INVALID_HANDLE_VALUE;
  }
  //wp->handle = INVALID_HANDLE_VALUE;
  free (wp->path);
  free (wp);
  wp = NULL;
  //変数を書き戻す
  (*env)->SetLongField (env, obj, wpid, (__int64) wp);
}  //close

//------------------------------------------------------------------------
//connect ()
//  接続を待つ
JNIEXPORT void JNICALL Java_xeij_NamedPipeInputStream_00024Win_connect (JNIEnv *env, jobject obj) {
  //変数を取り出す
  jclass cls = (*env)->GetObjectClass (env, obj);
  jfieldID wpid = (*env)->GetFieldID (env, cls, "wp", "J");
  workarea_t *wp = (workarea_t *) (*env)->GetLongField (env, obj, wpid);
  //閉じていたら失敗
  if (wp == NULL || wp->handle == INVALID_HANDLE_VALUE) {
    throwIOException (env, "named pipe not open");
    return;
  }
  //接続を待つ
  //  https://learn.microsoft.com/ja-jp/windows/win32/api/namedpipeapi/nf-namedpipeapi-connectnamedpipe
  if (!ConnectNamedPipe (wp->handle, NULL)) {
    jint error = GetLastError ();
    if (error == ERROR_PIPE_CONNECTED ||  //535 既に接続している
        error == ERROR_NO_DATA ||  //232 既に切断された
        error == ERROR_OPERATION_ABORTED) {  //995 スレッドが終了したか操作が取り消された
    } else {
      char mes[256];
      sprintf (mes, "ConnectNamedPipe returned error code %ld", error);
      throwIOException (env, mes);
      return;
    }
  }
}  //connect

//------------------------------------------------------------------------
//open (name)
//  名前付きパイプを開く
//  name  名前付きパイプの名前。プレフィックス"\\\\.\\pipe\\"を含まない
JNIEXPORT void JNICALL Java_xeij_NamedPipeInputStream_00024Win_open (JNIEnv *env, jobject obj, jstring name) {
  //ワークエリアを確保する
  workarea_t *wp = malloc (sizeof (workarea_t));
  //名前付きパイプのパスを作る
  const char *utf = (*env)->GetStringUTFChars (env, name, NULL);
  jint strlen_utf = strlen (utf);
  wp->path = malloc (9 + strlen_utf + 1);
  strcpy_s (wp->path, 9 + strlen_utf + 1, "\\\\.\\pipe\\");
  strcpy_s (wp->path + 9, strlen_utf + 1, utf);
  (*env)->ReleaseStringUTFChars (env, name, utf);
  //名前付きパイプを開く
  //  https://learn.microsoft.com/ja-jp/windows/win32/api/winbase/nf-winbase-createnamedpipea
  wp->handle = CreateNamedPipeA (wp->path,  //LPCSTR lpName
                                 PIPE_ACCESS_INBOUND,  //DWORD dwOpenMode
                                 PIPE_TYPE_BYTE | PIPE_WAIT,  //DWORD dwPipeMode
                                 PIPE_UNLIMITED_INSTANCES,  //DWORD nMaxInstances
                                 0,  //DWORD nOutBufferSize
                                 BUFFER_SIZE,  //DWORD nInBufferSize
                                 0,  //DWORD nDefaultTimeOut
                                 NULL);  //LPSECURITY_ATTRIBUTES lpSecurityAttributes
  //開けなかったら失敗
  if (wp->handle == INVALID_HANDLE_VALUE) {
    throwIOException (env, "CreateNamedPipeA failed");
    return;
  }
  //変数を書き戻す
  jclass cls = (*env)->GetObjectClass (env, obj);
  jfieldID wpid = (*env)->GetFieldID (env, cls, "wp", "J");
  (*env)->SetLongField (env, obj, wpid, (__int64) wp);
}  //open

//------------------------------------------------------------------------
//data = read ()
//  1バイト入力して入力したデータを返す
//  1バイト入力するまでブロックする
//  名前付きパイプにはEOFがないので-1が返ることはない
//  data  入力したデータ。0-255
JNIEXPORT jint JNICALL Java_xeij_NamedPipeInputStream_00024Win_read__ (JNIEnv *env, jobject obj) {
  //変数を取り出す
  jclass cls = (*env)->GetObjectClass (env, obj);
  jfieldID wpid = (*env)->GetFieldID (env, cls, "wp", "J");
  workarea_t *wp = (workarea_t *) (*env)->GetLongField (env, obj, wpid);
  //閉じていたら失敗
  if (wp == NULL || wp->handle == INVALID_HANDLE_VALUE) {
    throwIOException (env, "named pipe not open");
    return -1;
  }
  //1バイト入力する
  char buf[1];
  buf[0] = 0;
  jint off = 0;
  jint len = 1;
  jint k = 0;
  while (k < len) {
    jint t = 0;
    //  https://learn.microsoft.com/ja-jp/windows/win32/api/fileapi/nf-fileapi-readfile
    if (!ReadFile (wp->handle, &buf[off + k], len - k, (LPDWORD) &t, NULL)) {
      jint error = GetLastError ();
      if (error == ERROR_BROKEN_PIPE ||  //109 パイプが終了した。誰かが開いて閉じた
          error == ERROR_PIPE_LISTENING || //536 誰も開いていない
          error == ERROR_OPERATION_ABORTED) {  //995 スレッドが終了したか操作が取り消された
        break;
      } else {
        char mes[256];
        sprintf (mes, "ReadFile returned error code %ld", error);
        throwIOException (env, mes);
        return 0;
      }
    }
    k += t;
  }
  //入力したデータを返す
  return buf[0] & 0xff;
}  //read

//------------------------------------------------------------------------
//len = read (b)
//  配列に入力して入力した長さを返す
//  配列の長さが0のときは何もせず0を返す。さもなくば少なくとも1バイト入力するまでブロックする
//  len  入力した長さ
//  b    配列
JNIEXPORT jint JNICALL Java_xeij_NamedPipeInputStream_00024Win_read___3B (JNIEnv *env, jobject obj, jbyteArray b) {
  //read(b,0,b.length)を実行する
  return Java_xeij_NamedPipeInputStream_00024Win_read___3BII (env, obj, b, 0, (*env)->GetArrayLength (env, b));
}  //read

//------------------------------------------------------------------------
//len = read (b, off, len)
//  配列に入力して入力した長さを返す
//  入力する長さが0のときは何もせず0を返す。さもなくば少なくとも1バイト入力するまでブロックする
//  len  入力した長さ
//  b    配列
//  off  開始位置
//  len  入力する長さ
JNIEXPORT jint JNICALL Java_xeij_NamedPipeInputStream_00024Win_read___3BII (JNIEnv *env, jobject obj, jbyteArray b, jint off, jint len) {
  //変数を取り出す
  jclass cls = (*env)->GetObjectClass (env, obj);
  jfieldID wpid = (*env)->GetFieldID (env, cls, "wp", "J");
  workarea_t *wp = (workarea_t *) (*env)->GetLongField (env, obj, wpid);
  //閉じていたら失敗
  if (wp == NULL || wp->handle == INVALID_HANDLE_VALUE) {
    throwIOException (env, "named pipe not open");
    return -1;
  }
  //開始位置と入力する長さを確認する
  jint cap = (*env)->GetArrayLength (env, b);  //配列の長さ
  if (off < 0 || len < 0 || cap < off + len) {  //範囲外
    char mes[256];
    sprintf (mes, "b.length=%ld, off=%ld, len=%ld", cap, off, len);
    throwIndexOutOfBoundsException (env, mes);
    return 0;
  }
  //入力する長さが0のときは何もせず0を返す
  if (len == 0) {
    return 0;
  }
  //lenバイト入力する
  //  GetPrimitiveArrayCriticalに成功したらReleasePrimitiveArrayCriticalまで他のJNI関数を呼び出してはならない。入れ子にすることはできる
  char *buf = (char *) (*env)->GetPrimitiveArrayCritical (env, b, 0);
  jint k = 0;
  while (k < 1) {
    jint t = 0;
    //  https://learn.microsoft.com/ja-jp/windows/win32/api/fileapi/nf-fileapi-readfile
    if (!ReadFile (wp->handle, &buf[off + k], len - k, (LPDWORD) &t, NULL)) {
      jint error = GetLastError ();
      if (error == ERROR_BROKEN_PIPE ||  //109 パイプが終了した。誰かが開いて閉じた
          error == ERROR_PIPE_LISTENING || //536 誰も開いていない
          error == ERROR_OPERATION_ABORTED) {  //995 スレッドが終了したか操作が取り消された
        break;
      } else {
        char mes[256];
        sprintf (mes, "ReadFile returned error code %ld", error);
        (*env)->ReleasePrimitiveArrayCritical (env, b, buf, 0);
        throwIOException (env, mes);
        return 0;
      }
    }
    k += t;
  }
  (*env)->ReleasePrimitiveArrayCritical (env, b, buf, 0);
  //入力した長さを返す
  return k;
}  //read

//------------------------------------------------------------------------
//len = readNBytes (b, off, len)
//  配列に入力して入力した長さを返す
//  入力する長さが0のときは何もせず0を返す。さもなくばすべて入力するまでブロックする
//  len  入力した長さ
//  b    配列
//  off  開始位置
//  len  入力する長さ
JNIEXPORT jint JNICALL Java_xeij_NamedPipeInputStream_00024Win_readNBytes (JNIEnv *env, jobject obj, jbyteArray b, jint off, jint len) {
  //変数を取り出す
  jclass cls = (*env)->GetObjectClass (env, obj);
  jfieldID wpid = (*env)->GetFieldID (env, cls, "wp", "J");
  workarea_t *wp = (workarea_t *) (*env)->GetLongField (env, obj, wpid);
  //閉じていたら失敗
  if (wp == NULL || wp->handle == INVALID_HANDLE_VALUE) {
    throwIOException (env, "named pipe not open");
    return 0;
  }
  //開始位置と入力する長さを確認する
  jint cap = (*env)->GetArrayLength (env, b);  //配列の長さ
  if (off < 0 || len < 0 || cap < off + len) {  //範囲外
    char mes[256];
    sprintf (mes, "b.length=%ld, off=%ld, len=%ld", cap, off, len);
    throwIndexOutOfBoundsException (env, mes);
    return 0;
  }
  //入力する長さが0のときは何もせず0を返す
  if (len == 0) {
    return 0;
  }
  //lenバイト入力する
  //  GetPrimitiveArrayCriticalに成功したらReleasePrimitiveArrayCriticalまで他のJNI関数を呼び出してはならない。入れ子にすることはできる
  char *buf = (char *) (*env)->GetPrimitiveArrayCritical (env, b, 0);
  jint k = 0;
  while (k < len) {
    jint t = 0;
    //  https://learn.microsoft.com/ja-jp/windows/win32/api/fileapi/nf-fileapi-readfile
    if (!ReadFile (wp->handle, &buf[off + k], len - k, (LPDWORD) &t, NULL)) {
      jint error = GetLastError ();
      if (error == ERROR_BROKEN_PIPE ||  //109 パイプが終了した。誰かが開いて閉じた
          error == ERROR_PIPE_LISTENING || //536 誰も開いていない
          error == ERROR_OPERATION_ABORTED) {  //995 スレッドが終了したか操作が取り消された
        break;
      } else {
        char mes[256];
        sprintf (mes, "ReadFile returned error code %ld", error);
        (*env)->ReleasePrimitiveArrayCritical (env, b, buf, 0);
        throwIOException (env, mes);
        return 0;
      }
    }
    k += t;
  }
  (*env)->ReleasePrimitiveArrayCritical (env, b, buf, 0);
  //入力した長さを返す
  return k;
}  //readNBytes



//========================================================================

#define IN_QUEUE 8192
#define OUT_QUEUE 8192

#define DEFAULT_SPEED "19200 b8 pn s1 rts"

typedef struct {
  char portName[1024];
  HANDLE handle;
  COMMTIMEOUTS timeouts;
  //
  OVERLAPPED inOverlapped;
  unsigned char inBuffer[1];
  size_t inSize;
  //
  OVERLAPPED outOverlapped;
  unsigned char outBuffer[1];
  size_t outSize;
} workarea2_t;

static size_t available232c (workarea2_t *wp);
static _Bool close232c (workarea2_t *wp);
static _Bool open232c (workarea2_t *wp);
static _Bool speed232c (workarea2_t *wp, char *utf);
static _Bool stat232c (workarea2_t *wp, COMSTAT *stat_ptr);

//----------------------------------------------------------------
//len = available232c (wp)
//  ブロックせずに受信できる長さを返す
//  len  ブロックせずに受信できる長さ
//  wp   ワークエリア
static size_t available232c (workarea2_t *wp) {
  //閉じていたら失敗
  if (wp == NULL || wp->handle == INVALID_HANDLE_VALUE) {
    DEBUG ("available232c: handle is not open\n");
    return 0;
  }
  //ステータスを取得する
  COMSTAT stat;
  if (!stat232c (wp, &stat)) {
    return 0;
  }
  return stat.cbInQue;  //ブロックせずに受信できる長さ=受信したがReadFileされていないバイト数
}  //available232c

//----------------------------------------------------------------
//success = close232c (wp)
//  シリアルポートを閉じる
//  success  0=失敗,1=成功
//  wp       ワークエリア
static _Bool close232c (workarea2_t *wp) {
  return 1;
}  //close232c

//----------------------------------------------------------------
//success = open232c (wp)
//  シリアルポートを開く
//  wp->portNameにCOM?を設定してから呼び出す
//  success  0=失敗,1=成功
//  wp       ワークエリア
//  utf      UTF-8の文字列
static _Bool open232c (workarea2_t *wp) {
  //COM?を開く
  wp->handle = INVALID_HANDLE_VALUE;
  char device[256];
  if (!QueryDosDevice (wp->portName, device, sizeof (device))) {  //COM?が見つからない
    DEBUG ("open232c: QueryDosDevice %s failed (%ld)\n", wp->portName, GetLastError ());
    return 0;
  } else {
    DEBUG ("open232c: QueryDosDevice %s success\n", wp->portName);
  }
  wp->handle = CreateFile (wp->portName,  //LPCTSTR lpFileName
                           GENERIC_READ | GENERIC_WRITE,  //DWORD dwDesiredAccess
                           0,  //DWORD dwShareMode
                           NULL,  //LPSECURITY_ATTRIBUTES lpSecurityAttributes
                           OPEN_EXISTING,  //DWORD dwCreationDisposition。COM?はOPEN_EXISTINGであること
                           FILE_FLAG_OVERLAPPED,  //DWORD dwFlagsAndAttributes
                           NULL);  //HANDLE hTemplateFile。COM?はNULLであること
  if (wp->handle == INVALID_HANDLE_VALUE) {  //COM?を開けなかった
    DEBUG ("open232c: CreateFile %s failed (%ld)\n", wp->portName, GetLastError ());
    return 0;
  } else {
    DEBUG ("open232c: CreateFile %s success\n", wp->portName);
  }
  //通信モードを設定する
  if (!speed232c (wp, DEFAULT_SPEED)) {
    CloseHandle (wp->handle);
    wp->handle = INVALID_HANDLE_VALUE;
    return 0;
  }
  //バッファサイズを設定する
  if (!SetupComm (wp->handle, IN_QUEUE, OUT_QUEUE)) {
    DEBUG ("open232c: SetupComm failed (%ld)\n", GetLastError ());
    CloseHandle (wp->handle);
    wp->handle = INVALID_HANDLE_VALUE;
    return 0;
  } else {
    DEBUG ("open232c: SetupComm success\n");
  }
  //バッファを初期化する
  if (!PurgeComm (wp->handle, PURGE_RXABORT | PURGE_RXCLEAR | PURGE_TXABORT | PURGE_TXCLEAR)) {
    DEBUG ("open232c: PurgeComm failed (%ld)\n", GetLastError ());
    CloseHandle (wp->handle);
    wp->handle = INVALID_HANDLE_VALUE;
    return 0;
  } else {
    DEBUG ("open232c: PurgeComm success\n");
  }
  //タイムアウトを設定する
  if (!GetCommTimeouts (wp->handle, &wp->timeouts)) {
    DEBUG ("open232c: GetCommTimeouts failed (%ld)\n", GetLastError ());
    CloseHandle (wp->handle);
    wp->handle = INVALID_HANDLE_VALUE;
    return 0;
  } else {
    DEBUG ("open232c: GetCommTimeouts success\n");
  }
  wp->timeouts.ReadIntervalTimeout = 0;  //受信時MAXDWORD,0,0でデータの有無に関わらずすぐに復帰する。0,0,0でタイムアウトなし
  wp->timeouts.ReadTotalTimeoutMultiplier = 0;  //1バイト毎に何ms待つか
  wp->timeouts.ReadTotalTimeoutConstant = 0;  //ReadFile毎に何ms待つか
  wp->timeouts.WriteTotalTimeoutMultiplier = 0;  //1バイト毎に何ms待つか。送信時0,0でタイムアウトなし
  wp->timeouts.WriteTotalTimeoutConstant = 0;  //WriteFile毎に何ms待つか
  if (!SetCommTimeouts (wp->handle, &wp->timeouts)) {
    DEBUG ("open232c: SetCommTimeouts failed (%ld)\n", GetLastError ());
    CloseHandle (wp->handle);
    wp->handle = INVALID_HANDLE_VALUE;
    return 0;
  } else {
    DEBUG ("open232c: SetCommTimeouts success\n");
  }
  //イベントマスクを設定する
  if (!SetCommMask (wp->handle, EV_RXCHAR | EV_TXEMPTY)) {
    DEBUG ("open232c: SetCommMask failed (%ld)\n", GetLastError ());
    CloseHandle (wp->handle);
    wp->handle = INVALID_HANDLE_VALUE;
    return 0;
  } else {
    DEBUG ("open232c: SetCommMask success\n");
  }
  DEBUG ("open232c: %s opened\n", wp->portName);
  //OVERLAPPED構造体を作成する
  memset (&wp->inOverlapped, 0, sizeof (OVERLAPPED));
  memset (&wp->outOverlapped, 0, sizeof (OVERLAPPED));
  wp->inOverlapped.hEvent = CreateEvent (NULL,  //lpEventAttributes
                                         TRUE,  //bManualReset
                                         FALSE,  //bInitialState
                                         NULL);  //lpName
  wp->outOverlapped.hEvent = CreateEvent (NULL,  //lpEventAttributes
                                          TRUE,  //bManualReset
                                          FALSE,  //bInitialState
                                          NULL);  //lpName
  return 1;
}  //open232c

//----------------------------------------------------------------
//success = speed232c (wp, utf)
//  通信モードを設定する
//  X68000のSPEED.Xのコマンドラインと同じ書き方で文字列で指定する
//  75bpsと150bpsは指定できない
//  success  0=失敗,1=成功
//  wp       ワークエリア
//  utf      UTF-8の文字列
static _Bool speed232c (workarea2_t *wp, char *utf) {
  //閉じていたら失敗
  if (wp == NULL || wp->handle == INVALID_HANDLE_VALUE) {
    DEBUG ("speed232c: handle is not open\n");
    return 0;
  }
  //通信モードを取り出す
  DCB dcb;
  if (!GetCommState (wp->handle, &dcb)) {
    DEBUG ("speed232c: GetCommState failed (%ld)\n", GetLastError ());
    return 0;
  }
  DEBUG ("speed232c: GetCommState success\n");
  //通信モードを変更する
  dcb.fBinary = TRUE;  //バイナリモード。常にTRUE
  char w[256];  //キーワードをコピーする場所
  char *p = utf;
  while (*p != '\0') {
    if (isspace ((int) *p)) {  //空白を
      p++;  //読み飛ばす
      continue;
    }
    int i = 0;
    while (!(*p == ' ' || *p == '\0')) {  //空白または末尾の手前まで
      w[i++] = tolower (*p++);  //小文字化してコピーする
      if (i == sizeof (w) / sizeof (w[0])) {  //キーワードが長過ぎて'\0'を書き込む場所がなくなった
        return 0;
      }
    }
    w[i] = '\0';
    if ('1' <= w[0] && w[0] <= '9') {
      dcb.BaudRate = atol (w);
    } else if (strcmp (w, "b8") == 0) {
      dcb.ByteSize = 8;  //8ビット
    } else if (strcmp (w, "b7") == 0) {
      dcb.ByteSize = 7;  //7ビット
    } else if (strcmp (w, "b6") == 0) {
      dcb.ByteSize = 6;  //6ビット
    } else if (strcmp (w, "b5") == 0) {
      dcb.ByteSize = 5;  //5ビット
    } else if (strcmp (w, "pn") == 0) {
      dcb.Parity = NOPARITY;  //パリティなし
      dcb.fParity = FALSE;  //パリティを使用しない(あっても無視する)
    } else if (strcmp (w, "pe") == 0) {
      dcb.Parity = EVENPARITY;  //パリティ偶数
      dcb.fParity = TRUE;  //パリティを使用する
    } else if (strcmp (w, "po") == 0) {
      dcb.Parity = ODDPARITY;  //パリティ奇数
      dcb.fParity = TRUE;  //パリティを使用する
    } else if (strcmp (w, "s1") == 0) {
      dcb.StopBits = ONESTOPBIT;  //ストップ1
    } else if (strcmp (w, "s1.5") == 0) {
      dcb.StopBits = ONE5STOPBITS;  //ストップ1.5
    } else if (strcmp (w, "s2") == 0) {
      dcb.StopBits = TWOSTOPBITS;  //ストップ2
    } else if (strcmp (w, "xon") == 0) {
      dcb.fInX = TRUE;  //受信側XON/XOFF有効。受信バッファの空き容量がXoffLim未満になったらXoffCharを送信、使用量がXonLim以下になったらXonCharを送信
      dcb.fOutX = TRUE;  //送信側XON/XOFF有効。XoffCharを受信したらXonCharを受信するまで送信しない
      dcb.fRtsControl = RTS_CONTROL_DISABLE;  //受信側RTS無効。常にRTS=1
      dcb.fOutxCtsFlow = FALSE;  //送信側CTS無効
      dcb.fTXContinueOnXoff = TRUE;  //受信側の都合でXoffCharを送信しても送信側はデータの送信を継続する
      dcb.XonChar = 0x11;  //XONキャラクタ
      dcb.XoffChar = 0x13;  //XOFFキャラクタ
      dcb.XoffLim = IN_QUEUE / 8;  //受信バッファの空き容量がXoffLim未満になったらXoffCharを送信
      dcb.XonLim = IN_QUEUE / 2;  //使用量がXonLim以下になったらXonCharを送信
    } else if (strcmp (w, "rts") == 0) {
      dcb.fInX = FALSE;  //受信側XON/XOFF無効
      dcb.fOutX = FALSE;  //送信側XON/XOFF無効
      dcb.fRtsControl = RTS_CONTROL_HANDSHAKE;  //受信側RTS有効。受信バッファが1/2まで空いたらRTS=1、3/4まで埋まったらRTS=0
      dcb.fOutxCtsFlow = TRUE;  //送信側CTS有効。CTS=0のときCTS=1になるまで送信しない
    } else if (strcmp (w, "none") == 0) {
      dcb.fInX = FALSE;  //受信側XON/XOFF無効
      dcb.fOutX = FALSE;  //送信側XON/XOFF無効
      dcb.fRtsControl = RTS_CONTROL_DISABLE;  //受信側RTS無効。常にRTS=1
      dcb.fOutxCtsFlow = FALSE;  //送信側CTS無効
    } else {
      return 0;
    }
  }
  //通信モードを書き戻す
  if (!SetCommState (wp->handle, &dcb)) {
    DEBUG ("speed232c: SetCommState failed (%ld)\n", GetLastError ());
    return 0;
  }
  DEBUG ("speed232c: SetCommState success\n");
  return 1;
}  //speed232c

//------------------------------------------------------------------------
//success = stat232c (wp, stat_ptr)
//  ステータスを取得する
//  success   0=失敗,1=成功
//  wp        ワークエリア
//  stat_ptr  ステータス
static _Bool stat232c (workarea2_t *wp, COMSTAT *stat_ptr) {
  //閉じていたら失敗
  if (wp == NULL || wp->handle == INVALID_HANDLE_VALUE) {
    DEBUG ("stat232c: handle is not open\n");
    return 0;
  }
  DWORD errors;
  if (!ClearCommError (wp->handle, &errors, stat_ptr)) {
    DEBUG ("stat232c: ClearCommError failed (%ld)\n", GetLastError ());
    return 0;
  }
  DEBUG ("stat232c: ClearCommError success\n");
  if ((errors & CE_BREAK) != 0) {  //ブレークコンディション。中断
    DEBUG ("stat232c: break condition\n");
    return 0;
  }
  if ((errors & CE_FRAME) != 0) {  //フレーミングエラー。ストップビットがない。データ長またはパリティの有無が合っていない
    DEBUG ("stat232c: framing error\n");
    return 0;
  }
  if ((errors & CE_OVERRUN) != 0) {  //キャラクタバッファオーバーラン。次の文字が失われた
    DEBUG ("stat232c: character-buffer overrun\n");
    return 0;
  }
  //CE_RXOVER  //受信バッファオーバーフロー。受信バッファが一杯になった、または、EOFの後に文字を受信した
  if ((errors & CE_RXPARITY) != 0) {  //パリティエラー
    DEBUG ("stat232c: parity error\n");
    return 0;
  }
  return 1;
}  //stat232c



//========================================================================
//  OldSerialPort
//========================================================================

#include "xeij_OldSerialPort.h"

//------------------------------------------------------------------------
//OldSerialPort
//  close ()
//  シリアルポートを閉じる
JNIEXPORT void JNICALL Java_xeij_OldSerialPort_close (JNIEnv *env, jobject obj) {
  //変数を取り出す
  jclass cls = (*env)->GetObjectClass (env, obj);
  jfieldID wpid = (*env)->GetFieldID (env, cls, "wp", "J");
  workarea2_t *wp = (workarea2_t *) (*env)->GetLongField (env, obj, wpid);
  //閉じていたら何もしない
  if (wp == NULL || wp->handle == INVALID_HANDLE_VALUE) {
    return;
  }
  //変数を消す
  jobject isobj = (*env)->GetObjectField (env, obj, (*env)->GetFieldID (env, cls, "inputStream", "L" PACKAGE_PREFIX "OldSerialPort$SerialInputStream;"));
  jobject osobj = (*env)->GetObjectField (env, obj, (*env)->GetFieldID (env, cls, "outputStream", "L" PACKAGE_PREFIX "OldSerialPort$SerialOutputStream;"));
  jclass iscls = (*env)->GetObjectClass (env, isobj);
  jclass oscls = (*env)->GetObjectClass (env, osobj);
  (*env)->SetLongField (env, obj, wpid, (__int64) 0);
  (*env)->SetLongField (env, isobj, (*env)->GetFieldID (env, iscls, "wp", "J"), (__int64) 0);
  (*env)->SetLongField (env, osobj, (*env)->GetFieldID (env, oscls, "wp", "J"), (__int64) 0);
  //readをキャンセルする
  if (!CancelIoEx (wp->handle, &wp->inOverlapped)) {
    DEBUG ("close: CancelIoEx failed (%ld)\n", GetLastError ());
  } else {
    DEBUG ("close: CancelIoEx success\n");
    if (!GetOverlappedResult (wp->handle, &wp->inOverlapped, (LPDWORD) &wp->inSize, TRUE)) {
      DEBUG ("close: GetOverlappedResult failed (%ld)\n", GetLastError ());
    } else {
      DEBUG ("close: GetOverlappedResult success, %zd bytes\n", wp->inSize);
    }
  }
  //writeをキャンセルする
  if (!CancelIoEx (wp->handle, &wp->outOverlapped)) {
    DEBUG ("close: CancelIoEx failed (%ld)\n", GetLastError ());
  } else {
    DEBUG ("close: CancelIoEx success\n");
    if (!GetOverlappedResult (wp->handle, &wp->outOverlapped, (LPDWORD) &wp->outSize, TRUE)) {
      DEBUG ("close: GetOverlappedResult failed (%ld)\n", GetLastError ());
    } else {
      DEBUG ("close: GetOverlappedResult success, %zd bytes\n", wp->outSize);
    }
  }
  //動作を中止してバッファを初期化する
  if (!PurgeComm (wp->handle, PURGE_RXABORT | PURGE_RXCLEAR | PURGE_TXABORT | PURGE_TXCLEAR)) {
    DEBUG ("close: PurgeComm failed (%ld)\n", GetLastError ());
  } else {
    DEBUG ("close: PurgeComm success\n");
  }
  //シリアルポートを閉じる
  if (!CloseHandle (wp->handle)) {
    DEBUG ("close: CloseHandle failed (%ld)\n", GetLastError ());
  } else {
    DEBUG ("close: CloseHandle success\n");
  }
  //wp->handle = INVALID_HANDLE_VALUE;
  DEBUG ("close: %s closed\n", wp->portName);
  //OVERLAPPED構造体を破棄する
  if (!CloseHandle (wp->inOverlapped.hEvent)) {
    DEBUG ("close: CloseHandle failed (%ld)\n", GetLastError ());
  } else {
    DEBUG ("close: CloseHandle success\n");
  }
  //wp->inOverlapped.hEvent = INVALID_HANDLE_VALUE;
  if (!CloseHandle (wp->outOverlapped.hEvent)) {
    DEBUG ("close: CloseHandle failed (%ld)\n", GetLastError ());
  } else {
    DEBUG ("close: CloseHandle success\n");
  }
  //wp->outOverlapped.hEvent = INVALID_HANDLE_VALUE;
  //ワークエリアを開放する
  //wp->handle = INVALID_HANDLE_VALUE;
  free (wp);
  wp = NULL;
}  //close

//------------------------------------------------------------------------
//OldSerialPort
//  is = getInputStream ()
//  受信ストリームを返す
//  is  受信ストリーム
JNIEXPORT jobject JNICALL Java_xeij_OldSerialPort_getInputStream (JNIEnv *env, jobject obj) {
  //変数を取り出す
  jclass cls = (*env)->GetObjectClass (env, obj);
  jfieldID wpid = (*env)->GetFieldID (env, cls, "wp", "J");
  workarea2_t *wp = (workarea2_t *) (*env)->GetLongField (env, obj, wpid);
  //閉じていたら失敗
  if (wp == NULL || wp->handle == INVALID_HANDLE_VALUE) {
    throwIOException (env, "serial port is not open");
    return NULL;
  }
  //受信ストリームを返す
  return (*env)->GetObjectField (env, obj, (*env)->GetFieldID (env, cls, "inputStream", "L" PACKAGE_PREFIX "OldSerialPort$SerialInputStream;"));
}  //getInputStream

//------------------------------------------------------------------------
//OldSerialPort
//  os = getOutputStream ()
//  送信ストリームを返す
//  os  送信ストリーム
JNIEXPORT jobject JNICALL Java_xeij_OldSerialPort_getOutputStream (JNIEnv *env, jobject obj) {
  //変数を取り出す
  jclass cls = (*env)->GetObjectClass (env, obj);
  jfieldID wpid = (*env)->GetFieldID (env, cls, "wp", "J");
  workarea2_t *wp = (workarea2_t *) (*env)->GetLongField (env, obj, wpid);
  //閉じていたら失敗
  if (wp == NULL || wp->handle == INVALID_HANDLE_VALUE) {
    throwIOException (env, "serial port is not open");
    return NULL;
  }
  //送信ストリームを返す
  return (*env)->GetObjectField (env, obj, (*env)->GetFieldID (env, cls, "outputStream", "L" PACKAGE_PREFIX "OldSerialPort$SerialOutputStream;"));
}  //getOutputStream

//------------------------------------------------------------------------
//OldSerialPort
//  name = getPortName ()
//  ポート名を返す
//  name  ポート名
JNIEXPORT jstring JNICALL Java_xeij_OldSerialPort_getPortName (JNIEnv *env, jobject obj) {
  //変数を取り出す
  jclass cls = (*env)->GetObjectClass (env, obj);
  jfieldID wpid = (*env)->GetFieldID (env, cls, "wp", "J");
  workarea2_t *wp = (workarea2_t *) (*env)->GetLongField (env, obj, wpid);
  //閉じていたら失敗
  if (wp == NULL || wp->handle == INVALID_HANDLE_VALUE) {
    throwIOException (env, "serial port is not open");
    return NULL;
  }
  //ポート名を返す
  return (*env)->NewStringUTF (env, wp->portName);
}  //getPortName

//------------------------------------------------------------------------
//openCommon (env, obj, wp)
//  openの共通の設定
static void openCommon (JNIEnv *env, jobject obj, workarea2_t *wp) {
  //SerialInputStreamを作る
  jclass iscls = (*env)->FindClass (env, PACKAGE_PREFIX "OldSerialPort$SerialInputStream");  //SerialInputStreamクラス
  jobject isobj = (*env)->NewObject (env, iscls, (*env)->GetMethodID (env, iscls, "<init>", "(L" PACKAGE_PREFIX "OldSerialPort;)V"), obj);  //SerialInputStreamのインスタンス
  (*env)->SetLongField (env, isobj, (*env)->GetFieldID (env, iscls, "wp", "J"), (__int64) wp);  //SerialInputStream.wp
  //SerialOutputStreamを作る
  jclass oscls = (*env)->FindClass (env, PACKAGE_PREFIX "OldSerialPort$SerialOutputStream");  //SerialOutputStreamクラス
  jobject osobj = (*env)->NewObject (env, oscls, (*env)->GetMethodID (env, oscls, "<init>", "(L" PACKAGE_PREFIX "OldSerialPort;)V"), obj);  //SerialOutputStreamのインスタンス
  (*env)->SetLongField (env, osobj, (*env)->GetFieldID (env, oscls, "wp", "J"), (__int64) wp);  //SerialOutputStream.wp
  //OldSerialPortを作る
  jclass cls = (*env)->GetObjectClass (env, obj);  //OldSerialPortクラス
  (*env)->SetLongField (env, obj, (*env)->GetFieldID (env, cls, "wp", "J"), (__int64) wp);  //long。OldSerialPort.wp
  (*env)->SetObjectField (env, obj, (*env)->GetFieldID (env, cls, "inputStream", "L" PACKAGE_PREFIX "OldSerialPort$SerialInputStream;"), isobj);  //OldSerialPort.inputStream
  (*env)->SetObjectField (env, obj, (*env)->GetFieldID (env, cls, "outputStream", "L" PACKAGE_PREFIX "OldSerialPort$SerialOutputStream;"), osobj);  //OldSerialPort.outputStream
}

//------------------------------------------------------------------------
//OldSerialPort
//  open (str)
//  シリアルポートを開く
//  str  ポート名
JNIEXPORT void JNICALL Java_xeij_OldSerialPort_open__Ljava_lang_String_2 (JNIEnv *env, jobject obj, jstring str) {
  //ワークエリアを確保する
  workarea2_t *wp = malloc (sizeof (workarea2_t));
  memset (wp, 0, sizeof (workarea2_t));
  //ポート名をコピーする
  const char *utf = (*env)->GetStringUTFChars (env, str, NULL);
  if (strlen (utf) + 1 < sizeof (wp->portName)) {
    strcpy (wp->portName, utf);
  }
  (*env)->ReleaseStringUTFChars (env, str, utf);
  //シリアルポートを開く
  if (!open232c (wp)) {
    free (wp);
    throwIOException (env, "open232c failed");
    return;
  }
  //openの共通の設定
  openCommon (env, obj, wp);
}  //open

//------------------------------------------------------------------------
//OldSerialPort
//  open (vid, pid)
//  シリアルポートを開く
//  vid  ベンダーID
//  pid  プロダクトID
JNIEXPORT void JNICALL Java_xeij_OldSerialPort_open__II (JNIEnv *env, jobject obj, jint vid, jint pid) {
  //ワークエリアを確保する
  workarea2_t *wp = malloc (sizeof (workarea2_t));
  memset (wp, 0, sizeof (workarea2_t));
  //ハードウェアIDを作る
  char hardwareIdName[256];
  sprintf (hardwareIdName, "VID_%04lX&PID_%04lX", vid, pid);
  DEBUG ("open: hardwareIdName is %s\n", hardwareIdName);
  char hardwareIdPath[512];
  sprintf (hardwareIdPath, "SYSTEM\\CurrentControlSet\\Enum\\USB\\%s", hardwareIdName);
  DEBUG ("open: hardwareIdPath is %s\n", hardwareIdPath);
  //ハードウェアレジストリキーを開く
  HKEY hardwareIdKey;
  if (RegOpenKeyEx (HKEY_LOCAL_MACHINE,  //hKey
                    hardwareIdPath,  //lpSubKey
                    0,  //ulOptions
                    KEY_ENUMERATE_SUB_KEYS,  //samDesired
                    &hardwareIdKey) != ERROR_SUCCESS) {   //phkResult
    DEBUG ("open: RegOpenKeyEx %s failed (%ld)\n", hardwareIdPath, GetLastError ());
    goto exit;
  } else {
    DEBUG ("open: RegOpenKeyEx %s success\n", hardwareIdPath);
  }
  //インスタンスIDを探す
  char instanceIdName[256];
  DWORD instanceIdNameSize;
  char instanceIdClass[256];
  DWORD instanceIdClassSize;
  for (DWORD instanceIdIndex = 0; ; instanceIdIndex++) {
    instanceIdNameSize = sizeof (instanceIdName);
    instanceIdClassSize = sizeof (instanceIdClass);
    if (RegEnumKeyEx (hardwareIdKey,  //hKey,
                      instanceIdIndex,  //dwIndex
                      instanceIdName,  //lpName,
                      &instanceIdNameSize,  //lpcchName,
                      NULL,  //lpReserved,
                      instanceIdClass,  //lpClass,
                      &instanceIdClassSize,  //lpcchClass,
                      NULL) != ERROR_SUCCESS) {  //lpftLastWriteTime
      //これ以上ないときERROR_NO_MORE_ITEMS
      //instanceIdNameSizeが小さすぎるときERROR_MORE_DATA
      DEBUG ("open: RegEnumKeyEx %ld failed (%ld)\n", instanceIdIndex, GetLastError ());
      goto closeHardwareIdKey;
    } else {
      DEBUG ("open: RegEnumKeyEx %ld success\n", instanceIdIndex);
    }
    DEBUG ("open: instanceIdName is %s\n", instanceIdName);
    char instanceIdPath[768];
    sprintf (instanceIdPath, "%s\\%s", hardwareIdPath, instanceIdName);
    DEBUG ("open: instanceIdPath is %s\n", instanceIdPath);
    //インスタンスレジストリキーを開く
    HKEY instanceIdKey;
    if (RegOpenKeyEx (HKEY_LOCAL_MACHINE,  //hKey
                      instanceIdPath,  //lpSubKey
                      0,  //ulOptions
                      KEY_QUERY_VALUE,  //samDesired
                      &instanceIdKey) != ERROR_SUCCESS) {   //phkResult
      DEBUG ("open: RegOpenKeyEx %s failed (%ld)\n", instanceIdPath, GetLastError ());
      goto nextInstanceId;
    } else {
      DEBUG ("open: RegOpenKeyEx %s success\n", instanceIdPath);
    }
    //ポート名を確認する
    char *subKey = "Device Parameters";
    char *value = "PortName";
    char portName[1024];
    DWORD portNameSize;
    portNameSize = sizeof (portName);
    if (RegGetValue (instanceIdKey,  //hkey
                     subKey,  //lpSubKey
                     value,  //lpValue
                     RRF_RT_REG_SZ,  //dwFlags
                     NULL,  //pdwType
                     portName,  //pvData
                     &portNameSize) != ERROR_SUCCESS) {  //pcbData
      DEBUG ("open: RegGetValue %s\\%s\\%s failed (%ld)\n", instanceIdPath, subKey, value, GetLastError ());
      goto closeInstanceIdKey;
    } else {
      DEBUG ("open: RegGetValue %s\\%s\\%s success\n", instanceIdPath, subKey, value);
    }
    DEBUG ("open: portName is %s\n", portName);
    //ポート番号を確認する
    int portNumber = -1;
    if (sscanf (portName, "COM%d", &portNumber) != 1) {
      DEBUG ("open: sscanf COM%%d failed\n");
      goto closeInstanceIdKey;
    } else {
      DEBUG ("open: sscanf COM%%d success\n");
    }
    DEBUG ("open: portNumber is %d\n", portNumber);
    //シリアルポートを開く
    strcpy (wp->portName, portName);
    if (!open232c (wp)) {
      wp->portName[0] = 0;
    }
  closeInstanceIdKey:
    //インスタンスレジストリキーを閉じる
    if (RegCloseKey (instanceIdKey) != ERROR_SUCCESS) {
      DEBUG ("open: RegCloseKey %s failed (%ld)\n", instanceIdPath, GetLastError ());
    } else {
      DEBUG ("open: RegCloseKey %s success\n", instanceIdPath);
    }
    if (wp->portName[0] != 0) {
      goto closeHardwareIdKey;
    }
  nextInstanceId:
    ;
  }  //for instanceIdIndex
closeHardwareIdKey:
  //ハードウェアレジストリキーを閉じる
  if (RegCloseKey (hardwareIdKey) != ERROR_SUCCESS) {
    DEBUG ("open: RegCloseKey %s failed (%ld)\n", hardwareIdPath, GetLastError ());
  } else {
    DEBUG ("open: RegCloseKey %s success\n", hardwareIdPath);
  }
exit:
  if (wp->portName[0] == 0) {  //見つからなかった
    free (wp);
    char mes[256];
    sprintf (mes, "no serial port found for vid=0x%04lx, pid=0x%04lx", vid, pid);
    throwIOException (env, mes);
    return;
  }
  //openの共通の設定
  openCommon (env, obj, wp);
}  //open

//------------------------------------------------------------------------
//OldSerialPort
//  success = speed (str)
//  通信モードを設定する
//  X68000のSPEED.Xのコマンドラインと同じ書き方で文字列で指定する
//  75bpsと150bpsは指定できない
JNIEXPORT void JNICALL Java_xeij_OldSerialPort_speed (JNIEnv *env, jobject obj, jstring str) {
  //変数を取り出す
  jclass cls = (*env)->GetObjectClass (env, obj);
  jfieldID wpid = (*env)->GetFieldID (env, cls, "wp", "J");
  workarea2_t *wp = (workarea2_t *) (*env)->GetLongField (env, obj, wpid);
  //閉じていたら失敗
  if (wp == NULL || wp->handle == INVALID_HANDLE_VALUE) {
    throwIOException (env, "serial port had been closed");
    return;
  }
  //通信モードを設定する
  char *utf = (char *) (*env)->GetStringUTFChars (env, str, NULL);
  _Bool success = speed232c (wp, utf);
  (*env)->ReleaseStringUTFChars (env, str, utf);
  if (!success) {
    throwIOException (env, "speed232c failed");
    return;
  }
}  //speed



//========================================================================
//  OldSerialPort.SerialInputStream
//========================================================================

#include "xeij_OldSerialPort_SerialInputStream.h"

//------------------------------------------------------------------------
//SerialInputStream
//  length = available ()
//  ブロックせずに受信できる長さを返す
JNIEXPORT jint JNICALL Java_xeij_OldSerialPort_00024SerialInputStream_available (JNIEnv *env, jobject obj) {
  //変数を取り出す
  jclass cls = (*env)->GetObjectClass (env, obj);
  jfieldID wpid = (*env)->GetFieldID (env, cls, "wp", "J");
  workarea2_t *wp = (workarea2_t *) (*env)->GetLongField (env, obj, wpid);
  //ブロックせずに受信できる長さを返す
  return available232c (wp);
}  //available

//------------------------------------------------------------------------
//SerialInputStream
//  close ()
//  受信ストリームを閉じる
JNIEXPORT void JNICALL Java_xeij_OldSerialPort_00024SerialInputStream_close (JNIEnv *env, jobject obj) {
  //変数を消す
  jclass cls = (*env)->GetObjectClass (env, obj);
  jfieldID wpid = (*env)->GetFieldID (env, cls, "wp", "J");
  (*env)->SetLongField (env, obj, wpid, (__int64) 0);
}  //close

//------------------------------------------------------------------------
//SerialInputStream
//  data = read ()
//  1バイト受信する
JNIEXPORT jint JNICALL Java_xeij_OldSerialPort_00024SerialInputStream_read (JNIEnv *env, jobject obj) {
  //変数を取り出す
  jclass cls = (*env)->GetObjectClass (env, obj);
  jfieldID wpid = (*env)->GetFieldID (env, cls, "wp", "J");
  workarea2_t *wp = (workarea2_t *) (*env)->GetLongField (env, obj, wpid);
  //閉じていたら何もしない
  if (wp == NULL || wp->handle == INVALID_HANDLE_VALUE) {
    return 0;
  }
  //1バイト受信する
  wp->inSize = 0;
  if (!ReadFile (wp->handle, wp->inBuffer, 1, (LPDWORD) &wp->inSize, &wp->inOverlapped)) {
    DEBUG ("read: ReadFile failed (%ld)\n", GetLastError ());
    if (GetLastError () == ERROR_IO_PENDING) {
      if (!GetOverlappedResult (wp->handle, &wp->inOverlapped, (LPDWORD) &wp->inSize, TRUE)) {
        DEBUG ("read: GetOverlappedResult failed (%ld)\n", GetLastError ());
      } else {
        DEBUG ("read: GetOverlappedResult success, %zd bytes\n", wp->inSize);
        for (size_t i = 0; i < wp->inSize; i++) {
          DEBUG ("read:   inBuffer[%zd]=0x%02x\n", i, wp->inBuffer[i]);
        }
        if (!ResetEvent (wp->inOverlapped.hEvent)) {
          DEBUG ("read: ResetEvent failed (%ld)\n", GetLastError ());
        } else {
          DEBUG ("read: ResetEvent success\n");
        }
      }
    }
  } else {
    DEBUG ("read: ReadFile success, %zd bytes\n", wp->inSize);
    for (size_t i = 0; i < wp->inSize; i++) {
      DEBUG ("read:   inBuffer[%zd]=0x%02x\n", i, wp->inBuffer[i]);
    }
  }
  return wp->inSize < 1 ? -1 : wp->inBuffer[0] & 0xff;
}  //read



//========================================================================
//  OldSerialPort.SerialOutputStream
//========================================================================

#include "xeij_OldSerialPort_SerialOutputStream.h"

//------------------------------------------------------------------------
//SerialOutputStream
//  close ()
//  送信ストリームを閉じる
JNIEXPORT void JNICALL Java_xeij_OldSerialPort_00024SerialOutputStream_close (JNIEnv *env, jobject obj) {
  //変数を消す
  jclass cls = (*env)->GetObjectClass (env, obj);
  jfieldID wpid = (*env)->GetFieldID (env, cls, "wp", "J");
  (*env)->SetLongField (env, obj, wpid, (__int64) 0);
}  //close

//------------------------------------------------------------------------
//SerialOutputStream
//  write (data)
//  1バイト送信する
JNIEXPORT void JNICALL Java_xeij_OldSerialPort_00024SerialOutputStream_write (JNIEnv *env, jobject obj, jint data) {
  //変数を取り出す
  jclass cls = (*env)->GetObjectClass (env, obj);
  jfieldID wpid = (*env)->GetFieldID (env, cls, "wp", "J");
  workarea2_t *wp = (workarea2_t *) (*env)->GetLongField (env, obj, wpid);
  //閉じていたら何もしない
  if (wp == NULL || wp->handle == INVALID_HANDLE_VALUE) {
    return;
  }
  //1バイト送信する
  wp->outBuffer[0] = (unsigned char) data;
  wp->outSize = 0;
  if (!WriteFile (wp->handle, wp->outBuffer, 1, (LPDWORD) &wp->outSize, &wp->outOverlapped)) {
    DEBUG ("write: WriteFile failed (%ld)\n", GetLastError ());
    if (GetLastError () == ERROR_IO_PENDING) {
      if (!GetOverlappedResult (wp->handle, &wp->outOverlapped, (LPDWORD) &wp->outSize, TRUE)) {
        DEBUG ("write: GetOverlappedResult failed (%ld)\n", GetLastError ());
      } else {
        DEBUG ("write: GetOverlappedResult success, %zd bytes\n", wp->outSize);
        for (size_t i = 0; i < wp->outSize; i++) {
          DEBUG ("write:   outBuffer[%zd]=0x%02x\n", i, wp->outBuffer[i]);
        }
        if (!ResetEvent (wp->outOverlapped.hEvent)) {
          DEBUG ("write: ResetEvent failed (%ld)\n", GetLastError ());
        } else {
          DEBUG ("write: ResetEvent success\n");
        }
      }
    }
  } else {
    DEBUG ("write: WriteFile success, %zd bytes\n", wp->outSize);
    for (size_t i = 0; i < wp->outSize; i++) {
      DEBUG ("write:   outBuffer[%zd]=0x%02x\n", i, wp->outBuffer[i]);
    }
  }
}  //write



//========================================================================
//  ZKeyLEDPort
//========================================================================

#include "xeij_ZKeyLEDPort.h"

#define ZKEY_DEBUG(args...) {  \
  fprintf (stderr, "%s:%d:", __FILE__, __LINE__);  \
  fprintf (stderr, args);  \
  fflush (stderr);  \
}

//------------------------------------------------------------------------
//ZKeyLEDPort
//  close ()
//  ポートを閉じる
JNIEXPORT void JNICALL Java_xeij_ZKeyLEDPort_close (JNIEnv *env, jobject obj) {
  //変数からハンドルを読み出す
  jclass cls = (*env)->GetObjectClass (env, obj);
  jfieldID handleId = (*env)->GetFieldID (env, cls, "handle", "J");
  HANDLE handle = (HANDLE) (*env)->GetLongField (env, obj, handleId);
  //閉じていたら何もしない
  if (handle == (void *) 0) {
    return;
  }
  //ハンドルを閉じる
  CloseHandle (handle);
  //ハンドルを消す
  handle = (void *) 0;
  //ハンドルを変数へ書き込む
  (*env)->SetLongField (env, obj, handleId, (__int64) handle);
}  //close

//------------------------------------------------------------------------
//ZKeyLEDPort
//  hitKey (vk)
//  キーを叩く
//  vk       キー
JNIEXPORT void JNICALL Java_xeij_ZKeyLEDPort_hitKey (JNIEnv *env, jobject obj, jint vk) {
  INPUT pInputs[2];
  memset (pInputs, 0, sizeof (pInputs));
  pInputs[0].type = INPUT_KEYBOARD;
  pInputs[0].ki.wVk = vk;
  pInputs[1].type = INPUT_KEYBOARD;
  pInputs[1].ki.wVk = vk;
  pInputs[1].ki.dwFlags = KEYEVENTF_KEYUP;
  SendInput (2,  //cInputs
             pInputs,  //pInputs
             sizeof (INPUT));  //cbInput
}  //hitKey

//------------------------------------------------------------------------
//ZKeyLEDPort
//  pressed = isKeyPressed (vk)
//  キーは押されているか
//  vk       キー
//  pressed  true   キーは押されている
//           false  キーは離されている
JNIEXPORT jboolean JNICALL Java_xeij_ZKeyLEDPort_isKeyPressed (JNIEnv *env, jobject obj, jint vk) {
  return (GetKeyState (vk) & 128) != 0 ? JNI_TRUE : JNI_FALSE;
}  //isKeyPressed

//------------------------------------------------------------------------
//ZKeyLEDPort
//  toggled = isKeyToggled (vk)
//  キーは点灯しているか
//  vk       キー
//  toggled  true   キーは点灯している
//           false  キーは消灯している
JNIEXPORT jboolean JNICALL Java_xeij_ZKeyLEDPort_isKeyToggled (JNIEnv *env, jobject obj, jint vk) {
  return (GetKeyState (vk) & 1) != 0 ? JNI_TRUE : JNI_FALSE;
}  //isKeyToggled

static void printCaps (const char *devicePath) {
  fprintf (stderr, "--------------------------------------\n");
  fprintf (stderr, "%s\n", devicePath);
  fprintf (stderr, "--------------------------------------\n");
  HANDLE handle = CreateFile (devicePath,  //lpFileName
                              0,  //dwDesiredAccess
                              FILE_SHARE_READ | FILE_SHARE_WRITE,  //dwShareMode
                              NULL,  //lpSecurityAttributes
                              OPEN_EXISTING,  //dwCreationDisposition
                              0,  //dwFlagsAndAttributes
                              NULL);  //hTemplateFile
  if (handle == INVALID_HANDLE_VALUE) {
    ZKEY_DEBUG ("printCaps: CreateFile %s failed (%ld)\n", devicePath, GetLastError ());
    return;
  }
  HIDD_ATTRIBUTES attributes[1];
  memset (attributes, 0, sizeof (HIDD_ATTRIBUTES));
  if (!HidD_GetAttributes (handle, attributes)) {
    ZKEY_DEBUG ("printCaps: HidD_GetAttributes failed (%ld)\n", GetLastError ());
  } else {
    fprintf (stderr, "VendorID\t\t\t0x%04x\n", attributes->VendorID);
    fprintf (stderr, "ProductID\t\t\t0x%04x\n", attributes->ProductID);
    fprintf (stderr, "VersionNumber\t\t\t0x%04x\n", attributes->VersionNumber);
    fprintf (stderr, "--------------------------------------\n");
  }
  PHIDP_PREPARSED_DATA preparsedData = NULL;
  if (!HidD_GetPreparsedData (handle,  //HidDeviceObject
                              &preparsedData)) {  //*PreparsedData
    ZKEY_DEBUG ("printCaps: HidD_GetPreparsedData failed (%ld)\n", GetLastError ());
    return;
  }
  HIDP_CAPS caps[1];
  memset (caps, 0, sizeof (HIDP_CAPS));
  if (!HidP_GetCaps (preparsedData, caps)) {
    ZKEY_DEBUG ("printCaps: HidP_GetCaps failed (%ld)\n", GetLastError ());
  } else {
    fprintf (stderr, "Usage\t\t\t\t0x%04x\n", caps->Usage);
    fprintf (stderr, "UsagePage\t\t\t0x%04x\n", caps->UsagePage);
    fprintf (stderr, "InputReportByteLength\t\t0x%04x\n", caps->InputReportByteLength);
    fprintf (stderr, "OutputReportByteLength\t\t0x%04x\n", caps->OutputReportByteLength);
    fprintf (stderr, "FeatureReportByteLength\t\t0x%04x\n", caps->FeatureReportByteLength);
    fprintf (stderr, "NumberLinkCollectionNodes\t0x%04x\n", caps->NumberLinkCollectionNodes);
    fprintf (stderr, "NumberInputButtonCaps\t\t0x%04x\n", caps->NumberInputButtonCaps);
    fprintf (stderr, "NumberInputValueCaps\t\t0x%04x\n", caps->NumberInputValueCaps);
    fprintf (stderr, "NumberInputDataIndices\t\t0x%04x\n", caps->NumberInputDataIndices);
    fprintf (stderr, "NumberOutputButtonCaps\t\t0x%04x\n", caps->NumberOutputButtonCaps);
    fprintf (stderr, "NumberOutputValueCaps\t\t0x%04x\n", caps->NumberOutputValueCaps);
    fprintf (stderr, "NumberOutputDataIndices\t\t0x%04x\n", caps->NumberOutputDataIndices);
    fprintf (stderr, "NumberFeatureButtonCaps\t\t0x%04x\n", caps->NumberFeatureButtonCaps);
    fprintf (stderr, "NumberFeatureValueCaps\t\t0x%04x\n", caps->NumberFeatureValueCaps);
    fprintf (stderr, "NumberFeatureDataIndices\t0x%04x\n", caps->NumberFeatureDataIndices);
    fprintf (stderr, "--------------------------------------\n");
  }
  if (!HidD_FreePreparsedData (preparsedData)) {
    ZKEY_DEBUG ("printCaps: HidD_FreePreparsedData failed (%ld)\n", GetLastError ());
  }
  if (!CloseHandle (handle)) {
    ZKEY_DEBUG ("printCaps: CloseHandle failed (%ld)\n", GetLastError ());
  }
  fflush (stderr);
}

//------------------------------------------------------------------------
//ZKeyLEDPort
//  open ()
//  ポートを開く
JNIEXPORT void JNICALL Java_xeij_ZKeyLEDPort_open (JNIEnv *env, jobject obj) {
  //変数からハンドルを読み出す
  jclass cls = (*env)->GetObjectClass (env, obj);
  jfieldID handleId = (*env)->GetFieldID (env, cls, "handle", "J");
  HANDLE handle = (HANDLE) (*env)->GetLongField (env, obj, handleId);
  //変数からデバッグフラグを読み出す
  jfieldID debugFlagId = (*env)->GetFieldID (env, cls, "debugFlag", "Z");
  jboolean debugFlag = (*env)->GetBooleanField (env, obj, debugFlagId);
  //開いていたら失敗
  //  Javaは変数にゴミが入っていることはない
  if (handle != NULL) {
    if (debugFlag != JNI_FALSE) {
      ZKEY_DEBUG ("open: already open\n");
    }
    throwIOException (env, "already open");
    return;
  }
  //デバイス情報セットを作る
  GUID hidGuid[1];
  memset (hidGuid, 0, sizeof (GUID));
  HidD_GetHidGuid (hidGuid);  //HidD_GetHidGuidはエラーを返さない
  HDEVINFO infoSet = SetupDiGetClassDevs (hidGuid,  //ClassGuid
                                          NULL,  //Enumerator
                                          NULL,  //hwndParent
                                          DIGCF_DEVICEINTERFACE | DIGCF_PRESENT);  //Flags
  if (infoSet == INVALID_HANDLE_VALUE) {
    if (debugFlag != JNI_FALSE) {
      ZKEY_DEBUG ("open: SetupDiGetClassDevs failed (%ld)\n", GetLastError ());
    }
    throwIOException (env, "SetupDiGetClassDevs failed");
    return;
  } else {
    if (debugFlag != JNI_FALSE) {
      ZKEY_DEBUG ("open: SetupDiGetClassDevs success\n");
    }
  }
  char targetPath[MAX_PATH];
  targetPath[0] = 0;
  //デバイスを探す
  for (int index = 0; ; index++) {
    //デバイスインターフェイスを得る
    SP_DEVICE_INTERFACE_DATA interfaceData[1];
    memset (interfaceData, 0, sizeof (SP_DEVICE_INTERFACE_DATA));
    interfaceData->cbSize = sizeof (SP_DEVICE_INTERFACE_DATA);
    if (!SetupDiEnumDeviceInterfaces (infoSet,  //DeviceInfoSet
                                      0,  //DeviceInfoData
                                      hidGuid,  //InterfaceClassGuid
                                      index,  //MemberIndex
                                      interfaceData)) {  //DeviceInterfaceData
      DWORD error = GetLastError ();
      if (error != ERROR_NO_MORE_ITEMS) {
        if (debugFlag != JNI_FALSE) {
          ZKEY_DEBUG ("open: index %d, SetupDiEnumDeviceInterfaces failed (%ld)\n", index, error);
        }
      } else {
        if (debugFlag != JNI_FALSE) {
          ZKEY_DEBUG ("open: index %d, no more items\n", index);
        }
      }
      break;
    }
    if (debugFlag != JNI_FALSE) {
      ZKEY_DEBUG ("open: index %d, SetupDiEnumDeviceInterfaces success\n", index);
    }
    //デバイスインターフェイスの詳細のサイズを得る
    DWORD detailSize = 0;
    SetupDiGetDeviceInterfaceDetail (infoSet,  //DeviceInfoSet
                                     interfaceData,  //DeviceInterfaceData
                                     NULL,  //DeviceInterfaceDetailData
                                     0,  //DeviceInterfaceDetailDataSize
                                     &detailSize,  //RequiredSize
                                     NULL);  //DeviceInfoData
    if (GetLastError () != ERROR_INSUFFICIENT_BUFFER) {
      if (debugFlag != JNI_FALSE) {
        ZKEY_DEBUG ("open: index %d, SetupDiGetDeviceInterfaceDetail failed (%ld)\n", index, GetLastError ());
      }
      continue;
    } else {
      if (debugFlag != JNI_FALSE) {
        ZKEY_DEBUG ("open: index %d, SetupDiGetDeviceInterfaceDetail insufficient buffer, detailSize %ld\n", index, detailSize);
      }
    }
    //デバイスインターフェイスの詳細を得る
    SP_DEVICE_INTERFACE_DETAIL_DATA *detailData = malloc (detailSize);
    memset (detailData, 0, detailSize);
    detailData->cbSize = sizeof (SP_DEVICE_INTERFACE_DETAIL_DATA);  //detailSizeではない
    if (!SetupDiGetDeviceInterfaceDetail (infoSet,  //DeviceInfoSet
                                          interfaceData,  //DeviceInterfaceData
                                          detailData,  //DeviceInterfaceDetailData
                                          detailSize,  //DeviceInterfaceDetailDataSize
                                          NULL,  //RequiredSize
                                          NULL)) {  //DeviceInfoData
      if (debugFlag != JNI_FALSE) {
        ZKEY_DEBUG ("open: index %d, SetupDiGetDeviceInterfaceDetail failed (%ld)\n", index, GetLastError ());
      }
      continue;
    } else {
      if (debugFlag != JNI_FALSE) {
        ZKEY_DEBUG ("open: index %d, SetupDiGetDeviceInterfaceDetail success\n", index);
      }
    }
    //デバイスパスをコピーする
    char devicePath[MAX_PATH];
    strcpy (devicePath, detailData->DevicePath);
    free (detailData);
    char lowerPath[MAX_PATH];
    strcpy (lowerPath, devicePath);
    strlwr (lowerPath);
    //情報を表示する
    if (debugFlag != JNI_FALSE) {
      printCaps (devicePath);
    }
    //デバイスパスを比較する
    //  DevicePathはcase-insensitive。strcasestrは非標準
    if (strstr (lowerPath, "vid_33dd&pid_0011&mi_01&col05") == NULL) {
      if (debugFlag != JNI_FALSE) {
        ZKEY_DEBUG ("open: index %d, mismatch\n", index);
      }
      continue;
    } else {
      if (debugFlag != JNI_FALSE) {
        ZKEY_DEBUG ("open: index %d, match\n", index);
      }
    }
    strcpy (targetPath, devicePath);
  }  //for index
  //デバイス情報セットを捨てる
  if (!SetupDiDestroyDeviceInfoList (infoSet)) {
    if (debugFlag != JNI_FALSE) {
      ZKEY_DEBUG ("open: SetupDiDestroyDeviceInfoList failed (%ld)\n", GetLastError ());
    }
    throwIOException (env, "SetupDiDestroyDeviceInfoList failed");
    return;
  } else {
    if (debugFlag != JNI_FALSE) {
      ZKEY_DEBUG ("open: SetupDiDestroyDeviceInfoList success\n");
    }
  }
  //見つからなかったら失敗
  if (targetPath[0] == 0) {
    if (debugFlag != JNI_FALSE) {
      ZKEY_DEBUG ("open: device not found\n");
    }
    throwIOException (env, "device not found");
    return;
  } else {
    if (debugFlag != JNI_FALSE) {
      ZKEY_DEBUG ("open: device found\n");
    }
  }
  //デバイスを開く
  handle = CreateFile (targetPath,  //lpFileName
                       0,  //dwDesiredAccess
                       FILE_SHARE_READ | FILE_SHARE_WRITE,  //dwShareMode
                       NULL,  //lpSecurityAttributes
                       OPEN_EXISTING,  //dwCreationDisposition
                       0,  //dwFlagsAndAttributes
                       NULL);  //hTemplateFile
  if (handle == INVALID_HANDLE_VALUE) {
    if (debugFlag != JNI_FALSE) {
      ZKEY_DEBUG ("open: CreateFile %s failed (%ld)\n", targetPath, GetLastError ());
      ZKEY_DEBUG ("open: device not available\n");
    }
    throwIOException (env, "device not available");
    return;
  } else {
    if (debugFlag != JNI_FALSE) {
      ZKEY_DEBUG ("open: CreateFile %s success\n", targetPath);
    }
  }
  //ハンドルを変数へ書き込む
  (*env)->SetLongField (env, obj, handleId, (__int64) handle);
  //成功して終了
}  //open

//------------------------------------------------------------------------
//ZKeyLEDPort
//  success = send (data)
//  LEDのデータを送る
//  success  true   成功
//           false  失敗
//  data    LEDのデータ。0=消灯,…,32=暗い,…,64=やや暗い,…,128=やや明るい,…,255=明るい
//          +----------+----------+----------+----------+----------+----------+----------+----------+
//          |63      56|55      48|47      40|39      32|31      24|23      16|15       8|7        0|
//          |          |   全角   | ひらがな |    INS   |   CAPS   |コード入力| ローマ字 |   かな   |
//          +----------+----------+----------+----------+----------+----------+----------+----------+
JNIEXPORT jboolean JNICALL Java_xeij_ZKeyLEDPort_send (JNIEnv *env, jobject obj, jlong data) {
  //変数からハンドルを読み出す
  jclass cls = (*env)->GetObjectClass (env, obj);
  jfieldID handleId = (*env)->GetFieldID (env, cls, "handle", "J");
  HANDLE handle = (HANDLE) (*env)->GetLongField (env, obj, handleId);
  //閉じていたら失敗
  if (handle == (void *) 0) {
    return JNI_FALSE;
  }
  //機能レポートを作る
  static const int indexes[7] = { 7, 8, 9, 10, 11, 13, 14 };
  const size_t length = 65;
  char report[length];
  memset (report, 0, length);
  report[0] = (char) 10;
  report[1] = (char) 248;
  for (int i = 0; i < 7; i++) {
    report[indexes[i]] = (char) (data >> (8 * i));
  }
  //機能レポートを送る
  return HidD_SetFeature (handle,  //HidDeviceObject
                          report,  //ReportBuffer
                          length) ? JNI_TRUE : JNI_FALSE;  //ReportBufferLength
}  //send



