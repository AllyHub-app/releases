# Wydania AllyHub — tylko paczki

To repozytorium nie zawiera kodu źródłowego. Są tu wyłącznie gotowe paczki
AllyHub — aplikacji i publicznych wtyczek — żeby można je było pobrać
i aktualizować bez konta GitHub. Opis i instrukcja instalacji:
**https://iseno.net/allyhub**

## Co tu jest

- **Wydania** z tagami `<składnik>-v<wersja>`:
  - `app-v…` — aplikacja: `AllyHub-macos.zip` (macOS 15+, Apple Silicon i Intel,
    podpis Developer ID, notaryzacja Apple), programy dla serwera Linux
    (`allyhub-hostd-linux-*`, `ahctl-linux-*`, archiwa) i `install-linux.sh`;
  - `plugin-<nazwa>-v…` — publiczne wtyczki: Komputer, Hasła (KeepHome),
    Formularze, Zadania, Miejsca, Dashboardy, Docker.
- `latest.json` — indeks najnowszych wersji (z niego korzystają automatyczne
  aktualizacje aplikacji i demona),
- `catalog.json` — katalog publicznych wtyczek.

Najnowsza aplikacja zawsze pod tym samym adresem:

- macOS: https://github.com/AllyHub-app/releases/releases/latest/download/AllyHub-macos.zip
- Linux (serwer, bez interfejsu):
  `curl -fsSL https://github.com/AllyHub-app/releases/releases/latest/download/install-linux.sh | bash`

## Bezpieczeństwo

Każde wydanie ma `SHA256SUMS` z sumami wszystkich plików i jego podpis Ed25519
(`SHA256SUMS.sig`). AllyHub instaluje aktualizacje (aplikacji, demona i wtyczek)
tylko wtedy, gdy podpis zgadza się z kluczem wbudowanym w aplikację — paczki
podmienionej w tym repozytorium nie przyjmie. Na Macu nowa wersja musi mieć
dodatkowo ten sam podpis kodu (Developer ID) co zainstalowana.

Klucz publiczny wydań (Ed25519, base64):

```
iJQSqoWt57TbSNVa5Q7ag6acYLg14AiyQPSmhE9m8Ms=
```

Ręczne sprawdzenie (OpenSSL 3+):

```sh
printf -- '-----BEGIN PUBLIC KEY-----\nMCowBQYDK2VwAyEAiJQSqoWt57TbSNVa5Q7ag6acYLg14AiyQPSmhE9m8Ms=\n-----END PUBLIC KEY-----\n' > allyhub.pub
openssl pkeyutl -verify -pubin -inkey allyhub.pub -rawin -in SHA256SUMS -sigfile SHA256SUMS.sig
shasum -a 256 -c SHA256SUMS --ignore-missing
```

Wydania trafiają tu automatycznie z CI po wydaniu w (prywatnych) repozytoriach
źródłowych — te same pliki, te same sumy i podpisy.
