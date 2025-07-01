//========================================================================================
//  ATCMonitor.java
//    en:Address translation caches monitor
//    ja:アドレス変換キャッシュモニタ
//  Copyright (C) 2003-2024 Makoto Kamada
//
//  This file is part of the XEiJ (X68000 Emulator in Java).
//  You can use, modify and redistribute the XEiJ if the conditions are met.
//  Read the XEiJ License for more details.
//  https://stdkmd.net/xeij/
//========================================================================================

//      +------+----------------------------------------------------------------------------------------------------+
//      |      |          111111111122222222223333333333444444444455555555556666666666777777777788888888889999999999|
//      |      |0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789|
//      +------+----------------------------------------------------------------------------------------------------+
//      |     0|                                                                                                    |
//      |     1|                                     ADDRESS TRANSLATION CACHES                                     |
//      |     2|                                                                                                    |
//      |     3|        USER DATA                USER CODE             SUPERVISOR DATA          SUPERVISOR CODE     |
//      |     4|    dd/64=ddd% IN USE        dd/64=ddd% IN USE        dd/64=ddd% IN USE        dd/64=ddd% IN USE    |
//      |     5|                                                                                                    |
//      |     6|    LOGICAL  PHYSICAL        LOGICAL  PHYSICAL        LOGICAL  PHYSICAL        LOGICAL  PHYSICAL    |
//      |     7|  0 xxxxxxxx xxxxxxxx GW   0 xxxxxxxx xxxxxxxx GW   0 xxxxxxxx xxxxxxxx GW   0 xxxxxxxx xxxxxxxx GW |
//      |     8|  1 xxxxxxxx xxxxxxxx GW   1 xxxxxxxx xxxxxxxx GW   1 xxxxxxxx xxxxxxxx GW   1 xxxxxxxx xxxxxxxx GW |
//      |     9|  2 xxxxxxxx xxxxxxxx GW   2 xxxxxxxx xxxxxxxx GW   2 xxxxxxxx xxxxxxxx GW   2 xxxxxxxx xxxxxxxx GW |
//      |    10|  3 xxxxxxxx xxxxxxxx GW   3 xxxxxxxx xxxxxxxx GW   3 xxxxxxxx xxxxxxxx GW   3 xxxxxxxx xxxxxxxx GW |
//      |    11|  4 xxxxxxxx xxxxxxxx GW   4 xxxxxxxx xxxxxxxx GW   4 xxxxxxxx xxxxxxxx GW   4 xxxxxxxx xxxxxxxx GW |
//      |    12|  5 xxxxxxxx xxxxxxxx GW   5 xxxxxxxx xxxxxxxx GW   5 xxxxxxxx xxxxxxxx GW   5 xxxxxxxx xxxxxxxx GW |
//      |    13|  6 xxxxxxxx xxxxxxxx GW   6 xxxxxxxx xxxxxxxx GW   6 xxxxxxxx xxxxxxxx GW   6 xxxxxxxx xxxxxxxx GW |
//      |    14|  7 xxxxxxxx xxxxxxxx GW   7 xxxxxxxx xxxxxxxx GW   7 xxxxxxxx xxxxxxxx GW   7 xxxxxxxx xxxxxxxx GW |
//      |    15|  8 xxxxxxxx xxxxxxxx GW   8 xxxxxxxx xxxxxxxx GW   8 xxxxxxxx xxxxxxxx GW   8 xxxxxxxx xxxxxxxx GW |
//      |    16|  9 xxxxxxxx xxxxxxxx GW   9 xxxxxxxx xxxxxxxx GW   9 xxxxxxxx xxxxxxxx GW   9 xxxxxxxx xxxxxxxx GW |
//      |    17| 10 xxxxxxxx xxxxxxxx GW  10 xxxxxxxx xxxxxxxx GW  10 xxxxxxxx xxxxxxxx GW  10 xxxxxxxx xxxxxxxx GW |
//      |    18| 11 xxxxxxxx xxxxxxxx GW  11 xxxxxxxx xxxxxxxx GW  11 xxxxxxxx xxxxxxxx GW  11 xxxxxxxx xxxxxxxx GW |
//      |    19| 12 xxxxxxxx xxxxxxxx GW  12 xxxxxxxx xxxxxxxx GW  12 xxxxxxxx xxxxxxxx GW  12 xxxxxxxx xxxxxxxx GW |
//      |    20| 13 xxxxxxxx xxxxxxxx GW  13 xxxxxxxx xxxxxxxx GW  13 xxxxxxxx xxxxxxxx GW  13 xxxxxxxx xxxxxxxx GW |
//      |    21| 14 xxxxxxxx xxxxxxxx GW  14 xxxxxxxx xxxxxxxx GW  14 xxxxxxxx xxxxxxxx GW  14 xxxxxxxx xxxxxxxx GW |
//      |    22| 15 xxxxxxxx xxxxxxxx GW  15 xxxxxxxx xxxxxxxx GW  15 xxxxxxxx xxxxxxxx GW  15 xxxxxxxx xxxxxxxx GW |
//      |    23| 16 xxxxxxxx xxxxxxxx GW  16 xxxxxxxx xxxxxxxx GW  16 xxxxxxxx xxxxxxxx GW  16 xxxxxxxx xxxxxxxx GW |
//      |    24| 17 xxxxxxxx xxxxxxxx GW  17 xxxxxxxx xxxxxxxx GW  17 xxxxxxxx xxxxxxxx GW  17 xxxxxxxx xxxxxxxx GW |
//      |    25| 18 xxxxxxxx xxxxxxxx GW  18 xxxxxxxx xxxxxxxx GW  18 xxxxxxxx xxxxxxxx GW  18 xxxxxxxx xxxxxxxx GW |
//      |    26| 19 xxxxxxxx xxxxxxxx GW  19 xxxxxxxx xxxxxxxx GW  19 xxxxxxxx xxxxxxxx GW  19 xxxxxxxx xxxxxxxx GW |
//      |    27| 20 xxxxxxxx xxxxxxxx GW  20 xxxxxxxx xxxxxxxx GW  20 xxxxxxxx xxxxxxxx GW  20 xxxxxxxx xxxxxxxx GW |
//      |    28| 21 xxxxxxxx xxxxxxxx GW  21 xxxxxxxx xxxxxxxx GW  21 xxxxxxxx xxxxxxxx GW  21 xxxxxxxx xxxxxxxx GW |
//      |    29| 22 xxxxxxxx xxxxxxxx GW  22 xxxxxxxx xxxxxxxx GW  22 xxxxxxxx xxxxxxxx GW  22 xxxxxxxx xxxxxxxx GW |
//      |    30| 23 xxxxxxxx xxxxxxxx GW  23 xxxxxxxx xxxxxxxx GW  23 xxxxxxxx xxxxxxxx GW  23 xxxxxxxx xxxxxxxx GW |
//      |    31| 24 xxxxxxxx xxxxxxxx GW  24 xxxxxxxx xxxxxxxx GW  24 xxxxxxxx xxxxxxxx GW  24 xxxxxxxx xxxxxxxx GW |
//      |    32| 25 xxxxxxxx xxxxxxxx GW  25 xxxxxxxx xxxxxxxx GW  25 xxxxxxxx xxxxxxxx GW  25 xxxxxxxx xxxxxxxx GW |
//      |    33| 26 xxxxxxxx xxxxxxxx GW  26 xxxxxxxx xxxxxxxx GW  26 xxxxxxxx xxxxxxxx GW  26 xxxxxxxx xxxxxxxx GW |
//      |    34| 27 xxxxxxxx xxxxxxxx GW  27 xxxxxxxx xxxxxxxx GW  27 xxxxxxxx xxxxxxxx GW  27 xxxxxxxx xxxxxxxx GW |
//      |    35| 28 xxxxxxxx xxxxxxxx GW  28 xxxxxxxx xxxxxxxx GW  28 xxxxxxxx xxxxxxxx GW  28 xxxxxxxx xxxxxxxx GW |
//      |    36| 29 xxxxxxxx xxxxxxxx GW  29 xxxxxxxx xxxxxxxx GW  29 xxxxxxxx xxxxxxxx GW  29 xxxxxxxx xxxxxxxx GW |
//      |    37| 30 xxxxxxxx xxxxxxxx GW  30 xxxxxxxx xxxxxxxx GW  30 xxxxxxxx xxxxxxxx GW  30 xxxxxxxx xxxxxxxx GW |
//      |    38| 31 xxxxxxxx xxxxxxxx GW  31 xxxxxxxx xxxxxxxx GW  31 xxxxxxxx xxxxxxxx GW  31 xxxxxxxx xxxxxxxx GW |
//      |    39| 32 xxxxxxxx xxxxxxxx GW  32 xxxxxxxx xxxxxxxx GW  32 xxxxxxxx xxxxxxxx GW  32 xxxxxxxx xxxxxxxx GW |
//      |    40| 33 xxxxxxxx xxxxxxxx GW  33 xxxxxxxx xxxxxxxx GW  33 xxxxxxxx xxxxxxxx GW  33 xxxxxxxx xxxxxxxx GW |
//      |    41| 34 xxxxxxxx xxxxxxxx GW  34 xxxxxxxx xxxxxxxx GW  34 xxxxxxxx xxxxxxxx GW  34 xxxxxxxx xxxxxxxx GW |
//      |    42| 35 xxxxxxxx xxxxxxxx GW  35 xxxxxxxx xxxxxxxx GW  35 xxxxxxxx xxxxxxxx GW  35 xxxxxxxx xxxxxxxx GW |
//      |    43| 36 xxxxxxxx xxxxxxxx GW  36 xxxxxxxx xxxxxxxx GW  36 xxxxxxxx xxxxxxxx GW  36 xxxxxxxx xxxxxxxx GW |
//      |    44| 37 xxxxxxxx xxxxxxxx GW  37 xxxxxxxx xxxxxxxx GW  37 xxxxxxxx xxxxxxxx GW  37 xxxxxxxx xxxxxxxx GW |
//      |    45| 38 xxxxxxxx xxxxxxxx GW  38 xxxxxxxx xxxxxxxx GW  38 xxxxxxxx xxxxxxxx GW  38 xxxxxxxx xxxxxxxx GW |
//      |    46| 39 xxxxxxxx xxxxxxxx GW  39 xxxxxxxx xxxxxxxx GW  39 xxxxxxxx xxxxxxxx GW  39 xxxxxxxx xxxxxxxx GW |
//      |    47| 40 xxxxxxxx xxxxxxxx GW  40 xxxxxxxx xxxxxxxx GW  40 xxxxxxxx xxxxxxxx GW  40 xxxxxxxx xxxxxxxx GW |
//      |    48| 41 xxxxxxxx xxxxxxxx GW  41 xxxxxxxx xxxxxxxx GW  41 xxxxxxxx xxxxxxxx GW  41 xxxxxxxx xxxxxxxx GW |
//      |    49| 42 xxxxxxxx xxxxxxxx GW  42 xxxxxxxx xxxxxxxx GW  42 xxxxxxxx xxxxxxxx GW  42 xxxxxxxx xxxxxxxx GW |
//      |    50| 43 xxxxxxxx xxxxxxxx GW  43 xxxxxxxx xxxxxxxx GW  43 xxxxxxxx xxxxxxxx GW  43 xxxxxxxx xxxxxxxx GW |
//      |    51| 44 xxxxxxxx xxxxxxxx GW  44 xxxxxxxx xxxxxxxx GW  44 xxxxxxxx xxxxxxxx GW  44 xxxxxxxx xxxxxxxx GW |
//      |    52| 45 xxxxxxxx xxxxxxxx GW  45 xxxxxxxx xxxxxxxx GW  45 xxxxxxxx xxxxxxxx GW  45 xxxxxxxx xxxxxxxx GW |
//      |    53| 46 xxxxxxxx xxxxxxxx GW  46 xxxxxxxx xxxxxxxx GW  46 xxxxxxxx xxxxxxxx GW  46 xxxxxxxx xxxxxxxx GW |
//      |    54| 47 xxxxxxxx xxxxxxxx GW  47 xxxxxxxx xxxxxxxx GW  47 xxxxxxxx xxxxxxxx GW  47 xxxxxxxx xxxxxxxx GW |
//      |    55| 48 xxxxxxxx xxxxxxxx GW  48 xxxxxxxx xxxxxxxx GW  48 xxxxxxxx xxxxxxxx GW  48 xxxxxxxx xxxxxxxx GW |
//      |    56| 49 xxxxxxxx xxxxxxxx GW  49 xxxxxxxx xxxxxxxx GW  49 xxxxxxxx xxxxxxxx GW  49 xxxxxxxx xxxxxxxx GW |
//      |    57| 50 xxxxxxxx xxxxxxxx GW  50 xxxxxxxx xxxxxxxx GW  50 xxxxxxxx xxxxxxxx GW  50 xxxxxxxx xxxxxxxx GW |
//      |    58| 51 xxxxxxxx xxxxxxxx GW  51 xxxxxxxx xxxxxxxx GW  51 xxxxxxxx xxxxxxxx GW  51 xxxxxxxx xxxxxxxx GW |
//      |    59| 52 xxxxxxxx xxxxxxxx GW  52 xxxxxxxx xxxxxxxx GW  52 xxxxxxxx xxxxxxxx GW  52 xxxxxxxx xxxxxxxx GW |
//      |    60| 53 xxxxxxxx xxxxxxxx GW  53 xxxxxxxx xxxxxxxx GW  53 xxxxxxxx xxxxxxxx GW  53 xxxxxxxx xxxxxxxx GW |
//      |    61| 54 xxxxxxxx xxxxxxxx GW  54 xxxxxxxx xxxxxxxx GW  54 xxxxxxxx xxxxxxxx GW  54 xxxxxxxx xxxxxxxx GW |
//      |    62| 55 xxxxxxxx xxxxxxxx GW  55 xxxxxxxx xxxxxxxx GW  55 xxxxxxxx xxxxxxxx GW  55 xxxxxxxx xxxxxxxx GW |
//      |    63| 56 xxxxxxxx xxxxxxxx GW  56 xxxxxxxx xxxxxxxx GW  56 xxxxxxxx xxxxxxxx GW  56 xxxxxxxx xxxxxxxx GW |
//      |    64| 57 xxxxxxxx xxxxxxxx GW  57 xxxxxxxx xxxxxxxx GW  57 xxxxxxxx xxxxxxxx GW  57 xxxxxxxx xxxxxxxx GW |
//      |    65| 58 xxxxxxxx xxxxxxxx GW  58 xxxxxxxx xxxxxxxx GW  58 xxxxxxxx xxxxxxxx GW  58 xxxxxxxx xxxxxxxx GW |
//      |    66| 59 xxxxxxxx xxxxxxxx GW  59 xxxxxxxx xxxxxxxx GW  59 xxxxxxxx xxxxxxxx GW  59 xxxxxxxx xxxxxxxx GW |
//      |    67| 60 xxxxxxxx xxxxxxxx GW  60 xxxxxxxx xxxxxxxx GW  60 xxxxxxxx xxxxxxxx GW  60 xxxxxxxx xxxxxxxx GW |
//      |    68| 61 xxxxxxxx xxxxxxxx GW  61 xxxxxxxx xxxxxxxx GW  61 xxxxxxxx xxxxxxxx GW  61 xxxxxxxx xxxxxxxx GW |
//      |    69| 62 xxxxxxxx xxxxxxxx GW  62 xxxxxxxx xxxxxxxx GW  62 xxxxxxxx xxxxxxxx GW  62 xxxxxxxx xxxxxxxx GW |
//      |    70| 63 xxxxxxxx xxxxxxxx GW  63 xxxxxxxx xxxxxxxx GW  63 xxxxxxxx xxxxxxxx GW  63 xxxxxxxx xxxxxxxx GW |
//      |    71|                                     G:GLOBAL W:WRITE-PROTECTED                                     |
//      |    72|                                                                                                    |
//      +------+----------------------------------------------------------------------------------------------------+
//      |      |          111111111122222222223333333333444444444455555555556666666666777777777788888888889999999999|
//      |      |0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789|
//      +------+----------------------------------------------------------------------------------------------------+

