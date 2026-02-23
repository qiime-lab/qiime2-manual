# 8. Rarefaction curve の算出

> **IS入りサンプルの場合はスキップ**

```bash
mkdir -p rarefaction/csv

# observed OTUs, Shannon, Faith PD
qiime diversity alpha-rarefaction \
  --i-table table_cn.qza \
  --i-phylogeny phylogeny/rooted-tree.qza \
  --p-max-depth 9899 \
  --m-metadata-file sample-metadata_cn.txt \
  --o-visualization rarefaction/alpha-rarefaction.qzv

# Chao1（別途算出）
qiime diversity alpha-rarefaction \
  --i-table table_cn.qza \
  --p-max-depth 9899 \
  --p-metrics chao1 \
  --m-metadata-file sample-metadata_cn.txt \
  --o-visualization rarefaction/alpha-rarefaction_chao1.qzv
```

> **Note**: `--p-max-depth` には最小リード数を指定する。

## 8.1 テキストで出力

```bash
qiime tools export \
  --input-path rarefaction/alpha-rarefaction.qzv \
  --output-path rarefaction/calculation

qiime tools export \
  --input-path rarefaction/alpha-rarefaction_chao1.qzv \
  --output-path rarefaction/calculation_chao1

cp rarefaction/calculation/*.csv rarefaction/csv/
cp rarefaction/calculation_chao1/*.csv rarefaction/csv/
```

> **Tip**: QIIME 2 の rarefaction curve は QIIME 1 よりも安定する（プラトーに達しやすい）。これはデノイジングによってシーケンスエラー由来のASVが減少するためと考えられる。

---

**次のセクション**: [09. 分類器作成](10_classifier.md)
