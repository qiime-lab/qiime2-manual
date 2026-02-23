# 19. グループ間の検定・箱ひげ図の作図

> 参考: [beta-group-significance](https://docs.qiime2.org/2026.1/plugins/available/diversity/beta-group-significance/)

## 19.1 metadata ファイルにグループを記載

メタデータファイルにグループ情報を含む列を追加する（例: ISの有無）。

## 19.2 検定の実行

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

## 19.3 結果の読み方

結果には検定のp値とグループ間距離の箱ひげ図が出力される。

箱ひげ図は各グループの「内」と「間」の距離を示している。例えば「Distance to no」の場合、左の箱は no サンプル内の距離、右の箱は no と yes サンプル間の距離を表す。

---

**次のセクション**: [17. マルチラン処理](17_multi_run.md)
