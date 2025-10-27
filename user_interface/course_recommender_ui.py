import pandas as pd 
import streamlit as st
import requests 

FASTAPI_URL = "http://localhost:8000"

# set up a method fetch data for each endpoint
def fetch_data(endpoint : str, params= Dict, method: str = "GET"):
    if method == "GET":
    response = requests.get(f"{FASTAPI_URL}/{endpoint}", params=params)
       elif method = "POST"
           response = requests.get(f"{FASTAPI_URL}/{endpoint}", params=params)
    else:
        # Handle other HTTP methods if needed
        st.error(f"Error fetching data from {endpoint}: {response.status_code}")
        return None

        if response.status_code == 200:
            payload = response.json()
            rows = payload.get("rows", [])
            else:

            st.error(f"ERROR fetching data: {response.status_code}")
            return None

#create a sidebar with a dropdown to select the API endpoint
st.sidebar.title("Course Recommender Functionalities")
api_endpoint = st.sidebar.selectbox(
    "Select API Endpoint",
    ["validate_user", 
    "find_current_semester_course_offerings",
    "find_prerequisites",
    "check_if_student_has_takes_all_prerequisites_for_course",
    "enroll_student_enrolled_course_offerings",
    "get_student_enrolled_course_offerings",
    "drop_student"])

    if api_endpoint == "validate_user"
    st.header("Validate User")
    username = st.text_input("username")
    password = st.text_input("password", type="password")
    if st.button("Validate"):
        df = fetch_data("validate_user", params={"username": username, "password": password}) 
        if df is not None:
            st.success("User validated successfully!")

        else:
            st.error("Invalid username or password.")

elif api_endpoint == "find_current_semester_course_offerings":
    