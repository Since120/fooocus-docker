# Fooocus Docker

Dieses Repository enthält ein Dockerfile für [Fooocus](https://github.com/lllyasviel/Fooocus) - eine benutzerfreundliche Stable Diffusion XL Bildgenerierungs-Software.

## Voraussetzungen

- Docker installiert
- NVIDIA GPU mit mindestens 4GB VRAM
- NVIDIA Container Toolkit installiert
- Mindestens 8GB RAM

## Installation

### 1. Mit Docker Compose (empfohlen)

```bash
# Repository klonen
git clone https://github.com/DEIN-USERNAME/fooocus-docker.git
cd fooocus-docker

# Container starten
docker-compose up -d

# Logs anzeigen
docker-compose logs -f
```

### 2. Mit Docker CLI

```bash
# Image bauen
docker build -t fooocus:latest .

# Container starten
docker run -d \
  --name fooocus \
  --gpus all \
  -p 7865:7865 \
  -v $(pwd)/models:/app/models \
  -v $(pwd)/outputs:/app/outputs \
  fooocus:latest
```

### 3. Mit Portainer (wenn GPU bereits an VM durchgereicht ist)

**Methode A: Von Git Repository (empfohlen)**
1. In Portainer einloggen
2. Gehe zu "Stacks" → "Add stack"
3. Name eingeben: `fooocus`
4. "Repository" auswählen
5. Repository URL: `https://github.com/Since120/fooocus-docker`
6. Compose path: `docker-compose.yml`
7. Reference: `main`
8. "Deploy the stack" klicken

**Methode B: Web Editor**
1. In Portainer einloggen
2. Gehe zu "Stacks" → "Add stack"
3. Name eingeben: `fooocus`
4. "Web editor" auswählen
5. Inhalt der `docker-compose.yml` aus dem Repository kopieren
6. "Deploy the stack" klicken

**Hinweis:** Da die GPU bereits auf VM-Ebene freigegeben ist, wird `runtime: nvidia` in der docker-compose.yml automatisch die GPU nutzen. Keine weiteren GPU-Einstellungen in Portainer erforderlich.

## Zugriff

Nach dem Start ist Fooocus unter folgender Adresse erreichbar:

```
http://localhost:7865
```

## Verzeichnisstruktur

```
.
├── Dockerfile              # Docker-Image-Definition
├── docker-compose.yml      # Docker Compose-Konfiguration
├── README.md              # Diese Datei
├── models/                # Heruntergeladene KI-Modelle (persistent)
└── outputs/               # Generierte Bilder (persistent)
```

## Konfiguration

### Ports ändern

In `docker-compose.yml` den Port ändern:

```yaml
ports:
  - "8080:7865"  # Ändere 8080 zu deinem gewünschten Port
```

### Speicherlimit setzen

In `docker-compose.yml` die Kommentare bei `mem_limit` entfernen:

```yaml
mem_limit: 16g
memswap_limit: 16g
```

### Presets verwenden

Um Fooocus mit einem Preset zu starten, ändere die CMD-Zeile im Dockerfile:

```dockerfile
# Für Anime-Stil
CMD ["python3", "entry_with_update.py", "--listen", "0.0.0.0", "--port", "7865", "--preset", "anime"]

# Für realistischen Stil
CMD ["python3", "entry_with_update.py", "--listen", "0.0.0.0", "--port", "7865", "--preset", "realistic"]
```

## Fehlerbehebung

### GPU wird nicht erkannt

Stelle sicher, dass NVIDIA Container Toolkit installiert ist:

```bash
# Installieren (Ubuntu/Debian)
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker
```

### Container startet nicht

Logs überprüfen:

```bash
docker-compose logs -f
```

### Speicherplatzprobleme

Die Modelle sind groß (mehrere GB). Stelle sicher, dass genügend Speicherplatz vorhanden ist:

```bash
df -h
```

## Volumes

- `/app/models`: Hier werden die KI-Modelle gespeichert (werden beim ersten Start heruntergeladen)
- `/app/outputs`: Hier werden die generierten Bilder gespeichert

## Updates

Um Fooocus auf die neueste Version zu aktualisieren:

```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

## Lizenz

Fooocus ist unter der GPL-3.0 Lizenz lizenziert. Siehe das [Original-Repository](https://github.com/lllyasviel/Fooocus) für Details.

## Credits

- [Fooocus](https://github.com/lllyasviel/Fooocus) von lllyasviel
- Dieses Dockerfile erstellt für die einfache Bereitstellung mit Docker und Portainer
