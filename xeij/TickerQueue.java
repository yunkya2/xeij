//========================================================================================
//  TickerQueue.java
//    en:Sort of a simple task scheduler
//    ja:簡易タスクスケジューラのようなもの
//  Copyright (C) 2003-2019 Makoto Kamada
//
//  This file is part of the XEiJ (X68000 Emulator in Java).
//  You can use, modify and redistribute the XEiJ if the conditions are met.
//  Read the XEiJ License for more details.
//  https://stdkmd.net/xeij/
//========================================================================================

package xeij;

import java.lang.*;  //Boolean,Character,Class,Comparable,Double,Exception,Float,IllegalArgumentException,Integer,InterruptedException,Long,Math,Number,Object,Runnable,SecurityException,String,StringBuilder,System
import java.util.*;  //ArrayList,Arrays,Calendar,GregorianCalendar,HashMap,Map,Map.Entry,TimeZone,Timer,TimerTask,TreeMap

public class TickerQueue {

  public static final boolean TKQ_USE_TICKER0 = true;  //true=tkqTicker0を使う
  public static final int TKQ_MASK = 255;  //キューに入れられるティッカーの数の上限。2の累乗-1に限る


  //class Ticker
  //  ティッカー
  public static class Ticker {
    public Ticker () {
      time = Long.MAX_VALUE;  //キューに入っていない
    }
    protected long time;  //このティッカーを呼び出す時刻。キューに入っていないときLong.MAX_VALUE。番兵はLong.MAX_VALUE。外部から書き換えないこと
    //  tickが呼び出された時点でthisはキューから削除されている
    //  tickの中でtkqAddを呼び出してthisまたは他のティッカーをキューに追加できる
    //  tickの中でtkqRemoveを呼び出して他のティッカーをキューから削除できる
    //  tickの中でtkqRemoveAllを呼び出してすべてのティッカーをキューから削除できる
    //  tickの中でtkqRunを呼び出してはならない
    protected void tick () {
    }
  }  //class Ticker


  //tkqArray
  //  tkqArray[tkqHead]が先頭(timeが最小)
  //  tkqArray[tkqTail-1&TKQ_MASK]が末尾(timeが最大)
  //  tkqArray[tkqTail]はtimeがLong.MAX_VALUEの番兵
  //  先頭から末尾までtimeの昇順(timeが同じときは追加順)で隙間なく並べる
  //  配列の末尾で先頭に折り返す
  //  未使用領域は不定
  public static final Ticker[] tkqArray = new Ticker[TKQ_MASK + 1];  //キューに入っているティッカーの配列
  public static int tkqHead;  //先頭の位置。キューが空のときはtkqHead==tkqTailすなわち番兵の位置
  public static int tkqTail;  //末尾の直後の位置すなわち番兵の位置
  public static Ticker tkqTicker0;  //先頭のティッカー。tkqArray[tkqHead]のコピー。キューが空のときは番兵
  public static long tkqTime0;  //先頭のtime。tkqArray[tkqHead].timeのコピー。キューが空のときは番兵のtimeすなわちLong.MAX_VALUE


  //tkqInit ()
  //  初期化
  public static void tkqInit () {
    //tkqArray = new Ticker[TKQ_MASK + 1];
    if (TKQ_USE_TICKER0) {
      tkqTicker0 = tkqArray[tkqTail = tkqHead = 0] = new Ticker ();  //先頭の位置と番兵の位置と番兵と先頭のティッカー
    } else {
      tkqArray[tkqTail = tkqHead = 0] = new Ticker ();  //先頭の位置と番兵の位置と番兵と先頭のティッカー
    }
    tkqTime0 = tkqTicker0.time = Long.MAX_VALUE;  //番兵のtimeと先頭のtime
  }

