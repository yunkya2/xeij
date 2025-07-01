//========================================================================================
//  SpritePatternViewer.java
//    en:Sprite pattern viewer
//    ja:スプライトパターンビュア
//  Copyright (C) 2003-2024 Makoto Kamada
//
//  This file is part of the XEiJ (X68000 Emulator in Java).
//  You can use, modify and redistribute the XEiJ if the conditions are met.
//  Read the XEiJ License for more details.
//  https://stdkmd.net/xeij/
//========================================================================================

//----------------------------------------------------------------------------------------
//!!! 工事中
//  16x16のパターンを32x32に拡大して表示する
//    パターン
//      幅32px
//      高さ32px
//    セル
//      幅32px+ギャップ4px=幅36px/列
//      高さ32px+ギャップ8px=高さ40px/行
//    パターンエリア
//      幅36px/列*20列=幅720px
//      高さ40px/行*13行=高さ520px
//    PNL_STRETCH_BASEに従って水平方向に拡大してもよいがパネルの幅が変わってしまうので保留
//  パレットブロックは自動的に選択する
//    スプライトスクロールレジスタで使用されたことがあるとき
//      最後に使用されたパレットブロック
//    スプライトスクロールレジスタで使用されたことがないとき
//      直前のパターンと同じパレットブロック
//----------------------------------------------------------------------------------------

package xeij;

import java.awt.*;  //BasicStroke,BorderLayout,BoxLayout,Color,Component,Container,Cursor,Desktop,Dimension,Font,Frame,Graphics,Graphics2D,GraphicsDevice,GraphicsEnvironment,GridLayout,Image,Insets,Paint,Point,Rectangle,RenderingHints,Robot,Shape,Stroke,TexturePaint,Toolkit
import java.awt.event.*;  //ActionEvent,ActionListener,ComponentAdapter,ComponentEvent,ComponentListener,FocusAdapter,FocusEvent,FocusListener,InputEvent,KeyAdapter,KeyEvent,KeyListener,MouseAdapter,MouseEvent,MouseListener,MouseMotionAdapter,MouseWheelEvent,WindowAdapter,WindowEvent,WindowListener,WindowStateListener
import java.awt.image.*;  //BufferedImage,DataBuffer,DataBufferByte,DataBufferInt,IndexColorModel
import java.lang.*;  //Boolean,Character,Class,Comparable,Double,Exception,Float,IllegalArgumentException,Integer,Long,Math,Number,Object,Runnable,SecurityException,String,StringBuilder,System
import java.util.*;  //ArrayList,Arrays,Calendar,GregorianCalendar,HashMap,Map,Map.Entry,TimeZone,Timer,TimerTask,TreeMap
import javax.swing.*;  //AbstractSpinnerModel,Box,ButtonGroup,DefaultListModel,ImageIcon,JApplet,JButton,JCheckBox,JCheckBoxMenuItem,JDialog,JFileChooser,JFrame,JLabel,JList,JMenu,JMenuBar,JMenuItem,JPanel,JRadioButton,JScrollPane,JSpinner,JTextArea,JTextField,JTextPane,JViewport,ScrollPaneConstants,SpinnerListModel,SpinnerNumberModel,SwingConstants,SwingUtilities,UIManager,UIDefaults,UnsupportedLookAndFeelException

public class SpritePatternViewer {

  public static final boolean SPV_ON = true;

  //キャンバス
  public static final int SPV_CANVAS_WIDTH = 724;
  public static final int SPV_CANVAS_HEIGHT = 522;
  public static final int SPV_BACKGROUND_RGB = 0xff333333;  //背景色
  public static final int SPV_NUMBER_HEX_RGB = 0xff999999;  //スプライト番号(16進数)の色
  public static final int SPV_NUMBER_DEC_RGB = 0xffffffff;  //スプライト番号(10進数)の色
  public static final int SPV_PALET_BLOCK_RGB = 0xff999999;  //パレットブロックの色
  public static BufferedImage spvImage;  //イメージ
  public static int[] spvBitmap;  //ビットマップ

  //パネル
  public static JPanel spvPanel;  //パネル

