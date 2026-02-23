# 7. 多様性の算出

> **IS入りサンプルの場合はスキップ** → [13. IS除去後の多様性解析](13_is_diversity.md)

多様性の算出では解析に用いるリード数（sampling depth）を指定する必要がある。ここでは最小リード数を指定する。

## 最小リード数の確認

```bash
qiime tools export \
  --input-path denoising-stats.qza \
  --output-path ./
mv stats.tsv denoising-stats.tsv

# non-chimeric リード数を降順で表示
tail -n +3 denoising-stats.tsv | sort -k 8,8nr | cut -f 8
```

| コマンド | 説明 |
|---------|------|
| `tail -n +3` | 3行目から最後まで表示（ヘッダー除外） |
| `sort -k 8,8nr` | 8列目を数値として降順に並べ替え |
| `cut -f 8` | 8列目（non-chimeric リード数）を抽出 |

## 7.1 α・β多様性の算出

β多様性の Weighted UniFrac、Unweighted UniFrac、Bray-Curtis、Jaccard と、α多様性の observed OTUs、Shannon、Faith PD の qza, qzv ファイルが出力される。

```bash
qiime diversity core-metrics-phylogenetic \
  --i-phylogeny phylogeny/rooted-tree.qza \
  --i-table table_cn.qza \
  --p-sampling-depth 11045 \
  --m-metadata-file sample-metadata_cn.txt \
  --output-dir core-metrics-results
```

| パラメータ | 説明 |
|-----------|------|
| `--i-phylogeny` | 入力する有根系統樹ファイル名 |
| `--i-table` | 入力するtableファイル名 |
| `--p-sampling-depth` | 算出に用いるリード数（この値に満たないサンプルは除外される） |
| `--m-metadata-file` | metadataファイル名 |
| `--output-dir` | 出力ディレクトリ名 |

> **⚠️ sampling depth について**  
> sampling depth は最小リード数に設定することが一般的だが、極端にリード数の少ないサンプルが存在する場合は、そのサンプルを除外して他のサンプルの sampling depth を上げることも検討する。

## 7.2 Chao1 の算出

上記コマンドでは Chao1 は算出されない。下記で別途算出する。ただし、デノイジングによってシングルトンが QIIME 1 よりも出にくいため、observed OTUs と同じ値になることが多い。

```bash
qiime diversity alpha \
  --i-table table_cn.qza \
  --p-metric chao1 \
  --o-alpha-diversity core-metrics-results/chao1_index_vector.qza
```

## 7.3 α多様性の可視化

```bash
# observed OTUs
qiime metadata tabulate \
  --m-input-file core-metrics-results/observed_otus_vector.qza \
  --o-visualization core-metrics-results/observed_otus_vector.qzv

# Chao1
qiime metadata tabulate \
  --m-input-file core-metrics-results/chao1_index_vector.qza \
  --o-visualization core-metrics-results/chao1_index_vector.qzv

# Shannon
qiime metadata tabulate \
  --m-input-file core-metrics-results/shannon_vector.qza \
  --o-visualization core-metrics-results/shannon_vector.qzv

# Faith PD
qiime metadata tabulate \
  --m-input-file core-metrics-results/faith_pd_vector.qza \
  --o-visualization core-metrics-results/faith_pd_vector.qzv
```

## 7.4 テキスト形式での出力

ファイル名を指定できないので逐一出力ファイル名を変更していく。

```bash
# Weighted UniFrac PCoA座標
qiime tools export \
  --input-path core-metrics-results/weighted_unifrac_pcoa_results.qza \
  --output-path core-metrics-results/
mv core-metrics-results/ordination.txt core-metrics-results/weighted_unifrac_pcoa_results.txt

# Weighted UniFrac 距離行列
qiime tools export \
  --input-path core-metrics-results/weighted_unifrac_distance_matrix.qza \
  --output-path core-metrics-results/
mv core-metrics-results/distance-matrix.tsv core-metrics-results/weighted_unifrac_distance_matrix.tsv

# Unweighted UniFrac PCoA座標
qiime tools export \
  --input-path core-metrics-results/unweighted_unifrac_pcoa_results.qza \
  --output-path core-metrics-results/
mv core-metrics-results/ordination.txt core-metrics-results/unweighted_unifrac_pcoa_results.txt

# Unweighted UniFrac 距離行列
qiime tools export \
  --input-path core-metrics-results/unweighted_unifrac_distance_matrix.qza \
  --output-path core-metrics-results/
mv core-metrics-results/distance-matrix.tsv core-metrics-results/unweighted_unifrac_distance-matrix.tsv

# α多様性指標
for metric in observed_otus chao1 shannon faith_pd; do
  qiime tools export \
    --input-path core-metrics-results/${metric}_vector.qza \
    --output-path core-metrics-results/ 2>/dev/null || \
  qiime tools export \
    --input-path core-metrics-results/${metric}_index_vector.qza \
    --output-path core-metrics-results/ 2>/dev/null
  mv core-metrics-results/alpha-diversity.tsv core-metrics-results/${metric}_vector.tsv 2>/dev/null
done
```

### ディレクトリの整理

```bash
for dir in weighted_unifrac unweighted_unifrac bray_curtis jaccard observed_otus chao1 shannon faith_pd evenness; do
  mkdir -p core-metrics-results/${dir}
  mv core-metrics-results/${dir}_* core-metrics-results/${dir}/ 2>/dev/null
done
```

---

**次のセクション**: [08. Rarefaction curve](09_rarefaction.md)