  //tkqRun (currentTime)
  //  先頭のティッカーを取り除いてからtickを呼び出すことをtimeがcurrentTime以下のティッカーがなくなるまで繰り返す
  //  currentTime==Long.MAX_VALUEは指定不可
  public static void tkqRun (long currentTime) {
    if (TKQ_USE_TICKER0) {
      while (tkqTime0 <= currentTime) {  //timeがcurrentTime以下のティッカーがある
        Ticker ticker0 = tkqTicker0;  //先頭のティッカー
        tkqTime0 = (tkqTicker0 = tkqArray[tkqHead = tkqHead + 1 & TKQ_MASK]).time;  //次回の先頭の位置と次回の先頭のティッカーと次回の先頭のtime。キューが空になるとtkqTime0が番兵のtimeのLong.MAX_VALUEになって止まる
        ticker0.time = Long.MAX_VALUE;  //キューに入っていない
        ticker0.tick ();  //先頭のtickを呼び出す。ここでtkqAddやtkqRemoveが呼び出される場合があるのでその前にキューを更新しておく
      }
    } else {
      if (tkqTime0 <= currentTime) {  //timeがcurrentTime以下のティッカーがある
        Ticker nextTicker0 = tkqArray[tkqHead];  //次回の先頭のティッカー
        do {
          Ticker ticker0 = nextTicker0;  //先頭のティッカー
          tkqTime0 = (nextTicker0 = tkqArray[tkqHead = tkqHead + 1 & TKQ_MASK]).time;  //次回の先頭の位置と次回の先頭のティッカーと次回の先頭のtime。キューが空になるとtkqTime0が番兵のtimeのLong.MAX_VALUEになって止まる
          ticker0.time = Long.MAX_VALUE;  //キューに入っていない
          ticker0.tick ();  //先頭のtickを呼び出す。ここでtkqAddやtkqRemoveが呼び出される場合があるのでその前にキューを更新しておく
        } while (tkqTime0 <= currentTime);  //timeがcurrentTime以下のティッカーがある
      }
    }
  }  //tkqRun(long)

  //tkqAdd (newTicker, newTime)
  //  ティッカーをキューに追加する
  //  既にキューに入っているときは取り除いてからから入れ直す
  public static void tkqAdd (Ticker newTicker, long newTime) {
    if (newTicker.time != Long.MAX_VALUE) {  //既にキューに入っている
      tkqRemove (newTicker);  //取り除く
    }
    newTicker.time = newTime;
    int count = tkqTail - tkqHead & TKQ_MASK;  //キューに入っているティッカーの数。番兵を含まない
    if (count == TKQ_MASK) {  //キューが一杯で追加できない
      throw new Error ("tkqAdd: overflow");
    }
    if (count == 0 || newTime < tkqTime0) {  //先頭に追加するとき
      //  timeがnewTimeと等しいか小さいティッカーが1つもない
      if (TKQ_USE_TICKER0) {
        tkqTicker0 = tkqArray[tkqHead = tkqHead - 1 & TKQ_MASK] = newTicker;  //先頭の位置と先頭のティッカー
      } else {
        tkqArray[tkqHead = tkqHead - 1 & TKQ_MASK] = newTicker;  //先頭の位置と先頭のティッカー
      }
      tkqTime0 = newTime;  //先頭のtime
      return;
    }
    //先頭に追加しないとき
    //  timeがnewTimeと等しいか小さいティッカーが少なくとも1つある
    //  newTime==tkqTime0のときも追加順の制約で追加する位置は先頭にならない
    //timeがnewTimeよりも大きい最小を探す
    int l = 0;
    int r = count;
    while (l < r) {
      int m = l + r >> 1;
      if (tkqArray[m + tkqHead & TKQ_MASK].time <= newTime) {
        l = m + 1;
      } else {
        r = m;
      }
    }
    //  l=timeがnewTimeよりも大きい最小のオフセット。すべて大きければ0、すべて小さいか等しければcount
    //newTickerを入れるための隙間を空ける
    //  timeがnewTimeよりも大きい最小が前半にあるときは小さいか等しい方を手前に、後半にあるときは大きい方を後ろにずらす
    if (l << 1 < count) {  //timeがnewTimeよりも大きい最小が前半にあるとき
      l = l - 1 + tkqHead & TKQ_MASK;  //隙間を空ける位置。最後の移動元。timeがnewTimeよりも大きい最小のティッカーの直前の位置
      r = tkqHead = tkqHead - 1 & TKQ_MASK;  //先頭の直前の位置。最初の移動先
      while (l != r) {  //最後の移動元が移動先になる前に終了する
        int m = r + 1 & TKQ_MASK;  //移動元。移動先の直後
        tkqArray[r] = tkqArray[m];  //移動元から移動先へ、隙間を空ける位置に近い大きい方から先頭に近い小さい方へ移す
        r = m;  //今回の移動元にできた隙間を次回の移動先にする。先頭に近い小さい方から隙間を空ける位置に近い大きい方へ進む
      }
    } else {  //timeがnewTimeよりも大きい最小が後半にあるとき
      l = l + tkqHead & TKQ_MASK;  //隙間を空ける位置。最後の移動元。timeがnewTimeよりも大きい最小のティッカーの位置
      r = tkqTail = tkqTail + 1 & TKQ_MASK;  //番兵の直後の位置。最初の移動先
      while (l != r) {  //最後の移動元が移動先になる前に終了する
        int m = r - 1 & TKQ_MASK;  //移動元。移動先の直前
        tkqArray[r] = tkqArray[m];  //移動元から移動先へ、隙間を空ける位置に近い小さい方から番兵に近い大きい方へ移す
        r = m;  //今回の移動元にできた隙間を次回の移動先にする。番兵に近い大きい方から隙間を空ける位置に近い小さい方へ進む
      }
    }
    //できた隙間にnewTickerを入れる
    //  追加する位置が先頭ではないのでtkqTicker0とtkqTime0は変化しない
    tkqArray[l] = newTicker;
  }  //tkqAdd(Ticker,long)

