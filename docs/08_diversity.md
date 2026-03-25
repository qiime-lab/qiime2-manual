# 7. 多様性の算出

> **IS入りサンプルの場合はスキップ** → [13. IS除去後の多様性解析](13_is_diversity.md)

---

## 概要

マイクロバイオーム多様性解析は大きく **α多様性** と **β多様性** の2種類に分けられます。

### α多様性（Alpha Diversity）— サンプル内の多様性

α多様性は「1つのサンプルの中にどれだけ多様な微生物群集が存在するか」を定量します。処理群間でα多様性を比較することで、特定の条件が微生物群集の豊かさや均一さに影響するかどうかを評価できます。

| 指標 | 測定対象 | メリット | デメリット |
|------|---------|---------|-----------|
| **Shannon 多様性指数** | 豊富さ（richness）＋均一さ（evenness）の両方 | 広く使われており解釈しやすい、abundance を考慮する | 希少な taxa に対して感度が高い |
| **Faith's PD** | 系統発生的多様性（進化的な多様さ） | 進化的関係を捉えられる、系統的に遠い taxa の存在を反映 | 系統樹が必要、系統樹の品質に依存する |
| **Observed ASVs** | 豊富さのみ（検出された ASV 数） | シンプルで理解しやすい | 均一さや存在量を無視する |
| **Chao1** | 推定豊富さ（未観測の taxa を含む） | 観測されていない種を推定できる | DADA2 後のデータではシングルトンが少なく Observed ASVs とほぼ同値になることが多い |
| **Simpson 指数** | 支配的な taxa の影響を受けにくい均一さ | 外れ値に対してロバスト | 希少な taxa の情報を反映しにくい |
| **Pielou の均一度（Evenness）** | 均一さのみ | 豊富さと独立して均一さを評価できる | 豊富さとは別に解釈が必要 |

### β多様性（Beta Diversity）— サンプル間の多様性

β多様性は「2つのサンプルの間でどれだけ群集組成が異なるか」を定量します。距離行列として算出され、PCoA（主座標分析）などで可視化します。

| 指標 | 測定対象 | メリット | デメリット |
|------|---------|---------|-----------|
| **Bray-Curtis 非類似度** | 存在量ベースのサンプル間差異 | 直感的で解釈しやすい、系統樹不要 | 系統発生的関係を無視する |
| **Jaccard 距離** | 存在/非存在（presence/absence）ベース | シンプル | 存在量の差異を無視する |
| **Weighted UniFrac** | 存在量＋系統発生的関係 | 最も情報量が多い、支配的な taxa の違いを反映 | 計算コストが高い、系統樹が必要 |
| **Unweighted UniFrac** | 存在/非存在＋系統発生的関係 | 希少な系統のライン差異を検出できる | ノイズに感度が高い |

---

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

---

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

### sampling depth の選び方

> **sampling depth の選択指針**
>
> sampling depth の設定はα・β多様性解析の結果に大きく影響します。以下の方針を参考にしてください：
>
> 1. **最小リード数を基本とする**: 全サンプルが含まれるよう、最小リード数を sampling depth に設定するのが最もシンプルな方法です
> 2. **外れ値サンプルの扱い**: 1つのサンプルのみリード数が極端に少ない場合（例: 他のサンプルが 30,000 リードなのに 1 サンプルだけ 2,000 リード）は、そのサンプルを除外して残りのサンプルに高い sampling depth を設定することを検討してください
> 3. **rarefaction curve で確認**: `--p-max-depth` を最小リード数に設定した rarefaction curve でプラトーに達しているか確認します（[08. Rarefaction curve](09_rarefaction.md) 参照）
> 4. **q2-boots の活用**: ランダムサブサンプリングの不確実性を軽減するには q2-boots を検討してください（後述）

---

## 7.2 Chao1 の算出

上記コマンドでは Chao1 は算出されない。下記で別途算出する。ただし、デノイジングによってシングルトンが QIIME 1 よりも出にくいため、observed OTUs と同じ値になることが多い。

```bash
qiime diversity alpha \
  --i-table table_cn.qza \
  --p-metric chao1 \
  --o-alpha-diversity core-metrics-results/chao1_index_vector.qza
```

---

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

### Shannon 多様性指数の対数底カスタマイズ（2025.10）

QIIME 2 **2025.10** から、Shannon 多様性指数の対数底を指定できるようになりました。これにより、R の `vegan` パッケージや Python の `scikit-bio` との計算結果を一致させることができます。

```bash
qiime diversity alpha \
  --i-table table_cn.qza \
  --p-metric shannon \
  --o-alpha-diversity core-metrics-results/shannon_vector_log2.qza
```

> **Note**: デフォルトは自然対数（ln、底 = e）です。`vegan::diversity()` はデフォルトで底 2 の対数を使用します。論文や他ツールとの比較時には対数底を明示してください。

---

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

## 7.5 q2-boots によるブートストラップ多様性解析（2025.10+）

ランダムサブサンプリング（rarefaction）を1回だけ行う従来の `core-metrics-phylogenetic` とは異なり、**q2-boots** はラレファクションを複数回繰り返して結果を統合します。これにより、乱数シードに依存しない安定した多様性指標が得られます。

詳細は **[23. q2-boots](23_boots.md)** を参照してください。

```bash
# q2-boots を用いたブートストラップ多様性解析（例）
qiime boots core-metrics \
  --i-table table_cn.qza \
  --i-phylogeny phylogeny/rooted-tree.qza \
  --p-sampling-depth 11045 \
  --p-n 100 \
  --p-replacement \
  --m-metadata-file sample-metadata_cn.txt \
  --output-dir boots-core-metrics-results
```

> **2026.1 以降**: q2-boots の距離行列の集約にはデフォルトで **medoid 法**が使用されます。medoid は「最も代表的な距離行列」を選択する手法で、平均行列よりも外れ値に対してロバストです。

---

**次のセクション**: [08. Rarefaction curve](09_rarefaction.md)
