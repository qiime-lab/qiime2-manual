# 19. ユーティリティ

## 18. タグ付きサンプルの処理（研究員・技術員向け）

Python スクリプトでスプリットした fastq ファイルを下記コマンドで gz に圧縮する。以降は本マニュアルに沿って解析を進めれば良い。

```bash
# 「splited」というフォルダに圧縮したい fastq ファイルがある場合
gzip splited/*
```

## 20. ファイル名の一括変更

`rename.R` スクリプトを利用する。

### 準備

A列に変更前のファイル名、B列に変更後のファイル名を入力した CSV ファイルを作成する。

### 実行

```bash
Rscript rename.R rename_test.csv fastq/
```

> **注意点**:
> - CSV と `rename.R` は別の場所にあっても大丈夫
> - `"incomplete final line found by readTableHeader"` という警告が出ることがあるが問題なく実行できる
> - エラーが起きても表示されない場合があるため、実行後は目視で確認すること

---

**次のセクション**: [20. 解析のトレース](20_provenance.md)
