import java.awt.*;
import java.awt.event.*;
import java.io.*;
import java.nio.charset.*;
import java.util.*;
import javax.swing.*;

public class keymap implements ActionListener, KeyListener, Runnable {

  //定数
  public static final int COL_WIDTH  = 14;  //列の幅(px)。可変キーの幅の1/4
  public static final int ROW_HEIGHT = 14;  //行の高さ(px)。可変キーの高さの1/4
  public static final int COLS = 94;  //列数
  public static final int ROWS = 25;  //行数
  public static final int PADDING_TOP    = 7;  //パディング(px)
  public static final int PADDING_BOTTOM = 7;
  public static final int PADDING_LEFT   = 7;
  public static final int PADDING_RIGHT  = 7;
  public static final int LABEL_HEIGHT = 14;
  public static final int KEYBOARD_WIDTH = PADDING_LEFT + COL_WIDTH * COLS + PADDING_RIGHT;
  public static final int KEYBOARD_HEIGHT = PADDING_TOP + ROW_HEIGHT * ROWS + PADDING_BOTTOM;
  public static final int KEYS = 126;  //キーの数

  //番号
  public static final int[] NUMBER_ARRAY = {
    0x001,  //  0  ESC
    0x002,  //  1  １！ぬ　
    0x003,  //  2  ２＂ふ　
    0x004,  //  3  ３＃あぁ
    0x005,  //  4  ４＄うぅ
    0x006,  //  5  ５％えぇ
    0x007,  //  6  ６＆おぉ
    0x008,  //  7  ７＇やゃ
    0x009,  //  8  ８（ゆゅ
    0x00a,  //  9  ９）よょ
    0x00b,  // 10  ０　わを
    0x00c,  // 11  －＝ほ　
    0x00d,  // 12  ＾～へ　
    0x00e,  // 13  ￥｜ー　
    0x00f,  // 14  BS
    0x010,  // 15  TAB
    0x011,  // 16  Ｑ　た　
    0x012,  // 17  Ｗ　て　
    0x013,  // 18  Ｅ　いぃ
    0x014,  // 19  Ｒ　す　
    0x015,  // 20  Ｔ　か　
    0x016,  // 21  Ｙ　ん　
    0x017,  // 22  Ｕ　な　
    0x018,  // 23  Ｉ　に　
    0x019,  // 24  Ｏ　ら　
    0x01a,  // 25  Ｐ　せ　
    0x01b,  // 26  ＠｀゛　
    0x01c,  // 27  ［｛゜「
    0x01d,  // 28  リターン
    0x01e,  // 29  Ａ　ち　
    0x01f,  // 30  Ｓ　と　
    0x020,  // 31  Ｄ　し　
    0x021,  // 32  Ｆ　は　
    0x022,  // 33  Ｇ　き　
    0x023,  // 34  Ｈ　く　
    0x024,  // 35  Ｊ　ま　
    0x025,  // 36  Ｋ　の　
    0x026,  // 37  Ｌ　り　
    0x027,  // 38  ；＋れ　
    0x028,  // 39  ：＊け　
    0x029,  // 40  ］｝む」
    0x02a,  // 41  Ｚ　つっ
    0x02b,  // 42  Ｘ　さ　
    0x02c,  // 43  Ｃ　そ　
    0x02d,  // 44  Ｖ　ひ　
    0x02e,  // 45  Ｂ　こ　
    0x02f,  // 46  Ｎ　み　
    0x030,  // 47  Ｍ　も　
    0x031,  // 48  ，＜ね、
    0x032,  // 49  ．＞る。
    0x033,  // 50  ／？め・
    0x034,  // 51  　＿ろ□
    0x035,  // 52  スペース
    0x036,  // 53  HOME
    0x037,  // 54  DEL
    0x038,  // 55  ROLLUP
    0x039,  // 56  ROLLDOWN
    0x03a,  // 57  UNDO
    0x03b,  // 58  ←
    0x03c,  // 59  ↑
    0x03d,  // 60  →
    0x03e,  // 61  ↓
    0x03f,  // 62  CLR
    0x040,  // 63  ／
    0x041,  // 64  ＊
    0x042,  // 65  －
    0x043,  // 66  ７
    0x044,  // 67  ８
    0x045,  // 68  ９
    0x046,  // 69  ＋
    0x047,  // 70  ４
    0x048,  // 71  ５
    0x049,  // 72  ６
    0x04a,  // 73  ＝
    0x04b,  // 74  １
    0x04c,  // 75  ２
    0x04d,  // 76  ３
    0x04e,  // 77  ENTER
    0x04f,  // 78  ０
    0x050,  // 79  ，
    0x051,  // 80  ．
    0x052,  // 81  記号入力
    0x053,  // 82  登録
    0x054,  // 83  HELP
    0x055,  // 84  XF1
    0x056,  // 85  XF2
    0x057,  // 86  XF3
    0x058,  // 87  XF4
    0x059,  // 88  XF5
    0x05a,  // 89  かな
    0x05b,  // 90  ローマ字
    0x05c,  // 91  コード入力
    0x05d,  // 92  CAPS
    0x05e,  // 93  INS
    0x05f,  // 94  ひらがな
    0x060,  // 95  全角
    0x061,  // 96  BREAK
    0x062,  // 97  COPY
    0x063,  // 98  F1
    0x064,  // 99  F2
    0x065,  //100  F3
    0x066,  //101  F4
    0x067,  //102  F5
    0x068,  //103  F6
    0x069,  //104  F7
    0x06a,  //105  F8
    0x06b,  //106  F9
    0x06c,  //107  F10
    0x070,  //108  SHIFT
    0x071,  //109  CTRL
    0x072,  //110  OPT.1
    0x073,  //111  OPT.2
    0x074,  //112  NUM
    0x143,  //113  NumLk７
    0x144,  //114  NumLk８
    0x145,  //115  NumLk９
    0x147,  //116  NumLk４
    0x148,  //117  NumLk５
    0x149,  //118  NumLk６
    0x14b,  //119  NumLk１
    0x14c,  //120  NumLk２
    0x14d,  //121  NumLk３
    0x14f,  //122  NumLk０
    0x150,  //123  NumLk，
    0x151,  //124  NumLk．
    0x170,  //125  右SHIFT
  };

