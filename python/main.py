from fastapi import FastAPI
import uvicorn

app = FastAPI(
    title="STEP SEOUL API",
    version="1.0.0",
)


@app.get("/")
def root():
    return {
        "status": "success",
        "message": "STEP SEOUL API가 실행 중입니다.",
    }


@app.get("/health")
def health_check():
    return {
        "status": "healthy",
    }


if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="192.168.10.40",
        port=8000,
        reload=True,
    )