  //tkqRemove (oldTicker)
  //  ティッカーをキューから削除する
  //  キューに入っていないときは何もしない
  public static void tkqRemove (Ticker oldTicker) {
    long oldTime = oldTicker.time;
    if (oldTime == Long.MAX_VALUE) {  //キューに入っていない
      return;
    }
    oldTicker.time = Long.MAX_VALUE;
    if (tkqHead == tkqTail) {  //キューが空
      return;
    }
    if (TKQ_USE_TICKER0) {
      if (tkqTicker0 == oldTicker) {  //先頭から削除するとき
        tkqTime0 = (tkqTicker0 = tkqArray[tkqHead = tkqHead + 1 & TKQ_MASK]).time;  //先頭の位置と先頭のティッカーと先頭のtime
        return;
      }
    } else {
      if (tkqArray[tkqHead] == oldTicker) {  //先頭から削除するとき
        tkqTime0 = tkqArray[tkqHead = tkqHead + 1 & TKQ_MASK].time;  //先頭の位置と先頭のtime
        return;
      }
    }
    //先頭から削除しないとき
    int count = tkqTail - tkqHead & TKQ_MASK;  //キューに入っているティッカーの数。番兵を含まない
    //timeがoldTimeと等しいか大きい最小のティッカーを探す
    int l = 0;
    int r = count;
    while (l < r) {
      int m = l + r >> 1;
      if (tkqArray[m + tkqHead & TKQ_MASK].time < oldTime) {
        l = m + 1;
      } else {
        r = m;
      }
    }
    //  l=timeがoldTimeと等しいか大きい最小のティッカーのオフセット。すべて等しいか大きければ0、すべて小さければcount
    //oldTickerを探す
    //  timeが等しいティッカーが複数あるときその中からoldTickerを探さなければならない
    while (l < count && tkqArray[l + tkqHead & TKQ_MASK] != oldTicker) {
      l++;
    }
    if (l == count) {  //見つからなかった
      return;
    }
    //  l=oldTickerのオフセット。先頭は除外してあるので0ではない
    //oldTickerを削除してできた隙間を詰める
    //  oldTickerが前半にあるときは小さいか等しい方を後ろに、後半にあるときは等しいか大きい方を手前にずらす
    if (l << 1 < count) {  //oldTickerが前半にあるとき
      r = l + tkqHead & TKQ_MASK;  //詰める位置。最初の移動先
      l = tkqHead & TKQ_MASK;  //先頭の位置。最後の移動元
      tkqHead = tkqHead + 1 & TKQ_MASK;
      while (l != r) {  //最後の移動元が移動先になる前に終了する
        int m = r - 1 & TKQ_MASK;  //移動元。移動先の直前
        tkqArray[r] = tkqArray[m];  //移動元から移動先へ、先頭に近い小さい方から詰める位置に近い大きい方へ移す
        r = m;  //今回の移動元にできた隙間を次回の移動先にする。詰める位置に近い大きい方から先頭に近い小さい方へ進む
      }
    } else {  //oldTickerが後半にあるとき
      r = l + tkqHead & TKQ_MASK;  //詰める位置。最初の移動先
      l = tkqTail & TKQ_MASK;  //番兵の位置。最後の移動元
      tkqTail = tkqTail - 1 & TKQ_MASK;
      while (l != r) {  //最後の移動元が移動先になる前に終了する
        int m = r + 1 & TKQ_MASK;  //移動元。移動先の直後
        tkqArray[r] = tkqArray[m];  //移動元から移動先へ、番兵に近い大きい方から詰める位置に近い小さい方へ移す
        r = m;  //今回の移動元にできた隙間を次回の移動先にする。詰める位置に近い小さい方から番兵に近い大きい方へ進む
      }
    }
    //  削除する位置が先頭ではないのでtkqTicker0とtkqTime0は変化しない
  }  //tkqRemove(Ticker)

