# Fooocus mit TrueNAS SMB-Freigabe

Diese Anleitung zeigt, wie Sie Fooocus so konfigurieren, dass es Ihre bestehenden Modelle und LoRAs von einer TrueNAS SMB-Freigabe verwendet.

## Voraussetzungen

- TrueNAS mit SMB-Freigabe "AI"
- Modelle in: `storage/AI/Models/Checkpoints`
- LoRAs in: `storage/AI/Models/LoRA`
- SMB-Benutzername und Passwort

## Schritt 1: Environment-Variablen konfigurieren

Erstellen Sie eine `.env` Datei im gleichen Verzeichnis wie die `docker-compose.yml`:

```bash
# .env
SMB_HOST=//TRUENAS_IP_ODER_HOSTNAME/AI
SMB_USER=ihr_smb_benutzername
SMB_PASS=ihr_smb_passwort
```

**Beispiel:**
```bash
SMB_HOST=//192.168.1.100/AI
SMB_USER=admin
SMB_PASS=MeinSicheresPasswort123
```

## Schritt 2: docker-compose.smb.yml anpassen

Die `docker-compose.smb.yml` ist bereits vorbereitet. Sie müssen nur die `.env` Datei erstellen.

**Wichtig:** Die `.env` Datei sollte NICHT ins Git-Repository committed werden (ist bereits in `.gitignore`).

## Schritt 3: Container mit SMB-Support starten

```bash
# Mit docker-compose.smb.yml starten
docker-compose -f docker-compose.smb.yml up -d

# Logs prüfen um zu sehen ob Mount erfolgreich war
docker-compose -f docker-compose.smb.yml logs -f
```

Sie sollten folgende Meldungen sehen:
```
Mounting TrueNAS SMB share...
Successfully mounted //192.168.1.100/AI to /mnt/truenas
✓ Found Checkpoints directory
✓ Found LoRA directory
Starting Fooocus application...
```

## Schritt 4: Konfiguration überprüfen

Die `config.txt` ist bereits so konfiguriert, dass sie auf die gemounteten Pfade zeigt:

```json
{
    "path_checkpoints": ["/mnt/truenas/Models/Checkpoints"],
    "path_loras": ["/mnt/truenas/Models/LoRA"]
}
```

## Portainer-Spezifische Konfiguration

### Methode 1: Mit Environment-Variablen (empfohlen)

1. In Portainer: **Stacks** → **Add stack**
2. Name: `fooocus`
3. **Repository** auswählen
4. Repository URL: `https://github.com/Since120/fooocus-docker`
5. Compose path: `docker-compose.smb.yml`
6. **Environment variables** hinzufügen:
   - Name: `SMB_HOST`, Value: `//192.168.1.100/AI`
   - Name: `SMB_USER`, Value: `ihr_benutzername`
   - Name: `SMB_PASS`, Value: `ihr_passwort`
7. **Deploy the stack**

### Methode 2: Mit .env Datei

Wenn Sie lieber mit einer .env Datei arbeiten:

1. **Web editor** auswählen
2. Inhalt von `docker-compose.smb.yml` einfügen
3. Unter **Advanced settings** → **Environment variables**
4. "Advanced mode" aktivieren und .env Inhalt einfügen:
   ```
   SMB_HOST=//192.168.1.100/AI
   SMB_USER=ihr_benutzername
   SMB_PASS=ihr_passwort
   ```

## Verzeichnisstruktur auf TrueNAS

Stellen Sie sicher, dass Ihre TrueNAS-Freigabe folgende Struktur hat:

```
/mnt/pool/storage/AI/
├── Models/
│   ├── Checkpoints/
│   │   ├── model1.safetensors
│   │   └── model2.safetensors
│   └── LoRA/
│       ├── lora1.safetensors
│       └── lora2.safetensors
```

## Fehlerbehebung

### Mount schlägt fehl

**Symptome:**
```
Warning: Failed to mount SMB share. Using local models directory.
```

**Lösungen:**

1. **SMB-Credentials prüfen:**
   ```bash
   docker exec -it fooocus bash
   mount -t cifs //TRUENAS_IP/AI /test -o username=USER,password=PASS
   ```

2. **TrueNAS SMB-Berechtigungen prüfen:**
   - In TrueNAS: **Sharing** → **Windows (SMB) Shares**
   - Share "AI" auswählen → **Edit**
   - **Advanced Options** → **Access Control** prüfen

3. **Firewall prüfen:**
   ```bash
   # Auf TrueNAS-Host testen
   telnet TRUENAS_IP 445
   ```

4. **SELinux/AppArmor:**
   Falls Mount-Probleme auftreten, prüfen Sie die Security-Optionen:
   ```yaml
   security_opt:
     - apparmor:unconfined
   ```

### Modelle werden nicht angezeigt

**Prüfen Sie:**

1. **Verzeichnisse im Container:**
   ```bash
   docker exec -it fooocus ls -la /mnt/truenas/Models/Checkpoints
   docker exec -it fooocus ls -la /mnt/truenas/Models/LoRA
   ```

2. **config.txt im Container:**
   ```bash
   docker exec -it fooocus cat /app/config.txt
   ```

3. **Dateiberechtigungen:**
   Die Dateien müssen lesbar sein. Auf TrueNAS:
   ```bash
   chmod -R 755 /mnt/pool/storage/AI/Models
   ```

### Performance-Probleme

SMB kann bei großen Modellen langsam sein. Optimierungen:

1. **SMB Multi-Channel aktivieren** (TrueNAS SCALE)
2. **Jumbo Frames** im Netzwerk aktivieren (MTU 9000)
3. **10GbE Netzwerk** verwenden falls möglich

### Alternative: NFS statt SMB

Wenn Performance ein Problem ist, können Sie auch NFS verwenden:

```yaml
volumes:
  - type: nfs
    source: ":/mnt/pool/storage/AI"
    target: /mnt/truenas
    volume:
      nocopy: true
```

## Lokale Modelle + TrueNAS Modelle gleichzeitig

Sie können auch beide verwenden. In `config.txt`:

```json
{
    "path_checkpoints": [
        "/mnt/truenas/Models/Checkpoints",
        "/app/models/checkpoints"
    ],
    "path_loras": [
        "/mnt/truenas/Models/LoRA",
        "/app/models/loras"
    ]
}
```

Fooocus durchsucht dann beide Verzeichnisse.

## Sicherheit

**Wichtig:** Das SMB-Passwort wird als Environment-Variable gespeichert.

**Sicherer Ansatz:**

1. Erstellen Sie einen dedizierten TrueNAS-Benutzer nur für Fooocus
2. Geben Sie diesem Benutzer nur Lese-Rechte auf die Modell-Verzeichnisse
3. Verwenden Sie Docker Secrets in Produktion (nicht Environment-Variablen)

**Mit Docker Secrets (Portainer):**

1. In Portainer: **Secrets** → **Add secret**
2. Name: `smb_password`
3. Secret: `ihr_passwort`
4. In docker-compose.yml:
   ```yaml
   secrets:
     - smb_password

   services:
     fooocus:
       secrets:
         - smb_password
   ```

## Status prüfen

Nach dem Start:

```bash
# SMB-Mount prüfen
docker exec fooocus mount | grep truenas

# Modelle prüfen
docker exec fooocus ls /mnt/truenas/Models/Checkpoints

# Logs ansehen
docker-compose -f docker-compose.smb.yml logs -f
```

Bei Erfolg sehen Sie Ihre TrueNAS-Modelle in der Fooocus Web-UI!
