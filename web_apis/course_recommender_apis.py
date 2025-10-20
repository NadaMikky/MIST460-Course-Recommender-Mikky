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


def main():
    uvicorn.run(app, host="0.0.0.0", port=8000)


if __name__ == "__main__":
    main()
