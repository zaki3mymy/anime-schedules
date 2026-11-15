from unittest.mock import patch

import pytest

from anime_schedules import lambda_function


@pytest.fixture(autouse=True)
def _env(monkeypatch):
    monkeypatch.setenv("ANNICT_TOKEN", "token")
    monkeypatch.setenv("NOTIFY_API_KEY", "key")
    monkeypatch.setenv("NOTIFY_ENDPOINT", "https://example.com")


def test_skip_push_when_no_programs():
    with (
        patch.object(lambda_function, "_fetch_schedule", return_value={"programs": []}),
        patch.object(lambda_function, "_push_message") as push,
    ):
        lambda_function.lambda_handler({}, {})

    push.assert_not_called()


def test_push_when_programs_exist():
    program = {
        "started_at": "2025-07-10T13:30:00.000Z",
        "channel": {"name": "TOKYO MX"},
        "work": {"title": "title"},
        "episode": None,
    }
    with (
        patch.object(
            lambda_function, "_fetch_schedule", return_value={"programs": [program]}
        ),
        patch.object(lambda_function, "_push_message") as push,
    ):
        lambda_function.lambda_handler({}, {})

    push.assert_called_once()
    assert len(push.call_args.args[0]) == 1


def test_push_message_injects_traceparent():
    from opentelemetry import trace
    from opentelemetry.sdk.trace import TracerProvider
    from opentelemetry.sdk.trace.export import SimpleSpanProcessor
    from opentelemetry.sdk.trace.export.in_memory_span_exporter import (
        InMemorySpanExporter,
    )

    exporter = InMemorySpanExporter()
    provider = TracerProvider()
    provider.add_span_processor(SimpleSpanProcessor(exporter))
    tracer = provider.get_tracer("test")

    captured = {}

    class _Res:
        status = 200

        def read(self):
            return b""

        def __enter__(self):
            return self

        def __exit__(self, *args):
            return False

    def fake_urlopen(req):
        captured["headers"] = {k.lower(): v for k, v in req.header_items()}
        return _Res()

    with (
        patch.object(lambda_function, "_tracer", tracer),
        patch.object(lambda_function, "urlopen", fake_urlopen),
    ):
        lambda_function._push_message.__wrapped__([{"type": "text", "text": "a"}])

    spans = {s.name: s for s in exporter.get_finished_spans()}
    client = spans["POST /notify"]
    assert client.kind == trace.SpanKind.CLIENT
    assert client.attributes["http.response.status_code"] == 200
    trace_id = format(client.context.trace_id, "032x")
    span_id = format(client.context.span_id, "016x")
    assert captured["headers"]["traceparent"].startswith(f"00-{trace_id}-{span_id}-")
