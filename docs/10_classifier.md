# 10. 分類器作成

> **バージョン**: 本章は QIIME 2 2026.1 に対応しています。

> **27F-338R のアンプリコンならSkip**（事前に作成済みの分類器を使用）

## 概要

**分類学的同定（Taxonomic Classification）**とは、シーケンスで得られた各 ASV（Amplicon Sequence Variant）が「どの生物に属するか」を参照データベースと照合して決定するプロセスです。16S rRNA 遺伝子解析では、この工程によって「Firmicutes が 40%、Bacteroidota が 30%...」といった菌叢の組成情報が得られ、サンプル間比較や疾患・環境との関連付けが可能になります。

### Naive Bayes アプローチについて

QIIME 2 の標準分類法は **Naive Bayes 分類器**（`classify-sklearn`）です。参照データベースの配列と分類情報を学習させた機械学習モデルを作成し、未知の ASV に対して確率的に分類ラベルを付与します。

**特徴:**
- アンプリコン領域（例: V1-V2, V3-V4）に特化してトレーニングすることで精度が向上する
- Confidence スコアにより分類の信頼性を評価できる
- フルレングス配列でトレーニングするよりも、ターゲット領域に限定した方が低精度の分類（Unclassified）が減ることが知られている（Bokulich et al. 2018）

---

## データベースの選択

> **旧マニュアルからの変更**: SILVA 132 → **SILVA 138.2** を標準使用。新規データベースを追加。

| データベース | バージョン | メリット | デメリット |
|------------|-----------|---------|-----------|
| **SILVA** | 138.2 | 現在の業界標準。キュレーションが充実、16S/18S/ITS 対応、コミュニティサポート豊富 | ファイルサイズが大きい（~10 GB）、種レベルでの誤アノテーションが一部存在 |
| SILVA | 144（プレビュー） | GTDB 統合、分類体系改善。2025年11月ワークショップで発表 | 2026.1 時点では未リリース。正式対応版を要確認 |
| **Greengenes2** | 2024.09 | ICNP 準拠の門名（Bacillota など）、WoL2 系統樹バックボーン、系統的に一貫性が高い | SILVA と分類体系が異なるため直接比較不可。日本国内のコミュニティサポートが少ない |
| **UNITE** | 最新版 | ITS/真菌解析の標準。真菌の同定精度が高い | 16S 細菌解析には使用不可 |
| **MIDORI Reference 2** | 最新版 | ミトコンドリア DNA メタバーコーディング用。COI 等の動物同定に最適 | 16S 細菌解析には使用不可 |
| **PR2** | 最新版 | 18S 原生生物（プロティスト）専用データベース | 16S 細菌解析には使用不可 |
| **Eukaryome** | 最新版 | 真核生物全般をカバー。18S 解析に幅広く対応 | 16S 細菌解析には使用不可 |

> **選択指針**: 16S rRNA 細菌・古細菌解析では **SILVA 138.2**（推奨）または **Greengenes2 2024.09** を使用します。真菌 ITS 解析には UNITE、動物メタバーコーディングには MIDORI Reference 2、原生生物 18S 解析には PR2 または Eukaryome を使用します。

### 引用

