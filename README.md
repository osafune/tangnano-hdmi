Tang-nano HDMI-VGA output sample
================================

Tang-nanoボードでHDMI出力をするサンプルです。

- ボード上のRGB LEDがグラデーション点灯します
- ピン38～45にHDMI信号（VGA解像度）を出力します
- DVDロゴ(？)のアニメーション

[View Twieete](https://twitter.com/s_osafune/status/1226971066121310210)
<img src="https://raw.githubusercontent.com/osafune/tangnano-hdmi/master/img/twitter_1226971066121310210.png" width="504" height="445">

<blockquote class="twitter-tweet" data-theme="light"><p lang="ja" dir="ltr">Tang-NANOでHDMI出力できたよー。ロジック使用率は72% <a href="https://t.co/FEUQ0dh5A9">pic.twitter.com/FEUQ0dh5A9</a></p>&mdash; 長船 俊＠Nico-TECH:自造社団 (@s_osafune) <a href="https://twitter.com/s_osafune/status/1226971066121310210?ref_src=twsrc%5Etfw">February 10, 2020</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>



External connection
-------------------

- HDMIコネクタの外部回路

<img src="https://raw.githubusercontent.com/osafune/tangnano-hdmi/master/img/tangnano-hdmiconn.png" width="700" height="657">



Known issues
------------

- 画面にノイズが乗る
	- 原因として以下の2点が大きな要因です。

- 信号規格がHDMI規格に準拠していない
	- クロックジッタ、ライン開口ともにHDMI規格には収まっていません。
	- 簡易接続なので。

- データスキューの未調整
	- TMDS信号群のうちFastとSlowが2ns近く離れている様子。
	- IODELAYで調整できると考えています（プリミティブは実装済み）。

- 解決の見込みは？
	- 実験なので特に実用レベルまでブラッシュアップの予定はありません。
	- MAX10とかCyclone10LPとか使ったほうがいいよ（720pでの安定動作評価済み）
	- GW1NのPLLの限界、IOEの構造上の限界、STAレポートで調整できない限界。

