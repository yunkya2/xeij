//========================================================================================
//  SpriteScreen.java
//    en:Sprite screen
//    ja:スプライト画面
//  Copyright (C) 2003-2025 Makoto Kamada
//
//  This file is part of the XEiJ (X68000 Emulator in Java).
//  You can use, modify and redistribute the XEiJ if the conditions are met.
//  Read the XEiJ License for more details.
//  https://stdkmd.net/xeij/
//========================================================================================

package xeij;

import java.lang.*;  //Boolean,Character,Class,Comparable,Double,Exception,Float,IllegalArgumentException,Integer,Long,Math,Number,Object,Runnable,SecurityException,String,StringBuilder,System
import java.util.*;  //ArrayList,Arrays,Calendar,GregorianCalendar,HashMap,Map,Map.Entry,Timer,TimerTask,TreeMap

public class SpriteScreen {

  //レジスタ
  public static final int SPR_REG0_BG0_X       = 0x00eb0800;  //9-0 BG0スクロールX座標
  public static final int SPR_REG1_BG0_Y       = 0x00eb0802;  //9-0 BG0スクロールY座標
  public static final int SPR_REG2_BG1_X       = 0x00eb0804;  //9-0 BG1スクロールX座標
  public static final int SPR_REG3_BG1_Y       = 0x00eb0806;  //9-0 BG1スクロールY座標
  public static final int SPR_REG4_BG_CTRL     = 0x00eb0808;  //10  XPC1/PCS1
  //                                                            9   0=スプライト画面表示OFF,1=スプライト画面表示ON
  //                                                            5-4 BG1 00=BG1にTEXT0を割り当てる,01=BG1にTEXT1を割り当てる
  //                                                            3   BG1 0=BG1表示OFF,1=BG1表示ON
  //                                                            2-1 BG0 00=BG0にTEXT0を割り当てる,01=BG0にTEXT1を割り当てる
  //                                                            0   BG0 0=BG0表示OFF,1=BG0表示ON
  public static final int SPR_REG5_H_FRONT_END = 0x00eb080a;  //7-0 水平フロントポーチの終了キャラクタ位置
  public static final int SPR_REG6_H_BACK_END  = 0x00eb080c;  //5-0 水平バックポーチの終了キャラクタ位置
  public static final int SPR_REG7_V_BACK_END  = 0x00eb080e;  //7-0 垂直バックポーチの終了ラスタ
  public static final int SPR_REG8_RESO        = 0x00eb0810;  //4   スプライト画面解像度 0=低解像度,1=高解像度
  //                                                            3-2 スプライト画面垂直サイズ 00=256,01=512
  //                                                            1-0 スプライト画面水平サイズ
  //                                                                00=256(BGパターンは8x8,BG仮想画面は512x512)
  //                                                                01=512(BGパターンは16x16,BG仮想画面は1024x1024,BG0のみ)
  //以下は拡張。実機では使えない
  public static final int SPR_REG9_BANK_CONTROL = 0x00eb0812;  //2-0 バンク制御
  public static final int SPR_REG10_BANK_SELECT = 0x00eb0814;  //3-0 バンク選択

  //レジスタ
  //  ゼロ拡張
  public static int sprReg0Bg0XPort;
  public static int sprReg0Bg0XMask;
  public static int sprReg0Bg0XTest;
  public static int sprReg0Bg0XCurr;
  public static int sprReg1Bg0YPort;
  public static int sprReg1Bg0YMask;
  public static int sprReg1Bg0YTest;
  public static int sprReg1Bg0YCurr;
  public static int sprReg2Bg1XPort;
  public static int sprReg2Bg1XMask;
  public static int sprReg2Bg1XTest;
  public static int sprReg2Bg1XCurr;
  public static int sprReg3Bg1YPort;
  public static int sprReg3Bg1YMask;
  public static int sprReg3Bg1YTest;
  public static int sprReg3Bg1YCurr;
  public static int sprReg4BgCtrlPort;  //ポートの読み書きに使われる値
  public static int sprReg4BgCtrlMask;  //マスク。0=ポート,1=テスト
  public static int sprReg4BgCtrlTest;  //テストデータ
  public static int sprReg4BgCtrlCurr;  //使用されている値。sprReg4BgCtrlPort & ~sprReg4BgCtrlMask | sprReg4BgCtrlTest & sprReg4BgCtrlMask
  public static int sprReg5HFrontEndPort;
  public static int sprReg5HFrontEndMask;
  public static int sprReg5HFrontEndTest;
  public static int sprReg5HFrontEndCurr;
  public static int sprReg6HBackEndPort;
  public static int sprReg6HBackEndMask;
  public static int sprReg6HBackEndTest;
  public static int sprReg6HBackEndCurr;
  public static int sprReg7VBackEndPort;
  public static int sprReg7VBackEndMask;
  public static int sprReg7VBackEndTest;
  public static int sprReg7VBackEndCurr;
  public static int sprReg8ResoPort;  //ポートの読み書きに使われる値
  public static int sprReg8ResoMask;  //マスク。0=ポート,1=テスト
  public static int sprReg8ResoTest;  //テストデータ
  public static int sprReg8ResoCurr;  //使用されている値。sprReg8ResoPort & ~sprReg8ResoMask | sprReg8ResoTest & sprReg8ResoMask

  //スプライトスクロールレジスタ
  public static final int SPR_SHIFT = 10;  //7～/*11*/10
  public static final int SPR_COUNT = 1 << SPR_SHIFT;  //スプライトの枚数(欠番を含む)。128～/*2048*/1024
  public static final short[] sprX = new short[SPR_COUNT];  //x座標(0～1023)
  public static final short[] sprY = new short[SPR_COUNT];  //y座標(0～1023)
  public static final short[] sprNum = new short[SPR_COUNT];  //パターン番号(0～4095)
  public static final short[] sprColPort = new short[SPR_COUNT];  //パレットブロック(0～15)<<4
  public static final byte[] sprPrw = new byte[SPR_COUNT];  //プライオリティ(0～3)
  public static final boolean[] sprH = new boolean[SPR_COUNT];  //左右反転
  public static final boolean[] sprV = new boolean[SPR_COUNT];  //上下反転
  public static final int[] sprF = new int[SPR_COUNT];  //XPC1/PCS1

  //ラスタ毎にどのスプライトが含まれているかを示すテーブル
  //  1ラスタあたりSPR_COUNTビット
  //  プライオリティが0のスプライトは含まれない
  //  スプライト座標は1023までで縦16ビットなので1038まで1039ラスタ必要
  //  下からはみ出したスプライトが上から出てくるということはない
  //  [16]が画面上の最初のラスタになるので描画の際に注意すること
  public static final int[] sprRRmap = new int[1039 << (SPR_SHIFT - 5)];

  //パターン
  //  1要素に8ピクセル(4*8=32ビット)ずつ入れる
  //  上位が左側のピクセル
  public static final int[] sprPatPort = new int[32 * 4096];

  //パターン毎にどのスプライトで使用されているかを示すテーブル
  //  1パターンあたりSPR_COUNTビット
  //  プライオリティが0のスプライトは含まれない
  public static final int[] sprPPmap = new int[4096 << (SPR_SHIFT - 5)];

  //テキストエリア
  public static final short[] sprTNum = new short[4096 * 4];  //テキストエリア パターン番号<<3
  public static final short[] sprTColPort = new short[4096 * 4];  //テキストエリア パレットブロック<<4
  public static short[] sprTColCurr;
  public static final boolean[] sprTH = new boolean[4096 * 4];  //テキストエリア 左右反転
  public static final boolean[] sprTV = new boolean[4096 * 4];  //テキストエリア 上下反転。0=しない,15=する

  public static final boolean SPR_THREE_STEPS = true;
  public static int[] sprBuffer;  //表バッファ
  public static int[] sprShadowBuffer;  //裏バッファ
  //  reg4|=512のとき
  //    latched=true
  //  垂直映像期間の先頭
  //    active=latched
  //    (reg4&512)==0のとき
  //      latched=false
  //  activeのとき、そのフレームはスプライト画面が構築され、すべてのラスタが描画される
  public static boolean sprLatched;
  public static boolean sprActive;

  //パターンテスト
  public static final boolean SPR_PATTEST_ON = true;
  public static final int SPR_PATTEST_MARK = '\u02d9';  //上下左右の反転を示す印。'^'(U+005E;CIRCUMFLEX ACCENT),'~'(U+007E;TILDE),'¨'(U+00A8;DIAERESIS),'˙'(U+02D9;DOT ABOVE)
  public static final int[] sprPatTest = new int[32 * 4096];
  public static int[] sprPatCurr;
  public static final short[] sprColTest = new short[SPR_COUNT];  //パターンテスト用のパレットブロック(Sp)。(16～23)<<4
  public static final short[] sprTColTest = new short[4096 * 4];  //パターンテスト用のパレットブロック(T)。(24～27)<<4
  public static short[] sprColCurr;  //現在のパレットブロック(0～16)<<4

  //ラスタあたりのスプライトの枚数
  public static int sprSpritesPerRaster;  //32=標準

  //スプライトの枚数
  public static int sprNumberOfSpritesRequest;
  public static int sprNumberOfSprites;  //スプライトの枚数(欠番を含む)。128,256,512,1024/*,2048*/

  //4096個のパターン
  //
  //  テキストエリアの移動
  //    テキストエリアを$00EBC000～$00EBFFFFから$00EB4000～$00EB7FFFへ移動させて、テキストエリアを2面使っていてもパターンを256個定義できるようにします。
  //
  //  スプライトエリアとテキストエリアからのパターンの参照
  //    スプライトエリアとテキストエリアを以下のように変更することで、参照できるパターンの数を256個から1024個または4096個に増やします。
  //      スプライトエリア(256個のパターン)
  //        +0  ______XXXXXXXXXX  X:X座標
  //        +2  ______YYYYYYYYYY  Y:Y座標
  //        +4  VH__CCCCNNNNNNNN  V:上下 H:左右 C:パレットブロック N:パターン番号
  //        +6  ______________PP  P:プライオリティ
  //      スプライトエリア(1024個のパターン)
  //        +0  ______XXXXXXXXXX  X:X座標
  //        +2  ______YYYYYYYYYY  Y:Y座標
  //        +4  VHBBCCCCNNNNNNNN  V:上下 H:左右 B:バンク番号 C:パレットブロック N:パターン番号
  //        +6  ______________PP  P:プライオリティ
  //      スプライトエリア(4096個のパターン、反転なし)
  //        +0  ______XXXXXXXXXX  X:X座標
  //        +2  ______YYYYYYYYYY  Y:Y座標
  //        +4  BBBBCCCCNNNNNNNN  B:バンク番号 C:パレットブロック N:パターン番号
  //        +6  ______________PP  P:プライオリティ
  //      スプライトエリア(4096個のパターン、反転あり)
  //        +0  ______XXXXXXXXXX  X:X座標
  //        +2  ______YYYYYYYYYY  Y:Y座標
  //        +4  BBBBCCCCNNNNNNNN  B:バンク番号 C:パレットブロック N:パターン番号
  //        +6  VH____________PP  V:上下 H:左右 P:プライオリティ
  //      テキストエリア(256個のパターン)
  //            VH__CCCCNNNNNNNN  V:上下 H:左右 C:パレットブロック N:パターン番号
  //      テキストエリア(1024個のパターン)
  //            VHBBCCCCNNNNNNNN  V:上下 H:左右 B:バンク番号 C:パレットブロック N:パターン番号
  //      テキストエリア(4096個のパターン)
  //            BBBBCCCCNNNNNNNN  B:バンク番号 C:パレットブロック N:パターン番号
  //    4096個にしたとき上下左右の反転がなくなりますが、パターンを節約する必要がなければ、必要に応じて反転したパターンを定義すればよいと考えられます。
  //    反転の指示をバンク選択に置き換えることで、反転の結果を定義できるようになります。例えば、反転で済ませていたパターンの影の調整が、定義の処理の変更だけで行えます。
  //
  //  パターンエリアの拡張
  //    パターンエリア($00EB8000～$00EBFFFF)をバンク切り替えを用いて16倍に拡張することで、定義できるパターンの数を256個から4096個に増やします。
  //    バンク切り替えの弱点はランダムアクセスですが、1パターンが16または64ワードなので、書き込みが1パターンあたり1ワード増えたとしても影響は限定的と考えられます。
  //
  //  レジスタの追加
  //    バンク制御レジスタ($00EB0812)とバンク選択レジスタ($00EB0814)を追加します。
  //      バンク制御レジスタ($00EB0812)
  //            _____________MMT  M:モード T:移動
  //            モード  パターンの数  スプライトの反転  テキストの反転
  //               0         256            あり             あり
  //               1        1024            あり             あり
  //               2        4096            なし             なし
  //               3        4096            あり             なし
  //            移動  テキストエリアの移動
  //              0          しない
  //              1           する
  //      バンク選択レジスタ($00EB0814)
  //            ____BBBB________  B:バンク番号
  //    0～4095のパターン番号をシフトせずにバンク選択レジスタへ書き込めます。
  //    後のプログラムが誤動作しないように、どちらも使い終わったら0に戻してください。
  //
  //  疑似グラフィック画面
  //    バックグラウンドに4096個のパターンを1個ずつ敷き詰めることで、3枚目の1024x1024ドット16色のグラフィック画面として使うことができます。
  //
  //  テキストエリアに関する補足
  //    移動前のテキストエリアと、パターンエリアのバンク0の後半は、アドレスが同じですが実体が違います。
  //    移動前のテキストエリアへ書き込んだデータは、テキストエリアと、バンク0の後半の両方へ書き込まれます。
  //    移動前のテキストエリアから読み出したデータは、バンク0の後半から読み出されます。
  //    移動後のテキストエリアへ書き込んだデータは、バンク0の後半へ書き込まれていないので、移動前のテキストエリアから読み出せません。
  //    バンク1以上を選択すると、移動前のテキストエリアは見えなくなります。
  //
  //  その他
  //    標準のIOCSコールは4096個のパターンに対応していません。
  //
  public static boolean sprBankOnRequest;
  public static boolean sprBankOn;  //true=4096個のパターンが有効
  public static int sprBankMode;  //モード。0=256個,1=1024個,2=4096個反転なし,3=4096個反転あり
  public static boolean sprBankShifted;  //true=移動あり
  public static int sprBankNumber;  //バンク番号<<8

