#!/bin/sh
# Instalacja albo aktualizacja AllyHub na Macu jedną komendą:
#
#   curl -fsSL https://raw.githubusercontent.com/AllyHub-app/releases/main/install-mac.sh | sh
#
# Pobiera najnowszą aplikację (wersja z latest.json), sprawdza sumę SHA-256
# z wydania, podpis Developer ID (zespół RN9B242GHX) i notaryzację Apple,
# zamyka AllyHub i jego demona, podmienia /Applications/AllyHub.app
# i uruchamia aplikację. Przydaje się też, gdy aplikacja wisi na
# „Łączę z demonem urządzenia”.
#
# Uwaga: zamknięcie demona kończy procesy w otwartych terminalach AllyHub
# na tym Macu (karty wracają po starcie; sesje w tmux przetrwają).
#
#   sh install-mac.sh --check   tylko pobiera i sprawdza, niczego nie zmienia
set -eu

REPO="AllyHub-app/releases"
TEAM="RN9B242GHX"
DEST="/Applications/AllyHub.app"
CHECK=0
[ "${1:-}" = "--check" ] && CHECK=1

say() { printf '%s\n' "$*"; }
die() { printf 'Błąd: %s\n' "$*" >&2; exit 1; }

[ "$(uname -s)" = "Darwin" ] || die "ten skrypt jest dla macOS (serwer Linux: install-linux.sh)"

tmp=$(mktemp -d /tmp/allyhub-install.XXXXXX)
trap 'rm -rf "$tmp"' EXIT

# Wersja aplikacji z indeksu wydań (najnowsze wydanie w repo bywa wtyczką).
curl -fsSL "https://raw.githubusercontent.com/$REPO/main/latest.json" -o "$tmp/latest.json" ||
	die "nie udało się pobrać latest.json"
tag=$(plutil -extract components.app.tag raw -o - "$tmp/latest.json" 2>/dev/null) || die "brak wersji aplikacji w latest.json"
version=$(plutil -extract components.app.version raw -o - "$tmp/latest.json")
base="https://github.com/$REPO/releases/download/$tag"

say "==> AllyHub $version — pobieram"
curl -fSL --progress-bar "$base/AllyHub-macos.zip" -o "$tmp/AllyHub-macos.zip" || die "nie udało się pobrać AllyHub-macos.zip"
curl -fsSL "$base/SHA256SUMS" -o "$tmp/SHA256SUMS" || die "nie udało się pobrać SHA256SUMS"

say "==> Sprawdzam sumę, podpis i notaryzację"
want=$(awk '$2 == "AllyHub-macos.zip" || $2 == "*AllyHub-macos.zip" { print $1 }' "$tmp/SHA256SUMS")
got=$(shasum -a 256 "$tmp/AllyHub-macos.zip" | awk '{ print $1 }')
[ -n "$want" ] && [ "$want" = "$got" ] || die "suma SHA-256 się nie zgadza — paczka uszkodzona albo podmieniona"
ditto -x -k "$tmp/AllyHub-macos.zip" "$tmp/x" || die "nie udało się rozpakować paczki"
app="$tmp/x/AllyHub.app"
[ -d "$app" ] || die "w paczce nie ma AllyHub.app"
codesign --verify --deep --strict "$app" 2>/dev/null || die "podpis aplikacji jest nieprawidłowy"
codesign -dv "$app" 2>&1 | grep -q "^TeamIdentifier=$TEAM\$" || die "aplikacja nie jest podpisana przez zespół $TEAM"
spctl --assess --type execute "$app" 2>/dev/null || die "macOS nie przyjmuje aplikacji (brak notaryzacji)"

if [ "$CHECK" = 1 ]; then
	say "OK: AllyHub $version pobrany i sprawdzony (tryb --check — niczego nie zmieniono)"
	exit 0
fi

say "==> Zamykam AllyHub i demona"
osascript -e 'quit app "AllyHub"' >/dev/null 2>&1 || true
sleep 2
pkill -x AllyHub 2>/dev/null || true
pkill -f "AllyHub.app/Contents/MacOS/allyhub-hostd" 2>/dev/null || true
sleep 1
rm -f "$HOME/Library/Application Support/AllyHub/hostd.sock"

say "==> Instaluję w $DEST"
if [ -w "$(dirname "$DEST")" ] && { [ ! -e "$DEST" ] || [ -w "$DEST" ]; }; then
	rm -rf "$DEST" && ditto "$app" "$DEST"
else
	say "(potrzebne hasło administratora)"
	sudo rm -rf "$DEST" && sudo ditto "$app" "$DEST"
fi

open "$DEST"
say "Gotowe: AllyHub $version uruchomiony."