package xeij;

import java.awt.*;  //BasicStroke,BorderLayout,BoxLayout,Color,Component,Container,Cursor,Desktop,Dimension,Font,FlowLayout,Frame,Graphics,Graphics2D,GraphicsDevice,GraphicsEnvironment,GridLayout,Image,Insets,Paint,Point,Rectangle,RenderingHints,Robot,Shape,Stroke,TexturePaint,Toolkit
import java.awt.event.*;  //ActionEvent,ActionListener,ComponentAdapter,ComponentEvent,ComponentListener,FocusAdapter,FocusEvent,FocusListener,InputEvent,KeyAdapter,KeyEvent,KeyListener,MouseAdapter,MouseEvent,MouseListener,MouseMotionAdapter,MouseWheelEvent,WindowAdapter,WindowEvent,WindowListener,WindowStateListener
import java.awt.image.*;  //BufferedImage,DataBuffer,DataBufferByte,DataBufferInt,IndexColorModel
import java.lang.*;  //Boolean,Character,Class,Comparable,Double,Exception,Float,IllegalArgumentException,Integer,Long,Math,Number,Object,Runnable,SecurityException,String,StringBuilder,System
import java.util.*;  //ArrayList,Arrays,Calendar,GregorianCalendar,HashMap,Map,Map.Entry,Timer,TimerTask,TreeMap
import javax.swing.*;  //AbstractSpinnerModel,Box,ButtonGroup,DefaultListModel,ImageIcon,JApplet,JButton,JCheckBox,JCheckBoxMenuItem,JDialog,JFileChooser,JFrame,JLabel,JList,JMenu,JMenuBar,JMenuItem,JPanel,JRadioButton,JScrollPane,JSpinner,JTextArea,JTextField,JTextPane,JViewport,ScrollPaneConstants,SpinnerListModel,SpinnerNumberModel,SwingConstants,SwingUtilities,UIManager,UIDefaults,UnsupportedLookAndFeelException

