"""Notification Lambda — processes email/push notifications from SQS.

Triggered by SQS events. Reads DB secret, sends notifications.
Pay-per-request: 1M free/month, then $0.20/1M
SQS trigger: no additional charge for Lambda invocations from SQS
"""

import json
import os
import time
import urllib.request


def handler(event, context):
    results = []

    for record in event.get("Records", []):
        try:
            body = json.loads(record["body"])
            notification_type = body.get("type", "unknown")
            recipient = body.get("recipient", "")
            subject = body.get("subject", "")
            message = body.get("message", "")

            # ── Log the notification ─────────────────────────
            print(f"Processing notification: type={notification_type}, to={recipient}")

            # ── Email via SES (if configured) ────────────────
            if notification_type == "email" and recipient:
                # SES integration would go here
                # For now, log the intent
                print(f"Would send email to {recipient}: {subject}")

            results.append({
                "message_id": record.get("messageId"),
                "status": "processed",
                "type": notification_type,
            })

        except Exception as e:
            print(f"Error processing record: {e}")
            results.append({
                "message_id": record.get("messageId"),
                "status": "failed",
                "error": str(e),
            })

    return {
        "statusCode": 200,
        "body": json.dumps({
            "processed": len(results),
            "results": results,
        }),
    }
