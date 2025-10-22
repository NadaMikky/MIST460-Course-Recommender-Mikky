from fastapi import APIRouter, Query, HTTPException
from web_apis.course_recommender_apis import get_db_connection, _rows_to_dicts

router = APIRouter()
# 4. check_if_student_has_taken_all_prerequisites_for_course
@router.get("/check_if_student_has_taken_all_prerequisites_for_course")
def check_prereqs(student_id: int = Query(...), subject_code: str = Query(...), course_number: str = Query(...)):
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("EXEC dbo.procCheckIfStudentMeetsPrerequisites ?, ?, ?", (student_id, subject_code, course_number))
        # first resultset: prerequisites list
        prereq_rows = cur.fetchall()
        prereqs = _rows_to_dicts(cur, prereq_rows)
        meets_all = None
        # move to second resultset: scalar
        if cur.nextset():
            scalar = cur.fetchone()
            if scalar:
                meets_all = scalar[0]
        return {"prerequisites": prereqs, "meets_all_prerequisites": meets_all}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cur.close()
        conn.close()
