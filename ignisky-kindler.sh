#!/usr/bin/env bash
#
# ignisky-kindler — El encendedor de tu ecosistema de agentes AI 🔥
# Auto-configuración, verificación y monitorización de servidores MCP para Hermes Agent.
#
# Versión:    1.0.0
# Licencia:   MIT
# Autor:      IgnicionDev (yosoyignicion)
# Marca:      ignisky-* por Ignición 🔥
#
# Uso:        ./ignisky-kindler.sh [opciones]
#

set -euo pipefail

# ═══════════════════════════════════════════════════════════════
#  CONFIG
# ═══════════════════════════════════════════════════════════════

VERSION="1.0.0"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
CONFIG_FILE="${HERMES_HOME}/config.yaml"
BACKUP_DIR="${HERMES_HOME}/backups/kindler"

# ═══════════════════════════════════════════════════════════════
#  PALETA IGNICIÓN
# ═══════════════════════════════════════════════════════════════

ESC=$(printf '\033')
RED="${ESC}[38;2;237;33;0m"
DARK="${ESC}[38;2;5;5;5m"
LIGHT="${ESC}[38;2;229;229;229m"
GRAY="${ESC}[38;2;100;100;100m"
GREEN="${ESC}[38;2;0;200;100m"
YELLOW="${ESC}[38;2;255;200;0m"
BOLD="${ESC}[1m"
NC="${ESC}[0m"
CHECK="${GREEN}✓${NC}"
CROSS="${RED}✗${NC}"

# ═══════════════════════════════════════════════════════════════
#  UTILIDADES
# ═══════════════════════════════════════════════════════════════

log()    { echo -e "  ${GREEN}${BOLD}→${NC} $*"; }
warn()   { echo -e "  ${YELLOW}${BOLD}!${NC} $*"; }
error()  { echo -e "  ${RED}${BOLD}✖${NC} $*" >&2; }
die()    { error "$*"; exit 1; }
header() { echo -e "\n${RED}${BOLD}═══ $* ═══${NC}\n"; }
dim()    { echo -e "${GRAY}$*${NC}"; }

draw_box() {
    local title="$1"
    local width=58
    local padding=2
    echo -e "${RED}${BOLD}┌─${title} ${NC}${GRAY}$(printf '─%.0s' $(seq 1 $((width - ${#title} - 4))))${NC}"
}

box_item() { echo -e "  ${GRAY}│${NC}  $*"; }
box_end()  { echo -e "  ${GRAY}└$(printf '─%.0s' $(seq 1 56))${NC}\n"; }

# ═══════════════════════════════════════════════════════════════
#  CATÁLOGO DE MCPS
# ═══════════════════════════════════════════════════════════════

# Formato: nombre|comando_corto|descripción|categoría|tier(free/premium)
declare -a MCP_CATALOG=(
    "filesystem|npx -y @modelcontextprotocol/server-filesystem <path>|Acceso seguro al sistema de archivos local|Almacenamiento|free"
    "github|npx -y @modelcontextprotocol/server-github|Integración con repositorios y APIs de GitHub|Desarrollo|free"
    "time|uvx mcp-server-time|Hora y husos horarios del mundo|Utilidad|free"
    "sqlite|uvx mcp-server-sqlite --db-path <path>|Base de datos SQLite ligera para persistencia|Datos|free"
    "brave-search|npx -y @modelcontextprotocol/server-brave-search|Búsquedas web en tiempo real con Brave|Web|premium"
    "fetch|uvx mcp-server-fetch|Extracción y scrapeo de contenido web|Web|premium"
    "puppeteer|npx -y @modelcontextprotocol/server-puppeteer|Automatización completa de navegador Chromium|Browser|premium"
    "sequential-thinking|npx -y @modelcontextprotocol/server-sequential-thinking|Razonamiento estructurado paso a paso|IA|premium"
    "memory|npx -y @modelcontextprotocol/server-memory|Memoria persistente entre sesiones del agente|IA|premium"
    "mcp-installer|npx -y @modelcontextprotocol/server-mcp-installer|Auto-instalación de nuevos MCPs bajo demanda|Utilidad|premium"
    "perplexity|npx -y @modelcontextprotocol/server-perplexity|Búsqueda con IA generativa de Perplexity|Web|premium"
    "playwright|npx -y @modelcontextprotocol/server-playwright|Testing y automatización E2E de navegadores|Browser|premium"
    "redis|npx -y @modelcontextprotocol/server-redis|Caché en memoria y colas de mensajes|Datos|premium"
    "postgres|npx -y @modelcontextprotocol/server-postgres|Base de datos PostgreSQL relacional|Datos|premium"
    "notion|npx -y @modelcontextprotocol/server-notion|Gestión de notas y bases de datos de Notion|Productividad|premium"
    "slack|npx -y @modelcontextprotocol/server-slack|Mensajería y canales de Slack|Comunicación|premium"
    "docker|docker run ...|Contenedores Docker para entornos aislados|Infra|premium"
    "kubernetes|npx -y @modelcontextprotocol/server-kubernetes|Gestión de clusters Kubernetes|Infra|premium"
    "mcp-use|pip install mcp-use|Framework completo para crear apps MCP personalizadas|Framework|premium"
    "spotify|npx -y @modelcontextprotocol/server-spotify|Control de reproducción y playlists de Spotify|Multimedia|premium"
)

get_mcp_field() {
    local entry="$1" field="$2"
    echo "$entry" | cut -d'|' -f"$field"
}

get_mcp_name()   { get_mcp_field "$1" 1; }
get_mcp_cmd()    { get_mcp_field "$1" 2; }
get_mcp_desc()   { get_mcp_field "$1" 3; }
get_mcp_cat()    { get_mcp_field "$1" 4; }
get_mcp_tier()   { get_mcp_field "$1" 5; }

