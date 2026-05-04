# Troubleshooting

Practical issues you're likely to hit, organized by symptom.

## Setup issues

### "ffmpeg.exe is not recognized" / "The system cannot find the path specified"

**VR scripts** — `FFMPEG_PATH` points to a file that doesn't exist on your machine. The default is hardcoded to one user's path:

```
C:\Users\mtx\Desktop\desk\ffmpeg-master-latest-win64-gpl-shared\bin\ffmpeg.exe
```

Open `VR2Normal.bat` (or `only_vr.bat`) in a text editor and update the `set "FFMPEG_PATH=..."` line at the top.

**`only_1080p.bat`** — this script doesn't use `FFMPEG_PATH`; it calls `ffmpeg` directly. Make sure `ffmpeg.exe` is on your `PATH` (run `ffmpeg -version` in a fresh CMD window to verify).

### Window flashes and disappears immediately

Run the script from a CMD window instead of double-clicking, so the error message stays visible:

```cmd
cd C:\Users\<USERNAME>\Desktop\transcodeVR
VR2Normal.bat
```

The script does `pause` at the end on success, but a fatal error early in the script (typo in a path, missing `setlocal`) can skip that line.

## Runtime issues

### Conversions fail silently with `Files with errors: N`

The scripts run FFmpeg with `-loglevel error`, so you should see error messages mixed into the output. If you only see a count, scroll up — the actual error is above the `✓`/`✗` line.

Common causes:

- **CUDA decode unsupported for this codec** — VR sources in unusual codecs (AV1, ProRes, DNxHR) may not be decoded by NVDEC. Remove `-hwaccel cuda` from the FFmpeg line for an all-CPU run, or transcode the source to H.264 first.
- **Filter parameter typo** — if you've edited the `v360` filter, a missing colon or unknown parameter aborts FFmpeg before any frames are written.
- **Disk full** — VR conversions produce sizable 1440p MKVs. Check free space on the output drive.

### "No such filter: v360"

Your FFmpeg build is missing the `v360` filter. Use a `gpl-shared` or `full` build from the official Windows builds page rather than an `essentials` build.

### "h264_nvenc: encoder not found"

The 1080p script needs an FFmpeg compiled with NVENC support. Most current Windows binaries include it. Confirm with:

```cmd
ffmpeg -encoders | findstr nvenc
```

If nothing prints, install a different FFmpeg build.

## Output looks wrong

### Image is squashed, doubled, or shows two eyes

The `crop=w=iw/2:h=ih:x=0:y=0` step expects 180° **side-by-side** stereoscopic input — left eye on the left half, right eye on the right half. If your source is:

- **Top/bottom stereoscopic** — change to `crop=w=iw:h=ih/2:x=0:y=0`
- **Monoscopic 180°** — remove the `crop=...,` segment entirely
- **360°** — change `hequirect` to `equirect` and crop accordingly

### Image is fisheye-distorted

If the camera writes fisheye instead of equirectangular, change `hequirect` to `fisheye` in the `v360` filter:

```
v360=fisheye:flat:...
```

You may also need to adjust `iv_fov` / `ih_fov` to match the source lens specs.

### Framing is too tight or too loose

`d_fov=115` controls the output diagonal field of view.

- Larger values (130–150) → wider, more peripheral content visible, more lens distortion at the edges
- Smaller values (90–100) → tighter, more zoomed-in
- Below ~80 starts to look like a telephoto crop

### Camera is pointing the wrong direction

`pitch`, `yaw`, and `roll` reposition the virtual camera inside the hemisphere.

- `pitch=0` looks straight ahead. `pitch=-35` (the default) tilts down 35°. Positive values tilt up.
- `yaw=0` faces forward. Positive yaw pans right.
- `roll=0` is upright. Use only to compensate for a tilted-mounted camera.

Edit the values and re-render a single short clip to find what works for your source.

## Merge issues (`VR2Normal.bat`)

### "Only 1 file found in `<folder>` - skipping merge"

Working as intended. A folder with only one file doesn't need merging — the per-clip output is already the final file.

### Files merged in wrong order

The merge order is alphabetical (`dir /b /on`). If your filenames don't sort the way you want, rename them with zero-padded numbers:

- `clip01.mkv`, `clip02.mkv`, `clip10.mkv` — sorts correctly
- `clip1.mkv`, `clip2.mkv`, `clip10.mkv` — `clip10` ends up before `clip2`

You'd need to rename source files in `vr/<folder>/` before running the script (or rename the converted files in `nonevr/<folder>/` and re-run only the merge step manually).

### "Unsafe file name" or concat fails

Should not happen — `-safe 0` is set, which permits absolute paths. If you see this, check that the concat list (`temp/<folder>_concat.txt`) was written. The script deletes it on success, so the only way to inspect it is to interrupt the merge step or temporarily comment out the `del "!concat_file!"` line.

### `temp/` folder left behind

Happens when the script is interrupted (closed window, Ctrl+C, power loss). Safe to delete manually.

### Final summary says `Output: <folder>_MERGED.mkv` but the file is named `<folder>.mkv`

Cosmetic bug in the script's print statement. The actual output path is `nonevr/<folder>.mkv`. The summary line is misleading but the file is where you'd expect.

## Known quirks (not bugs, but worth knowing)

- **`!THREADS!` in `only_1080p.bat`** — this variable is referenced but never defined. The script substitutes nothing, so it's harmless. It looks like a leftover from a thread-pinning experiment.
- **Inconsistent folder conventions** — `only_1080p.bat` uses `input/` and `output/`, while `VR2Normal.bat` and `only_vr.bat` use `vr/` and `nonevr/`. Don't try to share folders between them.
- **No skip-already-converted logic** — running a VR script twice will re-encode every clip. Either move processed inputs out of `vr/` between runs, or delete `nonevr/` only when you want a fresh batch.
- **No exit code** — the scripts always end at `pause` regardless of how many failures occurred. They are not suitable for chaining into another pipeline that expects `errorlevel`-based success/failure signaling.
- **Hardcoded user path** — the default `FFMPEG_PATH` is one developer's machine. Update it on every install.

## Performance tuning

| Lever | Effect |
|---|---|
| `-preset slow` instead of `medium` (x264) | Better compression, slower encode |
| `-crf 22` instead of `24` (x264) | Higher quality, larger file |
| `-preset p7` instead of `p4` (NVENC) | Better NVENC quality, slower |
| Drop `-hwaccel cuda` | Forces CPU decode; useful for codecs NVDEC can't handle |
| Set `-threads N` | Caps x264 threads if you want to leave CPU for other work |

## Where to look next

- [configuration.md](configuration.md) — every variable, all in one place
- [ffmpeg-pipeline.md](ffmpeg-pipeline.md) — what each FFmpeg flag actually does
- [scripts/](scripts/) — per-script reference pages
