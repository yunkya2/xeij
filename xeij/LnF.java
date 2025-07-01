//========================================================================================
//  LnF.java
//    en:Look and feel
//    ja:ルックアンドフィール
//  Copyright (C) 2003-2024 Makoto Kamada
//
//  This file is part of the XEiJ (X68000 Emulator in Java).
//  You can use, modify and redistribute the XEiJ if the conditions are met.
//  Read the XEiJ License for more details.
//  https://stdkmd.net/xeij/
//========================================================================================

package xeij;

import java.awt.*;  //BasicStroke,BorderLayout,BoxLayout,Color,Component,Container,Cursor,Desktop,Dimension,Font,Frame,Graphics,Graphics2D,GraphicsDevice,GraphicsEnvironment,GridLayout,Image,Insets,Paint,Point,Rectangle,RenderingHints,Robot,Shape,Stroke,TexturePaint,Toolkit
import java.awt.image.*;  //BufferedImage,DataBuffer,DataBufferByte,DataBufferInt,IndexColorModel
import java.lang.*;  //Boolean,Character,Class,Comparable,Double,Exception,Float,IllegalArgumentException,Integer,Long,Math,Number,Object,Runnable,SecurityException,String,StringBuilder,System
import java.util.*;  //ArrayList,Arrays,Calendar,GregorianCalendar,HashMap,Map,Map.Entry,Timer,TimerTask,TreeMap
import javax.swing.*;  //AbstractSpinnerModel,Box,ButtonGroup,DefaultListModel,ImageIcon,JButton,JCheckBox,JCheckBoxMenuItem,JDialog,JFileChooser,JFrame,JLabel,JList,JMenu,JMenuBar,JMenuItem,JPanel,JRadioButton,JScrollPane,JSpinner,JTextArea,JTextField,JTextPane,JViewport,ScrollPaneConstants,SpinnerListModel,SpinnerNumberModel,SwingConstants,SwingUtilities,UIManager,UIDefaults,UnsupportedLookAndFeelException
import javax.swing.plaf.*;  //ColorUIResource,FontUIResource,IconUIResource,InsetsUIResource
import javax.swing.plaf.metal.*;  //MetalLookAndFeel,MetalTheme,OceanTheme

public class LnF {

  //色
  //  (0,y0),(7,y7),(14,y14)を通る2次関数
  //  y=(y0-2*y7+y14)/98*x^2+(-3*y0+4*y7-y14)/14*x+y0
  public static final int[][] LNF_HSB_INTERPOLATION_TABLE = {
    { 49, 0, 0 },  //x0=(49*y0)/49
    { 39, 13, -3 },  //x1=(39*y0+13*y7-3*y14)/49
    { 30, 24, -5 },  //x2=(30*y0+24*y7-5*y14)/49
    { 22, 33, -6 },  //x3=(22*y0+33*y7-6*y14)/49
    { 15, 40, -6 },  //x4=(15*y0+40*y7-6*y14)/49
    { 9, 45, -5 },  //x5=(9*y0+45*y7-5*y14)/49
    { 4, 48, -3 },  //x6=(4*y0+48*y7-3*y14)/49
    { 0, 49, 0 },  //x7=(49*y7)/49
    { -3, 48, 4 },  //x8=(-3*y0+48*y7+4*y14)/49
    { -5, 45, 9 },  //x9=(-5*y0+45*y7+9*y14)/49
    { -6, 40, 15 },  //x10=(-6*y0+40*y7+15*y14)/49
    { -6, 33, 22 },  //x11=(-6*y0+33*y7+22*y14)/49
    { -5, 24, 30 },  //x12=(-5*y0+24*y7+30*y14)/49
    { -3, 13, 39 },  //x13=(-3*y0+13*y7+39*y14)/49
    { 0, 0, 49 },  //x14=(49*y14)/49
  };
  public static final int[] LNF_DEFAULT_HSB = { 240, 240, 240, 70, 50, 30, 0, 50, 100 };
  public static final int[] lnfHSB = new int[9];  //h0,h7,h14,s0,s7,s14,b0,b7,b14
  public static final int[] lnfRGB = new int[15];  //rgb0,...,rgb14
  public static ColorUIResource lnfSecondary3;
  public static ColorUIResource lnfWhite;
  public static ColorUIResource lnfPrimary3;
  public static ColorUIResource lnfPrimary2;
  public static ColorUIResource lnfSecondary2;
  public static ColorUIResource lnfPrimary1;
  public static ColorUIResource lnfSecondary1;
  public static ColorUIResource lnfBlack;

  //フォント
  public static int lnfFontSizeRequest;
  public static int lnfFontSize;
  public static String[] lnfAvailableFontFamilyNames;
  public static String lnfMonospacedFamily;
  public static Font lnfMonospacedFont;
  public static Font lnfMonospacedFont12;
  public static FontUIResource lnfControlTextFontUIResource;
  public static FontUIResource lnfMenuTextFontUIResource;
  public static FontUIResource lnfSubTextFontUIResource;
  public static FontUIResource lnfSystemTextFontUIResource;
  public static FontUIResource lnfUserTextFontUIResource;
  public static FontUIResource lnfWindowTitleFontUIResource;

  //アイコン
  //  Xマークが左右にはみ出しているイメージ
  //  perl misc/favicon.pl
  public static final BufferedImage LNF_ICON_IMAGE_16 = XEiJ.createImage (
    16, 16,
    "................" +
    "1111111111.11111" +
    "1........1..1..." +
    ".1........1.1..." +
    ".1........1..1.." +
    "..1........1.1.1" +
    "..1........1..1." +
    "...1........1..." +
    "...1........1..." +
    ".1..1........1.." +
    "1.1.1........1.." +
    "..1..1........1." +
    "...1.1........1." +
    "...1..1........1" +
    "11111.1111111111" +
    "................",
    0xff000000,
    0xffffff00
    );
  public static final BufferedImage LNF_ICON_IMAGE_32 = XEiJ.createImage (
    32, 32,
    "................................" +
    "................................" +
    "1111111111111111111...1111111111" +
    "11111111111111111111..1111111111" +
    "11................11...11......." +
    ".11................11..111......" +
    ".11................11...11......" +
    "..11................11..111....." +
    "..11................11...11....." +
    "...11................11..111...1" +
    "...11................11...11..11" +
    "....11................11..111111" +
    "....11................11...1111." +
    ".....11................11..111.." +
    ".....11................11...1..." +
    "......11................11......" +
    "......11................11......" +
    "...1...11................11....." +
    "..111..11................11....." +
    ".1111...11................11...." +
    "111111..11................11...." +
    "11..11...11................11..." +
    "1...111..11................11..." +
    ".....11...11................11.." +
    ".....111..11................11.." +
    "......11...11................11." +
    "......111..11................11." +
    ".......11...11................11" +
    "1111111111..11111111111111111111" +
    "1111111111...1111111111111111111" +
    "................................" +
    "................................",
    0xff000000,
    0xffffff00
    );
  public static final BufferedImage LNF_ICON_IMAGE_48 = XEiJ.createImage (
    48, 48,
    "................................................" +
    "................................................" +
    "................................................" +
    "11111111111111111111111111111....111111111111111" +
    "11111111111111111111111111111....111111111111111" +
    "111111111111111111111111111111....11111111111111" +
    "111........................111....1111.........." +
    "1111........................111....111.........." +
    ".111........................111....1111........." +
    ".1111........................111....111........." +
    "..111........................111....1111........" +
    "..1111........................111....111........" +
    "...111........................111....1111......." +
    "...1111........................111....111......." +
    "....111........................111....1111.....1" +
    "....1111........................111....111....11" +
    ".....111........................111....1111..111" +
    ".....1111........................111....11111111" +
    "......111........................111....1111111." +
    "......1111........................111....11111.." +
    ".......111........................111....1111..." +
    ".......1111........................111....11...." +
    "........111........................111....1....." +
    "........1111........................111........." +
    ".........111........................111........." +
    ".....1...1111........................111........" +
    "....11....111........................111........" +
    "...1111...1111........................111......." +
    "..11111....111........................111......." +
    ".1111111...1111........................111......" +
    "11111111....111........................111......" +
    "111..1111...1111........................111....." +
    "11....111....111........................111....." +
    "1.....1111...1111........................111...." +
    ".......111....111........................111...." +
    ".......1111...1111........................111..." +
    "........111....111........................111..." +
    "........1111...1111........................111.." +
    ".........111....111........................111.." +
    ".........1111...1111........................111." +
    "..........111....111........................111." +
    "..........1111...1111........................111" +
    "11111111111111....111111111111111111111111111111" +
    "111111111111111...111111111111111111111111111111" +
    "111111111111111....11111111111111111111111111111" +
    "................................................" +
    "................................................" +
    "................................................",
    0xff000000,
    0xffffff00
    );
  public static final BufferedImage[] LNF_ICON_IMAGES = {
    LNF_ICON_IMAGE_16,
    LNF_ICON_IMAGE_32,
    LNF_ICON_IMAGE_48,
  };

