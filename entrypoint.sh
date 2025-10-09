#!/bin/bash
set -e

echo "Starting Fooocus with TrueNAS SMB mount..."

# Erstelle Mount-Punkt
mkdir -p /mnt/truenas

# Prüfe ob config.txt als Verzeichnis existiert und lösche es
if [ -d "/app/config.txt" ]; then
    echo "Removing config.txt directory..."
    rmdir /app/config.txt 2>/dev/null || rm -rf /app/config.txt
fi

# Mounte SMB Share wenn Credentials vorhanden sind
if [ ! -z "$SMB_HOST" ] && [ ! -z "$SMB_USER" ] && [ ! -z "$SMB_PASS" ]; then
    echo "Mounting TrueNAS SMB share..."
    echo "SMB Host: $SMB_HOST"

    # Versuche zu mounten mit privileged mode
    if mount -t cifs "$SMB_HOST" /mnt/truenas -o username="$SMB_USER",password="$SMB_PASS",uid=0,gid=0,file_mode=0755,dir_mode=0755,vers=3.0; then
        echo "✓ Successfully mounted $SMB_HOST to /mnt/truenas"

        # Prüfe ob Verzeichnisse existieren
        if [ -d "/mnt/truenas/Models/Checkpoints" ]; then
            echo "✓ Found Checkpoints directory"
            MODEL_COUNT=$(ls -1 /mnt/truenas/Models/Checkpoints/*.safetensors 2>/dev/null | wc -l)
            echo "  Found $MODEL_COUNT checkpoint files"
        else
            echo "⚠ Warning: /mnt/truenas/Models/Checkpoints not found"
        fi

        if [ -d "/mnt/truenas/Models/LoRA" ]; then
            echo "✓ Found LoRA directory"
            LORA_COUNT=$(ls -1 /mnt/truenas/Models/LoRA/*.safetensors 2>/dev/null | wc -l)
            echo "  Found $LORA_COUNT LoRA files"
        else
            echo "⚠ Warning: /mnt/truenas/Models/LoRA not found"
        fi
    else
        echo "⚠ Warning: Failed to mount SMB share. Using local models directory."
        echo "   This might be due to network connectivity or credentials."
    fi
else
    echo "No SMB credentials provided. Using local models directory."
fi

# Starte Fooocus
echo "Starting Fooocus application..."
cd /app
exec python3 entry_with_update.py --listen 0.0.0.0 --port 7865 "$@"
