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
- Optionally waits for the server's SMB port to answer before mounting, so a NAS that boots slower than the client does not leave the mount failed. See [Waiting for a slow server](#waiting-for-a-slow-server).
- Optionally makes other services (Docker, Home Assistant, …) start only after the share is mounted, via a `RequiresMountsFor` drop-in.
- Edit existing mounts: change credentials, SMB protocol version, boot behaviour or dependent services, with `daemon-reload` and live remount.
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
4. Edit a mount — change credentials, SMB version, boot behaviour or dependent services of an existing mount
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
  `RequiresMountsFor=<mount point>`. These drop-ins are removed together with the
  mount by the *Delete a mount* option. See [Picking dependent services](#picking-dependent-services).

Boot behaviour is shown for every mount in the listing, and switching a mount
between modes rewrites the unit and redoes the `systemctl enable` symlinks.

#### What happens when the mount fails

`mount.cifs` has no retry logic of its own. Against a server that is not up yet
it returns an error in **milliseconds** — connection refused, no route to host or
a name that does not resolve — so raising `TimeoutSec=` buys nothing at all: the
mount does not spend that time waiting, it fails immediately and stays failed.

Once the mount unit is `failed`, systemd does not retry it, and every service
with a `RequiresMountsFor` drop-in for that path refuses to start. In both
waiting modes that means the mount is down and Docker (or whatever depends on
it) stays down until someone intervenes. Mode 3 additionally leaves the system
`degraded`. That is what the option below is for.

### Waiting for a slow server

Typical case: after a power cut, a Raspberry Pi finishes booting long before the
NAS it mounts from. When the two waiting boot modes are selected, the wizard
offers to generate a companion unit,
`/etc/systemd/system/smb-wizard-wait-<mount>.service`:

```ini
[Unit]
Description=Wait for SMB server nas.local before mounting /mnt/nas
Requires=network-online.target
After=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
TimeoutStartSec=600
ExecStart=/bin/bash -c 'until timeout 3 bash -c "exec 3<>/dev/tcp/nas.local/445" 2>/dev/null; do sleep 5; done; sleep 3'
```

It polls the server's SMB port (445) every 5 seconds until it answers, then
waits 3 more seconds for the server to settle. The mount unit gains
`Requires=` and `After=` on it, so the mount is only attempted once the server
is actually reachable, and boot holds there in the meantime. The polling uses
bash's `/dev/tcp`, so nothing extra needs to be installed.

`TimeoutStartSec=` is the deadline you choose (default 600 s — 10 minutes). If the
server never shows up within it, the wait service fails, and `Requires=` makes
the mount give up rather than mount against a server known not to answer — the
same failed state as before, but only after a real deadline instead of after a
few milliseconds.

Ten minutes is the default because the scenario this targets is a general power
cut, where the whole chain comes back at once: the modem and router have to
finish before DNS resolves at all, and the server itself is doing a *dirty*
boot — filesystem checks, RAID consistency verification — which can take several
times longer than a clean one. Size the deadline against that, not against a
normal restart.

Waiting that long is cheaper than it sounds: what the wait holds back is
`remote-fs.target` and whatever is ordered after it (Docker, via the drop-in
above). `sshd` does not order itself after `remote-fs.target`, so you normally
keep SSH access to the machine while the wait is pending. Worth confirming on
your own system — `systemctl show sshd -p After | tr ' ' '\n' | grep -c remote-fs`
should print `0`.

The wait loop is also what makes a slow modem harmless. It retries through name
resolution failures, so a hostname that does not resolve yet simply fails one
probe and is tried again 5 seconds later, until the router is back and answering
DNS.

The wait service is removed together with the mount by *Delete a mount*, and can
be added to or removed from an existing mount through *Edit a mount* → *Boot
behaviour*.

### Picking dependent services

The wizard scans the machine for services that plausibly consume a network
share and offers the ones that actually exist, in a checkbox menu — **SPACE**
toggles, digits `1`–`9` toggle, **ENTER** confirms, **ESC** or `q` selects none.
Several can be picked at once:

```
Which services must start only after this mount?
(SPACE toggles, ENTER confirms, ESC selects none)

  > [x] 1) docker.service
    [ ] 2) jellyfin.service
    [x] 3) docker-compose@midia.service
    [ ] 4) Other — type names manually
```

It looks for the common container runtimes and media/home-automation services
(`docker`, `podman`, `jellyfin`, `plexmediaserver`, `emby-server`,
`home-assistant`, `hass`) plus live instances of the usual templates
(`docker-compose@*`, `compose@*`, `podman-compose@*`, `home-assistant@*`). Bare
templates such as `docker-compose@.service` are filtered out, since an
uninstantiated template cannot be started.

Picking **Other** adds a free-text field on top of whatever was checked, so any
unit the scan missed can still be named (several, separated by spaces). If the
scan finds nothing at all, that free-text field is offered directly instead of
the menu.

Prefer a narrow unit over a broad one where you have the choice: a drop-in on
`docker-compose@midia.service` orders just that project behind the mount, while
one on `docker.service` puts every container on this machine behind it.

The selection can be revisited later through *Edit a mount* → *Dependent
services*, without recreating the mount. The menu opens with the currently
configured services already checked, so confirming with ENTER changes nothing;
services configured earlier that the scan does not recognise are listed too, so
editing never silently drops them. The new selection replaces the old one — the
previous drop-ins are removed and the chosen ones written. Since this only
touches other units' drop-ins, the share is not remounted.

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
- Opcionalmente aguarda a porta SMB do servidor responder antes de montar, para que um NAS que liga mais devagar que o cliente não deixe a montagem falhada. Veja [Aguardando um servidor lento](#aguardando-um-servidor-lento).
- Opcionalmente faz outros serviços (Docker, Home Assistant, …) iniciarem só depois que o compartilhamento estiver montado, via drop-in `RequiresMountsFor`.
- Edição de montagens existentes: trocar credenciais, versão do protocolo SMB, comportamento no boot ou serviços dependentes, com `daemon-reload` e remontagem ao vivo.
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
4. Editar uma montagem — troca credenciais, versão SMB, comportamento no boot ou serviços dependentes de uma montagem existente
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
  `RequiresMountsFor=<ponto de montagem>`. Esses drop-ins são removidos junto com
  a montagem pela opção *Excluir uma montagem*. Veja
  [Escolhendo os serviços dependentes](#escolhendo-os-serviços-dependentes).

O comportamento no boot é exibido para cada montagem na listagem, e trocar de
modo reescreve a unidade e refaz os symlinks do `systemctl enable`.

#### O que acontece quando a montagem falha

O `mount.cifs` não tem retentativa própria. Contra um servidor que ainda não
subiu ele retorna erro em **milissegundos** — conexão recusada, sem rota até o
host ou nome que não resolve — então aumentar o `TimeoutSec=` não adianta nada:
a montagem não passa esse tempo esperando, ela falha na hora e fica falhada.

Uma vez que a unidade de montagem está `failed`, o systemd não tenta de novo, e
todo serviço com drop-in `RequiresMountsFor` para aquele caminho se recusa a
iniciar. Nos dois modos de espera isso significa montagem fora do ar e Docker (ou
o que quer que dependa dela) parado até alguém intervir. O modo 3 ainda deixa o
sistema `degraded`. É exatamente para isso que serve a opção abaixo.

### Aguardando um servidor lento

Caso típico: depois de uma queda de energia, um Raspberry Pi termina o boot muito
antes do NAS de onde ele monta. Quando um dos dois modos de espera é escolhido, o
wizard oferece gerar uma unidade acompanhante,
`/etc/systemd/system/smb-wizard-wait-<montagem>.service`:

```ini
[Unit]
Description=Wait for SMB server nas.local before mounting /mnt/nas
Requires=network-online.target
After=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
TimeoutStartSec=600
ExecStart=/bin/bash -c 'until timeout 3 bash -c "exec 3<>/dev/tcp/nas.local/445" 2>/dev/null; do sleep 5; done; sleep 3'
```

Ela sonda a porta SMB do servidor (445) a cada 5 segundos até responder e então
espera mais 3 segundos para o servidor assentar. A unidade de montagem ganha
`Requires=` e `After=` sobre ela, de modo que a montagem só é tentada quando o
servidor está de fato acessível — e o boot fica segurando nesse ponto. A sondagem
usa o `/dev/tcp` do bash, então nada extra precisa ser instalado.

O `TimeoutStartSec=` é o prazo que você escolhe (padrão 600 s — 10 minutos). Se o
servidor não aparecer dentro dele, o serviço de espera falha, e o `Requires=` faz
a montagem desistir em vez de montar contra um servidor que sabidamente não
respondeu — o mesmo estado de falha de antes, mas só depois de um prazo real, e
não depois de alguns milissegundos.

Dez minutos é o padrão porque o cenário alvo é uma queda de energia geral, em que
a cadeia inteira volta junto: o modem e o roteador precisam terminar antes de o
DNS sequer resolver, e o servidor está fazendo um boot *sujo* — checagem de
sistema de arquivos, verificação de consistência do RAID — que pode levar várias
vezes o tempo de um boot limpo. Dimensione o prazo por esse pior caso, não por um
reinício normal.

Esperar tudo isso custa menos do que parece: o que a espera segura é o
`remote-fs.target` e o que vem ordenado depois dele (o Docker, via o drop-in
acima). O `sshd` não se ordena depois do `remote-fs.target`, então você
normalmente mantém acesso SSH à máquina enquanto a espera está pendente. Vale
confirmar no seu sistema — `systemctl show sshd -p After | tr ' ' '\n' | grep -c remote-fs`
deve imprimir `0`.

O loop de espera também é o que torna um modem lento inofensivo. Ele retenta
inclusive quando o nome não resolve, então um hostname ainda sem DNS apenas falha
uma sondagem e é tentado de novo 5 segundos depois, até o roteador voltar e
responder.

O serviço de espera é removido junto com a montagem pela opção *Excluir uma
montagem*, e pode ser adicionado ou retirado de uma montagem existente em
*Editar uma montagem* → *Comportamento no boot*.

### Escolhendo os serviços dependentes

O wizard varre a máquina atrás de serviços que plausivelmente consomem um
compartilhamento de rede e oferece os que existem de fato, num menu de marcação —
**ESPAÇO** marca/desmarca, os dígitos `1`–`9` também alternam, **ENTER** confirma
e **ESC** ou `q` não escolhe nenhum. Dá para marcar vários de uma vez:

```
Quais serviços devem iniciar só depois desta montagem?
(ESPAÇO marca/desmarca, ENTER confirma, ESC não escolhe nenhum)

  > [x] 1) docker.service
    [ ] 2) jellyfin.service
    [x] 3) docker-compose@midia.service
    [ ] 4) Outro — digitar nomes manualmente
```

Ele procura os runtimes de contêiner e serviços de mídia/automação mais comuns
(`docker`, `podman`, `jellyfin`, `plexmediaserver`, `emby-server`,
`home-assistant`, `hass`) e mais as instâncias vivas dos templates usuais
(`docker-compose@*`, `compose@*`, `podman-compose@*`, `home-assistant@*`).
Templates puros como `docker-compose@.service` ficam de fora, já que um template
sem instância não pode ser iniciado.

Marcar **Outro** abre um campo livre por cima do que já foi marcado, então
qualquer unidade que a varredura não pegou ainda pode ser informada (várias,
separadas por espaço). Se a varredura não achar nada, esse campo livre é
oferecido direto, no lugar do menu.

Prefira a unidade mais estreita quando tiver escolha: um drop-in em
`docker-compose@midia.service` ordena só aquele projeto atrás da montagem,
enquanto um em `docker.service` coloca todos os contêineres da máquina atrás
dela.

A escolha pode ser revista depois em *Editar uma montagem* → *Serviços
dependentes*, sem precisar recriar a montagem. O menu abre com os serviços já
configurados marcados, então confirmar com ENTER não muda nada; serviços
configurados antes que a varredura não reconhece também aparecem na lista, de
modo que editar nunca os descarta em silêncio. A nova seleção substitui a
anterior — os drop-ins antigos são removidos e os escolhidos são gravados. Como
isso mexe apenas em drop-ins de outras unidades, o compartilhamento não é
remontado.

### Licença

MIT — veja `LICENSE`.
