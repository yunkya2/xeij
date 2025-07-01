//========================================================================================
//  CyberStickDigital.java
//    en:CYBER STICK (digital mode)
//    ja:サイバースティック(デジタルモード)
//  Copyright (C) 2003-2024 Makoto Kamada
//
//  This file is part of the XEiJ (X68000 Emulator in Java).
//  You can use, modify and redistribute the XEiJ if the conditions are met.
//  Read the XEiJ License for more details.
//  https://stdkmd.net/xeij/
//========================================================================================

//サイバースティック(デジタルモード)
//
//  データ
//    +-------+---------------------------------------------------------------+
//    | 出力  |                             入力                              |
//    +-------+-------+-------+-------+-------+-------+-------+-------+-------+
//    | pin8  |       | pin7  | pin6  |       | pin4  | pin3  | pin2  | pin1  |
//    |       +-------+-------+-------+-------+-------+-------+-------+-------+
//    |       |   7   |   6   |   5   |   4   |   3   |   2   |   1   |   0   |
//    +-------+-------+-------+-------+-------+-------+-------+-------+-------+
//    |       |       |       |       |       |SRIGHT | SLEFT | SDOWN |  SUP  |
//    |   0   |   1   |   B   |   A   |   1   +-------+-------+-------+-------+
//    |       |       |       |       |       |     START     |    SELECT     |
//    +-------+-------+-------+-------+-------+-------+-------+-------+-------+
//    |   1   |   1   |  E2   |  E1   |   1   |   D   |   C   | TDOWN |  TUP  |
//    +-------+-------+-------+-------+-------+-------+-------+-------+-------+
//    pin8の出力に合わせてpin1-4,6-7の入力が変化する
//    デジタルモードのSELECTとSTARTはサイバースティックにはなく電波新聞社のXE-1APで追加された機能とのことだが入れておく
//
//  参考
//    http://retropc.net/x68000/software/hardware/analog/ajoy/
//    https://ktjdragon.com/nb/misc/atari_cyberstick

package xeij;

import java.awt.*;
import java.awt.event.*;
import java.util.*;
import javax.swing.*;
import javax.swing.event.*;

//class CyberStickDigital
//  サイバースティック(デジタルモード)
public class CyberStickDigital extends Joystick implements ActionListener, ChangeListener, FocusListener, XInput.GamepadListener, KeyListener {

  protected static final int SUP_BIT           =  0;  //STICK ↑
  protected static final int SDOWN_BIT         =  1;  //STICK ↓
  protected static final int SLEFT_BIT         =  2;  //STICK ←
  protected static final int SRIGHT_BIT        =  3;  //STICK →
  protected static final int TUP_BIT           =  4;  //THROTTLE ↑
  protected static final int TDOWN_BIT         =  5;  //THROTTLE ↓
  protected static final int A_BIT             =  6;  //A
  protected static final int APRIME_BIT        =  7;  //A'
  protected static final int B_BIT             =  8;  //B
  protected static final int BPRIME_BIT        =  9;  //B'
  protected static final int C_BIT             = 10;  //C
  protected static final int D_BIT             = 11;  //D
  protected static final int E1_BIT            = 12;  //E1
  protected static final int E2_BIT            = 13;  //E2
  protected static final int SELECT_BIT        = 14;  //SELECT
  protected static final int START_BIT         = 15;  //START
  protected static final int BUTTONS           = 16;  //ボタンの数

  protected static final int SUP_MASK          = (1 << SUP_BIT);
  protected static final int SDOWN_MASK        = (1 << SDOWN_BIT);
  protected static final int SLEFT_MASK        = (1 << SLEFT_BIT);
  protected static final int SRIGHT_MASK       = (1 << SRIGHT_BIT);
  protected static final int TUP_MASK          = (1 << TUP_BIT);
  protected static final int TDOWN_MASK        = (1 << TDOWN_BIT);
  protected static final int A_MASK            = (1 << A_BIT);
  protected static final int APRIME_MASK       = (1 << APRIME_BIT);
  protected static final int B_MASK            = (1 << B_BIT);
  protected static final int BPRIME_MASK       = (1 << BPRIME_BIT);
  protected static final int C_MASK            = (1 << C_BIT);
  protected static final int D_MASK            = (1 << D_BIT);
  protected static final int E1_MASK           = (1 << E1_BIT);
  protected static final int E2_MASK           = (1 << E2_BIT);
  protected static final int SELECT_MASK       = (1 << SELECT_BIT);
  protected static final int START_MASK        = (1 << START_BIT);

