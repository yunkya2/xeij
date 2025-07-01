//========================================================================================
//  M68kException.java
//    en:M68k exception
//    ja:M68kの例外
//  Copyright (C) 2003-2025 Makoto Kamada
//
//  This file is part of the XEiJ (X68000 Emulator in Java).
//  You can use, modify and redistribute the XEiJ if the conditions are met.
//  Read the XEiJ License for more details.
//  https://stdkmd.net/xeij/
//========================================================================================

//----------------------------------------------------------------------------------------
//  throwするオブジェクトは1個だけで個々の例外の情報は持たない
//  例外の情報をフィールドに格納してからthrowする
//  プログラムカウンタはバスエラーとアドレスエラーのときはpc0、それ以外はpcを用いる
//----------------------------------------------------------------------------------------

package xeij;

import java.lang.*;  //Boolean,Character,Class,Comparable,Double,Exception,Float,IllegalArgumentException,Integer,Long,Math,Number,Object,Runnable,SecurityException,String,StringBuilder,System

public class M68kException extends Exception {

  public static final boolean M6E_DEBUG_ERROR = false;

  //特殊例外
  public static final int M6E_INSTRUCTION_BREAK_POINT = -1;  //命令ブレークポイント
  public static final int M6E_WAIT_EXCEPTION          = -2;  //待機例外

