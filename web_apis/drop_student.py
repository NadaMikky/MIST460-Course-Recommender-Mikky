from fastapi import APIRouter, Body, HTTPException
from typing import Dict, Any
from web_apis.get_db_connection import get_db_connection, _rows_to_dicts
import pyodbc

router = APIRouter()

# 7. drop_student_from_course_offering
@router.post("/drop_student_from_course_offering")
# takes student_id and course_offering_id from payload
def drop_student(payload: Dict[str, Any] = Body(...)):
    student_id = payload.get("student_id")
    course_offering_id = payload.get("course_offering_id")
    if student_id is None or course_offering_id is None:
        raise HTTPException(status_code=400, detail="student_id and course_offering_id required")

    conn = get_db_connection()
    cur = conn.cursor()
    try:
        # use schema-qualified EXEC and parameter placeholders
        cur.execute("EXEC dbo.procDropStudentFromCourseOfferingCalled ?, ?", (int(student_id), int(course_offering_id)))
        try:
            rows = cur.fetchall()
            return {"success": True, "data": _rows_to_dicts(cur, rows)}
        except Exception:
            return {"success": True}
    except pyodbc.Error as e:
        msg = str(e)
        # helpful guidance if the stored procedure is missing
        if "Could not find stored procedure" in msg or "2812" in msg:
            raise HTTPException(
                status_code=500,
                detail="Stored procedure dbo.procDropStudentFromCourseOfferingCalled not found. Run Database_objects_Mikky.sql against Homework3Group1 to create it."
            )
        raise HTTPException(status_code=500, detail=msg)
    finally:
        cur.close()
        conn.close()