  protected static final String[] BIT_TO_TEXT = {
    "STICK ↑",
    "STICK ↓",
    "STICK ←",
    "STICK →",
    "THROTTLE ↑",
    "THROTTLE ↓",
    "A",
    "A'",
    "B",
    "B'",
    "C",
    "D",
    "E1",
    "E2",
    "SELECT",
    "START",
  };

  protected static final boolean[] BIT_TO_REPEATABLE = {
    false,  //STICK ↑
    false,  //STICK ↓
    false,  //STICK ←
    false,  //STICK →
    false,  //THROTTLE ↑
    false,  //THROTTLE ↓
    true,   //A
    true,   //A'
    true,   //B
    true,   //B'
    true,   //C
    true,   //D
    true,   //E1
    true,   //E2
    false,  //SELECT
    false,  //START
  };

  protected static final int MAP_CODE     = BUTTONS * 0;  //XInputコードとキーコード
  protected static final int MAP_REPEAT   = BUTTONS * 1;  //連射有効
  protected static final int MAP_DELAY    = BUTTONS * 2;  //連射開始
  protected static final int MAP_INTERVAL = BUTTONS * 3;  //連射間隔
  protected static final int MAP_LENGTH   = BUTTONS * 4;
  protected int[] map;

  protected int xinputFocusedButton;  //フォーカスされているXInputテキストフィールドの番号。-1=なし
  protected long[] startTimeOf;  //連射開始時刻。ボタンが押されたとき初期化して押されている間だけ使う
  protected int lastButtons;  //前回押されていたボタン。XInputを含む
  protected int keyButtons;  //キーで押されているボタン

  protected int page;  //ページ

  protected JTextField[] xinputTextFieldOf = new JTextField[BUTTONS];
  protected JTextField[] keyTextFieldOf = new JTextField[BUTTONS];
  protected JCheckBox[] repeatCheckBoxOf = new JCheckBox[BUTTONS];
  protected SpinnerNumberModel[] delayModelOf = new SpinnerNumberModel[BUTTONS];
  protected JSpinner[] delaySpinnerOf = new JSpinner[BUTTONS];
  protected SpinnerNumberModel[] intervalModelOf = new SpinnerNumberModel[BUTTONS];
  protected JSpinner[] intervalSpinnerOf = new JSpinner[BUTTONS];

