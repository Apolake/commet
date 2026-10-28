# Docker & CasaOS Deployment Guide for Commet Web

Deploying the [Commet](https://commet.chat) Matrix web client on your VPS or CasaOS home server using Docker and Docker Compose.

---

## ⚡ Quick Start (1 Command on VPS / Server)

1. **Clone the repository on your server:**
   ```bash
   git clone https://github.com/commetchat/commet.git
   cd commet
   ```

2. **Run the deployment script:**
   ```bash
   chmod +x deploy.sh
   ./deploy.sh
   ```

Commet will build and run on `http://<your-server-ip>:28080`.

---

## 🏠 Deploying on CasaOS

CasaOS natively supports custom Compose setups. There are two simple ways to deploy and build Commet directly on your CasaOS machine:

### Method A: Via CasaOS Terminal / SSH (Recommended)

1. Open **Terminal** in CasaOS or SSH into your CasaOS server:
   ```bash
   mkdir -p /DATA/AppData/commet
   cd /DATA/AppData/commet
   git clone https://github.com/commetchat/commet.git .
   ```

2. Build and launch with Docker Compose:
   ```bash
   docker compose -f docker-compose.casaos.yml up -d --build
   ```

3. CasaOS will automatically detect the app, build it locally from source, and display the **Commet** tile with its icon on your CasaOS dashboard. Clicking it opens `http://<casaos-ip>:28080`.

---

### Method B: Via CasaOS Web UI ("Install a customized application")

1. First, make sure the project files are on your CasaOS server (e.g. in `/DATA/AppData/commet`):
   ```bash
   git clone https://github.com/commetchat/commet.git /DATA/AppData/commet
   ```

2. On the **CasaOS Dashboard**:
   - Click the **`+`** icon on the top right of the apps list.
   - Choose **"Install a customized application"**.
   - Click the **"Import"** button at the top right of the popup dialog.
   - Select **"File"** and upload `docker-compose.casaos.yml`, or copy & paste the contents of `docker-compose.casaos.yml`.
   - In the `build: context:` field, ensure it points to `/DATA/AppData/commet`.
   - Click **Submit**.

CasaOS will build the container directly and add Commet to your dashboard with full icon, description, and link bindings.

---

## 🚀 VPS Deployment Options

### Option 1: Standalone (Behind an existing Reverse Proxy)

If you already use **Nginx Proxy Manager**, **Traefik**, **Caddy**, or a **Cloudflare Tunnel** on your VPS:

1. Create your `.env` file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` to configure your preferred ports and Matrix homeserver:
   ```env
   COMMET_PORT=28080
   DEFAULT_HOMESERVER=matrix.org
   ```

3. Start the container:
   ```bash
   docker compose up -d --build
   ```

4. Configure your reverse proxy to forward traffic to `http://127.0.0.1:28080` (or your configured `COMMET_PORT`).

---

### Option 2: Direct VPS with Automated Free SSL / HTTPS (Caddy)

If you have a domain pointed to your VPS IP and want a turn-key setup with automatic Let's Encrypt certificates:

1. Copy `.env.example`:
   ```bash
   cp .env.example .env
   ```

2. Fill in your domain name, email, and ports:
   ```env
   DOMAIN=chat.yourdomain.com
   ACME_EMAIL=admin@yourdomain.com
   HTTP_PORT=280
   HTTPS_PORT=2443
   DEFAULT_HOMESERVER=matrix.org
   ```

3. Launch with the `https` profile:
   ```bash
   docker compose --profile https up -d --build
   ```

Caddy will automatically provision SSL certificates on `HTTP_PORT`/`HTTPS_PORT`, redirect HTTP to HTTPS, and route requests to Commet.

---

### Option 3: Low-Resource VPS (< 2 GB RAM) with Pre-built Assets

Building Flutter apps from source can require ~2–4 GB RAM. If your VPS has low memory (e.g. 1GB VPS):

1. **Build the web assets on your local computer:**
   ```bash
   cd commet
   dart run scripts/codegen.dart
   flutter build web --release --dart-define PLATFORM=web
   ```

2. **Deploy to your VPS using the pre-built image target:**
   ```bash
   docker compose -f docker-compose.prebuilt.yml up -d --build
   ```
   *(Creates a lightweight ~15MB Nginx container in seconds without compiling in Docker)*.

---

## 🛠️ Configuration Reference

All settings in [.env](file:///C:/Users/Otaku/Desktop/Work/commet/commet/.env.example):

| Variable | Default | Description |
|---|---|---|
| `COMMET_PORT` / `PORT` | `28080` | Host port to expose Commet directly (standalone mode) |
| `HTTP_PORT` | `280` | Host HTTP port for Caddy / ACME Let's Encrypt challenge verification |
| `HTTPS_PORT` | `2443` | Host HTTPS port for Caddy TLS/SSL encrypted traffic |
| `DEFAULT_HOMESERVER` | `matrix.org` | Matrix homeserver pre-filled in the login screen |
| `CALENDAR_WIDGET` | `calendar-widget.commet.chat` | Host domain for the calendar widget |
| `DOMAIN` | `localhost` | Domain name when using the automatic HTTPS profile (`caddy`) |
| `ACME_EMAIL` | `admin@example.com` | Email address for Let's Encrypt certificate notices |

---

## 📋 Common Commands

- **Check logs:**
  ```bash
  docker compose logs -f commet
  ```

- **Stop the service:**
  ```bash
  docker compose down
  ```

- **Update to the latest version:**
  ```bash
  git pull
  docker compose up -d --build
  ```

- **Container health check:**
  ```bash
  docker compose ps
  ```
