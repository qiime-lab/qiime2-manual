#!/bin/bash
# 解析ディレクトリのセットアップスクリプト
# Usage: bash setup_dirs.sh [project_name]

PROJECT_NAME=${1:-"analysis"}

echo "Creating analysis directory structure: ${PROJECT_NAME}/"

mkdir -p "${PROJECT_NAME}"/{classifier,input,taxonomy,phylogeny,filterIS/{taxonomy,phylogeny,core-metrics-results,rarefaction/csv},rarefaction/csv,filterNC,core-metrics-results,export}

cat << 'MSG'

ディレクトリ構成:
  classifier/            - 分類器ファイル
  input/                 - シーケンスデータ (.fastq.gz)
  taxonomy/              - 種同定結果
  phylogeny/             - 系統樹
  filterIS/              - IS除去後データ
  rarefaction/           - Rarefaction curve
  filterNC/              - ネガコン除去後データ
  core-metrics-results/  - 多様性解析結果
  export/                - R用エクスポートデータ

次のステップ:
  1. input/ に FASTQ ファイルを配置
  2. sample-metadata.txt を作成
  3. sample-metadata_cn.txt を作成
MSG

echo ""
echo "Done! cd ${PROJECT_NAME} で解析開始"
