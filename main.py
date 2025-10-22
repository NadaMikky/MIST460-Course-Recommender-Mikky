from fastapi import FastAPI
from web_apis.validate_user import router as validate_router
from web_apis.find_current_semester_course_offering import router as current_offering_router
from web_apis.find_prerequisites import router as prereq_router
from web_apis.check_prereqs import router as check_prereq_router
from web_apis.enroll_student import router as enroll_router
from web_apis.get_student_enrolled_course_offerings import router as get_enroll_router
from web_apis.drop_student import router as drop_router

app = FastAPI(title="Course Recommender API")
# include routers (each defines a small group of routes)
app.include_router(validate_router)
app.include_router(current_offering_router)
app.include_router(prereq_router)
app.include_router(check_prereq_router)
app.include_router(enroll_router)
app.include_router(get_enroll_router)
app.include_router(drop_router)

@app.get("/", tags=["root"])
def read_root():
    return {"message": "Course Recommender API is running"}
