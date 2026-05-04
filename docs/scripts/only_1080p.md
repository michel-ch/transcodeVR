# `only_1080p.bat`

NVENC-based 1080p downscale. Standalone — does **not** share folders or settings with the VR scripts.

## What it does

For every subfolder of `input/`:

1. Walks the folder for `*.MP4` files.
2. Downscales each one to 1920×1080 with `h264_nvenc`.
3. Writes the result as `output/<folder>/<name>_1080p.MP4`. Audio is stream-copied (no re-encode).

## Variables

```bat
set "INPUT_FOLDER=C:\Users\%USERNAME%\Desktop\transcodeVR\input"
set "OUTPUT_FOLDER=C:\Users\%USERNAME%\Desktop\transcodeVR\output"

set "GPU_ENCODER=h264_nvenc"
set "GPU_PRESET=p4"
set "GPU_CRF=23"

set "FILTER=scale=1920:1080"
```

Note that `INPUT_FOLDER` / `OUTPUT_FOLDER` are different from the VR scripts' `INPUT_DIR` / `OUTPUT_DIR`, both in name and in default path (`input/` / `output/` rather than `vr/` / `nonevr/`).

There is no `FFMPEG_PATH` variable — the script invokes `ffmpeg` directly, so `ffmpeg.exe` must be on your system `PATH`.

## FFmpeg command

```
ffmpeg -y !THREADS! -i <input>
       -vf "scale=1920:1080"
       -c:v h264_nvenc -preset p4 -cq 23
       -c:a copy
       <output>_1080p.MP4
```

| Flag | Meaning |
|---|---|
| `-y` | Overwrite output without asking |
| `!THREADS!` | Undefined variable — expands to nothing. Harmless but dead code. |
| `-vf scale=1920:1080` | Force resolution to 1920×1080. Stretches non-16:9 sources. |
| `-c:v h264_nvenc` | Hardware H.264 encoder on NVIDIA GPUs |
| `-preset p4` | Mid-range NVENC preset (`p1` fastest – `p7` slowest/best) |
| `-cq 23` | NVENC constant-quality target. Lower = better quality, larger files |
| `-c:a copy` | Pass audio through without re-encoding |

## Output naming

| Input | Output |
|---|---|
| `input/scene_a/clip01.MP4` | `output/scene_a/clip01_1080p.MP4` |
| `input/scene_a/clip02.MP4` | `output/scene_a/clip02_1080p.MP4` |

The `_1080p` suffix is added before the extension, and the `.MP4` extension is preserved (matching the input).

## Differences from the VR scripts

| | VR scripts | `only_1080p.bat` |
|---|---|---|
| Input root | `vr/` | `input/` |
| Output root | `nonevr/` | `output/` |
| Source extensions | `*.mp4 *.mkv *.avi *.mov` | `*.MP4` only |
| FFmpeg path | `FFMPEG_PATH` (configurable) | `ffmpeg` from `PATH` |
| Encoder | `libx264` (CPU) | `h264_nvenc` (GPU) |
| Output container | `.mkv` | `.MP4` (preserved from input) |
| Audio | re-encoded with Opus | stream-copied |
| Per-folder merge | yes (in `VR2Normal.bat` only) | no |

## Caveats

- **`*.MP4` glob** — the script's `for %%f in ("%%d\*.MP4")` line is technically case-insensitive on NTFS, so lowercase `.mp4` files will match. But if you ever run this from a case-sensitive filesystem, only uppercase will be picked up. Safer to keep filenames in uppercase or to add a second `for` line for `*.mp4`.
- **Stretching** — `scale=1920:1080` does not preserve aspect ratio. For mixed-source folders, change the filter to `scale=-2:1080` (height-locked, width auto-rounded to even) or `scale=1920:-2`.
- **Audio passthrough** — if the source has audio in a codec the MP4 container can't hold (rare for typical phone/camera footage), you'll need to add `-c:a aac -b:a 192K` or similar.
- **NVENC quality** — `-cq 23` is roughly visually equivalent to `libx264 -crf 23` but NVENC is generally less efficient bit-for-bit. If file size matters, raise `-cq` or use `-preset p7`.

## Related

- [../configuration.md](../configuration.md)
- [../ffmpeg-pipeline.md](../ffmpeg-pipeline.md)
- [../troubleshooting.md](../troubleshooting.md)
