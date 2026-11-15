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