public class ATCMonitor {

  public static final boolean ACM_ON = true;

  //アドレス変換キャッシュ
  public static int[][] acmCaches;

  //キャンバス
  public static final int ACM_WIDTH = 4 * 100;
  public static final int ACM_HEIGHT = 6 * 73;
  public static final int ACM_OFFSET = ACM_WIDTH + 3 >> 2;
  public static IndexColorModel acmColorModel;
  public static BufferedImage acmImage;
  public static byte[] acmBitmap;

  //パネル
  public static JPanel acmPanel;  //パネル

  //ウインドウ
  public static JFrame acmFrame;  //ウインドウ

  //タイマー
  public static final int ACM_INTERVAL = 10;
  public static int acmTimer;

  //フォント
  public static final byte[] ACM_FONT_1 = new byte[5 * 127];
  public static final byte[] ACM_FONT_2 = new byte[5 * 127];
  public static final byte[] ACM_FONT_3 = new byte[5 * 127];

  //acmInit ()
  //  初期化
  public static void acmInit () {

    //アドレス変換キャッシュ
    acmCaches = new int[][] {
      MC68060.mmuUserDataCache,
      MC68060.mmuUserCodeCache,
      MC68060.mmuSuperDataCache,
      MC68060.mmuSuperCodeCache,
    };

    //フォント
    {
      final long m = 0b01010100_01010000_01000100_01000000_00010100_00010000_00000100_00000000L;
      int k = 0;
      for (int i = 0; i < 127; i++) {
        int t = Indicator.IND_ASCII_3X5[i];
        int d;
        //d = t >> 14 - 6 & 0b01000000 | t >> 13 - 4 & 0b00010000 | t >> 12 - 2 & 0b00000100;
        d = (int) (m >>> (t >>> 12 - 3 & 7 << 3)) & 255;
        ACM_FONT_1[k] = (byte)  d;
        ACM_FONT_2[k] = (byte) (d * 2);
        ACM_FONT_3[k] = (byte) (d * 3);
        k++;
        //d = t >> 11 - 6 & 0b01000000 | t >> 10 - 4 & 0b00010000 | t >>  9 - 2 & 0b00000100;
        d = (int) (m >>> (t >>>  9 - 3 & 7 << 3)) & 255;
        ACM_FONT_1[k] = (byte)  d;
        ACM_FONT_2[k] = (byte) (d * 2);
        ACM_FONT_3[k] = (byte) (d * 3);
        k++;
        //d = t >>  8 - 6 & 0b01000000 | t >>  7 - 4 & 0b00010000 | t >>  6 - 2 & 0b00000100;
        d = (int) (m >>> (t >>>  6 - 3 & 7 << 3)) & 255;
        ACM_FONT_1[k] = (byte)  d;
        ACM_FONT_2[k] = (byte) (d * 2);
        ACM_FONT_3[k] = (byte) (d * 3);
        k++;
        //d = t <<  6 - 5 & 0b01000000 | t           & 0b00010000 | t >>  3 - 2 & 0b00000100;
        d = (int) (m >>> (t            & 7 << 3)) & 255;
        ACM_FONT_1[k] = (byte)  d;
        ACM_FONT_2[k] = (byte) (d * 2);
        ACM_FONT_3[k] = (byte) (d * 3);
        k++;
        //d = t <<  6 - 2 & 0b01000000 | t <<  4 - 1 & 0b00010000 | t <<  2 - 0 & 0b00000100;
        d = (int) (m >>> (t <<   6 - 3 & 7 << 3)) & 255;
        ACM_FONT_1[k] = (byte)  d;
        ACM_FONT_2[k] = (byte) (d * 2);
        ACM_FONT_3[k] = (byte) (d * 3);
        k++;
      }
    }

    //ウインドウ
    acmFrame = null;

    //タイマー
    acmTimer = 0;

  }  //acmInit()