  //768x512でスプライトを表示
  //  CRTCのR20の下位5ビットが%1xx1xのときスプライト画面を表示できないという制限を解除します。
  //  CRTCのR20のビット4,1,0はドットクロック(オシレータと分周比)を選択します。%1xx1xはドットクロックが25MHz以上で、標準の画面モードではCRTMOD 16～19の768x512、1024x424、1024x848、640x480が該当します。
  //  この制限は強く、768x512でスプライト画面を表示したくてもスプライトエリア、パターンエリア、テキストエリアにアクセスしただけでバスエラーが発生してしまい、取り付く島もありません。
  //  この制限を解除することで、768x512のときもスプライト画面を表示できるようになります。
  //  (もちろん、描画バッファの幅が512ドット分しかなければバッファの幅を広げる作業も必要になるでしょう)
  //
  //  IOCS _SP_INITはスプライト画面を表示できないとき-1を返すことになっていますが、標準のIOCS _SP_INITにはCRTCのR20の下位5ビットが%10110のときだけスプライト画面を表示できないと判断するというバグがあり、1024x848、640x480のときIOCS _SP_INITを使うとアクセスできないスプライトスクロールレジスタを初期化しようとしてバスエラーが発生します。このバグはIPLROM 1.6で修正されています。
  //
  public static boolean spr768x512Request;
  public static boolean spr768x512;  //true=制限を解除する
  public static boolean sprAccessible;  //true=スプライト画面を表示できる(CRTCのR20の下位5ビットが%1xx1xでないまたは制限が解除されている)

  //512x512でBG1を表示
  //  512x512のときはバックグラウンドを1面しか表示できないという制限を解除します。
  //  256x256のときと同様に512x512のときもバックグラウンドを2面表示できるようになります。
  public static boolean spr512bg1Request;
  public static boolean spr512bg1;  //true=制限を解除する

  //ウェイト
  public static final long SPR_WAIT_PATTERN_DISP_0 = XEiJ.TMR_FREQ * 215L / 1000000000L;
  public static final long SPR_WAIT_SPRITE_DISP_0 = XEiJ.TMR_FREQ * 275L / 1000000000L;
  public static final long SPR_WAIT_SPRITE_DISP_1 = XEiJ.TMR_FREQ * 400L / 1000000000L;
  public static final long SPR_WAIT_PATTERN_DISP_1 = XEiJ.TMR_FREQ * 465L / 1000000000L;
  public static long sprWaitSprite;  //スプライトのウェイト
  public static long sprWaitPattern;  //パターンのウェイト

  //sprInit ()
  //  スプライト画面を初期化する
  public static void sprInit () {
    sprReg0Bg0XPort = 0;
    sprReg0Bg0XMask = 0;
    sprReg0Bg0XTest = 0;
    sprReg0Bg0XCurr = 0;
    sprReg1Bg0YPort = 0;
    sprReg1Bg0YMask = 0;
    sprReg1Bg0YTest = 0;
    sprReg1Bg0YCurr = 0;
    sprReg2Bg1XPort = 0;
    sprReg2Bg1XMask = 0;
    sprReg2Bg1XTest = 0;
    sprReg2Bg1XCurr = 0;
    sprReg3Bg1YPort = 0;
    sprReg3Bg1YMask = 0;
    sprReg3Bg1YTest = 0;
    sprReg3Bg1YCurr = 0;
    sprReg4BgCtrlPort = 0;
    sprReg4BgCtrlMask = 0;
    sprReg4BgCtrlTest = 0;
    sprReg4BgCtrlCurr = 0;
    sprReg5HFrontEndPort = 0;
    sprReg5HFrontEndMask = 0;
    sprReg5HFrontEndTest = 0;
    sprReg5HFrontEndCurr = 0;
    sprReg6HBackEndPort = 0;
    sprReg6HBackEndMask = 0;
    sprReg6HBackEndTest = 0;
    sprReg6HBackEndCurr = 0;
    sprReg7VBackEndPort = 0;
    sprReg7VBackEndMask = 0;
    sprReg7VBackEndTest = 0;
    sprReg7VBackEndCurr = 0;
    sprReg8ResoPort = 0;
    sprReg8ResoMask = 0;
    sprReg8ResoTest = 0;
    sprReg8ResoCurr = 0;
    //sprX = new short[SPR_COUNT];
    //sprY = new short[SPR_COUNT];
    //sprNum = new short[SPR_COUNT];
    //sprColPort = new short[SPR_COUNT];
    //sprPrw = new byte[SPR_COUNT];
    //sprH = new boolean[SPR_COUNT];
    //sprV = new boolean[SPR_COUNT];
    //sprF = new int[SPR_COUNT];
    //sprRRmap = new int[1039 << (SPR_SHIFT - 5)];
    //sprPPmap = new int[4096 << (SPR_SHIFT - 5)];
    //sprTNum = new short[4096 * 4];
    //sprTColPort = new short[4096 * 4];
    //sprTH = new boolean[4096 * 4];
    //sprTV = new boolean[4096 * 4];

    if (SPR_THREE_STEPS) {
      sprBuffer = new int[1056 * 3];
      sprShadowBuffer = new int[1056 * 3];
    }

    //sprPatPort = new int[32 * 4096];
    //パターンテスト
    if (SPR_PATTEST_ON) {
      //スプライトパターン
      //sprPatTest = new int[32 * 4096];
      Arrays.fill (sprPatTest, 0x00000000);
      //  BGに0番が並んでいるときBGが手前にあるとスプライトが見えにくくなるので0番は上下左右の反転を示す印だけにする
      if (SPR_PATTEST_MARK == '^') {
        sprPatTest[ 5] = 0x01000000;
        sprPatTest[ 6] = 0x10100000;
        sprPatTest[13] = 0x02000000;
        sprPatTest[14] = 0x20200000;
        sprPatTest[21] = 0x03000000;
        sprPatTest[22] = 0x30300000;
        sprPatTest[29] = 0x04000000;
        sprPatTest[30] = 0x40400000;
      } else if (SPR_PATTEST_MARK == '~') {
        sprPatTest[ 6] = 0x11100000;
        sprPatTest[14] = 0x22200000;
        sprPatTest[22] = 0x33300000;
        sprPatTest[30] = 0x44400000;
      } else if (SPR_PATTEST_MARK == '¨') {
        sprPatTest[ 6] = 0x10100000;
        sprPatTest[14] = 0x20200000;
        sprPatTest[22] = 0x30300000;
        sprPatTest[30] = 0x40400000;
      } else if (SPR_PATTEST_MARK == '˙') {
        sprPatTest[ 6] = 0x01000000;
        sprPatTest[14] = 0x02000000;
        sprPatTest[22] = 0x03000000;
        sprPatTest[30] = 0x04000000;
      }
      for (int i = 32; i < (32 * 4096); i += 32) {
        int x1 = i >> 9 & 15;  //上位4bit
        int x0 = i >> 5 & 15;  //下位4bit
        x1 = Indicator.IND_ASCII_3X5[(9 - x1 >> 4 & 7 | 48) + x1];  //上位3x5dot
        x0 = Indicator.IND_ASCII_3X5[(9 - x0 >> 4 & 7 | 48) + x0];  //下位3x5dot
        int p0 = VideoController.VCN_TXP0[x1 >> 12 - 5 & 0b11100000 | x0 >> 12 - 1 & 0b00001110];
        int p1 = VideoController.VCN_TXP0[x1 >>  9 - 5 & 0b11100000 | x0 >>  9 - 1 & 0b00001110];
        int p2 = VideoController.VCN_TXP0[x1 >>  6 - 5 & 0b11100000 | x0 >>  6 - 1 & 0b00001110];
        int p3 = VideoController.VCN_TXP0[x1 <<  5 - 3 & 0b11100000 | x0 >>  3 - 1 & 0b00001110];
        int p4 = VideoController.VCN_TXP0[x1 <<  5 - 0 & 0b11100000 | x0 <<  1 - 0 & 0b00001110];
        //左上
        sprPatTest[i     ] = p0;
        sprPatTest[i +  1] = p1;
        sprPatTest[i +  2] = p2;
        sprPatTest[i +  3] = p3;
        sprPatTest[i +  4] = p4;
        //左下
        sprPatTest[i +  8] = p0 << 1;
        sprPatTest[i +  9] = p1 << 1;
        sprPatTest[i + 10] = p2 << 1;
        sprPatTest[i + 11] = p3 << 1;
        sprPatTest[i + 12] = p4 << 1;
        //右上
        sprPatTest[i + 16] = p0 * 3;
        sprPatTest[i + 17] = p1 * 3;
        sprPatTest[i + 18] = p2 * 3;
        sprPatTest[i + 19] = p3 * 3;
        sprPatTest[i + 20] = p4 * 3;
        //右下
        sprPatTest[i + 24] = p0 << 2;
        sprPatTest[i + 25] = p1 << 2;
        sprPatTest[i + 26] = p2 << 2;
        sprPatTest[i + 27] = p3 << 2;
        sprPatTest[i + 28] = p4 << 2;
        //上下左右の反転を示す印
        if (SPR_PATTEST_MARK == '^') {
          sprPatTest[i +  5] = 0x01000000;
          sprPatTest[i +  6] = 0x10100000;
          sprPatTest[i + 13] = 0x02000000;
          sprPatTest[i + 14] = 0x20200000;
          sprPatTest[i + 21] = 0x03000000;
          sprPatTest[i + 22] = 0x30300000;
          sprPatTest[i + 29] = 0x04000000;
          sprPatTest[i + 30] = 0x40400000;
        } else if (SPR_PATTEST_MARK == '~') {
          sprPatTest[i +  6] = 0x11100000;
          sprPatTest[i + 14] = 0x22200000;
          sprPatTest[i + 22] = 0x33300000;
          sprPatTest[i + 30] = 0x44400000;
        } else if (SPR_PATTEST_MARK == '¨') {
          sprPatTest[i +  6] = 0x10100000;
          sprPatTest[i + 14] = 0x20200000;
          sprPatTest[i + 22] = 0x30300000;
          sprPatTest[i + 30] = 0x40400000;
        } else if (SPR_PATTEST_MARK == '˙') {
          sprPatTest[i +  6] = 0x01000000;
          sprPatTest[i + 14] = 0x02000000;
          sprPatTest[i + 22] = 0x03000000;
          sprPatTest[i + 30] = 0x04000000;
        }
      }
      //パレットブロック
      //sprColTest = new short[SPR_COUNT];
      //sprTColTest = new short[4096 * 4];
      for (int i = 0; i < SPR_COUNT; i++) {
        sprColTest[i] = (short) ((16 + ((i & 255) * (VideoController.VCN_PATTEST_BLOCKS - 4) >> 8)) << 4);  //0..255 -> 0..VideoController.VCN_PATTEST_BLOCKS-5
      }
      for (int i = 0; i < 4; i++) {
        Arrays.fill (sprTColTest, i << 12, (i + 1) << 12,
                     (short) ((16 + VideoController.VCN_PATTEST_BLOCKS - 4 + i) << 4));
      }
    }  //if SPR_PATTEST_ON
    sprPatCurr = sprPatPort;
    sprColCurr = sprColPort;
    sprTColCurr = sprTColPort;

    //ラスタあたりのスプライトの枚数
    sprSpritesPerRaster = Math.max (0, Math.min (/*2040*/1016, Settings.sgsGetInt ("sprras")));

    //スプライトの枚数
    {
      int n = Settings.sgsGetInt ("numspr");
      n = (n == 128 || n == 256 ? n :
           n == 504 || n == 1016 /*|| n == 2040 */? n + 8 :
           128);
      if (n == 128 && Settings.sgsGetOnOff ("dblspr")) {
        n = 256;
      }
      sprNumberOfSpritesRequest = n;
    }

    //4096個のパターン
    sprBankOnRequest = Settings.sgsGetOnOff ("sprbank");

    //768x512でスプライトを表示
    spr768x512Request = Settings.sgsGetOnOff ("spr768x512");

    //512x512でBG1を表示
    spr512bg1Request = Settings.sgsGetOnOff ("spr512bg1");

    //ウェイト
    sprWaitSprite = SPR_WAIT_SPRITE_DISP_0;
    sprWaitPattern = SPR_WAIT_PATTERN_DISP_0;

    sprReset ();
  }  //sprInit()

