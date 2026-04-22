from fastapi import APIRouter
from services.music_source import MusicSourceAdapter

router = APIRouter()
adapter = MusicSourceAdapter()

@router.get("/{track_id}")
async def get_related(track_id: str):
    return await adapter.get_related(track_id)