  //ウインドウ
  public static JFrame spvFrame;  //ウインドウ

  //タイマー
  public static final int SPV_INTERVAL = 10;
  public static int spvTimer;

  //パレットブロック
  public static final int[] spvLastPaletBlock = new int[256];  //前回のパレットブロック<<4
  public static final int[] spvPaletBlock = new int[256];  //パレットブロック<<4

  public static void spvInit () {

    //ウインドウ
    spvFrame = null;

    //タイマー
    spvTimer = 0;

    //パレットブロック
    for (int n = 0; n < 256; n++) {
      spvLastPaletBlock[n] = 0x10;
    }

  }  //spvInit()

  //spvStart ()
  public static void spvStart () {
    if (RestorableFrame.rfmGetOpened (Settings.SGS_SPV_FRAME_KEY)) {
      spvOpen ();
    }
  }  //spvStart()

  //spvOpen ()
  //  スプライトパターンビュアを開く
  public static void spvOpen () {
    if (spvFrame == null) {
      spvMakeFrame ();
    } else {
      spvUpdateFrame ();
    }
    XEiJ.dbgVisibleMask |= XEiJ.DBG_SPV_VISIBLE_MASK;
    XEiJ.pnlExitFullScreen (false);
    spvFrame.setVisible (true);
  }  //spvOpen()

  //spvMakeFrame ()
  //  スプライトパターンビュアを作る
  //  ここでは開かない
  public static void spvMakeFrame () {

    //キャンバス
    spvImage = new BufferedImage (SPV_CANVAS_WIDTH, SPV_CANVAS_HEIGHT, BufferedImage.TYPE_INT_RGB);
    spvBitmap = ((DataBufferInt) spvImage.getRaster ().getDataBuffer ()).getData ();
    Arrays.fill (spvBitmap, SPV_BACKGROUND_RGB);
    for (int n = 0; n < 256; n++) {
      //  perl misc/optdiv.pl 255 20
      //  x/20==x*205>>>12 (0<=x<=1038) [255*205==52275]
      int ny = n * 205 >>> 12;
      int nx = n - 20 * ny;
      int x0 = 4 + 36 * nx;
      int y0 = 8 + 40 * ny;
      int i0 = x0 + SPV_CANVAS_WIDTH * y0;
      //0x10の位
      {
        int t = n >>> 4;
        spvPutc (-6 * SPV_CANVAS_WIDTH + i0, (9 - t >> 4 & 7 | 48) + t, SPV_NUMBER_HEX_RGB);
      }
      //0x1の位
      {
        int t = n & 15;
        spvPutc (4 + -6 * SPV_CANVAS_WIDTH + i0, (9 - t >> 4 & 7 | 48) + t, SPV_NUMBER_HEX_RGB);
      }
      //100の位
      int bcd = XEiJ.FMT_BCD4[n];
      if (100 <= n) {
        spvPutc (10 + -6 * SPV_CANVAS_WIDTH + i0, bcd >>> 8 | 48, SPV_NUMBER_DEC_RGB);
      }
      //10の位
      if (10 <= n) {
        spvPutc (14 + -6 * SPV_CANVAS_WIDTH + i0, bcd >>> 4 & 15 | 48, SPV_NUMBER_DEC_RGB);
      }
      //1の位
      spvPutc (18 + -6 * SPV_CANVAS_WIDTH + i0, bcd & 15 | 48, SPV_NUMBER_DEC_RGB);
    }  //for n

    //パネル
    spvPanel = ComponentFactory.setFixedSize (
      new JPanel () {
        @Override protected void paintComponent (Graphics g) {
          g.drawImage (spvImage, 0, 0, null);
        }
        @Override protected void paintBorder (Graphics g) {
        }
        @Override protected void paintChildren (Graphics g) {
        }
      },
      SPV_CANVAS_WIDTH, SPV_CANVAS_HEIGHT);
    spvPanel.setBackground (Color.black);
    spvPanel.setOpaque (true);

    //ウインドウ
    spvFrame = Multilingual.mlnTitle (
      ComponentFactory.createRestorableSubFrame (
        Settings.SGS_SPV_FRAME_KEY,
        "Sprite Pattern Viewer",
        null,
        spvPanel
        ),
      "ja", "スプライトパターンビュア");  //Multilingual.mlnTitle

    //  ウインドウリスナー
    ComponentFactory.addListener (
      spvFrame,
      new WindowAdapter () {
        @Override public void windowClosing (WindowEvent we) {
          XEiJ.dbgVisibleMask &= ~XEiJ.DBG_SPV_VISIBLE_MASK;
        }
      });

  }  //spvMakeFrame()