  public static void sprTini () {
    //ラスタあたりのスプライトの枚数
    Settings.sgsPutInt ("sprras", sprSpritesPerRaster);
    //スプライトの枚数
    Settings.sgsPutOnOff ("dblspr", false);
    Settings.sgsPutInt ("numspr", sprNumberOfSpritesRequest <= 256 ? sprNumberOfSpritesRequest : sprNumberOfSpritesRequest - 8);
    //4096個のパターン
    Settings.sgsPutOnOff ("sprbank", sprBankOnRequest);
    //768x512でスプライトを表示
    Settings.sgsPutOnOff ("spr768x512", spr768x512Request);
    //512x512でBG1を表示
    Settings.sgsPutOnOff ("spr512bg1", spr512bg1Request);
  }

  //sprReset ()
  //  リセット
  public static void sprReset () {
    //スプライトの枚数
    sprNumberOfSprites = sprNumberOfSpritesRequest;
    //4096個のパターン
    sprBankOn = sprBankOnRequest;
    sprBankMode = 0;
    sprBankShifted = false;
    sprBankNumber = (0 << 8);
    //768x512でスプライトを表示
    spr768x512 = spr768x512Request;
    sprAccessible = spr768x512;
    //512x512でBG1を表示
    spr512bg1 = spr512bg1Request;

    Arrays.fill (sprX, (short) 0);
    Arrays.fill (sprY, (short) 0);
    Arrays.fill (sprNum, (short) 0);
    Arrays.fill (sprColPort, (short) 0);
    Arrays.fill (sprPrw, (byte) 0);
    Arrays.fill (sprH, false);
    Arrays.fill (sprV, false);
    Arrays.fill (sprF, 0);
    Arrays.fill (sprRRmap, 0);
    Arrays.fill (sprPatPort, 0);
    Arrays.fill (sprPPmap, 0);
    Arrays.fill (sprTNum, (short) 0);
    Arrays.fill (sprTColPort, (short) 0);
    Arrays.fill (sprTH, false);
    Arrays.fill (sprTV, false);
  }  //sprReset()


  //
  //  ノーマル
  //    ラスタ(dst=-2,src=-2)
  //      表(0)にスプライト(0)を並べる
  //      表(0)と裏(-1)を入れ換える
  //    ラスタ(dst=-1,src=-1)
  //      表(-1)を表(1)として再利用する
  //      表(1)にスプライト(1)を並べる
  //      表(1)と裏(0)を入れ換える
  //      表(0)にバックグラウンド(0)を並べる
  //    ラスタ(dst=src)
  //      表(dst)のスプライト(src)とバックグラウンド(src)を重ねる
  //      表(dst)を描画する
  //      表(dst)を表(dst+2)として再利用する
  //      表(dst+2)にスプライト(src+2)を並べる
  //      表(dst+2)と裏(dst+1)を入れ換える
  //      表(dst+1)にバックグラウンド(src+1)を並べる
  //
  //  ラスタ2度読み
  //    偶数ラスタ(dst=-2,src=-1)
  //      表(0)にスプライト(0)を並べる
  //      表(0)と裏(-1)を入れ換える
  //    奇数ラスタ(dst=-1,src=-1)
  //      表(-1)を表(1)として再利用する
  //      表(1)にスプライト(0)を並べる
  //      表(1)と裏(0)を入れ換える
  //      表(0)にバックグラウンド(0)を並べる
  //    偶数ラスタ(dst=src*2)
  //      表(dst)のスプライト(src)とバックグラウンド(src)を重ねる
  //      表(dst)を描画する
  //      表(dst)を表(dst+2)として再利用する
  //      表(dst+2)にスプライト(src+1)を並べる
  //      表(dst+2)と裏(dst+1)を入れ換える
  //      表(dst+1)にバックグラウンド(src)を並べる
  //    奇数ラスタ(dst=src*2+1)
  //      表(dst)のスプライト(src)とバックグラウンド(src)を重ねる
  //      表(dst)を描画する
  //      表(dst)を表(dst+2)として再利用する
  //      表(dst+2)にスプライト(src+1)を並べる
  //      表(dst+2)と裏(dst+1)を入れ換える
  //      表(dst+1)にバックグラウンド(src+1)を並べる
  //
  //  インタレース
  //    ラスタ(dst=-4,src=-4)
  //      表(0)にスプライト(0)を並べる
  //      表(0)と裏(-2)を入れ換える
  //    ラスタ(dst=-2,src=-2)
  //      表(-2)を表(2)として再利用する
  //      表(2)にスプライト(2)を並べる
  //      表(2)と裏(0)を入れ換える
  //      表(0)にバックグラウンド(0)を並べる
  //    ラスタ(dst=src)
  //      表(dst)のスプライト(src)とバックグラウンド(src)を重ねる
  //      表(dst)を描画する
  //      表(dst)を表(dst+4)として再利用する
  //      表(dst+4)にスプライト(src+4)を並べる
  //      表(dst+4)と裏(dst+2)を入れ換える
  //      表(dst+2)にバックグラウンド(src+2)を並べる
  //
  //  スリット
  //    ラスタ(dst=-4,src=-2)
  //      表(0)にスプライト(0)を並べる
  //      表(0)と裏(-2)を入れ換える
  //    ラスタ(dst=-2,src=-1)
  //      表(-2)を表(2)として再利用する
  //      表(2)にスプライト(1)を並べる
  //      表(2)と裏(0)を入れ換える
  //      表(0)にバックグラウンド(0)を並べる
  //    ラスタ(dst=src*2)
  //      表(dst)のスプライト(src)とバックグラウンド(src)を重ねる
  //      表(dst)を描画する
  //      表(dst)を表(dst+4)として再利用する
  //      表(dst+4)にスプライト(src+2)を並べる
  //      表(dst+4)と裏(dst+2)を入れ換える
  //      表(dst+2)にバックグラウンド(src+1)を並べる
  //

  //sprSwap ()
  //  表と裏を入れ換える
  //
  //!!! if (SPR_THREE_STEPS)
  public static void sprSwap () {
    int[] t = sprBuffer;
    sprBuffer = sprShadowBuffer;
    sprShadowBuffer = t;
  }  //sprSwap()