  //アイコンのパターンとイメージ
  public static final String[] LNF_NUMBER_PATTERN_ARRAY = {
    (
      "22222222222222" +
      "2............2" +
      "2.1111111111.2" +
      "2.1111111111.2" +
      "2.11......11.2" +
      "2.11......11.2" +
      "2.11......11.2" +
      "2.11......11.2" +
      "2.11......11.2" +
      "2.11......11.2" +
      "2.1111111111.2" +
      "2.1111111111.2" +
      "2............2" +
      "22222222222222"),
    (
      "22222222222222" +
      "2............2" +
      "2.....11.....2" +
      "2.....11.....2" +
      "2.....11.....2" +
      "2.....11.....2" +
      "2.....11.....2" +
      "2.....11.....2" +
      "2.....11.....2" +
      "2.....11.....2" +
      "2.....11.....2" +
      "2.....11.....2" +
      "2............2" +
      "22222222222222"),
    (
      "22222222222222" +
      "2............2" +
      "2.1111111111.2" +
      "2.1111111111.2" +
      "2.........11.2" +
      "2.........11.2" +
      "2.1111111111.2" +
      "2.1111111111.2" +
      "2.11.........2" +
      "2.11.........2" +
      "2.1111111111.2" +
      "2.1111111111.2" +
      "2............2" +
      "22222222222222"),
    (
      "22222222222222" +
      "2............2" +
      "2.1111111111.2" +
      "2.1111111111.2" +
      "2.........11.2" +
      "2.........11.2" +
      "2.1111111111.2" +
      "2.1111111111.2" +
      "2.........11.2" +
      "2.........11.2" +
      "2.1111111111.2" +
      "2.1111111111.2" +
      "2............2" +
      "22222222222222"),
    (
      "22222222222222" +
      "2............2" +
      "2.11......11.2" +
      "2.11......11.2" +
      "2.11......11.2" +
      "2.11......11.2" +
      "2.1111111111.2" +
      "2.1111111111.2" +
      "2.........11.2" +
      "2.........11.2" +
      "2.........11.2" +
      "2.........11.2" +
      "2............2" +
      "22222222222222"),
    (
      "22222222222222" +
      "2............2" +
      "2.1111111111.2" +
      "2.1111111111.2" +
      "2.11.........2" +
      "2.11.........2" +
      "2.1111111111.2" +
      "2.1111111111.2" +
      "2.........11.2" +
      "2.........11.2" +
      "2.1111111111.2" +
      "2.1111111111.2" +
      "2............2" +
      "22222222222222"),
    (
      "22222222222222" +
      "2............2" +
      "2.1111111111.2" +
      "2.1111111111.2" +
      "2.11.........2" +
      "2.11.........2" +
      "2.1111111111.2" +
      "2.1111111111.2" +
      "2.11......11.2" +
      "2.11......11.2" +
      "2.1111111111.2" +
      "2.1111111111.2" +
      "2............2" +
      "22222222222222"),
    (
      "22222222222222" +
      "2............2" +
      "2.1111111111.2" +
      "2.1111111111.2" +
      "2.........11.2" +
      "2.........11.2" +
      "2.........11.2" +
      "2.........11.2" +
      "2.........11.2" +
      "2.........11.2" +
      "2.........11.2" +
      "2.........11.2" +
      "2............2" +
      "22222222222222"),
    (
      "22222222222222" +
      "2............2" +
      "2.1111111111.2" +
      "2.1111111111.2" +
      "2.11......11.2" +
      "2.11......11.2" +
      "2.1111111111.2" +
      "2.1111111111.2" +
      "2.11......11.2" +
      "2.11......11.2" +
      "2.1111111111.2" +
      "2.1111111111.2" +
      "2............2" +
      "22222222222222"),
    (
      "22222222222222" +
      "2............2" +
      "2.1111111111.2" +
      "2.1111111111.2" +
      "2.11......11.2" +
      "2.11......11.2" +
      "2.1111111111.2" +
      "2.1111111111.2" +
      "2.........11.2" +
      "2.........11.2" +
      "2.1111111111.2" +
      "2.1111111111.2" +
      "2............2" +
      "22222222222222"),
    (
      "22222222222222" +
      "2............2" +
      "2.11.1111111.2" +
      "2.11.1111111.2" +
      "2.11.11...11.2" +
      "2.11.11...11.2" +
      "2.11.11...11.2" +
      "2.11.11...11.2" +
      "2.11.11...11.2" +
      "2.11.11...11.2" +
      "2.11.1111111.2" +
      "2.11.1111111.2" +
      "2............2" +
      "22222222222222"),
    (
      "22222222222222" +
      "2............2" +
      "2..11....11..2" +
      "2..11....11..2" +
      "2..11....11..2" +
      "2..11....11..2" +
      "2..11....11..2" +
      "2..11....11..2" +
      "2..11....11..2" +
      "2..11....11..2" +
      "2..11....11..2" +
      "2..11....11..2" +
      "2............2" +
      "22222222222222"),
    (
      "22222222222222" +
      "2............2" +
      "2.11.1111111.2" +
      "2.11.1111111.2" +
      "2.11......11.2" +
      "2.11......11.2" +
      "2.11.1111111.2" +
      "2.11.1111111.2" +
      "2.11.11......2" +
      "2.11.11......2" +
      "2.11.1111111.2" +
      "2.11.1111111.2" +
      "2............2" +
      "22222222222222"),
    (
      "22222222222222" +
      "2............2" +
      "2.11.1111111.2" +
      "2.11.1111111.2" +
      "2.11......11.2" +
      "2.11......11.2" +
      "2.11.1111111.2" +
      "2.11.1111111.2" +
      "2.11......11.2" +
      "2.11......11.2" +
      "2.11.1111111.2" +
      "2.11.1111111.2" +
      "2............2" +
      "22222222222222"),
    (
      "22222222222222" +
      "2............2" +
      "2.11.11...11.2" +
      "2.11.11...11.2" +
      "2.11.11...11.2" +
      "2.11.11...11.2" +
      "2.11.1111111.2" +
      "2.11.1111111.2" +
      "2.11......11.2" +
      "2.11......11.2" +
      "2.11......11.2" +
      "2.11......11.2" +
      "2............2" +
      "22222222222222"),
    (
      "22222222222222" +
      "2............2" +
      "2.11.1111111.2" +
      "2.11.1111111.2" +
      "2.11.11......2" +
      "2.11.11......2" +
      "2.11.1111111.2" +
      "2.11.1111111.2" +
      "2.11......11.2" +
      "2.11......11.2" +
      "2.11.1111111.2" +
      "2.11.1111111.2" +
      "2............2" +
      "22222222222222"),
  };
  public static final Image[] LNF_NUMBER_IMAGE_ARRAY = new Image[LNF_NUMBER_PATTERN_ARRAY.length];
  public static final Image[] LNF_NUMBER_SELECTED_IMAGE_ARRAY = new Image[LNF_NUMBER_PATTERN_ARRAY.length];

