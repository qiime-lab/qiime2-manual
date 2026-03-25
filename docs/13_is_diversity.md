# 13. IS除去後の系統樹作成・多様性解析・Rarefaction

## 概要

IS除去後のサンプルに対して系統樹作成・多様性解析・rarefactionを実施する。IS由来のASVが除外されているため、真の細菌叢組成に基づいた多様性指標が得られる。コマンドは基本的にIS除去前（[第8章](08_diversity.md)・[第9章](09_rarefaction.md)）と同じだが、入出力パスが `filterIS/` 以下になる。

### IS除去前後の比較の重要性

IS除去前後でα多様性やβ多様性がどの程度変化するかを確認することで、IS添加が解析に与える影響を評価できる。理想的にはIS由来ASVのリード数がサンプル全体の一定割合（通常5〜15%程度）に収まっており、IS除去後も α多様性の順位関係や β多様性のクラスタリングパターンが大きく変わらないことを確認する。もし除去前後で PCoA の構造が大きく変化する場合は、IS添加量のばらつきや意図しないISのキャリーオーバーを疑う。

---

## 12. 系統樹作成

```bash
mkdir -p filterIS/phylogeny

qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences filterIS/rep-seqs_filterIS.qza \
  --o-alignment filterIS/phylogeny/aligned-rep-seqs_filterIS.qza \
  --o-masked-alignment filterIS/phylogeny/masked-aligned-rep-seqs_filterIS.qza \
  --o-tree filterIS/phylogeny/unrooted-tree_filterIS.qza \
  --o-rooted-tree filterIS/phylogeny/rooted-tree_filterIS.qza
```

## 13. 多様性の算出

### 13.1 最小リード数の確認

```bash
qiime tools export \
  --input-path filterIS/table_filterIS.qza \
  --output-path filterIS/taxonomy
mv filterIS/taxonomy/feature-table.biom filterIS/taxonomy/feature-table_filterIS.biom
biom convert -i filterIS/taxonomy/feature-table_filterIS.biom \
  -o filterIS/taxonomy/feature-table_filterIS.txt --to-tsv
```

エクセルなどで開いて最小リード数を確認する。

### 13.2 α・β多様性の算出

```bash
qiime diversity core-metrics-phylogenetic \
  --i-phylogeny filterIS/phylogeny/rooted-tree_filterIS.qza \
  --i-table filterIS/table_filterIS.qza \
  --p-sampling-depth 19658 \
  --m-metadata-file sample-metadata_cn.txt \
  --output-dir filterIS/core-metrics-results
```

> **補足 — q2-boots による代替**: QIIME 2 では `q2-boots` プラグインを使ってブートストラップ法によるリサンプリングを行う方法も利用可能である。`q2-boots` は単回のrarефactionに依存せず複数回のリサンプリング結果を平均するため、統計的にロバストな多様性指標が得られる。サンプル数が少なく rarefaction の安定性が懸念される場合は検討する。
>
> ```bash
> # q2-boots を使った代替（要 q2-boots インストール）
> qiime boots core-metrics-phylogenetic \
>   --i-table filterIS/table_filterIS.qza \
>   --i-phylogeny filterIS/phylogeny/rooted-tree_filterIS.qza \
>   --p-sampling-depth 19658 \
>   --p-n 100 \
>   --m-metadata-file sample-metadata_cn.txt \
>   --output-dir filterIS/core-metrics-boots
> ```

### 13.3 Chao1 の算出

```bash
qiime diversity alpha \
  --i-table filterIS/table_filterIS.qza \
  --p-metric chao1 \
  --o-alpha-diversity filterIS/core-metrics-results/chao1_index_vector.qza
```

### 13.4 α多様性の可視化

```bash
for metric in observed_otus chao1_index shannon faith_pd; do
  qiime metadata tabulate \
    --m-input-file filterIS/core-metrics-results/${metric}_vector.qza \
    --o-visualization filterIS/core-metrics-results/${metric}_vector.qzv
done
```

### 13.5 テキスト形式での出力

