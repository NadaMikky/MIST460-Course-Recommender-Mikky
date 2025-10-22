import pyodbc
from fastapi import HTTPException
from typing import List, Dict, Any

# This file contains common database utility functions 
# used by other modules like course_recommender_apis.py.
# Database connection parameters
DB_SERVER = 'localhost'
DB_DATABASE = 'Homework3Group1'
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
        raise HTTPException(status_code=500, detail="Database connection error")

def _rows_to_dicts(cursor, rows) -> List[Dict[str, Any]]:
    cols = [c[0] for c in cursor.description] if cursor.description else []
    result = []
    for row in rows:
        row_dict = {}
        for idx, col in enumerate(cols):
            row_dict[col] = row[idx]
        result.append(row_dict)
    return result
