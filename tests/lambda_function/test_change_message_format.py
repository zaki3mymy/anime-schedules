from anime_schedules.lambda_function import _change_message_format


def test_ok():
    # 準備
    schedules = {
        "programs": [
            {
                "id": 401273,
                "started_at": "2025-07-10T13:30:00.000Z",
                "is_rebroadcast": False,
                "channel": {"id": 19, "name": "TOKYO MX"},
                "work": {
                    "id": 12904,
                    "title": "忍者と殺し屋のふたりぐらし",
                    "title_kana": "にんじゃところしやのふたりぐらし",
                    "title_en": "Ninja to Koroshiya no Futarigurashi",
                    "media": "tv",
                    "media_text": "TV",
                    "released_on": "",
                    "released_on_about": "",
                    "official_site_url": "https://ninkoro.jp/",
                    "wikipedia_url": "https://ja.wikipedia.org/wiki/%E5%BF%8D%E8%80%85%E3%81%A8%E6%AE%BA%E3%81%97%E5%B1%8B%E3%81%AE%E3%81%B5%E3%81%9F%E3%82%8A%E3%81%90%E3%82%89%E3%81%97",
                    "twitter_username": "ninkoro_anime",
                    "twitter_hashtag": "にんころ",
                    "syobocal_tid": "7363",
                    "mal_anime_id": "58725",
                    "images": {
                        "recommended_url": "",
                        "facebook": {
                            "og_image_url": "https://ninkoro.jp/core_sys/images/others/ogp.jpg"
                        },
                        "twitter": {
                            "mini_avatar_url": "https://twitter.com/ninkoro_anime/profile_image?size=mini",
                            "normal_avatar_url": "https://twitter.com/ninkoro_anime/profile_image?size=normal",
                            "bigger_avatar_url": "https://twitter.com/ninkoro_anime/profile_image?size=bigger",
                            "original_avatar_url": "https://twitter.com/ninkoro_anime/profile_image?size=original",
                            "image_url": "",
                        },
                    },
                    "episodes_count": 12,
                    "watchers_count": 1314,
                    "reviews_count": 30,
                    "no_episodes": False,
                    "season_name": "2025-spring",
                    "season_name_text": "2025年春",
                },
                "episode": None,
            },
            {
                "id": 404059,
                "started_at": "2025-07-10T15:00:00.000Z",
                "is_rebroadcast": False,
                "channel": {"id": 241, "name": "dアニメストア"},
                "work": {
                    "id": 13993,
                    "title": "小市民シリーズ 第2期",
                    "title_kana": "しょうしみんしりーず",
                    "title_en": "Shoushimin Series 2nd Season",
                    "media": "tv",
                    "media_text": "TV",
                    "released_on": "",
                    "released_on_about": "",
                    "official_site_url": "https://shoshimin-anime.com/",
                    "wikipedia_url": "https://ja.wikipedia.org/wiki/%E3%80%88%E5%B0%8F%E5%B8%82%E6%B0%91%E3%80%89%E3%82%B7%E3%83%AA%E3%83%BC%E3%82%BA#%E3%83%86%E3%83%AC%E3%83%93%E3%82%A2%E3%83%8B%E3%83%A1",
                    "twitter_username": "shoshimin_pr",
                    "twitter_hashtag": "小市民",
                    "syobocal_tid": "7397",
                    "mal_anime_id": "59828",
                    "images": {
                        "recommended_url": "",
                        "facebook": {
                            "og_image_url": "https://shoshimin-anime.com/core_sys/images/others/ogp.jpg"
                        },
                        "twitter": {
                            "mini_avatar_url": "https://twitter.com/shoshimin_pr/profile_image?size=mini",
                            "normal_avatar_url": "https://twitter.com/shoshimin_pr/profile_image?size=normal",
                            "bigger_avatar_url": "https://twitter.com/shoshimin_pr/profile_image?size=bigger",
                            "original_avatar_url": "https://twitter.com/shoshimin_pr/profile_image?size=original",
                            "image_url": "",
                        },
                    },
                    "episodes_count": 12,
                    "watchers_count": 1603,
                    "reviews_count": 31,
                    "no_episodes": False,
                    "season_name": "2025-spring",
                    "season_name_text": "2025年春",
                },
                "episode": None,
            },
            {
                "id": 431527,
                "started_at": "2025-07-10T15:30:00.000Z",
                "is_rebroadcast": False,
                "channel": {"id": 19, "name": "TOKYO MX"},
                "work": {
                    "id": 15042,
                    "title": "ふたりソロキャンプ",
                    "title_kana": "ふたりそろきゃんぷ",
                    "title_en": "Futari Solo Camp",
                    "media": "tv",
                    "media_text": "TV",
                    "released_on": "",
                    "released_on_about": "",
                    "official_site_url": "https://2solocamp-anime.com/",
                    "wikipedia_url": "https://ja.wikipedia.org/wiki/%E3%81%B5%E3%81%9F%E3%82%8A%E3%82%BD%E3%83%AD%E3%82%AD%E3%83%A3%E3%83%B3%E3%83%97",
                    "twitter_username": "2solocamp_anime",
                    "twitter_hashtag": "ふたりソロキャンプ",
                    "syobocal_tid": "7474",
                    "mal_anime_id": "60665",
                    "images": {
                        "recommended_url": "",
                        "facebook": {
                            "og_image_url": "https://2solocamp-anime.com/core_sys/images/others/ogp.jpg"
                        },
                        "twitter": {
                            "mini_avatar_url": "https://twitter.com/2solocamp_anime/profile_image?size=mini",
                            "normal_avatar_url": "https://twitter.com/2solocamp_anime/profile_image?size=normal",
                            "bigger_avatar_url": "https://twitter.com/2solocamp_anime/profile_image?size=bigger",
                            "original_avatar_url": "https://twitter.com/2solocamp_anime/profile_image?size=original",
                            "image_url": "",
                        },
                    },
                    "episodes_count": 1,
                    "watchers_count": 428,
                    "reviews_count": 0,
                    "no_episodes": False,
                    "season_name": "2025-summer",
                    "season_name_text": "2025年夏",
                },
                "episode": {
                    "id": 171236,
                    "number": 1.0,
                    "number_text": "第1話",
                    "sort_number": 100,
                    "title": "独り野営にて思ふ",
                    "records_count": 0,
                    "record_comments_count": 0,
                },
            },
        ],
        "total_count": 3,
        "next_page": None,
        "prev_page": None,
    }

    # 実行
    actual = _change_message_format(schedules)

    # 検証
    expected = [
        {
            "type": "text",
            "text": """忍者と殺し屋のふたりぐらし
2025/07/10 22:30:00
TOKYO MX
N/A N/A""",
        },
        {
            "type": "text",
            "text": """小市民シリーズ 第2期
2025/07/11 00:00:00
dアニメストア
N/A N/A""",
        },
        {
            "type": "text",
            "text": """ふたりソロキャンプ
2025/07/11 00:30:00
TOKYO MX
第1話 独り野営にて思ふ""",
        },
    ]
    assert expected == actual
