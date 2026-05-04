# `only_vr.bat`

VR-to-flat conversion **without** the merge step. Use this when you want each source clip kept as a separate output file.

## What it does

For every subfolder of `vr/`:

1. Walks the folder for `.mp4 .mkv .avi .mov` files.
2. Runs each one through the [VR FFmpeg pipeline](../ffmpeg-pipeline.md) and writes a `.mkv` into `nonevr/<folder>/`.

That's it — no concatenation, no `temp/` directory, no merged output file.

## Variables

```bat
set "INPUT_DIR=C:\Users\%USERNAME%\Desktop\transcodeVR\vr"
set "OUTPUT_DIR=C:\Users\%USERNAME%\Desktop\transcodeVR\nonevr"
set "FFMPEG_PATH=C:\Users\mtx\Desktop\desk\ffmpeg-master-latest-win64-gpl-shared\bin\ffmpeg.exe"
```

Note that `TEMP_DIR` is **not** declared — this script doesn't create or use a temp directory.

## Counters

| Counter | Incremented when |
|---|---|
| `processed` | A per-clip conversion succeeds |
| `errors` | A per-clip conversion fails |

## Execution flow

```
1. Read INPUT_DIR, OUTPUT_DIR, FFMPEG_PATH
2. mkdir OUTPUT_DIR if missing
3. for each subdir D in INPUT_DIR:
     mkdir OUTPUT_DIR\<D> if missing
     for each .mp4 / .mkv / .avi / .mov in D:
         ffmpeg <VR pipeline> → OUTPUT_DIR\<D>\<name>.mkv
         increment processed or errors
4. print "Conversion completed!" summary, pause
```

## When to use this vs `VR2Normal.bat`

| Use `only_vr.bat` when… | Use `VR2Normal.bat` when… |
|---|---|
| Each clip is a separate take/scene that should stay separate | Clips are sequential segments of the same recording |
| You plan to edit the converted files in another tool | You want a single playable file per scene |
| You've already merged them or don't want a merged output | You want one-button "import → unified file" |

The two scripts share the same FFmpeg command, so output produced by `only_vr.bat` is identical (file-for-file) to the per-clip stage of `VR2Normal.bat`. You can run `only_vr.bat` first, inspect the results, and re-run `VR2Normal.bat` later — but be aware that the latter will re-encode all the clips again (it doesn't detect already-converted output).

## Failure modes

Same as `VR2Normal.bat` minus everything related to the merge step:

- **`ffmpeg.exe` not found** — every conversion fails.
- **Wrong source projection** — the `v360=hequirect:flat` step produces visually wrong output if your source is fisheye or full-equirectangular instead of half-equirectangular. Edit the `v360` filter accordingly.

## Related

- [VR2Normal.md](VR2Normal.md) — same conversion plus a per-folder merge
- [../ffmpeg-pipeline.md](../ffmpeg-pipeline.md)
- [../troubleshooting.md](../troubleshooting.md)