  //sprStep1 (src)
  //  スプライトを並べる
  //
  //  sprBuffer[2112 + x]
  //    4bitパレット
  //             28  24  20  16  12   8   4   0
  //    手前← |---|SP3|BG0|SP2|BG1|SP1|---|---| →奥
  //
  //  sprBuffer[1056 + x]
  //    パレットブロック
  //             28  24  20  16  12   8   4   0
  //    手前← |---|SP3|BG0|SP2|BG1|SP1|---|---| →奥
  //
  //!!! if (SPR_THREE_STEPS)
  public static void sprStep1 (int src) {
    //バッファをクリアする
    //  4bitパレットとパレットブロックの両方をクリアすること
    Arrays.fill (sprBuffer, 0);
    //垂直映像開始位置の指定に伴う補正
    src += sprReg7VBackEndCurr - CRTC.crtR06VBackEndCurr;
    if (src < 0 || 1023 < src) {
      return;
    }
    //水平映像開始位置の指定に伴う補正
    int hStart = (sprReg6HBackEndCurr - CRTC.crtR02HBackEndCurr - 4) << 3;
    int width16 = 16 + XEiJ.pnlScreenWidth;
    //ラスタにかかっているスプライトの数
    int cnt = sprSpritesPerRaster;  //1ラスタあたりのスプライト数-ラスタにかかっているスプライトの数
    if (cnt == 0) {
      return;
    }
    for (int i = (16 + src) << (SPR_SHIFT - 5), nn = 0; nn < sprNumberOfSprites; nn += 32) {
      for (int map = sprRRmap[i++], n = nn; map != 0; map <<= 1, n++) {  //nは昇順
        if (0 <= map) {  //このスプライトはラスタにかかっていない
          continue;
        }
        int x = hStart + sprX[n];  //X座標。画面左端は16
        if (x <= 0 || width16 <= x) {  //画面外
          //画面外のスプライトは水平表示限界に影響する。X68030実機で確認
          if (--cnt == 0) {  //今回のスプライトで終わりにする
            return;
          }
          continue;
        }
        //  8x8のパターンを
        //    +---+---+
        //    | 0 | 2 |
        //    +---+---+
        //    | 1 | 3 |
        //    +---+---+
        //  の順序で並べる
        int a = (sprNum[n] << 5) + (sprV[n] ? sprY[n] - src - 1 : 16 + src - sprY[n]);
        int prw = sprPrw[n] << 3;  //プライオリティ*8。表示されていることがわかっているのでプライオリティは1～3のいずれかであるはず
        int col = sprColCurr[n] << prw >>> 4;  //パレットブロック
        int f = sprF[n];  //XPC1/PCS1
        int s, t;
        if ((t = f | sprPatCurr[a]) != 0) {  //左半分のパターンあり
          if (sprH[n]) {  //左右反転あり。左半分→右半分
            if ((s = 15       & t) != 0 && sprBuffer[2112 +  8 + x] >>> prw == 0) {  //ドットがありかつ若い番号のスプライトよりも優先順位が高い
              sprBuffer[2112 +  8 + x] = s        << prw;
              sprBuffer[1056 +  8 + x] = col;
            }
            if ((s = 15 <<  4 & t) != 0 && sprBuffer[2112 +  9 + x] >>> prw == 0) {  //ドットがありかつ若い番号のスプライトよりも優先順位が高い
              sprBuffer[2112 +  9 + x] = s >>>  4 << prw;
              sprBuffer[1056 +  9 + x] = col;
            }
            if ((s = 15 <<  8 & t) != 0 && sprBuffer[2112 + 10 + x] >>> prw == 0) {  //ドットがありかつ若い番号のスプライトよりも優先順位が高い
              sprBuffer[2112 + 10 + x] = s >>>  8 << prw;
              sprBuffer[1056 + 10 + x] = col;
            }
            if ((s = 15 << 12 & t) != 0 && sprBuffer[2112 + 11 + x] >>> prw == 0) {  //ドットがありかつ若い番号のスプライトよりも優先順位が高い
              sprBuffer[2112 + 11 + x] = s >>> 12 << prw;
              sprBuffer[1056 + 11 + x] = col;
            }
            if ((s = 15 << 16 & t) != 0 && sprBuffer[2112 + 12 + x] >>> prw == 0) {  //ドットがありかつ若い番号のスプライトよりも優先順位が高い
              sprBuffer[2112 + 12 + x] = s >>> 16 << prw;
              sprBuffer[1056 + 12 + x] = col;
            }
            if ((s = 15 << 20 & t) != 0 && sprBuffer[2112 + 13 + x] >>> prw == 0) {  //ドットがありかつ若い番号のスプライトよりも優先順位が高い
              sprBuffer[2112 + 13 + x] = s >>> 20 << prw;
              sprBuffer[1056 + 13 + x] = col;
            }
            if ((s = 15 << 24 & t) != 0 && sprBuffer[2112 + 14 + x] >>> prw == 0) {  //ドットがありかつ若い番号のスプライトよりも優先順位が高い
              sprBuffer[2112 + 14 + x] = s >>> 24 << prw;
              sprBuffer[1056 + 14 + x] = col;
            }
            if ((s = t >>> 28    ) != 0 && sprBuffer[2112 + 15 + x] >>> prw == 0) {  //ドットがありかつ若い番号のスプライトよりも優先順位が高い
              sprBuffer[2112 + 15 + x] = s        << prw;
              sprBuffer[1056 + 15 + x] = col;
            }
          } else {  //左右反転なし。左半分→左半分
            if ((s = t >>> 28    ) != 0 && sprBuffer[2112 +      x] >>> prw == 0) {  //ドットがありかつ若い番号のスプライトよりも優先順位が高い
              sprBuffer[2112 +      x] = s        << prw;
              sprBuffer[1056 +      x] = col;
            }
            if ((s = 15 << 24 & t) != 0 && sprBuffer[2112 +  1 + x] >>> prw == 0) {  //ドットがありかつ若い番号のスプライトよりも優先順位が高い
              sprBuffer[2112 +  1 + x] = s >>> 24 << prw;
              sprBuffer[1056 +  1 + x] = col;
            }
            if ((s = 15 << 20 & t) != 0 && sprBuffer[2112 +  2 + x] >>> prw == 0) {  //ドットがありかつ若い番号のスプライトよりも優先順位が高い
              sprBuffer[2112 +  2 + x] = s >>> 20 << prw;
              sprBuffer[1056 +  2 + x] = col;
            }
            if ((s = 15 << 16 & t) != 0 && sprBuffer[2112 +  3 + x] >>> prw == 0) {  //ドットがありかつ若い番号のスプライトよりも優先順位が高い
              sprBuffer[2112 +  3 + x] = s >>> 16 << prw;
              sprBuffer[1056 +  3 + x] = col;
            }
            if ((s = 15 << 12 & t) != 0 && sprBuffer[2112 +  4 + x] >>> prw == 0) {  //ドットがありかつ若い番号のスプライトよりも優先順位が高い
              sprBuffer[2112 +  4 + x] = s >>> 12 << prw;
              sprBuffer[1056 +  4 + x] = col;
            }
            if ((s = 15 <<  8 & t) != 0 && sprBuffer[2112 +  5 + x] >>> prw == 0) {  //ドットがありかつ若い番号のスプライトよりも優先順位が高い
              sprBuffer[2112 +  5 + x] = s >>>  8 << prw;
              sprBuffer[1056 +  5 + x] = col;
            }
            if ((s = 15 <<  4 & t) != 0 && sprBuffer[2112 +  6 + x] >>> prw == 0) {  //ドットがありかつ若い番号のスプライトよりも優先順位が高い
              sprBuffer[2112 +  6 + x] = s >>>  4 << prw;
              sprBuffer[1056 +  6 + x] = col;
            }
            if ((s = 15       & t) != 0 && sprBuffer[2112 +  7 + x] >>> prw == 0) {  //ドットがありかつ若い番号のスプライトよりも優先順位が高い
              sprBuffer[2112 +  7 + x] = s        << prw;
              sprBuffer[1056 +  7 + x] = col;
            }
          }  //if 左右反転あり/左右反転なし
        }  //if 左半分のパターンあり
        if ((t = f | sprPatCurr[16 + a]) != 0) {  //右半分のパターンあり
          if (sprH[n]) {  //左右反転あり。右半分→左半分
            if ((s = 15       & t) != 0 && sprBuffer[2112 +      x] >>> prw == 0) {  //ドットがありかつ若い番号のスプライトよりも優先順位が高い
              sprBuffer[2112 +      x] = s        << prw;
              sprBuffer[1056 +      x] = col;
            }
            if ((s = 15 <<  4 & t) != 0 && sprBuffer[2112 +  1 + x] >>> prw == 0) {  //ドットがありかつ若い番号のスプライトよりも優先順位が高い
              sprBuffer[2112 +  1 + x] = s >>>  4 << prw;
              sprBuffer[1056 +  1 + x] = col;
            }
            if ((s = 15 <<  8 & t) != 0 && sprBuffer[2112 +  2 + x] >>> prw == 0) {  //ドットがありかつ若い番号のスプライトよりも優先順位が高い
              sprBuffer[2112 +  2 + x] = s >>>  8 << prw;
              sprBuffer[1056 +  2 + x] = col;
            }
            if ((s = 15 << 12 & t) != 0 && sprBuffer[2112 +  3 + x] >>> prw == 0) {  //ドットがありかつ若い番号のスプライトよりも優先順位が高い
              sprBuffer[2112 +  3 + x] = s >>> 12 << prw;
              sprBuffer[1056 +  3 + x] = col;
            }
            if ((s = 15 << 16 & t) != 0 && sprBuffer[2112 +  4 + x] >>> prw == 0) {  //ドットがありかつ若い番号のスプライトよりも優先順位が高い
              sprBuffer[2112 +  4 + x] = s >>> 16 << prw;
              sprBuffer[1056 +  4 + x] = col;
            }
            if ((s = 15 << 20 & t) != 0 && sprBuffer[2112 +  5 + x] >>> prw == 0) {  //ドットがありかつ若い番号のスプライトよりも優先順位が高い
              sprBuffer[2112 +  5 + x] = s >>> 20 << prw;
              sprBuffer[1056 +  5 + x] = col;
            }
            if ((s = 15 << 24 & t) != 0 && sprBuffer[2112 +  6 + x] >>> prw == 0) {  //ドットがありかつ若い番号のスプライトよりも優先順位が高い
              sprBuffer[2112 +  6 + x] = s >>> 24 << prw;
              sprBuffer[1056 +  6 + x] = col;
            }
            if ((s = t >>> 28    ) != 0 && sprBuffer[2112 +  7 + x] >>> prw == 0) {  //ドットがありかつ若い番号のスプライトよりも優先順位が高い
              sprBuffer[2112 +  7 + x] = s        << prw;
              sprBuffer[1056 +  7 + x] = col;
            }
          } else {  //左右反転なし。右半分→右半分
            if ((s = t >>> 28    ) != 0 && sprBuffer[2112 +  8 + x] >>> prw == 0) {  //ドットがありかつ若い番号のスプライトよりも優先順位が高い
              sprBuffer[2112 +  8 + x] = s        << prw;
              sprBuffer[1056 +  8 + x] = col;
            }
            if ((s = 15 << 24 & t) != 0 && sprBuffer[2112 +  9 + x] >>> prw == 0) {  //ドットがありかつ若い番号のスプライトよりも優先順位が高い
              sprBuffer[2112 +  9 + x] = s >>> 24 << prw;
              sprBuffer[1056 +  9 + x] = col;
            }
            if ((s = 15 << 20 & t) != 0 && sprBuffer[2112 + 10 + x] >>> prw == 0) {  //ドットがありかつ若い番号のスプライトよりも優先順位が高い
              sprBuffer[2112 + 10 + x] = s >>> 20 << prw;
              sprBuffer[1056 + 10 + x] = col;
            }
            if ((s = 15 << 16 & t) != 0 && sprBuffer[2112 + 11 + x] >>> prw == 0) {  //ドットがありかつ若い番号のスプライトよりも優先順位が高い
              sprBuffer[2112 + 11 + x] = s >>> 16 << prw;
              sprBuffer[1056 + 11 + x] = col;
            }
            if ((s = 15 << 12 & t) != 0 && sprBuffer[2112 + 12 + x] >>> prw == 0) {  //ドットがありかつ若い番号のスプライトよりも優先順位が高い
              sprBuffer[2112 + 12 + x] = s >>> 12 << prw;
              sprBuffer[1056 + 12 + x] = col;
            }
            if ((s = 15 <<  8 & t) != 0 && sprBuffer[2112 + 13 + x] >>> prw == 0) {  //ドットがありかつ若い番号のスプライトよりも優先順位が高い
              sprBuffer[2112 + 13 + x] = s >>>  8 << prw;
              sprBuffer[1056 + 13 + x] = col;
            }
            if ((s = 15 <<  4 & t) != 0 && sprBuffer[2112 + 14 + x] >>> prw == 0) {  //ドットがありかつ若い番号のスプライトよりも優先順位が高い
              sprBuffer[2112 + 14 + x] = s >>>  4 << prw;
              sprBuffer[1056 + 14 + x] = col;
            }
            if ((s = 15       & t) != 0 && sprBuffer[2112 + 15 + x] >>> prw == 0) {  //ドットがありかつ若い番号のスプライトよりも優先順位が高い
              sprBuffer[2112 + 15 + x] = s        << prw;
              sprBuffer[1056 + 15 + x] = col;
            }
          }  //if 左右反転あり/左右反転なし
        }  //if 右半分のパターンあり
        if (--cnt == 0) {  //今回のスプライトで終わりにする
          return;
        }
      }  //for map,n
    }  // for i,nn
  }  //sprStep1(int)

