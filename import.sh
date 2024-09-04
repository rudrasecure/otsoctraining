#!/bin/bash

# Folder containing the .ova files (you can change this path as needed)
OVA_FOLDER="OVA"

# Loop through all .ova files in the folder
for ova_file in "$OVA_FOLDER"/*.ova; do
    # Check if the file exists (in case no .ova files are found)
    if [ -f "$ova_file" ]; then
        echo "Importing $ova_file ..."
        
        # Import the OVA file using VBoxManage
        VBoxManage import "$ova_file"
        
        echo "$ova_file has been imported successfully."
    else
        echo "No .ova files found in $OVA_FOLDER"
        exit 1
    fi
done