  //位置
  public static final int[][] BOUNDS_ARRAY = {
    {  0,  5,  4, 4 },  //  0  0x001  ESC
    {  4,  5,  4, 4 },  //  1  0x002  １！ぬ　
    {  8,  5,  4, 4 },  //  2  0x003  ２＂ふ　
    { 12,  5,  4, 4 },  //  3  0x004  ３＃あぁ
    { 16,  5,  4, 4 },  //  4  0x005  ４＄うぅ
    { 20,  5,  4, 4 },  //  5  0x006  ５％えぇ
    { 24,  5,  4, 4 },  //  6  0x007  ６＆おぉ
    { 28,  5,  4, 4 },  //  7  0x008  ７＇やゃ
    { 32,  5,  4, 4 },  //  8  0x009  ８（ゆゅ
    { 36,  5,  4, 4 },  //  9  0x00a  ９）よょ
    { 40,  5,  4, 4 },  // 10  0x00b  ０　わを
    { 44,  5,  4, 4 },  // 11  0x00c  －＝ほ　
    { 48,  5,  4, 4 },  // 12  0x00d  ＾～へ　
    { 52,  5,  4, 4 },  // 13  0x00e  ￥｜ー　
    { 56,  5,  6, 4 },  // 14  0x00f  BS
    {  0,  9,  6, 4 },  // 15  0x010  TAB
    {  6,  9,  4, 4 },  // 16  0x011  Ｑ　た　
    { 10,  9,  4, 4 },  // 17  0x012  Ｗ　て　
    { 14,  9,  4, 4 },  // 18  0x013  Ｅ　いぃ
    { 18,  9,  4, 4 },  // 19  0x014  Ｒ　す　
    { 22,  9,  4, 4 },  // 20  0x015  Ｔ　か　
    { 26,  9,  4, 4 },  // 21  0x016  Ｙ　ん　
    { 30,  9,  4, 4 },  // 22  0x017  Ｕ　な　
    { 34,  9,  4, 4 },  // 23  0x018  Ｉ　に　
    { 38,  9,  4, 4 },  // 24  0x019  Ｏ　ら　
    { 42,  9,  4, 4 },  // 25  0x01a  Ｐ　せ　
    { 46,  9,  4, 4 },  // 26  0x01b  ＠｀゛　
    { 50,  9,  4, 4 },  // 27  0x01c  ［｛゜「
    { 55,  9,  7, 8 },  // 28  0x01d  リターン
    {  7, 13,  4, 4 },  // 29  0x01e  Ａ　ち　
    { 11, 13,  4, 4 },  // 30  0x01f  Ｓ　と　
    { 15, 13,  4, 4 },  // 31  0x020  Ｄ　し　
    { 19, 13,  4, 4 },  // 32  0x021  Ｆ　は　
    { 23, 13,  4, 4 },  // 33  0x022  Ｇ　き　
    { 27, 13,  4, 4 },  // 34  0x023  Ｈ　く　
    { 31, 13,  4, 4 },  // 35  0x024  Ｊ　ま　
    { 35, 13,  4, 4 },  // 36  0x025  Ｋ　の　
    { 39, 13,  4, 4 },  // 37  0x026  Ｌ　り　
    { 43, 13,  4, 4 },  // 38  0x027  ；＋れ　
    { 47, 13,  4, 4 },  // 39  0x028  ：＊け　
    { 51, 13,  4, 4 },  // 40  0x029  ］｝む」
    {  9, 17,  4, 4 },  // 41  0x02a  Ｚ　つっ
    { 13, 17,  4, 4 },  // 42  0x02b  Ｘ　さ　
    { 17, 17,  4, 4 },  // 43  0x02c  Ｃ　そ　
    { 21, 17,  4, 4 },  // 44  0x02d  Ｖ　ひ　
    { 25, 17,  4, 4 },  // 45  0x02e  Ｂ　こ　
    { 29, 17,  4, 4 },  // 46  0x02f  Ｎ　み　
    { 33, 17,  4, 4 },  // 47  0x030  Ｍ　も　
    { 37, 17,  4, 4 },  // 48  0x031  ，＜ね、
    { 41, 17,  4, 4 },  // 49  0x032  ．＞る。
    { 45, 17,  4, 4 },  // 50  0x033  ／？め・
    { 49, 17,  4, 4 },  // 51  0x034  　＿ろ□
    { 21, 21, 14, 4 },  // 52  0x035  スペース
    { 64,  5,  4, 4 },  // 53  0x036  HOME
    { 72,  5,  4, 4 },  // 54  0x037  DEL
    { 64,  9,  4, 4 },  // 55  0x038  ROLLUP
    { 68,  9,  4, 4 },  // 56  0x039  ROLLDOWN
    { 72,  9,  4, 4 },  // 57  0x03a  UNDO
    { 64, 13,  4, 8 },  // 58  0x03b  ←
    { 68, 13,  4, 4 },  // 59  0x03c  ↑
    { 72, 13,  4, 8 },  // 60  0x03d  →
    { 68, 17,  4, 4 },  // 61  0x03e  ↓
    { 78,  5,  4, 4 },  // 62  0x03f  CLR
    { 82,  5,  4, 4 },  // 63  0x040  ／
    { 86,  5,  4, 4 },  // 64  0x041  ＊
    { 90,  5,  4, 4 },  // 65  0x042  －
    { 78,  9,  4, 2 },  // 66  0x043  ７
    { 82,  9,  4, 2 },  // 67  0x044  ８
    { 86,  9,  4, 2 },  // 68  0x045  ９
    { 90,  9,  4, 4 },  // 69  0x046  ＋
    { 78, 13,  4, 2 },  // 70  0x047  ４
    { 82, 13,  4, 2 },  // 71  0x048  ５
    { 86, 13,  4, 2 },  // 72  0x049  ６
    { 90, 13,  4, 4 },  // 73  0x04a  ＝
    { 78, 17,  4, 2 },  // 74  0x04b  １
    { 82, 17,  4, 2 },  // 75  0x04c  ２
    { 86, 17,  4, 2 },  // 76  0x04d  ３
    { 90, 17,  4, 8 },  // 77  0x04e  ENTER
    { 78, 21,  4, 2 },  // 78  0x04f  ０
    { 82, 21,  4, 2 },  // 79  0x050  ，
    { 86, 21,  4, 2 },  // 80  0x051  ．
    { 82,  0,  4, 4 },  // 81  0x052  記号入力
    { 86,  0,  4, 4 },  // 82  0x053  登録
    { 90,  0,  4, 4 },  // 83  0x054  HELP
    { 11, 21,  5, 4 },  // 84  0x055  XF1
    { 16, 21,  5, 4 },  // 85  0x056  XF2
    { 35, 21,  6, 4 },  // 86  0x057  XF3
    { 41, 21,  5, 4 },  // 87  0x058  XF4
    { 46, 21,  5, 4 },  // 88  0x059  XF5
    { 64,  0,  4, 4 },  // 89  0x05a  かな
    { 68,  0,  4, 4 },  // 90  0x05b  ローマ字
    { 72,  0,  4, 4 },  // 91  0x05c  コード入力
    { 78,  0,  4, 4 },  // 92  0x05d  CAPS
    { 68,  5,  4, 4 },  // 93  0x05e  INS
    {  7, 21,  4, 4 },  // 94  0x05f  ひらがな
    { 51, 21,  4, 4 },  // 95  0x060  全角
    {  0,  0,  4, 4 },  // 96  0x061  BREAK
    {  5,  0,  4, 4 },  // 97  0x062  COPY
    { 11,  1,  5, 3 },  // 98  0x063  F1
    { 16,  1,  5, 3 },  // 99  0x064  F2
    { 21,  1,  5, 3 },  //100  0x065  F3
    { 26,  1,  5, 3 },  //101  0x066  F4
    { 31,  1,  5, 3 },  //102  0x067  F5
    { 37,  1,  5, 3 },  //103  0x068  F6
    { 42,  1,  5, 3 },  //104  0x069  F7
    { 47,  1,  5, 3 },  //105  0x06a  F8
    { 52,  1,  5, 3 },  //106  0x06b  F9
    { 57,  1,  5, 3 },  //107  0x06c  F10
    {  0, 17,  9, 4 },  //108  0x070  SHIFT
    {  0, 13,  7, 4 },  //109  0x071  CTRL
    { 64, 21,  6, 4 },  //110  0x072  OPT.1
    { 70, 21,  6, 4 },  //111  0x073  OPT.2
    null             ,  //112  0x074  NUM
    { 78, 11,  4, 2 },  //113  0x143  NumLk７
    { 82, 11,  4, 2 },  //114  0x144  NumLk８
    { 86, 11,  4, 2 },  //115  0x145  NumLk９
    { 78, 15,  4, 2 },  //116  0x147  NumLk４
    { 82, 15,  4, 2 },  //117  0x148  NumLk５
    { 86, 15,  4, 2 },  //118  0x149  NumLk６
    { 78, 19,  4, 2 },  //119  0x14b  NumLk１
    { 82, 19,  4, 2 },  //120  0x14c  NumLk２
    { 86, 19,  4, 2 },  //121  0x14d  NumLk３
    { 78, 23,  4, 2 },  //122  0x14f  NumLk０
    { 82, 23,  4, 2 },  //123  0x150  NumLk，
    { 86, 23,  4, 2 },  //124  0x151  NumLk．
    { 53, 17,  9, 4 },  //125  0x170  右SHIFT
  };

