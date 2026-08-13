"""
FinPulse — Event Hubs Producer
Simulates a stream of financial transactions and sends them to Azure Event Hubs.

Auth: Uses a connection string for local development (simplest path).
In a "production" setup you'd swap to DefaultAzureCredential + Managed Identity
(see the commented alternative below) — worth being able to explain both.
"""

import asyncio
import json
import os
import random
import uuid
from datetime import datetime, timezone

from azure.eventhub.aio import EventHubProducerClient
from azure.eventhub import EventData
from dotenv import load_dotenv
from faker import Faker

load_dotenv()

fake = Faker()

EVENT_HUB_CONNECTION_STR = os.environ["EVENT_HUB_CONNECTION_STR"]  # from Key Vault / .env, not hardcoded
EVENT_HUB_NAME = os.environ.get("EVENT_HUB_NAME", "transactions")

CURRENCIES = ["GBP", "USD", "EUR", "KES", "NGN", "ZAR"]
COUNTRIES = ["UK", "US", "Germany", "Kenya", "Nigeria", "South Africa"]
# Deliberately include a couple of higher-risk jurisdictions so downstream
# "flagging" logic in dbt has something realistic to key off later.
HIGH_RISK_COUNTRIES = {"Nigeria"}


def generate_transaction() -> dict:
    country = random.choice(COUNTRIES)
    amount = round(random.uniform(5, 15000), 2)
    return {
        "transaction_id": str(uuid.uuid4()),
        "account_id": f"ACC{random.randint(10000, 99999)}",
        "customer_name": fake.name(),
        "amount": amount,
        "currency": random.choice(CURRENCIES),
        "country": country,
        "merchant": fake.company(),
        "is_high_risk_country": country in HIGH_RISK_COUNTRIES,
        "event_timestamp": datetime.now(timezone.utc).isoformat(),
    }


async def run(num_events: int = 20, delay_seconds: float = 1.0):
    producer = EventHubProducerClient.from_connection_string(
        conn_str=EVENT_HUB_CONNECTION_STR,
        eventhub_name=EVENT_HUB_NAME,
    )

    async with producer:
        for i in range(num_events):
            batch = await producer.create_batch()
            txn = generate_transaction()
            batch.add(EventData(json.dumps(txn)))
            await producer.send_batch(batch)
            print(f"[{i+1}/{num_events}] sent txn {txn['transaction_id']} "
                  f"{txn['amount']} {txn['currency']} ({txn['country']})")
            await asyncio.sleep(delay_seconds)

    print("Done.")


if __name__ == "__main__":
    asyncio.run(run(num_events=20, delay_seconds=1.0))
