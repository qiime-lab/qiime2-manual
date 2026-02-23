# 9. 分類器作成

> **27F-338R のアンプリコンならSkip**（事前に作成済みの分類器を使用）

## データベースの選択

> **⚠️ 旧マニュアルからの変更**: SILVA 132 → **SILVA 138.2** に更新

| データベース | バージョン | 状態 |
|------------|-----------|------|
| SILVA | 138.2 | **推奨**（本マニュアルで使用） |
| SILVA | 132 | 旧バージョン（非推奨） |
| GreenGenes | 13_8 | 更新停止（非推奨） |
| GreenGenes2 | 2024.09 | 利用可能だがSILVAとの互換性に注意 |

### 引用

SILVA を使用する際は以下を引用してください：
- Quast et al., *Nucleic Acids Res.*, 2013 ([link](https://academic.oup.com/nar/article/41/D1/D590/1069277))
- Yilmaz et al., *Nucleic Acids Res.*, 2014 ([link](https://academic.oup.com/nar/article/42/D1/D643/1061236))

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

## 分類器作成の背景

ナイーブベイズで16S rRNA遺伝子をターゲットとして分類するときは、trainに使用する領域をシーケンス領域に限定した方が望ましいことが分かっている（unclassifiedなASVが減る）。これは他のマーカー遺伝子（ITSなど）にはあてはまらないことに注意。

> 参考: Bokulich et al. (2018). Optimizing taxonomic classification of marker-gene amplicon sequences with QIIME 2's q2-feature-classifier plugin. *Microbiome*, 6, 90.

---

**次のセクション**: [10. 細菌種の同定](11_taxonomy.md)
