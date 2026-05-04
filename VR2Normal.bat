@echo off
setlocal enabledelayedexpansion

:: Set paths
set "INPUT_DIR=C:\Users\%USERNAME%\Desktop\transcodeVR\vr"
set "OUTPUT_DIR=C:\Users\%USERNAME%\Desktop\transcodeVR\nonevr"
set "FFMPEG_PATH=C:\Users\mtx\Desktop\desk\ffmpeg-master-latest-win64-gpl-shared\bin\ffmpeg.exe"
set "TEMP_DIR=C:\Users\%USERNAME%\Desktop\transcodeVR\temp"

:: Create output directory if it doesn't exist
if not exist "%OUTPUT_DIR%" (
    mkdir "%OUTPUT_DIR%"
    echo Created output directory: %OUTPUT_DIR%
)

:: Create temp directory for merge operations
if not exist "%TEMP_DIR%" (
    mkdir "%TEMP_DIR%"
    echo Created temp directory: %TEMP_DIR%
)

:: Counter for processed files
set /a processed=0
set /a errors=0
set /a merged=0
set /a merge_errors=0

echo Starting VR video conversion...
echo Input folder: %INPUT_DIR%
echo Output folder: %OUTPUT_DIR%
echo.

:: Array to store folders for later merging
set folder_count=0

:: Loop through all subdirectories in the input folder
for /d %%D in ("%INPUT_DIR%\*") do (
    set "folder_name=%%~nxD"
    set "input_folder=%%D"
    set "output_folder=%OUTPUT_DIR%\!folder_name!"
    
    :: Store folder name for later merging
    set /a folder_count+=1
    set "merge_folder_!folder_count!=!folder_name!"
    
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
            
            :: Run FFmpeg conversion
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
echo.

:: Now merge files in each folder
echo Starting file merging process...
echo.

for /l %%i in (1,1,%folder_count%) do (
    set "current_folder=!merge_folder_%%i!"
    set "merge_source_dir=%OUTPUT_DIR%\!current_folder!"
    set "concat_file=%TEMP_DIR%\!current_folder!_concat.txt"
    set "merged_output=%OUTPUT_DIR%\!current_folder!.mkv"
    
    echo Processing folder: !current_folder!
    
    :: Count files in the folder
    set file_count=0
    for %%G in ("!merge_source_dir!\*.mkv") do (
        set /a file_count+=1
    )
    
    if !file_count! gtr 1 (
        echo Found !file_count! files to merge in !current_folder!
        
        :: Create concat file with sorted filenames
        if exist "!concat_file!" del "!concat_file!"
        
        :: Use dir to sort files naturally and create concat list
        for /f "tokens=*" %%G in ('dir /b /on "!merge_source_dir!\*.mkv"') do (
            echo file '!merge_source_dir!\%%G' >> "!concat_file!"
        )
        
        echo Merging files in !current_folder!...
        "%FFMPEG_PATH%" -hide_banner -loglevel error -stats -f concat -safe 0 -i "!concat_file!" -c copy "!merged_output!"
        
        if !errorlevel! equ 0 (
            echo ✓ Successfully merged !current_folder! - Output: !current_folder!_MERGED.mkv
            set /a merged+=1
        ) else (
            echo ✗ Error merging !current_folder!
            set /a merge_errors+=1
        )
        
        :: Clean up concat file
        if exist "!concat_file!" del "!concat_file!"
        
    ) else if !file_count! equ 1 (
        echo Only 1 file found in !current_folder! - skipping merge
    ) else (
        echo No files found in !current_folder! - skipping merge
    )
    echo.
)

:: Clean up temp directory
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"

echo.
echo ===========================================
echo FINAL SUMMARY
echo ===========================================
echo Individual files converted: %processed%
echo Individual conversion errors: %errors%
echo Folders merged successfully: %merged%
echo Merge errors: %merge_errors%
echo ===========================================
echo.
echo Merged files are saved
echo in the output directory root.
echo ===========================================

pause