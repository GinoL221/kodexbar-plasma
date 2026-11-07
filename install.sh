#!/bin/sh
#
# KodexBar Plasma - Automated Installer with NaN Cloud Adapter
# https://github.com/GinoL221/kodexbar-plasma
#

set -eu

REPO_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$REPO_DIR"

printf '\n\033[1;34m=== Instalador de KodexBar Plasma (con NaN Cloud) ===\033[0m\n\n'

# 1. Comprobación de requisitos básicos
printf '1. Comprobando dependencias del sistema...\n'

if ! command -v kpackagetool6 >/dev/null 2>&1; then
    printf '\033[1;31merror: kpackagetool6 no está instalado.\033[0m\n' >&2
    printf 'Instalalo con el gestor de paquetes de tu distribución (parte de KDE Plasma 6 / plasma-framework).\n' >&2
    exit 1
fi
printf '   ✓ kpackagetool6 encontrado\n'

if ! command -v python3 >/dev/null 2>&1; then
    printf '\033[1;31merror: python3 no está instalado.\033[0m\n' >&2
    exit 1
fi
printf '   ✓ python3 encontrado\n'

# Comprobar si existe el binario oficial de codexbar
CODEXBAR_BIN=""
for candidate in "$HOME/.local/bin/codexbar" /usr/local/bin/codexbar /usr/bin/codexbar; do
    if [ -x "$candidate" ]; then
        CODEXBAR_BIN="$candidate"
        break
    fi
done
if [ -z "$CODEXBAR_BIN" ] && command -v codexbar >/dev/null 2>&1; then
    CODEXBAR_BIN=$(command -v codexbar)
fi

if [ -n "$CODEXBAR_BIN" ]; then
    printf '   ✓ CLI oficial de CodexBar encontrada en: %s\n' "$CODEXBAR_BIN"
else
    printf '\033[1;33m   ! Advertencia: No se encontró la CLI oficial de CodexBar en ubicaciones estándar.\033[0m\n'
    printf '     Podés instalarla vía:\n'
    printf '     - Homebrew: brew install steipete/tap/codexbar\n'
    printf '     - O descargando el binario desde: https://github.com/steipete/CodexBar/releases/latest\n'
    printf '     (El widget se instalará de todos modos y la detectará apenas la agregues a ~/.local/bin/codexbar).\n'
fi

# 2. Instalar el adaptador de NaN Cloud
printf '\n2. Instalando el adaptador NaN Cloud (~/.local/bin/codexbar-nan)...\n'
mkdir -p "$HOME/.local/bin" "$HOME/.config/codexbar"
install -m 755 "$REPO_DIR/scripts/codexbar-nan" "$HOME/.local/bin/codexbar-nan"
printf '   ✓ Adaptador instalado con éxito en %s/.local/bin/codexbar-nan\n' "$HOME"

# 3. Configuración de la API Key de NaN Cloud
NAN_KEY_FILE="$HOME/.config/codexbar/nan-api-key"
if [ -f "$NAN_KEY_FILE" ] && [ -s "$NAN_KEY_FILE" ]; then
    chmod 600 "$NAN_KEY_FILE"
    printf '   ✓ Clave de NaN Cloud existente detectada en %s (permisos 600 asegurados)\n' "$NAN_KEY_FILE"
else
    if [ -t 0 ]; then
        printf '\n   ¿Tenés una API Key de NaN Cloud para configurar ahora? [s/N]: '
        read -r respuesta || respuesta="n"
        case "$respuesta" in
            [sS]|[yY])
                printf '   Pegá tu API Key de NaN Cloud (no se mostrará en pantalla): '
                stty -echo 2>/dev/null || true
                read -r nan_key
                stty echo 2>/dev/null || true
                printf '\n'
                if [ -n "$nan_key" ]; then
                    printf '%s\n' "$nan_key" > "$NAN_KEY_FILE"
                    chmod 600 "$NAN_KEY_FILE"
                    printf '   ✓ Clave guardada de forma segura en %s\n' "$NAN_KEY_FILE"
                else
                    printf '   (Entrada vacía; podés agregarla luego en %s)\n' "$NAN_KEY_FILE"
                fi
                ;;
            *)
                printf '   Podés configurar tu clave en cualquier momento guardándola en:\n'
                printf '   %s\n' "$NAN_KEY_FILE"
                ;;
        esac
    else
        printf '   Recordatorio: Guardá tu API key de NaN Cloud en %s con chmod 600\n' "$NAN_KEY_FILE"
    fi
fi

# 4. Instalar o actualizar el applet en KDE Plasma
printf '\n3. Instalando applet en KDE Plasma...\n'
PACKAGE_DIR="$HOME/.local/share/plasma/plasmoids/org.kde.plasma.kodexbar.plasma"

if [ -d "$PACKAGE_DIR" ]; then
    kpackagetool6 -t Plasma/Applet -u "$REPO_DIR" >/dev/null 2>&1 || kpackagetool6 -t Plasma/Applet -i "$REPO_DIR"
    printf '   ✓ Applet actualizado con éxito en %s\n' "$PACKAGE_DIR"
else
    kpackagetool6 -t Plasma/Applet -i "$REPO_DIR"
    printf '   ✓ Applet instalado con éxito en %s\n' "$PACKAGE_DIR"
fi

# 5. Opciones de recarga de plasmashell
printf '\n\033[1;32m=== ¡Instalación completada con éxito! ===\033[0m\n'
printf 'Para añadir el widget a tu panel:\n'
printf '1. Hacé clic derecho en tu panel de Plasma -> "Añadir elementos gráficos..."\n'
printf '2. Buscá "KodexBar Plasma" y arrastralo a la barra de tareas.\n'

RESTART_OPT="${1:-}"
if [ "$RESTART_OPT" = "--restart" ]; then
    printf '\nReiniciando plasmashell...\n'
    nohup plasmashell --replace >/dev/null 2>&1 &
    sleep 2
    printf '✓ plasmashell reiniciado.\n'
elif [ -t 0 ]; then
    printf '\n¿Deseás reiniciar plasmashell ahora para aplicar los cambios al panel? [s/N]: '
    read -r rst || rst="n"
    case "$rst" in
        [sS]|[yY])
            nohup plasmashell --replace >/dev/null 2>&1 &
            sleep 2
            printf '✓ plasmashell reiniciado.\n'
            ;;
    esac
fi

printf '\n'
