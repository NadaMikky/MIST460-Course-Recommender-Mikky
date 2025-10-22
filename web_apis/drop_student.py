from fastapi import APIRouter, Body, HTTPException
from typing import Dict, Any
from web_apis.course_recommender_apis import get_db_connection, _rows_to_dicts
import pyodbc

router = APIRouter()

@router.post("/drop_student_from_course_offering")
def drop_student(payload: Dict[str, Any] = Body(...)):
    student_id = payload.get("student_id")
    course_offering_id = payload.get("course_offering_id")
    if student_id is None or course_offering_id is None:
        raise HTTPException(status_code=400, detail="student_id and course_offering_id required")

    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("{CALL procDropStudentFromCourseOfferingCalled(?, ?)}", (int(student_id), int(course_offering_id)))
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
