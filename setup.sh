#!/data/data/com.termux/files/usr/bin/bash

LINKS=(
"https://files.zetsu.lol/f/21a077e7-0551-4ed7-a817-d61ef6220fb6"
"https://files.zetsu.lol/f/137a6350-3255-4882-8127-6ba19329010e"
"https://files.zetsu.lol/f/a293aa85-1b6b-4054-8498-2f92cb816688"
"https://files.zetsu.lol/f/e6d92c49-cd0d-479d-b091-11f23b067f09"
)

if ! su -c id 2>/dev/null | grep -q "uid=0"; then
  echo "[!] Root tidak terdeteksi / izin su ditolak"; exit 1
fi

# 1. Aktifkan Opsi Pengembang (setara tap nomor build)
echo "[1/5] Aktifkan opsi pengembang..."
su -c 'settings put global development_settings_enabled 1'
sleep 1

# 2. Matikan skala animasi
echo "[2/5] Matikan animasi..."
su -c '
settings put global window_animation_scale 0
settings put global transition_animation_scale 0
settings put global animator_duration_scale 0
'

# 3. Smallest width 960dp
echo "[3/5] Atur smallest width 960dp..."
SIZE=$(su -c "wm size" | grep -oE '[0-9]+x[0-9]+' | tail -1)
W=${SIZE%x*}; H=${SIZE#*x}
[ "$H" -lt "$W" ] && W=$H
DENSITY=$((W * 160 / 960))
su -c "wm density $DENSITY"
echo "    density = $DENSITY"

# 4. Aktifkan 4 toggle
echo "[4/5] Aktifkan toggle..."
su -c '
settings put global force_allow_on_external 1
settings put global force_resizable_activities 1
settings put global enable_freeform_support 1
settings put global force_desktop_mode_on_external_displays 1
'

# 5. Download & install APK
echo "[5/5] Download & install APK..."
command -v curl >/dev/null || pkg install -y curl

i=0
for URL in "${LINKS[@]}"; do
  i=$((i+1))
  DL="$HOME/app_$i.apk"
  TMP="/data/local/tmp/app_$i.apk"

  echo "  ($i/${#LINKS[@]}) Download..."
  if ! curl -L --fail -o "$DL" "$URL"; then
    echo "  [!] Download $i gagal, lanjut"; continue
  fi

  if [ "$(head -c 2 "$DL")" != "PK" ]; then
    echo "  [!] File $i bukan APK valid, dilewati"; rm -f "$DL"; continue
  fi

  echo "  Install $i..."
  su -c "cp '$DL' '$TMP' && chmod 644 '$TMP' && pm install -r -d -g '$TMP'; rm -f '$TMP'"
  rm -f "$DL"
done

echo "[✓] Selesai. Reboot jika freeform/desktop mode belum aktif."
