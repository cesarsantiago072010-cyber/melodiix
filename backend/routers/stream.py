from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from services.music_source import MusicSourceAdapter
import httpx

router = APIRouter()
source = MusicSourceAdapter()

@router.get("/{video_id}")
async def get_stream_url(video_id: str):
    url = await source.get_stream_url(video_id)
    if not url:
        raise HTTPException(status_code=404, detail="Stream no disponible")

    # Proxy del audio en vez de devolver la URL directa
    async def audio_stream():
        async with httpx.AsyncClient() as client:
            async with client.stream("GET", url) as resp:
                async for chunk in resp.aiter_bytes():
                    yield chunk

    return StreamingResponse(audio_stream(), media_type="audio/webm")
