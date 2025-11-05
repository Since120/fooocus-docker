#!/bin/bash
set -e

echo "Starting Fooocus with local Proxmox storage..."

# Prüfe ob AI Models gemountet sind
if [ -d "/mnt/ai/Models/Checkpoints" ]; then
    echo "✓ Found Checkpoints directory"
    MODEL_COUNT=$(ls -1 /mnt/ai/Models/Checkpoints/*.safetensors 2>/dev/null | wc -l)
    echo "  Found $MODEL_COUNT checkpoint files"
else
    echo "⚠ Warning: /mnt/ai/Models/Checkpoints not found"
fi

if [ -d "/mnt/ai/Models/LoRA" ]; then
    echo "✓ Found LoRA directory"
    LORA_COUNT=$(ls -1 /mnt/ai/Models/LoRA/*.safetensors 2>/dev/null | wc -l)
    echo "  Found $LORA_COUNT LoRA files"
else
    echo "⚠ Warning: /mnt/ai/Models/LoRA not found"
fi

# Erstelle Output-Verzeichnis falls nicht vorhanden
mkdir -p /mnt/ai/Outputs/fooocus-vm
echo "✓ Output directory: /mnt/ai/Outputs/fooocus-vm"

# Starte Fooocus
echo "Starting Fooocus application..."
cd /app
exec python3 entry_with_update.py --listen 0.0.0.0 --port 7865 "$@"