  //  map[i]=xCode<<16|keyCode
  //  xCode=map[i]>>>16
  //  keyCode=map[i]&65535
  //  xCode=128|xIndex<<5|xBit
  //  xIndex=(xCode>>5)&3
  //  xBit=xCode&31
  protected final int[][] defaultMaps = new int[][] {
    {
      (128 | 0 << 5 | XInput.RSUP_BIT   ) << 16 | KeyEvent.VK_UP,         //STICK ↑
      (128 | 0 << 5 | XInput.RSDOWN_BIT ) << 16 | KeyEvent.VK_DOWN,       //STICK ↓
      (128 | 0 << 5 | XInput.RSLEFT_BIT ) << 16 | KeyEvent.VK_LEFT,       //STICK ←
      (128 | 0 << 5 | XInput.RSRIGHT_BIT) << 16 | KeyEvent.VK_RIGHT,      //STICK →
      (128 | 0 << 5 | XInput.LSUP_BIT   ) << 16 | KeyEvent.VK_PAGE_UP,    //THROTTLE ↑
      (128 | 0 << 5 | XInput.LSDOWN_BIT ) << 16 | KeyEvent.VK_PAGE_DOWN,  //THROTTLE ↓
      (128 | 0 << 5 | XInput.RSTICK_BIT ) << 16 | KeyEvent.VK_Z,          //A。右スティック
      (128 | 0 << 5 | XInput.A_BIT      ) << 16 | KeyEvent.VK_V,          //A'。台座
      (128 | 0 << 5 | XInput.X_BIT      ) << 16 | KeyEvent.VK_X,          //B。右スティック
      (128 | 0 << 5 | XInput.B_BIT      ) << 16 | KeyEvent.VK_B,          //B'。台座
      (128 | 0 << 5 | XInput.Y_BIT      ) << 16 | KeyEvent.VK_C,          //C。台座
      (128 | 0 << 5 | XInput.LSTICK_BIT ) << 16 | KeyEvent.VK_A,          //D。左スティック
      (128 | 0 << 5 | XInput.LB_BIT     ) << 16 | KeyEvent.VK_S,          //E1。左スティック
      (128 | 0 << 5 | XInput.RB_BIT     ) << 16 | KeyEvent.VK_D,          //E2。左スティック
      (128 | 0 << 5 | XInput.BACK_BIT   ) << 16 | KeyEvent.VK_E,          //SELECT
      (128 | 0 << 5 | XInput.START_BIT  ) << 16 | KeyEvent.VK_R,          //START
      0, 0, 0, 0, 0, 0,   0,   0,   0,   0,   0,   0,   0,   0, 0, 0,  //連射有効
      0, 0, 0, 0, 0, 0,  50,  50,  50,  50,  50,  50,  50,  50, 0, 0,  //連射開始
      0, 0, 0, 0, 0, 0, 100, 100, 100, 100, 100, 100, 100, 100, 0, 0,  //連射間隔
    },
    {
      (128 | 1 << 5 | XInput.RSUP_BIT   ) << 16 | KeyEvent.VK_UNDEFINED,  //STICK ↑
      (128 | 1 << 5 | XInput.RSDOWN_BIT ) << 16 | KeyEvent.VK_UNDEFINED,  //STICK ↓
      (128 | 1 << 5 | XInput.RSLEFT_BIT ) << 16 | KeyEvent.VK_UNDEFINED,  //STICK ←
      (128 | 1 << 5 | XInput.RSRIGHT_BIT) << 16 | KeyEvent.VK_UNDEFINED,  //STICK →
      (128 | 1 << 5 | XInput.LSUP_BIT   ) << 16 | KeyEvent.VK_UNDEFINED,  //THROTTLE ↑
      (128 | 1 << 5 | XInput.LSDOWN_BIT ) << 16 | KeyEvent.VK_UNDEFINED,  //THROTTLE ↓
      (128 | 1 << 5 | XInput.RSTICK_BIT ) << 16 | KeyEvent.VK_UNDEFINED,  //A。右スティック
      (128 | 1 << 5 | XInput.A_BIT      ) << 16 | KeyEvent.VK_UNDEFINED,  //A'。台座
      (128 | 1 << 5 | XInput.X_BIT      ) << 16 | KeyEvent.VK_UNDEFINED,  //B。右スティック
      (128 | 1 << 5 | XInput.B_BIT      ) << 16 | KeyEvent.VK_UNDEFINED,  //B'。台座
      (128 | 1 << 5 | XInput.Y_BIT      ) << 16 | KeyEvent.VK_UNDEFINED,  //C。台座
      (128 | 1 << 5 | XInput.LSTICK_BIT ) << 16 | KeyEvent.VK_UNDEFINED,  //D。左スティック
      (128 | 1 << 5 | XInput.LB_BIT     ) << 16 | KeyEvent.VK_UNDEFINED,  //E1。左スティック
      (128 | 1 << 5 | XInput.RB_BIT     ) << 16 | KeyEvent.VK_UNDEFINED,  //E2。左スティック
      (128 | 1 << 5 | XInput.BACK_BIT   ) << 16 | KeyEvent.VK_UNDEFINED,  //SELECT
      (128 | 1 << 5 | XInput.START_BIT  ) << 16 | KeyEvent.VK_UNDEFINED,  //START
      0, 0, 0, 0, 0, 0,   0,   0,   0,   0,   0,   0,   0,   0, 0, 0,  //連射有効
      0, 0, 0, 0, 0, 0,  50,  50,  50,  50,  50,  50,  50,  50, 0, 0,  //連射開始
      0, 0, 0, 0, 0, 0, 100, 100, 100, 100, 100, 100, 100, 100, 0, 0,  //連射間隔
    },
  };

