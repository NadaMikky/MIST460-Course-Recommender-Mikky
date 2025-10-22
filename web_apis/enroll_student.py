from fastapi import APIRouter, Body, HTTPException
from typing import Dict, Any
from web_apis.course_recommender_apis import get_db_connection, _rows_to_dicts
import pyodbc

router = APIRouter()

# 5. enroll_student_in_course_offering 
@router.post("/enroll_student_in_course_offering")
def enroll_student(payload: Dict[str, Any] = Body(...)):
    student_id = payload.get("student_id")
    crn = payload.get("crn")
    if student_id is None or crn is None:
        raise HTTPException(status_code=400, detail="student_id and crn required")

    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("{CALL procEnrollStudentInCourseOfferingCalled(?, ?)}", (int(student_id), int(crn)))
        # optional resultset
        try:
            rows = cur.fetchall()
            return {"success": True, "data": _rows_to_dicts(cur, rows)}
        except Exception:
            return {"success": True}
    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cur.close()
        conn.close()
