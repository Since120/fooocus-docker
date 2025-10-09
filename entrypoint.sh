#!/bin/bash
set -e

echo "Starting Fooocus with TrueNAS SMB mount..."

# Erstelle Mount-Punkt
mkdir -p /mnt/truenas

# Mounte SMB Share wenn Credentials vorhanden sind
if [ ! -z "$SMB_HOST" ] && [ ! -z "$SMB_USER" ] && [ ! -z "$SMB_PASS" ]; then
    echo "Mounting TrueNAS SMB share..."

    # Versuche zu mounten
    if mount -t cifs "$SMB_HOST" /mnt/truenas -o username="$SMB_USER",password="$SMB_PASS",uid=1000,gid=1000,file_mode=0777,dir_mode=0777; then
        echo "Successfully mounted $SMB_HOST to /mnt/truenas"

        # Prüfe ob Verzeichnisse existieren
        if [ -d "/mnt/truenas/Models/Checkpoints" ]; then
            echo "✓ Found Checkpoints directory"
            ls -la /mnt/truenas/Models/Checkpoints | head -5
        else
            echo "⚠ Warning: /mnt/truenas/Models/Checkpoints not found"
        fi

        if [ -d "/mnt/truenas/Models/LoRA" ]; then
            echo "✓ Found LoRA directory"
            ls -la /mnt/truenas/Models/LoRA | head -5
        else
            echo "⚠ Warning: /mnt/truenas/Models/LoRA not found"
        fi
    else
        echo "⚠ Warning: Failed to mount SMB share. Using local models directory."
    fi
else
    echo "No SMB credentials provided. Using local models directory."
fi

# Starte Fooocus
echo "Starting Fooocus application..."
cd /app
exec python3 entry_with_update.py --listen 0.0.0.0 --port 7865 "$@"