  //new CyberStickDigital (number)
  //  コンストラクタ
  //  number  枝番号。1～2
  public CyberStickDigital (int number) {
    this.number = number;
    id = "cyberstickdigital" + number;
    nameEn = "CYBER STICK (digital) #" + number;
    nameJa = "サイバースティック (デジタル) #" + number;
    map = new int[MAP_LENGTH];
    int[] tempMap = Settings.sgsGetIntArray (id);
    if (0 < tempMap.length && tempMap[0] == -2) {  //新フォーマット
      for (int i = 0; i < MAP_LENGTH; i++) {
        map[i] = i + 1 < tempMap.length ? tempMap[i + 1] : 0;
      }
    } else {  //初期値
      System.arraycopy (defaultMaps[number - 1], 0,  //from
                        map, 0,  //to
                        MAP_LENGTH);  //length
    }
    if (PPI.PPI_XINPUT_ON) {
      xinputFocusedButton = -1;
    }
    startTimeOf = new long[BUTTONS];
    reset ();
    configurationPanel = null;
  }

  //tini ()
  //  後始末
  @Override public void tini () {
    if (true &&  //false=初期値と同じでも出力して値を確認する
        Arrays.equals (map, defaultMaps[number - 1])) {  //初期値と同じ
      Settings.sgsPutIntArray (id, new int[0]);  //"none"ではなく""にする
    } else {  //初期値と違う
      int[] tempMap = new int[1 + MAP_LENGTH];
      tempMap[0] = -2;  //新フォーマット
      for (int i = 0; i < MAP_LENGTH; i++) {
        tempMap[1 + i] = map[i];
      }
      Settings.sgsPutIntArray (id, tempMap);
    }
  }

  //reset ()
  //  リセット。設定パネルが表示されるとき呼び出される
  @Override public final void reset () {
    lastButtons = 0;
    keyButtons = 0;
    page = 0;
  }

  private void updateText () {
    for (int i = 0; i < BUTTONS; i++) {
      String text;
      int xCode = map[MAP_CODE + i] >>> 16;
      if (xCode == 0) {
        text = Multilingual.mlnJapanese ? "なし" : "none";
      } else {
        int xIndex = (xCode >> 5) & 3;
        int xBit = xCode & 31;
        text = "#" + xIndex + " " + XInput.BIT_TO_TEXT[xBit];
      }
      xinputTextFieldOf[i].setText (text);
      int keyCode = map[MAP_CODE + i] & 65535;
      if (keyCode == 0) {
        text = Multilingual.mlnJapanese ? "なし" : "none";
      } else {
        text = KeyEvent.getKeyText (keyCode);
      }
      keyTextFieldOf[i].setText (text);
    }
  }


  //ボタンのアクションリスナー
  @Override public void actionPerformed (ActionEvent ae) {
    Object source = ae.getSource ();
    String command = ae.getActionCommand ();
    if (command.equals ("Reset to default values")) {  //初期値に戻す
      if (Arrays.equals (map, defaultMaps[number - 1])) {  //初期値と同じ
        JOptionPane.showMessageDialog (
          null,
          Multilingual.mlnJapanese ? nameJa + " の設定は初期値と同じです" : nameEn + " settings are equals to default values",
          Multilingual.mlnJapanese ? "確認" : "Confirmation",
          JOptionPane.PLAIN_MESSAGE);
        return;
      }
      if (JOptionPane.showConfirmDialog (
        null,
        Multilingual.mlnJapanese ? nameJa + " の設定を初期値に戻しますか？" : "Do you want to reset " + nameEn + " settings to default values?",
        Multilingual.mlnJapanese ? "確認" : "Confirmation",
        JOptionPane.YES_NO_OPTION,
        JOptionPane.PLAIN_MESSAGE) != JOptionPane.YES_OPTION) {
        return;
      }
      System.arraycopy (defaultMaps[number - 1], 0,  //from
                        map, 0,  //to
                        MAP_LENGTH);  //length
      updateText ();
      for (int i = 0; i < BUTTONS; i++) {
        if (BIT_TO_REPEATABLE[i]) {
          repeatCheckBoxOf[i].setSelected (map[MAP_REPEAT + i] != 0);
          delayModelOf[i].setValue (Math.max (DELAY_MIN, Math.min (DELAY_MAX, map[MAP_DELAY + i])));
          intervalModelOf[i].setValue (Math.max (INTERVAL_MIN, Math.min (INTERVAL_MAX, map[MAP_INTERVAL + i])));
        }
      }
    } else if (command.startsWith ("Repeat ")) {
      int i = Integer.parseInt (command.substring (7));
      map[MAP_REPEAT + i] = repeatCheckBoxOf[i].isSelected () ? 1 : 0;
    } else {
      System.out.println ("unknown action command " + command);
    }
  }