  //spvUpdateFrame ()
  //  スプライトパターンビュアを更新する
  public static void spvUpdateFrame () {

    if (spvFrame == null) {
      return;
    }

    //パレットブロック
    for (int n = 0; n < 256; n++) {
      spvPaletBlock[n] = -1;
    }
    for (int sn = 0; sn < 128; sn++) {  //スプライト番号
      int n = SpriteScreen.sprNum[sn];  //パターン番号
      if (spvPaletBlock[n] < 0) {
        spvPaletBlock[n] = spvLastPaletBlock[n] = SpriteScreen.sprColPort[sn];  //パレットブロック<<4
      }
    }
    for (int n = 0; n < 256; n++) {
      if (spvPaletBlock[n] < 0) {
        spvPaletBlock[n] = spvLastPaletBlock[n];
      }
    }
    int a = 0;
    for (int n = 0; n < 256; n++) {
      //  perl misc/optdiv.pl 255 20
      //  x/20==x*205>>>12 (0<=x<=1038) [255*205==52275]
      int ny = n * 205 >>> 12;
      int nx = n - 20 * ny;
      int x0 = 4 + 36 * nx;
      int y0 = 8 + 40 * ny;
      int i0 = x0 + SPV_CANVAS_WIDTH * y0;
      //パレットブロック
      int p = spvPaletBlock[n];  //パレットブロック<<4
      //10の位
      spvPutc (24 + -6 * SPV_CANVAS_WIDTH + i0, p < 0xa0 ? ' ' : '1', SPV_PALET_BLOCK_RGB);
      //1の位
      spvPutc (28 + -6 * SPV_CANVAS_WIDTH + i0, (p < 0xa0 ? p : p - 0xa0) >>> 4 | 48, SPV_PALET_BLOCK_RGB);
      //パターン
      //  +---+---+
      //  | 0 | 2 |
      //  +---+---+
      //  | 1 | 3 |
      //  +---+---+
      for (int u = 0; u < 32; u += 16) {
        for (int v = 0; v < 32; v += 2) {
          int d = SpriteScreen.sprPatPort[a++];
          int i = u + v * SPV_CANVAS_WIDTH + i0;
          int t = VideoController.vcnPal32TS[d >>> 28 | p];
          spvBitmap[                        i] = t;
          spvBitmap[ 1 +                    i] = t;
          spvBitmap[     SPV_CANVAS_WIDTH + i] = t;
          spvBitmap[ 1 + SPV_CANVAS_WIDTH + i] = t;
          t = VideoController.vcnPal32TS[d >>> 24 & 15 | p];
          spvBitmap[ 2 +                    i] = t;
          spvBitmap[ 3 +                    i] = t;
          spvBitmap[ 2 + SPV_CANVAS_WIDTH + i] = t;
          spvBitmap[ 3 + SPV_CANVAS_WIDTH + i] = t;
          t = VideoController.vcnPal32TS[d >>> 20 & 15 | p];
          spvBitmap[ 4 +                    i] = t;
          spvBitmap[ 5 +                    i] = t;
          spvBitmap[ 4 + SPV_CANVAS_WIDTH + i] = t;
          spvBitmap[ 5 + SPV_CANVAS_WIDTH + i] = t;
          t = VideoController.vcnPal32TS[d >>> 16 & 15 | p];
          spvBitmap[ 6 +                    i] = t;
          spvBitmap[ 7 +                    i] = t;
          spvBitmap[ 6 + SPV_CANVAS_WIDTH + i] = t;
          spvBitmap[ 7 + SPV_CANVAS_WIDTH + i] = t;
          t = VideoController.vcnPal32TS[(char) d >>> 12 | p];
          spvBitmap[ 8 +                    i] = t;
          spvBitmap[ 9 +                    i] = t;
          spvBitmap[ 8 + SPV_CANVAS_WIDTH + i] = t;
          spvBitmap[ 9 + SPV_CANVAS_WIDTH + i] = t;
          t = VideoController.vcnPal32TS[d >>> 8 & 15 | p];
          spvBitmap[10 +                    i] = t;
          spvBitmap[11 +                    i] = t;
          spvBitmap[10 + SPV_CANVAS_WIDTH + i] = t;
          spvBitmap[11 + SPV_CANVAS_WIDTH + i] = t;
          t = VideoController.vcnPal32TS[d >>> 4 & 15 | p];
          spvBitmap[12 +                    i] = t;
          spvBitmap[13 +                    i] = t;
          spvBitmap[12 + SPV_CANVAS_WIDTH + i] = t;
          spvBitmap[13 + SPV_CANVAS_WIDTH + i] = t;
          t = VideoController.vcnPal32TS[d & 15 | p];
          spvBitmap[14 +                    i] = t;
          spvBitmap[15 +                    i] = t;
          spvBitmap[14 + SPV_CANVAS_WIDTH + i] = t;
          spvBitmap[15 + SPV_CANVAS_WIDTH + i] = t;
        }  //for v
      }  //for u
    }  //for n
    spvPanel.repaint ();

  }  //spvUpdateFrame()