  //例外ベクタ番号
  //  F=スタックされたPCは命令の先頭を指す
  //  N=スタックされたPCは次の命令を指す
  public static final int M6E_RESET_INITIAL_SSP              =  0;  //0000     012346  Reset Initial Interrupt Stack Pointer
  public static final int M6E_RESET_INITIAL_PC               =  1;  //0004     012346  Reset Initial Program Counter
  public static final int M6E_ACCESS_FAULT                   =  2;  //4008  F  012346  Access Fault アクセスフォルト
  public static final int M6E_ADDRESS_ERROR                  =  3;  //200C  F  012346  Address Error アドレスエラー
  public static final int M6E_ILLEGAL_INSTRUCTION            =  4;  //0010  F  012346  Illegal Instruction 不当命令
  public static final int M6E_DIVIDE_BY_ZERO                 =  5;  //2014  N  012346  Integer Divide by Zero ゼロ除算
  public static final int M6E_CHK_INSTRUCTION                =  6;  //2018  N  012346  CHK, CHK2 instructions CHK命令
  public static final int M6E_TRAPV_INSTRUCTION              =  7;  //201C  N  012346  FTRAPcc, TRAPcc, TRAPV instructions TRAPV命令
  public static final int M6E_PRIVILEGE_VIOLATION            =  8;  //0020  F  012346  Privilege Violation 特権違反
  public static final int M6E_TRACE                          =  9;  //2024  N  012346  Trace トレース
  public static final int M6E_LINE_1010_EMULATOR             = 10;  //0028  F  012346  Line 1010 Emulator (Unimplemented A-Line opcode) ライン1010エミュレータ(SXコール)
  public static final int M6E_LINE_1111_EMULATOR             = 11;  //002C  F  012346  Line 1111 Emulator (Unimplemented F-Line opcode) ライン1111エミュレータ(DOSコール,FEファンクションコール)
  public static final int M6E_FP_UNIMPLEMENTED_INSTRUCTION   = 11;  //202C  N  -----6  未実装浮動小数点命令
  public static final int M6E_FP_DISABLED                    = 11;  //402C  N  -----6  浮動小数点無効
  public static final int M6E_EMULATOR_INTERRUPT             = 12;  //0030  N  -----S  エミュレータ割り込み
  public static final int M6E_COPROCESSOR_PROTOCOL_VIOLATION = 13;  //0034     ---C--  コプロセッサプロトコル違反
  public static final int M6E_FORMAT_ERROR                   = 14;  //0038  F  -12346  フォーマットエラー
  public static final int M6E_UNINITIALIZED_INTERRUPT        = 15;  //003C  N  012346  未初期化割り込み
  public static final int M6E_SPURIOUS_INTERRUPT             = 24;  //0060  N  012346  スプリアス割り込み
  public static final int M6E_LEVEL_1_INTERRUPT_AUTOVECTOR   = 25;  //0064  N  012346  レベル1割り込みオートベクタ(FDC,FDD,ハードディスク,プリンタ)
  public static final int M6E_LEVEL_2_INTERRUPT_AUTOVECTOR   = 26;  //0068  N  012346  レベル2割り込みオートベクタ(拡張I/Oスロット)
  public static final int M6E_LEVEL_3_INTERRUPT_AUTOVECTOR   = 27;  //006C  N  012346  レベル3割り込みオートベクタ(DMAコントローラ転送終了など)
  public static final int M6E_LEVEL_4_INTERRUPT_AUTOVECTOR   = 28;  //0070  N  012346  レベル4割り込みオートベクタ(拡張I/Oスロット)
  public static final int M6E_LEVEL_5_INTERRUPT_AUTOVECTOR   = 29;  //0074  N  012346  レベル5割り込みオートベクタ(SCC RS-232C,マウス)
  public static final int M6E_LEVEL_6_INTERRUPT_AUTOVECTOR   = 30;  //0078  N  012346  レベル6割り込みオートベクタ(MFP 各種タイマ,KEY,同期など)
  public static final int M6E_LEVEL_7_INTERRUPT_AUTOVECTOR   = 31;  //007C  N  012346  レベル7割り込みオートベクタ(NMI)
  public static final int M6E_TRAP_0_INSTRUCTION_VECTOR      = 32;  //0080  N  012346  TRAP#0命令ベクタ
  public static final int M6E_TRAP_1_INSTRUCTION_VECTOR      = 33;  //0084  N  012346  TRAP#1命令ベクタ(MPCM,BGDRV)
  public static final int M6E_TRAP_2_INSTRUCTION_VECTOR      = 34;  //0088  N  012346  TRAP#2命令ベクタ(PCM8)
  public static final int M6E_TRAP_3_INSTRUCTION_VECTOR      = 35;  //008C  N  012346  TRAP#3命令ベクタ(ZMUSIC,ZMSC3,MIDDRV)
  public static final int M6E_TRAP_4_INSTRUCTION_VECTOR      = 36;  //0090  N  012346  TRAP#4命令ベクタ(MXDRV,MADRV,MLD,MCDRV)
  public static final int M6E_TRAP_5_INSTRUCTION_VECTOR      = 37;  //0094  N  012346  TRAP#5命令ベクタ(CDC)
  public static final int M6E_TRAP_6_INSTRUCTION_VECTOR      = 38;  //0098  N  012346  TRAP#6命令ベクタ
  public static final int M6E_TRAP_7_INSTRUCTION_VECTOR      = 39;  //009C  N  012346  TRAP#7命令ベクタ
  public static final int M6E_TRAP_8_INSTRUCTION_VECTOR      = 40;  //00A0  N  012346  TRAP#8命令ベクタ(ROMデバッガがブレークポイントに使用)M6E_
  public static final int M6E_TRAP_9_INSTRUCTION_VECTOR      = 41;  //00A4  N  012346  TRAP#9命令ベクタ(デバッガがブレークポイントに使用)
  public static final int M6E_TRAP_10_INSTRUCTION_VECTOR     = 42;  //00A8  N  012346  TRAP#10命令ベクタ(POWER OFFまたはリセット)
  public static final int M6E_TRAP_11_INSTRUCTION_VECTOR     = 43;  //00AC  N  012346  TRAP#11命令ベクタ(BREAK)
  public static final int M6E_TRAP_12_INSTRUCTION_VECTOR     = 44;  //00B0  N  012346  TRAP#12命令ベクタ(COPY)
  public static final int M6E_TRAP_13_INSTRUCTION_VECTOR     = 45;  //00B4  N  012346  TRAP#13命令ベクタ(^C)
  public static final int M6E_TRAP_14_INSTRUCTION_VECTOR     = 46;  //00B8  N  012346  TRAP#14命令ベクタ(エラー表示)
  public static final int M6E_TRAP_15_INSTRUCTION_VECTOR     = 47;  //00BC  N  012346  TRAP#15命令ベクタ(IOCSコール)
  public static final int M6E_FP_BRANCH_SET_UNORDERED        = 48;  //00C0  F  --CC46  浮動小数点比較不能状態での分岐またはセット
  public static final int M6E_FP_INEXACT_RESULT              = 49;  //00C4  N  --CC46  浮動小数点不正確な結果
  //                                                                     30C4  N
  public static final int M6E_FP_DIVIDE_BY_ZERO              = 50;  //00C8  N  --CC46  浮動小数点ゼロによる除算
  public static final int M6E_FP_UNDERFLOW                   = 51;  //00CC  N  --CC46  浮動小数点アンダーフロー
  //                                                                     30CC  N
  public static final int M6E_FP_OPERAND_ERROR               = 52;  //00D0  N  --CC46  浮動小数点オペランドエラー
  //                                                                     30D0  N
  public static final int M6E_FP_OVERFLOW                    = 53;  //00D4  N  --CC46  浮動小数点オーバーフロー
  //                                                                     30D4  N
  public static final int M6E_FP_SIGNALING_NAN               = 54;  //00D8  N  --CC46  浮動小数点シグナリングNAN
  //                                                                     30D8  N
  public static final int M6E_FP_UNSUPPORTED_DATA_TYPE       = 55;  //00DC  N  ----46  浮動小数点未実装データ型(pre- 非正規化数)
  //                                                                     20DC  N  ----46  浮動小数点未実装データ型(パックトデシマル)
  //                                                                     30DC  N  ----46  浮動小数点未実装データ型(post- 非正規化数)
  public static final int M6E_MMU_CONFIGULATION_ERROR        = 56;  // 0E0  N  --M3--  MMUコンフィギュレーションエラー
  public static final int M6E_MMU_ILLEGAL_OPERATION_ERROR    = 57;  // 0E4     --M---  MMU不当操作エラー
  public static final int M6E_MMU_ACCESS_LEVEL_VIOLATION     = 58;  // 0E8     --M---  MMUアクセスレベル違反
  //  未実装実効アドレス(MC68060)
  //    ベクタ番号60、フォーマット0。PCは例外を発生させた命令
  //      Fop.X #<data>,FPn
  //      Fop.P #<data>,FPn
  //      FMOVEM.L #<data>,#<data>,FPSR/FPIAR
  //      FMOVEM.L #<data>,#<data>,FPCR/FPIAR
  //      FMOVEM.L #<data>,#<data>,FPCR/FPSR
  //      FMOVEM.L #<data>,#<data>,#<data>,FPCR/FPSR/FPIAR
  //      FMOVEM.X <ea>,Dn
  //      FMOVEM.X Dn,<ea>
  public static final int M6E_UNIMPLEMENTED_EFFECTIVE        = 60;  //00F0  F  -----6  未実装実効アドレス
  //  未実装整数命令(MC68060)
  //    ベクタ番号61、フォーマット0。PCは例外を発生させた命令
  //      MULU.L <ea>,Dh:Dl
  //      MULS.L <ea>,Dh:Dl
  //      DIVU.L <ea>,Dr:Dq
  //      DIVS.L <ea>,Dr:Dq
  //      CAS2.W Dc1:Dc2,Du1:Du2,(Rn1):(Rn2)
  //      CAS2.L Dc1:Dc2,Du1:Du2,(Rn1):(Rn2)
  //      CHK2.B <ea>,Rn
  //      CHK2.W <ea>,Rn
  //      CHK2.L <ea>,Rn
  //      CMP2.B <ea>,Rn
  //      CMP2.W <ea>,Rn
  //      CMP2.L <ea>,Rn
  //      CAS.W Dc,Du,<ea> (misaligned <ea>)
  //      CAS.L Dc,Du,<ea> (misaligned <ea>)
  //      MOVEP.W (d16,Ar),Dq
  //      MOVEP.L (d16,Ar),Dq
  //      MOVEP.W Dq,(d16,Ar)
  //      MOVEP.L Dq,(d16,Ar)
  public static final int M6E_UNIMPLEMENTED_INSTRUCTION      = 61;  //00F4  F  -----6  未実装整数命令

