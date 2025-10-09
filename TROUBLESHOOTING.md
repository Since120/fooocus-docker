# Fooocus Docker - Fehlerbehebung

## Häufige Fehler beim ersten Start

### OSError: prompt_expansion/fooocus_expansion does not appear to have a file named config.json

**Ursache:** Das Prompt-Expansion-Modell konnte nicht korrekt heruntergeladen werden.

**Lösung 1: Container neu starten**
Der Container läuft weiter und funktioniert, auch wenn dieser Fehler auftritt. Die Prompt-Expansion-Funktion wird automatisch deaktiviert, aber die Bildgenerierung funktioniert normal.

```bash
# In Portainer: Container einfach laufen lassen
# ODER neu starten:
docker-compose restart
```

**Lösung 2: Modelle manuell herunterladen**
Falls der Fehler weiterhin auftritt, können Sie die Modelle manuell herunterladen:

```bash
# In den Container gehen
docker exec -it fooocus bash

# Modelle manuell laden
cd /app
python3 -c "
from modules.model_loader import load_file_from_url
load_file_from_url(
    url='https://huggingface.co/lllyasviel/misc/resolve/main/fooocus_expansion/pytorch_model.bin',
    model_dir='/app/models/prompt_expansion/fooocus_expansion',
    file_name='pytorch_model.bin'
)
"
```

**Lösung 3: Image neu bauen**
```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Exception in thread Thread-4 (worker)

**Ursache:** Dies ist ein nicht-kritischer Fehler während der Initialisierung des Worker-Threads.

**Lösung:** Der Container funktioniert trotzdem. Gradio läuft auf `http://0.0.0.0:7865` und ist erreichbar. Einfach ignorieren und im Browser auf Port 7865 zugreifen.

### Gradio Version Warning

```
IMPORTANT: You are using gradio version 3.41.2, however version 4.44.1 is available
```

**Ursache:** Fooocus ist für Gradio 3.x optimiert.

**Lösung:** Diese Warnung kann ignoriert werden. Fooocus funktioniert mit Gradio 3.41.2 wie vorgesehen.

### Container startet nicht / GPU nicht erkannt

**Symptome:**
- Container startet sofort wieder
- Fehler: "could not select device driver"

**Lösung:**

1. **NVIDIA Container Toolkit prüfen (auf dem Host/VM):**
```bash
# Prüfen ob nvidia-smi funktioniert
nvidia-smi

# NVIDIA Docker Runtime prüfen
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi
```

2. **Docker Daemon neu starten:**
```bash
sudo systemctl restart docker
```

3. **runtime: nvidia in docker-compose prüfen:**
Die docker-compose.yml sollte enthalten:
```yaml
runtime: nvidia
```

### Modelle werden nicht persistiert

**Symptome:**
- Modelle werden bei jedem Neustart heruntergeladen
- Generierte Bilder verschwinden

**Lösung:**

1. **Volumes prüfen:**
```bash
# Lokale Verzeichnisse prüfen
ls -la ./models
ls -la ./outputs

# Container Volume-Mounts prüfen
docker inspect fooocus | grep -A 10 Mounts
```

2. **Berechtigungen setzen:**
```bash
# Berechtigungen für Volume-Verzeichnisse
chmod -R 777 ./models
chmod -R 777 ./outputs
```

3. **Named Volumes verwenden:**
In `docker-compose.portainer.yml` sind Named Volumes konfiguriert, die persistent sind.

### Langsame Bildgenerierung

**Ursache:** GPU wird nicht genutzt oder zu wenig VRAM

**Diagnose:**
```bash
# Während der Bildgenerierung GPU-Nutzung prüfen
docker exec fooocus nvidia-smi
```

**Lösung:**
1. Sicherstellen, dass GPU erkannt wird (siehe "GPU nicht erkannt")
2. VRAM-Einstellungen in Fooocus anpassen
3. Kleinere Bildgrößen verwenden

### Out of Memory (OOM) Fehler

**Symptome:**
```
CUDA out of memory
RuntimeError: Unable to allocate tensor
```

**Lösung:**

1. **Bildgröße reduzieren:**
In Fooocus UI: Kleinere Auflösung wählen (z.B. 512x512 statt 1024x1024)

2. **Memory Limits in docker-compose.yml anpassen:**
```yaml
mem_limit: 16g  # Erhöhen wenn mehr RAM verfügbar
```

3. **VRAM-Modus ändern:**
Im Dockerfile die CMD-Zeile ändern:
```dockerfile
# Für GPUs mit weniger VRAM (4GB)
CMD ["python3", "entry_with_update.py", "--listen", "0.0.0.0", "--port", "7865", "--lowvram"]

# Für extrem wenig VRAM (unter 4GB)
CMD ["python3", "entry_with_update.py", "--listen", "0.0.0.0", "--port", "7865", "--normalvram"]
```

### Port 7865 bereits belegt

**Fehler:**
```
Error starting userland proxy: listen tcp4 0.0.0.0:7865: bind: address already in use
```

**Lösung:**

1. **Port ändern in docker-compose.yml:**
```yaml
ports:
  - "8080:7865"  # Externen Port ändern
```

2. **Oder anderen Container stoppen:**
```bash
# Prüfen welcher Container Port 7865 nutzt
docker ps | grep 7865
docker stop <container-id>
```

### Logs anzeigen

**Container-Logs in Echtzeit:**
```bash
docker-compose logs -f

# Oder in Portainer:
# Container auswählen → "Logs" → "Auto-refresh" aktivieren
```

### Container zurücksetzen

**Alle Daten löschen und neu starten:**
```bash
# Container und Volumes löschen
docker-compose down -v

# Lokale Verzeichnisse löschen (optional)
rm -rf ./models/* ./outputs/*

# Neu starten
docker-compose up -d
```

## Performance-Optimierung

### Erste Bildgenerierung ist langsam

**Normal:** Beim ersten Mal werden Modelle heruntergeladen und kompiliert. Das kann 5-10 Minuten dauern.

**Nach dem ersten Mal sollte es schneller sein.**

### Batch-Größe optimieren

In Fooocus UI: "Advanced" → "Performance" → Batch-Größe anpassen

### Modelle vorab herunterladen

Um Wartezeit zu reduzieren, können Sie die Hauptmodelle vorab herunterladen:

```bash
# In den Container
docker exec -it fooocus bash

# Beispiel: Realistic Vision herunterladen
cd /app/models/checkpoints
wget https://huggingface.co/lllyasviel/fav_models/resolve/main/fav/realisticVisionV51_v51VAE.safetensors
```

## Support

Bei weiteren Problemen:
- Fooocus Issues: https://github.com/lllyasviel/Fooocus/issues
- Docker Logs prüfen: `docker-compose logs -f`
- GitHub Issues dieses Repos: https://github.com/Since120/fooocus-docker/issues