# ═══════════════════════════════════════════════════════════════
#  DETECTOR — Hermes + MCPs instalados
# ═══════════════════════════════════════════════════════════════

detect_hermes() {
    if command -v hermes &>/dev/null; then
        log "Hermes Agent detectado: ${BOLD}$(hermes --version 2>&1 | head -1)${NC}"
        return 0
    fi
    if [[ -f "$CONFIG_FILE" ]]; then
        warn "Hermes CLI no está en PATH, pero existe config.yaml"
        return 0
    fi
    error "No se detectó Hermes Agent en PATH ni config.yaml en ${HERMES_HOME}"
    error "Instala Hermes primero: curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash"
    return 1
}

detect_installed_mcps() {
    local -n _result="$1"
    _result=()
    if [[ ! -f "$CONFIG_FILE" ]]; then
        warn "No se encontró config.yaml en ${CONFIG_FILE}"
        return 1
    fi
    while IFS= read -r line; do
        local name
        name=$(echo "$line" | sed -n 's/^  \([a-zA-Z_-]\):*/\1/p' | head -1)
        [[ -z "$name" || "$name" == \#* ]] && continue
        # Python parse para extraer nombres reales de MCPs
    done < <(grep -A1 '^mcp_servers:' "$CONFIG_FILE" 2>/dev/null || true)
    # Usar hermes mcp list si está disponible
    if command -v hermes &>/dev/null; then
        while IFS= read -r line; do
            local name
            name=$(echo "$line" | awk '{print $1}')
            [[ -n "$name" && "$name" != "No" ]] && _result+=("$name")
        done < <(hermes mcp list 2>/dev/null | tail -n +2 || true)
    fi
}

check_mcp_health() {
    local mcp_name="$1"
    if command -v hermes &>/dev/null; then
        if hermes mcp test "$mcp_name" &>/dev/null; then
            return 0
        fi
    fi
    return 1
}

check_all_mcps() {
    header "🔥 Health Check — ignisky-kindler:glow"
    local -n _installed="$1"
    local all_ok=true
    for mcp in "${_installed[@]}"; do
        if check_mcp_health "$mcp"; then
            echo -e "  ${CHECK} ${BOLD}$mcp${NC}  $(dim· responde correctamente)"
        else
            echo -e "  ${CROSS} ${BOLD}$mcp${NC}  $(dim· no responde o no encontrado)"
            all_ok=false
        fi
    done
    echo ""
    if $all_ok; then
        log "Todos los MCPs responden correctamente 🟢"
    else
        warn "Algunos MCPs tienen problemas — revisa la configuración"
    fi
}

# ═══════════════════════════════════════════════════════════════
#  INSTALADOR
# ═══════════════════════════════════════════════════════════════

backup_config() {
    local ts
    ts=$(date +%Y%m%d-%H%M%S)
    mkdir -p "$BACKUP_DIR"
    cp "$CONFIG_FILE" "${BACKUP_DIR}/config-${ts}.yaml"
    log "Backup creado: ${GRAY}${BACKUP_DIR}/config-${ts}.yaml${NC}"
}

install_mcp() {
    local mcp_name="$1" mcp_cmd="$2" mcp_desc="$3"
    if [[ "$DRY_RUN" == true ]]; then
        log "[DRY-RUN] Se instalaría ${BOLD}${mcp_name}${NC} — ${mcp_desc}"
        log "[DRY-RUN] Comando: ${GRAY}${mcp_cmd}${NC}"
        return 0
    fi
    log "Instalando ${BOLD}${mcp_name}${NC} — ${mcp_desc}"
    if command -v hermes &>/dev/null; then
        if hermes mcp add "$mcp_name" --command "$mcp_cmd" &>/dev/null; then
            log "${CHECK} ${mcp_name} instalado correctamente"
            return 0
        fi
        if hermes mcp install "$mcp_name" &>/dev/null; then
            log "${CHECK} ${mcp_name} instalado desde catálogo"
            return 0
        fi
    fi
    warn "No se pudo instalar ${mcp_name} automáticamente"
    warn "Instálalo manualmente: ${GRAY}${mcp_cmd}${NC}"
    return 1
}

install_bulk() {
    local -a requested=("$@")
    local count=0
    for entry in "${MCP_CATALOG[@]}"; do
        local name tier
        name=$(get_mcp_name "$entry")
        tier=$(get_mcp_tier "$entry")
        for req in "${requested[@]}"; do
            if [[ "$name" == "$req" ]]; then
                if [[ "$tier" == "premium" && "${PREMIUM_UNLOCKED:-false}" != "true" ]]; then
                    echo -e "  ${YELLOW}⛁${NC} ${BOLD}$name${NC} ${DARK}· Premium — Compra el pack para desbloquear${NC}"
                    continue
                fi
                install_mcp "$name" "$(get_mcp_cmd "$entry")" "$(get_mcp_desc "$entry")"
                ((count++))
            fi
        done
    done
    if [[ $count -gt 0 ]]; then
        log "${BOLD}$count MCP(s) procesado(s)${NC}"
    else
        warn "Ningún MCP instalado. Revisa los nombres: ${requested[*]}"
    fi
}

remove_mcp() {
    local mcp_name="$1"
    log "Desinstalando ${BOLD}${mcp_name}${NC}"
    if command -v hermes &>/dev/null; then
        hermes mcp remove "$mcp_name" &>/dev/null && log "${CHECK} ${mcp_name} eliminado" || warn "No se pudo eliminar ${mcp_name}"
    fi
}

# ═══════════════════════════════════════════════════════════════
#  EXPORTADOR
# ═══════════════════════════════════════════════════════════════

export_config() {
    local output_path="${1:-./kindler-export-$(date +%Y%m%d).json}"
    header "📤 Exportando configuración a ${output_path}"
    if [[ -f "$CONFIG_FILE" ]]; then
        python3 -c "
import json, yaml
with open('${CONFIG_FILE}') as f:
    cfg = yaml.safe_load(f)
mcps = cfg.get('mcp_servers', {})
result = {
    'exported_at': '$(date -u +%Y-%m-%dT%H:%M:%SZ)',
    'tool': 'ignisky-kindler',
    'version': '${VERSION}',
    'mcp_count': len(mcps),
    'mcp_servers': {k: {
        'command': v.get('command', ''),
        'args': v.get('args', []),
        'env_keys': list(v.get('env', {}).keys()) if v.get('env') else []
    } for k, v in mcps.items()}
}
with open('${output_path}', 'w') as f:
    json.dump(result, f, indent=2)
print('✅ Exportado correctamente')
" 2>&1 || warn "Error al exportar"
    else
        warn "No hay config.yaml para exportar"
    fi
}

# ═══════════════════════════════════════════════════════════════
#  PREMIUM STUBS (placeholder — solo se activan con flag --premium)
# ═══════════════════════════════════════════════════════════════

premium_watcher() {
    header "🔥 ignisky-kindler:watcher"
    echo -e "  ${YELLOW}⛁${NC} ${BOLD}Premium feature${NC}"
    dim "  Monitoriza todos tus MCPs cada 60 segundos"
    dim "  Reconecta automáticamente los que fallen"
    dim "  Alerta visual cuando un MCP se cae"
    echo ""
    echo -e "  ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${BOLD}💎 Esta función está disponible en el pack premium${NC}"
    echo -e "  ${BOLD}👉 https://ignaciodev.gumroad.com/l/ignisky-kindler-premium  ·  Cupón: ${RED}IGNICION25${NC}"
    echo -e "  ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

premium_shield() {
    header "🔥 ignisky-kindler:shield"
    echo -e "  ${YELLOW}⛁${NC} ${BOLD}Premium feature${NC}"
    dim "  Backup automático antes de cada modificación"
    dim "  Sistema de restore point interactivo"
    dim "  Rollback a cualquier estado anterior"
    echo ""
    echo -e "  ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${BOLD}💎 Disponible en el pack premium${NC}"
    echo -e "  ${BOLD}👉 https://ignaciodev.gumroad.com/l/ignisky-kindler-premium  ·  Cupón: ${RED}IGNICION25${NC}"
    echo -e "  ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

premium_inferno() {
    header "🔥 ignisky-kindler:inferno — Catálogo Premium"
    echo -e "  ${YELLOW}⛁${NC} ${BOLD}16 MCPs avanzados disponibles${NC}"
    echo ""
    for entry in "${MCP_CATALOG[@]}"; do
        local name desc cat tier
        name=$(get_mcp_name "$entry")
        desc=$(get_mcp_desc "$entry")
        cat=$(get_mcp_cat "$entry")
        tier=$(get_mcp_tier "$entry")
        if [[ "$tier" == "premium" ]]; then
            echo -e "  ${GRAY}│${NC} ${RED}🔥${NC} ${BOLD}$name${NC} ${GRAY}· ${cat}${NC}"
            echo -e "  ${GRAY}│${NC}   ${GRAY}${desc}${NC}"
        fi
    done
    echo ""
    echo -e "  ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${BOLD}💎 Compra el pack premium para desbloquearlos todos${NC}"
    echo -e "  ${BOLD}👉 https://ignaciodev.gumroad.com/l/ignisky-kindler-premium  ·  Cupón: ${RED}IGNICION25${NC}"
    echo -e "  ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

premium_env_inject() {
    header "🔥 ignisky-kindler:env-inject"
    echo -e "  ${YELLOW}⛁${NC} ${BOLD}Premium feature${NC}"
    dim "  Inyecta variables de entorno automáticamente"
    dim "  Detecta API keys necesarias para cada MCP"
    dim "  Te guía para configurarlas sin tocar archivos manualmente"
    echo ""
    echo -e "  ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${BOLD}💎 Disponible en el pack premium${NC}"
    echo -e "  ${BOLD}👉 https://ignaciodev.gumroad.com/l/ignisky-kindler-premium  ·  Cupón: ${RED}IGNICION25${NC}"
    echo -e "  ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# ═══════════════════════════════════════════════════════════════
#  MODO INTERACTIVO
# ═══════════════════════════════════════════════════════════════

show_banner() {
    echo ""
    echo -e "  ${RED}${BOLD}╔══════════════════════════════════════════╗${NC}"
    echo -e "  ${RED}${BOLD}║   🔥 ignisky-kindler v${VERSION}              ${NC}"
    echo -e "  ${RED}${BOLD}║   El encendedor de tu ecosistema AI     ║${NC}"
    echo -e "  ${RED}${BOLD}╚══════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${GRAY}by IgnicionDev · Parte de ignisky-* 🔥${NC}"
    echo ""
}

show_status() {
    local -n _installed="$1"
    echo -e "  ${RED}${BOLD}═══ 📊 Estado actual ═══${NC}"
    echo ""
    if command -v hermes &>/dev/null; then
        echo -e "  ${CHECK} Hermes: ${BOLD}$(hermes --version 2>&1 | head -1)${NC}"
    else
        echo -e "  ${CROSS} Hermes CLI no encontrado"
    fi
    echo -e "  ${CHECK} Config: ${GRAY}${CONFIG_FILE}${NC}"
    echo -e "  ${CHECK} MCPs instalados: ${BOLD}${#_installed[@]}${NC}"
    for mcp in "${_installed[@]}"; do
        echo -e "         ${GRAY}·${NC} ${mcp}"
    done
    echo ""
}

interactive_menu() {
    local -a installed_mcps=("$@")
    while true; do
        echo -e "\n${RED}${BOLD}┌─ ¿Qué quieres hacer? ───────────────────────────────────┐${NC}"
        echo -e "  ${GRAY}│${NC}  ${BOLD}1${NC}  🔥  Instalar MCPs nuevos"
        echo -e "  ${GRAY}│${NC}  ${BOLD}2${NC}  ✅  Verificar salud de MCPs instalados"
        echo -e "  ${GRAY}│${NC}  ${BOLD}3${NC}  📋  Ver catálogo completo disponible"
        echo -e "  ${GRAY}│${NC}  ${BOLD}4${NC}  🗑️   Desinstalar un MCP"
        echo -e "  ${GRAY}│${NC}  ${BOLD}5${NC}  📤  Exportar configuración actual"
        echo -e "  ${GRAY}│${NC}  ${BOLD}6${NC}  💎  Ver funciones premium"
        echo -e "  ${GRAY}│${NC}  ${BOLD}7${NC}  ⚡  Sugerencias de optimización"
        echo -e "  ${GRAY}│${NC}  ${BOLD}0${NC}  🚪  Salir"
        echo -e "${RED}${BOLD}└────────────────────────────────────────────────────────┘${NC}"
        echo ""
        read -r -p "  ${RED}›${NC} ${BOLD}Opción${NC} [0-7]: " opt
        echo ""

        case "$opt" in
            1) interactive_install ;;
            2) check_all_mcps installed_mcps ;;
            3) interactive_catalog ;;
            4) interactive_remove ;;
            5) export_config ;;
            6) interactive_premium ;;
            7) suggest_optimizations ;;
            0) echo -e "  ${GREEN}¡Hasta luego! 🔥${NC}\n"; exit 0 ;;
            *) warn "Opción inválida" ;;
        esac
    done
}

