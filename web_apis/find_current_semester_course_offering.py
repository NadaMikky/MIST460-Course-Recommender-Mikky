from fastapi import APIRouter, Query, HTTPException
from web_apis.get_db_connection import get_db_connection

router = APIRouter()

# 2. find_current_semester_course_offerings
@router.get("/find_current_semester_course_offerings")
def find_current_semester_course_offerings(subject_code: str = Query(...), course_number: str = Query(...)):
    # open DB connection and call stored procedure
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("{CALL procFindCurrentSemesterCourseOfferingsForSpecifiedCourse(?, ?)}", (subject_code, course_number))
        rows = cur.fetchall()
        cols = [c[0] for c in cur.description] if cur.description else []
        data = [{cols[i]: row[i] for i in range(len(cols))} for row in rows]
        return {"data": data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cur.close()
        conn.close()