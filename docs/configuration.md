# Configuration

There is no config file — every adjustable value lives at the top of one of the `.bat` scripts. This page lists every variable, what it controls, and where to change it.

## Path variables

### VR scripts (`VR2Normal.bat`, `only_vr.bat`)

```bat
set "INPUT_DIR=C:\Users\%USERNAME%\Desktop\transcodeVR\vr"
set "OUTPUT_DIR=C:\Users\%USERNAME%\Desktop\transcodeVR\nonevr"
set "FFMPEG_PATH=C:\Users\mtx\Desktop\desk\ffmpeg-master-latest-win64-gpl-shared\bin\ffmpeg.exe"
set "TEMP_DIR=C:\Users\%USERNAME%\Desktop\transcodeVR\temp"   :: VR2Normal only
```

| Variable | Purpose |
|---|---|
| `INPUT_DIR` | Root containing scene subfolders with VR clips |
| `OUTPUT_DIR` | Root where converted (and optionally merged) MKVs are written |
| `FFMPEG_PATH` | Absolute path to `ffmpeg.exe`. Quoted in invocations |
| `TEMP_DIR` | Workspace for concat list files (deleted on success) |

`%USERNAME%` is the current Windows user; use that to keep paths portable across machines. `FFMPEG_PATH` is hardcoded to one user's path — change it on every machine you run from.

### 1080p script (`only_1080p.bat`)

```bat
set "INPUT_FOLDER=C:\Users\%USERNAME%\Desktop\transcodeVR\input"
set "OUTPUT_FOLDER=C:\Users\%USERNAME%\Desktop\transcodeVR\output"
```

This script does not have an `FFMPEG_PATH`; it calls `ffmpeg` directly from the shell, so `ffmpeg.exe` must be on `PATH` for it to work.

## VR encoder settings

These appear inline in the FFmpeg command in `VR2Normal.bat` and `only_vr.bat`. To change them, edit the single long FFmpeg line.

| Setting | Default | Notes |
|---|---|---|
| Decode accel | `-hwaccel cuda` | NVIDIA CUDA decode |
| Video codec | `libx264` | Software x264 encode |
| Preset | `medium` | Speed/quality tradeoff |
| Quality | `-crf 24` | Lower = better quality, larger file |
| Tune | `film` | x264 tuning for live-action content |
| GOP / B-frames | `keyint=600:bframes=7` | ~10 s GOP at 60 fps; deep B-frames |
| Audio codec | `libopus` | |
| Audio bitrate | `128K` | |
| Output resolution | `2560x1440` | Set in the `v360` filter (`w=2560:h=1440`) |
| Container | `.mkv` | Hardcoded in the output filename |

## VR projection settings

The `v360` filter parameters control the framing of the output. See [ffmpeg-pipeline.md](ffmpeg-pipeline.md) for what each one does.

| Parameter | Default | Effect |
|---|---|---|
| `crop=w=iw/2:h=ih:x=0:y=0` | left half | Selects which eye is used (`x=0` = left, `x=iw/2` = right) |
| `iv_fov` / `ih_fov` | 180 / 180 | Source FOV (vertical / horizontal). `180/180` = full hemisphere |
| `d_fov` | 115 | Output diagonal FOV — smaller = more zoomed in |
| `pitch` | -35 | Tilt down 35°; raise toward 0 to look more level |
| `yaw` / `roll` | 0 / 0 | Pan / roll |
| `interp` | `lanczos` | Resampling filter |
| `reset_rot` | 1 | Resets pre-rotation metadata before reprojection |

## 1080p encoder settings

In `only_1080p.bat`:

```bat
set "GPU_ENCODER=h264_nvenc"
set "GPU_PRESET=p4"
set "GPU_CRF=23"
set "FILTER=scale=1920:1080"
```

| Variable | Purpose |
|---|---|
| `GPU_ENCODER` | NVENC encoder name (`h264_nvenc`, `hevc_nvenc`, etc.) |
| `GPU_PRESET` | NVENC preset (`p1` fastest – `p7` slowest/best) |
| `GPU_CRF` | Despite the name, this is passed as `-cq` (NVENC quality target) |
| `FILTER` | Single `-vf` filter chain. Default downscales to 1080p |

Audio is hardcoded to `-c:a copy` (stream-copied, no re-encode).

## Changing things safely

- Quote all paths. Spaces in `INPUT_DIR` / `OUTPUT_DIR` will break the script if unquoted.
- Don't add `/` separators on Windows — stick with `\`.
- The VR encoder line is long. Edit one parameter at a time and rerun on a single short clip to confirm.
- Keep `set "X=value"` syntax; the surrounding double quotes prevent trailing-space bugs.
