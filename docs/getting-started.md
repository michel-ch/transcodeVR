# Getting started

This page covers requirements, installation, and a first end-to-end run.

## Requirements

### Operating system
Windows. The scripts are CMD batch files (`.bat`) and use `setlocal enabledelayedexpansion`, the `for /d` loop, and Windows-style paths.

### FFmpeg
You need an FFmpeg build that includes:

- `libx264` — used by the VR scripts for video encoding
- `libopus` — used by the VR scripts for audio encoding
- NVENC (`h264_nvenc`) — used by `only_1080p.bat`
- The `v360` filter — used by the VR scripts to reproject the 180° hemisphere
- CUDA decode (`-hwaccel cuda`) — used by the VR scripts

A `ffmpeg-master-latest-win64-gpl-shared` build from the official Windows builds includes all of the above. The default path baked into the scripts is:

```
C:\Users\mtx\Desktop\desk\ffmpeg-master-latest-win64-gpl-shared\bin\ffmpeg.exe
```

If your FFmpeg lives elsewhere, see [configuration.md](configuration.md).

### GPU
An NVIDIA GPU with current drivers. The VR scripts use CUDA only for decode (encode stays on x264), and the 1080p script uses NVENC for encode.

## Installation

1. Place the `transcodeVR` folder at `C:\Users\<USERNAME>\Desktop\transcodeVR`. (Other locations work, but you'll need to edit `INPUT_DIR` / `OUTPUT_DIR` in each script — see [configuration.md](configuration.md).)
2. Make sure `ffmpeg.exe` is at the path above, or update `FFMPEG_PATH` in `VR2Normal.bat` and `only_vr.bat`.

## First run (VR conversion)

1. Create a subfolder under `vr/`, e.g. `vr/scene_a/`.
2. Drop your VR clips into it (`.mp4`, `.mkv`, `.avi`, or `.mov`).
3. Double-click `VR2Normal.bat`, or run it from CMD:
   ```cmd
   VR2Normal.bat
   ```
4. The script:
   - Creates `nonevr/scene_a/` if missing
   - Converts each clip to a flat 2D `.mkv` inside `nonevr/scene_a/`
   - Concatenates those `.mkv` files (alphabetically) into `nonevr/scene_a.mkv` if there is more than one
   - Cleans up `temp/` at the end
5. A summary is printed showing how many files were converted, how many errored, and how many folders were merged.

If you want each clip kept separate (no merge), use `only_vr.bat` instead.

## First run (1080p downscale)

1. Create `input/<scene>/` and drop `.MP4` files into it.
2. Run `only_1080p.bat`.
3. Output appears at `output/<scene>/<name>_1080p.MP4`.

## Verifying it worked

Open one of the produced `.mkv` files in any player (VLC, mpv, MPC-HC). For the VR conversion the content should appear as a normal flat 2D image, framed roughly the way the camera was tilted (the default is a 35° downward tilt — see [ffmpeg-pipeline.md](ffmpeg-pipeline.md) if you need to change that).