  //文字
  public static final String[] TEXT_ARRAY = (
    "ESC,"        +  //  0  0x001
    "１！ぬ　,"   +  //  1  0x002
    "２＂ふ　,"   +  //  2  0x003
    "３＃あぁ,"   +  //  3  0x004
    "４＄うぅ,"   +  //  4  0x005
    "５％えぇ,"   +  //  5  0x006
    "６＆おぉ,"   +  //  6  0x007
    "７＇やゃ,"   +  //  7  0x008
    "８（ゆゅ,"   +  //  8  0x009
    "９）よょ,"   +  //  9  0x00a
    "０　わを,"   +  // 10  0x00b
    "－＝ほ　,"   +  // 11  0x00c
    "＾～へ　,"   +  // 12  0x00d
    "￥｜ー　,"   +  // 13  0x00e
    "BS,"         +  // 14  0x00f
    "TAB,"        +  // 15  0x010
    "Ｑ　た　,"   +  // 16  0x011
    "Ｗ　て　,"   +  // 17  0x012
    "Ｅ　いぃ,"   +  // 18  0x013
    "Ｒ　す　,"   +  // 19  0x014
    "Ｔ　か　,"   +  // 20  0x015
    "Ｙ　ん　,"   +  // 21  0x016
    "Ｕ　な　,"   +  // 22  0x017
    "Ｉ　に　,"   +  // 23  0x018
    "Ｏ　ら　,"   +  // 24  0x019
    "Ｐ　せ　,"   +  // 25  0x01a
    "＠｀゛　,"   +  // 26  0x01b
    "［｛゜「,"   +  // 27  0x01c
    "リターン,"   +  // 28  0x01d
    "Ａ　ち　,"   +  // 29  0x01e
    "Ｓ　と　,"   +  // 30  0x01f
    "Ｄ　し　,"   +  // 31  0x020
    "Ｆ　は　,"   +  // 32  0x021
    "Ｇ　き　,"   +  // 33  0x022
    "Ｈ　く　,"   +  // 34  0x023
    "Ｊ　ま　,"   +  // 35  0x024
    "Ｋ　の　,"   +  // 36  0x025
    "Ｌ　り　,"   +  // 37  0x026
    "；＋れ　,"   +  // 38  0x027
    "：＊け　,"   +  // 39  0x028
    "］｝む」,"   +  // 40  0x029
    "Ｚ　つっ,"   +  // 41  0x02a
    "Ｘ　さ　,"   +  // 42  0x02b
    "Ｃ　そ　,"   +  // 43  0x02c
    "Ｖ　ひ　,"   +  // 44  0x02d
    "Ｂ　こ　,"   +  // 45  0x02e
    "Ｎ　み　,"   +  // 46  0x02f
    "Ｍ　も　,"   +  // 47  0x030
    "，＜ね、,"   +  // 48  0x031
    "．＞る。,"   +  // 49  0x032
    "／？め・,"   +  // 50  0x033
    "　＿ろ□,"   +  // 51  0x034
    "スペース,"   +  // 52  0x035
    "HOME,"       +  // 53  0x036
    "DEL,"        +  // 54  0x037
    "ROLLUP,"     +  // 55  0x038
    "ROLLDOWN,"   +  // 56  0x039
    "UNDO,"       +  // 57  0x03a
    "←,"         +  // 58  0x03b
    "↑,"         +  // 59  0x03c
    "→,"         +  // 60  0x03d
    "↓,"         +  // 61  0x03e
    "CLR,"        +  // 62  0x03f
    "／,"         +  // 63  0x040
    "＊,"         +  // 64  0x041
    "－,"         +  // 65  0x042
    "７,"         +  // 66  0x043
    "８,"         +  // 67  0x044
    "９,"         +  // 68  0x045
    "＋,"         +  // 69  0x046
    "４,"         +  // 70  0x047
    "５,"         +  // 71  0x048
    "６,"         +  // 72  0x049
    "＝,"         +  // 73  0x04a
    "１,"         +  // 74  0x04b
    "２,"         +  // 75  0x04c
    "３,"         +  // 76  0x04d
    "ENTER,"      +  // 77  0x04e
    "０,"         +  // 78  0x04f
    "，,"         +  // 79  0x050
    "．,"         +  // 80  0x051
    "記号入力,"   +  // 81  0x052
    "登録,"       +  // 82  0x053
    "HELP,"       +  // 83  0x054
    "XF1,"        +  // 84  0x055
    "XF2,"        +  // 85  0x056
    "XF3,"        +  // 86  0x057
    "XF4,"        +  // 87  0x058
    "XF5,"        +  // 88  0x059
    "かな,"       +  // 89  0x05a
    "ローマ字,"   +  // 90  0x05b
    "コード入力," +  // 91  0x05c
    "CAPS,"       +  // 92  0x05d
    "INS,"        +  // 93  0x05e
    "ひらがな,"   +  // 94  0x05f
    "全角,"       +  // 95  0x060
    "BREAK,"      +  // 96  0x061
    "COPY,"       +  // 97  0x062
    "F1,"         +  // 98  0x063
    "F2,"         +  // 99  0x064
    "F3,"         +  //100  0x065
    "F4,"         +  //101  0x066
    "F5,"         +  //102  0x067
    "F6,"         +  //103  0x068
    "F7,"         +  //104  0x069
    "F8,"         +  //105  0x06a
    "F9,"         +  //106  0x06b
    "F10,"        +  //107  0x06c
    "SHIFT,"      +  //108  0x070
    "CTRL,"       +  //109  0x071
    "OPT.1,"      +  //110  0x072
    "OPT.2,"      +  //111  0x073
    "NUM,"        +  //112  0x074
    "NumLk７,"    +  //113  0x143
    "NumLk８,"    +  //114  0x144
    "NumLk９,"    +  //115  0x145
    "NumLk４,"    +  //116  0x147
    "NumLk５,"    +  //117  0x148
    "NumLk６,"    +  //118  0x149
    "NumLk１,"    +  //119  0x14b
    "NumLk２,"    +  //120  0x14c
    "NumLk３,"    +  //121  0x14d
    "NumLk０,"    +  //122  0x14f
    "NumLk，,"    +  //123  0x150
    "NumLk．,"    +  //124  0x151
    "右SHIFT"        //125  0x170
    ).split (",");

