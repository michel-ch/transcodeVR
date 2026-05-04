# Folder structure

All three scripts work on a "one level of subfolders" model: the input root contains scene/group subfolders, and each subfolder contains the actual video files.

## Project layout

```
transcodeVR/
├── VR2Normal.bat
├── only_vr.bat
├── only_1080p.bat
├── README.md
├── docs/                  # this documentation
├── vr/                    # VR input  (used by VR2Normal.bat, only_vr.bat)
│   ├── scene_a/
│   │   ├── clip01.mp4
│   │   └── clip02.mp4
│   └── scene_b/
│       └── ...
├── nonevr/                # VR output (created on first run)
│   ├── scene_a/
│   │   ├── clip01.mkv
│   │   └── clip02.mkv
│   └── scene_a.mkv        # merged file (VR2Normal only, ≥2 clips)
├── input/                 # 1080p input  (only_1080p.bat)
│   └── scene_a/
│       └── clip01.MP4
├── output/                # 1080p output
│   └── scene_a/
│       └── clip01_1080p.MP4
└── temp/                  # transient concat lists (auto-deleted)
```

## VR pipeline (`vr/` ➜ `nonevr/`)

Used by `VR2Normal.bat` and `only_vr.bat`.

- **Input root**: `vr/`
- **Output root**: `nonevr/`
- The scripts iterate every subdirectory of `vr/` and look for `*.mp4 *.mkv *.avi *.mov` inside (any case mix Windows considers a match).
- For each input subdir `vr/X/`, the scripts create `nonevr/X/` if it doesn't already exist.
- Output files keep the original basename and always use `.mkv` as the container.
- `VR2Normal.bat` additionally writes `nonevr/X.mkv` — the alphabetical concatenation of every `.mkv` in `nonevr/X/`. Folders containing 0 or 1 file are skipped at the merge step.

Files placed directly in `vr/` (not in a subfolder) are **not** processed.

## 1080p pipeline (`input/` ➜ `output/`)

Used by `only_1080p.bat`.

- **Input root**: `input/`
- **Output root**: `output/`
- The script iterates every subdirectory of `input/` and processes `*.MP4` files. (See [troubleshooting.md](troubleshooting.md) for notes on the case-glob behavior.)
- Output filename: `<original_name>_1080p.MP4`
- Container is unchanged (still MP4) since audio is stream-copied.

`input/` and `output/` are **not** the same folders the VR scripts use. The VR pipeline and 1080p pipeline are independent.

## `temp/`

Used only by `VR2Normal.bat`. Holds one `<folder>_concat.txt` file per scene during the merge phase, listing the per-clip outputs in alphabetical order so `ffmpeg -f concat` can stitch them. The directory is removed (`rmdir /s /q`) at the end of the run.

If `VR2Normal.bat` is interrupted mid-run, you may find a leftover `temp/` directory; it is safe to delete manually.

## Empty folders

The repository ships with empty `vr/`, `nonevr/`, and `temp/` directories so the scripts don't need to bootstrap them. They are placeholders — drop your own content into `vr/<scene>/`.

`input/` and `output/` are **not** pre-created; `only_1080p.bat` will create `output/` on demand but expects you to create `input/<scene>/` yourself.
