# anime-schedules

今日放送するアニメを [Annict](https://developers.annict.com/) から取得して通知APIで通知する。


## Description

Annict で「見てるアニメ」に登録しているアニメのうち、今日の16時～26時(時間は適当に決めた)に放送するアニメの放送情報を取得してLINEに通知する。「見てるアニメ」は放送局も設定しておかないといけないことに注意。

以下のようなフォーマットでメッセージが届く。
```
タイトル
放送時間
放送曲
話数 サブタイトル
```

[デプロイ](#deployment) することで毎日18時に通知してくれるようになる。


## Requirements

実行に必要なソフトウェア。
- Python 3.13
- Terraform 1.10

その他、必要となるアカウント。
- Annictアカウント
- AWSアカウント(デプロイ先)


## Usage

環境変数 `ANNICT_TOKEN`, `NOTIFY_API_KEY`を設定し、以下を実行する。
```
python src/anime_schedules/lambda_function.py
```


## Local Development

実際の Annict API・通知API を呼び出さずに動作確認したい場合、Mockoon CLI によるスタブサーバーを利用できる。
`podman-compose up` を実行すると、`lambda` サービスは `local-net` という podman-compose 内部ネットワークを経由して `stub` サービス（`config/mockoon/api-stub.json` で定義）に向けて通信する。

`lambda_handler` は `ANNICT_TOKEN`, `NOTIFY_API_KEY`, `NOTIFY_ENDPOINT`, `ANNICT_ENDPOINT` の環境変数を参照する。`.env.example` をコピーして `.env.local` を作成し、`ANNICT_TOKEN`・`NOTIFY_API_KEY` にダミー値を、`ANNICT_ENDPOINT`・`NOTIFY_ENDPOINT` にスタブサーバーのURL（`http://stub:3000`）を設定する（`.env.local` は git 管理対象外）。
```
cp .env.example .env.local
# .env.local の ANNICT_ENDPOINT / NOTIFY_ENDPOINT を http://stub:3000 に変更
podman-compose up --build
```


## Deployment

Terraform を使ってAWS上にリソースを作成する。  
詳細は [tf/README.md](./tf/README.md) を参照。
