# 4. サンプル名の変更

> 参考: [the metadata tutorial](https://docs.qiime2.org/2026.1/tutorials/metadata/)

---

## 概要

シーケンス受託機関から納品されるファイルのサンプルIDは、機器の管理番号や内部コードに基づいた形式（例: `Sample_001_S1_L001`）になっていることが多く、そのままでは解析結果の読み取りや グループ判別が困難です。サンプル名の変更（リネーム）により、以下のメリットが得られます。

- **可読性の向上**: 処理群・対照群・採取日などを含む論文掲載に適した名前に変更できる
- **グループ識別の容易化**: `Control_01`、`Treatment_01` のようなプレフィックスでグループが一目で分かる
- **下流解析の簡略化**: R や Python でのメタデータ結合時にIDの整合が取りやすくなる
- **バッチ統合時の衝突回避**: 複数ランをマージする際にIDの重複を防ぐ（詳細は [17. マルチラン解析](17_multi_run.md) 参照）

---

## メタデータファイルの準備と検証

サンプル名変更には、元のサンプルIDと新しいIDを対応させた列をメタデータファイルに記載します。変更前にメタデータファイルを必ず検証してください。

```bash
# メタデータの形式を検証する
qiime metadata tabulate \
  --m-input-file sample-metadata.txt \
  --o-visualization metadata-validation.qzv
```

> **注意**: `sample-metadata.txt` の `newID` 列に空白・特殊文字・重複値が含まれていないことを確認してください。QIIME 2 2026.1 以降、タブ区切りファイルの列名に空白が含まれる場合は警告が出るようになりました。

---

## サンプル名の変更コマンド

```bash
qiime feature-table group \
  --i-table table.qza \
  --p-axis sample \
  --m-metadata-file sample-metadata.txt \
  --m-metadata-column newID \
  --p-mode sum \
  --o-grouped-table table_cn.qza
```

| パラメータ | 説明 |
|-----------|------|
| `--i-table` | 入力する feature table（変更前） |
| `--p-axis sample` | サンプル軸に対して操作する |
| `--m-metadata-file` | 変換マッピングを含むメタデータファイル |
| `--m-metadata-column` | 新しいサンプルIDが記載された列名 |
| `--p-mode sum` | 同じ新IDに対応する複数サンプルはリード数を合算する |
| `--o-grouped-table` | 出力する feature table（変更後） |

---

## 変更後の確認

可視化してきちんと名前が変更されていることを確認する：

```bash
qiime feature-table summarize \
  --i-table table_cn.qza \
  --o-visualization table_cn.qzv \
  --m-sample-metadata-file sample-metadata_cn.txt
```

QIIME 2 View（https://view.qiime2.org）で `table_cn.qzv` を開き、サンプルIDが意図した通りに変更されているか確認してください。

---

## 注意点

### 元のIDが失われることへの対策

`qiime feature-table group` で作成した `table_cn.qza` には**元のサンプルIDの情報は含まれません**。後から元のIDに戻したり、元IDと新IDを照合したりするために、必ず**マッピングファイルを別途保管**してください。

推奨するマッピングファイルの形式（例: `id_mapping.tsv`）:

```
original_id	new_id	group	note
Sample_001_S1_L001	Control_01	Control	採取日: 2024-04-01
Sample_002_S2_L001	Control_02	Control	採取日: 2024-04-01
Sample_003_S3_L001	Treatment_01	Treatment	採取日: 2024-04-01
```

このファイルはプロジェクトの `README` や論文の補足資料としても有用です。

### メタデータ列の検証

`--m-metadata-column` に指定する列（ここでは `newID`）は、以下の点を事前に確認してください：

1. **全サンプルに値が存在する**（欠損値があると対応するサンプルが処理されない）
2. **新IDが一意である**（複数の元IDが同じ新IDに対応している場合、`--p-mode sum` でリード数が合算される）
3. **使用できる文字のみ含む**（英数字・アンダースコア・ハイフンを推奨。スペースや記号は問題を起こす可能性がある）

---

**次のセクション**: [05. Feature table の作成](06_feature_table.md)
