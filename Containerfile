FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim AS deps-builder

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