  //ファイル名
  public File lastFile;

  //フレーム
  public JFrame mainFrame;

  //パネル
  public JComponent mainPanel;

  //マップ
  public int[] extendedKeyCodeArray;
  public int[] keyCharArray;
  public int[] keyCodeArray;
  public int[] keyLocationArray;
  public int[] modifiersExArray;
  public String[] paramStringArray;
  public JTextField[] textFieldArray;

  //メイン
  public static void main (String[] args) {
    javax.swing.SwingUtilities.invokeLater (new keymap ());
  }

  //初期化
  @Override public void run () {

    //ファイル名
    String currentDirectory = null;
    try {
      currentDirectory = System.getProperty ("user.dir");
    } catch (Exception e) {
    }
    if (currentDirectory == null) {
      currentDirectory = ".";
    }
    lastFile = new File (currentDirectory + File.separator + "keymap.dat");

    //フレーム
    JFrame.setDefaultLookAndFeelDecorated (true);
    JDialog.setDefaultLookAndFeelDecorated (true);
    mainFrame = new JFrame ("keymap");
    mainFrame.setLocationByPlatform (true);
    mainFrame.setBackground (Color.white);
    mainFrame.setDefaultCloseOperation (JFrame.EXIT_ON_CLOSE);
    //mainFrame.setDefaultCloseOperation (WindowConstants.DISPOSE_ON_CLOSE);

    //メニュー
    JMenuItem resetMenuItem = new JMenuItem ();
    resetMenuItem.setText ("白紙(R)");
    resetMenuItem.setMnemonic ('R');
    resetMenuItem.setActionCommand ("reset");
    resetMenuItem.addActionListener (this);

    JMenuItem openMenuItem = new JMenuItem ();
    openMenuItem.setText ("開く(O)");
    openMenuItem.setMnemonic ('O');
    openMenuItem.setActionCommand ("open");
    openMenuItem.addActionListener (this);

    JMenuItem saveMenuItem = new JMenuItem ();
    saveMenuItem.setText ("保存(S)");
    saveMenuItem.setMnemonic ('S');
    saveMenuItem.setActionCommand ("save");
    saveMenuItem.addActionListener (this);

    JMenuItem quitMenuItem = new JMenuItem ();
    quitMenuItem.setText ("終了(Q)");
    quitMenuItem.setMnemonic ('Q');
    quitMenuItem.setActionCommand ("quit");
    quitMenuItem.addActionListener (this);

    JMenu fileMenu = new JMenu ();
    fileMenu.setText ("ファイル(F)");
    fileMenu.setMnemonic ('F');
    fileMenu.add (resetMenuItem);
    fileMenu.add (openMenuItem);
    fileMenu.add (saveMenuItem);
    fileMenu.addSeparator ();
    fileMenu.add (quitMenuItem);

    JMenuBar menuBar = new JMenuBar ();
    menuBar.add (fileMenu);

    mainFrame.setJMenuBar (menuBar);

    //マップ
    extendedKeyCodeArray = new int[KEYS];
    keyCharArray = new int[KEYS];
    keyCodeArray = new int[KEYS];
    keyLocationArray = new int[KEYS];
    modifiersExArray = new int[KEYS];
    paramStringArray = new String[KEYS];
    textFieldArray = new JTextField[KEYS];

    JPanel keyboardPanel = new JPanel ();
    keyboardPanel.setLayout (null);
    keyboardPanel.setPreferredSize (new Dimension (KEYBOARD_WIDTH, KEYBOARD_HEIGHT));

    for (int i = 0; i < KEYS; i++) {
      clearKey (i);
      textFieldArray[i] = null;

      int[] bounds = BOUNDS_ARRAY[i];
      if (bounds != null) {

        JLabel label = new JLabel (TEXT_ARRAY[i]);
        label.setBounds (PADDING_LEFT + COL_WIDTH * bounds[0],
                         PADDING_TOP + ROW_HEIGHT * bounds[1],
                         COL_WIDTH * bounds[2],
                         LABEL_HEIGHT);
        label.setHorizontalAlignment (SwingConstants.CENTER);
        keyboardPanel.add (label);

        JTextField textField = new JTextField ("", 10);
        textFieldArray[i] = textField;
        textField.setBounds (PADDING_LEFT + COL_WIDTH * bounds[0],
                             PADDING_TOP + ROW_HEIGHT * bounds[1] + LABEL_HEIGHT,
                             COL_WIDTH * bounds[2],
                             ROW_HEIGHT * bounds[3] - LABEL_HEIGHT);
        textField.setHorizontalAlignment (JTextField.CENTER);
        if (i == 15) {  //TAB
          textField.setFocusTraversalKeysEnabled (false);  //Tabを入力できる
        } else {
          textField.setFocusTraversalKeysEnabled (true);  //Tabで次のキーに移る
        }
        textField.setName (String.valueOf (i));
        textField.addKeyListener (this);
        keyboardPanel.add (textField);

        drawKey (i);

      }  //if bounds!=null

    }  //for i

    //パネル
    mainPanel = new JScrollPane (keyboardPanel);
    mainPanel.setPreferredSize (new Dimension (KEYBOARD_WIDTH + 3, KEYBOARD_HEIGHT + 3));
    mainFrame.setContentPane (mainPanel);
    mainFrame.pack ();
    mainFrame.setVisible (true);

  }  //run

