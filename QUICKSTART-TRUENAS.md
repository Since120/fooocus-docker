# Quick Start - Fooocus mit Ihren TrueNAS Modellen

## Schritt-für-Schritt Anleitung für Portainer

### 1. Stoppen Sie den aktuellen Container

In Portainer:
- Gehen Sie zu **Containers**
- Wählen Sie den `fooocus` Container
- Klicken Sie auf **Stop**
- Klicken Sie auf **Remove**

### 2. Erstellen Sie die Environment-Variablen

Sie benötigen folgende Informationen:
- **TrueNAS IP oder Hostname**
- **SMB Share Name**: `AI`
- **SMB Benutzername**
- **SMB Passwort**

### 3. Deployen Sie den neuen Stack

In Portainer:

1. **Stacks** → **Add stack**
2. **Name**: `fooocus`
3. **Build method**: **Repository**
4. **Repository URL**: `https://github.com/Since120/fooocus-docker`
5. **Compose path**: `docker-compose.smb.yml`
6. **Reference**: `main`

7. **Environment variables** hinzufügen (unter "Advanced settings"):

   Klicken Sie auf "+ add an environment variable" für jede Variable:

   | Name | Value |
   |------|-------|
   | `SMB_HOST` | `//IHR_TRUENAS_IP/AI` |
   | `SMB_USER` | `ihr_smb_benutzername` |
   | `SMB_PASS` | `ihr_smb_passwort` |

   **Beispiel:**
   - SMB_HOST: `//192.168.1.100/AI`
   - SMB_USER: `admin`
   - SMB_PASS: `MeinPasswort123`

8. Klicken Sie auf **Deploy the stack**

### 4. Prüfen Sie die Logs

1. Gehen Sie zu **Containers**
2. Klicken Sie auf `fooocus`
3. Klicken Sie auf **Logs**
4. Aktivieren Sie **Auto-refresh**

Sie sollten sehen:
```
Mounting TrueNAS SMB share...
Successfully mounted //192.168.1.100/AI to /mnt/truenas
✓ Found Checkpoints directory
✓ Found LoRA directory
Starting Fooocus application...
```

### 5. Zugriff

Öffnen Sie im Browser:
```
http://[IHRE_VM_IP]:7865
```

Ihre Modelle und LoRAs von TrueNAS sollten jetzt in Fooocus verfügbar sein!

## Verzeichnisstruktur auf TrueNAS

Stellen Sie sicher, dass Ihre TrueNAS-Freigabe diese Struktur hat:

```
/mnt/pool/storage/AI/
├── Models/
│   ├── Checkpoints/
│   │   └── (Ihre .safetensors Modelle)
│   └── LoRA/
│       └── (Ihre .safetensors LoRAs)
```

Die Pfade werden automatisch in Fooocus gemappt:
- TrueNAS: `storage/AI/Models/Checkpoints` → Fooocus: `/mnt/truenas/Models/Checkpoints`
- TrueNAS: `storage/AI/Models/LoRA` → Fooocus: `/mnt/truenas/Models/LoRA`

## Troubleshooting

### Mount schlägt fehl

1. **Prüfen Sie die Logs** (siehe Schritt 4)
2. **Prüfen Sie SMB-Zugriff** von einem anderen Computer:
   - Windows: `\\TRUENAS_IP\AI` im Explorer öffnen
   - Linux: `smbclient //TRUENAS_IP/AI -U benutzername`

3. **TrueNAS SMB-Freigabe prüfen:**
   - In TrueNAS: **Sharing** → **Windows (SMB) Shares**
   - Share "AI" sollte aktiviert sein
   - Berechtigungen prüfen

### Modelle werden nicht angezeigt

1. **In den Container gehen:**
   ```bash
   docker exec -it fooocus bash
   ```

2. **Verzeichnisse prüfen:**
   ```bash
   ls -la /mnt/truenas/Models/Checkpoints
   ls -la /mnt/truenas/Models/LoRA
   ```

3. **Config prüfen:**
   ```bash
   cat /app/config.txt
   ```

### Neu starten

```bash
# In Portainer: Container → Restart
# Oder über CLI:
docker restart fooocus
```

## Nächste Schritte

- Lesen Sie [TRUENAS-SMB-SETUP.md](TRUENAS-SMB-SETUP.md) für erweiterte Konfiguration
- Lesen Sie [TROUBLESHOOTING.md](TROUBLESHOOTING.md) für weitere Hilfe

## Performance-Tipp

Für beste Performance:
- Verwenden Sie 1GbE oder besser 10GbE Netzwerk zwischen Docker-Host und TrueNAS
- Aktivieren Sie SMB Multi-Channel in TrueNAS (wenn unterstützt)
- Für extrem große Modelle: Erwägen Sie NFS statt SMB