  //acmStart ()
  public static void acmStart () {
    if (RestorableFrame.rfmGetOpened (Settings.SGS_ACM_FRAME_KEY)) {
      acmOpen ();
    }
  }  //acmStart()

  //acmOpen ()
  //  アドレス変換キャッシュモニタを開く
  public static void acmOpen () {
    if (acmFrame == null) {
      acmMakeFrame ();
    } else {
      acmUpdateFrame ();
    }
    XEiJ.dbgVisibleMask |= XEiJ.DBG_ACM_VISIBLE_MASK;
    XEiJ.pnlExitFullScreen (false);
    acmFrame.setVisible (true);
  }  //acmOpen()

  //acmMakeFrame ()
  //  アドレス変換キャッシュモニタを作る
  //  ここでは開かない
  public static void acmMakeFrame () {

    //キャンバス
    acmColorModel = new IndexColorModel (2, 4,
                                         //                   黒           青           橙           白
                                         new byte[] { (byte) 0x00, (byte) 0x20, (byte) 0xff, (byte) 0xff },  //Red
                                         new byte[] { (byte) 0x00, (byte) 0x20, (byte) 0x87, (byte) 0xff },  //Green
                                         new byte[] { (byte) 0x00, (byte) 0xff, (byte) 0x40, (byte) 0xff });  //Blue
    acmImage = new BufferedImage (ACM_WIDTH, ACM_HEIGHT, BufferedImage.TYPE_BYTE_BINARY, acmColorModel);
    acmBitmap = ((DataBufferByte) acmImage.getRaster ().getDataBuffer ()).getData ();
    acmDrawString3 (37, 1, "ADDRESS TRANSLATION CACHES");
    acmDrawString2 (8, 3, "USER DATA");
    acmDrawString2 (33, 3, "USER CODE");
    acmDrawString2 (55, 3, "SUPERVISOR DATA");
    acmDrawString2 (80, 3, "SUPERVISOR CODE");
    for (int z = 0; z < 4; z++) {
      int x0 = 25 * z;
      acmDrawString3 (x0 + 6, 4, "/64=");
      acmDrawString3 (x0 + 13, 4, "% IN USE");
      acmDrawString2 (x0 + 4, 6, "LOGICAL  PHYSICAL");
    }
    acmDrawString2 (37, 71, "G:GLOBAL W:WRITE-PROTECTED");

    //パネル
    acmPanel = ComponentFactory.setFixedSize (
      new JPanel () {
        @Override protected void paintComponent (Graphics g) {
          g.drawImage (acmImage, 0, 0, null);
        }
        @Override protected void paintBorder (Graphics g) {
        }
        @Override protected void paintChildren (Graphics g) {
        }
        @Override public void update (Graphics g) {
        }
      }, ACM_WIDTH, ACM_HEIGHT);
    acmPanel.setBackground (Color.black);
    acmPanel.setOpaque (true);

    //ウインドウ
    acmFrame = Multilingual.mlnTitle (
      ComponentFactory.createRestorableSubFrame (
        Settings.SGS_ACM_FRAME_KEY,
        "Address translation caches monitor",
        null,
        acmPanel
        ),
      "ja", "アドレス変換キャッシュモニタ");  //Multilingual.mlnTitle

    //  ウインドウリスナー
    ComponentFactory.addListener (
      acmFrame,
      new WindowAdapter () {
        @Override public void windowClosing (WindowEvent we) {
          XEiJ.dbgVisibleMask &= ~XEiJ.DBG_ACM_VISIBLE_MASK;
        }
      });

  }  //acmMakeFrame()

