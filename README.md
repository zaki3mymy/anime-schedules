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
- Python 3.14
- [uv](https://docs.astral.sh/uv/)（Python の依存関係の管理）。バージョンは `pyproject.toml` の `[tool.uv] required-version` の範囲のもの（CI も同じ範囲の uv を使う）
- Terraform 1.10

開発に使うツールは nix で管理している（[開発環境](#開発環境)）。

その他、必要となるアカウント。
- Annictアカウント
- AWSアカウント(デプロイ先)


## 開発環境

開発に使うツールは [flake.nix](flake.nix) で管理する。

| ツール | 用途 |
| --- | --- |
| uv | Python と依存関係の管理 |

次のものは flake に入れていないので、別に入れる。

- Python：uv が `.python-version` を見て入れる（CI の `setup-uv` と同じ）。ruff などの Python のツールは uv.lock で管理し、`uv run` で使う
- terraform：unfree で cache.nixos.org にビルド済みのものがなく、flake.lock を更新するたびにソースからのビルド（数分）がかかるため。CI では `hashicorp/setup-terraform` で入れる
- podman・podman-compose：コンテナでの動作確認に使う。コンテナのランタイムなので OS 側で用意する

[direnv](https://direnv.net/) を使うと、このディレクトリに入ったときに自動でツールが PATH に入る（[.envrc](.envrc)）。direnv を使わないときは `nix develop` を実行する。

```shell
direnv allow   # または nix develop
```

- ツールのバージョンは、flake.lock の nixpkgs のコミット（`rev`）で決まる。nixpkgs のコミットを進めると、すべてのツールがまとめて新しくなる。
  - 更新は Dependabot が週に1回 PR を作る。手で上げるときは `nix flake update` を実行する。
  - 実際のバージョンは `nix develop -c uv --version` や `nix eval --inputs-from . --raw nixpkgs#uv.version` で確かめられる。
- uv のバージョンは `pyproject.toml` の `[tool.uv] required-version` の範囲のものを使う（CI も同じ範囲の uv を使う）。nixpkgs を進めて uv が範囲から外れたら、`required-version` と CI の uv を合わせて上げる。


## Usage

依存パッケージをインストールする。
```
uv sync
```

環境変数 `ANNICT_TOKEN`, `NOTIFY_API_KEY`を設定し、以下を実行する。
```
uv run python src/anime_schedules/lambda_function.py
```

テストと lint は以下で実行する。
```
uv run pytest
uv run ruff check src tests
uv run ruff format --check src tests
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

### OTelメトリクス収集・トレース可視化

`podman-compose up` すると、`otel-collector` / `jaeger` / `prometheus` / `loki` / `grafana` も起動する。
`lambda` サービスは OTLP (HTTP:4318) で `otel-collector` にテレメトリを送信し、`otel-collector` がトレースを Jaeger に、メトリクスを Prometheus に、ログを Loki にルーティングする。

```
lambda → OTLP(HTTP:4318) → otel-collector
                                ├─ traces  → Jaeger  (UI: localhost:16686)
                                ├─ metrics → Prometheus (UI: localhost:9090) ─┐
                                └─ logs    → Loki (localhost:3100) ──────────┴→ Grafana (UI: localhost:3000)
```

- Jaeger UI: http://localhost:16686
- Prometheus UI: http://localhost:9090
- Grafana UI: http://localhost:3000 (初期ログイン `admin` / `admin`。Prometheus をデータソースとして手動で追加する必要がある。データソースURLは `http://prometheus:9090`)
- Loki: http://localhost:3100 (Grafana にデータソースとして手動で追加する。データソースURLは `http://loki:3100`。Explore で `{service_name="anime-schedules"}` で確認する)

`lambda` サービスは [OpenTelemetry の自動計装](https://opentelemetry.io/docs/zero-code/python/) (`opentelemetry-instrument`) 経由で起動しており、コード変更なしに以下のスパンが記録される。
- Lambda呼び出し全体（EventBridgeトリガー）のスパン
- Annict API・通知APIへの `urllib` リクエストのスパン
- `logging` のログ（そのときのスパンの `trace_id`・`span_id` が付く）

なお、ローカル環境用の `Containerfile` を使ったコンテナイメージであり、`tf/modules/main.tf` でデプロイしている本番のZipパッケージ形式のLambda関数には `opentelemetry` パッケージが含まれないため、OTel の Python計装レイヤーと Collectorレイヤー（どちらもコミュニティ製）を付与（`tf/main.tf` の `otel_layer_arns`）してLambdaに提供している。Collectorの設定は zip に同梱した `src/anime_schedules/collector.yaml` を使い、トレース・メトリクス・ログを Grafana Cloud に OTLP で送信する。

Lambda のランタイムの Python は、コミュニティの Python計装レイヤーを作った Python（今は 3.14）と同じバージョンにしている。違うとレイヤーの `.pyc` が使われず、コールドスタートのたびにコンパイルし直すので遅くなる。レイヤーを上げるときは、そのタグの `python/src/otel/Dockerfile` の Python のバージョンも確認する。

コミュニティの Python計装レイヤーには、次の計装が入っていない。そのため、これらを入れたレイヤーを自前で作り、コミュニティのレイヤーに重ねている（`tf/modules/main.tf` の `aws_lambda_layer_version.otel_instrumentations`）。

| 計装 | 無いと |
| --- | --- |
| `opentelemetry-instrumentation-urllib` | 通知APIへのリクエストに `traceparent` が付かず、nandemo-oshirase と1つのトレースにならない（[#35](https://github.com/zaki3mymy/anime-schedules/issues/35)） |
| `opentelemetry-instrumentation-logging` | `logging` のログが OTel のログとして送られない |

- zip は `scripts/build_otel_instrumentations_layer.py` で作る（CI の terraform-plan と `deploy.yml` で、Terraform の前に実行する）。依存するパッケージはコミュニティのレイヤーにあるので、これらの計装だけを `--no-deps` で入れる。計装を足すときは、スクリプトの `PACKAGES` と `pyproject.toml` の両方に足す。同じバージョンなら zip のハッシュは変わらないので、レイヤーは作り直されない。
- バージョンは `uv.lock` のものを使う。`pyproject.toml` の OTel の依存は、コミュニティの Python計装レイヤー（タグの `requirements.txt`）と同じバージョンに `==` で固定している（ローカルと本番のバージョンをそろえるため）。Dependabot では OTel のパッケージを上げない（`.github/dependabot.yml` の `ignore`）。
- コミュニティのレイヤーの新しいバージョンは、`.github/workflows/update-otel-lambda-layers.yml` が見つけて、`tf/main.tf` の ARN と `pyproject.toml`・`uv.lock` の OTel の依存を一緒に上げる PR を作る。opentelemetry-lambda のリリースは feed-release-invoke-workflow の `repository_dispatch`（`otel-lambda-release`）で知り、取りこぼしに備えて週1回の `schedule` でも確認する。

Grafana Cloud に送るための Authorization ヘッダーの値（`Basic <base64(スタックの ID:トークン)>`）は、SSM Parameter Store の `/app/grafana/prod/otlp_auth`（SecureString）に置かれている前提で、パラメータはこのリポジトリの外で作成・管理する。Collectorレイヤーは SSM Parameter Store を読めないため、Terraform がこのパラメータを読み、Lambda の環境変数 `GRAFANA_CLOUD_OTLP_AUTH` に渡す（値は Terraform の state と Lambda の環境変数に残る）。トークン（Access Policy）には、`traces:write`・`metrics:write`・`logs:write` の権限が要る。`logs:write` が無いと、ログの送信だけが 401/403 で失敗する。

Lambda の計装が付ける AWS のアカウント ID（`cloud.account.id`）と関数の ARN（`cloud.resource_id`）は、Collector で消してから送る。urllib の計装が付ける呼び出し先の URL（`http.url`）は、span では通知 API の API Gateway のホストだけを `{nandemo-oshirase}` に置き換え、メトリクスでは属性ごと消す（Annict の URL のクエリに日付が入り、メトリクスの系列が毎日増えるため）。ログの本文では、ARN の中のアカウント ID を `***` に、API Gateway のホストを `{nandemo-oshirase}` に置き換える（今のアプリのログには入らないが、例外のメッセージなどに入ったときのため）。CloudWatch Logs には元のまま出る。

ログは、アプリの `logging` のログを `opentelemetry-instrumentation-logging`（自前の計装のレイヤー）が OTel のログにして送る。CloudWatch Logs にも今までどおり出る。Grafana の Explore（データソース: Loki）で `{service_name="anime-schedules"}` で絞り込む。Lambda の計装は実行の終わりにトレースとメトリクスしか flush しないので、ログは `lambda_handler` の最後（例外のときも）で flush している（`lambda_function.py` の `_flush_logs`）。flush しないと、応答を返したあとに実行環境が凍結され、次の呼び出しまで送られない（実行環境が止まると失われる）ことがある。

メトリクスは累積値（cumulative）で送る。1日1回の実行でほぼ毎回コールドスタートになり、カウンタは毎回 0 から数え直すため、Grafana では `increase()` ではなく、その日の値（例: `max_over_time(...[1d])`）で見る。


## Deployment

Terraform を使ってAWS上にリソースを作成する。  
詳細は [tf/README.md](./tf/README.md) を参照。
