from fastapi import APIRouter, HTTPException
from services.music_source import MusicSourceAdapter

router = APIRouter()
source = MusicSourceAdapter()


@router.get("/{video_id}")
async def get_stream_url(video_id: str):
    url = await source.get_stream_url(video_id)
    if not url:
        raise HTTPException(status_code=404, detail="Stream no disponible")
    return {"url": url}
