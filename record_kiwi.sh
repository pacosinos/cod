#!/usr/bin/env bash
set -Eeuo pipefail

# --- RUTA A KIWIRECORDER ---
KIWI_DIR="${KIWI_DIR:-$HOME/kiwiclient}"
KIWICLIENT_REPO="${KIWICLIENT_REPO:-https://github.com/jks-prv/kiwiclient}"
REC="$KIWI_DIR/kiwirecorder.py"

# --- CONFIG ---
FREQ="${FREQ:-77.50k}"     # DCF77
FS="${FS:-12000}"          # 12000 o 20250 (mismo en todos)
DUR="${DUR:-15}"           # segundos
OUTDIR="${OUTDIR:-$PWD/capturas_kiwi}"
KIWI_PWD="${KIWI_PWD:-}"   # password si el Kiwi lo pide (vacío si no)

# --- TUS TRES KIWI SDR (de tus pantallas) ---
HOSTS=(
  "sdr.gb0snb.com:8073"        # Kelvedon Hatch (GB0SNB)
  "177.ham-radio-op.net:8073"  # Whitstable (G4KJS)
  "msars.ddns.net:8073"        # Mid Sussex ARS
)

if [[ -n "${KIWI_HOSTS:-}" ]]; then
  IFS=',' read -r -a _env_hosts <<< "$KIWI_HOSTS"
  HOSTS=()
  for entry in "${_env_hosts[@]}"; do
    entry="${entry//[[:space:]]/}"
    [[ -n "$entry" ]] && HOSTS+=("$entry")
  done
  unset _env_hosts entry
fi

[[ ${#HOSTS[@]} -gt 0 ]] || { echo "No hay KiwiSDR definidos. Ajusta HOSTS o la variable KIWI_HOSTS."; exit 1; }

# --- COMPROBACIONES ---
command -v python3 >/dev/null 2>&1 || { echo "python3 no está disponible en PATH."; exit 1; }

ensure_kiwirecorder() {
  if [[ -f "$REC" ]]; then
    return
  fi

  if [[ -d "$KIWI_DIR" ]]; then
    if [[ -d "$KIWI_DIR/.git" ]]; then
      echo "Actualizando kiwiclient en $KIWI_DIR..."
      git -C "$KIWI_DIR" pull --ff-only
    else
      echo "No encuentro $REC dentro de $KIWI_DIR. Ajusta KIWI_DIR."
      exit 1
    fi
  else
    command -v git >/dev/null 2>&1 || { echo "No se puede clonar kiwiclient porque git no está disponible."; exit 1; }
    echo "Clonando kiwiclient desde $KIWICLIENT_REPO en $KIWI_DIR..."
    git clone --depth 1 "$KIWICLIENT_REPO" "$KIWI_DIR"
  fi

  [[ -f "$REC" ]] || { echo "No se encontró kiwirecorder.py en $KIWI_DIR tras la instalación."; exit 1; }
}

ensure_kiwirecorder

mkdir -p "$OUTDIR"

# --- Sincroniza al PRÓXIMO minuto UTC ---
now=$(date -u +%s)
start=$(( (now/60 + 1) * 60 ))
wait_time=$(( start - now ))
if (( wait_time > 0 )); then
  sleep "$wait_time"
fi

timestamp=$(date -u +%Y%m%dT%H%M%S)

graba_kiwi () {
  local host_port="$1"
  local host="${host_port%:*}"
  local port="${host_port#*:}"
  local outfile="$OUTDIR/${host//./_}_${timestamp}.wav"

  local args=( -s "$host" -p "$port" -f "$FREQ" -m iq -r "$FS" -w -T "$DUR" -o "$outfile" )
  [[ -n "$KIWI_PWD" ]] && args+=( -P "$KIWI_PWD" )

  echo "[+] $host:$port -> $outfile"
  python3 "$REC" "${args[@]}"
}

pids=()
for hp in "${HOSTS[@]}"; do
  graba_kiwi "$hp" &
  pids+=( "$!" )
  sleep 0.1
done

fail=0
for pid in "${pids[@]}"; do
  if ! wait "$pid"; then
    fail=1
  fi
done

echo
if [[ $fail -eq 0 ]]; then
  echo "✔ Listo. WAV IQ en: $OUTDIR"
else
  echo "⚠ Alguna grabación falló."
fi