  //sprStep2 (src)
  //  バックグラウンドを並べる
  //
  //  sprBuffer[2112 + x]
  //    4bitパレット
  //             28  24  20  16  12   8   4   0
  //    手前← |---|SP3|BG0|SP2|BG1|SP1|---|---| →奥
  //
  //  sprBuffer[1056 + x]
  //    パレットブロック
  //             28  24  20  16  12   8   4   0
  //    手前← |---|SP3|BG0|SP2|BG1|SP1|---|---| →奥
  //
  //!!! if (SPR_THREE_STEPS)
  public static void sprStep2 (int src) {
    //垂直映像開始位置の指定に伴う補正
    src += sprReg7VBackEndCurr - CRTC.crtR06VBackEndCurr;
    if (src < 0 || 1023 < src) {
      return;
    }
    //水平映像開始位置の指定に伴う補正
    int hStart = (sprReg6HBackEndCurr - CRTC.crtR02HBackEndCurr - 4) << 3;
    int width16 = 16 + XEiJ.pnlScreenWidth;
    if ((sprReg8ResoCurr & 3) == 0) {  //水平256ドット、BGパターンは8x8、BG仮想画面は512x512、BG0とBG1
      final short[] tnum = sprTNum, tcol = sprTColCurr;
      final boolean[] th = sprTH, tv = sprTV;
      int x, y, sx, sy;
      //BG0
      //  BG0の有無は表示ラスタまで分からないので1ラスタ手前では常に展開しておかなければならない
      int ofst = (sprReg4BgCtrlCurr << (12 - 1)) & (3 << 12);  //4096*(BG0に割り当てられているテキスト)
      x = 16 + hStart - sprReg0Bg0XCurr;  //X座標。画面左端は16
      y = (src + sprReg1Bg0YCurr) & 511;
      sx = (((x & 7) - x) >> 3) & 63;  //テキストX座標
      sy = ofst + ((y >> 3) << 6);  //ofst+(テキストY座標*64)
      x &= 7;
      y &= 7;
      while (x < width16) {
        int t;
        if ((t = sprPatCurr[tnum[sy + sx] + (tv[sy + sx] ? 7 - y : y)]) != 0) {  //パターンあり
          if (th[sy + sx]) {  //左右反転あり
            sprBuffer[2112 +      x] |= (t        & 15) << 20;
            sprBuffer[2112 +  1 + x] |= (t >>>  4 & 15) << 20;
            sprBuffer[2112 +  2 + x] |= (t >>>  8 & 15) << 20;
            sprBuffer[2112 +  3 + x] |= (t >>> 12 & 15) << 20;
            sprBuffer[2112 +  4 + x] |= (t >>> 16 & 15) << 20;
            sprBuffer[2112 +  5 + x] |= (t >>> 20 & 15) << 20;
            sprBuffer[2112 +  6 + x] |= (t >>> 24 & 15) << 20;
            sprBuffer[2112 +  7 + x] |= (t >>> 28     ) << 20;
          } else {  //左右反転なし
            sprBuffer[2112 +      x] |= (t >>> 28     ) << 20;
            sprBuffer[2112 +  1 + x] |= (t >>> 24 & 15) << 20;
            sprBuffer[2112 +  2 + x] |= (t >>> 20 & 15) << 20;
            sprBuffer[2112 +  3 + x] |= (t >>> 16 & 15) << 20;
            sprBuffer[2112 +  4 + x] |= (t >>> 12 & 15) << 20;
            sprBuffer[2112 +  5 + x] |= (t >>>  8 & 15) << 20;
            sprBuffer[2112 +  6 + x] |= (t >>>  4 & 15) << 20;
            sprBuffer[2112 +  7 + x] |= (t        & 15) << 20;
          }  //if 左右反転あり/左右反転なし
        }  //if パターンあり
        if ((t = tcol[sy + sx]) != 0) {  //パレットブロックが0でないとき。バックグラウンドは4bitパレットが0でもパレットブロックが必要
          t <<= 20 - 4;  //tcolはパレットブロック<<4。ここでは4bitパレットと同じ位置に置く
          sprBuffer[1056      + x] |= t;
          sprBuffer[1056 +  1 + x] |= t;
          sprBuffer[1056 +  2 + x] |= t;
          sprBuffer[1056 +  3 + x] |= t;
          sprBuffer[1056 +  4 + x] |= t;
          sprBuffer[1056 +  5 + x] |= t;
          sprBuffer[1056 +  6 + x] |= t;
          sprBuffer[1056 +  7 + x] |= t;
        }
        x += 8;
        sx = (sx + 1) & 63;
      }  //while x<width16
      //BG1
      //  BG1の有無は表示ラスタまで分からないので1ラスタ手前では常に展開しておかなければならない
      ofst = (sprReg4BgCtrlCurr << (12 - 4)) & (3 << 12);  //4096*(BG1に割り当てられているテキスト)
      x = 16 + hStart - sprReg2Bg1XCurr;  //X座標。画面左端は16
      y = (src + sprReg3Bg1YCurr) & 511;
      sx = (((x & 7) - x) >> 3) & 63;  //テキストX座標
      sy = ofst + ((y >> 3) << 6);  //ofst+(テキストY座標*64)
      x &= 7;
      y &= 7;
      while (x < width16) {
        int t;
        if ((t = sprPatCurr[tnum[sy + sx] + (tv[sy + sx] ? 7 - y : y)]) != 0) {  //パターンあり
          if (th[sy + sx]) {  //左右反転あり
            sprBuffer[2112 +      x] |= (t        & 15) << 12;
            sprBuffer[2112 +  1 + x] |= (t >>>  4 & 15) << 12;
            sprBuffer[2112 +  2 + x] |= (t >>>  8 & 15) << 12;
            sprBuffer[2112 +  3 + x] |= (t >>> 12 & 15) << 12;
            sprBuffer[2112 +  4 + x] |= (t >>> 16 & 15) << 12;
            sprBuffer[2112 +  5 + x] |= (t >>> 20 & 15) << 12;
            sprBuffer[2112 +  6 + x] |= (t >>> 24 & 15) << 12;
            sprBuffer[2112 +  7 + x] |= (t >>> 28     ) << 12;
          } else {  //左右反転なし
            sprBuffer[2112 +      x] |= (t >>> 28     ) << 12;
            sprBuffer[2112 +  1 + x] |= (t >>> 24 & 15) << 12;
            sprBuffer[2112 +  2 + x] |= (t >>> 20 & 15) << 12;
            sprBuffer[2112 +  3 + x] |= (t >>> 16 & 15) << 12;
            sprBuffer[2112 +  4 + x] |= (t >>> 12 & 15) << 12;
            sprBuffer[2112 +  5 + x] |= (t >>>  8 & 15) << 12;
            sprBuffer[2112 +  6 + x] |= (t >>>  4 & 15) << 12;
            sprBuffer[2112 +  7 + x] |= (t        & 15) << 12;
          }  //if 左右反転あり/左右反転なし
        }  //if パターンあり
        if ((t = tcol[sy + sx]) != 0) {  //パレットブロックが0でないとき。バックグラウンドは4bitパレットが0でもパレットブロックが必要
          t <<= 12 - 4;  //tcolはパレットブロック<<4。ここでは4bitパレットと同じ位置に置く
          sprBuffer[1056      + x] |= t;
          sprBuffer[1056 +  1 + x] |= t;
          sprBuffer[1056 +  2 + x] |= t;
          sprBuffer[1056 +  3 + x] |= t;
          sprBuffer[1056 +  4 + x] |= t;
          sprBuffer[1056 +  5 + x] |= t;
          sprBuffer[1056 +  6 + x] |= t;
          sprBuffer[1056 +  7 + x] |= t;
        }
        x += 8;
        sx = (sx + 1) & 63;
      }  //while x<width16
    } else {  //水平512ドット、BGパターンは16x16、BG仮想画面は1024x1024、BG0のみ
      final short[] tnum = sprTNum, tcol = sprTColCurr;
      final boolean[] th = sprTH, tv = sprTV;
      int x, y, sx, sy;
      //BG0
      //  BG0の有無は表示ラスタまで分からないので1ラスタ手前では常に展開しておかなければならない
      int ofst = (sprReg4BgCtrlCurr << (12 - 1)) & (3 << 12);  //4096*(BG0に割り当てられているテキスト)
      x = 16 + hStart - sprReg0Bg0XCurr;  //X座標。画面左端は16
      y = (src + sprReg1Bg0YCurr) & 1023;
      sx = (((x & 15) - x) >> 4) & 63;  //テキストX座標
      sy = ofst + ((y >> 4) << 6);  //ofst+(テキストY座標*64)
      x &= 15;
      y &= 15;
      while (x < width16) {
        int a = (tnum[sy + sx] << 2) + (tv[sy + sx] ? 15 - y : y);
        int t;
        if ((t = sprPatCurr[a]) != 0) {  //左半分のパターンあり
          if (th[sy + sx]) {  //左右反転あり。左半分→右半分
            sprBuffer[2112 +  8 + x] |= (t        & 15) << 20;
            sprBuffer[2112 +  9 + x] |= (t >>>  4 & 15) << 20;
            sprBuffer[2112 + 10 + x] |= (t >>>  8 & 15) << 20;
            sprBuffer[2112 + 11 + x] |= (t >>> 12 & 15) << 20;
            sprBuffer[2112 + 12 + x] |= (t >>> 16 & 15) << 20;
            sprBuffer[2112 + 13 + x] |= (t >>> 20 & 15) << 20;
            sprBuffer[2112 + 14 + x] |= (t >>> 24 & 15) << 20;
            sprBuffer[2112 + 15 + x] |= (t >>> 28     ) << 20;
          } else {  //左右反転なし。左半分→左半分
            sprBuffer[2112 +      x] |= (t >>> 28     ) << 20;
            sprBuffer[2112 +  1 + x] |= (t >>> 24 & 15) << 20;
            sprBuffer[2112 +  2 + x] |= (t >>> 20 & 15) << 20;
            sprBuffer[2112 +  3 + x] |= (t >>> 16 & 15) << 20;
            sprBuffer[2112 +  4 + x] |= (t >>> 12 & 15) << 20;
            sprBuffer[2112 +  5 + x] |= (t >>>  8 & 15) << 20;
            sprBuffer[2112 +  6 + x] |= (t >>>  4 & 15) << 20;
            sprBuffer[2112 +  7 + x] |= (t        & 15) << 20;
          }  //if 左右反転あり/左右反転なし
        }  //if 左半分のパターンあり
        if ((t = sprPatCurr[16 + a]) != 0) {  //右半分のパターンあり
          if (th[sy + sx]) {  //左右反転あり。右半分→左半分
            sprBuffer[2112 +      x] |= (t        & 15) << 20;
            sprBuffer[2112 +  1 + x] |= (t >>>  4 & 15) << 20;
            sprBuffer[2112 +  2 + x] |= (t >>>  8 & 15) << 20;
            sprBuffer[2112 +  3 + x] |= (t >>> 12 & 15) << 20;
            sprBuffer[2112 +  4 + x] |= (t >>> 16 & 15) << 20;
            sprBuffer[2112 +  5 + x] |= (t >>> 20 & 15) << 20;
            sprBuffer[2112 +  6 + x] |= (t >>> 24 & 15) << 20;
            sprBuffer[2112 +  7 + x] |= (t >>> 28     ) << 20;
          } else {  //左右反転なし。右半分→右半分
            sprBuffer[2112 +  8 + x] |= (t >>> 28     ) << 20;
            sprBuffer[2112 +  9 + x] |= (t >>> 24 & 15) << 20;
            sprBuffer[2112 + 10 + x] |= (t >>> 20 & 15) << 20;
            sprBuffer[2112 + 11 + x] |= (t >>> 16 & 15) << 20;
            sprBuffer[2112 + 12 + x] |= (t >>> 12 & 15) << 20;
            sprBuffer[2112 + 13 + x] |= (t >>>  8 & 15) << 20;
            sprBuffer[2112 + 14 + x] |= (t >>>  4 & 15) << 20;
            sprBuffer[2112 + 15 + x] |= (t        & 15) << 20;
          }  //if 左右反転あり/左右反転なし
        }  //if 右半分のパターンあり
        if ((t = tcol[sy + sx]) != 0) {  //パレットブロックが0でないとき。バックグラウンドは4bitパレットが0でもパレットブロックが必要
          t <<= 20 - 4;  //tcolはパレットブロック<<4。ここでは4bitパレットと同じ位置に置く
          sprBuffer[1056      + x] |= t;
          sprBuffer[1056 +  1 + x] |= t;
          sprBuffer[1056 +  2 + x] |= t;
          sprBuffer[1056 +  3 + x] |= t;
          sprBuffer[1056 +  4 + x] |= t;
          sprBuffer[1056 +  5 + x] |= t;
          sprBuffer[1056 +  6 + x] |= t;
          sprBuffer[1056 +  7 + x] |= t;
          sprBuffer[1056 +  8 + x] |= t;
          sprBuffer[1056 +  9 + x] |= t;
          sprBuffer[1056 + 10 + x] |= t;
          sprBuffer[1056 + 11 + x] |= t;
          sprBuffer[1056 + 12 + x] |= t;
          sprBuffer[1056 + 13 + x] |= t;
          sprBuffer[1056 + 14 + x] |= t;
          sprBuffer[1056 + 15 + x] |= t;
        }  //if パレットブロックが0でないとき
        x += 16;
        sx = (sx + 1) & 63;
      }  //while x<width16
      if (spr512bg1) {  //512x512でBG1を表示
        //BG1
        //  BG1の有無は表示ラスタまで分からないので1ラスタ手前では常に展開しておかなければならない
        ofst = (sprReg4BgCtrlCurr << (12 - 4)) & (3 << 12);  //4096*(BG1に割り当てられているテキスト)
        x = 16 + hStart - sprReg2Bg1XCurr;  //X座標。画面左端は16
        y = (src + sprReg3Bg1YCurr) & 1023;
        sx = (((x & 15) - x) >> 4) & 63;  //テキストX座標
        sy = ofst + ((y >> 4) << 6);  //ofst+(テキストY座標*64)
        x &= 15;
        y &= 15;
        while (x < width16) {
          int a = (tnum[sy + sx] << 2) + (tv[sy + sx] ? 15 - y : y);
          int t;
          if ((t = sprPatCurr[a]) != 0) {  //左半分のパターンあり
            if (th[sy + sx]) {  //左右反転あり。左半分→右半分
              sprBuffer[2112 +  8 + x] |= (t        & 15) << 12;
              sprBuffer[2112 +  9 + x] |= (t >>>  4 & 15) << 12;
              sprBuffer[2112 + 10 + x] |= (t >>>  8 & 15) << 12;
              sprBuffer[2112 + 11 + x] |= (t >>> 12 & 15) << 12;
              sprBuffer[2112 + 12 + x] |= (t >>> 16 & 15) << 12;
              sprBuffer[2112 + 13 + x] |= (t >>> 20 & 15) << 12;
              sprBuffer[2112 + 14 + x] |= (t >>> 24 & 15) << 12;
              sprBuffer[2112 + 15 + x] |= (t >>> 28     ) << 12;
            } else {  //左右反転なし。左半分→左半分
              sprBuffer[2112 +      x] |= (t >>> 28     ) << 12;
              sprBuffer[2112 +  1 + x] |= (t >>> 24 & 15) << 12;
              sprBuffer[2112 +  2 + x] |= (t >>> 20 & 15) << 12;
              sprBuffer[2112 +  3 + x] |= (t >>> 16 & 15) << 12;
              sprBuffer[2112 +  4 + x] |= (t >>> 12 & 15) << 12;
              sprBuffer[2112 +  5 + x] |= (t >>>  8 & 15) << 12;
              sprBuffer[2112 +  6 + x] |= (t >>>  4 & 15) << 12;
              sprBuffer[2112 +  7 + x] |= (t        & 15) << 12;
            }  //if 左右反転あり/左右反転なし
          }  //if 左半分のパターンあり
          if ((t = sprPatCurr[16 + a]) != 0) {  //右半分のパターンあり
            if (th[sy + sx]) {  //左右反転あり。右半分→左半分
              sprBuffer[2112 +      x] |= (t        & 15) << 12;
              sprBuffer[2112 +  1 + x] |= (t >>>  4 & 15) << 12;
              sprBuffer[2112 +  2 + x] |= (t >>>  8 & 15) << 12;
              sprBuffer[2112 +  3 + x] |= (t >>> 12 & 15) << 12;
              sprBuffer[2112 +  4 + x] |= (t >>> 16 & 15) << 12;
              sprBuffer[2112 +  5 + x] |= (t >>> 20 & 15) << 12;
              sprBuffer[2112 +  6 + x] |= (t >>> 24 & 15) << 12;
              sprBuffer[2112 +  7 + x] |= (t >>> 28     ) << 12;
            } else {  //左右反転なし。右半分→右半分
              sprBuffer[2112 +  8 + x] |= (t >>> 28     ) << 12;
              sprBuffer[2112 +  9 + x] |= (t >>> 24 & 15) << 12;
              sprBuffer[2112 + 10 + x] |= (t >>> 20 & 15) << 12;
              sprBuffer[2112 + 11 + x] |= (t >>> 16 & 15) << 12;
              sprBuffer[2112 + 12 + x] |= (t >>> 12 & 15) << 12;
              sprBuffer[2112 + 13 + x] |= (t >>>  8 & 15) << 12;
              sprBuffer[2112 + 14 + x] |= (t >>>  4 & 15) << 12;
              sprBuffer[2112 + 15 + x] |= (t        & 15) << 12;
            }  //if 左右反転あり/左右反転なし
          }  //if 右半分のパターンあり
          if ((t = tcol[sy + sx]) != 0) {  //パレットブロックが0でないとき。バックグラウンドは4bitパレットが0でもパレットブロックが必要
            t <<= 12 - 4;  //tcolはパレットブロック<<4。ここでは4bitパレットと同じ位置に置く
            sprBuffer[1056      + x] |= t;
            sprBuffer[1056 +  1 + x] |= t;
            sprBuffer[1056 +  2 + x] |= t;
            sprBuffer[1056 +  3 + x] |= t;
            sprBuffer[1056 +  4 + x] |= t;
            sprBuffer[1056 +  5 + x] |= t;
            sprBuffer[1056 +  6 + x] |= t;
            sprBuffer[1056 +  7 + x] |= t;
            sprBuffer[1056 +  8 + x] |= t;
            sprBuffer[1056 +  9 + x] |= t;
            sprBuffer[1056 + 10 + x] |= t;
            sprBuffer[1056 + 11 + x] |= t;
            sprBuffer[1056 + 12 + x] |= t;
            sprBuffer[1056 + 13 + x] |= t;
            sprBuffer[1056 + 14 + x] |= t;
            sprBuffer[1056 + 15 + x] |= t;
          }  //if パレットブロックが0でないとき
          x += 16;
          sx = (sx + 1) & 63;
        }  //while x<width16
      }
    }  //if 水平256ドット/水平512ドット
  }  //sprStep2(int)

