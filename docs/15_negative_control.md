# 15. ネガティブコントロールのOTUを抜く

> ※QIIME 2 のチュートリアルには記載が見られなかった。`qiime feature-table --help` コマンドの出力結果を参考に作成。

## 概要

**ネガティブコントロール（ネガコン; NC）** とは、サンプルを含まないブランク（滅菌水や空のチューブなど）をDNA抽出からシーケンスまで同じプロトコルで処理したものである。NCに検出されたASVは、DNA抽出キット試薬・PCR試薬・実験環境由来の**コンタミネーション**を示す可能性が高い。

### なぜネガコン解析が重要か

- **コンタミネーションASVの同定**: DNA抽出キット（特に MoBio/Qiagen PowerSoil など）には常在するバックグラウンド細菌が含まれており、低バイオマスサンプルではこれが結果を大きく歪める
- **低バイオマスサンプルへの必須対応**: 腸内フローラ（高バイオマス）では影響が小さいが、皮膚・肺・脳脊髄液・プラセンタなど低バイオマスサンプルでは NC 由来 ASV がサンプルの主要 ASV として現れることもある
- **論文投稿要件**: 多くのジャーナル（Nature Microbiology, Gut, Microbiome など）では NC の実施と報告を必須または強く推奨している

## ネガコン解析のメリット・デメリット

### メリット

- **コンタミネーション ASV の同定と除去**: 実験由来のノイズを排除することで、生物学的シグナルの信頼性が上がる
- **結果への信頼性向上**: NC の報告は透明性の確保につながり、査読者や読者の信頼を得やすい
- **再現性向上**: コンタミネーション由来のばらつきを除去することでサンプル間比較が安定する

### デメリット

- **積極的な除去による本物の ASV の消失**: NC と同じ ASV がサンプルにも存在する場合、本物のシグナルを除去してしまう可能性がある（特に Propionibacterium などは環境にも人体にも存在する）
- **低存在量コンタミネーションの見逃し**: NCのリード数が極めて少ない場合、実際にはコンタミしているASVが検出されないことがある
- **1本のNCでは全コンタミを捉えられない**: バッチ・抽出日・試薬ロットごとにNCを設けないと、ランダムなコンタミを見逃す

---

## 17.1 ネガコンのOTU IDの確認

`feature-table_cn.txt` や `feature-table_filterIS.txt` からネガコンのOTU IDを確認する。ネガコンに含まれるOTUのID（例: `64a6d38e951ce89cfd685c6d033a700e`）をメモする。

## 17.2 metadata ファイルの作成

1行目1列目に `#OTUID` と入力し、2行目以降にメモしたOTU IDを入力する。ファイル名は `NC_OTU.txt` とする。

```
#OTUID
64a6d38e951ce89cfd685c6d033a700e
ec9211f2975b1612cd3ad75b7822ad4f
```

## 17.3 OTUの除去（手動除去）

```bash
mkdir -p filterNC

# table ファイルからネガコンを抜く
qiime feature-table filter-features \
  --i-table table_cn.qza \
  --m-metadata-file NC_OTU.txt \
  --p-exclude-ids True \
  --o-filtered-table filterNC/table_filterNC.qza

# 可視化
qiime feature-table summarize \
  --i-table filterNC/table_filterNC.qza \
  --o-visualization filterNC/table_filterNC.qzv \
  --m-sample-metadata-file sample-metadata_cn.txt

# テキスト出力
qiime tools export \
  --input-path filterNC/table_filterNC.qza \
  --output-path filterNC/
mv filterNC/feature-table.biom filterNC/feature-table_filterNC.biom
biom convert -i filterNC/feature-table_filterNC.biom \
  -o filterNC/feature-table_filterNC.txt --to-tsv

# 代表配列からもNC を抜く
qiime feature-table filter-seqs \
  --i-data rep-seqs.qza \
  --m-metadata-file NC_OTU.txt \
  --p-exclude-ids True \
  --o-filtered-data filterNC/rep-seqs_filterNC.qza

qiime feature-table tabulate-seqs \
  --i-data filterNC/rep-seqs_filterNC.qza \
  --o-visualization filterNC/rep-seqs_filterNC.qzv
```

## 17.4 確認

リード数の差分を計算し、除去したOTUのリード数と一致することを確認する。また、`rep-seqs_filterNC.qzv` で Sequence count が正しく減少していること、除去したOTU IDが検索でヒットしないことを確認する。

---

## decontam による統計的コンタミネーション評価

NCが複数ある場合や系統的なコンタミネーション評価を行いたい場合は、QIIME 2 の `q2-quality-control` プラグインに含まれる `decontam-score` アクションを利用できる。

```bash
# decontam によるコンタミネーション評価（QIIME 2 プラグイン）
qiime quality-control decontam-score \
  --i-table table_cn.qza \
  --m-metadata-file sample-metadata_cn.txt \
  --p-method prevalence \
  --p-neg-control-column is_negative_control \
  --o-decontam-scores decontam-scores.qza \
  --o-visualization decontam-scores.qzv
```

> **⚠️ QIIME 2 2025.7 以降の変更点**:
> - `decontam-remove` アクションは **2025.7 で廃止**された（`filter-features` で代替可能なため冗長と判断）。コンタミ除去は `decontam-score` でスコアを算出し、結果を参照して上記の手動除去（`filter-features`）を行う。
> - `decontam-score-viz`（可視化）は **2025.7 でページネーションとソート可能カラムが追加**され、多数の ASV がある場合の操作性が向上した。

`sample-metadata_cn.txt` に `is_negative_control` カラム（`true`/`false`）を追加しておく必要がある。decontam スコアが高い（prevalence 法では p 値が低い）ASV がコンタミネーション候補として示される。

## 手動除去 vs decontam の使い分け

| 状況 | 推奨手法 |
|------|---------|
| NCが1〜2本、コンタミ ASV が明確に少数 | **手動除去**（シンプルで確実） |
| NCが複数バッチにわたる、コンタミ ASV が多数 | **decontam-score** による統計的評価 + 手動除去 |
| 低バイオマスサンプルで系統的な評価が必要 | **decontam-score**（prevalence 法または frequency 法） |
| 既存解析との互換性を重視 | **手動除去** |

手動除去は単純で再現性が高く、NC が少ない場合には最もシンプルな方法である。decontam はNCが多い場合や確率的なコンタミネーション評価を要する場合に有効だが、閾値設定（スコアのカットオフ）に判断が必要であり、過剰除去に注意する。

---

**次のセクション**: [16. 統計検定](16_statistical_testing.md)
