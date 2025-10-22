from fastapi import FastAPI, HTTPException
import uvicorn
import pyodbc

# This file is for database connection function used by other modules like course_recommender_apis.py
# What it does? 
# it establishes and returns a connection to the SQL Server database using pyodbc.

# Database connection parameters
DB_SERVER = 'localhost'
DB_DATABASE = 'Homework3Group1'
DB_DRIVER = '{ODBC Driver 17 for SQL Server}'


def get_db_connection():
    try:
        conn_str = f"DRIVER={DB_DRIVER};SERVER={DB_SERVER};DATABASE={DB_DATABASE};Trusted_Connection=yes;"
        return pyodbc.connect(conn_str)
    except Exception:
        raise HTTPException(status_code=500, detail="Database connection error")


def _rows_to_dicts(cursor, rows):
    if not cursor.description:
        return []
    cols = [c[0] for c in cursor.description]
    return [dict(zip(cols, row)) for row in rows]