  public static final String[] M6E_ERROR_NAME = {
    "undefined exception #0",  //0
    "undefined exception #1",  //1
    "Access fault",  //2
    "Address error",  //3
    "Illegal instruction",  //4
    "Divide by zero",  //5
    "CHK instruction",  //6
    "Trapv instruction",  //7
    "Privilege violation",  //8
    "Trace",  //9
    "Line 1010 emulator",  //10
    "Line 1111 emulator",  //11
    "Emulator interrupt",  //12
    "Coprocessor protocol violation",  //13
    "Format error",  //14
    "Uninitialized interrupt",  //15
    "undefined exception #16",  //16
    "undefined exception #17",  //17
    "undefined exception #18",  //18
    "undefined exception #19",  //19
    "undefined exception #20",  //20
    "undefined exception #21",  //21
    "undefined exception #22",  //22
    "undefined exception #23",  //23
    "Spurious interrupt",  //24
    "Level 1 interrupt autovector",  //25
    "Level 2 interrupt autovector",  //26
    "Level 3 interrupt autovector",  //27
    "Level 4 interrupt autovector",  //28
    "Level 5 interrupt autovector",  //29
    "Level 6 interrupt autovector",  //30
    "Level 7 interrupt autovector",  //31
    "TRAP #0 instruction vector",  //32
    "TRAP #1 instruction vector",  //33
    "TRAP #2 instruction vector",  //34
    "TRAP #3 instruction vector",  //35
    "TRAP #4 instruction vector",  //36
    "TRAP #5 instruction vector",  //37
    "TRAP #6 instruction vector",  //38
    "TRAP #7 instruction vector",  //39
    "TRAP #8 instruction vector",  //40
    "TRAP #9 instruction vector",  //41
    "TRAP #10 instruction vector",  //42
    "TRAP #11 instruction vector",  //43
    "TRAP #12 instruction vector",  //44
    "TRAP #13 instruction vector",  //45
    "TRAP #14 instruction vector",  //46
    "TRAP #15 instruction vector",  //47
    "FP branch/set on unordered ",  //48
    "FP inexact result",  //49
    "FP divide by zero",  //50
    "FP underflow",  //51
    "FP operand error",  //52
    "FP overflow",  //53
    "FP signaling NAN",  //54
    "FP unsupported data type",  //55
    "MMU configulation error",  //56
    "MMU illegal operation error",  //57
    "MMU access level violation",  //58
    "undefined exception #59",  //59
    "Unimplemented effective address",  //60
    "Unimplemented instruction",  //61
    "undefined exception #62",  //62
    "undefined exception #63",  //63
  };