  //消去
  public void clearKey (int i) {
    extendedKeyCodeArray[i] = KeyEvent.VK_UNDEFINED;
    keyCharArray[i] = 0;
    keyCodeArray[i] = KeyEvent.VK_UNDEFINED;
    keyLocationArray[i] = KeyEvent.KEY_LOCATION_UNKNOWN;
    modifiersExArray[i] = 0;
    paramStringArray[i] = "";
  }  //clearKey

  //表示
  public void drawKey (int i) {
    JTextField textField = textFieldArray[i];
    if (textField != null) {
      int keyCode = keyCodeArray[i];
      int keyLocation = keyLocationArray[i];
      String paramString = paramStringArray[i];
      Color background = Color.gray;
      switch (keyLocation) {
      case KeyEvent.KEY_LOCATION_LEFT:
        background = Color.cyan;
        break;
      case KeyEvent.KEY_LOCATION_NUMPAD:
        background = Color.orange;
        break;
      case KeyEvent.KEY_LOCATION_RIGHT:
        background = Color.pink;
        break;
      case KeyEvent.KEY_LOCATION_STANDARD:
        background = Color.yellow;
        break;
      case KeyEvent.KEY_LOCATION_UNKNOWN:
        background = Color.lightGray;
        break;
      }
      textField.setBackground (background);
      if (keyCode == KeyEvent.VK_UNDEFINED) {
        textField.setText ("");
      } else {
        textField.setText (KeyEvent.getKeyText (keyCode));
      }
    }
  }  //drawKey

