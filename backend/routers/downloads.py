from fastapi import APIRouter, BackgroundTasks
from pathlib import Path
import yt_dlp

router        = APIRouter()
DOWNLOADS_DIR = Path("./downloads")
DOWNLOADS_DIR.mkdir(exist_ok=True)
download_status: dict[str, dict] = {}


@router.post("/{video_id}")
async def start_download(video_id: str, background_tasks: BackgroundTasks):
    if video_id in download_status and \
       download_status[video_id]["status"] not in ("error",):
        return download_status[video_id]
    download_status[video_id] = {"status": "queued", "progress": 0}
    background_tasks.add_task(_download_audio, video_id)
    return {"status": "queued", "video_id": video_id}


@router.get("/{video_id}/status")
async def get_status(video_id: str):
    return download_status.get(video_id, {"status": "not_found"})


@router.delete("/{video_id}")
async def delete_download(video_id: str):
    path = DOWNLOADS_DIR / f"{video_id}.m4a"
    if path.exists():
        path.unlink()
    download_status.pop(video_id, None)
    return {"deleted": True}


@router.get("/file/{video_id}")
async def get_file_path(video_id: str):
    path = DOWNLOADS_DIR / f"{video_id}.m4a"
    return {"path": str(path) if path.exists() else None,
            "exists": path.exists()}


def _download_audio(video_id: str):
    out_path = str(DOWNLOADS_DIR / f"{video_id}.%(ext)s")

    def progress_hook(d):
        if d["status"] == "downloading":
            downloaded = d.get("downloaded_bytes", 0)
            total      = d.get("total_bytes") or \
                         d.get("total_bytes_estimate", 1)
            download_status[video_id] = {
                "status":   "downloading",
                "progress": int((downloaded / total) * 100),
            }
        elif d["status"] == "finished":
            download_status[video_id] = {"status": "complete", "progress": 100}

    ydl_opts = {
        "format":      "bestaudio[ext=m4a]/bestaudio/best",
        "outtmpl":     out_path,
        "quiet":       True,
        "progress_hooks": [progress_hook],
        "postprocessors": [{
            "key":            "FFmpegExtractAudio",
            "preferredcodec": "m4a",
        }],
    }
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            ydl.download(
                [f"https://www.youtube.com/watch?v={video_id}"])
    except Exception as e:
        download_status[video_id] = {"status": "error", "message": str(e)}