  //スピナーのチェンジリスナー
  @Override public void stateChanged (ChangeEvent ce) {
    JSpinner spinner = (JSpinner) ce.getSource ();
    String name = spinner.getName ();
    if (name.startsWith ("Delay ")) {
      int i = Integer.parseInt (name.substring (6));
      map[MAP_DELAY + i] = delayModelOf[i].getNumber ().intValue ();
    } else if (name.startsWith ("Interval ")) {
      int i = Integer.parseInt (name.substring (9));
      map[MAP_INTERVAL + i] = intervalModelOf[i].getNumber ().intValue ();
    } else {
      System.out.println ("unknown spinner name " + name);
    }
  }


  //テキストフィールドのフォーカスリスナー
  @Override public void focusGained (FocusEvent fe) {
    Component component = fe.getComponent ();
    String componentName = component.getName ();
    int type = componentName.charAt (0);  //'x'または'k'
    int i = Integer.parseInt (componentName.substring (1));
    //背景色を変えて目立たさせる
    component.setBackground (new Color (LnF.lnfRGB[6]));
    if (PPI.PPI_XINPUT_ON && type == 'x') {  //XInput
      //Gamepadリスナーを追加する
      xinputFocusedButton = i;
      if (PPI.ppiXInput != null) {
        PPI.ppiXInput.addGamepadListener (this);
      }
    } else if (type == 'k') {  //キー
    } else {
      System.out.println ("unknown component name " + componentName);
    }
  }
  @Override public void focusLost (FocusEvent fe) {
    Component component = fe.getComponent ();
    String componentName = component.getName ();
    int type = componentName.charAt (0);  //'x'または'k'
    int i = Integer.parseInt (componentName.substring (1));
    //背景色を元に戻す
    component.setBackground (null);
    if (PPI.PPI_XINPUT_ON && type == 'x') {  //XInput
      //Gamepadリスナーを削除する
      if (PPI.ppiXInput != null) {
        PPI.ppiXInput.removeGamepadListeners ();
      }
      xinputFocusedButton = -1;
    } else if (type == 'k') {  //キー
    } else {
      System.out.println ("unknown component name " + componentName);
    }
  }


  //Gamepadリスナー
  @Override public void connected (XInput.Gamepad gamepad) {
  }
  @Override public void disconnected (XInput.Gamepad gamepad) {
  }
  @Override public void buttonPressed (XInput.Gamepad gamepad, int buttonMasks) {
    if (buttonMasks == 0) {  //ないはず
      return;
    }
    if (PPI.PPI_XINPUT_ON && 0 <= xinputFocusedButton) {  //フォーカスされているxinputのテキストフィールドがある
      int xIndex = gamepad.getIndex ();
      int xBit = Integer.numberOfTrailingZeros (buttonMasks);
      int xCode = 128 | xIndex << 5 | xBit;
      int keyCode = map[MAP_CODE + xinputFocusedButton] & 65535;
      map[MAP_CODE + xinputFocusedButton] = xCode << 16 | keyCode;
      //すべてのボタンのxIndexを更新する
      //  インデックスを変更したいときボタンを1個割り当て直せば済む
      for (int i = 0; i < BUTTONS; i++) {
        int xCode2 = map[MAP_CODE + i] >>> 16;
        if (xCode2 != 0) {
          int keyCode2 = map[MAP_CODE + i] & 65535;
          map[MAP_CODE + i] = ((xCode2 & ~(3 << 5)) | xIndex << 5) << 16 | keyCode2;
        }
      }
      updateText ();
    }
  }
  @Override public void buttonReleased (XInput.Gamepad gamepad, int buttonMasks) {
  }
  @Override public void leftStickMovedX (XInput.Gamepad gamepad) {
  }
  @Override public void leftStickMovedY (XInput.Gamepad gamepad) {
  }
  @Override public void leftTriggerMoved (XInput.Gamepad gamepad) {
  }
  @Override public void rightStickMovedX (XInput.Gamepad gamepad) {
  }
  @Override public void rightStickMovedY (XInput.Gamepad gamepad) {
  }
  @Override public void rightTriggerMoved (XInput.Gamepad gamepad) {
  }