  public static M68kException m6eSignal;  //throwする唯一のインスタンス
  public static int m6eNumber;  //ベクタ番号。0～255
  public static int m6eAddress;  //アクセスアドレス
  public static int m6eDirection;  //転送方向。0=WRITE,1=READ
  public static int m6eSize;  //オペレーションサイズ。0=BYTE,1=WORD,2=LONG

  //  MC68060のページフォルトに関する考察
  //    ページフォルトが発生すると、プレデクリメントとポストインクリメントによるアドレスレジスタの変化がすべてキャンセルされる
  //      MOVE.B (A0)+,(A0)+またはMOVE.B -(A0),-(A0)でソースまたはデスティネーションでページフォルトが発生したとき、
  //      どの組み合わせでもA0は命令開始時の値のままアクセスフォルトハンドラに移行する
  //    RTEでページフォルトを発生させた命令に復帰すると、ソースをリードするところからやり直す
  //      MOVE.B <mem>,<mem>のデスティネーションのライトでページフォルトが発生したとき、ソースのリードが2回行われる
  //      これはMC68060ユーザーズマニュアルの7.10 BUS SYNCHRONIZATIONに書かれており、
  //      060turboでも、ページフォルトのハンドラでソースを書き換えると結果に反映されることから、リードが再実行されていることを確認できる
  //      リードすると値が変化する可能性のあるデバイスから非常駐の可能性のあるページに転送するとき、MOVE.B <mem>,<mem>を使ってはいけない
  //        http://cache.freescale.com/files/32bit/doc/ref_manual/MC68060UM.pdf

