"""Baixa efeitos sonoros gravados (Mixkit, licença gratuita) e grava WAV no jogo.

Substitui os bipes antigos gerados por seno/ruído.

  python tools/fetch_sfx.py
  python tools/fetch_sfx.py impact

Precisa: pip install miniaudio numpy
"""
from __future__ import annotations

import sys
import tempfile
import urllib.request
import wave
from pathlib import Path

import miniaudio
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "audio" / "sfx"
CACHE = Path(tempfile.gettempdir()) / "unbox-fighters-sfx-cache"
SR_OUT = 44100
PEAK_DB = -1.5

# Mixkit preview IDs. Licença: Mixkit Sound Effects Free License (uso no jogo ok).
JOBS: dict[str, dict] = {
	"hammer_hit": {"id": 833, "fade_out": 0.06},
	"crate_crack": {"id": 2182, "fade_out": 0.05},
	"crate_break": {"id": 3141, "end": 1.15, "fade_out": 0.12},
	"part_pickup": {"id": 3005, "fade_out": 0.04},
	"part_place": {"id": 2858, "end": 0.52, "fade_out": 0.08},
	"part_reject": {"id": 2569, "end": 0.55, "fade_out": 0.08},
	"fighter_complete": {"id": 2865, "fade_out": 0.1},
	"impact": {"id": 2143, "fade_out": 0.08},
	"step": {"id": 542, "start": 0.15, "end": 0.40, "fade_in": 0.008, "fade_out": 0.07},
}


def _opener() -> None:
	opener = urllib.request.build_opener()
	opener.addheaders = [
		("User-Agent", "Mozilla/5.0"),
		("Referer", "https://mixkit.co/"),
	]
	urllib.request.install_opener(opener)


def _download(sid: int) -> Path:
	CACHE.mkdir(parents=True, exist_ok=True)
	dest = CACHE / f"{sid}.mp3"
	if dest.exists() and dest.stat().st_size > 1000:
		return dest
	url = f"https://assets.mixkit.co/active_storage/sfx/{sid}/{sid}-preview.mp3"
	urllib.request.urlretrieve(url, dest)
	return dest


def _decode_stereo(path: Path) -> tuple[np.ndarray, int]:
	decoded = miniaudio.decode_file(str(path))
	sr = int(decoded.sample_rate)
	ch = max(1, int(decoded.nchannels))
	raw = np.asarray(decoded.samples, dtype=np.float32)
	peak = float(np.max(np.abs(raw))) if raw.size else 0.0
	if peak > 1.5:
		raw = raw / 32768.0
	if ch == 1:
		mono = raw.reshape(-1)
		x = np.stack([mono, mono], axis=1)
	else:
		x = raw.reshape(-1, ch)[:, :2]
	return x, sr


def _resample(x: np.ndarray, sr: int, target: int) -> np.ndarray:
	if sr == target:
		return x
	n_src = x.shape[0]
	n_dst = max(1, int(round(n_src * target / sr)))
	t_src = np.linspace(0.0, 1.0, n_src, endpoint=False)
	t_dst = np.linspace(0.0, 1.0, n_dst, endpoint=False)
	out = np.empty((n_dst, x.shape[1]), dtype=np.float32)
	for c in range(x.shape[1]):
		out[:, c] = np.interp(t_dst, t_src, x[:, c])
	return out


def _slice(x: np.ndarray, sr: int, start: float | None, end: float | None) -> np.ndarray:
	a = 0 if start is None else max(0, int(start * sr))
	b = x.shape[0] if end is None else min(x.shape[0], int(end * sr))
	return x[a:b]


def _fade(x: np.ndarray, sr: int, fade_in: float, fade_out: float) -> np.ndarray:
	n = x.shape[0]
	if n == 0:
		return x
	out = x.copy()
	fi = min(n, int(fade_in * sr))
	fo = min(n, int(fade_out * sr))
	if fi > 1:
		out[:fi] *= np.linspace(0.0, 1.0, fi, dtype=np.float32)[:, None]
	if fo > 1:
		out[-fo:] *= np.linspace(1.0, 0.0, fo, dtype=np.float32)[:, None]
	return out


def _normalize(x: np.ndarray, peak_db: float) -> np.ndarray:
	peak = float(np.max(np.abs(x))) if x.size else 0.0
	if peak < 1e-6:
		return x
	target = float(10.0 ** (peak_db / 20.0))
	return x * (target / peak)


def _write_wav(path: Path, x: np.ndarray, sr: int) -> None:
	pcm = np.clip(x, -1.0, 1.0)
	frames = (pcm * 32767.0).astype(np.int16)
	with wave.open(str(path), "w") as w:
		w.setnchannels(2)
		w.setsampwidth(2)
		w.setframerate(sr)
		w.writeframes(frames.tobytes())


def main() -> None:
	_opener()
	OUT.mkdir(parents=True, exist_ok=True)
	wanted = set(sys.argv[1:])
	for name, job in JOBS.items():
		if wanted and name not in wanted:
			continue
		src = _download(int(job["id"]))
		x, sr = _decode_stereo(src)
		x = _resample(x, sr, SR_OUT)
		x = _slice(x, SR_OUT, job.get("start"), job.get("end"))
		x = _fade(x, SR_OUT, float(job.get("fade_in", 0.003)), float(job.get("fade_out", 0.06)))
		x = _normalize(x, PEAK_DB)
		dest = OUT / f"{name}.wav"
		_write_wav(dest, x, SR_OUT)
		print(f"wrote {dest.name} ({x.shape[0] / SR_OUT:.2f}s)")
	print("done")


if __name__ == "__main__":
	main()
