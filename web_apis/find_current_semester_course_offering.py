from fastapi import APIRouter, Query, HTTPException
from web_apis.get_db_connection import get_db_connection

router = APIRouter()

@router.get("/find_current_semester_course_offerings")
def find_current_semester_course_offerings(subject_code: str = Query(...), course_number: str = Query(...)):
    # open DB connection
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # call stored procedure with parameters
        cursor.execute("{CALL procFindCurrentSemesterCourseOfferingsForSpecifiedCourse(?, ?)}", (subject_code, course_number))
        rows = cursor.fetchall()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cursor.close()
        conn.close()

    # convert rows to list of dicts for JSON
    cols = [c[0] for c in cursor.description] if cursor.description else []
    results = [dict(zip(cols, row)) for row in rows]

    return {"data": results}