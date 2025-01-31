# lilToon MsdfMask Extension

## 概要
* lilToon で設定できる一部のマスクテクスチャを MSDF (Multi-channel Signed Distance Field) テクスチャとして
  扱えるようにしたカスタムシェーダーです。
* カットアウトで切り抜きたいけどエッジを立たせようとするとアルファマスクが無駄に大きくなってしまう……
  というような場面で価値を発揮すると思います。

## 使い方
1. 先に lilToon を Unity プロジェクトにインポートしておいてください(VPM 可)。
2. lilToon_MsdfMask.unitypackage を放り込んでください。
3. マテリアルのシェーダー一覧から "MsdfMask/lilToon" を選択すると使うことができます。
    * カスタムプロパティーの項目にどのマスクを MSDF テクスチャとして扱うか、また値を反転するかの選択肢が生えます。
    * 現在は AlphaMask, MainColor2, MainColor3, Shadow, Emission1, Emisson2, MatCap1, MatCap2 に対応しています。
4. MSDF テクスチャの作り方は各自でどうにかしてください(ここに書くには長すぎる)。
    * lilToon_MsdfMask 独自の仕様として、指定されたテクスチャの A チャンネルを従来のマスクの値のように扱います。
    * RGB を MSDF として 0/1 の判定のみに使い、 1 になった範囲の値を A から取ってくる感じです。
    * [msdfgen](https://github.com/Chlumsky/msdfgen) の mtsdf モードは使えません。普通に msdf モードを使ってね。

おまけ機能としてアルファマスク 2nd も実装しました。
衣装が既にアルファマスクを使っていてその上から追加で独自のマスクをかけたいときに有用だと思います。

## ライセンス
lilToon_MsdfMask は lilToon のコードの一部を改変して作成されました。
lilToon は The MIT License でライセンスされています(LICENSE-lilToon.txt も参照してください)。
