import json
import logging
import os
from datetime import datetime, timedelta, timezone
from urllib.parse import urlencode
from urllib.request import Request, urlopen

ENDPOINT = "https://api.annict.com"

logger = logging.getLogger(name=__name__)


def _fetch_schedule(date: datetime) -> dict:
    """その日の18時～26時に放送されるアニメを取得する。

    Args:
        date (datetime): 放送日を取得する日(JST)

    Returns:
        dict: 放送日
    """
    token = os.environ["TOKEN"]

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

    url = f"{ENDPOINT}/v1/me/programs?{urlencode(params)}"
    logger.debug(url)
    headers = {"Authorization": f"Bearer {token}"}
    req = Request(url, headers=headers)
    with urlopen(req) as res:
        body = res.read()

    return json.loads(body)


def lambda_handler(event, context):
    TOKEN = os.environ.get("TOKEN")
    if not TOKEN:
        raise KeyError("Environment variable 'TOKEN' is not set.")

    today = datetime.now(timezone.utc) + timedelta(hours=9)
    body = _fetch_schedule(today)
    with open("tmp.json", "w", encoding="utf-8") as f:
        json.dump(body, f, indent=4, ensure_ascii=False)


if __name__ == "__main__":
    lambda_handler({}, {})
