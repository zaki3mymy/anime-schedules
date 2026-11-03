import json
import logging
import os
from datetime import datetime, timedelta, timezone
from urllib.parse import urlencode
from urllib.request import Request, urlopen

from opentelemetry import metrics, trace

ANNICT_ENDPOINT = "https://api.annict.com"

logger = logging.getLogger(name=__name__)

_tracer = trace.get_tracer("anime_schedules")
_meter = metrics.get_meter("anime_schedules")

_notification_counter = _meter.create_counter(
    "anime_schedules.notifications.sent",
    unit="1",
    description="Number of notification API calls",
)
_fetched_count_histogram = _meter.create_histogram(
    "anime_schedules.schedules.fetched",
    unit="1",
    description="Number of programs fetched per run",
)


@_tracer.start_as_current_span("fetch_schedule")
def _fetch_schedule(date: datetime) -> dict:
    """その日の18時～26時に放送されるアニメを取得する。

    Args:
        date (datetime): 放送日を取得する日(JST)

    Returns:
        dict: 放送日
    """
    token = os.environ["ANNICT_TOKEN"]
    annict_endpoint = os.environ.get("ANNICT_ENDPOINT", ANNICT_ENDPOINT)

    # 時間を落とす
    date = date.replace(hour=0, minute=0, second=0, microsecond=0)

    # Annict では時間はUTCとして扱われるため日本時間に合わせる
    from_dt = date + timedelta(hours=(18 - 9))
    to_dt = date + timedelta(hours=(26 - 9))
    params = {
        "filter_started_at_gt": from_dt.isoformat(),
        "filter_started_at_lt": to_dt.isoformat(),
        # 放送日の昇順で取得する
        "sort_started_at": "asc",
    }

    # 参考: https://developers.annict.com/docs/rest-api/v1/programs#get-v1meprograms
    url = f"{annict_endpoint}/v1/me/programs?{urlencode(params)}"
    logger.debug(url)
    headers = {
        "Authorization": f"Bearer {token}",
        # urllibの素の User-Agent では Annict は 403 を返すようにしているっぽい。
        # Windows の cmd に標準搭載されている curl では通ったのでそれを使う。
        # 日に1回しか動かさないので許してくれるだろう・・・。
        "User-Agent": "curl/8.11.1",
    }
    req = Request(url, headers=headers)
    with urlopen(req) as res:
        body = res.read()

    schedules = json.loads(body)
    programs_count = len(schedules.get("programs", []))
    trace.get_current_span().set_attribute("annict.programs_count", programs_count)
    _fetched_count_histogram.record(programs_count)
    return schedules


def _change_message_format(schedules: dict[str, list]) -> list[dict[str, str]]:
    def format_msg(program) -> str:
        title = program["work"]["title"]
        dt = datetime.fromisoformat(program["started_at"])
        started_at = (dt + timedelta(hours=9)).strftime("%Y/%m/%d %H:%M:%S")
        channel = program["channel"]["name"]
        episode = program.get("episode", {}) or {}
        episode_number = episode.get("number_text", "N/A")
        episode_title = episode.get("title", "N/A")

        msg = f"""{title}
{started_at}
{channel}
{episode_number} {episode_title}"""
        return msg

    return [
        {"type": "text", "text": format_msg(p)} for p in schedules.get("programs", [])
    ]


@_tracer.start_as_current_span("push_message")
def _push_message(messages: list[dict[str, str]]):
    trace.get_current_span().set_attribute("notify.message_count", len(messages))

    api_key = os.environ["NOTIFY_API_KEY"]
    notify_endpoint = os.environ["NOTIFY_ENDPOINT"]

    url = f"{notify_endpoint}/notify"
    headers = {
        "Content-Type": "application/json",
        "x-api-key": api_key,
    }

    texts = [m["text"] for m in messages]
    body = {"messages": texts}
    req = Request(
        url, json.dumps(body).encode("utf-8"), headers=headers, method="POST"
    )
    try:
        with urlopen(req) as res:
            res.read()
    except Exception:
        _notification_counter.add(1, {"status": "error"})
        raise
    _notification_counter.add(1, {"status": "success"})


def lambda_handler(event, context):
    if not os.environ.get("ANNICT_TOKEN"):
        raise KeyError("Environment variable 'ANNICT_TOKEN' is not set.")
    if not os.environ.get("NOTIFY_API_KEY"):
        raise KeyError("Environment variable 'NOTIFY_API_KEY' is not set.")
    if not os.environ.get("NOTIFY_ENDPOINT"):
        raise KeyError("Environment variable 'NOTIFY_ENDPOINT' is not set.")

    today = datetime.now(timezone.utc) + timedelta(hours=9)
    schedules = _fetch_schedule(today)
    logger.info(json.dumps({"schedules": schedules}, ensure_ascii=False))

    messages = _change_message_format(schedules)
    logger.info(json.dumps({"send_messages": messages}, ensure_ascii=False))

    _push_message(messages)


if __name__ == "__main__":
    lambda_handler({}, {})