  public static final String LNF_EJECT_PATTERN = (
    ".............." +
    "......11......" +
    ".....1..1....." +
    "....1....1...." +
    "...1......1..." +
    "..1........1.." +
    ".1..........1." +
    ".1..........1." +
    ".111111111111." +
    ".............." +
    ".111111111111." +
    ".1..........1." +
    ".1..........1." +
    ".111111111111.");
  public static Image LNF_EJECT_IMAGE;
  public static Image LNF_EJECT_DISABLED_IMAGE;

  public static final String LNF_OPEN_PATTERN = (
    "...11111111111" +
    "...1.........1" +
    "...1.........1" +
    "11111111111..1" +
    "1.........1..1" +
    "1.........1..1" +
    "1.........1..1" +
    "1.........1..1" +
    "1.........1..1" +
    "1.........1..1" +
    "1.........1111" +
    "1.........1..." +
    "1.........1..." +
    "11111111111...");
  public static Image LNF_OPEN_IMAGE;
  public static Image LNF_OPEN_DISABLED_IMAGE;

  public static final String LNF_PROTECT_PATTERN = (
    "11111111111111" +
    "1............1" +
    "1..........111" +
    "1..........1.." +
    "1..........1.." +
    "1.....11...111" +
    "1....1..1....1" +
    "1....1..1....1" +
    "1.....11.....1" +
    "1.....11.....1" +
    "1.....11.....1" +
    "1.....11.....1" +
    "1.....11.....1" +
    "11111111111111");
  public static Image LNF_PROTECT_IMAGE;
  public static Image LNF_PROTECT_DISABLED_IMAGE;

  public static final String LNF_PROTECT_SELECTED_PATTERN = (
    "11111111111111" +
    "1............1" +
    "1............1" +
    "1............1" +
    "1............1" +
    "1.....11.....1" +
    "1....1..1....1" +
    "1....1..1....1" +
    "1.....11.....1" +
    "1.....11.....1" +
    "1.....11.....1" +
    "1.....11.....1" +
    "1.....11.....1" +
    "11111111111111");
  public static Image LNF_PROTECT_SELECTED_IMAGE;
  public static Image LNF_PROTECT_DISABLED_SELECTED_IMAGE;

  public static final String LNF_HD_PATTERN = (
    ".............." +
    "....111111...." +
    ".111......111." +
    "1............1" +
    "1............1" +
    ".111......111." +
    "1...111111...1" +
    "1............1" +
    ".111......111." +
    "1...111111...1" +
    "1............1" +
    ".111......111." +
    "....111111...." +
    "..............");
  public static ImageIcon LNF_HD_ICON;
  public static ImageIcon LNF_HD_DISABLED_ICON;

  public static final String LNF_MO_PATTERN = (
    "...11111111111" +
    "..1..........1" +
    ".1...1111....1" +
    "1...1....1...1" +
    "1..1......1..1" +
    "1.1...11...1.1" +
    "1.1..1..1..1.1" +
    "1.1..1..1..1.1" +
    "1.1...11...1.1" +
    "1..1......1..1" +
    "1...1....1...1" +
    "1....1111....1" +
    "1............1" +
    "11111111111111");
  public static ImageIcon LNF_MO_ICON;
  public static ImageIcon LNF_MO_DISABLED_ICON;

  public static final String LNF_CD_PATTERN = (
    ".....1111....." +
    "...11....11..." +
    "..1........1.." +
    ".1..........1." +
    ".1....11....1." +
    "1....1..1....1" +
    "1...1....1...1" +
    "1...1....1...1" +
    "1....1..1....1" +
    ".1....11....1." +
    ".1..........1." +
    "..1........1.." +
    "...11....11..." +
    ".....1111.....");
  public static ImageIcon LNF_CD_ICON;
  public static ImageIcon LNF_CD_DISABLED_ICON;

  public static final String LNF_BREAK_PATTERN = (
    "11111111111111111111" +
    "1..................1" +
    "1....11......11....1" +
    "1....111....111....1" +
    "1.....111..111.....1" +
    "1......111111......1" +
    "1.......1111.......1" +
    "1.......1111.......1" +
    "1......111111......1" +
    "1.....111..111.....1" +
    "1....111....111....1" +
    "1....11......11....1" +
    "1..................1" +
    "11111111111111111111"
    );
  public static Image LNF_BREAK_IMAGE;
  public static Image LNF_BREAK_DISABLED_IMAGE;

  public static final String LNF_TRACE_PATTERN = (
    "11111111111111111111" +
    "1..................1" +
    "1..................1" +
    "1....11111.........1" +
    "1....11111.........1" +
    "1.......11.........1" +
    "1.......11...1.....1" +
    "1.......11...11....1" +
    "1.......11111111...1" +
    "1.......11111111...1" +
    "1............11....1" +
    "1............1.....1" +
    "1..................1" +
    "11111111111111111111"
    );
  public static Image LNF_TRACE_IMAGE;
  public static Image LNF_TRACE_DISABLED_IMAGE;

  public static final String LNF_TRACE_10_PATTERN = (
    "11111111111111111111" +
    "1..................1" +
    "1..................1" +
    "1.........1.11111..1" +
    "1.........1.1...1..1" +
    "1..111....1.1...1..1" +
    "1....1....1.1...1..1" +
    "1....1.1..1.1...1..1" +
    "1....1111.1.1...1..1" +
    "1......1..1.1...1..1" +
    "1.........1.11111..1" +
    "1..................1" +
    "1..................1" +
    "11111111111111111111"
    );
  public static Image LNF_TRACE_10_IMAGE;
  public static Image LNF_TRACE_10_DISABLED_IMAGE;

