from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import search, stream, lyrics, downloads, related

app = FastAPI(title="Melodix API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(search.router,    prefix="/search",    tags=["search"])
app.include_router(stream.router,    prefix="/stream",    tags=["stream"])
app.include_router(lyrics.router,    prefix="/lyrics",    tags=["lyrics"])
app.include_router(downloads.router, prefix="/downloads", tags=["downloads"])
app.include_router(related.router, prefix="/related",   tags=["related"])