  //acmUpdateFrame ()
  //  アドレス変換キャッシュモニタを更新する
  public static void acmUpdateFrame () {

    if (acmFrame == null) {
      return;
    }

    for (int z = 0; z < 4; z++) {
      int[] cache = acmCaches[z];
      int x0 = 25 * z;
      int inuse = 0;
      int t;
      for (int l = 0, i = 0; l < 64; l++, i += 4) {  //ライン,インデックス
        t = XEiJ.FMT_BCD4[l];
        int y = 7 + l;
        int r = cache[i];  //リード用の論理ページアドレス
        if (!MC68060.mmuEnabled || r == 1) {  //無効
          acmDrawChar1 (x0 + 1, y, t >> 4 == 0 ? ' ' : (t >> 4) + '0');  //10の位
          acmDrawChar1 (x0 + 2, y, (t & 15) + '0');  //1の位
          acmDrawString1 (x0 + 4, y, "-------- -------- --");
        } else {  //有効
          inuse++;
          int w = cache[i + 1];  //ライト用の論理ページアドレス
          int p = cache[i + 2];  //物理ページアドレス
          int g = cache[i + 3];  //グローバルフラグ
          acmDrawChar3 (x0 + 1, y, t >> 4 == 0 ? ' ' : (t >> 4) + '0');  //10の位
          acmDrawChar3 (x0 + 2, y, (t & 15) + '0');  //1の位
          //論理ページアドレス
          t = r >>> 28;
          acmDrawChar3 (x0 + 4, y, (9 - t >> 4 & 7) + t + '0');
          t = r >>> 24 & 15;
          acmDrawChar3 (x0 + 5, y, (9 - t >> 4 & 7) + t + '0');
          t = r >>> 20 & 15;
          acmDrawChar3 (x0 + 6, y, (9 - t >> 4 & 7) + t + '0');
          t = r >>> 16 & 15;
          acmDrawChar3 (x0 + 7, y, (9 - t >> 4 & 7) + t + '0');
          t = (char) r >>> 12;
          acmDrawChar3 (x0 + 8, y, (9 - t >> 4 & 7) + t + '0');
          t = r >>> 8 & 15;
          acmDrawChar3 (x0 + 9, y, (9 - t >> 4 & 7) + t + '0');
          t = r >>> 4 & 15;
          acmDrawChar3 (x0 + 10, y, (9 - t >> 4 & 7) + t + '0');
          t = r & 15;
          acmDrawChar3 (x0 + 11, y, (9 - t >> 4 & 7) + t + '0');
          //物理ページアドレス
          t = p >>> 28;
          acmDrawChar3 (x0 + 13, y, (9 - t >> 4 & 7) + t + '0');
          t = p >>> 24 & 15;
          acmDrawChar3 (x0 + 14, y, (9 - t >> 4 & 7) + t + '0');
          t = p >>> 20 & 15;
          acmDrawChar3 (x0 + 15, y, (9 - t >> 4 & 7) + t + '0');
          t = p >>> 16 & 15;
          acmDrawChar3 (x0 + 16, y, (9 - t >> 4 & 7) + t + '0');
          t = (char) p >>> 12;
          acmDrawChar3 (x0 + 17, y, (9 - t >> 4 & 7) + t + '0');
          t = p >>> 8 & 15;
          acmDrawChar3 (x0 + 18, y, (9 - t >> 4 & 7) + t + '0');
          t = p >>> 4 & 15;
          acmDrawChar3 (x0 + 19, y, (9 - t >> 4 & 7) + t + '0');
          t = p & 15;
          acmDrawChar3 (x0 + 20, y, (9 - t >> 4 & 7) + t + '0');
          //グローバル
          acmDrawChar3 (x0 + 22, y, g != 0 ? 'G' : '-');
          //ライトプロテクト
          acmDrawChar3 (x0 + 23, y, w == 1 ? 'W' : '-');
        }  //if 無効/有効
      }  //for l,i
      t = XEiJ.FMT_BCD4[inuse];
      acmDrawChar3 (x0 + 4, 4, t >> 4 == 0 ? ' ' : (t >> 4) + '0');  //10の位
      acmDrawChar3 (x0 + 5, 4, (t & 15) + '0');  //1の位
      t = XEiJ.FMT_BCD4[100 * inuse + 32 >> 6];
      acmDrawChar3 (x0 + 10, 4, t >> 8 == 0 ? ' ' : (t >> 8) + '0');  //100の位
      acmDrawChar3 (x0 + 11, 4, t >> 4 == 0 ? ' ' : (t >> 4 & 15) + '0');  //10の位
      acmDrawChar3 (x0 + 12, 4, (t & 15) + '0');  //1の位
    }  //for z

    acmPanel.repaint ();

  }  //acmUpdateFrame()