  //アクションリスナー
  @Override public void actionPerformed (ActionEvent e) {
    switch (e.getActionCommand ()) {
    case "reset":
      reset ();
      break;
    case "open":
      open ();
      break;
    case "save":
      save ();
      break;
    case "quit":
      quit ();
      break;
    }
  }  //actionPerformed

  //白紙
  public void reset () {
    if (JOptionPane.showConfirmDialog (mainFrame,
                                       "白紙に戻します",
                                       "確認",
                                       JOptionPane.YES_NO_OPTION,
                                       JOptionPane.PLAIN_MESSAGE) == JOptionPane.YES_OPTION) {
      for (int i = 0; i < KEYS; i++) {
        clearKey (i);
        drawKey (i);
      }
    }
  }  //reset

  //開く
  public void open () {
    JFileChooser fileChooser = new JFileChooser ();
    fileChooser.setSelectedFile (lastFile);
    if (fileChooser.showOpenDialog (mainFrame) == JFileChooser.APPROVE_OPTION) {
      for (int i = 0; i < KEYS; i++) {
        clearKey (i);
        drawKey (i);
      }
      File file = fileChooser.getSelectedFile ();
      lastFile = file;
      try (BufferedReader br = new BufferedReader (new FileReader (file, Charset.forName ("UTF-8")))) {
        for (String line = br.readLine (); line != null; line = br.readLine ()) {
          if (!line.startsWith ("#")) {
            String[] fieldArray = line.split ("\t");
            if (fieldArray.length == 7) {
              int number = Integer.parseInt (fieldArray[0]);
              for (int i = 0; i < KEYS; i++) {
                if (NUMBER_ARRAY[i] == number) {
                  extendedKeyCodeArray[i] = Integer.parseInt (fieldArray[1]);
                  keyCharArray[i] = Integer.parseInt (fieldArray[2]);
                  keyCodeArray[i] = Integer.parseInt (fieldArray[3]);
                  keyLocationArray[i] = Integer.parseInt (fieldArray[4]);
                  modifiersExArray[i] = Integer.parseInt (fieldArray[5]);
                  paramStringArray[i] = fieldArray[6];
                  drawKey (i);
                  break;
                }
              }
            }
          }
        }
      } catch (IOException ioe) {
        //ioe.printStackTrace ();
      }
    }
  }  //open