  public static final String LNF_TRACE_100_PATTERN = (
    "11111111111111111111" +
    "1..................1" +
    "1..................1" +
    "1........1.111.111.1" +
    "1........1.1.1.1.1.1" +
    "1.111....1.1.1.1.1.1" +
    "1...1....1.1.1.1.1.1" +
    "1...1.1..1.1.1.1.1.1" +
    "1...1111.1.1.1.1.1.1" +
    "1.....1..1.1.1.1.1.1" +
    "1........1.111.111.1" +
    "1..................1" +
    "1..................1" +
    "11111111111111111111"
    );
  public static Image LNF_TRACE_100_IMAGE;
  public static Image LNF_TRACE_100_DISABLED_IMAGE;

  public static final String LNF_STEP_PATTERN = (
    "11111111111111111111" +
    "1..................1" +
    "1..................1" +
    "1.....111111.......1" +
    "1.....111111.......1" +
    "1.....11..11.......1" +
    "1.....11..11..1....1" +
    "1.....11..11..11...1" +
    "1...1111..1111111..1" +
    "1...1111..1111111..1" +
    "1.............11...1" +
    "1.............1....1" +
    "1..................1" +
    "11111111111111111111"
    );
  public static Image LNF_STEP_IMAGE;
  public static Image LNF_STEP_DISABLED_IMAGE;

  public static final String LNF_STEP_10_PATTERN = (
    "11111111111111111111" +
    "1..................1" +
    "1..................1" +
    "1.........1.11111..1" +
    "1.........1.1...1..1" +
    "1..111....1.1...1..1" +
    "1..1.1....1.1...1..1" +
    "1..1.1.1..1.1...1..1" +
    "1..1.1111.1.1...1..1" +
    "1......1..1.1...1..1" +
    "1.........1.11111..1" +
    "1..................1" +
    "1..................1" +
    "11111111111111111111"
    );
  public static Image LNF_STEP_10_IMAGE;
  public static Image LNF_STEP_10_DISABLED_IMAGE;

  public static final String LNF_STEP_100_PATTERN = (
    "11111111111111111111" +
    "1..................1" +
    "1..................1" +
    "1........1.111.111.1" +
    "1........1.1.1.1.1.1" +
    "1.111....1.1.1.1.1.1" +
    "1.1.1....1.1.1.1.1.1" +
    "1.1.1.1..1.1.1.1.1.1" +
    "1.1.1111.1.1.1.1.1.1" +
    "1.....1..1.1.1.1.1.1" +
    "1........1.111.111.1" +
    "1..................1" +
    "1..................1" +
    "11111111111111111111"
    );
  public static Image LNF_STEP_100_IMAGE;
  public static Image LNF_STEP_100_DISABLED_IMAGE;

  public static final String LNF_STEP_UNTIL_RETURN_PATTERN = (
    "11111111111111111111" +
    "1..................1" +
    "1........1.........1" +
    "1.......11.........1" +
    "1......11111111....1" +
    "1......11111111....1" +
    "1.......11...11....1" +
    "1........1...11....1" +
    "1............11....1" +
    "1....1111111111....1" +
    "1....1111111111....1" +
    "1..................1" +
    "1..................1" +
    "11111111111111111111"
    );
  public static Image LNF_STEP_UNTIL_RETURN_IMAGE;
  public static Image LNF_STEP_UNTIL_RETURN_DISABLED_IMAGE;

  public static final String LNF_RUN_PATTERN = (
    "11111111111111111111" +
    "1..................1" +
    "1........11........1" +
    "1........111.......1" +
    "1.........111......1" +
    "1..........111.....1" +
    "1....1111111111....1" +
    "1....1111111111....1" +
    "1..........111.....1" +
    "1.........111......1" +
    "1........111.......1" +
    "1........11........1" +
    "1..................1" +
    "11111111111111111111"
    );
  public static Image LNF_RUN_IMAGE;
  public static Image LNF_RUN_DISABLED_IMAGE;

  public static final String LNF_CLEAR_PATTERN = (
    "11111111111111111111" +
    "1..................1" +
    "1....1111111111....1" +
    "1....1........1....1" +
    "1....1.11.....1....1" +
    "1....11..1....1....1" +
    "1....1.11.1..1.....1" +
    "1.....1..1.11.1....1" +
    "1....1....1..11....1" +
    "1....1.....11.1....1" +
    "1....1........1....1" +
    "1....1111111111....1" +
    "1..................1" +
    "11111111111111111111"
    );
  public static Image LNF_CLEAR_IMAGE;
  public static Image LNF_CLEAR_DISABLED_IMAGE;

  public static final String LNF_OLDEST_PATTERN = (
    "11111111111111111111" +
    "1..................1" +
    "1.1111....11....11.1" +
    "1.1..1...1.1...1.1.1" +
    "1.1..1..1..1..1..1.1" +
    "1.1..1.1...1.1...1.1" +
    "1.1..11....11....1.1" +
    "1.1..11....11....1.1" +
    "1.1..1.1...1.1...1.1" +
    "1.1..1..1..1..1..1.1" +
    "1.1..1...1.1...1.1.1" +
    "1.1111....11....11.1" +
    "1..................1" +
    "11111111111111111111"
    );
  public static Image LNF_OLDEST_IMAGE;
  public static Image LNF_OLDEST_DISABLED_IMAGE;

  public static final String LNF_OLDER_PATTERN = (
    "11111111111111111111" +
    "1..................1" +
    "1.......11....11...1" +
    "1......1.1...1.1...1" +
    "1.....1..1..1..1...1" +
    "1....1...1.1...1...1" +
    "1...1....11....1...1" +
    "1...1....11....1...1" +
    "1....1...1.1...1...1" +
    "1.....1..1..1..1...1" +
    "1......1.1...1.1...1" +
    "1.......11....11...1" +
    "1..................1" +
    "11111111111111111111"
    );
  public static Image LNF_OLDER_IMAGE;
  public static Image LNF_OLDER_DISABLED_IMAGE;

  public static final String LNF_PREVIOUS_PATTERN = (
    "11111111111111111111" +
    "1..................1" +
    "1..........11......1" +
    "1.........1.1......1" +
    "1........1..1......1" +
    "1.......1...1......1" +
    "1......1....1......1" +
    "1......1....1......1" +
    "1.......1...1......1" +
    "1........1..1......1" +
    "1.........1.1......1" +
    "1..........11......1" +
    "1..................1" +
    "11111111111111111111"
    );
  public static Image LNF_PREVIOUS_IMAGE;
  public static Image LNF_PREVIOUS_DISABLED_IMAGE;

  public static final String LNF_NEXT_PATTERN = (
    "11111111111111111111" +
    "1..................1" +
    "1......11..........1" +
    "1......1.1.........1" +
    "1......1..1........1" +
    "1......1...1.......1" +
    "1......1....1......1" +
    "1......1....1......1" +
    "1......1...1.......1" +
    "1......1..1........1" +
    "1......1.1.........1" +
    "1......11..........1" +
    "1..................1" +
    "11111111111111111111"
    );
  public static Image LNF_NEXT_IMAGE;
  public static Image LNF_NEXT_DISABLED_IMAGE;

