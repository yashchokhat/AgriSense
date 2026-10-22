from datetime import datetime, timezone
from typing import Any, Optional, Dict, Tuple
from flask import jsonify, Response

def api_response(
    data: Any = None,
    success: bool = True,
    error_code: Optional[str] = None,
    error_message: Optional[str] = None,
    error_details: Any = None,
    status_code: int = 200,
) -> Tuple[Response, int]:
    """
    Constructs a consistent standard JSON response format for all AgriSense API endpoints.
    """
    now_iso = datetime.now(timezone.utc).isoformat()

    error_payload = None
    if not success or error_code or error_message:
        error_payload = {
            "code": error_code or "SERVER_ERROR",
            "message": error_message or "An unexpected error occurred.",
            "details": error_details,
        }

    payload = {
        "success": success,
        "data": data,
        "meta": {
            "timestamp": now_iso,
            "version": "1.0.0",
        },
        "error": error_payload,
    }

    return jsonify(payload), status_code