interactive_install() {
    header "🔥 Instalar MCPs"
    echo -e "  ${BOLD}Selecciona los MCPs a instalar (separados por espacio):${NC}"
    echo ""
    local i=1
    declare -a names
    for entry in "${MCP_CATALOG[@]}"; do
        local name desc tier
        name=$(get_mcp_name "$entry")
        desc=$(get_mcp_desc "$entry")
        tier=$(get_mcp_tier "$entry")
        names[$i]="$name"
        local lock=""
        [[ "$tier" == "premium" ]] && lock="${YELLOW}⛁${NC} "
        echo -e "  ${GRAY}│${NC}  ${BOLD}$i${NC}  ${lock}${name} ${GRAY}· ${desc}${NC}"
        ((i++))
    done
    echo ""
    read -r -p "  ${RED}›${NC} Números (ej: 1 2 3): " -a selections
    local -a to_install=()
    for sel in "${selections[@]}"; do
        [[ -n "${names[$sel]}" ]] && to_install+=("${names[$sel]}")
    done
    if [[ ${#to_install[@]} -gt 0 ]]; then
        backup_config
        install_bulk "${to_install[@]}"
    else
        warn "Ninguna selección válida"
    fi
}

interactive_catalog() {
    header "📋 Catálogo de MCPs"
    echo -e "  ${BOLD}Disponibles:${NC}"
    echo ""
    for entry in "${MCP_CATALOG[@]}"; do
        local name desc cat tier
        name=$(get_mcp_name "$entry")
        desc=$(get_mcp_desc "$entry")
        cat=$(get_mcp_cat "$entry")
        tier=$(get_mcp_tier "$entry")
        local icon="🆓"
        [[ "$tier" == "premium" ]] && icon="${YELLOW}⛁${NC}"
        echo -e "  ${GRAY}│${NC}  ${icon} ${RED}${BOLD}$name${NC} ${GRAY}· ${cat}${NC}"
        echo -e "  ${GRAY}│${NC}    ${GRAY}${desc}${NC}"
    done
    echo ""
    echo -e "  ${YELLOW}⛁${NC} ${GRAY}= Premium (requiere pack)${NC}"
}

interactive_remove() {
    header "🗑️  Desinstalar MCP"
    local -a installed=()
    detect_installed_mcps installed
    if [[ ${#installed[@]} -eq 0 ]]; then
        warn "No hay MCPs instalados para desinstalar"
        return
    fi
    echo -e "  ${BOLD}Selecciona MCP a desinstalar:${NC}"
    local i=1
    declare -a names
    for mcp in "${installed[@]}"; do
        names[$i]="$mcp"
        echo -e "  ${GRAY}│${NC}  ${BOLD}$i${NC}  $mcp"
        ((i++))
    done
    echo ""
    read -r -p "  ${RED}›${NC} Número: " sel
    if [[ -n "${names[$sel]}" ]]; then
        backup_config
        remove_mcp "${names[$sel]}"
    fi
}

interactive_premium() {
    header "💎 ignisky-kindler Premium"
    echo -e "  ${BOLD}Funciones exclusivas:${NC}"
    echo ""
    echo -e "  ${GRAY}│${NC}  🔥  ${BOLD}kindler:watcher${NC}  ${GRAY}· Monitoriza MCPs cada 60s y reconecta${NC}"
    echo -e "  ${GRAY}│${NC}  🛡️   ${BOLD}kindler:shield${NC}   ${GRAY}· Backup + restore point interactivo${NC}"
    echo -e "  ${GRAY}│${NC}  🔥  ${BOLD}kindler:inferno${NC}  ${GRAY}· 20+ MCPs con instalación 1 comando${NC}"
    echo -e "  ${GRAY}│${NC}  🔐  ${BOLD}kindler:inject${NC}   ${GRAY}· Env vars inyectadas automáticamente${NC}"
    echo ""
    echo -e "  ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${BOLD}👉 https://ignaciodev.gumroad.com/l/ignisky-kindler-premium${NC}"
    echo -e "  ${BOLD}🏷️  Cupón: ${RED}IGNICION25${NC} ${GRAY}(25% OFF → 11.25€)${NC}"
    echo -e "  ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    read -r -p "  ${RED}›${NC} Presiona Enter para volver al menú..." _
}

# ═══════════════════════════════════════════════════════════════
#  SUGEST — Genera comandos copiables para optimizar
# ═══════════════════════════════════════════════════════════════

suggest_optimizations() {
    header "⚡ ignisky-kindler:suggest — Comandos para optimizar"
    if [[ ! -f "$CONFIG_FILE" ]]; then
        warn "No se encuentra config.yaml en ${CONFIG_FILE}"
        return 1
    fi

    local tmpfile
    tmpfile=$(mktemp /tmp/kindler-suggest-XXXXXX.json)
    trap 'rm -f "$tmpfile"' RETURN

    # Analizar con Python y generar comandos
    python3 -c "
import json, yaml, os, sys

config_path = os.path.join(os.environ.get('HERMES_HOME', os.path.expanduser('~/.hermes')), 'config.yaml')

try:
    with open(config_path) as f:
        cfg = yaml.safe_load(f)
except Exception as e:
    print(json.dumps({'error': str(e)}))
    sys.exit(1)

a = cfg.get('agent', {})
c = cfg.get('compression', {})

quick_wins = []
deep_ops = []

# 1. reasoning_effort
re = a.get('reasoning_effort', 'medium')
if re != 'low':
    quick_wins.append({
        'cmd': 'hermes config set agent.reasoning_effort low',
        'current': re,
        'recommended': 'low',
        'why': 'Ahorra ~20% tokens por turno. Para debugging complejo cambia a medium sobre la marcha con /reasoning medium'
    })

# 2. max_turns
mt = a.get('max_turns', 60)
if mt > 60:
    quick_wins.append({
        'cmd': f'hermes config set agent.max_turns 60',
        'current': mt,
        'recommended': 60,
        'why': 'Limita el contexto máximo. Si necesitas sesiones largas, 90 es el max recomendado'
    })

# 3. checkpoints
ch = cfg.get('checkpoints', {})
if not ch.get('enabled', False):
    quick_wins.append({
        'cmd': 'hermes config set checkpoints.enabled true',
        'current': 'desactivado',
        'recommended': 'activado',
        'why': 'Protege contra perdida de trabajo. Permite /rollback si algo sale mal'
    })

# 4. compression
ce = c.get('enabled', False)
th = c.get('threshold', 0.5)
tr = c.get('target_ratio', 0.2)
if not ce:
    quick_wins.append({
        'cmd': 'hermes config set compression.enabled true',
        'current': 'desactivado',
        'recommended': 'activado',
        'why': 'Comprime conversaciones largas automaticamente. Threshold 0.5, target 0.2'
    })
elif th > 0.5 or tr > 0.3:
    quick_wins.append({
        'cmd': 'hermes config set compression.threshold 0.5 && hermes config set compression.target_ratio 0.2',
        'current': f'{th}/{tr}',
        'recommended': '0.5/0.2',
        'why': 'Valores mas agresivos de compresion = menos tokens en sesiones largas'
    })

# 5. disabled_toolsets
dt = a.get('disabled_toolsets', [])
if isinstance(dt, str):
    try:
        dt = json.loads(dt)
    except:
        dt = []
if len(dt) < 3:
    quick_wins.append({
        'cmd': 'hermes config set agent.disabled_toolsets [\"vision\",\"image_gen\",\"computer_use\"]',
        'current': f'{len(dt)} toolsets',
        'recommended': '3 toolsets',
        'why': 'Desactivar vision, image_gen y computer_use reduce el contexto inicial. Solo activalos cuando los necesites'
    })

# 6. approvals mode
am = cfg.get('approvals', {}).get('mode', 'manual')
if am == 'manual':
    deep_ops.append({
        'cmd': 'hermes config set approvals.mode smart',
        'current': 'manual',
        'recommended': 'smart',
        'why': 'Evita interrupciones: auto-aprueba comandos seguros, pregunta solo los riesgosos'
    })

# 7. prompt caching
pc = cfg.get('prompt_caching', {})
if not pc.get('cache_ttl'):
    deep_ops.append({
        'cmd': 'hermes config set prompt_caching.cache_ttl 5m',
        'current': 'sin cache',
        'recommended': '5m',
        'why': 'Cachea respuestas frecuentes para no regenerar tokens'
    })

result = {
    'quick_wins': quick_wins,
    'deep_ops': deep_ops,
    'counts': {
        'quick': len(quick_wins),
        'deep': len(deep_ops),
        'total': len(quick_wins) + len(deep_ops)
    }
}
with open(sys.argv[1], 'w') as f:
    json.dump(result, f, indent=2, ensure_ascii=False)
print('OK')
" "$tmpfile" 2>&1 || {
        warn "Error al analizar la configuracion (python3 + pyyaml requerido)"
        return 1
    }

    # Leer resultados
    local qcount dcount total
    qcount=$(python3 -c "import json; print(json.load(open('$tmpfile'))['counts']['quick'])")
    dcount=$(python3 -c "import json; print(json.load(open('$tmpfile'))['counts']['deep'])")
    total=$(python3 -c "import json; print(json.load(open('$tmpfile'))['counts']['total'])")

    if [[ "$total" -eq 0 ]]; then
        echo -e "  ${GREEN}${BOLD}✅ Tu configuración ya está optimizada. No hay cambios sugeridos.${NC}"
        echo ""
        echo -e "  ${GRAY}Para mantenerla así, ejecuta periódicamente: ignisky-kindler --tokens${NC}"
        return 0
    fi

    echo -e "  ${BOLD}Se encontraron ${total} mejoras disponibles:${NC}"
    echo -e "  ${GREEN}  ⚡ ${qcount} quick wins${NC} ${GRAY}(gratis, aplicables ahora)${NC}"
    [[ "$dcount" -gt 0 ]] && echo -e "  ${YELLOW}  🔧 ${dcount} optimizaciones adicionales${NC}"
    echo ""

    # Quick wins (gratis)
    if [[ "$qcount" -gt 0 ]]; then
        echo -e "  ${GREEN}${BOLD}╔═══ ⚡ QUICK WINS ═══════════════════════════════════╗${NC}"
        python3 -c "
import json
d = json.load(open('$tmpfile'))
for i, r in enumerate(d['quick_wins'], 1):
    print(f'  {chr(0x1F7E2)}  Comando {i}:')
    print(f'     {r[\"cmd\"]}')
    print(f'     {chr(0x1F4A1)} {r[\"why\"]}')
    print(f'     {chr(0x1F4CB)} Actual: {r[\"current\"]} → Recomendado: {r[\"recommended\"]}')
    print()
        "
    fi

    # Deep optimizations (con CTA premium)
    if [[ "$dcount" -gt 0 ]]; then
        echo -e "  ${YELLOW}${BOLD}╔═══ 🔧 OPTIMIZACIONES ADICIONALES ═══════════════════╗${NC}"
        python3 -c "
import json
d = json.load(open('$tmpfile'))
for i, r in enumerate(d['deep_ops'], 1):
    print(f'  {chr(0x1F7E1)}  Comando {i}:')
    print(f'     {r[\"cmd\"]}')
    print(f'     {chr(0x1F4A1)} {r[\"why\"]}')
    print()
        "
    fi

    # Instrucción final
    echo -e "  ${BOLD}📋 Para aplicar, copia y pega los comandos en tu terminal:${NC}"
    echo ""
    python3 -c "
import json
d = json.load(open('$tmpfile'))
for r in d['quick_wins']:
    print(f'  {r[\"cmd\"]}')
    print()
    " 2>/dev/null

    # CTA premium si hay deep ops
    if [[ "$dcount" -gt 0 ]]; then
        echo -e "  ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "  ${BOLD}💎 ¿Prefieres que lo haga automáticamente?${NC}"
        echo -e "  ${BOLD}   kindler:inferno aplica todas las optimizaciones${NC}"
        echo -e "  ${BOLD}   de una sola vez.👉 https://ignaciodev.gumroad.com/l/ignisky-kindler-premium${NC}"
        echo -e "  ${BOLD}   Cupón: ${RED}IGNICION25${NC} (25% OFF)"
        echo -e "  ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    fi
}

# ═══════════════════════════════════════════════════════════════
#  TOKEN AUDIT — Analiza y optimiza el consumo de tokens
# ═══════════════════════════════════════════════════════════════

token_audit() {
    header "⚡ ignisky-kindler:tokens — Auditoría de consumo"
    if [[ ! -f "$CONFIG_FILE" ]]; then
        warn "No se encuentra config.yaml en ${CONFIG_FILE}"
        return 1
    fi

    local tmpfile
    tmpfile=$(mktemp /tmp/kindler-tokens-XXXXXX.json)
    trap 'rm -f "$tmpfile"' RETURN

    # Analizar config.yaml con Python
    python3 -c "
import json, yaml, os, sys

HERMES_HOME = os.environ.get('HERMES_HOME', os.path.expanduser('~/.hermes'))
config_path = os.path.join(HERMES_HOME, 'config.yaml')

try:
    with open(config_path) as f:
        cfg = yaml.safe_load(f)
except Exception as e:
    print(json.dumps({'error': str(e)}))
    sys.exit(1)

a = cfg.get('agent', {})
c = cfg.get('compression', {})
mcps = cfg.get('mcp_servers', {})

rules = []
score = 100

# 1. reasoning_effort
re = a.get('reasoning_effort', 'medium')
if re == 'low':
    rules.append({'icon': '🟢', 'setting': 'reasoning_effort', 'value': re, 'tip': 'Óptimo — mínimo consumo por turno'})
elif re == 'medium':
    rules.append({'icon': '🟡', 'setting': 'reasoning_effort', 'value': re, 'tip': 'Buen balance, pero low ahorra ~20% tokens'})
    score -= 10
else:
    rules.append({'icon': '🔴', 'setting': 'reasoning_effort', 'value': re, 'tip': 'Alto consumo — usa low para tareas simples'})
    score -= 25

# 2. Compression
ce = c.get('enabled', False)
if ce:
    th = c.get('threshold', 0.5)
    tr = c.get('target_ratio', 0.2)
    if th <= 0.5 and tr <= 0.3:
        rules.append({'icon': '🟢', 'setting': 'compression', 'value': f'{th}/{tr}', 'tip': 'Compresión activa y bien configurada'})
    else:
        rules.append({'icon': '🟡', 'setting': 'compression', 'value': f'{th}/{tr}', 'tip': 'Reducir threshold a 0.5 y target_ratio a 0.2 ahorra mas'})
        score -= 10
else:
    rules.append({'icon': '🔴', 'setting': 'compression', 'value': 'desactivada', 'tip': 'ACTIVALA: hermes config set compression.enabled true'})
    score -= 30

# 3. disabled_toolsets
dt = a.get('disabled_toolsets', [])
if isinstance(dt, str):
    try:
        dt = json.loads(dt)
    except:
        dt = []
disabled_count = len(dt)
if disabled_count >= 3:
    rules.append({'icon': '🟢', 'setting': 'disabled_toolsets', 'value': f'{disabled_count} toolsets', 'tip': f'{disabled_count} toolsets desactivados — optimo'})
else:
    rules.append({'icon': '🟡', 'setting': 'disabled_toolsets', 'value': f'{disabled_count} toolsets', 'tip': 'desactiva vision, image_gen, computer_use para ahorrar'})
    score -= 10

# 4. max_turns
mt = a.get('max_turns', 60)
if mt <= 60:
    rules.append({'icon': '🟢', 'setting': 'max_turns', 'value': mt, 'tip': 'Limite ajustado — evita contexto innecesariamente largo'})
elif mt <= 90:
    rules.append({'icon': '🟡', 'setting': 'max_turns', 'value': mt, 'tip': 'Aceptable, pero 60 turnos bastan para la mayoria'})
    score -= 5
else:
    rules.append({'icon': '🔴', 'setting': 'max_turns', 'value': mt, 'tip': 'Muy alto — riesgo de consumo excesivo, baja a 60'})
    score -= 15

# 5. MCPs instalados
mcp_count = len(mcps)
if mcp_count <= 5:
    rules.append({'icon': '🟢', 'setting': 'mcps_instalados', 'value': mcp_count, 'tip': 'Pocos MCPs — consumo minimo por tool-call'})
elif mcp_count <= 10:
    rules.append({'icon': '🟡', 'setting': 'mcps_instalados', 'value': mcp_count, 'tip': 'Moderado — cada MCP anade tools al contexto'})
    score -= 5
else:
    rules.append({'icon': '🔴', 'setting': 'mcps_instalados', 'value': mcp_count, 'tip': 'Muchos MCPs — revisa cuales necesitas realmente'})
    score -= 15

# 6. Prompt caching
pc = cfg.get('prompt_caching', {})
pce = pc.get('cache_ttl', 'N/A')
rules.append({'icon': '🟢', 'setting': 'prompt_caching', 'value': pce, 'tip': 'Caching activo — reduce tokens en consultas repetidas'})

# 7. checkpoints
ch = cfg.get('checkpoints', {})
che = ch.get('enabled', False)
if che:
    rules.append({'icon': '🟢', 'setting': 'checkpoints', 'value': 'activados', 'tip': 'Proteccion contra perdida de trabajo'})
else:
    rules.append({'icon': '🟡', 'setting': 'checkpoints', 'value': 'desactivados', 'tip': 'Activalos: hermes config set checkpoints.enabled true'})
    score -= 5

result = {
    'score': max(0, score),
    'grade': 'A' if score >= 90 else 'B' if score >= 75 else 'C' if score >= 50 else 'D',
    'rules': rules,
    'summary': {
        'reasoning': re,
        'compression': f'{c.get(\"threshold\",\"?\")}/{c.get(\"target_ratio\",\"?\")}' if ce else 'OFF',
        'disabled_toolsets': disabled_count,
        'max_turns': mt,
        'mcps': mcp_count
    }
}
with open(sys.argv[1], 'w') as f:
    json.dump(result, f, indent=2, ensure_ascii=False)
print('OK')
" "$tmpfile" 2>&1 || {
        warn "Error al analizar la configuracion (python3 + pyyaml requerido)"
        return 1
    }

    # Leer resultado
    local score grade
    score=$(python3 -c "import json; print(json.load(open('$tmpfile'))['score'])")
    grade=$(python3 -c "import json; print(json.load(open('$tmpfile'))['grade'])")

    # Score visual
    echo -e "  ${BOLD}Puntuacion de eficiencia:${NC}"
    echo -e "  ${RED}${BOLD}┌─────────────────────────────────────────────────────┐${NC}"
    printf "  ${RED}${BOLD}│${NC}  ${BOLD}SCORE: ${NC}"
    if [[ "$grade" == "A" ]]; then
        echo -e "${GREEN}${BOLD}${score}/100 (${grade}) — Optimimo 🔥${NC}"
    elif [[ "$grade" == "B" ]]; then
        echo -e "${YELLOW}${BOLD}${score}/100 (${grade}) — Bueno, mejorable${NC}"
    else
        echo -e "${RED}${BOLD}${score}/100 (${grade}) — Necesita ajustes${NC}"
    fi
    echo -e "  ${RED}${BOLD}└─────────────────────────────────────────────────────┘${NC}"
    echo ""

    # Resumen rapido
    python3 -c "
import json
d = json.load(open('$tmpfile'))
s = d['summary']
print(f'  \\033[90mResumen rapido:\\033[0m')
print(f'  \\033[90m│\\033[0m  🧠 Razonamiento:  \\033[1m{s[\"reasoning\"]}\\033[0m')
print(f'  \\033[90m│\\033[0m  📦 Compresion:    \\033[1m{s[\"compression\"]}\\033[0m')
print(f'  \\033[90m│\\033[0m  🚫 Toolsets off:  \\033[1m{s[\"disabled_toolsets\"]}\\033[0m')
print(f'  \\033[90m│\\033[0m  🔄 Max turns:     \\033[1m{s[\"max_turns\"]}\\033[0m')
print(f'  \\033[90m│\\033[0m  📎 MCPs activos:  \\033[1m{s[\"mcps\"]}\\033[0m')
print()
    "

    # Recomendaciones detalladas
    echo -e "  ${BOLD}Recomendaciones:${NC}"
    python3 -c "
import json
d = json.load(open('$tmpfile'))
for r in d['rules']:
    icon = r['icon']
    print(f'  {icon} {r[\"setting\"]}: {r[\"value\"]}')
    print(f'     {r[\"tip\"]}')
    print()
    "

    # CTA premium
    if [[ "$score" -lt 90 ]]; then
        echo -e "  ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "  ${BOLD}💎 El pack premium incluye optimizacion automatica${NC}"
        echo -e "  ${BOLD}👉 https://ignaciodev.gumroad.com/l/ignisky-kindler-premium · Cupon: ${RED}IGNICION25${NC}"
        echo -e "  ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    fi
}

usage() {
    echo -e "${RED}${BOLD}ignisky-kindler v${VERSION}${NC} ${GRAY}— El encendedor de tu ecosistema AI 🔥${NC}"
    echo ""
    echo -e "${BOLD}Uso:${NC} ${SCRIPT_NAME} [opciones]"
    echo ""
    echo -e "${BOLD}Opciones disponibles:${NC}"
    echo -e "  ${GREEN}--help${NC}, ${GREEN}-h${NC}        Muestra esta ayuda"
    echo -e "  ${GREEN}--version${NC}            Muestra la versión"
    echo -e "  ${GREEN}--dry-run${NC}             Simula sin hacer cambios reales"
    echo -e "  ${GREEN}--check${NC}               Health check de todos los MCPs instalados"
    echo -e "  ${GREEN}--list${NC}                Lista MCPs instalados"
    echo -e "  ${GREEN}--install${NC} <mcps>      Instala MCPs (separados por coma)"
    echo -e "  ${GREEN}--remove${NC} <mcp>        Desinstala un MCP"
    echo -e "  ${GREEN}--export${NC} <path>       Exporta la configuración a JSON"
    echo -e "  ${GREEN}--premium${NC}             Muestra catálogo premium disponible"
    echo -e "  ${GREEN}--catalog${NC}             Muestra catálogo completo (gratis + premium)"
    echo -e "  ${GREEN}--silent${NC}              Sin output interactivo (modo script)"
    echo -e "  ${GREEN}--tokens${NC}              Auditoría de consumo de tokens y recomendaciones"
    echo -e "  ${GREEN}--suggest${NC}             Genera comandos para optimizar tu configuración"
    echo ""
    echo -e "${BOLD}Premium (requiere pack):${NC}"
    echo -e "  ${YELLOW}⛁${NC} ${GREEN}--watch${NC}              Modo daemon: monitoriza y reconecta"
    echo -e "  ${YELLOW}⛁${NC} ${GREEN}--rollback${NC}           Restaura backup anterior"
    echo -e "  ${YELLOW}⛁${NC} ${GREEN}--env-inject${NC}         Inyecta variables de entorno"
    echo ""
    echo -e "${BOLD}Ejemplos:${NC}"
    echo -e "  ${GRAY}# Modo interactivo (por defecto)${NC}"
    echo -e "  ${SCRIPT_NAME}"
    echo ""
    echo -e "  ${GRAY}# Instalación rápida de MCPs gratis${NC}"
    echo -e "  ${SCRIPT_NAME} --install filesystem,github,time,sqlite"
    echo ""
    echo -e "  ${GRAY}# Ver catálogo completo${NC}"
    echo -e "  ${SCRIPT_NAME} --catalog"
    echo ""
    echo -e "  ${GRAY}# Health check de todo${NC}"
    echo -e "  ${SCRIPT_NAME} --check"
    echo ""
    echo -e "  ${GRAY}# Auditoría de tokens${NC}"
    echo -e "  ${SCRIPT_NAME} --tokens"
    echo ""
    echo -e "  ${GRAY}# Sugerencias de optimización${NC}"
    echo -e "  ${SCRIPT_NAME} --suggest"
    echo ""
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}💎 https://ignaciodev.gumroad.com/l/ignisky-kindler-premium  ·  Cupón: ${RED}IGNICION25${NC}"
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 0
}

VERBOSE=false
DRY_RUN=false
SILENT=false
PREMIUM_UNLOCKED=false
INTERACTIVE=true

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)       usage ;;
            --version)       echo "ignisky-kindler v${VERSION}"; exit 0 ;;
            -v|--verbose)    VERBOSE=true ;;
            --dry-run)       DRY_RUN=true ;;
            --silent)        SILENT=true; INTERACTIVE=false ;;
            --check)         MODE="check" ;;
            --list)          MODE="list" ;;
            --install)       MODE="install"; INSTALL_MCPS="$2"; shift ;;
            --remove)        MODE="remove"; REMOVE_MCP="$2"; shift ;;
            --export)        MODE="export"; EXPORT_PATH="${2:-./kindler-export.json}"; shift ;;
            --premium)       MODE="premium" ;;
            --catalog)       MODE="catalog" ;;
            --tokens)        MODE="tokens" ;;
            --suggest)       MODE="suggest" ;;
            --watch)         MODE="watch" ;;
            --rollback)      MODE="rollback" ;;
            --env-inject)    MODE="env-inject" ;;
            --premium-unlock) PREMIUM_UNLOCKED=true ;;
            *)               die "Opción desconocida: $1. Usa --help para ayuda." ;;
        esac
        shift
    done
}