  public static final String LNF_NEWER_PATTERN = (
    "11111111111111111111" +
    "1..................1" +
    "1...11....11.......1" +
    "1...1.1...1.1......1" +
    "1...1..1..1..1.....1" +
    "1...1...1.1...1....1" +
    "1...1....11....1...1" +
    "1...1....11....1...1" +
    "1...1...1.1...1....1" +
    "1...1..1..1..1.....1" +
    "1...1.1...1.1......1" +
    "1...11....11.......1" +
    "1..................1" +
    "11111111111111111111"
    );
  public static Image LNF_NEWER_IMAGE;
  public static Image LNF_NEWER_DISABLED_IMAGE;

  public static final String LNF_NEWEST_PATTERN = (
    "11111111111111111111" +
    "1..................1" +
    "1.11....11....1111.1" +
    "1.1.1...1.1...1..1.1" +
    "1.1..1..1..1..1..1.1" +
    "1.1...1.1...1.1..1.1" +
    "1.1....11....11..1.1" +
    "1.1....11....11..1.1" +
    "1.1...1.1...1.1..1.1" +
    "1.1..1..1..1..1..1.1" +
    "1.1.1...1.1...1..1.1" +
    "1.11....11....1111.1" +
    "1..................1" +
    "11111111111111111111"
    );
  public static Image LNF_NEWEST_IMAGE;
  public static Image LNF_NEWEST_DISABLED_IMAGE;

  public static final String LNF_ORI_BYTE_ZERO_D0_PATTERN = (
    "22222222222222222222" +
    "2..................2" +
    "2..................2" +
    "2...1111....1111...2" +
    "2..1....1..1....1..2" +
    "2..1...11..1...11..2" +
    "2..1..1.1..1..1.1..2" +
    "2..1.1..1..1.1..1..2" +
    "2..11...1..11...1..2" +
    "2..1....1..1....1..2" +
    "2...1111....1111...2" +
    "2..................2" +
    "2..................2" +
    "22222222222222222222"
    );
  public static Image LNF_ORI_BYTE_ZERO_D0_IMAGE;
  public static Image LNF_ORI_BYTE_ZERO_D0_SELECTED_IMAGE;

  public static final String LNF_STOP_ON_ERROR_PATTERN = (
    "22222222222222222222" +
    "2..................2" +
    "2........11........2" +
    "2........11........2" +
    "2........11........2" +
    "2........11........2" +
    "2........11........2" +
    "2........11........2" +
    "2..................2" +
    "2..................2" +
    "2........11........2" +
    "2........11........2" +
    "2..................2" +
    "22222222222222222222"
    );
  public static Image LNF_STOP_ON_ERROR_IMAGE;
  public static Image LNF_STOP_ON_ERROR_SELECTED_IMAGE;

  public static final String LNF_STOP_AT_START_PATTERN = (
    "22222222222222222222" +
    "2..................2" +
    "2..................2" +
    "2..............1...2" +
    "2.............11...2" +
    "2...1111.....1.1...2" +
    "2.......1...1..1...2" +
    "2...11111..1...1...2" +
    "2..1....1.1111111..2" +
    "2..1...11......1...2" +
    "2...111.11.....1...2" +
    "2..................2" +
    "2..................2" +
    "22222222222222222222"
    );
  public static Image LNF_STOP_AT_START_IMAGE;
  public static Image LNF_STOP_AT_START_SELECTED_IMAGE;

