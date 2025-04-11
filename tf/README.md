# Deployment

Terraform を使ってAWS上にリソースを作成する。
- Lambda
- EventBridge
- CloudWatch Logs
- Resource Group

このディレクトリで`terraform apply`を実行することで作成する。以下の変数を与える必要がある。

| variable | description |
| --- | --- |
| annict_token | Annictアプリケーションのアクセストークン |
| line_token | Messaging APIを利用するチャネルのアクセストークン |
| line_user_id | 通知するLINEユーザーのID(チャネル基本設定で確認できる) |
