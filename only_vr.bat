@echo off
setlocal enabledelayedexpansion

:: Set paths
set "INPUT_DIR=C:\Users\%USERNAME%\Desktop\transcodeVR\vr"
set "OUTPUT_DIR=C:\Users\%USERNAME%\Desktop\transcodeVR\nonevr"
set "FFMPEG_PATH=C:\Users\mtx\Desktop\desk\ffmpeg-master-latest-win64-gpl-shared\bin\ffmpeg.exe"

:: Create output directory if it doesn't exist
if not exist "%OUTPUT_DIR%" (
    mkdir "%OUTPUT_DIR%"
    echo Created output directory: %OUTPUT_DIR%
)

:: Counter for processed files
set /a processed=0
set /a errors=0

echo Starting VR video conversion...
echo Input folder: %INPUT_DIR%
echo Output folder: %OUTPUT_DIR%
echo.

:: Loop through all subdirectories in the input folder
for /d %%D in ("%INPUT_DIR%\*") do (
    set "folder_name=%%~nxD"
    set "input_folder=%%D"
    set "output_folder=%OUTPUT_DIR%\!folder_name!"
    
    :: Create corresponding output folder if it doesn't exist
    if not exist "!output_folder!" (
        mkdir "!output_folder!"
        echo Created folder: !output_folder!
    )
    
    :: Process all video files in the current folder
    for %%F in ("!input_folder!\*.mp4" "!input_folder!\*.mkv" "!input_folder!\*.avi" "!input_folder!\*.mov") do (
        if exist "%%F" (
            set "input_file=%%F"
            set "filename=%%~nF"
            set "output_file=!output_folder!\!filename!.mkv"
            
            echo.
            echo Processing: !filename!
            echo Input:  !input_file!
            echo Output: !output_file!
            
            :: Run FFmpeg conversion (VR to flat)
            "%FFMPEG_PATH%" -hide_banner -loglevel error -stats -y -hwaccel cuda -i "!input_file!" -map 0:v:0 -map 0:a -vf "crop=w=iw/2:h=ih:x=0:y=0,v360=hequirect:flat:in_stereo=2d:out_stereo=2d:iv_fov=180:ih_fov=180:d_fov=115:pitch=-35:yaw=0:roll=0:w=2560:h=1440:interp=lanczos:reset_rot=1" -c:v libx264 -preset medium -crf 24 -tune film -x264-params keyint=600:bframes=7 -c:a libopus -b:a 128K -map_metadata:g -1 -map_metadata:s:v -1 -map_metadata:s:a 0:s:a -metadata:s "HANDLER_NAME=" "!output_file!"
            
            if !errorlevel! equ 0 (
                echo ✓ Successfully converted: !filename!
                set /a processed+=1
            ) else (
                echo ✗ Error converting: !filename!
                set /a errors+=1
            )
        )
    )
)

echo.
echo ===========================================
echo Conversion completed!
echo Files processed successfully: %processed%
echo Files with errors: %errors%
echo ===========================================

pause