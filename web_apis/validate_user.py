from fastapi import APIRouter, HTTPException, Body
from typing import Dict, Any
from web_apis.get_db_connection import get_db_connection, _rows_to_dicts
import pyodbc

router = APIRouter()

# 1. validate_user
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
        # use schema-qualified procedure name
        cur.execute("EXEC dbo.procValidateUser ?, ?", (username, password))
        row = cur.fetchone() # get first row of resultset
        if not row:
            return {"valid": False}
        
        cols = [c[0] for c in cur.description] if cur.description else []
        user = {cols[i]: row[i] for i in range(len(cols))}
        return {"valid": True, "user": user}
    except pyodbc.Error as e:
        msg = str(e)
        if "Could not find stored procedure" in msg or "2812" in msg:
            raise HTTPException(
                status_code=500,
                detail="Stored procedure dbo.procValidateUser not found. Run Database_objects_Mikky.sql against Homework3Group1."
            )
        raise HTTPException(status_code=500, detail=msg)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cur.close()
        conn.close()