  //lnfInit ()
  //  Look&Feelを初期化する
  //  既存のコンポーネントのUIを切り替えると部分的に更新されず汚くなることがあるのでコンポーネントを作る前に行うこと
  //  既存のコンポーネントのUIを切り替える方法
  //    SwingUtilities.updateComponentTreeUI (rootPaneContainer.getRootPane ());
  public static void lnfInit () {

    if (false) {
      //利用可能なすべてのLook&Feelを表示する
      //  UIManager.setLookAndFeel(info.getClassName())とするとLook&Feelが変更される
      //  Metal以外はJavaのバージョンによって位置が異なる場合があるらしい
      System.out.println ("\n[UIManager.getInstalledLookAndFeels()]");
      for (UIManager.LookAndFeelInfo info : UIManager.getInstalledLookAndFeels ()) {
        System.out.println ("        //  " + info.getName () + " = " + info.getClassName ());
        //  Metal = javax.swing.plaf.metal.MetalLookAndFeel
        //  Nimbus = javax.swing.plaf.nimbus.NimbusLookAndFeel
        //  CDE/Motif = com.sun.java.swing.plaf.motif.MotifLookAndFeel
        //  Windows = com.sun.java.swing.plaf.windows.WindowsLookAndFeel
        //  Windows Classic = com.sun.java.swing.plaf.windows.WindowsClassicLookAndFeel
      }
    }

    if (false) {
      //UIDefaultsをダンプする
      System.out.println ("\n[UIManager.getDefaults()]");
      TreeMap<String,String> m = new TreeMap<String,String> ();
      //UIManager.getDefaults ().forEach ((k, v) -> m.put (k.toString (), v.toString ()));  //UIManager.getDefaults()はHashtable<Object,Object>
      //なぜかUIManager.getDefaults().forEach(BiConsumer)がBiConsumerを1回も呼び出さずに終了してしまう
      for (Map.Entry<Object,Object> e : UIManager.getDefaults ().entrySet ()) {
        m.put (e.getKey ().toString (), e.getValue ().toString ());
      }
      m.forEach ((k, v) -> System.out.println (k + " = " + v));
    }

    //色
    //  以下の順序で明るさを変化させると綺麗に見える
    //  secondary3  アクティブでないウインドウのタイトルバーとメニューバーとコンテンツの背景
    //    control                        コントロール・カラー
    //    menuBackground                 メニューのバックグラウンド・カラー
    //    windowTitleInactiveBackground  アクティブでないウィンドウ・タイトルのバックグラウンド・カラー
    //  white       ウインドウのタイトルバーのドットとクローズボタンなどの溝とメニューのボーダーの明るい部分
    //    controlHighlight               コントロール・ハイライト・カラー
    //    primaryControlHighlight        一次コントロール・ハイライト・カラー
    //    separatorBackground            セパレータのバックグラウンド・カラー
    //    white                          白
    //    windowBackground               ウィンドウのバックグラウンド・カラー
    //  primary3    アクティブなウインドウのタイトルバーの背景
    //    primaryControl                 一次コントロール・カラー
    //    textHighlightColor             テキスト・ハイライト・カラー
    //    windowTitleBackground          ウィンドウ・タイトルのバックグラウンド・カラー
    //  primary2    アクティブなウインドウの枠の溝の明るい部分とメニューバーの上のボーダーと選択されているメニューの背景
    //    desktopColor                   デスクトップ・カラー
    //    focusColor                     フォーカス・カラー
    //    menuSelectedBackground         選択されたメニューのバックグラウンド・カラー
    //    primaryControlShadow           一次コントロール・シャドウ・カラー
    //  secondary2  アクティブでないウインドウの枠の溝の明るい部分とメニューバーの上のボーダーとメニューバーの下のボーダー
    //    controlDisabled                無効なコントロールのコントロール・カラー
    //    controlShadow                  コントロール・シャドウ・カラー
    //    inactiveControlTextColor       アクティブでないコントロール・テキスト・カラー
    //    inactiveSystemTextColor        アクティブでないシステム・テキスト・カラー
    //    menuDisabledForeground         無効なメニューのフォアグラウンド・カラー
    //  primary1    アクティブなウインドウの枠とクローズボタンなどの溝の底
    //    acceleratorForeground          アクセラレータのフォアグラウンド・カラー
    //    primaryControlDarkShadow       一次コントロール・ダーク・シャドウ・カラー
    //    separatorForeground            セパレータのフォアグラウンド・カラー
    //  secondary1  アクティブでないウインドウの枠とクローズボタンなどの溝の底とタイトルバーのドットの暗い部分
    //    controlDarkShadow              コントロール・ダーク・シャドウ・カラー
    //  black       ウインドウの枠とクローズボタンなどの溝の暗い部分とタイトルバーの文字とメニューの文字
    //    acceleratorSelectedForeground  選択されたアクセラレータのフォアグラウンド・カラー
    //    black                          黒
    //    controlInfo                    制御情報カラー
    //    controlTextColor               コントロール・テキスト・カラー
    //    highlightedTextColor           ハイライト・テキストのテキスト・カラー
    //    menuForeground                 メニューのフォアグラウンド・カラー
    //    menuSelectedForeground         選択されたメニューのフォアグラウンド・カラー
    //    primaryControlInfo             一次制御情報カラー
    //    systemTextColor                システム・テキスト・カラー
    //    userTextColor                  ユーザー・テキスト・カラー
    //    windowTitleForeground          ウィンドウ・タイトルのフォアグラウンド・カラー
    //    windowTitleInactiveForeground  アクティブでないウィンドウ・タイトルのフォアグラウンド・カラー
    {
      int[] a = Settings.sgsGetIntArray ("hhssbb", -1, -1);
      boolean ok = a.length == 6;
      for (int i = 0; ok && i < 6; i++) {
        ok = 0 <= a[i] && a[i] <= (i < 2 ? 2000 : 1000);
      }
      if (ok) {
        for (int i = 0; i < 3; i++) {
          lnfHSB[3 * i    ] = (a[2 * i    ] * (i == 0 ? 360 : 100) + 500) / 1000;
          lnfHSB[3 * i + 2] = (a[2 * i + 1] * (i == 0 ? 360 : 100) + 500) / 1000;
          lnfHSB[3 * i + 1] = (lnfHSB[3 * i    ] +
                               lnfHSB[3 * i + 2]) / 2;
        }
      } else {
        a = Settings.sgsGetIntArray ("hsb", -1, -1);
        ok = a.length == 9;
        for (int i = 0; ok && i < 9; i++) {
          ok = 0 <= a[i] && a[i] <= (i < 3 ? 720 : 100);
        }
        System.arraycopy (ok ? a : LNF_DEFAULT_HSB, 0, lnfHSB, 0, 9);
      }
    }
    for (int i = 0; i <= 14; i++) {
      int[] t = LNF_HSB_INTERPOLATION_TABLE[i];
      float h = (float) (t[0] * lnfHSB[0] + t[1] * lnfHSB[1] + t[2] * lnfHSB[2]) / (49.0F * 360.0F);
      float s = (float) (t[0] * lnfHSB[3] + t[1] * lnfHSB[4] + t[2] * lnfHSB[5]) / (49.0F * 100.0F);
      float b = (float) (t[0] * lnfHSB[6] + t[1] * lnfHSB[7] + t[2] * lnfHSB[8]) / (49.0F * 100.0F);
      lnfRGB[i] = Color.HSBtoRGB (h,
                                  Math.max (0.0F, Math.min (1.0F, s)),
                                  Math.max (0.0F, Math.min (1.0F, b)));
    }
    lnfSecondary3 = new ColorUIResource (lnfRGB[0]);
    lnfWhite      = new ColorUIResource (lnfRGB[2]);
    lnfPrimary3   = new ColorUIResource (lnfRGB[4]);
    lnfPrimary2   = new ColorUIResource (lnfRGB[6]);
    lnfSecondary2 = new ColorUIResource (lnfRGB[8]);
    lnfPrimary1   = new ColorUIResource (lnfRGB[10]);
    lnfSecondary1 = new ColorUIResource (lnfRGB[12]);
    lnfBlack      = new ColorUIResource (lnfRGB[14]);

    //フォント
    //  フォントサイズを変更できるようにする
    lnfFontSizeRequest = Math.max (10, Math.min (18, Settings.sgsGetInt ("fontsize", 14))) & -2;  //10,12,14,16,18
    lnfFontSize = lnfFontSizeRequest;
    //  "Monospaced"を"ＭＳ ゴシック"にする
    //  /lib/fontconfig.properties.src
    //  の
    //  monospaced.plain.japanese=MS Gothic
    //  は変わっていないが"MS Gothic"が通らなくなったらしい
    //  "ＭＳ ゴシック"は通る
    //  スマートな修正方法が思いつかなかったので面倒だが全部書き換える
    lnfAvailableFontFamilyNames = GraphicsEnvironment.getLocalGraphicsEnvironment ().getAvailableFontFamilyNames ();
    lnfMonospacedFamily = (Arrays.asList (lnfAvailableFontFamilyNames).contains ("ＭＳ ゴシック") ? "ＭＳ ゴシック" :
                           "Monospaced");
    lnfMonospacedFont = new Font (lnfMonospacedFamily, Font.PLAIN, lnfFontSize);
    lnfMonospacedFont12 = new Font (lnfMonospacedFamily, Font.PLAIN, 12);
    //  日本語はボールドにすると読みにくいのでプレーンにする
    //  ControlTextFont=javax.swing.plaf.FontUIResource[family=Dialog,name=Dialog,style=bold,size=12]
    //  MenuTextFont=javax.swing.plaf.FontUIResource[family=Dialog,name=Dialog,style=bold,size=12]
    //  SubTextFont=javax.swing.plaf.FontUIResource[family=Dialog,name=Dialog,style=plain,size=10]
    //  SystemTextFont=javax.swing.plaf.FontUIResource[family=Dialog,name=Dialog,style=plain,size=12]
    //  UserTextFont=javax.swing.plaf.FontUIResource[family=Dialog,name=Dialog,style=plain,size=12]
    //  WindowTitleFont=javax.swing.plaf.FontUIResource[family=Dialog,name=Dialog,style=bold,size=12]
    lnfControlTextFontUIResource = new FontUIResource ("Dialog", Font.PLAIN, lnfFontSize);
    lnfMenuTextFontUIResource = new FontUIResource ("Dialog", Font.PLAIN, lnfFontSize);
    lnfSubTextFontUIResource = new FontUIResource ("Dialog", Font.PLAIN, lnfFontSize * 5 / 6);
    lnfSystemTextFontUIResource = new FontUIResource ("Dialog", Font.PLAIN, lnfFontSize);
    lnfUserTextFontUIResource = new FontUIResource ("Dialog", Font.PLAIN, lnfFontSize);
    lnfWindowTitleFontUIResource = new FontUIResource ("Dialog", Font.PLAIN, lnfFontSize);

    //Look&Feel
    JFrame.setDefaultLookAndFeelDecorated (true);
    JDialog.setDefaultLookAndFeelDecorated (true);
    MetalLookAndFeel.setCurrentTheme (new XEiJTheme ());
    try {
      UIManager.setLookAndFeel (new MetalLookAndFeel ());
    } catch (UnsupportedLookAndFeelException ulafe) {
    }

    //アイコン
    for (int i = 0; i < LNF_NUMBER_PATTERN_ARRAY.length; i++) {
      LNF_NUMBER_IMAGE_ARRAY[i] = XEiJ.createImage (14, 14, LNF_NUMBER_PATTERN_ARRAY[i], lnfRGB[0], lnfRGB[12], lnfRGB[0]);
      LNF_NUMBER_SELECTED_IMAGE_ARRAY[i] = XEiJ.createImage (14, 14, LNF_NUMBER_PATTERN_ARRAY[i], lnfRGB[0], lnfRGB[12], lnfRGB[12]);
    }

    LNF_EJECT_IMAGE = XEiJ.createImage (14, 14, LNF_EJECT_PATTERN, lnfRGB[0], lnfRGB[12]);
    LNF_EJECT_DISABLED_IMAGE = XEiJ.createImage (14, 14, LNF_EJECT_PATTERN, lnfRGB[0], lnfRGB[6]);

    LNF_OPEN_IMAGE = XEiJ.createImage (14, 14, LNF_OPEN_PATTERN, lnfRGB[0], lnfRGB[12]);
    LNF_OPEN_DISABLED_IMAGE = XEiJ.createImage (14, 14, LNF_OPEN_PATTERN, lnfRGB[0], lnfRGB[6]);

    LNF_PROTECT_IMAGE = XEiJ.createImage (14, 14, LNF_PROTECT_PATTERN, lnfRGB[0], lnfRGB[12]);
    LNF_PROTECT_DISABLED_IMAGE = XEiJ.createImage (14, 14, LNF_PROTECT_PATTERN, lnfRGB[0], lnfRGB[6]);
    LNF_PROTECT_SELECTED_IMAGE = XEiJ.createImage (14, 14, LNF_PROTECT_SELECTED_PATTERN, lnfRGB[0], lnfRGB[12]);
    LNF_PROTECT_DISABLED_SELECTED_IMAGE = XEiJ.createImage (14, 14, LNF_PROTECT_SELECTED_PATTERN, lnfRGB[0], lnfRGB[6]);

    LNF_HD_ICON = new ImageIcon (XEiJ.createImage (14, 14, LNF_HD_PATTERN, lnfRGB[0], lnfRGB[12]));
    LNF_HD_DISABLED_ICON = new ImageIcon (XEiJ.createImage (14, 14, LNF_HD_PATTERN, lnfRGB[0], lnfRGB[6]));

    LNF_MO_ICON = new ImageIcon (XEiJ.createImage (14, 14, LNF_MO_PATTERN, lnfRGB[0], lnfRGB[12]));
    LNF_MO_DISABLED_ICON = new ImageIcon (XEiJ.createImage (14, 14, LNF_MO_PATTERN, lnfRGB[0], lnfRGB[6]));

    LNF_CD_ICON = new ImageIcon (XEiJ.createImage (14, 14, LNF_CD_PATTERN, lnfRGB[0], lnfRGB[12]));
    LNF_CD_DISABLED_ICON = new ImageIcon (XEiJ.createImage (14, 14, LNF_CD_PATTERN, lnfRGB[0], lnfRGB[6]));

    LNF_BREAK_IMAGE = XEiJ.createImage (20, 14, LNF_BREAK_PATTERN, lnfRGB[0], lnfRGB[12]);
    LNF_BREAK_DISABLED_IMAGE= XEiJ.createImage (20, 14, LNF_BREAK_PATTERN, lnfRGB[0], lnfRGB[6]);

    LNF_TRACE_IMAGE = XEiJ.createImage (20, 14, LNF_TRACE_PATTERN, lnfRGB[0], lnfRGB[12]);
    LNF_TRACE_DISABLED_IMAGE= XEiJ.createImage (20, 14, LNF_TRACE_PATTERN, lnfRGB[0], lnfRGB[6]);

    LNF_TRACE_10_IMAGE = XEiJ.createImage (20, 14, LNF_TRACE_10_PATTERN, lnfRGB[0], lnfRGB[12]);
    LNF_TRACE_10_DISABLED_IMAGE= XEiJ.createImage (20, 14, LNF_TRACE_10_PATTERN, lnfRGB[0], lnfRGB[6]);

    LNF_TRACE_100_IMAGE = XEiJ.createImage (20, 14, LNF_TRACE_100_PATTERN, lnfRGB[0], lnfRGB[12]);
    LNF_TRACE_100_DISABLED_IMAGE= XEiJ.createImage (20, 14, LNF_TRACE_100_PATTERN, lnfRGB[0], lnfRGB[6]);

    LNF_STEP_IMAGE = XEiJ.createImage (20, 14, LNF_STEP_PATTERN, lnfRGB[0], lnfRGB[12]);
    LNF_STEP_DISABLED_IMAGE= XEiJ.createImage (20, 14, LNF_STEP_PATTERN, lnfRGB[0], lnfRGB[6]);

    LNF_STEP_10_IMAGE = XEiJ.createImage (20, 14, LNF_STEP_10_PATTERN, lnfRGB[0], lnfRGB[12]);
    LNF_STEP_10_DISABLED_IMAGE= XEiJ.createImage (20, 14, LNF_STEP_10_PATTERN, lnfRGB[0], lnfRGB[6]);

    LNF_STEP_100_IMAGE = XEiJ.createImage (20, 14, LNF_STEP_100_PATTERN, lnfRGB[0], lnfRGB[12]);
    LNF_STEP_100_DISABLED_IMAGE= XEiJ.createImage (20, 14, LNF_STEP_100_PATTERN, lnfRGB[0], lnfRGB[6]);

    LNF_STEP_UNTIL_RETURN_IMAGE = XEiJ.createImage (20, 14, LNF_STEP_UNTIL_RETURN_PATTERN, lnfRGB[0], lnfRGB[12]);
    LNF_STEP_UNTIL_RETURN_DISABLED_IMAGE= XEiJ.createImage (20, 14, LNF_STEP_UNTIL_RETURN_PATTERN, lnfRGB[0], lnfRGB[6]);

    LNF_RUN_IMAGE = XEiJ.createImage (20, 14, LNF_RUN_PATTERN, lnfRGB[0], lnfRGB[12]);
    LNF_RUN_DISABLED_IMAGE= XEiJ.createImage (20, 14, LNF_RUN_PATTERN, lnfRGB[0], lnfRGB[6]);

    LNF_CLEAR_IMAGE = XEiJ.createImage (20, 14, LNF_CLEAR_PATTERN, lnfRGB[0], lnfRGB[12]);
    LNF_CLEAR_DISABLED_IMAGE= XEiJ.createImage (20, 14, LNF_CLEAR_PATTERN, lnfRGB[0], lnfRGB[6]);

    LNF_OLDEST_IMAGE = XEiJ.createImage (20, 14, LNF_OLDEST_PATTERN, lnfRGB[0], lnfRGB[12]);
    LNF_OLDEST_DISABLED_IMAGE= XEiJ.createImage (20, 14, LNF_OLDEST_PATTERN, lnfRGB[0], lnfRGB[6]);

    LNF_OLDER_IMAGE = XEiJ.createImage (20, 14, LNF_OLDER_PATTERN, lnfRGB[0], lnfRGB[12]);
    LNF_OLDER_DISABLED_IMAGE= XEiJ.createImage (20, 14, LNF_OLDER_PATTERN, lnfRGB[0], lnfRGB[6]);

    LNF_PREVIOUS_IMAGE = XEiJ.createImage (20, 14, LNF_PREVIOUS_PATTERN, lnfRGB[0], lnfRGB[12]);
    LNF_PREVIOUS_DISABLED_IMAGE= XEiJ.createImage (20, 14, LNF_PREVIOUS_PATTERN, lnfRGB[0], lnfRGB[6]);

    LNF_NEXT_IMAGE = XEiJ.createImage (20, 14, LNF_NEXT_PATTERN, lnfRGB[0], lnfRGB[12]);
    LNF_NEXT_DISABLED_IMAGE= XEiJ.createImage (20, 14, LNF_NEXT_PATTERN, lnfRGB[0], lnfRGB[6]);

    LNF_NEWER_IMAGE = XEiJ.createImage (20, 14, LNF_NEWER_PATTERN, lnfRGB[0], lnfRGB[12]);
    LNF_NEWER_DISABLED_IMAGE= XEiJ.createImage (20, 14, LNF_NEWER_PATTERN, lnfRGB[0], lnfRGB[6]);

    LNF_NEWEST_IMAGE = XEiJ.createImage (20, 14, LNF_NEWEST_PATTERN, lnfRGB[0], lnfRGB[12]);
    LNF_NEWEST_DISABLED_IMAGE= XEiJ.createImage (20, 14, LNF_NEWEST_PATTERN, lnfRGB[0], lnfRGB[6]);

    LNF_ORI_BYTE_ZERO_D0_IMAGE = XEiJ.createImage (20, 14, LNF_ORI_BYTE_ZERO_D0_PATTERN, lnfRGB[0], lnfRGB[6], lnfRGB[12]);
    LNF_ORI_BYTE_ZERO_D0_SELECTED_IMAGE= XEiJ.createImage (20, 14, LNF_ORI_BYTE_ZERO_D0_PATTERN, lnfRGB[0], lnfRGB[12], lnfRGB[12]);

    LNF_STOP_ON_ERROR_IMAGE = XEiJ.createImage (20, 14, LNF_STOP_ON_ERROR_PATTERN, lnfRGB[0], lnfRGB[6], lnfRGB[12]);
    LNF_STOP_ON_ERROR_SELECTED_IMAGE= XEiJ.createImage (20, 14, LNF_STOP_ON_ERROR_PATTERN, lnfRGB[0], lnfRGB[12], lnfRGB[12]);

    LNF_STOP_AT_START_IMAGE = XEiJ.createImage (20, 14, LNF_STOP_AT_START_PATTERN, lnfRGB[0], lnfRGB[6], lnfRGB[12]);
    LNF_STOP_AT_START_SELECTED_IMAGE= XEiJ.createImage (20, 14, LNF_STOP_AT_START_PATTERN, lnfRGB[0], lnfRGB[12], lnfRGB[12]);

  }  //lnfInit()

