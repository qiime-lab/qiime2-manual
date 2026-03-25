# 12. IS（内部標準）を抜く

> 参考: [Filtering sequences](https://docs.qiime2.org/2026.1/tutorials/filtering/)

## 概要

**内部標準（Internal Standard; IS）** とは、DNA抽出前にサンプルへ既知量を添加する外来微生物のことである。16S rRNAアンプリコン解析では通常、サンプル内の各菌の「相対存在量」しか得られないが、ISを使うことで「絶対定量（コピー数/g）」が可能になる。

IS法では、以下のような菌種がよく用いられる。

| IS菌種 | 特徴 |
|--------|------|
| Salinibacterium | 極限環境微生物。ヒト・動物腸内には自然には存在しない |
| Agrobacterium（Rhizobium） | 植物根粒菌。ヒト・動物腸内には自然には存在しない |

IS除去は、定量計算に使い終わったIS由来のASVを feature table および代表配列から取り除くステップである。IS除去後のデータが、真の細菌叢組成に基づく多様性解析・絶対定量の基盤となる。

## IS法のメリット・デメリット

### メリット

- **絶対定量が可能**: 相対存在量ではなく、copies/g dry feces などの実量値を算出できる
- **DNA抽出・PCR効率の補正**: ISはすべてのサンプルで同一量を添加するため、サンプル間の抽出効率やPCR増幅効率の差異を補正できる
- **Compositional artifact の回避**: 相対存在量では「ある菌が増えると別の菌の割合が下がる」という見かけ上の変化（compositional artifact）が生じるが、絶対定量では真の増減を捉えられる
- **生物学的意義が高い**: 菌数の実際の変化量を反映するため、介入実験や疾患研究での解釈が容易

### デメリット

- **ウェットラボの手間**: DNA抽出のたびに全サンプルへISを一定量添加する必要があり、ピペッティング精度が結果の質に直結する
- **IS菌種の選定が重要**: IS菌種がサンプル中に自然存在すると定量値が誤る。環境サンプルや特殊な腸内フローラを持つ被験者では事前確認が必要
- **ウェットラボプロトコルの複雑化**: IS溶液の調製・保管・品質管理が加わる
- **IS除去の注意**: `--p-exclude` は部分一致で除外するため、科レベル（`f__Rhizobiaceae` など）で分類が止まっているASVは除外されない場合がある（後述の注意参照）

---

## ISの除去

```bash
mkdir -p filterIS/taxonomy

# table ファイルからISを抜く
qiime taxa filter-table \
  --i-table table_cn.qza \
  --i-taxonomy taxonomy/rep-seqs_classified.qza \
  --p-exclude rhizobium,Salinibacterium \
  --o-filtered-table filterIS/table_filterIS.qza

# 代表配列ファイルからISを抜く
qiime taxa filter-seqs \
  --i-sequences rep-seqs.qza \
  --i-taxonomy taxonomy/rep-seqs_classified.qza \
  --p-exclude rhizobium,Salinibacterium \
  --o-filtered-sequences filterIS/rep-seqs_filterIS.qza
```

## 結果の確認

```bash
# table ファイルの可視化
qiime feature-table summarize \
  --i-table filterIS/table_filterIS.qza \
  --o-visualization filterIS/table_filterIS.qzv \
  --m-sample-metadata-file sample-metadata_cn.txt

# 代表配列ファイルの可視化
qiime feature-table tabulate-seqs \
  --i-data filterIS/rep-seqs_filterIS.qza \
  --o-visualization filterIS/rep-seqs_filterIS.qzv

# Feature table の作成
qiime tools export \
  --input-path filterIS/table_filterIS.qza \
  --output-path filterIS/
mv filterIS/feature-table.biom filterIS/feature-table_filterIS.biom
biom convert -i filterIS/feature-table_filterIS.biom -o filterIS/feature-table_filterIS.txt --to-tsv
```

> **確認ポイント**: table ファイルでは OTU（feature）数とリード数、代表配列ファイルでは Sequence count が減少していることを確認する。

> **⚠️ 注意**: `--p-exclude` は菌種名の部分一致で除外する。科レベルで終わっている場合（`f__Rhizobiaceae;` など）は除外できない。IS除去後の taxonomy ファイルに Rhizobiaceae や Microbacteriaceae が含まれていないか確認すること。

## IS除去の詳細確認手順

IS除去が正しく行われたかどうかは以下の手順で確認する。

### 1. リード数の差分確認

IS除去前（`table_cn.qza`）と除去後（`table_filterIS.qza`）のリード数の差が、IS由来ASVのリード数と一致するかを確認する。

```bash
# IS除去前のサマリー
qiime feature-table summarize \
  --i-table table_cn.qza \
  --o-visualization table_cn.qzv \
  --m-sample-metadata-file sample-metadata_cn.txt
```

各サンプルのリード数差分 = IS由来リード数（Salinibacterium + Agrobacterium の合計）となっているか確認する。

### 2. taxonomyファイルでの目視確認

エクスポートしたテキストファイルを開き、以下の文字列が feature ID として残っていないことを確認する。

- `Salinibacterium`
- `Rhizobium`
- `Agrobacterium`
- `Rhizobiaceae`（科レベル終端の場合）
- `Microbacteriaceae`（科レベル終端の場合）

```bash
# IS関連の分類群が残っていないか grep で確認
grep -i "salinibacterium\|rhizobium\|agrobacterium\|rhizobiaceae\|microbacteriaceae" \
  filterIS/feature-table_filterIS.txt
# 出力が空であれば除去成功
```

### 3. ASV数の確認

`rep-seqs_filterIS.qzv` を QIIME 2 View で開き、除去前の `rep-seqs.qzv` と比較して Sequence count がIS添加数分だけ減少していることを確認する。

---

**次のセクション**: [13. IS除去後の多様性解析](13_is_diversity.md)
