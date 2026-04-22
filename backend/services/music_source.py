from ytmusicapi import YTMusic

yt = YTMusic()


class MusicSourceAdapter:

    async def search(self, query: str) -> dict:
        results = yt.search(query, filter="songs", limit=20)
        return {"tracks": [self._format_track(r) for r in results
                           if r.get("videoId")]}

    def _format_track(self, raw: dict) -> dict:
        vid    = raw.get("videoId", "")
        thumb  = raw.get("thumbnails", [])
        if isinstance(thumb, dict):
            thumb = [thumb]
        artists = raw.get("artists") or [{}]
        valid_thumbs = [t for t in thumb if t.get("url", "").startswith("http")]
        thumbnail = valid_thumbs[-1].get("url", "") if valid_thumbs else ""
        return {
            "id":          vid,
            "title":       raw.get("title", ""),
            "artist":      artists[0].get("name", "") if artists else "",
            "album":       raw.get("album", {}).get("name", "") if raw.get("album") else "",
            "duration_ms": (raw.get("duration_seconds") or 0) * 1000,
            "thumbnail":   thumbnail,
            "stream_url":  "",
        }

async def get_stream_url(self, video_id: str) -> str:
    import httpx
    instances = [
        "https://invidious.snopyta.org",
        "https://invidious.kavin.rocks",
        "https://vid.puffyan.us",
    ]
    for instance in instances:
        try:
            async with httpx.AsyncClient() as client:
                resp = await client.get(
                    f"{instance}/api/v1/videos/{video_id}",
                    timeout=10
                )
                data = resp.json()
                formats = data.get("adaptiveFormats", [])
                audio = [f for f in formats if f.get("type", "").startswith("audio")]
                if audio:
                    return audio[0]["url"]
        except Exception:
            continue
    return ""

    async def get_related(self, track_id: str) -> dict:
        try:
            related = yt.get_watch_playlist(videoId=track_id, limit=10)
            tracks  = related.get("tracks", [])
            return {"tracks": [self._format_track(t) for t in tracks
                               if t.get("videoId")]}
        except Exception:
            return {"tracks": []}