  //lnfTini ()
  //  後始末
  public static void lnfTini () {
    //色
    Settings.sgsPutIntArray ("hsb", lnfHSB, -1);
    Settings.sgsPutString ("hhssbb", "none");
    //フォントサイズ
    Settings.sgsPutInt ("fontsize", lnfFontSizeRequest);
  }



  //$$XET XEiJのテーマ
  public static class XEiJTheme extends MetalTheme {

    //名前
    @Override public String getName () {
      return "XEiJ";
    }  //getName()

    //色
    //  背景を黒にする
    //  以下の順序で明るさを変化させると綺麗に見える
    //  secondary3
    //    アクティブでないウインドウのタイトルバーの背景
    //    メニューバーの背景
    //    コンテンツの背景
    //  white
    //    ウインドウのタイトルバーのドットの明るい部分(左上)
    //    クローズボタンなどの溝の明るい部分
    //    メニューのボーダーの明るい部分
    //  primary3
    //    アクティブなウインドウのタイトルバーの背景
    //  primary2
    //    アクティブなウインドウの枠の溝の明るい部分
    //    アクティブなウインドウのメニューバーの上のボーダー
    //    選択されているメニューの背景
    //  secondary2
    //    アクティブでないウインドウの枠の溝の明るい部分
    //    アクティブでないウインドウのメニューバーの上のボーダー
    //    メニューバーの下のボーダー
    //  primary1
    //    アクティブなウインドウの枠
    //    アクティブなウインドウのクローズボタンなどの溝の底
    //  secondary1
    //    アクティブでないウインドウの枠
    //    アクティブでないウインドウのクローズボタンなどの溝の底
    //    アクティブでないウインドウのタイトルバーのドットの暗い部分(右下)
    //  black
    //    ウインドウの枠の溝の暗い部分
    //    クローズボタンなどの溝の暗い部分
    //    タイトルバーの文字
    //    メニューの文字
    @Override protected ColorUIResource getSecondary3 () {
      return lnfSecondary3;
    }  //getSecondary3()
    @Override protected ColorUIResource getWhite () {
      return lnfWhite;
    }  //getWhite()
    @Override protected ColorUIResource getPrimary3 () {
      return lnfPrimary3;
    }  //getPrimary3()
    @Override protected ColorUIResource getPrimary2 () {
      return lnfPrimary2;
    }  //getPrimary2()
    @Override protected ColorUIResource getSecondary2 () {
      return lnfSecondary2;
    }  //getSecondary2()
    @Override protected ColorUIResource getPrimary1 () {
      return lnfPrimary1;
    }  //getPrimary1()
    @Override protected ColorUIResource getSecondary1 () {
      return lnfSecondary1;
    }  //getSecondary1()
    @Override protected ColorUIResource getBlack () {
      return lnfBlack;
    }  //getBlack()

