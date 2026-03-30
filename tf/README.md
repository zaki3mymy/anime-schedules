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
| notify_api_key | 通知APIのAPIキー |
| notify_endpoint | 通知APIのエンドポイントURL |