  //sprStep3 ()
  //  スプライトとバックグラウンドを重ねる
  //
  //  sprBuffer[2112 + x]
  //    4bitパレット
  //             28  24  20  16  12   8   4   0
  //    手前← |---|SP3|BG0|SP2|BG1|SP1|---|---| →奥
  //
  //  sprBuffer[1056 + x]
  //    パレットブロック
  //             28  24  20  16  12   8   4   0
  //    手前← |---|SP3|BG0|SP2|BG1|SP1|---|---| →奥
  //
  //  sprBuffer[x]
  //    8bitパレット
  //
  //!!! if (SPR_THREE_STEPS)
  public static void sprStep3 () {
    int width16 = 16 + XEiJ.pnlScreenWidth;
    if (!sprActive ||
        (sprReg4BgCtrlCurr & 512) == 0) {  //スプライト画面が表示されていない
      Arrays.fill (sprBuffer, 16, width16, 0);
    } else {  //スプライト画面が表示されている
      int mask = (15 << 24 |  //スプライト(プライオリティ3)
                  15 << 16 |  //スプライト(プライオリティ2)
                  15 << 8 |  //スプライト(プライオリティ1)
                  15 << 20 & -(sprReg4BgCtrlCurr & 1) |  //BG0。スプライト(プライオリティ3)とスプライト(プライオリティ2)の間
                  15 << 12 & -(sprReg4BgCtrlCurr & 8));  //BG1。スプライト(プライオリティ2)とスプライト(プライオリティ1)の間
      for (int x = 16; x < width16; x++) {  //X座標。画面左端は16
        int l = sprBuffer[2112 + x];  //4bitパレット
        int h = sprBuffer[1056 + x];  //パレットブロック
        if ((l &= mask) != 0) {  //4bitパレットが0でないプレーンがある
          int i = Integer.numberOfLeadingZeros (l) & -4;  //一番手前にあるものを選ぶ
          sprBuffer[x] = h << i >>> 28 << 4 | l << i >>> 28;  //パレットブロックと4bitパレットを合わせて8bitパレットを作る
        } else if ((h &= mask & (15 << 20 | 15 << 12)) != 0) {  //パレットブロックが0でないバックグラウンドプレーンがある
          int i = Integer.numberOfTrailingZeros (h) & -4;  //一番奥にあるものを選ぶ
          sprBuffer[x] = (h >> i & 15) << 4 | l >> i & 15;  //パレットブロックと4bitパレットを合わせて8bitパレットを作る
        } else {  //4bitパレットとパレットブロックがすべて0
          sprBuffer[x] = 0;
        }
      }  //for x
    }
  }  //sprStep3()



  //d = sprReadByte (a)
  //  リードバイト
  public static int sprReadByte (int a) throws M68kException {
    return ((a & 1) == 0 ?
            sprReadWord (a) >> 8 :
            sprReadWord (a & ~1) & 0x00ff);
  }  //sprReadByte

  //d = sprReadWord (a)
  //  リードワード
  public static int sprReadWord (int a) throws M68kException {
    a &= XEiJ.BUS_MOTHER_MASK;
    if (a < 0x00eb0800 || (0x00eb0840 <= a && a < 0x00eb4000)) {  //$00EB0000～$00EB07FF/$00EB0840～$00EB3FFF スプライトスクロールレジスタ
      //  アクセスできないとき
      //    バスエラーを返す
      //  ウェイトを追加する
      //  スプライト番号が範囲外のとき
      //    0xffffを返す
      //  スプライトスクロールレジスタを読み出して返す
      if (!sprAccessible) {  //アクセスできないとき
        return MemoryMappedDevice.MMD_NUL.mmdRwz (a);  //バスエラーを返す
      }
      //ウェイトを追加する
      XEiJ.mpuClockTime += sprWaitSprite;
      int n = (a - 0x00eb0000) >> 3;  //スプライト番号
      if (sprNumberOfSprites <= n) {  //スプライト番号が範囲外のとき
        return 0xffff;  //0xffffを返す
      }
      //スプライトスクロールレジスタを読み出して返す
      switch (a & 6) {
      case 0:
        return sprX[n];  //x座標
      case 2:
        return sprY[n];  //y座標
      case 4:
        {
          int v = sprV[n] ? 0x8000 : 0;  //上下反転<<15
          int h = sprH[n] ? 0x4000 : 0;  //左右反転<<14
          int col = sprColPort[n] << 4;  //(パレットブロック<<4)<<4
          int num = sprNum[n];  //パターン番号
          if (sprBankOn) {  //4096個のパターンが有効
            if (sprBankMode == 0) {  //256個
              return (v | h | col | num);
            } else if (sprBankMode == 1) {  //1024個
              return (v | h | (num & 0x0300) << 4 | col | (num & 0x00ff));
            } else {  //4096個
              return ((num & 0x0f00) << 4 | col | (num & 0x00ff));
            }
          } else {  //4096個のパターンが無効
            return (v | h | col | num);
          }
        }
      default:
        if (sprBankOn &&  //4096個のパターンが有効かつ
            sprBankMode == 3) {  //4096個反転あり
          return ((sprV[n] ? 0x8000 : 0) |  //上下反転<<15
                  (sprH[n] ? 0x4000 : 0) |  //左右反転<<14
                  (sprF[n] & 0x0004) |  //XPC1/PCS1
                  sprPrw[n]);  //プライオリティ
        } else {  //4096個のパターンが無効または(4096個反転あり)でない
          return ((sprF[n] & 0x0004) |  //XPC1/PCS1
                  sprPrw[n]);  //プライオリティ
        }
      }  //switch a&6
    } else if (a < 0x00eb4000) {  //$00EB0800～$00EB083F 各種レジスタ
      //  レジスタがあるとき
      //    レジスタの値を返す
      //  0xffffを返す
      switch (a) {
      case SPR_REG0_BG0_X:
        return sprReg0Bg0XPort;
      case SPR_REG1_BG0_Y:
        return sprReg1Bg0YPort;
      case SPR_REG2_BG1_X:
        return sprReg2Bg1XPort;
      case SPR_REG3_BG1_Y:
        return sprReg3Bg1YPort;
      case SPR_REG4_BG_CTRL:
        return sprReg4BgCtrlPort;
      case SPR_REG5_H_FRONT_END:
        return sprReg5HFrontEndPort;
      case SPR_REG6_H_BACK_END:
        return sprReg6HBackEndPort;
      case SPR_REG7_V_BACK_END:
        return sprReg7VBackEndPort;
      case SPR_REG8_RESO:
        return sprReg8ResoPort;
      case SPR_REG9_BANK_CONTROL:  //バンク制御
        if (sprBankOn) {  //4096個のパターンが有効
          return sprBankMode << 1 | (sprBankShifted ? 1 : 0);  //モード<<1|移動
        } else {  //4096個のパターンが無効
          return 0xffff;
        }
      case SPR_REG10_BANK_SELECT:  //バンク選択
        if (sprBankOn) {  //4096個のパターンが有効
          return sprBankNumber;  //バンク番号<<8
        } else {  //4096個のパターンが無効
          return 0xffff;
        }
      }
      return 0xffff;
    } else if (a < 0x00eb8000) {  //$00EB4000～$00EB7FFF テキストエリア
      //  4096個のパターンが有効かつ移動あり
      //    アクセスできないとき
      //      バスエラーを返す
      //    ウェイトを追加する
      //    テキストエリアを読み出して返す
      //  0xffffを返す
      if (sprBankOn &&  //4096個のパターンが有効かつ
          sprBankShifted) {  //移動あり
        if (!sprAccessible) {  //アクセスできないとき
          return MemoryMappedDevice.MMD_NUL.mmdRwz (a);  //バスエラーを返す
        }
        //ウェイトを追加する
        XEiJ.mpuClockTime += sprWaitPattern;
        //テキストエリアを読み出して返す
        int p = (a >> 1) & 8191;  //(4096*テキスト)+位置
        int v = sprTV[p] ? 0x8000 : 0;  //上下反転
        int h = sprTH[p] ? 0x4000 : 0;  //左右反転
        int col = sprTColPort[p] << 4;  //(パレットブロック<<4)<<4
        int num = sprTNum[p] >> 3;  //パターン番号
        if (sprBankOn) {  //4096個のパターンが有効
          if (sprBankMode == 0) {  //256個
            return (v | h | col | num);
          } else if (sprBankMode == 1) {  //1024個
            return (v | h | (num & 0x0300) << 4 | col | (num & 0x00ff));
          } else {  //4096個
            return ((num & 0x0f00) << 4 | col | (num & 0x00ff));
          }
        } else {  //4096個のパターンが無効
          return (v | h | col | num);
        }
      }  //if 4096個のパターンが有効かつテキストエリアが移動しているとき
      return 0xffff;
    } else {  //$00EB8000～$00EBFFFF パターンエリアとテキストエリア
      //  アクセスできないとき
      //    バスエラーを返す
      //  ウェイトを追加する
      //  XPC1/PCS1が選択されているとき
      //    0xffffを返す
      //  パターンエリアを読み出して返す
      if (!sprAccessible) {  //アクセスできないとき
        return MemoryMappedDevice.MMD_NUL.mmdRwz (a);  //バスエラーを返す
      }
      //ウェイトを追加する
      XEiJ.mpuClockTime += sprWaitPattern;
      if ((sprReg4BgCtrlPort & 0x0400) != 0) {  //XPC1/PCS1が選択されているとき
        return 0xffff;
      }
      //パターンエリアを読み出して返す
      int i = (a >> 2) & 8191;  //(パターン番号<<5)+int[]インデックス
      if (sprBankOn) {  //4096個のパターンが有効
        i += sprBankNumber << 5;  //(バンク番号<<8)<<5
      }
      return ((a & 2) == 0 ?
              sprPatPort[i] >>> 16 :
              (char) sprPatPort[i]);
    }
  }  //sprReadWord

