# FFmpeg pipeline

This page walks through the FFmpeg command line used by the VR scripts (`VR2Normal.bat`, `only_vr.bat`) and the simpler one used by `only_1080p.bat`.

## VR pipeline

Full command (one line in the script, broken up here for clarity):

```
ffmpeg
  -hide_banner -loglevel error -stats
  -y
  -hwaccel cuda
  -i <input>
  -map 0:v:0 -map 0:a
  -vf "crop=w=iw/2:h=ih:x=0:y=0,
       v360=hequirect:flat:in_stereo=2d:out_stereo=2d:
            iv_fov=180:ih_fov=180:d_fov=115:
            pitch=-35:yaw=0:roll=0:
            w=2560:h=1440:interp=lanczos:reset_rot=1"
  -c:v libx264 -preset medium -crf 24 -tune film
  -x264-params keyint=600:bframes=7
  -c:a libopus -b:a 128K
  -map_metadata:g -1
  -map_metadata:s:v -1
  -map_metadata:s:a 0:s:a
  -metadata:s "HANDLER_NAME="
  <output>.mkv
```

### Logging flags

- `-hide_banner` — suppresses the FFmpeg version/build splash
- `-loglevel error` — only errors, no warnings or info
- `-stats` — keeps the live "frame=… fps=… time=…" progress line

The combination gives a clean console: progress while the encode runs, plus any errors that abort it.

### Input

- `-y` — overwrite the output file without asking
- `-hwaccel cuda` — decode the input on the GPU (CUDA/NVDEC). Only the decode path is offloaded; encoding stays on the CPU with x264.
- `-i <input>` — the source clip

### Stream selection

- `-map 0:v:0` — first video stream from input #0
- `-map 0:a` — every audio stream from input #0

If your source has multiple video streams (rare), only the first is converted. All audio tracks pass through.

### Filter chain

The chain has two stages, applied in order.

#### `crop=w=iw/2:h=ih:x=0:y=0`

The input is 180° side-by-side stereoscopic: the left eye occupies the left half, the right eye the right half. This filter takes the left half and discards the right.

- `iw/2` — half the input width
- `ih` — full input height
- `x=0,y=0` — start from the top-left corner

To use the right eye instead, change `x=0` to `x=iw/2`.

#### `v360=hequirect:flat:...`

This is the projection step. It treats the cropped image as a 180° hemispherical equirectangular projection (the `hequirect` input format) and re-renders it as a flat rectilinear ("normal camera") view.

| Parameter | Value | Meaning |
|---|---|---|
| input format | `hequirect` | Half-equirectangular (180° hemisphere) |
| output format | `flat` | Rectilinear / pinhole camera |
| `in_stereo` | `2d` | Treat input as monoscopic from this point on (we already cropped to one eye) |
| `out_stereo` | `2d` | Output is monoscopic |
| `iv_fov` / `ih_fov` | 180 / 180 | Source vertical / horizontal FOV |
| `d_fov` | 115 | Output **diagonal** FOV. Smaller = more zoomed in. 115° gives an ultra-wide-but-not-fisheye look |
| `pitch` | -35 | Tilt the virtual camera **down** 35°. Useful when the VR rig was head-mounted and looking at a subject below |
| `yaw` / `roll` | 0 / 0 | No pan, no tilt |
| `w` / `h` | 2560 / 1440 | Output resolution (1440p) |
| `interp` | `lanczos` | Lanczos resampling for the reprojection |
| `reset_rot` | 1 | Discards any pre-existing rotation metadata before reprojecting |

If you change `d_fov`, `pitch`, or `yaw`, do a test render first on a short clip — the reprojection is non-linear and small numeric changes can have surprising effects near the edges of the frame.

### Video encoding

- `-c:v libx264` — software x264 encoder
- `-preset medium` — balanced speed/quality
- `-crf 24` — quality target. Lower numbers = better quality and larger files. 23–24 is a typical "visually transparent" range for x264
- `-tune film` — x264 psychovisual tuning for live-action content (slightly more aggressive deblocking, less dark-area dithering)
- `-x264-params keyint=600:bframes=7`
  - `keyint=600` — one keyframe every 600 frames (~10 s at 60 fps, ~20 s at 30 fps). Good for archival; bad for seeking-heavy use cases
  - `bframes=7` — up to 7 B-frames between references. Improves compression at the cost of encoder/decoder complexity

### Audio encoding

- `-c:a libopus` — Opus codec, generally the best quality-per-bit at moderate bitrates
- `-b:a 128K` — 128 kbps target. Suitable for stereo and most surround content

### Metadata stripping

The three `-map_metadata` flags and the `-metadata:s` flag remove identifying / quirky metadata that VR cameras and editing tools tend to leave behind:

- `-map_metadata:g -1` — drop all global metadata
- `-map_metadata:s:v -1` — drop all per-stream video metadata
- `-map_metadata:s:a 0:s:a` — keep audio stream metadata from input
- `-metadata:s "HANDLER_NAME="` — blank out the `HANDLER_NAME` tag (sometimes shows up as "GoPro AVC" / "VideoHandler" in players)

### Output

`<output>.mkv` — Matroska container. MKV is used (rather than MP4) because it tolerates Opus + arbitrary stream layouts cleanly and because the merge step uses `-f concat -c copy`, which works reliably with MKV.

## Merge command (VR2Normal only)

After all per-clip conversions, `VR2Normal.bat` runs:

```
ffmpeg -hide_banner -loglevel error -stats
       -f concat -safe 0
       -i <concat_list.txt>
       -c copy
       <merged>.mkv
```

- `-f concat` — demuxer mode that takes a text file of `file '<path>'` lines and stitches them in order
- `-safe 0` — allows absolute paths in the concat list (otherwise FFmpeg refuses for safety)
- `-c copy` — no re-encode; streams are copied bit-for-bit

The concat list is built earlier in the script via `dir /b /on` (alphabetical sort) of the per-clip outputs. **No re-encoding happens at merge time** — this is fast, but it requires that all per-clip outputs share identical codec parameters (which they do, because they were all produced by the same FFmpeg command).

## 1080p pipeline

```
ffmpeg
  -y !THREADS!
  -i <input>
  -vf "scale=1920:1080"
  -c:v h264_nvenc -preset p4 -cq 23
  -c:a copy
  <output>_1080p.MP4
```

Much simpler:

- `!THREADS!` is undefined in the script and expands to nothing — see [troubleshooting.md](troubleshooting.md)
- `scale=1920:1080` — straight Lanczos-equivalent downscale (default `bicubic` for `scale`)
- `h264_nvenc -preset p4 -cq 23` — NVENC encode at quality target 23, preset p4 (mid-range speed)
- `-c:a copy` — audio is stream-copied unchanged

There is no aspect ratio preservation in this filter; if your source is not 16:9, the output will be stretched. Replace `scale=1920:1080` with `scale=-2:1080` to preserve aspect ratio while constraining height.
