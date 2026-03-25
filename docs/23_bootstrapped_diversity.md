# 23. ブートストラップ多様性解析（q2-boots）

## 概要

従来の rarefaction（リード数の均一化）は、1 回のランダムサブサンプリングのみに依存するため、その結果が特定のランダムサンプリングに左右されるという問題がある。特にサンプル間のシーケンス深度にばらつきがある場合、1 回の rarefaction で得られた結果は変動が大きく、再現性に懸念が生じる。

**q2-boots**（2025.10+）はこの問題に対処するため、rarefaction を n 回繰り返し（デフォルト: 100 回）、各イテレーションの結果を集約することで、より安定した多様性指標を提供する。

### q2-boots の主な特徴

| 機能 | 内容 |
|------|------|
| 反復 rarefaction | rarefaction を n 回繰り返す（デフォルト 100 回） |
| 結果の集約 | α 多様性は中央値、距離行列は medoid 平均（2026.1 デフォルト） |
| インターフェース | `q2-diversity` と同一の引数体系 |
| 出力形式 | 通常の多様性解析と同じ `.qza` 形式 |

> **参考文献**: Keefe, C.R., et al. (2025). Bootstrapped rarefaction outperforms single rarefaction for alpha and beta diversity estimation. *F1000Research*.

### 従来の rarefaction との比較

| 観点 | 従来の rarefaction（ch09） | q2-boots（本章） |
|------|--------------------------|-----------------|
| サブサンプリング | 1 回のみ | n 回（デフォルト 100 回） |
| 結果の安定性 | ランダム性に依存 | 統計的に安定 |
| 計算時間 | 速い | n 倍かかる |
| インターフェース | `qiime diversity core-metrics-phylogenetic` | `qiime boots core-metrics` |
| 推奨場面 | 探索的解析 | 論文投稿・深度ばらつきが大きい場合 |

---

## メリット・デメリット

### メリット

- **ランダム変動の低減**: 単一の rarefaction が偶然依存するサンプリング結果の影響を排除
- **より頑健な結果**: 複数回の集約により、統計的に信頼性の高い多様性指標を得られる
- **q2-diversity と同一インターフェース**: 既存のコマンドとほぼ同じ引数で使用可能
- **論文投稿レベルの解析**: 査読者が求める統計的頑健性を満たしやすい

### デメリット

- **計算時間**: n 回分の計算が必要なため、デフォルト（n=100）では従来の 100 倍の時間がかかる
- **新しいツール**: コミュニティでの使用経験がまだ少なく、知見が蓄積中
- **サンプルが十分な場合**: シーケンス深度が均一なデータセットでは結果がほとんど変わらない場合がある

---

## いつ使うか

> **推奨**: サンプル間のシーケンス深度に大きなばらつきがある場合や、論文投稿用の解析では q2-boots の使用を推奨する。探索的な解析や初期の QC 確認では、従来の rarefaction（[ch09](09_rarefaction.md)）で十分な場合が多い。

**q2-boots を選ぶ状況**:
- 最小リード数と最大リード数の比が 2 倍以上異なる
- 論文の査読対応
- α 多様性検定の統計的信頼性を高めたい

**従来 rarefaction で十分な状況**:
- シーケンス深度が比較的均一（最小/最大が 1.5 倍以内）
- 探索的解析・仮説生成フェーズ
- 大規模データセットで計算資源が限られている

---

## インストール

```bash
# q2-boots は 2025.10 以降の QIIME 2 に同梱（amplicon distribution）
# バージョン確認
qiime info | grep boots
```

---

## ブートストラップ Core Metrics（推奨コマンド）

`q2-diversity` の `core-metrics-phylogenetic` に相当する包括的な解析を一度に実行する。

```bash
# ブートストラップ core-metrics（q2-diversity と同じインターフェース）
qiime boots core-metrics \
  --i-table table_cn.qza \
  --i-phylogeny phylogeny/rooted-tree.qza \
  --p-sampling-depth 11045 \
  --p-n 100 \
  --p-replacement \
  --m-metadata-file sample-metadata_cn.txt \
  --output-dir boots-core-metrics-results
```

**パラメータ解説**:

