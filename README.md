# smb-wizard

[![release](https://img.shields.io/github/v/release/rogercrocha/smb-wizard-for-linux)](https://github.com/rogercrocha/smb-wizard-for-linux/releases)
[![license](https://img.shields.io/github/license/rogercrocha/smb-wizard-for-linux)](LICENSE)
![language](https://img.shields.io/github/languages/top/rogercrocha/smb-wizard-for-linux)

Interactive SMB mount manager for Linux via systemd `.mount` units.
Gerenciador interativo de montagens SMB para Linux via unidades `.mount` do systemd.

---

## English

Bilingual (English / Portuguese) interactive wizard to create, list, edit and delete SMB / CIFS mounts as systemd `.mount` units.

### Features

- Detects the system language from `$LANG` and shows messages in Portuguese or English.
- Detects immutable systems (read-only `/`, e.g. Bazzite, Silverblue, SteamOS) and suggests `/home/<user>/mnt` instead of `/mnt` as the default mount base.
- Arrow-key navigable menus (`↑` / `↓` + ENTER) with numeric shortcuts (digits 1–9) and ESC / `q` to cancel. Falls back to plain numbered input when stdin is not a TTY.
- Generates one systemd `.mount` unit per mount, with credentials stored in a separate `/etc/samba-cred-*.cred` file (mode 0600, owned by root). Credential filenames include the mountpoint, so two different mounts to the same `//server/share` do not collide.
- Pre-flight authentication check with `smbclient` before writing any files. Distinguishes bad credentials, unreachable host and non-existent share with distinct error messages.
- Auth retry loop with attempt counter (3 attempts) to avoid server-side account lockout.
- Automatic rollback if `systemctl enable --now` fails after files were already written.
- Edit existing mounts: change credentials or SMB protocol version, with `daemon-reload` and live remount.
- Cleanup option that removes one or all mounts, with their units, credential files and empty mountpoint directories.

### Dependencies

- `bash` 4+
- `systemd`, `findmnt`, `mount.cifs` (package `cifs-utils`)
- `smbclient` (package `samba-client`) for the pre-flight check; the wizard works without it but skips the check
- `ncurses` (`tput`) for arrow-key menus
- `sudo` rights — the wizard calls `sudo` internally for privileged operations

### Quick install (one-liner)

Run the script directly from GitHub, no cloning needed:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/rogercrocha/smb-wizard-for-linux/v1.1.1/smb-wizard.sh)
```

`bash <(curl ...)` (process substitution) is used instead of `curl ... | bash` so the interactive prompts and the arrow-key menu still work — the pipe form would consume stdin and break input. If you prefer to review the source before running it, use the clone-based installation below.

### Installation

```bash
git clone https://github.com/rogercrocha/smb-wizard-for-linux.git
cd smb-wizard-for-linux
chmod +x smb-wizard.sh
```

### Usage

```bash
bash smb-wizard.sh
```

The interactive menu offers:

1. List mounts — show all SMB mounts configured via the wizard
2. Create a mount — prompts for server, share, mount point, credentials, SMB version
3. Delete a mount — remove one or all SMB mounts
4. Edit a mount — change credentials or SMB version of an existing mount
5. Exit

### License

MIT — see `LICENSE`.

---

## Português

Wizard interativo bilíngue (português / inglês) para criar, listar, editar e excluir montagens SMB / CIFS como unidades `.mount` do systemd.

### Características

- Detecta o idioma do sistema via `$LANG` e mostra mensagens em português ou inglês.
- Detecta sistemas imutáveis (`/` somente-leitura, ex: Bazzite, Silverblue, SteamOS) e sugere `/home/<usuário>/mnt` como base de montagem em vez de `/mnt`.
- Menus navegáveis por setas (`↑` / `↓` + ENTER) com atalhos numéricos (dígitos 1–9) e ESC / `q` para cancelar. Cai em modo de entrada numerada quando stdin não é TTY.
- Gera uma unidade `.mount` por montagem com credenciais em arquivo separado em `/etc/samba-cred-*.cred` (modo 0600, dono root). O nome do arquivo de credencial inclui o ponto de montagem, então duas montagens distintas para `//servidor/share` não colidem.
- Checagem prévia de autenticação com `smbclient` antes de gravar qualquer arquivo. Distingue credenciais erradas, host inacessível e share inexistente.
- Loop de retentativa de autenticação com contador (3 tentativas) para evitar bloqueio de conta no servidor.
- Rollback automático se `systemctl enable --now` falhar depois que os arquivos já foram escritos.
- Edição de montagens existentes: trocar credenciais ou versão do protocolo SMB, com `daemon-reload` e remontagem ao vivo.
- Limpeza removendo uma ou todas as montagens, com suas unidades, arquivos de credencial e diretórios vazios.

### Dependências

- `bash` 4+
- `systemd`, `findmnt`, `mount.cifs` (pacote `cifs-utils`)
- `smbclient` (pacote `samba-client`) para a checagem prévia; o script funciona sem ele mas pula a checagem
- `ncurses` (`tput`) para os menus de seta
- Permissão de `sudo` — o script chama `sudo` internamente para operações privilegiadas

### Instalação rápida (linha única)

Rodar o script direto do GitHub, sem clonar:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/rogercrocha/smb-wizard-for-linux/v1.1.1/smb-wizard.sh)
```

Usamos `bash <(curl ...)` (process substitution) em vez de `curl ... | bash` para que os prompts interativos e o menu de setas continuem funcionando — a forma com pipe ocuparia o stdin e quebraria a entrada do usuário. Se preferir revisar o código antes de rodar, use a instalação por clone abaixo.

### Instalação

```bash
git clone https://github.com/rogercrocha/smb-wizard-for-linux.git
cd smb-wizard-for-linux
chmod +x smb-wizard.sh
```

### Uso

```bash
bash smb-wizard.sh
```

O menu interativo oferece:

1. Listar montagens — mostra todas as montagens SMB configuradas pelo wizard
2. Criar uma montagem — solicita servidor, compartilhamento, ponto de montagem, credenciais, versão SMB
3. Excluir uma montagem — remove uma ou todas as montagens SMB
4. Editar uma montagem — troca credenciais ou versão SMB de uma montagem existente
5. Sair

### Licença

MIT — veja `LICENSE`.
