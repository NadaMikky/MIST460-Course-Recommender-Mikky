from fastapi import FastAPI, HTTPException, Body, Query
import uvicorn
from typing import List, Dict, Any, Optional
import pyodbc

app = FastAPI()

# Database connection parameters
DB_SERVER = 'localhost'
DB_DATABASE = 'Homework3Group1'
DB_USERNAME = 'your_username'
DB_PASSWORD = 'your_password'
DB_DRIVER = '{ODBC Driver 17 for SQL Server}'


def get_db_connection():
    try:
        conn_str = (
            f'DRIVER={DB_DRIVER};'
            f'SERVER={DB_SERVER};'
            f'DATABASE={DB_DATABASE};'
            f'Trusted_Connection=yes;'
        )
        return pyodbc.connect(conn_str)
    except Exception as e:
        print(f"ERROR connecting to database: {e}")
        raise HTTPException(status_code=500, detail="Database connection error")


# 10/20 helper to convert pyodbc rows to list[dict]
def _rows_to_dicts(cursor, rows):
    cols = [c[0] for c in cursor.description] if cursor.description else []
    result = []
    for row in rows:
        row_dict = {}
        for idx, col in enumerate(cols):
            row_dict[col] = row[idx]
        result.append(row_dict)
    return result

# 1. validate_user
@app.post("/validate_user")
def validate_user(payload: Dict[str, str] = Body(...)):
    """
    Calls procValidateUser(username, password)
    Expects JSON body: { "username": "...", "password": "..." }
    Returns {"valid": bool, "user": {...} } if stored procedure returns a row, otherwise {"valid": false}
    Note: this endpoint assumes a stored procedure named procValidateUser(username, password) exists.
    """
    username = payload.get("username")
    password = payload.get("password")
    if not username or not password:
        raise HTTPException(status_code=400, detail="username and password required")

    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("{CALL procValidateUser(?, ?)}", (username, password))
        row = cursor.fetchone()
        if not row:
            return {"valid": False}
        # convert single row to dict using description
        cols = [c[0] for c in cursor.description] if cursor.description else []
        user = {cols[i]: row[i] for i in range(len(cols))}
        return {"valid": True, "user": user}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        try:
            cursor.close()
        except Exception:
            pass
        try:
            conn.close()
        except Exception:
            pass