  //  FSLW  Fault Status Long Word
  //      31  30  29  28  27  26  25  24  23  22  21  20  19  18  17  16  15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
  //    ┏━━━━━━━┯━┯━┯━┯━━━┯━━━┯━━━┯━━━━━┯━┯━┯━┯━┯━┯━┯━┯━┯━┯━┯━┯━┯━┯━┯━┯━┓
  //    ┃              │MA│  │LK│  RW  │ SIZE │  TT  │    TM    │IO│PBE SBE PTA PTB IL│PF│SP│WP│TWE RE│WE│TTR BPE    SEE┃
  //    ┗━━━━━━━┷━┷━┷━┷━━━┷━━━┷━━━┷━━━━━┷━┷━┷━┷━┷━┷━┷━┷━┷━┷━┷━┷━┷━┷━┷━┷━┛
  public static final int M6E_FSLW_MISALIGNED         = 1 << 27;  //MA    Misaligned Access
  public static final int M6E_FSLW_LOCKED             = 1 << 25;  //LK    Locked Transfer
  public static final int M6E_FSLW_READ_AND_WRITE     = 3 << 23;  //RW    Read and Write
  public static final int M6E_FSLW_RW_WRITE           = 1 << 23;  //        Write
  public static final int M6E_FSLW_RW_READ            = 2 << 23;  //        Read
  public static final int M6E_FSLW_RW_MODIFY          = 3 << 23;  //        Read-Modify-Write
  public static final int M6E_FSLW_TRANSFER_SIZE      = 3 << 21;  //SIZE  Transfer Size
  public static final int M6E_FSLW_SIZE_LONG          = 0 << 21;  //        Long    マニュアルが間違っているので注意
  public static final int M6E_FSLW_SIZE_BYTE          = 1 << 21;  //        Byte    マニュアルが間違っているので注意
  public static final int M6E_FSLW_SIZE_WORD          = 2 << 21;  //        Word    マニュアルが間違っているので注意
  public static final int M6E_FSLW_SIZE_QUAD          = 3 << 21;  //        Double Precision or MOVE16
  public static final int M6E_FSLW_TRANSFER_TYPE      = 3 << 19;  //TT    Transfer Type
  public static final int M6E_FSLW_TT_NORMAL          = 0 << 19;  //        Normal Access
  public static final int M6E_FSLW_TT_MOVE16          = 1 << 19;  //        MOVE16 Access
  public static final int M6E_FSLW_TT_ALTERNATE       = 2 << 19;  //        Alternate Logical Function Code Access, Debug Access
  public static final int M6E_FSLW_TT_ACKNOWLEDGE     = 3 << 19;  //        Acknowledge Access, Low-Power Stop Broadcast
  public static final int M6E_FSLW_TRANSFER_MODIFIER  = 7 << 16;  //TM    Transfer Modifier
  public static final int M6E_FSLW_TM_CACHE_PUSH      = 0 << 16;  //        Data Cache Push Access
  public static final int M6E_FSLW_TM_USER_DATA       = 1 << 16;  //        User Data Access
  public static final int M6E_FSLW_TM_USER_CODE       = 2 << 16;  //        User Code Access
  public static final int M6E_FSLW_TM_MMU_DATA        = 3 << 16;  //        MMU Table Search Data Access
  public static final int M6E_FSLW_TM_MMU_CODE        = 4 << 16;  //        MMU Table Search Code Access
  public static final int M6E_FSLW_TM_SUPER_DATA      = 5 << 16;  //        Supervisor Data Access
  public static final int M6E_FSLW_TM_SUPER_CODE      = 6 << 16;  //        Supervisor Code Access
  public static final int M6E_FSLW_TM_DATA            = 1 << 16;  //        Data Access
  public static final int M6E_FSLW_TM_CODE            = 2 << 16;  //        Code Access
  public static final int M6E_FSLW_TM_SUPERVISOR      = 4 << 16;  //        Supervisor Access
  public static final int M6E_FSLW_INSTRUCTION        = 1 << 15;  //IO    Instruction or Operand
  public static final int M6E_FSLW_IOMA_FIRST         = 0 << 15 | 0 << 27;  //Fault occurred on the first access of a misaligned transfer, or to the only access of an aligned transfer
  public static final int M6E_FSLW_IOMA_SECOND        = 0 << 15 | 1 << 27;  //Fault occurred on the second or later access of a misaligned transfer
  public static final int M6E_FSLW_IOMA_OPWORD        = 1 << 15 | 0 << 27;  //Fault occurred on an instruction opword fetch
  public static final int M6E_FSLW_IOMA_EXWORD        = 1 << 15 | 1 << 27;  //Fault occurred on a fetch of an extension word
  public static final int M6E_FSLW_PUSH_BUFFER        = 1 << 14;  //PBE   Push Buffer Bus Error
  public static final int M6E_FSLW_STORE_BUFFER       = 1 << 13;  //SBE   Store Buffer Bus Error
  public static final int M6E_FSLW_ROOT_DESCRIPTOR    = 1 << 12;  //PTA   Pointer A Fault
  public static final int M6E_FSLW_POINTER_DESCRIPTOR = 1 << 11;  //PTB   Pointer B Fault
  public static final int M6E_FSLW_INDIRECT_LEVEL     = 1 << 10;  //IL    Indirect Level Fault
  public static final int M6E_FSLW_PAGE_FAULT         = 1 <<  9;  //PF    Page Fault
  public static final int M6E_FSLW_SUPERVISOR_PROTECT = 1 <<  8;  //SP    Supervisor Protect
  public static final int M6E_FSLW_WRITE_PROTECT      = 1 <<  7;  //WP    Write Protect
  public static final int M6E_FSLW_TABLE_SEARCH       = 1 <<  6;  //TWE   Bus Error on Table Search
  public static final int M6E_FSLW_BUS_ERROR_ON_READ  = 1 <<  5;  //RE    Bus Error on Read
  public static final int M6E_FSLW_BUS_ERROR_ON_WRITE = 1 <<  4;  //WE    Bus Error on Write
  public static final int M6E_FSLW_TRANSPARENT        = 1 <<  3;  //TTR   TTR Hit
  public static final int M6E_FSLW_BRANCH_PREDICTION  = 1 <<  2;  //BPE   Branch Prediction Error
  public static final int M6E_FSLW_SOFTWARE_EMULATION = 1 <<  0;  //SEE   Software Emulation Error