  //保存
  public void save () {
    StringBuilder sb = new StringBuilder ();
    for (String key : new String[] {
      "os.name", "os.version",
    }) {
      try {
        String value = System.getProperty (key);
        sb.append ("# ").append (key).append (" = ").append (value).append ('\n');
      } catch (Exception e) {
      }
    }
    sb.append ("# number extendedKeyCode keyChar keyCode keyLocation modifiersEx paramString\n");
    for (int i = 0; i < KEYS; i++) {
      if (keyCodeArray[i] != KeyEvent.VK_UNDEFINED) {
        sb.append (NUMBER_ARRAY[i]).append ('\t')
          .append (extendedKeyCodeArray[i]).append ('\t')
            .append (keyCharArray[i]).append ('\t')
              .append (keyCodeArray[i]).append ('\t')
                .append (keyLocationArray[i]).append ('\t')
                  .append (modifiersExArray[i]).append ('\t')
                    .append (paramStringArray[i]).append ('\n');
      }
    }
    String data = sb.toString ();
    JFileChooser fileChooser = new JFileChooser ();
    fileChooser.setSelectedFile (lastFile);
    if (fileChooser.showSaveDialog (mainFrame) == JFileChooser.APPROVE_OPTION) {
      File file = fileChooser.getSelectedFile ();
      lastFile = file;
      try (BufferedWriter bw = new BufferedWriter (new FileWriter (file, Charset.forName ("UTF-8")))) {
        bw.write (data);
      } catch (IOException ioe) {
        //ioe.printStackTrace ();
      }
    }
  }  //save

