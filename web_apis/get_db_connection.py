#get_db_connection.py : this file is for database connection function used by other modules like course_recommender_apis.py
from fastapi import FastAPI, HTTPException
import uvicorn
import pyodbc
import os
from dotenv import load_dotenv
from pathlib import Path

#load environment variables from .env file 
path = Path(__file__).parent / '.env'
load_dotenv(dotenv_path=path)

# This file is for database connection function used by other modules like course_recommender_apis.py
# What it does? 
# it establishes and returns a connection to the SQL Server database using pyodbc.


def get_db_connection():
    environment = os.getenv("ENVIRONMENT", "development")

    if environment == "production":
        # Azure SQL settings
        DB_SERVER = os.getenv("DB_SERVER")       # e.g. your-server.database.windows.net
        DB_DATABASE = os.getenv("DB_NAME")       # Course_Recommender_MikkyDB
        DB_USERNAME = os.getenv("DB_USERNAME")
        DB_PASSWORD = os.getenv("DB_PASSWORD")
        DB_DRIVER = os.getenv("DB_DRIVER", "{ODBC Driver 18 for SQL Server}")

        connection_string = (
            f"DRIVER={DB_DRIVER};"
            f"SERVER={DB_SERVER};"
            f"DATABASE={DB_DATABASE};"
            f"UID={DB_USERNAME};"
            f"PWD={DB_PASSWORD};"
            "Encrypt=yes;"
            "TrustServerCertificate=no;"
            "Connection Timeout=30;"
        )
    else:
        # Local SQL Server settings
        DB_SERVER = "localhost"
        DB_DATABASE = "Homework3Group1"
        DB_DRIVER = "{ODBC Driver 17 for SQL Server}"

        connection_string = (
            f"DRIVER={DB_DRIVER};"
            f"SERVER={DB_SERVER};"
            f"DATABASE={DB_DATABASE};"
            "Trusted_Connection=yes;"
            "Connection Timeout=30;"
        )

    try:
        return pyodbc.connect(connection_string)
    except Exception:
        raise HTTPException(status_code=500, detail="Database connection error")

def _rows_to_dicts(cursor, rows):
    if not cursor.description:
        return []
    cols = [c[0] for c in cursor.description]
    return [dict(zip(cols, row)) for row in rows]