  //acmDrawChar1 (x, y, c)
  //  パレットコード1で文字を描く
  public static void acmDrawChar1 (int x, int y, int c) {
    byte[] bb = acmBitmap;
    x += ACM_OFFSET * 6 * y;
    c *= 5;
    bb[x                 ] = ACM_FONT_1[c    ];
    bb[x + ACM_OFFSET    ] = ACM_FONT_1[c + 1];
    bb[x + ACM_OFFSET * 2] = ACM_FONT_1[c + 2];
    bb[x + ACM_OFFSET * 3] = ACM_FONT_1[c + 3];
    bb[x + ACM_OFFSET * 4] = ACM_FONT_1[c + 4];
  }  //acmDrawChar1(int,int,int)

  //acmDrawChar2 (x, y, c)
  //  パレットコード2で文字を描く
  public static void acmDrawChar2 (int x, int y, int c) {
    byte[] bb = acmBitmap;
    x += ACM_OFFSET * 6 * y;
    c *= 5;
    bb[x                 ] = ACM_FONT_2[c    ];
    bb[x + ACM_OFFSET    ] = ACM_FONT_2[c + 1];
    bb[x + ACM_OFFSET * 2] = ACM_FONT_2[c + 2];
    bb[x + ACM_OFFSET * 3] = ACM_FONT_2[c + 3];
    bb[x + ACM_OFFSET * 4] = ACM_FONT_2[c + 4];
  }  //acmDrawChar2(int,int,int)

