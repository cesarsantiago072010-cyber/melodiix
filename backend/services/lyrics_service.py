import httpx

LRCLIB_BASE = "https://lrclib.net/api"


async def fetch_lyrics(artist: str, title: str, duration: int = 0) -> dict:
    async with httpx.AsyncClient() as client:
        resp = await client.get(
            f"{LRCLIB_BASE}/get",
            params={
                "artist_name": artist,
                "track_name":  title,
                "duration":    duration,
            },
            timeout=10,
        )
    if resp.status_code == 200:
        data = resp.json()
        return {
            "plain":  data.get("plainLyrics"),
            "synced": data.get("syncedLyrics"),
        }
    return {"plain": None, "synced": None}
