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
- Selectable boot behaviour: let boot continue while the share mounts in the background, or hold the boot until the remote server answers. See [Boot behaviour](#boot-behaviour).
- Optionally makes other services (Docker, Home Assistant, …) start only after the share is mounted, via a `RequiresMountsFor` drop-in.
- Edit existing mounts: change credentials, SMB protocol version or boot behaviour, with `daemon-reload` and live remount.
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
bash <(curl -fsSL https://raw.githubusercontent.com/rogercrocha/smb-wizard-for-linux/v1.1.2/smb-wizard.sh)
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
2. Create a mount — prompts for server, share, mount point, credentials, SMB version and boot behaviour
3. Delete a mount — remove one or all SMB mounts
4. Edit a mount — change credentials, SMB version or boot behaviour of an existing mount
5. Exit

### Boot behaviour

When creating a mount (and from the *Edit a mount* menu, for mounts that already
exist) the wizard asks how boot should treat it. This is aimed at headless boxes —
a Raspberry Pi OS Lite running Home Assistant and other self-hosted apps, for
example — where services started at boot expect the share to already be there.

| Mode | Unit written | What happens at boot |
| --- | --- | --- |
| **Do not wait** (default) | `nofail` + `WantedBy=multi-user.target`, `TimeoutSec=30` | Boot never waits; the mount comes up in the background. Same behaviour as previous versions. |
| **Wait, but continue if it fails** (recommended) | `nofail` + `Before=`/`WantedBy=remote-fs.target`, timeout you choose | Boot waits for the mount attempt to finish, up to the timeout. If the server is down, boot carries on normally. |
| **Wait and require success** | no `nofail` + `Before=`/`RequiredBy=remote-fs.target`, timeout you choose | Boot waits, and a failed mount fails `remote-fs.target`, so the system finishes booting in a `degraded` state. |

For the two waiting modes the wizard also:

- asks for the maximum time to wait (default 90 s, written as `TimeoutSec=`);
- checks that a wait-online service (`NetworkManager-wait-online.service`,
  `systemd-networkd-wait-online.service` or `ifupdown-wait-online.service`) is
  enabled, and offers to enable it. Without it `network-online.target` is
  reached immediately and the mount tends to fail at boot even though the unit
  declares `Requires=network-online.target`;
- makes sure `remote-fs.target` is enabled, since that is the target the mount
  is ordered before;
- optionally asks for services that must start only after the mount, and writes
  `/etc/systemd/system/<service>.d/10-smb-wizard-<mount>.conf` containing
  `RequiresMountsFor=<mount point>`. On Raspberry Pi OS with Docker, answering
  `docker.service` here is usually what you want so containers with bind mounts
  into the share do not start against an empty directory. These drop-ins are
  removed together with the mount by the *Delete a mount* option.

Boot behaviour is shown for every mount in the listing, and switching a mount
between modes rewrites the unit and redoes the `systemctl enable` symlinks.

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
- Comportamento no boot selecionável: deixar o boot seguir enquanto o compartilhamento monta em segundo plano, ou segurar o boot até o servidor remoto responder. Veja [Comportamento no boot](#comportamento-no-boot).
- Opcionalmente faz outros serviços (Docker, Home Assistant, …) iniciarem só depois que o compartilhamento estiver montado, via drop-in `RequiresMountsFor`.
- Edição de montagens existentes: trocar credenciais, versão do protocolo SMB ou comportamento no boot, com `daemon-reload` e remontagem ao vivo.
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
bash <(curl -fsSL https://raw.githubusercontent.com/rogercrocha/smb-wizard-for-linux/v1.1.2/smb-wizard.sh)
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
2. Criar uma montagem — solicita servidor, compartilhamento, ponto de montagem, credenciais, versão SMB e comportamento no boot
3. Excluir uma montagem — remove uma ou todas as montagens SMB
4. Editar uma montagem — troca credenciais, versão SMB ou comportamento no boot de uma montagem existente
5. Sair

### Comportamento no boot

Ao criar uma montagem (e pelo menu *Editar uma montagem*, para montagens que já
existem) o wizard pergunta como o boot deve tratá-la. A ideia é atender máquinas
headless — um Raspberry Pi OS Lite rodando Home Assistant e outros aplicativos
self-hosted, por exemplo — onde os serviços iniciados no boot já esperam
encontrar o compartilhamento montado.

| Modo | Unidade gerada | O que acontece no boot |
| --- | --- | --- |
| **Não esperar** (padrão) | `nofail` + `WantedBy=multi-user.target`, `TimeoutSec=30` | O boot nunca espera; a montagem sobe em segundo plano. Mesmo comportamento das versões anteriores. |
| **Esperar, mas seguir se falhar** (recomendado) | `nofail` + `Before=`/`WantedBy=remote-fs.target`, tempo que você escolher | O boot aguarda a tentativa de montagem terminar, até o tempo limite. Se o servidor estiver fora do ar, o boot segue normalmente. |
| **Esperar e exigir sucesso** | sem `nofail` + `Before=`/`RequiredBy=remote-fs.target`, tempo que você escolher | O boot aguarda e, se a montagem falhar, o `remote-fs.target` falha junto: o sistema termina o boot em estado `degraded`. |

Nos dois modos de espera o wizard também:

- pergunta o tempo máximo de espera (padrão 90 s, gravado como `TimeoutSec=`);
- verifica se há um serviço wait-online (`NetworkManager-wait-online.service`,
  `systemd-networkd-wait-online.service` ou `ifupdown-wait-online.service`)
  habilitado e oferece habilitá-lo. Sem ele o `network-online.target` é atingido
  de imediato e a montagem tende a falhar no boot, mesmo com a unidade
  declarando `Requires=network-online.target`;
- garante que o `remote-fs.target` esteja habilitado, já que é o target antes do
  qual a montagem é ordenada;
- opcionalmente pergunta quais serviços devem iniciar só depois da montagem e
  grava `/etc/systemd/system/<serviço>.d/10-smb-wizard-<montagem>.conf` com
  `RequiresMountsFor=<ponto de montagem>`. No Raspberry Pi OS com Docker,
  responder `docker.service` aqui costuma ser o que você quer, para que
  contêineres com bind mounts para dentro do compartilhamento não subam contra
  um diretório vazio. Esses drop-ins são removidos junto com a montagem pela
  opção *Excluir uma montagem*.

O comportamento no boot é exibido para cada montagem na listagem, e trocar de
modo reescreve a unidade e refaz os symlinks do `systemctl enable`.

### Licença

MIT — veja `LICENSE`.