  //acmDrawChar3 (x, y, c)
  //  パレットコード3で文字を描く
  public static void acmDrawChar3 (int x, int y, int c) {
    byte[] bb = acmBitmap;
    x += ACM_OFFSET * 6 * y;
    c *= 5;
    bb[x                 ] = ACM_FONT_3[c    ];
    bb[x + ACM_OFFSET    ] = ACM_FONT_3[c + 1];
    bb[x + ACM_OFFSET * 2] = ACM_FONT_3[c + 2];
    bb[x + ACM_OFFSET * 3] = ACM_FONT_3[c + 3];
    bb[x + ACM_OFFSET * 4] = ACM_FONT_3[c + 4];
  }  //acmDrawChar3(int,int,int)

  //acmDrawString1 (x, y, s)
  //  パレットコード1で文字列を描く
  public static void acmDrawString1 (int x, int y, String s) {
    acmDrawString1 (x, y, s.toCharArray ());
  }  //acmDrawString1(int,int,String)
  public static void acmDrawString1 (int x, int y, char[] s) {
    byte[] bb = acmBitmap;
    x += ACM_OFFSET * 6 * y;
    for (char c : s) {
      c *= 5;
      bb[x                 ] = ACM_FONT_1[c    ];
      bb[x + ACM_OFFSET    ] = ACM_FONT_1[c + 1];
      bb[x + ACM_OFFSET * 2] = ACM_FONT_1[c + 2];
      bb[x + ACM_OFFSET * 3] = ACM_FONT_1[c + 3];
      bb[x + ACM_OFFSET * 4] = ACM_FONT_1[c + 4];
      x++;
    }
  }  //acmDrawString1(int,int,char[])