  //テキストフィールドのキーリスナー
  @Override public void keyPressed (KeyEvent ke) {
    Component component = ke.getComponent ();
    String componentName = component.getName ();
    int type = componentName.charAt (0);  //'x'または'k'
    int i = Integer.parseInt (componentName.substring (1));
    int xCode = map[MAP_CODE + i] >>> 16;
    int keyCode = map[MAP_CODE + i] & 65535;
    if (PPI.PPI_XINPUT_ON && type == 'x') {  //XInput
      if (ke.getKeyCode () == KeyEvent.VK_ESCAPE) {  //Escキーは解除とみなす
        xCode = 0;
      }
    } else if (type == 'k') {  //キー
      if (ke.getKeyCode () == KeyEvent.VK_ESCAPE) {  //Escキーは解除とみなす
        keyCode = KeyEvent.VK_UNDEFINED;
      } else {  //それ以外は割り当てを変更する
        keyCode = ke.getKeyCode ();
      }
    } else {
      System.out.println ("unknown component name " + componentName);
    }
    map[MAP_CODE + i] = xCode << 16 | keyCode;
    updateText ();
    ke.consume ();
  }
  @Override public void keyReleased (KeyEvent ke) {
    ke.consume ();
  }
  @Override public void keyTyped (KeyEvent ke) {
    ke.consume ();
  }