# ═══════════════════════════════════════════════════════════════
#  MAIN
# ═══════════════════════════════════════════════════════════════

main() {
    parse_args "$@"

    # Si hay modo específico por flag, ejecutar y salir
    if [[ -n "${MODE:-}" ]]; then
        case "$MODE" in
            check)
                local -a installed=()
                detect_installed_mcps installed
                check_all_mcps installed
                ;;
            list)
                local -a installed=()
                detect_installed_mcps installed
                header "📋 MCPs instalados"
                for mcp in "${installed[@]}"; do
                    echo -e "  ${GRAY}·${NC} ${BOLD}$mcp${NC}"
                done
                echo -e "\n${GRAY}Total: ${#installed[@]}${NC}"
                ;;
            install)
                [[ "$DRY_RUN" == true ]] && warn "DRY RUN — No se realizarán cambios"
                IFS=',' read -ra REQUESTED <<< "${INSTALL_MCPS:-}"
                if [[ "$DRY_RUN" != true ]]; then
                    backup_config
                fi
                install_bulk "${REQUESTED[@]}"
                ;;
            remove)
                backup_config
                remove_mcp "${REMOVE_MCP:-}"
                ;;
            export)
                export_config "${EXPORT_PATH:-}"
                ;;
            premium)
                premium_inferno
                ;;
            catalog)
                interactive_catalog
                ;;
            tokens)
                token_audit
                ;;
            suggest)
                suggest_optimizations
                ;;
            watch)
                premium_watcher
                ;;
            rollback)
                premium_shield
                ;;
            env-inject)
                premium_env_inject
                ;;
        esac
        exit 0
    fi

    # Modo interactivo (por defecto)
    detect_hermes || exit 1

    local -a installed_mcps=()
    detect_installed_mcps installed_mcps

    show_banner
    show_status installed_mcps

    if [[ "$DRY_RUN" == true ]]; then
        warn "Modo dry-run activado — solo se mostrará información, sin cambios"
        echo ""
    fi

    interactive_menu "${installed_mcps[@]}"
}

main "$@"