| パラメータ | 値 | 説明 |
|-----------|-----|------|
| `--p-sampling-depth` | 11045 | 各サンプルのサブサンプリング深度（最小リード数を目安に設定） |
| `--p-n` | 100 | rarefaction を繰り返す回数 |
| `--p-replacement` | — | 復元抽出（ブートストラップ）を使用 |

出力ディレクトリ `boots-core-metrics-results/` には以下が生成される：
- `observed_features_vector.qza`: 観察 OTU 数（集約済み）
- `shannon_entropy_vector.qza`: Shannon 多様性（集約済み）
- `evenness_vector.qza`: Pielou の均一度（集約済み）
- `faith_pd_vector.qza`: Faith PD（集約済み）
- `bray_curtis_distance_matrix.qza`: Bray-Curtis 距離行列（medoid 平均）
- `jaccard_distance_matrix.qza`: Jaccard 距離行列
- `unweighted_unifrac_distance_matrix.qza`: Unweighted UniFrac
- `weighted_unifrac_distance_matrix.qza`: Weighted UniFrac

---

## α多様性のブートストラップ（個別指標）

特定の α 多様性指標のみをブートストラップ計算する場合：

```bash
# α多様性のブートストラップ
qiime boots alpha \
  --i-table table_cn.qza \
  --p-sampling-depth 11045 \
  --p-metric shannon \
  --p-n 100 \
  --o-average-alpha-diversity boots-shannon.qza
```

利用可能な `--p-metric` の例：
- `shannon`: Shannon エントロピー
- `observed_features`: 観察 feature 数
- `pielou_e`: Pielou の均一度
- `chao1`: Chao1 推定多様性

---

## β多様性のブートストラップ（系統的距離）

```bash
# β多様性のブートストラップ
qiime boots beta-phylogenetic \
  --i-table table_cn.qza \
  --i-phylogeny phylogeny/rooted-tree.qza \
  --p-sampling-depth 11045 \
  --p-metric weighted_unifrac \
  --p-n 100 \
  --o-average-distance-matrix boots-wunifrac.qza
```

系統情報を使わない場合は `boots beta` を使用：

```bash
qiime boots beta \
  --i-table table_cn.qza \
  --p-sampling-depth 11045 \
  --p-metric braycurtis \
  --p-n 100 \
  --o-average-distance-matrix boots-braycurtis.qza
```

---

## 結果の可視化・統計検定

`boots core-metrics` で得られた出力は、`q2-diversity` と同じダウンストリームアクションに渡せる。

```bash
# α多様性の群間比較（ブートストラップ済みベクターを使用）
qiime diversity alpha-group-significance \
  --i-alpha-diversity boots-core-metrics-results/shannon_entropy_vector.qza \
  --m-metadata-file sample-metadata_cn.txt \
  --o-visualization boots-shannon-significance.qzv

# β多様性の PERMANOVA（ブートストラップ済み距離行列を使用）
qiime diversity beta-group-significance \
  --i-distance-matrix boots-core-metrics-results/weighted_unifrac_distance_matrix.qza \
  --m-metadata-file sample-metadata_cn.txt \
  --m-metadata-column Group \
  --p-method permanova \
  --o-visualization boots-permanova.qzv
```

---

## 集約方法の変更（上級者向け）

デフォルトの集約方法（medoid）以外を使いたい場合：

```bash
# 距離行列の集約方法を指定
qiime boots beta-phylogenetic \
  --i-table table_cn.qza \
  --i-phylogeny phylogeny/rooted-tree.qza \
  --p-sampling-depth 11045 \
  --p-metric weighted_unifrac \
  --p-n 100 \
  --p-average-method medoid \   # medoid（デフォルト）または mean
  --o-average-distance-matrix boots-wunifrac-medoid.qza
```

`medoid` は n 個の距離行列のうち、他のすべての行列との距離の合計が最小となる行列を代表として選ぶ方法で、外れ値に頑健。`mean` は単純な算術平均。

---

**前のセクション**: [22. 差次的存在量解析](22_differential_abundance.md)（参照）
**Appendix**: [メタデータ仕様](appendix_metadata.md) | [変更履歴](appendix_changelog.md)