  //configurationPanel = getConfigurationPanel ()
  //  設定パネルを返す。初回は作る
  @Override public JComponent getConfigurationPanel () {

    if (configurationPanel != null) {
      return configurationPanel;
    }

    for (int i = 0; i < BUTTONS; i++) {
      xinputTextFieldOf[i] =
        ComponentFactory.setEnabled (
          ComponentFactory.addListener (
            ComponentFactory.addListener (
              ComponentFactory.setHorizontalAlignment (
                ComponentFactory.setName (
                  ComponentFactory.createTextField ("", 8),
                  "x" + i),
                JTextField.CENTER),
              (KeyListener) this),
            (FocusListener) this),
          PPI.PPI_XINPUT_ON && XEiJ.prgWindllLoaded);
      keyTextFieldOf[i] =
        ComponentFactory.addListener (
          ComponentFactory.addListener (
            ComponentFactory.setHorizontalAlignment (
              ComponentFactory.setName (
                ComponentFactory.createTextField ("", 8),
                "k" + i),
              JTextField.CENTER),
            (KeyListener) this),
          (FocusListener) this);
      if (BIT_TO_REPEATABLE[i]) {
        repeatCheckBoxOf[i] =
          ComponentFactory.setText (
            ComponentFactory.createCheckBox (map[MAP_REPEAT + i] != 0, "Repeat " + i, (ActionListener) this),
            "");
        delayModelOf[i] =
          new SpinnerNumberModel (Math.max (DELAY_MIN, Math.min (DELAY_MAX, map[MAP_DELAY + i])),
                                  DELAY_MIN, DELAY_MAX, DELAY_STEP);
        delaySpinnerOf[i] =
          ComponentFactory.setName (
            ComponentFactory.createNumberSpinner (delayModelOf[i], 4, (ChangeListener) this),
            "Delay " + i);
        intervalModelOf[i] =
          new SpinnerNumberModel (Math.max (INTERVAL_MIN, Math.min (INTERVAL_MAX, map[MAP_INTERVAL + i])),
                                  INTERVAL_MIN, INTERVAL_MAX, INTERVAL_STEP);
        intervalSpinnerOf[i] =
          ComponentFactory.setName (
            ComponentFactory.createNumberSpinner (intervalModelOf[i], 4, (ChangeListener) this),
            "Interval " + i);
      }
    }
    updateText ();

    //    0    1       2        3        4      5       6
    //       Button  XInput  Keyboard  Burst  Delay  Interval
    //    ---------------------------------------------------
    //    #    *       *        *        *      *       *
    ArrayList<Object> cellList = new ArrayList<Object> ();
    //
    cellList.add (null);
    cellList.add (Multilingual.mlnText (ComponentFactory.createLabel ("Button"), "ja", "ボタン"));
    cellList.add (ComponentFactory.createLabel ("XInput"));
    cellList.add (Multilingual.mlnText (ComponentFactory.createLabel ("Keyboard"), "ja", "キーボード"));
    cellList.add (Multilingual.mlnText (ComponentFactory.createLabel ("Burst"), "ja", "連射"));
    cellList.add (Multilingual.mlnText (ComponentFactory.createLabel ("Delay (ms)"), "ja", "開始 (ms)"));
    cellList.add (Multilingual.mlnText (ComponentFactory.createLabel ("Interval (ms)"), "ja", "間隔 (ms)"));
    //
    cellList.add (ComponentFactory.createHorizontalSeparator ());
    //
    for (int i = 0; i < BUTTONS; i++) {
      cellList.add (String.valueOf (1 + i));  //#
      cellList.add (BIT_TO_TEXT[i]);  //Button
      cellList.add (xinputTextFieldOf[i]);  //XInput
      cellList.add (keyTextFieldOf[i]);  //Keyboard
      cellList.add (BIT_TO_REPEATABLE[i] ? repeatCheckBoxOf[i] : null);  //Burst
      cellList.add (BIT_TO_REPEATABLE[i] ? delaySpinnerOf[i] : null);  //Delay
      cellList.add (BIT_TO_REPEATABLE[i] ? intervalSpinnerOf[i] : null);  //Interval
    }

    configurationPanel =
      ComponentFactory.createVerticalBox (
        Box.createVerticalStrut (5),
        ComponentFactory.createHorizontalBox (
          Box.createHorizontalGlue (),
          Multilingual.mlnText (ComponentFactory.createLabel (getNameEn ()), "ja", getNameJa ()),
          Box.createHorizontalGlue ()),
        Box.createVerticalStrut (5),
        ComponentFactory.createHorizontalBox (
          ComponentFactory.createGridPanel (
            7,  //colCount
            2 + BUTTONS,  //rowCount
            "paddingLeft=3,paddingRight=3,center",   //gridStyles
            "",  //colStyles
            "italic;colSpan=7,widen",  //rowStyles
            "",  //cellStyles
            cellList.toArray (new Object[0]))),
        Box.createVerticalStrut (5),
        ComponentFactory.createHorizontalBox (
          Box.createHorizontalGlue (),
          Multilingual.mlnText (ComponentFactory.createButton ("Reset to default values", (ActionListener) this), "ja", "初期値に戻す"),
          Box.createHorizontalGlue ()),
        Box.createVerticalStrut (5));

    return configurationPanel;
  }


  //input (ke, pressed)
  //  キー入力イベントを処理する
  //  ke  キーイベント
  //  pressed  false=離された,true=押された
  @Override public boolean input (KeyEvent ke, boolean pressed) {
    int keyCode = ke.getKeyCode ();
    //キーで押されているボタンを更新する
    for (int i = 0; i < BUTTONS; i++) {
      if (keyCode == (map[MAP_CODE + i] & 65535)) {
        if (pressed) {
          keyButtons |= 1 << i;
        } else {
          keyButtons &= ~(1 << i);
        }
        return true;
      }
    }
    return false;
  }


  //setPin8 (pin8)
  //  ピン8を変更する
  //  pin8  ピン8
  @Override public void setPin8 (int pin8) {
    page = pin8;
  }


