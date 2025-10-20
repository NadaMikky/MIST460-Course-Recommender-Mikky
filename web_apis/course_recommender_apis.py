from fastapi import FastAPI, HTTPException
import uvicorn
from typing import List, Dict, Any

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


@app.get("/find_current_semester_course_offerings")
def find_current_semester_course_offerings(
    subject_code: str,
    course_number: str
):
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute(
            "{CALL procFindCurrentSemesterCourseOfferingsForSpecifiedCourse(?, ?)}",
            (subject_code, course_number)
        )
        rows = cursor.fetchall()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cursor.close()
        conn.close()

    # Convert rows to list of dictionaries for better JSON serialization
    results = [
        {
            "SubjectCode": row.SubjectCode,
            "CourseNumber": row.CourseNumber,
            "CRN": row.CRN,
            "Semester": row.Semester,
            "Year": row.Year,
            "CourseOfferingID": row.CourseOfferingID,
            "NumberSeatsRemaining": row.NumberSeatsRemaining
        }
        for row in rows
    ]

    return {"data": results}


def main():
    uvicorn.run(app, host="0.0.0.0", port=8000)


if __name__ == "__main__":
    main()
