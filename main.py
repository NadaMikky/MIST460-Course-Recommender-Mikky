from fastapi import FastAPI
# reuse the app you already defined in the course_recommender_apis module
from web_apis.course_recommender_apis import app as app  # re-export as main.app

# add a lightweight root endpoint
@app.get("/", tags=["root"])
def read_root():
    return {"message": "Course Recommender API (main) is running"}

def main():
    print("Hello Nada, from mist460-course-recommender-mikky!")


if __name__ == "__main__":
    main()