  //d = readByte ()
  //  ポートから読み出す
  //  d  値。0～255
  @Override public int readByte () {
    //ボタンの状態を確認する
    int currentButtons = keyButtons;  //現在押されているボタン
    int lastIndex = -1;
    int lastMasks = 0;
    for (int i = 0; i < BUTTONS; i++) {
      int xCode = map[MAP_CODE + i] >>> 16;
      if (xCode != 0) {  //割り当てられている
        int xIndex = (xCode >> 5) & 3;
        int xBit = xCode & 31;
        if (lastIndex != xIndex) {
          lastIndex = xIndex;
          lastMasks = PPI.ppiXInput == null ? 0 : PPI.ppiXInput.getButtonMasks (lastIndex);
        }
        if ((lastMasks & (1 << xBit)) != 0) {  //押されている
          currentButtons |= 1 << i;
        }
      }
    }
    int pressedButtons = ~lastButtons & currentButtons;  //今回押されたボタン
    lastButtons = currentButtons;
    int outputButtons = 0;  //出力するボタン
    for (int i = 0; i < BUTTONS; i++) {
      if ((pressedButtons & (1 << i)) != 0 &&  //今回押された
          map[MAP_REPEAT + i] != 0) {  //連射有効
        startTimeOf[i] = XEiJ.mpuClockTime + map[MAP_DELAY + i] * (XEiJ.TMR_FREQ / 1000);  //連射開始時刻
      }
      if ((currentButtons & (1 << i)) != 0 &&  //現在押されている
          (map[MAP_REPEAT + i] == 0 ||  //連射が無効または
           XEiJ.mpuClockTime < startTimeOf[i] ||  //連射開始時刻になっていないまたは
           ((int) ((XEiJ.mpuClockTime - startTimeOf[i]) /  //連射開始時刻を過ぎた時間を
                   ((map[MAP_INTERVAL + i] >> 1) * (XEiJ.TMR_FREQ / 1000)))  //連射間隔の半分で割った商が
            & 1) != 0)) {  //奇数
        outputButtons |= 1 << i;
      }
    }
    //データを作る
    return (page == 0 ?
            0b11111111 &
            ((outputButtons & (SUP_MASK | SDOWN_MASK)) == SUP_MASK ? ~0b00000001 : -1) &  //↑が押されていて↓が押されていない
            ((outputButtons & (SDOWN_MASK | SUP_MASK)) == SDOWN_MASK ? ~0b00000010 : -1) &  //↓が押されていて↑が押されていない
            ((outputButtons & SELECT_MASK) != 0 ? ~0b00000011 : -1) &  //↑↓
            ((outputButtons & (SLEFT_MASK | SRIGHT_MASK)) == SLEFT_MASK ? ~0b00000100 : -1) &  //←が押されていて→が押されていない
            ((outputButtons & (SRIGHT_MASK | SLEFT_MASK)) == SRIGHT_MASK ? ~0b00001000 : -1) &  //→が押されていて←が押されていない
            ((outputButtons & START_MASK) != 0 ? ~0b00001100 : -1) &  //←→
            ((outputButtons & (A_MASK | APRIME_MASK)) != 0 ? ~0b00100000 : -1) &
            ((outputButtons & (B_MASK | BPRIME_MASK)) != 0 ? ~0b01000000 : -1)
            :
            0b11111111 &
            ((outputButtons & (TUP_MASK | TDOWN_MASK)) == TUP_MASK ? ~0b00000001 : -1) &  //↑が押されていて↓が押されていない
            ((outputButtons & (TDOWN_MASK | TUP_MASK)) == TDOWN_MASK ? ~0b00000010 : -1) &  //↓が押されていて↑が押されていない
            ((outputButtons & C_MASK) != 0 ? ~0b00000100 : -1) &
            ((outputButtons & D_MASK) != 0 ? ~0b00001000 : -1) &
            ((outputButtons & E1_MASK) != 0 ? ~0b00100000 : -1) &
            ((outputButtons & E2_MASK) != 0 ? ~0b01000000 : -1)
            );
  }  //readByte

}  //class CyberStickDigital
