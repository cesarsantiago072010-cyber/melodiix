from fastapi import APIRouter
from services.lyrics_service import fetch_lyrics

router = APIRouter()


@router.get("/")
async def get_lyrics(artist: str, title: str, duration: int = 0):
    return await fetch_lyrics(artist, title, duration)
