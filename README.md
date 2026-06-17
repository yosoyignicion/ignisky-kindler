# 🔥 ignisky-kindler

> **Auto-configuración, verificación y optimización de servidores MCP para Hermes Agent.**
> El encendedor de tu ecosistema AI — por IgnicionDev.

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-ED2100?style=flat-square" alt="MIT"></a>
  <a href="https://hermes-agent.nousresearch.com"><img src="https://img.shields.io/badge/Hermes-0.16%2B-050505?style=flat-square" alt="Hermes"></a>
  <a href="https://github.com/yosoyignicion"><img src="https://img.shields.io/badge/Ignición-Integrations-ED2100?style=flat-square" alt="Ignición"></a>
  <a href=".github/workflows/lint.yml"><img src="https://img.shields.io/badge/ShellCheck-Passing-ED2100?style=flat-square" alt="ShellCheck"></a>
  <a href="https://gumroad.com/l/..."><img src="https://img.shields.io/badge/Premium-15€-050505?style=flat-square&logo=gumroad&logoColor=white" alt="Premium"></a>
</p>

---

## ¿Qué es ignisky-kindler?

Una herramienta CLI que automatiza la instalación, verificación y optimización de servidores MCP (Model Context Protocol) para [Hermes Agent](https://hermes-agent.nousresearch.com).

Si usas Hermes a diario y quieres que tus MCPs estén configurados, monitorizados y optimizados sin perder tiempo en comandos sueltos, esto es para ti.

---

## ⚡ Lo que hace por ti

| Modo | Comando | Lo que consigues |
|------|---------|-----------------|
| 🖥️ **Interactivo** | `./ignisky-kindler.sh` | Menú paso a paso: instalar, verificar, exportar |
| 🩺 **Diagnóstico** | `--tokens` | Analiza tu configuración y te da una nota del 0 al 100 |
| 💊 **Prescripción** | `--suggest` | Genera comandos exactos para optimizar tu setup |
| ✅ **Health check** | `--check` | Verifica que todos tus MCPs respondan en segundos |
| 📦 **Instalación** | `--install filesystem,github,time,sqlite` | Configura MCPs en lote |
| 📤 **Export** | `--export ./backup.json` | Lleva tu configuración a otro equipo |
| 🧪 **Simulación** | `--dry-run --install ...` | Mira qué pasaría antes de hacer cambios |

---

## 🆓 vs 💎 Premium

| Característica | Gratis | Premium |
|----------------|:------:|:-------:|
| Instalación de MCPs core (4) | ✅ | ✅ |
| Health check | ✅ | ✅ |
| Auditoría de tokens (`--tokens`) | ✅ | ✅ |
| Sugerencias de optimización (`--suggest`) | ✅ | ✅ |
| Catálogo completo de MCPs | ✅ (20) | ✅ (20) |
| Exportación JSON | ✅ | ✅ |
| **Catálogo de 20+ MCPs avanzados** | ❌ | ✅ |
| **kindler:watcher** — Monitorización 24/7 con reconexión automática | ❌ | ✅ |
| **kindler:shield** — Backup automático + restore point interactivo | ❌ | ✅ |
| **kindler:inject** — Variables de entorno inyectadas automáticamente | ❌ | ✅ |
| **Aplicación automática de optimizaciones** | ❌ | ✅ |
| 🎨 **Tema Ignición para Hermes Desktop** (exclusivo escritorio — valorado en 5€) | ❌ | ✅ **BONUS EXCLUSIVO** |

<p align="center">
  <a href="https://gumroad.com/l/...">
    <img src="https://img.shields.io/badge/🎯-CONSEGUIR+PREMIUM-ED2100?style=for-the-badge" alt="Premium">
  </a>
  <br>
  <sub>Código <code>IGNICION25</code> → 25% OFF (11.25€)</sub>
</p>

---

## 🚀 Primeros pasos

```bash
# 1. Clona el repo
git clone https://github.com/yosoyignicion/ignisky-kindler.git
cd ignisky-kindler

# 2. Hazlo ejecutable
chmod +x ignisky-kindler.sh

# 3. Modo interactivo (recomendado para empezar)
./ignisky-kindler.sh

# 4. O directamente: audita tu configuración
./ignisky-kindler.sh --tokens
```

### Requisitos

- **Hermes Agent** 0.16+ ([instalar](https://hermes-agent.nousresearch.com))
- **Bash** 4.0+
- **Python 3** + **PyYAML** (`pip install pyyaml`) — solo para `--tokens` y `--suggest`
- Linux o macOS

> **¿Usas Hermes desde Telegram, Discord u otro gateway?** No puedes ejecutar kindler directamente en estos canales. Ejecútalo en el servidor donde corre Hermes y pasa los comandos sugeridos manualmente, o configura los MCPs desde la terminal del servidor.

---

## 🔗 Ecosistema ignisky-*

Este script forma parte de una suite de herramientas para Hermes Agent:

| Herramienta | Función | Estado |
|-------------|---------|--------|
| [**ignisky-kindler**](https://github.com/yosoyignicion/ignisky-kindler) | Configuración y monitorización de MCPs | ✅ Disponible |
| [**ignisky-embers**](https://github.com/yosoyignicion/ignisky-embers) | Auditoría de seguridad del filesystem expuesto al agente | 🔄 En desarrollo |
| [**ignisky-spark**](https://github.com/yosoyignicion/ignisky-spark) | Scaffolding inteligente de workspaces para agentes AI | 🔄 En desarrollo |
| [**ignisky-forge**](https://github.com/yosoyignicion/ignisky-forge) | Gestión y sincronización de perfiles Hermes | 🔄 En desarrollo |

---

## 📸 Capturas

```
$ ./ignisky-kindler --tokens

═══ ⚡ ignisky-kindler:tokens — Auditoría de consumo ═══
┌─────────────────────────────────────────────────────┐
│  SCORE: 95/100 (A) — Óptimo 🔥                      │
└─────────────────────────────────────────────────────┘

🧠 Razonamiento:  low         → 🟢
📦 Compresión:    0.5/0.2     → 🟢
🚫 Toolsets off:  3           → 🟢
🔄 Max turns:     60          → 🟢
📎 MCPs activos:  6           → 🟡
```

---

## 📬 Feedback

¿Bugs, sugerencias o quieres proponer un MCP para el catálogo?

- **Issues:** [github.com/yosoyignicion/ignisky-kindler/issues](https://github.com/yosoyignicion/ignisky-kindler/issues)
- **Comunidad:** Discord (próximamente)

---

<p align="center">
  <sub>Hecho con 🔥 por <a href="https://github.com/yosoyignicion">IgnicionDev</a>
  · <a href="https://yosoyignicion.github.io/portafolio">Portafolio</a></sub>
  <br>
  <sub>Parte del <b>Hermes Integrations Pack</b> · Paleta Ignición #ED2100 · #050505</sub>
</p>
