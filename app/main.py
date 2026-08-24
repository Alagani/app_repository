from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(title="fastapi-app", version="0.1.0")


class Health(BaseModel):
    status: str


@app.get("/", response_model=Health)
def root() -> Health:
    return Health(status="ok")


@app.get("/healthz", response_model=Health)
def healthz() -> Health:
    """Liveness/readiness probe target for the Kubernetes Deployment."""
    return Health(status="ok")
