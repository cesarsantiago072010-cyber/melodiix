from ytmusicapi import YTMusic
import asyncio

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
        def _extract():
            try:
                from pytubefix import YouTube
                yt_video = YouTube(f"https://www.youtube.com/watch?v={video_id}")
                stream = yt_video.streams.filter(only_audio=True).first()
                url = stream.url
                print(f"[PYTUBE] Got URL: {url[:80]}")
                return url
            except Exception as e:
                print(f"[PYTUBE] Error: {e}")
                return ""

        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(None, _extract)

    async def get_related(self, track_id: str) -> dict:
        try:
            related = yt.get_watch_playlist(videoId=track_id, limit=10)
            tracks  = related.get("tracks", [])
            return {"tracks": [self._format_track(t) for t in tracks
                               if t.get("videoId")]}
        except Exception:
            return {"tracks": []}
