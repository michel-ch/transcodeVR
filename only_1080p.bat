@echo off
setlocal enabledelayedexpansion

set "INPUT_FOLDER=C:\Users\%USERNAME%\Desktop\transcodeVR\input"
set "OUTPUT_FOLDER=C:\Users\%USERNAME%\Desktop\transcodeVR\output"

:: GPU settings
set "GPU_ENCODER=h264_nvenc"
set "GPU_PRESET=p4"
set "GPU_CRF=23"

:: 1080p scaling only
set "FILTER=scale=1920:1080"

if not exist "%OUTPUT_FOLDER%" mkdir "%OUTPUT_FOLDER%"

for /d %%d in ("%INPUT_FOLDER%\*") do (
    set "current_output_folder=%OUTPUT_FOLDER%\%%~nxd"
    if not exist "!current_output_folder!" mkdir "!current_output_folder!"
    
    for %%f in ("%%d\*.MP4") do (
        if exist "%%f" (
            set "output_file=!current_output_folder!\%%~nf_1080p%%~xf"
            
            echo Converting: %%~nxf
            
            ffmpeg -y !THREADS! -i "%%f" -vf "!FILTER!" -c:v !GPU_ENCODER! -preset !GPU_PRESET! -cq !GPU_CRF! -c:a copy "!output_file!"
        )
    )
)

echo Done!
pause