# transcodeVR — Documentation

`transcodeVR` is a small set of Windows batch scripts that drive FFmpeg to:

- Convert 180° side-by-side VR video to flat 2D MKV (`VR2Normal.bat`, `only_vr.bat`)
- Optionally merge per-folder clips into a single file (`VR2Normal.bat`)
- Downscale ordinary video to 1080p with NVENC (`only_1080p.bat`)

The project has no build system, no dependencies to install, and no source code beyond the three `.bat` files. All heavy lifting is done by FFmpeg.

## Where to start

| If you want to… | Read |
|---|---|
| Get up and running | [getting-started.md](getting-started.md) |
| Understand the folder layout | [folder-structure.md](folder-structure.md) |
| Change paths or encoder settings | [configuration.md](configuration.md) |
| Understand the FFmpeg filter chain | [ffmpeg-pipeline.md](ffmpeg-pipeline.md) |
| Look up what a specific script does | [scripts/](scripts/) |
| Diagnose an issue | [troubleshooting.md](troubleshooting.md) |
| Read the architecture / design write-up | [`../report/report.pdf`](../report/report.pdf) (PDF; source `.tex` alongside) |

## Per-script reference

- [scripts/VR2Normal.md](scripts/VR2Normal.md) — VR conversion + per-folder merge
- [scripts/only_vr.md](scripts/only_vr.md) — VR conversion, no merge
- [scripts/only_1080p.md](scripts/only_1080p.md) — 1080p downscale (NVENC)

## At a glance

```
                         ┌────────────────────────┐
   vr/<scene>/*.mp4 ───► │  VR2Normal.bat         │ ───► nonevr/<scene>/*.mkv
                         │  only_vr.bat           │      (and nonevr/<scene>.mkv
                         └────────────────────────┘       for VR2Normal)

                         ┌────────────────────────┐
   input/<scene>/*.MP4 ─►│  only_1080p.bat        │ ───► output/<scene>/*_1080p.MP4
                         └────────────────────────┘
```

All three scripts iterate one level of subfolders below the input root, then process every video they find inside.
