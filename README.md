Tang-nano HDMI-VGA output sample
================================

Tang-nanoボードでHDMI出力をする実験サンプルです。

- ボード上のRGB LEDがグラデーション点灯します
- ピン38～45にHDMI信号（VGA解像度）を出力します
- DVDロゴ(？)のアニメーション

[View tweet<br>
<img src="https://raw.githubusercontent.com/osafune/tangnano-hdmi/master/img/twitter_1226971066121310210.png" width="504" height="445">
](https://twitter.com/s_osafune/status/1226971066121310210)

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
	- MAX10とかCyclone10LPとか使ったほうがいいよ（→[HDLのMISCモジュール集](https://github.com/osafune/misc_hdl_module#dvi_encoder)）。
	- GW1NのPLLの限界、IOEの構造上の限界、STAレポートで調整できない限界。

