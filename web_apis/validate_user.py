from fastapi import APIRouter, HTTPException, Body
from typing import Dict, Any
from web_apis.course_recommender_apis import get_db_connection, _rows_to_dicts

router = APIRouter()

@router.post("/validate_user")
def validate_user(payload: Dict[str, str] = Body(...)):
    # simple input check
    username = payload.get("username")
    password = payload.get("password")
    if not username or not password:
        raise HTTPException(status_code=400, detail="username and password required")

    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("{CALL procValidateUser(?, ?)}", (username, password))
        row = cur.fetchone()
        if not row:
            return {"valid": False}
        cols = [c[0] for c in cur.description] if cur.description else []
        user = {cols[i]: row[i] for i in range(len(cols))}
        return {"valid": True, "user": user}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cur.close()
        conn.close()