  //acmDrawString2 (x, y, s)
  //  パレットコード2で文字列を描く
  public static void acmDrawString2 (int x, int y, String s) {
    acmDrawString2 (x, y, s.toCharArray ());
  }  //acmDrawString2(int,int,String)
  public static void acmDrawString2 (int x, int y, char[] s) {
    byte[] bb = acmBitmap;
    x += ACM_OFFSET * 6 * y;
    for (char c : s) {
      c *= 5;
      bb[x                 ] = ACM_FONT_2[c    ];
      bb[x + ACM_OFFSET    ] = ACM_FONT_2[c + 1];
      bb[x + ACM_OFFSET * 2] = ACM_FONT_2[c + 2];
      bb[x + ACM_OFFSET * 3] = ACM_FONT_2[c + 3];
      bb[x + ACM_OFFSET * 4] = ACM_FONT_2[c + 4];
      x++;
    }
  }  //acmDrawString2(int,int,char[])

  //acmDrawString3 (x, y, s)
  //  パレットコード3で文字列を描く
  public static void acmDrawString3 (int x, int y, String s) {
    acmDrawString3 (x, y, s.toCharArray ());
  }  //acmDrawString3(int,int,String)
  public static void acmDrawString3 (int x, int y, char[] s) {
    byte[] bb = acmBitmap;
    x += ACM_OFFSET * 6 * y;
    for (char c : s) {
      c *= 5;
      bb[x                 ] = ACM_FONT_3[c    ];
      bb[x + ACM_OFFSET    ] = ACM_FONT_3[c + 1];
      bb[x + ACM_OFFSET * 2] = ACM_FONT_3[c + 2];
      bb[x + ACM_OFFSET * 3] = ACM_FONT_3[c + 3];
      bb[x + ACM_OFFSET * 4] = ACM_FONT_3[c + 4];
      x++;
    }
  }  //acmDrawString3(int,int,char[])

}  //class ATCMonitor



