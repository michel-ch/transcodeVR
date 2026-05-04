# transcodeVR

Windows batch scripts that wrap FFmpeg to convert 180° side-by-side VR video into flat 2D, and to downscale ordinary clips to 1080p with NVENC.

## Requirements

- Windows (scripts are CMD `.bat`)
- An FFmpeg build with `libx264`, `libopus`, NVENC and the `v360` filter
  - Default location: `C:\Users\mtx\Desktop\desk\ffmpeg-master-latest-win64-gpl-shared\bin\ffmpeg.exe`
  - Edit `FFMPEG_PATH` at the top of `VR2Normal.bat` / `only_vr.bat` to point elsewhere
- NVIDIA GPU with CUDA — used for `-hwaccel cuda` decode (VR scripts) and `h264_nvenc` encode (1080p script)

## Folder layout

```
transcodeVR/
├── VR2Normal.bat     # VR → flat, then merge per folder
├── only_vr.bat       # VR → flat, no merge
├── only_1080p.bat    # 1080p downscale (NVENC)
├── vr/               # VR input — one subfolder per scene
├── nonevr/           # converted output
└── temp/             # concat lists (auto-cleaned by VR2Normal)
```

`only_1080p.bat` uses different paths: `input/` (source) and `output/` (destination), neither of which is created by the other scripts.

## Scripts

### `VR2Normal.bat`

For each subfolder of `vr/`, converts every `*.mp4 *.mkv *.avi *.mov` from 180° SBS to flat 2D, then concatenates the per-folder outputs into one `.mkv` named after the folder.

Pipeline per file:
- **Crop** left eye: `crop=iw/2:ih:0:0`
- **Reproject**: `v360=hequirect:flat` with `iv_fov=180 ih_fov=180 d_fov=115 pitch=-35`
- **Encode video**: 2560×1440, `libx264 -preset medium -crf 24 -tune film`, GOP 600, 7 B-frames
- **Encode audio**: `libopus -b:a 128K`, all input audio tracks mapped
- **Strip metadata**: global + per-stream metadata removed, `HANDLER_NAME` blanked

Merge step:
- Files inside each output subfolder are sorted with `dir /b /on` (alphabetical) and stream-copied through `ffmpeg -f concat`
- Folders with ≤1 file are skipped
- `temp/` is removed at the end

### `only_vr.bat`

Same per-file VR conversion as `VR2Normal.bat`, no merge step. Use when you want each source clip kept as a separate output.

### `only_1080p.bat`

Downscales `*.MP4` files inside subfolders of `input/` to 1920×1080 using `h264_nvenc -preset p4 -cq 23`. Audio is stream-copied. Output: `output/<subfolder>/<name>_1080p.MP4`.

## Usage

1. Drop VR clips into per-scene subfolders under `vr/` (e.g. `vr/scene_a/clip01.mp4`).
2. Run the script you want — double-click or from CMD:
   ```cmd
   VR2Normal.bat
   ```
3. Output:
   - Per-clip flats in `nonevr/<subfolder>/`
   - For `VR2Normal.bat`, the merged file at `nonevr/<subfolder>.mkv`

## Tuning

The framing is tuned for a specific VR camera placement: `d_fov=115` (diagonal FOV) with `pitch=-35` (looking down 35°). Adjust those two values in the `v360=...` filter if your source is mounted differently or you want a wider/narrower view. `crop=iw/2:ih:0:0` keeps the left eye — change `x=0` to `x=iw/2` to use the right eye instead.

## Known quirks

- `only_1080p.bat` references an undefined `!THREADS!` variable — expands to nothing, so it's harmless dead code. It also invokes `ffmpeg` from `PATH` instead of using a configurable `FFMPEG_PATH` like the VR scripts.
- `only_1080p.bat` does not share folders with the other two scripts — it expects `input/` and `output/`, not `vr/` and `nonevr/`.
- `VR2Normal.bat`'s success line says `..._MERGED.mkv` but the file is actually written as `<folder>.mkv`.
- All paths are anchored to `C:\Users\<USERNAME>\Desktop\transcodeVR`; move the project elsewhere and the scripts will need their `INPUT_DIR` / `OUTPUT_DIR` lines updated.
