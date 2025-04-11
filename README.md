# anime-schedules

今日放送するアニメを [Annict](https://developers.annict.com/) から取得して [LINE Messaging API](https://developers.line.biz/ja/services/messaging-api/) で通知する。


## Description

Annict で「見てるアニメ」に登録しているアニメのうち、今日の16時～26時(時間は適当に決めた)に放送するアニメの放送情報を取得してLINEに通知する。「見てるアニメ」は放送局も設定しておかないといけないことに注意。

以下のようなフォーマットでメッセージが届く。
```
タイトル
放送時間
放送曲
話数 サブタイトル
```

[デプロイ](#deployment) することで毎日16時に通知してくれるようになる。


## Requirements

実行に必要なソフトウェア。
- Python 3.13
- Terraform 1.10

その他、必要となるアカウント。
- Annictアカウント
- LINE Developersアカウント
- AWSアカウント(デプロイ先)


## Usage

環境変数 `ANNICT_TOKEN`, `LINE_TOKEN`, `LINE_USER_ID`を設定し、以下を実行する。
```
python src/anime_schedules/lambda_function.py
```


## Deployment

Terraform を使ってAWS上にリソースを作成する。  
詳細は [tf/README.md](./tf/README.md) を参照。