  public static int m6eFSLW;

  //アドレスレジスタの増分
  //  実効アドレスの計算でポストインクリメントまたはプレデクリメントのとき、
  //  アドレスレジスタを更新してそのままにするとページフォルトを起こした命令を再実行することができない
  //  MOVE.L (A0)+,(d16,A0)などでデスティネーションの実効アドレスの計算にソースの結果を反映させる必要があるので、
  //  アドレスレジスタは更新しておいてページフォルトのときだけ命令開始時の値に巻き戻す
  //  CMPM.L (A0)+,(A1)+やSUBX.L -(A0),-(A1)などでは複数の増分を並べるかまたは積まなければならない
  //    m6eIncremented += (long) offset << (r << 3);
  //  で積むことにする
  //  巻き戻すとき負数に注意する
  public static long m6eIncremented;

  public static final String[] M6E_FSLW_TEXT_IOMA = {
    "IO=0,MA=0  First access of a misaligned transfer or only access of an aligned transfer",
    "IO=0,MA=1  Second or later access of a misaligned transfer",
    "IO=1,MA=0  Instruction opword fetch",
    "IO=1,MA=1  Fetch of an extension word",
  };
  public static final String[] M6E_FSLW_TEXT_LK = {
    "LK=0       Not locked",
    "LK=1       Locked",
  };
  public static final String[] M6E_FSLW_TEXT_RW = {
    "RW=0       Undefined, reserved",
    "RW=1       Write",
    "RW=2       Read",
    "RW=3       Read-Modify-Write",
  };
  public static final String[] M6E_FSLW_TEXT_SIZE = {
    "SIZE=0     Byte",
    "SIZE=1     Word",
    "SIZE=2     Long",
    "SIZE=3     Double precision or MOVE16",
  };
  public static final String[] M6E_FSLW_TEXT_TT = {
    "TT=0       Normal access",
    "TT=1       MOVE16 access",
    "TT=2       Alternate or debug access",
    "TT=3       Acknowledge or LPSTOP broadcast",
  };
  public static final String[] M6E_FSLW_TEXT_TM = {
    "TM=0       Data cache push access",
    "TM=1       User data or MOVE16 access",
    "TM=2       User code access",
    "TM=3       MMU table search data access",
    "TM=4       MMU table search code access",
    "TM=5       Supervisor data access",
    "TM=6       Supervisor code access",
    "TM=7       Reserved",
    //"TM=0       Logical function code 0",
    //"TM=1       Debug access",
    //"TM=2       Reserved",
    //"TM=3       Logical function code 3",
    //"TM=4       Logical function code 4",
    //"TM=5       Debug pipe control mode access",
    //"TM=6       Debug pipe control mode access",
    //"TM=7       Logical function code 7",
  };
  public static final String[] M6E_FSLW_TEXT_CAUSE = {
    "SEE=1      Software emulation error",  //0
    "",  //1
    "BPE=1      Branch prediction error",  //2
    "TTR=1      TTR hit",  //3
    "WE=1       Bus error on write",  //4
    "RE=1       Bus error on read",  //5
    "TWE=1      Bus error on table search",  //6
    "WP=1       Write protect",  //7
    "SP=1       Supervisor protect",  //8
    "PF=1       Page fault",  //9
    "IL=1       Indirect level fault",  //10
    "PTB=1      Pointer B fault",  //11
    "PTA=1      Pointer A fault",  //12
    "SBE=1      Store buffer bus error",  //13
    "PBE=1      Push buffer bus error",  //14
  };

