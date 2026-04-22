from fastapi import APIRouter, Query
from services.music_source import MusicSourceAdapter

router = APIRouter()
source = MusicSourceAdapter()


@router.get("/")
async def search_tracks(q: str = Query(..., min_length=1)):
    return await source.search(q)


@router.get("/related")
async def get_related(track_id: str):
    return await source.get_related(track_id)