  //tkqRemoveAll ()
  //  すべてのティッカーをキューから削除する
  public static void tkqRemoveAll () {
    while (tkqHead != tkqTail) {
      if (TKQ_USE_TICKER0) {
        tkqRemove (tkqTicker0);
      } else {
        tkqRemove (tkqArray[tkqHead]);
      }
    }
  }  //tkqRemoveAll()


  //テスト

  public static class TestTicker extends Ticker {
    private int value;
    private TestTicker (int value) {
      this.value = value;
    }
    @Override protected void tick () {
      System.out.print (time);
      System.out.print ('(');
      System.out.print (value);
      System.out.print (')');
      System.out.print (' ');
    }
  }  //class TestTicker

  public static void tkqTest () {
    tkqInit ();
    TestTicker[] tickers = new TestTicker[100];
    for (int i = 0; i < 100; i++) {
      tickers[i] = new TestTicker (i);
    }
    //正順に追加
    System.out.println ("test 1");
    for (int i = 0; i < 100; i++) {
      tkqAdd (tickers[i], i);
    }
    tkqRun (100);
    System.out.println ();
    //逆順に追加
    System.out.println ("test 2");
    for (int i = 100 - 1; i >= 0; i--) {
      tkqAdd (tickers[i], i);
    }
    tkqRun (100);
    System.out.println ();
    //ランダムに追加
    System.out.println ("test 3");
    for (int i = 0; i < 100; i++) {
      tkqAdd (tickers[i], (int) (Math.random () * 100));
    }
    tkqRun (100);
    System.out.println ();
    //偶数だけ削除
    System.out.println ("test 4");
    for (int i = 0; i < 100; i++) {
      tkqAdd (tickers[i], i);
    }
    for (int i = 0; i < 100; i += 2) {
      tkqRemove (tickers[i]);
    }
    tkqRun (100);
    System.out.println ();
    //奇数だけ削除
    System.out.println ("test 5");
    for (int i = 0; i < 100; i++) {
      tkqAdd (tickers[i], i);
    }
    for (int i = 1; i < 100; i += 2) {
      tkqRemove (tickers[i]);
    }
    tkqRun (100);
    System.out.println ();
    //50個入れた状態で50個追加して50個消費することを10回繰り返す
    {
      System.out.println ("test 6");
      int t = 0;
      for (int i = 0; i < 50; i++) {
        tkqAdd (tickers[i], t++);
      }
      for (int j = 0; j < 5; j++) {
        for (int i = 0; i < 50; i++) {
          tkqAdd (tickers[50 + i], t++);
        }
        tkqRun (t - 50 - 1);
        System.out.println ();
        for (int i = 0; i < 50; i++) {
          tkqAdd (tickers[i], t++);
        }
        tkqRun (t - 50 - 1);
        System.out.println ();
      }
    }
  }  //tkqTest ()


}  //class TickerQueue