    //フォント
    @Override public FontUIResource getControlTextFont () {
      return lnfControlTextFontUIResource;
    }  //getControlTextFont()
    @Override public FontUIResource getMenuTextFont () {
      return lnfMenuTextFontUIResource;
    }  //getMenuTextFont()
    @Override public FontUIResource getSubTextFont () {
      return lnfSubTextFontUIResource;
    }  //getSubTextFont()
    @Override public FontUIResource getSystemTextFont () {
      return lnfSystemTextFontUIResource;
    }  //getSystemTextFont()
    @Override public FontUIResource getUserTextFont () {
      return lnfUserTextFontUIResource;
    }  //getUserTextFont()
    @Override public FontUIResource getWindowTitleFont () {
      return lnfWindowTitleFontUIResource;
    }  //getWindowTitleFont()

    //カスタム
    @Override public void addCustomEntriesToTable (UIDefaults table) {
      super.addCustomEntriesToTable (table);
      table.putDefaults (new Object[] {
        //ボタン
        //  隙間を詰める
        "Button.margin", new InsetsUIResource (1, 7, 1, 7),  //2,14,2,14
        //アイコン
        //  ウインドウのタイトルバーの左端のアイコンはこれだけで変更できる
        //  タスクバーのアイコンはこれだけでは変更できない
        //    おそらく変更する前にコピーされている
        //  メインのウインドウだけwindow.setIconImage(LNF_ICON_IMAGE_16)などと書くことにする
        "InternalFrame.icon", new IconUIResource (new ImageIcon (LNF_ICON_IMAGE_16)),
      });
    }  //addCustomEntriesToTable(UIDefaults)

  }  //class XEiJTheme



}  //class LnF



