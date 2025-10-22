from fastapi import APIRouter, Query, HTTPException
from web_apis.course_recommender_apis import get_db_connection, _rows_to_dicts

router = APIRouter()

# 3. find_prerequisites
@router.get("/find_prerequisites")
def find_prerequisites(subject_code: str = Query(...), course_number: str = Query(...)):
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("EXEC dbo.procFindPrerequisites ?, ?", (subject_code, course_number))
        rows = cur.fetchall()
        return {"data": _rows_to_dicts(cur, rows)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cur.close()
        conn.close()
