# 19. 統計検定・差次解析

> **バージョン**: 本章は QIIME 2 2026.1 に対応しています。

> 参考: [beta-group-significance](https://docs.qiime2.org/2026.1/plugins/available/diversity/beta-group-significance/)

## 概要

マイクロバイオーム研究において統計検定は不可欠です。「A 群と B 群で菌叢が違う」という観察を科学的に主張するためには、観察された差異が偶然によるものでないことを統計的に示す必要があります。

マイクロバイオームデータは以下の特性を持つため、統計手法の選択に注意が必要です：

- **高次元性**: 数百〜数千の菌種（特徴量）が存在する
- **組成性**: 相対存在量データであり、各変数が独立でない（→ 第22章参照）
- **非正規性**: カウントデータであり正規分布に従わないことが多い
- **ゼロインフレーション**: 多くの菌種が多くのサンプルで検出されない（構造的ゼロ）

これらの特性に対応した統計手法を選択することで、誤った結論（偽陽性・偽陰性）を避けられます。

---

## 19.1 metadata ファイルにグループを記載

メタデータファイルにグループ情報を含む列を追加する（例: ISの有無）。

---

## 19.2 β多様性の群間検定（PERMANOVA）

### PERMANOVA とは

**PERMANOVA（Permutational Multivariate Analysis of Variance）**は、β多様性の距離行列を用いて、グループ間でコミュニティ組成全体が統計的に異なるかを検定します。

- **何を検定するか**: グループ間の全体的なコミュニティ組成の差異
- **帰無仮説**: 全グループのコミュニティ組成は同一の分布から来ている

| 項目 | 内容 |
|------|------|
| **メリット** | ノンパラメトリック（分布の仮定が不要）、多変量データを一度に扱える、広く受け入れられた標準的手法 |
| **デメリット** | p値のみで効果量が得られない、群内分散（dispersion）の違いに敏感（PERMDISP と組み合わせて確認を推奨）、どの菌種が差に寄与するかは分からない |

```bash
# Weighted UniFrac で PERMANOVA 検定
qiime diversity beta-group-significance \
  --i-distance-matrix filterIS/core-metrics-results/weighted_unifrac/weighted_unifrac_distance_matrix.qza \
  --m-metadata-file sample-metadata_cn.txt \
  --m-metadata-column IS \
  --o-visualization filterIS/core-metrics-results/weighted_unifrac/weighted_unifrac_group_distance.qzv

# 可視化の出力
qiime tools export \
  --input-path filterIS/core-metrics-results/weighted_unifrac/weighted_unifrac_group_distance.qzv \
  --output-path filterIS/core-metrics-results/weighted_unifrac/group_distance
cp filterIS/core-metrics-results/weighted_unifrac/group_distance/*.png \
  filterIS/core-metrics-results/weighted_unifrac/

# Unweighted UniFrac
qiime diversity beta-group-significance \
  --i-distance-matrix filterIS/core-metrics-results/unweighted_unifrac/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-file sample-metadata_cn.txt \
  --m-metadata-column IS \
  --o-visualization filterIS/core-metrics-results/unweighted_unifrac/unweighted_unifrac_group_distance.qzv

qiime tools export \
  --input-path filterIS/core-metrics-results/unweighted_unifrac/unweighted_unifrac_group_distance.qzv \
  --output-path filterIS/core-metrics-results/unweighted_unifrac/group_distance
cp filterIS/core-metrics-results/unweighted_unifrac/group_distance/*.png \
  filterIS/core-metrics-results/unweighted_unifrac/
```

| パラメータ | 説明 |
|-----------|------|
| `--i-distance-matrix` | 入力する距離行列ファイル |
| `--m-metadata-file` | metadataファイル |
| `--m-metadata-column` | グループの列名 |
| `--p-method` | 検定の種類（`permanova`, `anosim`, `permdisp`から選択。デフォルト: `permanova`） |

---

## 19.3 ANOSIM・PERMDISP

`--p-method` パラメータを変更することで、PERMANOVA 以外の検定も実行できます。

### ANOSIM（Analysis of Similarities）

```bash
qiime diversity beta-group-significance \
  --i-distance-matrix filterIS/core-metrics-results/weighted_unifrac/weighted_unifrac_distance_matrix.qza \
  --m-metadata-file sample-metadata_cn.txt \
  --m-metadata-column IS \
  --p-method anosim \
  --o-visualization filterIS/core-metrics-results/weighted_unifrac/weighted_unifrac_anosim.qzv
```

**ANOSIM の特徴:**
- ランクベースの検定。群間距離と群内距離のランクを比較する
- R 統計量（-1〜1）: 1 に近いほどグループが明確に分離
- PERMANOVA より統計的検出力が低い場合があるが、解釈が直感的

### PERMDISP（Beta Dispersion Test）

```bash
qiime diversity beta-group-significance \
  --i-distance-matrix filterIS/core-metrics-results/weighted_unifrac/weighted_unifrac_distance_matrix.qza \
  --m-metadata-file sample-metadata_cn.txt \
  --m-metadata-column IS \
  --p-method permdisp \
  --o-visualization filterIS/core-metrics-results/weighted_unifrac/weighted_unifrac_permdisp.qzv
```

**PERMDISP の特徴:**
- グループ間の**分散（dispersion）の均一性**を検定する（ベータ多様性の組成差ではない）
- PERMANOVA は dispersion の違いに敏感であるため、**PERMANOVA の前に PERMDISP を実施**し、dispersion が均一であることを確認することが推奨される
- PERMDISP が有意（p < 0.05）の場合、PERMANOVA の有意差は組成差ではなく dispersion の違いを反映している可能性がある

**使い分けの指針:**
1. まず **PERMDISP** で群内分散の均一性を確認
2. PERMDISP が非有意 → **PERMANOVA** で群間差を検定
3. PERMANOVA に加えて **ANOSIM** で補足確認することも有用

---

## 19.4 α多様性の群間検定

β多様性（群間コミュニティ差）だけでなく、各サンプルの**α多様性（多様性指標）**についてもグループ間で統計検定できます。

```bash
# Shannon 多様性指数のグループ間検定
qiime diversity alpha-group-significance \
  --i-alpha-diversity core-metrics-results/shannon_vector.qza \
  --m-metadata-file sample-metadata_cn.txt \
  --o-visualization core-metrics-results/shannon-group-significance.qzv
```

Shannon 以外にも、`core-metrics-results/` 内の各ベクターファイル（`observed_features_vector.qza`, `evenness_vector.qza`, `faith_pd_vector.qza`）を同様に検定できます。

**使用される検定:**
- 2グループ間: Kruskal-Wallis 検定（ノンパラメトリック）
- 3グループ以上: Kruskal-Wallis 検定 + 事後検定（Dunn 法）

---

## 19.5 結果の読み方

β多様性検定の結果には検定の p 値とグループ間距離の箱ひげ図が出力される。

箱ひげ図は各グループの「内」と「間」の距離を示している。例えば「Distance to no」の場合、左の箱は no サンプル内の距離、右の箱は no と yes サンプル間の距離を表す。

---

## 統計手法の比較表

| 手法 | 対象データ | 検出内容 | メリット | デメリット |
|------|----------|---------|---------|-----------|
| **PERMANOVA** | β多様性距離行列 | グループ間のコミュニティ組成差 | ノンパラメトリック、多変量、標準的手法 | どの菌種が差に寄与するか分からない、dispersion 差に敏感 |
| **ANOSIM** | β多様性距離行列 | グループ間のコミュニティ差 | ランクベース、解釈が直感的 | PERMANOVA より統計的検出力が低い場合がある |
| **PERMDISP** | β多様性距離行列 | グループ間の分散（dispersion）差 | 群内分散の均一性を検定できる | 組成差の検定ではない（PERMANOVA の前提確認として使用） |
| **Kruskal-Wallis** | α多様性ベクター | グループ間の多様性指標差 | ノンパラメトリック、各指標に適用可能 | 指標ごとの単変量検定（多重検定補正に注意） |
| **ANCOM-BC2** | Feature table | 特定の菌種レベルの差異 | 組成データ対応、共変量調整、効果量あり | 詳細は第22章参照 |

> **個別菌種の差異を検定したい場合**は、β多様性ベースの手法ではなく差次的存在量解析（Differential Abundance Analysis）を使用します。→ **[第22章 差次的存在量解析](22_differential_abundance.md)**

---

**次のセクション**: [17. マルチラン処理](17_multi_run.md)