  //d = sprReadLong (a)
  //  リードロング
  public static int sprReadLong (int a) throws M68kException {
    return (sprReadWord (a) << 16 |
            sprReadWord (a + 2));
  }  //sprReadLong



  //sprWriteByte (a, d)
  //  ライトバイト
  public static void sprWriteByte (int a, int d) throws M68kException {
    a &= XEiJ.BUS_MOTHER_MASK;
    if (a < 0x00eb0800 ||  //スプライトスクロールレジスタ
        (sprBankOn && sprBankShifted ? 0x00eb4000 : 0x00eb8000) <= a) {  //パターンエリアとテキストエリア
      sprWriteWord (a & ~1, d << 8 | (d & 0x00ff));  //上位バイトと下位バイトに同じ値を書き込む
    } else {  //各種レジスタ
      if ((a & 1) == 0) {
        sprWriteWord (a, d << 8 | (sprReadWord (a) & 0x00ff));
      } else {
        sprWriteWord (a & ~1, (sprReadWord (a & ~1) & 0xff00) | (d & 0x00ff));
      }
    }
  }  //sprWriteByte

  //sprWriteWord (a, d)
  //  ライトワード
  public static void sprWriteWord (int a, int d) throws M68kException {
    a &= XEiJ.BUS_MOTHER_MASK;
    if (a < 0x00eb0800 || (0x00eb0840 <= a && a < 0x00eb4000)) {  //$00EB0000～$00EB07FF/$00EB0840～$00EB3FFF スプライトスクロールレジスタ
      //  アクセスできないとき
      //    バスエラー
      //    終了
      //  ウェイトを追加する
      //  スプライト番号が範囲外のとき
      //    終了
      //  スプライトスクロールレジスタへ書き込む
      //  終了
      if (!sprAccessible) {  //アクセスできないとき
        MemoryMappedDevice.MMD_NUL.mmdWw (a, d);  //バスエラー
        return;
      }
      //ウェイトを追加する
      XEiJ.mpuClockTime += sprWaitSprite;
      int n = (a - 0x00eb0000) >> 3;  //スプライト番号
      if (sprNumberOfSprites <= n) {  //スプライト番号が範囲外のとき
        return;
      }
      //スプライトスクロールレジスタへ書き込む
      switch (a & 6) {
      case 0:
        sprX[n] = (short) (d & 1023);  //x座標
        return;
      case 2:
        d &= 1023;
        if (sprY[n] != d) {
          int y = sprY[n];  //元のy座標
          sprY[n] = (short) d;  //y座標
          if (sprPrw[n] != 0) {
            int mask = ~(0x80000000 >>> n);  //intのシフトカウントは5bitでマスクされる
            int i = y << (SPR_SHIFT - 5) | n >> 5;  //移動元
            sprRRmap[i                          ] &= mask;
            sprRRmap[i + ( 1 << (SPR_SHIFT - 5))] &= mask;
            sprRRmap[i + ( 2 << (SPR_SHIFT - 5))] &= mask;
            sprRRmap[i + ( 3 << (SPR_SHIFT - 5))] &= mask;
            sprRRmap[i + ( 4 << (SPR_SHIFT - 5))] &= mask;
            sprRRmap[i + ( 5 << (SPR_SHIFT - 5))] &= mask;
            sprRRmap[i + ( 6 << (SPR_SHIFT - 5))] &= mask;
            sprRRmap[i + ( 7 << (SPR_SHIFT - 5))] &= mask;
            sprRRmap[i + ( 8 << (SPR_SHIFT - 5))] &= mask;
            sprRRmap[i + ( 9 << (SPR_SHIFT - 5))] &= mask;
            sprRRmap[i + (10 << (SPR_SHIFT - 5))] &= mask;
            sprRRmap[i + (11 << (SPR_SHIFT - 5))] &= mask;
            sprRRmap[i + (12 << (SPR_SHIFT - 5))] &= mask;
            sprRRmap[i + (13 << (SPR_SHIFT - 5))] &= mask;
            sprRRmap[i + (14 << (SPR_SHIFT - 5))] &= mask;
            sprRRmap[i + (15 << (SPR_SHIFT - 5))] &= mask;
            mask = ~mask;
            i = d << (SPR_SHIFT - 5) | n >> 5;  //移動先
            sprRRmap[i                          ] |= mask;
            sprRRmap[i + ( 1 << (SPR_SHIFT - 5))] |= mask;
            sprRRmap[i + ( 2 << (SPR_SHIFT - 5))] |= mask;
            sprRRmap[i + ( 3 << (SPR_SHIFT - 5))] |= mask;
            sprRRmap[i + ( 4 << (SPR_SHIFT - 5))] |= mask;
            sprRRmap[i + ( 5 << (SPR_SHIFT - 5))] |= mask;
            sprRRmap[i + ( 6 << (SPR_SHIFT - 5))] |= mask;
            sprRRmap[i + ( 7 << (SPR_SHIFT - 5))] |= mask;
            sprRRmap[i + ( 8 << (SPR_SHIFT - 5))] |= mask;
            sprRRmap[i + ( 9 << (SPR_SHIFT - 5))] |= mask;
            sprRRmap[i + (10 << (SPR_SHIFT - 5))] |= mask;
            sprRRmap[i + (11 << (SPR_SHIFT - 5))] |= mask;
            sprRRmap[i + (12 << (SPR_SHIFT - 5))] |= mask;
            sprRRmap[i + (13 << (SPR_SHIFT - 5))] |= mask;
            sprRRmap[i + (14 << (SPR_SHIFT - 5))] |= mask;
            sprRRmap[i + (15 << (SPR_SHIFT - 5))] |= mask;
          }
        }
        return;
      case 4:
        {
          int preNum = sprNum[n];  //変更前のパターン番号
          int col = (d & 0x0f00) >> 4;  //パレットブロック<<4
          int num = (d & 0x00ff);  //パターン番号の下位8bit
          if (sprBankOn) {  //4096個のパターンが有効
            if (sprBankMode <= 1) {  //256個または1024個
              sprV[n] = (d & 0x8000) != 0;  //上下反転
              sprH[n] = (d & 0x4000) != 0;  //左右反転
              if (sprBankMode == 1) {  //1024個
                num |= (d & 0x3000) >> 4;  //パターン番号の上位2bit
              }
            } else  {  //4096個
              //4096個反転ありのときここでは反転を操作しない
              if (sprBankMode == 2) {  //反転なし
                sprV[n] = false;  //上下反転
                sprH[n] = false;  //左右反転
              }
              num |= (d & 0xf000) >> 4;  //パターン番号の上位4bit
            }
          } else {  //4096個のパターンが無効
            sprV[n] = (d & 0x8000) != 0;  //上下反転
            sprH[n] = (d & 0x4000) != 0;  //左右反転
          }
          sprColPort[n] = (short) col;  //パレットブロック<<4
          sprNum[n] = (short) num;  //パターン番号
          if (sprPrw[n] != 0 && preNum != num) {  //表示されているかつパターン番号が変わった
            int mask = 0x80000000 >>> n;  //intのシフトカウントは5bitでマスクされる
            sprPPmap[preNum << (SPR_SHIFT - 5) | n >> 5] &= ~mask;  //消滅
            sprPPmap[num << (SPR_SHIFT - 5) | n >> 5] |= mask;  //出現
          }
        }
        return;
      default:
        {
          if (sprBankOn &&  //4096個のパターンが有効かつ
              sprBankMode == 3) {  //4096個反転あり
            //4096個反転ありのときここで反転を操作する
            sprV[n] = (d & 0x8000) != 0;  //上下反転<<15
            sprH[n] = (d & 0x4000) != 0;  //左右反転<<14
          }
          int prePrw = sprPrw[n];  //変更前のプライオリティ
          int prw = (d & 0x0003);
          sprPrw[n] = (byte) prw;  //プライオリティ
          if (prePrw == 0 && prw != 0) {  //出現
            int y = sprY[n];
            int mask = 0x80000000 >>> n;  //intのシフトカウントは5bitでマスクされる
            int i = y << (SPR_SHIFT - 5) | n >> 5;
            sprRRmap[i                          ] |= mask;
            sprRRmap[i + ( 1 << (SPR_SHIFT - 5))] |= mask;
            sprRRmap[i + ( 2 << (SPR_SHIFT - 5))] |= mask;
            sprRRmap[i + ( 3 << (SPR_SHIFT - 5))] |= mask;
            sprRRmap[i + ( 4 << (SPR_SHIFT - 5))] |= mask;
            sprRRmap[i + ( 5 << (SPR_SHIFT - 5))] |= mask;
            sprRRmap[i + ( 6 << (SPR_SHIFT - 5))] |= mask;
            sprRRmap[i + ( 7 << (SPR_SHIFT - 5))] |= mask;
            sprRRmap[i + ( 8 << (SPR_SHIFT - 5))] |= mask;
            sprRRmap[i + ( 9 << (SPR_SHIFT - 5))] |= mask;
            sprRRmap[i + (10 << (SPR_SHIFT - 5))] |= mask;
            sprRRmap[i + (11 << (SPR_SHIFT - 5))] |= mask;
            sprRRmap[i + (12 << (SPR_SHIFT - 5))] |= mask;
            sprRRmap[i + (13 << (SPR_SHIFT - 5))] |= mask;
            sprRRmap[i + (14 << (SPR_SHIFT - 5))] |= mask;
            sprRRmap[i + (15 << (SPR_SHIFT - 5))] |= mask;
            sprPPmap[sprNum[n] << (SPR_SHIFT - 5) | n >> 5] |= mask;
          } else if (prePrw != 0 && prw == 0) {  //消滅
            int y = sprY[n];
            int mask = ~(0x80000000 >>> n);  //intのシフトカウントは5bitでマスクされる
            int i = y << (SPR_SHIFT - 5) | n >> 5;
            sprRRmap[i                          ] &= mask;
            sprRRmap[i + ( 1 << (SPR_SHIFT - 5))] &= mask;
            sprRRmap[i + ( 2 << (SPR_SHIFT - 5))] &= mask;
            sprRRmap[i + ( 3 << (SPR_SHIFT - 5))] &= mask;
            sprRRmap[i + ( 4 << (SPR_SHIFT - 5))] &= mask;
            sprRRmap[i + ( 5 << (SPR_SHIFT - 5))] &= mask;
            sprRRmap[i + ( 6 << (SPR_SHIFT - 5))] &= mask;
            sprRRmap[i + ( 7 << (SPR_SHIFT - 5))] &= mask;
            sprRRmap[i + ( 8 << (SPR_SHIFT - 5))] &= mask;
            sprRRmap[i + ( 9 << (SPR_SHIFT - 5))] &= mask;
            sprRRmap[i + (10 << (SPR_SHIFT - 5))] &= mask;
            sprRRmap[i + (11 << (SPR_SHIFT - 5))] &= mask;
            sprRRmap[i + (12 << (SPR_SHIFT - 5))] &= mask;
            sprRRmap[i + (13 << (SPR_SHIFT - 5))] &= mask;
            sprRRmap[i + (14 << (SPR_SHIFT - 5))] &= mask;
            sprRRmap[i + (15 << (SPR_SHIFT - 5))] &= mask;
            sprPPmap[sprNum[n] << (SPR_SHIFT - 5) | n >> 5] &= mask;
          }
          sprF[n] = (d & 0x0004) != 0 ? -1 : 0;  //XPC1/PCS1
        }
        return;
      }  //switch a&6
    } else if (a < 0x00eb4000) {  //$00EB0800～$00EB083F 各種レジスタ
      //  レジスタがあるとき
      //    レジスタへ書き込む
      //    終了
      //  終了
      switch (a) {
      case SPR_REG0_BG0_X:
        sprReg0Bg0XPort = (d & 1023);
        {
          int curr = sprReg0Bg0XMask == 0 ? sprReg0Bg0XPort : sprReg0Bg0XTest;
          if (sprReg0Bg0XCurr != curr) {
            sprReg0Bg0XCurr = curr;
          }
        }
        return;
      case SPR_REG1_BG0_Y:
        sprReg1Bg0YPort = (d & 1023);
        {
          int curr = sprReg1Bg0YMask == 0 ? sprReg1Bg0YPort : sprReg1Bg0YTest;
          if (sprReg1Bg0YCurr != curr) {
            sprReg1Bg0YCurr = curr;
          }
        }
        return;
      case SPR_REG2_BG1_X:
        sprReg2Bg1XPort = (d & 1023);
        {
          int curr = sprReg2Bg1XMask == 0 ? sprReg2Bg1XPort : sprReg2Bg1XTest;
          if (sprReg2Bg1XCurr != curr) {
            sprReg2Bg1XCurr = curr;
          }
        }
        return;
      case SPR_REG3_BG1_Y:
        sprReg3Bg1YPort = (d & 1023);
        {
          int curr = sprReg3Bg1YMask == 0 ? sprReg3Bg1YPort : sprReg3Bg1YTest;
          if (sprReg3Bg1YCurr != curr) {
            sprReg3Bg1YCurr = curr;
          }
        }
        return;
      case SPR_REG4_BG_CTRL:  //$00EB0808
        sprReg4BgCtrlPort = (d & 0x063f);
        {
          int curr = sprReg4BgCtrlPort & ~sprReg4BgCtrlMask | sprReg4BgCtrlTest & sprReg4BgCtrlMask;
          if (sprReg4BgCtrlCurr != curr) {
            sprReg4BgCtrlCurr = curr;
            if ((sprReg4BgCtrlCurr & 512) == 0) {  //DISP=0
              sprWaitSprite = SPR_WAIT_SPRITE_DISP_0;
              sprWaitPattern = SPR_WAIT_PATTERN_DISP_0;
            } else {  //DISP=1
              sprWaitSprite = SPR_WAIT_SPRITE_DISP_1;
              sprWaitPattern = SPR_WAIT_PATTERN_DISP_1;
              if (SPR_THREE_STEPS) {
                sprLatched = true;
              }
            }
          }
        }
        return;
      case SPR_REG5_H_FRONT_END:
        sprReg5HFrontEndPort = (d & 255);
        {
          int curr = sprReg5HFrontEndMask == 0 ? sprReg5HFrontEndPort : sprReg5HFrontEndTest;
          if (sprReg5HFrontEndCurr != curr) {
            sprReg5HFrontEndCurr = curr;
          }
        }
        return;
      case SPR_REG6_H_BACK_END:
        sprReg6HBackEndPort = (d & 63);
        {
          int curr = sprReg6HBackEndMask == 0 ? sprReg6HBackEndPort : sprReg6HBackEndTest;
          if (sprReg6HBackEndCurr != curr) {
            sprReg6HBackEndCurr = curr;
          }
        }
        return;
      case SPR_REG7_V_BACK_END:
        sprReg7VBackEndPort = (d & 255);
        {
          int curr = sprReg7VBackEndMask == 0 ? sprReg7VBackEndPort : sprReg7VBackEndTest;
          if (sprReg7VBackEndCurr != curr) {
            sprReg7VBackEndCurr = curr;
          }
        }
        return;
      case SPR_REG8_RESO:
        sprReg8ResoPort = (d & 31);
        {
          int curr = sprReg8ResoPort & ~sprReg8ResoMask | sprReg8ResoTest & sprReg8ResoMask;
          if (sprReg8ResoCurr != curr) {
            sprReg8ResoCurr = curr;
            CRTC.crtRestart ();
          }
        }
        return;
      case SPR_REG9_BANK_CONTROL:
        if (sprBankOn) {  //4096個のパターンが有効
          sprBankMode = (d & 6) >> 1;  //モード
          sprBankShifted = (d & 1) != 0;  //移動
        }
        return;
      case SPR_REG10_BANK_SELECT:
        if (sprBankOn) {  //4096個のパターンが有効
          sprBankNumber = (d & (15 << 8));  //バンク番号<<8
        }
        return;
      }  //switch a
      return;
    } else if (a < 0x00eb8000) {  //$00EB4000～$00EB7FFF テキストエリア
      //  4096個のパターンが有効かつ移動あり
      //    アクセスできないとき
      //      バスエラーで終了
      //    ウェイトを追加する
      //    テキストエリアへ書き込んで終了
      //  終了
      if (sprBankOn &&  //4096個のパターンが有効かつ
          sprBankShifted) {  //移動あり
        if (!sprAccessible) {  //アクセスできないとき
          MemoryMappedDevice.MMD_NUL.mmdWw (a, d);  //バスエラーで終了
          return;
        }
        //ウェイトを追加する
        XEiJ.mpuClockTime += sprWaitPattern;
        //テキストエリアへ書き込んで終了
        boolean v = (d & 0x8000) != 0;  //上下反転
        boolean h = (d & 0x4000) != 0;  //左右反転
        int col = (d & 0x0f00) >> 4;  //パレットブロック<<4
        int num = (d & 0x00ff);  //パターン番号の下位8bit
        if (sprBankMode == 0) {  //256個
        } else if (sprBankMode == 1) {  //1024個
          num |= (d & 0x3000) >> 4;  //パターン番号の上位2bit
        } else {  //4096個。反転は無効
          v = false;  //上下反転
          h = false;  //左右反転
          num |= (d & 0xf000) >> 4;  //パターン番号の上位4bit
        }
        int p = (a >> 1) & 8191;  //(4096*テキスト)+位置
        sprTV[p] = v;  //上下反転
        sprTH[p] = h;  //左右反転
        sprTColPort[p] = (short) col;  //パレットブロック<<4
        sprTNum[p] = (short) (num << 3);  //パターン番号<<3
        return;
      }
      return;
    } else if (a < 0x00ebc000) {  //$00EB8000～$00EBBFFF パターンエリア
      //  アクセスできないとき
      //    バスエラー
      //    終了
      //  ウェイトを追加する
      //  XPC1/PCS1が選択されているとき
      //    終了
      //  パターンエリアへ書き込む
      //  終了
      if (!sprAccessible) {  //アクセスできないとき
        MemoryMappedDevice.MMD_NUL.mmdWw (a, d);  //バスエラー
        return;
      }
      //ウェイトを追加する
      XEiJ.mpuClockTime += sprWaitPattern;
      if ((sprReg4BgCtrlPort & 0x0400) != 0) {  //XPC1/PCS1が選択されているとき
        return;
      }
      //パターンエリアへ書き込む
      int i = ((a >> 2) & 8191);  //(パターン番号<<5)+int[]インデックス
      if (sprBankOn) {  //4096個のパターンが有効
        i += sprBankNumber << 5;  //(バンク番号<<8)<<5
      }
      sprPatPort[i] = ((a & 2) == 0 ?
                       d << 16 | (char) sprPatPort[i] :
                       (sprPatPort[i] & 0xffff0000) | (char) d);
      return;
    } else {  //$00EBC000～$00EBFFFF パターンエリアとテキストエリア
      //  アクセスできないとき
      //    バスエラー
      //    終了
      //  ウェイトを追加する
      //  XPC1/PCS1が選択されているとき
      //    終了
      //  パターンエリアへ書き込む
      //  4096個のパターンが無効または移動なしかつバンク番号が0のとき
      //    テキストエリアへ書き込む
      //    終了
      //  終了
      if (!sprAccessible) {  //アクセスできないとき
        MemoryMappedDevice.MMD_NUL.mmdWw (a, d);  //バスエラー
        return;
      }
      //ウェイトを追加する
      XEiJ.mpuClockTime += sprWaitPattern;
      if ((sprReg4BgCtrlPort & 0x0400) != 0) {  //XPC1/PCS1が選択されているとき
        return;
      }
      //パターンエリアへ書き込む
      int i = ((a >> 2) & 8191);  //(パターン番号<<5)+int[]インデックス
      if (sprBankOn) {  //4096個のパターンが有効
        i += sprBankNumber << 5;  //(バンク番号<<8)<<5
      }
      sprPatPort[i] = ((a & 2) == 0 ?
                       d << 16 | (char) sprPatPort[i] :
                       (sprPatPort[i] & 0xffff0000) | (char) d);
      if (!sprBankOn ||  //4096個のパターンが無効または
          (!sprBankShifted && sprBankNumber == (0 << 8))) {  //移動なしかつバンク番号が0のとき
        //テキストエリアへ書き込む
        boolean v = (d & 0x8000) != 0;  //上下反転
        boolean h = (d & 0x4000) != 0;  //左右反転
        int col = (d & 0x0f00) >> 4;  //パレットブロック<<4
        int num = (d & 0x00ff);  //パターン番号の下位8bit
        if (sprBankOn) {  //4096個のパターンが有効
          if (sprBankMode == 0) {  //256個
          } else if (sprBankMode == 1) {  //1024個
            num |= (d & 0x3000) >> 4;  //パターン番号の上位2bit
          } else {  //4096個。反転は無効
            v = false;  //上下反転
            h = false;  //左右反転
            num |= (d & 0xf000) >> 4;  //パターン番号の上位4bit
          }
        }
        int p = (a >> 1) & 8191;  //(4096*テキスト)+位置
        sprTV[p] = v;  //上下反転
        sprTH[p] = h;  //左右反転
        sprTColPort[p] = (short) col;  //パレットブロック<<4
        sprTNum[p] = (short) (num << 3);  //パターン番号<<3
        return;
      }
      return;
    }
  }  //sprWriteWord

  //sprWriteLong (a, d)
  //  ライトロング
  public static void sprWriteLong (int a, int d) throws M68kException {
    sprWriteWord (a, d >> 16);
    sprWriteWord (a + 2, d);
  }  //sprWriteLong



}  //class SpriteScreen



