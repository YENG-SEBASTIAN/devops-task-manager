"""Cleanup Lambda — scheduled task for housekeeping.

Runs daily via EventBridge (cron). Deletes old logs, expired tokens, etc.
Pay-per-request: basically free (~$0.0000167 per execution, 1x/day)
"""

import json
import os
import time


def handler(event, context):
    start = time.time()
    results = {}

    # ── Database cleanup ─────────────────────────────────────
    try:
        results["database"] = _cleanup_database()
    except Exception as e:
        results["database"] = {"status": "error", "error": str(e)}

    # ── Log cleanup ──────────────────────────────────────────
    try:
        results["logs"] = _cleanup_old_logs()
    except Exception as e:
        results["logs"] = {"status": "error", "error": str(e)}

    duration = round(time.time() - start, 2)

    print(f"Cleanup completed in {duration}s: {json.dumps(results)}")

    return {
        "statusCode": 200,
        "body": json.dumps({
            "status": "completed",
            "duration_seconds": duration,
            "results": results,
            "timestamp": int(time.time()),
        }),
    }


def _cleanup_database():
    """Delete expired/soft-deleted records older than 90 days."""
    # In production, this would connect to RDS and run:
    # DELETE FROM tasks WHERE deleted_at < NOW() - INTERVAL '90 days';
    # DELETE FROM auth_tokens WHERE expires_at < NOW();
    return {"status": "skipped", "note": "Connect to RDS to enable"}


def _cleanup_old_logs():
    """Clean up CloudWatch log groups older than retention period."""
    # Log retention is already configured in Terraform (14-30 days)
    # This is a no-op unless custom cleanup is needed
    return {"status": "ok", "note": "Retention managed by Terraform"}
