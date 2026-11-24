from unittest.mock import Mock, patch

import pytest
from opentelemetry._logs._internal import ProxyLoggerProvider
from opentelemetry.sdk._logs import LoggerProvider

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


def test_flushes_logs_after_handling():
    provider = Mock(spec=LoggerProvider)
    with (
        patch.object(lambda_function, "get_logger_provider", return_value=provider),
        patch.object(lambda_function, "_fetch_schedule", return_value={"programs": []}),
    ):
        lambda_function.lambda_handler({}, {})

    provider.force_flush.assert_called_once_with(
        timeout_millis=lambda_function.LOG_FLUSH_TIMEOUT_MILLIS
    )


def test_flushes_logs_even_when_handling_raises():
    provider = Mock(spec=LoggerProvider)
    with (
        patch.object(lambda_function, "get_logger_provider", return_value=provider),
        patch.object(
            lambda_function, "_fetch_schedule", side_effect=RuntimeError("boom")
        ),
        pytest.raises(RuntimeError),
    ):
        lambda_function.lambda_handler({}, {})

    provider.force_flush.assert_called_once()


def test_skips_flush_without_sdk():
    # SDK が設定されていないときは、API の ProxyLoggerProvider が返る（force_flush が無い）
    with (
        patch.object(
            lambda_function, "get_logger_provider", return_value=ProxyLoggerProvider()
        ),
        patch.object(lambda_function, "_fetch_schedule", return_value={"programs": []}),
    ):
        lambda_function.lambda_handler({}, {})
