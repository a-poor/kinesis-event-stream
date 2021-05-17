import json
import time
import boto3
import numpy as np
import datetime as dt
from tqdm import trange


N_USERS = 100
N_EVENTS = 10_000

source = ["api","site","site","site"]
events = [
    "/","/","/","/","/","/","/","/",
    "/about","/about",
    "/blog","/blog","/blog","/blog",
    "/blog/b01","/blog/b01","/blog/b01",
    "/blog/b02","/blog/b02",
    "/blog/b03",
]

def rand_time():
    return dt.datetime.now() - dt.timedelta(
        days=np.random.randint(50),
        hours=np.random.randint(24),
        minutes=np.random.randint(60)
    )

def create_event(eid: int):
    return {
        "eventid": eid,
        "timestamp": str(rand_time()),
        "userid": np.random.randint(N_USERS),
        "path": np.random.choice(events),
        "source": np.random.choice(source)
    }

client = boto3.client("firehose")

for e in trange(N_EVENTS,desc="Events Pushed"):
    time.sleep(max(0,np.random.exponential(.1)))
    client.put_record(
        DeliveryStreamName="kinesis-test-stream",
        Record={
            "Data": json.dumps(create_event(e)).encode()
        }
    )

