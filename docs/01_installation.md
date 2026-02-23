# 0. 準備

## 0.1 QIIME 2 のインストール

### macOS（conda）

Apple Silicon (M1/M2/M3/M4) と Intel の両方に対応。

```bash
# Miniconda のインストール（未インストールの場合）
# https://docs.conda.io/en/latest/miniconda.html からダウンロード

# QIIME 2 2026.1 amplicon distribution のインストール
# Apple Silicon Mac の場合
wget https://data.qiime2.org/distro/amplicon/qiime2-amplicon-2026.1-py310-osx-arm64-conda.yml
conda env create -n qiime2-2026.1 --file qiime2-amplicon-2026.1-py310-osx-arm64-conda.yml

# Intel Mac の場合
wget https://data.qiime2.org/distro/amplicon/qiime2-amplicon-2026.1-py310-osx-conda.yml
conda env create -n qiime2-2026.1 --file qiime2-amplicon-2026.1-py310-osx-conda.yml

# 環境の有効化
conda activate qiime2-2026.1

# 動作確認
qiime --version
```

### Linux（conda）

```bash
wget https://data.qiime2.org/distro/amplicon/qiime2-amplicon-2026.1-py310-linux-conda.yml
conda env create -n qiime2-2026.1 --file qiime2-amplicon-2026.1-py310-linux-conda.yml
conda activate qiime2-2026.1
```

### Windows（WSL2）

> **⚠️ 旧マニュアルからの変更**: VirtualBox ではなく WSL2（Windows Subsystem for Linux 2）を使用する。パフォーマンスが大幅に向上し、ファイルアクセスも容易になる。

```powershell
# PowerShell（管理者）で実行
wsl --install

# 再起動後、Ubuntu を起動
# 以降は Linux と同じ手順でインストール
```

WSL2の詳細なセットアップ手順は [Microsoft公式ドキュメント](https://learn.microsoft.com/ja-jp/windows/wsl/install) を参照。

### Docker（全OS共通）

```bash
docker pull quay.io/qiime2/amplicon:2026.1
docker run -it -v $(pwd):/data quay.io/qiime2/amplicon:2026.1 bash
```

## 0.2 解析フォルダの作成

下記のようなフォルダを作成すると、コマンドのコピー＆ペーストで一通りの解析ができるようになっている。

```
analysis/
├── classifier/          # 分類器ファイル
├── input/               # シーケンスデータ（.fastq.gz）
├── sample-metadata.txt  # メタデータ（名前変更前）
└── sample-metadata_cn.txt  # メタデータ（名前変更後）
```

実際の解析では2つのメタデータファイルを作成の上、`input` フォルダに解析したいファイル（.fastq.gz）を入れる。

```bash
# ディレクトリ作成
mkdir -p analysis/{classifier,input,taxonomy,phylogeny,filterIS,rarefaction}
cd analysis
```

## 0.3 メタデータファイルの作成

metadata ファイルはサンプル名の変更前（`sample-metadata.txt`）と変更後（`sample-metadata_cn.txt`）の2種類必要になる。

### sample-metadata.txt の例

```
#SampleID	BarcodeSequence	LinkerPrimerSequence	newID	IS	Description
SP01	ACGTACGT	AGRGTTTGATYMTGGCTCAG	Sample_A	yes	test sample
SP02	TGCATGCA	AGRGTTTGATYMTGGCTCAG	Sample_B	no	control
```

- 作成後、右端に `newID` 列を作成して変更後の名前を入力
- タブ区切りテキストで保存する
- `IS` 列のように任意の列を作成すれば、UniFrac や bar chart で操作することも可能

### sample-metadata_cn.txt の例

```
#SampleID	IS	Description
Sample_A	yes	test sample
Sample_B	no	control
```

- 1列目の `#SampleID` に変更後の名前を入力
- タブ区切りテキストで保存する

### メタデータファイルのルール

> 参考: [Metadata in QIIME 2](https://docs.qiime2.org/2026.1/tutorials/metadata/)

- 空白文字（スペースなど）は無視される。`"gut"` と `"gut "` は同じ意味
- 行頭が `#` の行は無視される（コメントとして利用可能）
- 1列目は identifier (ID) column。`#SampleID` で問題ない
- identifier は36文字以内、ASCIIコード（A-Z, a-z, 0-9, `.`, `-`）を推奨
- QIIME 2 ではID column のみでも valid
- 列名は Unicode文字、空白でない、unique、予約語でないことが条件
- 空のセルは `"missing data"` とみなされる。`"NA"` と書いても missing data にはならないことに注意
- 数字のみの列は `numeric`、文字列が1つでも含まれると `categorical` と認識される
- 列型を明示したい場合は2行1列目に `#q2:types` と記載し、`categorical` or `numeric` と記載する
- numeric は `0-9`, `+`, `-`, E-notation（`1e9`, `1.23E-4` 等）をサポート
- `NaN`, `nan`, `inf`, `-Infinity` はサポートされないことに注意

---

**次のセクション**: [01. データの読み込み](02_data_import.md)