  //終了
  public void quit () {
    System.exit (0);
  }  //quit

  //キーリスナー
  @Override public void keyPressed (KeyEvent ke) {
    int i = Integer.parseInt (ke.getComponent ().getName ());
    int keyCode = ke.getKeyCode ();
    if (i != 0 && keyCode == KeyEvent.VK_ESCAPE) {  //ESC以外でEscが押された
      clearKey (i);
      drawKey (i);
    } else {  //ESCまたはEsc以外が押された
      int extendedKeyCode = ke.getExtendedKeyCode ();
      int keyChar = (int) ke.getKeyChar ();
      int keyLocation = ke.getKeyLocation ();
      int modifiersEx = ke.getModifiersEx ();
      String paramString = ke.paramString ();
      extendedKeyCodeArray[i] = extendedKeyCode;
      keyCharArray[i] = keyChar;
      keyCodeArray[i] = keyCode;
      keyLocationArray[i] = keyLocation;
      modifiersExArray[i] = modifiersEx;
      paramStringArray[i] = paramString;
      drawKey (i);
      for (int j = 0; j < KEYS; j++) {
        if (j != i &&
            extendedKeyCodeArray[j] == extendedKeyCode &&
            keyCharArray[j] == keyChar &&
            keyCodeArray[j] == keyCode &&
            keyLocationArray[j] == keyLocation &&
            modifiersExArray[j] == modifiersEx &&
            paramStringArray[j].equals (paramString)) {  //他のキーに割り当てられていたら取り除く
          clearKey (j);
          drawKey (j);
          break;
        }
      }
    }
    ke.consume ();
  }  //keyPressed

  @Override public void keyReleased (KeyEvent ke) {
    ke.consume ();
  }  //keyReleased

  @Override public void keyTyped (KeyEvent ke) {
    ke.consume ();
  }  //keyTyped

}  //class keymap
