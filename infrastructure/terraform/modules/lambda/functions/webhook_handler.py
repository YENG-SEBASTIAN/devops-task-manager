"""Webhook Lambda — handles external webhook events (GitHub, Stripe, etc.)

Receives webhook payloads, validates, and queues notifications.
Pay-per-request: 1M free/month, then $0.20/1M
"""

import hashlib
import hmac
import json
import os
import time


def handler(event, context):
    try:
        body = json.loads(event.get("body", "{}"))
        headers = {k.lower(): v for k, v in (event.get("headers") or {}).items()}

        # ── GitHub webhook validation ────────────────────────
        github_event = headers.get("x-github-event", "")
        if github_event:
            print(f"GitHub webhook: event={github_event}")
            return _handle_github(body, github_event)

        # ── Generic webhook ──────────────────────────────────
        source = body.get("source", "unknown")
        event_type = body.get("event", "unknown")
        print(f"Generic webhook: source={source}, event={event_type}")

        # Queue notification
        queue_url = os.environ.get("SQS_QUEUE_URL")
        if queue_url:
            _send_sqs(queue_url, {
                "type": "webhook",
                "source": source,
                "event": event_type,
                "payload": body,
                "timestamp": int(time.time()),
            })

        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"status": "accepted"}),
        }

    except Exception as e:
        print(f"Webhook error: {e}")
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": str(e)}),
        }


def _handle_github(body, event_type):
    action = body.get("action", "")
    repo = body.get("repository", {}).get("full_name", "")

    print(f"GitHub: {event_type} {action} on {repo}")

    # Queue relevant notifications
    queue_url = os.environ.get("SQS_QUEUE_URL")
    if queue_url and event_type in ("push", "pull_request", "issues"):
        _send_sqs(queue_url, {
            "type": "github",
            "event": event_type,
            "action": action,
            "repo": repo,
            "sender": body.get("sender", {}).get("login", ""),
            "timestamp": int(time.time()),
        })

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"status": "accepted", "event": event_type}),
    }


def _send_sqs(queue_url, message):
    """Send message to SQS queue."""
    try:
        import boto3
        sqs = boto3.client("sqs")
        sqs.send_message(
            QueueUrl=queue_url,
            MessageBody=json.dumps(message),
        )
    except Exception as e:
        print(f"SQS send error: {e}")
