Tang-nano HDMI-VGA output sample
================================

Tang-nanoボードでHDMI出力をする実験サンプルです。

- ボード上のRGB LEDがグラデーション点灯します
- ピン38～45にHDMI信号（480p VGA解像度）を出力します
- DVDロゴ(？)のアニメーション

[View tweet<br>
<img src="https://raw.githubusercontent.com/osafune/tangnano-hdmi/master/img/twitter_1226971066121310210.png" width="504" height="445">
](https://twitter.com/s_osafune/status/1226971066121310210)

External connection
-------------------

- HDMIコネクタの外部回路

<img src="https://raw.githubusercontent.com/osafune/tangnano-hdmi/master/img/tangnano-hdmiconn.png" width="600" height="564">



Known issues
------------

- 画面にノイズが乗る
	- 原因として以下の2点が大きな要因です。何回かリセットするといい感じの位相が得られるかもしれません。

- 信号規格がHDMI規格に準拠していない
	- ジッタ、アイともにHDMI規格にはたぶん収まっていません。Tang-NANOボード上のDC/DCを止めると多少改善されます。
	- Tang-NANOボードのクロック周波数から無理矢理VGAクロックを作り出しているので安定性が悪いです。

- データスキューの未調整
	- ~~TMDS信号群のうちFastとSlowが2ns近く離れている様子。~~ →クロックツリーを見直して解決しました。
	- IODELAYで調整できると考えています（プリミティブは実装済み）。

- 解決の見込みは？
	- 実験なので実用レベルへのブラッシュアップの予定はありません。
	- GW1NのPLLの限界、IOEの構造上の限界、STAレポートで検証できない限界。
	- 実用にするならMAX10とかCyclone10LPとか使ったほうがいいよ（→[HDLのMISCモジュール集](https://github.com/osafune/misc_hdl_module#dvi_encoder)）。
