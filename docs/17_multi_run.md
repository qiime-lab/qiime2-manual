# 17. マルチラン処理・同一サンプルの結合

## 概要

複数のシーケンシングランにまたがるサンプルを統合するためのステップである。

### なぜマルチラン処理が必要か

DADA2 はシーケンシングラン固有のエラーモデルを学習してデノイジングを行う。このため、**異なるランのデータを混在させたまま DADA2 を実行することはできない**。ランをまたいで fastq を混ぜてから DADA2 にかけると、エラーモデルが複数ランのノイズを混同し、ASV検出精度が著しく低下する。

> *"The DADA2 denoising process is only applicable to a single sequencing run at a time, so we need to run this on a per sequencing run basis and then merge the results."*

### よくあるマルチランのシナリオ

- **リード数不足によるリシーケンス**: 初回ランで特定サンプルのリード数が低く（例: 5,000 リード未満）、同一サンプルを追加ランで補完する
- **マルチバッチ実験**: 異なる時期・異なる施設で採取されたサンプルを同じデータセットとして統合する
- **試薬ロット・機器変更**: MiSeq のメンテナンス前後でランが分かれる場合など

---

## メリット・デメリット

### マージのメリット

- **サンプルあたりの深度増加**: リシーケンスによりリード数の少なかったサンプルを解析対象に含められる
- **異なる実験バッチのサンプルを統合**: 大規模コホート研究など、複数バッチにわたるサンプルを1つのデータセットとして扱える
- **`feature-table merge` の簡便さ**: QIIME 2 のコマンド1本でマージが完了し、新たな ASV 検出は不要

### マージのデメリット

- **バッチ効果が残存する可能性**: 異なるランに由来するサンプル間には、シーケンシングバイアスや試薬由来の差異が残る場合がある。β多様性解析でランIDによるクラスタリングが見られることがある（後述の確認手順を参照）
- **整合性検証の必要**: マージ前後でサンプルごとのリード数が正しく合算されているかを必ず確認する
- **DADA2 を別々に実行する計算コスト**: ランごとに独立して DADA2 を実行するため、計算時間が増加する

---

## 手順

DADA2のデノイジングまでは別々のデータとして処理し、その後マージする。

```bash
# table ファイルの結合
# ⚠️ --p-overlap-method 'sum' を忘れずに指定する
qiime feature-table merge \
  --i-tables table1.qza \
  --i-tables table2.qza \
  --p-overlap-method 'sum' \
  --o-merged-table merged_table.qza

# 代表配列ファイルの結合
qiime feature-table merge-seqs \
  --i-data rep-seqs1.qza \
  --i-data rep-seqs2.qza \
  --o-merged-data merged_rep-seqs.qza
```

> **⚠️ 注意**: `--p-overlap-method 'sum'` がないと「同じ名前のファイルがある」としてエラーになる。

結合の前後で各サンプルのリード数の値が合致しているか、table ファイルや txt ファイルで必ず確認すること。結合する fastq.gz のファイル名が異なる場合は、誤った結合を防ぐために事前にファイル名を同一にすること。

---

## バッチ効果の確認方法

マージ後は必ずバッチ効果の有無を確認する。

### β多様性によるバッチ効果確認

マージ後にβ多様性のPCoAでRun IDによる色分けを行い、Run間のバッチ効果がないことを確認する。

```bash
# merged_table.qza に対して通常の多様性解析を実施後、
# Emperor PCoA viewer で Run ID カラムを Color に設定して確認する
qiime diversity core-metrics-phylogenetic \
  --i-phylogeny rooted-tree.qza \
  --i-table merged_table.qza \
  --p-sampling-depth <適切な値> \
  --m-metadata-file sample-metadata.txt \
  --output-dir merged-core-metrics-results
```

`sample-metadata.txt` に `run_id`（例: `run1` / `run2`）カラムを追加しておき、PCoA の Emperor ビューアで `run_id` を色分けに使う。

### バッチ効果が見られた場合の対処

- **下流解析での共変量補正**: 統計検定（PERMANOVA など）で `run_id` を共変量（`--p-no-center` または式中の covariates）として組み込む
- **ComBat などのバッチ補正**: R の `sva` パッケージや `MMUPHin` （マイクロバイオーム専用のバッチ補正ツール）を使用する。ただしバッチ補正は生物学的なシグナルも変化させる可能性があるため、補正前後の比較を必ず行う
- **ランごとの解析**: バッチ効果が著しい場合は、統合ではなくランごとに解析結果を報告することも検討する

---

**次のセクション**: [18. R/phyloseqへのエクスポート](18_export_to_r.md)
