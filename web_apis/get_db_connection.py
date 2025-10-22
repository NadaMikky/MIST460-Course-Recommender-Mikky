from fastapi import FastAPI, HTTPException
import uvicorn
import pyodbc

# This file is for database connection function used by other modules like course_recommender_apis.py
# What it does? 
# it establishes and returns a connection to the SQL Server database using pyodbc.

# Database connection parameters
DB_SERVER = 'localhost'
DB_DATABASE = 'Homework3Group1'
DB_USERNAME = 'your_username' #not needed
DB_PASSWORD = 'your_password' # not needed 
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

