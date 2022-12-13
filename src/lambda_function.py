from datetime import datetime
from pytz import timezone


def lambda_handler(event, context):
    now = datetime.now(timezone('Asia/Tokyo')).hour

    if 4 < now < 11:
        return "おはよう"
    elif 12 < now < 19:
        return "こんにちは"
    return "こんばんは"
