from ytmusicapi import YTMusic

yt = YTMusic()


class MusicSourceAdapter:

    async def search(self, query: str) -> dict:
        results = yt.search(query, filter="songs", limit=20)
        return {"tracks": [self._format_track(r) for r in results
                           if r.get("videoId")]}

    def _format_track(self, raw: dict) -> dict:  # ← 4 espacios
        vid   = raw.get("videoId", "")
        thumb   = raw.get("thumbnails", [])
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
        import yt_dlp
        ydl_opts = {
            "format":      "bestaudio/best",
            "quiet":       True,
            "no_warnings": True,
            "extractor_args": {
                "youtube": {
                    "player_client": ["tv_embedded"],
                    "player_skip": ["webpage", "configs"]
                }
            },
        }
        try:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(
                    f"https://www.youtube.com/watch?v={video_id}",
                    download=False,
                )
            return info.get("url", "")
        except Exception as e:
            print(f"yt-dlp error: {e}")
            return ""

    async def get_related(self, track_id: str) -> dict:
        try:
            related = yt.get_watch_playlist(videoId=track_id, limit=10)
            tracks  = related.get("tracks", [])
            return {"tracks": [self._format_track(t) for t in tracks
                               if t.get("videoId")]}
        except Exception:
            return {"tracks": []}
