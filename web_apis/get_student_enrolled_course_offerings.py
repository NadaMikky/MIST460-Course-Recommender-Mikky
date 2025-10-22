from fastapi import APIRouter, Query, HTTPException
from web_apis.course_recommender_apis import get_db_connection, _rows_to_dicts

router = APIRouter()

# 6. get_student_enrolled_course_offerings
@router.get("/get_student_enrolled_course_offerings")
def get_enrollments(student_id: int = Query(...)):
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("""
            SELECT rco.RegistrationCourseOfferingID, rco.EnrollmentStatus, co.CourseOfferingID, co.CRN,
                   co.CourseOfferingSemester, co.CourseOfferingYear, c.SubjectCode, c.CourseNumber, c.Title
            FROM RegistrationCourseOffering rco
            JOIN Registration r ON rco.RegistrationID = r.RegistrationID
            JOIN CourseOffering co ON rco.CourseOfferingID = co.CourseOfferingID
            JOIN Course c ON co.CourseID = c.CourseID
            WHERE r.StudentID = ?
            ORDER BY co.CourseOfferingYear DESC, co.CourseOfferingSemester;
        """, (student_id,))
        rows = cur.fetchall()
        return {"data": _rows_to_dicts(cur, rows)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cur.close()
        conn.close()
