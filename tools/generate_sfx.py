"""Generate short procedural SFX WAVs for Unbox Fighters."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "assets" / "audio" / "sfx"
SR = 44100


def write_wav(name: str, samples: list[float]) -> None:
	OUT.mkdir(parents=True, exist_ok=True)
	path = OUT / name
	peak = max(1e-9, max(abs(s) for s in samples))
	gain = min(0.95, 0.85 / peak) if peak > 0.85 else 1.0
	with wave.open(str(path), "w") as w:
		w.setnchannels(1)
		w.setsampwidth(2)
		w.setframerate(SR)
		frames = bytearray()
		for s in samples:
			v = max(-1.0, min(1.0, s * gain))
			frames += struct.pack("<h", int(v * 32767.0))
		w.writeframes(frames)
	print(f"wrote {path.name} ({len(samples) / SR:.3f}s)")


def env(t: float, attack: float, hold: float, release: float, total: float) -> float:
	if t < attack:
		return t / max(attack, 1e-6)
	if t < attack + hold:
		return 1.0
	if t < total:
		return max(0.0, 1.0 - (t - attack - hold) / max(release, 1e-6))
	return 0.0


def tone(
	freq: float,
	dur: float,
	vol: float = 0.5,
	attack: float = 0.005,
	release: float | None = None,
	kind: str = "sin",
) -> list[float]:
	if release is None:
		release = max(0.02, dur * 0.35)
	hold = max(0.0, dur - attack - release)
	n = int(SR * dur)
	out: list[float] = []
	phase = 0.0
	for i in range(n):
		t = i / SR
		a = env(t, attack, hold, release, dur)
		phase += 2.0 * math.pi * freq / SR
		if kind == "sin":
			s = math.sin(phase)
		elif kind == "tri":
			s = 2.0 * abs(2.0 * ((phase / (2.0 * math.pi)) % 1.0) - 1.0) - 1.0
		else:
			s = 1.0 if (phase % (2.0 * math.pi)) < math.pi else -1.0
		out.append(s * a * vol)
	return out


def noise_burst(
	dur: float,
	vol: float = 0.4,
	attack: float = 0.001,
	release: float | None = None,
	band: str | None = None,
) -> list[float]:
	if release is None:
		release = dur * 0.6
	hold = max(0.0, dur - attack - release)
	n = int(SR * dur)
	out: list[float] = []
	state = 0.0
	for i in range(n):
		t = i / SR
		a = env(t, attack, hold, release, dur)
		x = (i * 1103515245 + 12345) & 0x7FFFFFFF
		nse = (x / 0x7FFFFFFF) * 2.0 - 1.0
		if band == "low":
			state = state * 0.92 + nse * 0.08
			s = state
		elif band == "high":
			prev = state
			state = nse
			s = nse - prev * 0.3
		else:
			s = nse
		out.append(s * a * vol)
	return out


def mix(*tracks: list[float]) -> list[float]:
	length = max(len(t) for t in tracks)
	out = [0.0] * length
	for tr in tracks:
		for i, v in enumerate(tr):
			out[i] += v
	return out


def delay(samples: list[float], seconds: float) -> list[float]:
	return [0.0] * int(SR * seconds) + samples


def main() -> None:
	hammer = mix(
		noise_burst(0.06, vol=0.55, attack=0.001, release=0.05, band="low"),
		tone(90, 0.09, vol=0.45, attack=0.001, release=0.07),
		tone(180, 0.05, vol=0.2, attack=0.001, release=0.04, kind="tri"),
		noise_burst(0.03, vol=0.25, attack=0.0005, release=0.025, band="high"),
	)
	write_wav("hammer_hit.wav", hammer)

	crack = mix(
		noise_burst(0.08, vol=0.5, attack=0.0008, release=0.07, band="high"),
		tone(140, 0.07, vol=0.3, attack=0.001, release=0.05),
		tone(320, 0.04, vol=0.15, attack=0.001, release=0.03, kind="tri"),
	)
	write_wav("crate_crack.wav", crack)

	break_sfx = mix(
		noise_burst(0.18, vol=0.65, attack=0.001, release=0.15, band="low"),
		noise_burst(0.12, vol=0.35, attack=0.002, release=0.1, band="high"),
		tone(70, 0.16, vol=0.4, attack=0.001, release=0.12),
		tone(110, 0.1, vol=0.25, attack=0.001, release=0.08),
		delay(noise_burst(0.08, vol=0.2, band="high"), 0.04),
	)
	write_wav("crate_break.wav", break_sfx)

	pickup = mix(
		tone(520, 0.07, vol=0.18, attack=0.002, release=0.05),
		tone(780, 0.06, vol=0.12, attack=0.002, release=0.045, kind="tri"),
		noise_burst(0.05, vol=0.12, attack=0.001, release=0.04, band="high"),
	)
	write_wav("part_pickup.wav", pickup)

	place = mix(
		tone(240, 0.08, vol=0.28, attack=0.001, release=0.06),
		tone(480, 0.07, vol=0.22, attack=0.001, release=0.05, kind="tri"),
		tone(720, 0.05, vol=0.12, attack=0.001, release=0.04),
		noise_burst(0.025, vol=0.18, attack=0.0005, release=0.02, band="high"),
	)
	write_wav("part_place.wav", place)

	reject = mix(
		tone(160, 0.1, vol=0.22, attack=0.002, release=0.08),
		tone(120, 0.12, vol=0.18, attack=0.002, release=0.1),
		noise_burst(0.06, vol=0.12, attack=0.002, release=0.05, band="low"),
	)
	write_wav("part_reject.wav", reject)

	complete = mix(
		tone(523.25, 0.12, vol=0.22, attack=0.004, release=0.08),
		delay(tone(659.25, 0.12, vol=0.2, attack=0.004, release=0.08), 0.07),
		delay(tone(783.99, 0.18, vol=0.22, attack=0.004, release=0.12), 0.14),
		delay(tone(1046.5, 0.2, vol=0.16, attack=0.004, release=0.14), 0.2),
	)
	write_wav("fighter_complete.wav", complete)
	print("done")


if __name__ == "__main__":
	main()
