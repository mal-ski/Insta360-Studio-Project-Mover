#!/bin/bash

echo -e "\nThis script is designed to apply necessary modifications to Insta360 Studio project files when you move your source video files to a different location."
echo -e "To ensure that all your saved project settings can be utilized from the new video location.\n"

# Function to process the path and remove any trailing slashes or backslashes and convert it to UNIX like format.
process_path() {
    local path="$1"
    local fixed_path=$(echo "${path//\\//}")

    if [[ "$fixed_path" = *"/" || "$fixed_path" = *"\\" ]]; then
        fixed_path=$(echo "${fixed_path/%\/}")
        fixed_path=$(echo "${fixed_path/%\\/}")
    fi
    
    echo "$fixed_path"
}

read -rp "Path to the project files: " path_to_project_files
read -rp "Old file path of video files: " old_path
read -rp "New file path of video files: " new_path

# Check for Windows file path backslashes and replace them with the UNIX format, as UNIX format is required by Insta Studio.
unix_path_to_project_files=$( process_path $path_to_project_files)

# Make sure that path to projects ends with slash "/".
if [[ "$unix_path_to_project_files" != *"/" ]]; then
    unix_path_to_project_files="$unix_path_to_project_files/"
fi

# Remove forward slashes and backslashes from paths to both old and new videos.
videos_old_path=$(process_path "$old_path")
videos_new_path=$(process_path "$new_path")

echo -e "\nStarting migration.\n"

# Replace old video file paths with new ones and generate new MD5 hashes in the project directory.
for directory in $(ls "$unix_path_to_project_files" ); do
    # Validation ensures that we only modify directories with 32-character hex MD5 sums.
    if [[ $directory =~ ^[a-f0-9]{32}$ ]]
    then
            project_file_name=$(ls "$unix_path_to_project_files"$directory/*.insprj)
            # Validation ensures that we modify only projects that match our video source.
            if grep -q "$videos_old_path" "$project_file_name"; then
                sed -i "s*${videos_old_path}*${videos_new_path}*g" "$project_file_name"
                video_file_name=$(basename -s .insprj "$unix_path_to_project_files"$directory/*.insprj)
                new_md5sum=($(echo -n "$videos_new_path"/"$video_file_name" | md5sum ))
                printf "$directory  -->  $new_md5sum"
                mv "$unix_path_to_project_files""$directory" "$unix_path_to_project_files"$new_md5sum && printf " | Success!\n"
            else
                echo "Source video path mismatch in this project $directory. Skip it!"
            fi
    fi
done