```bash
# β多様性のPCoA座標・距離行列
for prefix in weighted_unifrac unweighted_unifrac; do
  qiime tools export \
    --input-path filterIS/core-metrics-results/${prefix}_pcoa_results.qza \
    --output-path filterIS/core-metrics-results/
  mv filterIS/core-metrics-results/ordination.txt \
    filterIS/core-metrics-results/${prefix}_pcoa_results.txt

  qiime tools export \
    --input-path filterIS/core-metrics-results/${prefix}_distance_matrix.qza \
    --output-path filterIS/core-metrics-results/
  mv filterIS/core-metrics-results/distance-matrix.tsv \
    filterIS/core-metrics-results/${prefix}_distance_matrix.tsv
done

# α多様性
for metric in observed_otus chao1_index shannon faith_pd; do
  qiime tools export \
    --input-path filterIS/core-metrics-results/${metric}_vector.qza \
    --output-path filterIS/core-metrics-results/
  mv filterIS/core-metrics-results/alpha-diversity.tsv \
    filterIS/core-metrics-results/${metric}_vector.tsv 2>/dev/null
done

# ディレクトリ整理
for dir in weighted_unifrac unweighted_unifrac bray_curtis jaccard observed_otus chao1 shannon faith_pd evenness; do
  mkdir -p filterIS/core-metrics-results/${dir}
  mv filterIS/core-metrics-results/${dir}_* filterIS/core-metrics-results/${dir}/ 2>/dev/null
done
```

## 14. Rarefaction curve（IS除去後）

```bash
mkdir -p filterIS/rarefaction/csv

# observed OTUs, Shannon, Faith PD
qiime diversity alpha-rarefaction \
  --i-table filterIS/table_filterIS.qza \
  --i-phylogeny filterIS/phylogeny/rooted-tree_filterIS.qza \
  --p-max-depth 19658 \
  --m-metadata-file sample-metadata_cn.txt \
  --o-visualization filterIS/rarefaction/alpha-rarefaction.qzv

# Chao1
qiime diversity alpha-rarefaction \
  --i-table filterIS/table_filterIS.qza \
  --p-max-depth 19658 \
  --p-metrics chao1 \
  --m-metadata-file sample-metadata_cn.txt \
  --o-visualization filterIS/rarefaction/alpha-rarefaction_chao1.qzv

# テキスト出力
qiime tools export --input-path filterIS/rarefaction/alpha-rarefaction.qzv \
  --output-path filterIS/rarefaction/calculation
qiime tools export --input-path filterIS/rarefaction/alpha-rarefaction_chao1.qzv \
  --output-path filterIS/rarefaction/calculation_chao1

cp filterIS/rarefaction/calculation/*.csv filterIS/rarefaction/csv/
cp filterIS/rarefaction/calculation_chao1/*.csv filterIS/rarefaction/csv/
```

## 15. 100%積み上げ棒グラフ作成（IS除去後）

```bash
qiime taxa barplot \
  --i-table filterIS/table_filterIS.qza \
  --i-taxonomy taxonomy/rep-seqs_classified.qza \
  --m-metadata-file sample-metadata_cn.txt \
  --o-visualization filterIS/taxonomy/taxa-bar-plots_filterIS.qzv
```

ISの2菌種が抜かれていることを確認する。

### 分類レベルごとにテキスト出力

```bash
for level in 5 6 7; do
  qiime taxa collapse \
    --i-table filterIS/table_filterIS.qza \
    --i-taxonomy taxonomy/rep-seqs_classified.qza \
    --p-level ${level} \
    --o-collapsed-table filterIS/taxonomy/collapsed_table${level}_filterIS.qza
  qiime tools export \
    --input-path filterIS/taxonomy/collapsed_table${level}_filterIS.qza \
    --output-path filterIS/taxonomy
  mv filterIS/taxonomy/feature-table.biom \
    filterIS/taxonomy/collapsed_table${level}_filterIS.biom
  biom convert \
    -i filterIS/taxonomy/collapsed_table${level}_filterIS.biom \
    -o filterIS/taxonomy/collapsed_table${level}_filterIS.txt --to-tsv
done
```

> **⚠️ 確認**: IS として入れている Agrobacterium の科である Rhizobiaceae、Salinibacterium の科である Microbacteriaceae が taxonomy ファイルに含まれていないか確認すること。`--p-exclude` は属レベル以下の名前で除外するため、科レベルで終わっている場合は除外されない。

---

**次のセクション**: [14. IS検量線・絶対定量](14_is_quantification.md)
