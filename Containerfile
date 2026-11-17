# uv の公式イメージの python3.13-bookworm-slim のタグは、uv 0.10 以降は更新されていない（uv 0.9.30 のまま）。
# そのため Python のイメージに uv の実行ファイルだけをコピーする。uv のバージョンは
# pyproject.toml の [tool.uv] required-version の範囲に合わせる（上げるときは両方を変える）
FROM python:3.13-slim-bookworm AS deps-builder
COPY --from=ghcr.io/astral-sh/uv:0.13.8 /uv /uvx /bin/

WORKDIR /app

COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project
# venv内のコンソールスクリプトのshebangがビルドステージ内のパス(/app/.venv/bin/python)を
# 指しており、そのままコピーすると最終イメージで実行できないため書き換える
RUN sed -i '1s|^#!.*|#!/usr/bin/env python3|' .venv/bin/opentelemetry-instrument

FROM public.ecr.aws/lambda/python:3.13

WORKDIR ${LAMBDA_TASK_ROOT}

# opentelemetry-instrumentはawslambdaric経由の起動前に実行されるため、
# 依存パッケージをコピーした${LAMBDA_TASK_ROOT}をあらかじめ検索パスに加えておく必要がある
ENV PYTHONPATH=${LAMBDA_TASK_ROOT}

COPY --from=deps-builder /app/.venv/lib/python3.13/site-packages/ ${LAMBDA_TASK_ROOT}/
COPY --from=deps-builder /app/.venv/bin/opentelemetry-instrument /usr/local/bin/opentelemetry-instrument
COPY src/anime_schedules/ .

CMD ["lambda_function.lambda_handler"]
