# 6. 代表配列の系統樹作成

> **IS入りサンプルの場合はスキップ** → [12. IS除去後の系統樹作成](13_is_diversity.md)

多様性解析で使用するための系統樹を作成する。内部で行われている計算は以下の通り：

1. **MAFFT** でリードのマルチプルアラインメントを行う
2. 高変異領域を **mask（filter）** する（高変異領域は系統樹のノイズになり得るため）
3. **FastTree** を用いて系統樹を作成する（無根系統樹）
4. **midpoint rooting** によって根をつける

```bash
# ディレクトリ作成
mkdir -p phylogeny

qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences rep-seqs.qza \
  --o-alignment phylogeny/aligned-rep-seqs.qza \
  --o-masked-alignment phylogeny/masked-aligned-rep-seqs.qza \
  --o-tree phylogeny/unrooted-tree.qza \
  --o-rooted-tree phylogeny/rooted-tree.qza
```

| パラメータ | 説明 |
|-----------|------|
| `--i-sequences` | 入力する代表配列ファイル名 |
| `--o-alignment` | 出力するアラインメントファイル名 |
| `--o-masked-alignment` | マスク処理後のアラインメントファイル名 |
| `--o-tree` | 出力する無根系統樹ファイル名 |
| `--o-rooted-tree` | 出力する有根系統樹ファイル名 |

> **Tip**: 非常に大きなデータセットの場合、MAFFT の `--large` フラグを使用することでRAM使用量を抑えることができる（QIIME 2 2025.7 で追加）。

---

**次のセクション**: [07. 多様性解析](08_diversity.md)