  public static void spvPutc (int i, int c, int f) {
    int t = Indicator.IND_ASCII_3X5[c];
    spvBitmap[                           i] = t << 31 - 14 < 0 ? f : SPV_BACKGROUND_RGB;
    spvBitmap[1 +                        i] = t << 31 - 13 < 0 ? f : SPV_BACKGROUND_RGB;
    spvBitmap[2 +                        i] = t << 31 - 12 < 0 ? f : SPV_BACKGROUND_RGB;
    spvBitmap[    1 * SPV_CANVAS_WIDTH + i] = t << 31 - 11 < 0 ? f : SPV_BACKGROUND_RGB;
    spvBitmap[1 + 1 * SPV_CANVAS_WIDTH + i] = t << 31 - 10 < 0 ? f : SPV_BACKGROUND_RGB;
    spvBitmap[2 + 1 * SPV_CANVAS_WIDTH + i] = t << 31 -  9 < 0 ? f : SPV_BACKGROUND_RGB;
    spvBitmap[    2 * SPV_CANVAS_WIDTH + i] = t << 31 -  8 < 0 ? f : SPV_BACKGROUND_RGB;
    spvBitmap[1 + 2 * SPV_CANVAS_WIDTH + i] = t << 31 -  7 < 0 ? f : SPV_BACKGROUND_RGB;
    spvBitmap[2 + 2 * SPV_CANVAS_WIDTH + i] = t << 31 -  6 < 0 ? f : SPV_BACKGROUND_RGB;
    spvBitmap[    3 * SPV_CANVAS_WIDTH + i] = t << 31 -  5 < 0 ? f : SPV_BACKGROUND_RGB;
    spvBitmap[1 + 3 * SPV_CANVAS_WIDTH + i] = t << 31 -  4 < 0 ? f : SPV_BACKGROUND_RGB;
    spvBitmap[2 + 3 * SPV_CANVAS_WIDTH + i] = t << 31 -  3 < 0 ? f : SPV_BACKGROUND_RGB;
    spvBitmap[    4 * SPV_CANVAS_WIDTH + i] = t << 31 -  2 < 0 ? f : SPV_BACKGROUND_RGB;
    spvBitmap[1 + 4 * SPV_CANVAS_WIDTH + i] = t << 31 -  1 < 0 ? f : SPV_BACKGROUND_RGB;
    spvBitmap[2 + 4 * SPV_CANVAS_WIDTH + i] = t << 31 -  0 < 0 ? f : SPV_BACKGROUND_RGB;
  }  //spvPutc(int,int)

}  //class SpritePatternViewer