SILVA を使用する際は以下を引用してください：
- Quast et al., *Nucleic Acids Res.*, 2013 ([link](https://academic.oup.com/nar/article/41/D1/D590/1069277))
- Yilmaz et al., *Nucleic Acids Res.*, 2014 ([link](https://academic.oup.com/nar/article/42/D1/D643/1061236))

Greengenes2 を使用する際：
- McDonald et al., *Nature Biotechnology*, 2023

---

## 分類器作成のメリット・デメリット

| 項目 | 内容 |
|------|------|
| **メリット** | アンプリコン領域に特化することで Unclassified が減少し精度が向上する |
| **メリット** | RESCRIPt により再現性の高いパイプラインが構築できる |
| **メリット** | 任意のプライマーペア・データベースに対応可能 |
| **デメリット** | 計算コストが高い（標準的な PC で数時間〜半日） |
| **デメリット** | scikit-learn のバージョン依存があるため、**QIIME 2 のバージョンが変わるたびに再作成が必要** |
| **デメリット** | プライマーペアによってはリファレンス配列からの領域抽出が失敗することがある（`extract-reads` の `--p-min-length`/`--p-max-length` 調整が必要） |

> **注意**: 作成した分類器（`.qza`）は QIIME 2 のバージョンが変わると使用できなくなる場合があります。バージョンとともに保存・管理してください。

---

## 方法A: RESCRIPt プラグインを使用（推奨）

> **新規追加**: QIIME 2 2020.6 以降、RESCRIPt プラグインにより SILVA データを直接ダウンロード・処理できる。手動ダウンロードよりも簡便かつ再現性が高い。

```bash
mkdir -p classifier/silva138_v12

# SILVA 138.2 データの取得（要インターネット接続）
qiime rescript get-silva-data \
  --p-version '138.2' \
  --p-target 'SSURef_NR99' \
  --p-include-species-labels \
  --o-silva-sequences classifier/silva138_v12/silva-138.2-ssu-nr99-seqs.qza \
  --o-silva-taxonomy classifier/silva138_v12/silva-138.2-ssu-nr99-tax.qza

# 逆転写（RNA → DNA）
qiime rescript reverse-transcribe \
  --i-rna-sequences classifier/silva138_v12/silva-138.2-ssu-nr99-seqs.qza \
  --o-dna-sequences classifier/silva138_v12/silva-138.2-ssu-nr99-seqs-dna.qza

# V1-V2 領域の抽出（27F-338R）
qiime feature-classifier extract-reads \
  --i-sequences classifier/silva138_v12/silva-138.2-ssu-nr99-seqs-dna.qza \
  --p-f-primer AGRGTTTGATYMTGGCTCAG \
  --p-r-primer TGCTGCCTCCCGTAGGAGT \
  --p-min-length 100 \
  --p-max-length 400 \
  --o-reads classifier/silva138_v12/ref-seqs_silva138_v12.qza

# 分類器の作成（時間がかかる）
qiime feature-classifier fit-classifier-naive-bayes \
  --i-reference-reads classifier/silva138_v12/ref-seqs_silva138_v12.qza \
  --i-reference-taxonomy classifier/silva138_v12/silva-138.2-ssu-nr99-tax.qza \
  --o-classifier classifier/silva138_v12/classifier_silva138_v12.qza
```

### RESCRIPt の追加アクション（2025.4+）

RESCRIPt には SILVA 以外のデータベース取得アクションも追加されています。

```bash
# PR2 データの取得（18S 原生生物解析用）
qiime rescript get-pr2-data \
  --o-pr2-sequences pr2-seqs.qza \
  --o-pr2-taxonomy pr2-tax.qza

# Eukaryome データの取得（真核生物 18S 解析用）
qiime rescript get-eukaryome-data \
  --o-sequences eukaryome-seqs.qza \
  --o-taxonomy eukaryome-tax.qza

# MIDORI Reference 2 データの取得（ミトコンドリアメタバーコーディング用）
qiime rescript get-midori2-data \
  --o-sequences midori2-seqs.qza \
  --o-taxonomy midori2-tax.qza

# orient-reads: 配列の向きを統一する（データベース作成前の前処理として推奨）
qiime rescript orient-reads \
  --i-sequences classifier/silva138_v12/silva-138.2-ssu-nr99-seqs-dna.qza \
  --i-reference-sequences classifier/silva138_v12/silva-138.2-ssu-nr99-seqs-dna.qza \
  --o-reads-same-strand classifier/silva138_v12/silva-138.2-oriented.qza \
  --o-unorientable-reads classifier/silva138_v12/silva-138.2-unorientable.qza
```

---

## 方法B: 手動ダウンロード（旧方法）

QIIME 2 公式が提供するプレフォーマット済みファイルを使用する方法。

```bash
mkdir -p classifier/silva138_v12
cd classifier/silva138_v12

# QIIME 2 公式の pre-formatted SILVA 138 ファイルをダウンロード
# https://docs.qiime2.org/2026.1/data-resources/ から最新URLを確認
wget https://data.qiime2.org/2026.1/common/silva-138-99-seqs.qza
wget https://data.qiime2.org/2026.1/common/silva-138-99-tax.qza

# V1-V2 領域の抽出
qiime feature-classifier extract-reads \
  --i-sequences silva-138-99-seqs.qza \
  --p-f-primer AGRGTTTGATYMTGGCTCAG \
  --p-r-primer TGCTGCCTCCCGTAGGAGT \
  --p-min-length 100 \
  --p-max-length 400 \
  --o-reads ref-seqs_silva138_v12.qza

# 分類器の作成
qiime feature-classifier fit-classifier-naive-bayes \
  --i-reference-reads ref-seqs_silva138_v12.qza \
  --i-reference-taxonomy silva-138-99-tax.qza \
  --o-classifier classifier_silva138_v12.qza

cd ../..
```

---

## Greengenes2 を使用する場合

SILVA と異なる分類体系を持つ Greengenes2 を使用する場合のコマンドです。SILVA との分類名は直接比較できないため、論文等では使用したデータベースを明記してください。

```bash
# Greengenes2 を使用する場合
qiime rescript get-gg2-data \
  --p-version '2024.09' \
  --o-sequences gg2-seqs.qza \
  --o-taxonomy gg2-tax.qza
```

---

## 旧方法（参考）: SILVA 132 からの手動作成

<details>
<summary>クリックで展開（非推奨）</summary>

```bash
mkdir -p classifier/27f_338r_silva99
cd classifier/27f_338r_silva99/

curl -O https://www.arb-silva.de/fileadmin/silva_databases/qiime/Silva_132_release.zip
unzip Silva_132_release.zip

# 配列ファイルのインポート
qiime tools import \
  --type 'FeatureData[Sequence]' \
  --input-path SILVA_132_QIIME_release/rep_set/rep_set_all/99/silva132_99.fna \
  --output-path silva132_99.qza

# 細菌種名ファイルのインポート
qiime tools import \
  --type 'FeatureData[Taxonomy]' \
  --input-format HeaderlessTSVTaxonomyFormat \
  --input-path SILVA_132_QIIME_release/taxonomy/taxonomy_all/99/taxonomy_7_levels.txt \
  --output-path silva132_99_taxonomy_7_levels.qza

# V1-2 領域の抽出
qiime feature-classifier extract-reads \
  --i-sequences silva132_99.qza \
  --p-f-primer AGRGTTTGATYMTGGCTCAG \
  --p-r-primer TGCTGCCTCCCGTAGGAGT \
  --p-min-length 100 \
  --p-max-length 400 \
  --o-reads ref-seqs_silva99_v12.qza

# 分類器の作成
qiime feature-classifier fit-classifier-naive-bayes \
  --i-reference-reads ref-seqs_silva99_v12.qza \
  --i-reference-taxonomy silva132_99_taxonomy_7_levels.qza \
  --o-classifier classifier_silva99_v12.qza

cd ../..
```

</details>

---

## 分類器作成の背景

ナイーブベイズで16S rRNA遺伝子をターゲットとして分類するときは、trainに使用する領域をシーケンス領域に限定した方が望ましいことが分かっている（unclassifiedなASVが減る）。これは他のマーカー遺伝子（ITSなど）にはあてはまらないことに注意。

### classify-sklearn の orientation オプション（2025.7+）

QIIME 2 2025.7 以降、`classify-sklearn` に `--p-reads-per-batch` の改善とともに **`--p-read-orientation`** オプションで `both`（センス・アンチセンス両方向を試みる）が指定できるようになりました。リードの向きが混在しているデータセットや、orient-reads 処理を省略したい場合に有用です。

```bash
qiime feature-classifier classify-sklearn \
  --i-classifier classifier/silva138_v12/classifier_silva138_v12.qza \
  --i-reads rep-seqs.qza \
  --p-read-orientation both \
  --o-classification taxonomy/rep-seqs_classified.qza
```

> 参考: Bokulich et al. (2018). Optimizing taxonomic classification of marker-gene amplicon sequences with QIIME 2's q2-feature-classifier plugin. *Microbiome*, 6, 90.

---

**次のセクション**: [11. 細菌種の同定](11_taxonomy.md)
