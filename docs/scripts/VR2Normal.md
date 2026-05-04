# `VR2Normal.bat`

VR-to-flat conversion **plus** per-folder concatenation. The most complete script in the project.

## What it does

For every subfolder of `vr/`:

1. Walks the folder for `.mp4 .mkv .avi .mov` files.
2. Runs each one through the [VR FFmpeg pipeline](../ffmpeg-pipeline.md) and writes a `.mkv` into `nonevr/<folder>/`.
3. After every folder has been processed, walks `nonevr/<folder>/` again, builds an alphabetical concat list, and stitches the pieces into `nonevr/<folder>.mkv` via `ffmpeg -f concat -c copy`.

Folders containing 0 or 1 file skip the merge step (a single-file folder doesn't need merging).

## Variables

```bat
set "INPUT_DIR=C:\Users\%USERNAME%\Desktop\transcodeVR\vr"
set "OUTPUT_DIR=C:\Users\%USERNAME%\Desktop\transcodeVR\nonevr"
set "FFMPEG_PATH=C:\Users\mtx\Desktop\desk\ffmpeg-master-latest-win64-gpl-shared\bin\ffmpeg.exe"
set "TEMP_DIR=C:\Users\%USERNAME%\Desktop\transcodeVR\temp"
```

See [configuration.md](../configuration.md) for full details.

## Counters

The script tracks four counters and prints a summary at the end:

| Counter | Incremented when |
|---|---|
| `processed` | A per-clip conversion succeeds (`errorlevel == 0`) |
| `errors` | A per-clip conversion fails |
| `merged` | A per-folder concat succeeds |
| `merge_errors` | A per-folder concat fails |

## Execution flow

```
1. Read INPUT_DIR, OUTPUT_DIR, FFMPEG_PATH, TEMP_DIR
2. mkdir OUTPUT_DIR if missing
3. mkdir TEMP_DIR if missing
4. for each subdir D in INPUT_DIR:
     remember its name in merge_folder_<n>
     mkdir OUTPUT_DIR\<D> if missing
     for each .mp4 / .mkv / .avi / .mov in D:
         ffmpeg <VR pipeline> → OUTPUT_DIR\<D>\<name>.mkv
         increment processed or errors
5. print "Conversion completed!" summary
6. for each remembered folder:
     count .mkv files in OUTPUT_DIR\<folder>
     if count > 1:
         build TEMP_DIR\<folder>_concat.txt with alphabetically sorted entries
         ffmpeg -f concat -c copy → OUTPUT_DIR\<folder>.mkv
         increment merged or merge_errors
         delete the concat file
     elif count == 1: skip
     else: skip
7. rmdir /s /q TEMP_DIR
8. print final summary, pause
```

## Output naming

| Input | Output |
|---|---|
| `vr/scene_a/clip01.mp4` | `nonevr/scene_a/clip01.mkv` |
| `vr/scene_a/clip02.mp4` | `nonevr/scene_a/clip02.mkv` |
| (folder `scene_a` after merge) | `nonevr/scene_a.mkv` |

The merged file lives **next to** the per-clip folder, not inside it.

## Concatenation order

The concat list is built with:

```
for /f "tokens=*" %%G in ('dir /b /on "<folder>\*.mkv"') do (
    echo file '<folder>\%%G' >> <concat_file>
)
```

`dir /b /on` sorts by name, so the merge order is the alphabetical order of the produced `.mkv` filenames. If you need a specific order (for example, multi-segment dashcam clips), make sure the source filenames sort correctly when zero-padded:

- Good: `clip01.mp4`, `clip02.mp4`, … `clip10.mp4`
- Bad: `clip1.mp4`, `clip10.mp4`, `clip2.mp4` (alphabetical puts `clip10` before `clip2`)

## Exit behavior

The final `pause` keeps the window open until you press a key. There is no non-zero exit code on partial failures — the script always reaches `pause` regardless of how many clips errored.

## Failure modes

- **`ffmpeg.exe` not found** — the FFmpeg invocations all fail, every clip lands in the `errors` counter.
- **Source filter mismatch** — if your VR source is fisheye instead of equirectangular, the `v360=hequirect:flat` step will produce visually wrong output. Change `hequirect` to `fisheye` in the filter string.
- **Concat fails with mixed codec parameters** — only happens if you re-run after editing the encoder settings between batches and leave old `.mkv` files mixed in. Easiest fix: clear the per-folder output before re-running.
- **`temp/` left behind** — happens if the script is killed mid-run; safe to delete.

## Related

- [only_vr.md](only_vr.md) — same conversion without the merge step
- [../ffmpeg-pipeline.md](../ffmpeg-pipeline.md) — what each FFmpeg flag does
- [../troubleshooting.md](../troubleshooting.md)