  public static String m6eToString6 () {
    StringBuilder sb = new StringBuilder ();
    int supervisor = m6eFSLW & M6E_FSLW_TM_SUPERVISOR;
    int instruction = m6eFSLW & M6E_FSLW_TM_CODE;
    if (0 <= m6eNumber && m6eNumber < M6E_ERROR_NAME.length) {
      sb.append (M6E_ERROR_NAME[m6eNumber]);
    } else {
      sb.append ("undefined exception #").append (m6eNumber);
    }
    XEiJ.fmtHex8 (sb.append (" at PC=$"), XEiJ.regPC0).append ("($");
    int pa = MC68060.mmuTranslatePeek (XEiJ.regPC0, supervisor, 1);
    if ((XEiJ.regPC0 ^ pa) == 1) {
      sb.append ("????????");
    } else {
      XEiJ.fmtHex8 (sb, pa);
    }
    XEiJ.fmtHex4 (sb.append ("), SR=$"), XEiJ.regSRT1 | XEiJ.regSRS | XEiJ.regSRI | XEiJ.regCCR);
    //              111111111122222222223333333333444444444455555555556666
    //    0123456789012345678901234567890123456789012345678901234567890123
    if (0b0011011101000000000000000000000000000000000000000000000000000000L << m6eNumber < 0L) {  //FORMAT $2,$4
      if ((m6eFSLW & (M6E_FSLW_BUS_ERROR_ON_READ | M6E_FSLW_BUS_ERROR_ON_WRITE)) != 0) {  //バスエラーのとき。m6eAddressは物理アドレス
        XEiJ.fmtHex8 (sb.append ("\n  Fault or effective address is EA=($"), m6eAddress).append (')');
      } else {  //バスエラーでないとき。m6eAddressは論理アドレス
        XEiJ.fmtHex8 (sb.append ("\n  Fault or effective address is EA=$"), m6eAddress).append ("($");
        pa = MC68060.mmuTranslatePeek (m6eAddress, supervisor, instruction);
        if ((m6eAddress ^ pa) == 1) {
          sb.append ("????????");
        } else {
          XEiJ.fmtHex8 (sb, pa);
        }
        sb.append (')');
      }
    }
    if (m6eNumber == M6E_ACCESS_FAULT) {  //FORMAT $4
      XEiJ.fmtHex8 (sb.append ("\n  Fault status long word is FSLW=$"), m6eFSLW);
      sb.append ("\n  Fault was caused by:");
      for (int i = 14; i >= 0; i--) {
        if ((m6eFSLW & (1 << i)) != 0) {
          sb.append ("\n    ").append (M6E_FSLW_TEXT_CAUSE[i]);
        }
      }
      sb.append ("\n  Fault occured on:\n    ")
        .append (M6E_FSLW_TEXT_IOMA[(m6eFSLW & M6E_FSLW_INSTRUCTION) >>> 15 - 1 | (m6eFSLW & M6E_FSLW_MISALIGNED) >>> 27])
          .append ("\n    ").append (M6E_FSLW_TEXT_LK[(m6eFSLW & M6E_FSLW_LOCKED) >>> 25])
            .append ("\n    ").append (M6E_FSLW_TEXT_RW[(m6eFSLW & M6E_FSLW_READ_AND_WRITE) >>> 23])
              .append ("\n    ").append (M6E_FSLW_TEXT_SIZE[(m6eFSLW & M6E_FSLW_TRANSFER_SIZE) >>> 21])
                .append ("\n    ").append (M6E_FSLW_TEXT_TT[(m6eFSLW & M6E_FSLW_TRANSFER_TYPE) >>> 19])
                  .append ("\n    ").append (M6E_FSLW_TEXT_TM[(m6eFSLW & M6E_FSLW_TRANSFER_MODIFIER) >>> 16]);
    }
    return sb.toString ();
  }  //m6eToString6()

}  //class M68kException