# 2. find_current_semester_course_offerings
@app.get("/find_current_semester_course_offerings")
def find_current_semester_course_offerings(
    subject_code: str = Query(..., alias="subject_code"),
    course_number: str = Query(..., alias="course_number")
):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            "{CALL procFindCurrentSemesterCourseOfferingsForSpecifiedCourse(?, ?)}",
            (subject_code, course_number)
        )
        rows = cursor.fetchall()
        results = _rows_to_dicts(cursor, rows)
        return {"data": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        try:
            cursor.close()
        except Exception:
            pass
        try:
            conn.close()
        except Exception:
            pass

# 3. find_prerequisites
@app.get("/find_prerequisites")
def find_prerequisites(
    subject_code: str = Query(..., alias="subject_code"),
    course_number: str = Query(..., alias="course_number")
):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            "EXEC dbo.procFindPrerequisites ?, ?",
            (subject_code, course_number)
        )
        rows = cursor.fetchall()
        results = _rows_to_dicts(cursor, rows)
        return {"data": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        try:
            cursor.close()
        except Exception:
            pass
        try:
            conn.close()
        except Exception:
            pass

# 4. check_if_student_has_taken_all_prerequisites_for_course
@app.get("/check_if_student_has_taken_all_prerequisites_for_course")
def check_if_student_has_taken_all_prerequisites_for_course(
    student_id: int = Query(..., alias="student_id"),
    subject_code: str = Query(..., alias="subject_code"),
    course_number: str = Query(..., alias="course_number")
):
    """
    Calls dbo.procCheckIfStudentMeetsPrerequisites which returns:
      - first resultset: list of prerequisites with HasCompleted flags
      - second resultset: single scalar MeetsAllPrerequisites
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("EXEC dbo.procCheckIfStudentMeetsPrerequisites ?, ?, ?", (student_id, subject_code, course_number))
        # first resultset
        prereq_rows = cursor.fetchall()
        prereqs = _rows_to_dicts(cursor, prereq_rows)
        meets_all = None
        # move to next resultset to get the scalar if present
        if cursor.nextset():
            scalar_rows = cursor.fetchall()
            if scalar_rows and len(scalar_rows) > 0:
                # expect a single row with MeetsAllPrerequisites column
                row = scalar_rows[0]
                if cursor.description:
                    colname = cursor.description[0][0]
                    meets_all = row[0]
                else:
                    meets_all = row[0]
        return {"prerequisites": prereqs, "meets_all_prerequisites": meets_all}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        try:
            cursor.close()
        except Exception:
            pass
        try:
            conn.close()
        except Exception:
            pass

#  5. enroll_student_in_course_offering (uses stored procedure procEnrollStudentInCourseOfferingCalled)
@app.post("/enroll_student_in_course_offering")
def enroll_student_in_course_offering(payload: Dict[str, Any] = Body(...)):
    student_id = payload.get("student_id")
    crn = payload.get("crn")
    if student_id is None or crn is None:
        raise HTTPException(status_code=400, detail="student_id and crn are required")

    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        # call the stored procedure that performs enrollment (expected to RAISERROR on failure)
        cursor.execute("{CALL procEnrollStudentInCourseOfferingCalled(?, ?)}", (int(student_id), int(crn)))
        # try to fetch any resultset returned by the proc (optional)
        try:
            rows = cursor.fetchall()
            data = _rows_to_dicts(cursor, rows)
            return {"success": True, "data": data}
        except Exception:
            # no rows returned, assume success if no exception
            return {"success": True, "message": "Enrolled (no resultset returned)"}
    except pyodbc.Error as e:
        # return DB error text
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        try:
            cursor.close()
        except Exception:
            pass
        try:
            conn.close()
        except Exception:
            pass

# 6. get_student_enrolled_course_offerings
@app.get("/get_student_enrolled_course_offerings")
def get_student_enrolled_course_offerings(student_id: int = Query(..., alias="student_id")):
    """
    Returns the student's enrollments with course and offering details.
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        query = """
        SELECT rco.RegistrationCourseOfferingID,
               rco.EnrollmentStatus,
               co.CourseOfferingID,
               co.CRN,
               co.CourseOfferingSemester,
               co.CourseOfferingYear,
               co.Section,
               co.Location,
               c.SubjectCode,
               c.CourseNumber,
               c.Title
        FROM RegistrationCourseOffering rco
        JOIN Registration r ON rco.RegistrationID = r.RegistrationID
        JOIN CourseOffering co ON rco.CourseOfferingID = co.CourseOfferingID
        JOIN Course c ON co.CourseID = c.CourseID
        WHERE r.StudentID = ?
        ORDER BY co.CourseOfferingYear DESC, co.CourseOfferingSemester, co.Section;
        """
        cursor.execute(query, (student_id,))
        rows = cursor.fetchall()
        results = _rows_to_dicts(cursor, rows)
        return {"data": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        try:
            cursor.close()
        except Exception:
            pass
        try:
            conn.close()
        except Exception:
            pass

# 7. drop_student_from_course_offering (uses stored procedure procDropStudentFromCourseOfferingCalled)
@app.post("/drop_student_from_course_offering")
def drop_student_from_course_offering(payload: Dict[str, Any] = Body(...)):
    student_id = payload.get("student_id")
    course_offering_id = payload.get("course_offering_id")
    if student_id is None or course_offering_id is None:
        raise HTTPException(status_code=400, detail="student_id and course_offering_id are required")

    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("{CALL procDropStudentFromCourseOfferingCalled(?, ?)}", (int(student_id), int(course_offering_id)))
        # attempt to return any resultset (proc may return updated RCO row)
        try:
            rows = cursor.fetchall()
            data = _rows_to_dicts(cursor, rows)
            return {"success": True, "data": data}
        except Exception:
            return {"success": True, "message": "Dropped (no resultset returned)"}
    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        try:
            cursor.close()
        except Exception:
            pass
        try:
            conn.close()
        except Exception:
            pass


def main():
    uvicorn.run(app, host="0.0.0.0", port=8000)


if __name__ == "__main__":
    main()
