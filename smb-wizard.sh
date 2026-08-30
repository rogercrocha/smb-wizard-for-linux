#!/usr/bin/env bash
# smb-wizard.sh
# Gerenciador interativo de montagens SMB via systemd.
# Interactive SMB mount manager via systemd.

set -euo pipefail

UNIT_DIR="/etc/systemd/system"

# ╔══════════════════════════════════════════════════════════════╗
# ║  DETECÇÃO DE IDIOMA / LANGUAGE DETECTION                     ║
# ╚══════════════════════════════════════════════════════════════╝

detect_lang() {
  local lang="${LANG:-${LANGUAGE:-${LC_ALL:-}}}"
  lang="${lang,,}"
  if [[ "$lang" == pt* ]]; then
    echo "pt"
  else
    echo "en"
  fi
}

LANG_CODE="$(detect_lang)"

# ── Strings PT ───────────────────────────────────────────────────────────────
msg_pt() {
  case "$1" in
    title)           echo "Gerenciador de Montagens SMB" ;;
    title_by)        echo "por rogercrocha" ;;
    thanks_line1)    echo "Obrigado por usar o meu script!" ;;
    thanks_line2)    echo "Se achou útil, considere deixar uma estrela no GitHub:" ;;
    menu_list)       echo "Listar montagens" ;;
    menu_create)     echo "Criar uma montagem" ;;
    menu_edit)       echo "Editar uma montagem" ;;
    menu_delete)     echo "Excluir uma montagem" ;;
    menu_exit)       echo "Sair" ;;
    menu_choose)     echo "Escolha [0/1/2/3/4]: " ;;
    press_enter)     echo "Pressione ENTER para continuar..." ;;
    menu_invalid)    echo "Opção inválida." ;;
    leaving)         echo "Saindo." ;;
    no_mounts)       echo "Nenhuma montagem SMB configurada." ;;
    mounts_found)    echo "Montagens SMB configuradas:" ;;
    mounts_avail)    echo "Montagens disponíveis:" ;;
    server_lbl)      echo "Servidor" ;;
    mount_lbl)       echo "Montagem" ;;
    status_lbl)      echo "Status" ;;
    cred_lbl)        echo "Credenciais" ;;
    unit_lbl)        echo "Unidade" ;;
    status_active)   echo "ativo" ;;
    status_failed)   echo "falhou" ;;
    status_inactive) echo "inativo" ;;
    status_unknown)  echo "desconhecido" ;;
    cred_undef)      echo "não definido" ;;
    remove_all)      echo "Remover todas" ;;
    cancel)          echo "Cancelar" ;;
    choose_num)      echo "Escolha [0 / número / T]: " ;;
    cancelled)       echo "Cancelado." ;;
    aborted)         echo "Abortado." ;;
    invalid_opt)     echo "Opção inválida. Abortado." ;;
    will_remove)     echo "O seguinte será removido:" ;;
    confirm_remove)  echo "Confirma a remoção? [y/N]: " ;;
    unmounting)      echo "==> Desmontando..." ;;
    unmounted)       echo "    Desmontado:" ;;
    already_unmnt)   echo "    Já desmontado:" ;;
    unmount_fail)    echo "    Falha ao desmontar:" ;;
    disabling)       echo "==> Desabilitando unidades..." ;;
    disabled)        echo "    Desabilitado:" ;;
    removing_units)  echo "==> Removendo arquivos de unidade..." ;;
    removing_creds)  echo "==> Removendo credenciais..." ;;
    removing_dirs)   echo "==> Removendo diretórios de montagem..." ;;
    removed)         echo "    Removido:" ;;
    ignored_dir)     echo "    Ignorado (não vazio ou inexistente):" ;;
    reloading)       echo "==> Recarregando systemd..." ;;
    done)            echo "Pronto." ;;
    no_cifs)         echo "ERRO: cifs-utils não encontrado. Instale antes de continuar." ;;
    ask_server)      echo "Servidor SMB (nome do host ou IP): " ;;
    ask_share)       echo "Nome do compartilhamento: " ;;
    ask_mount)       echo "Ponto de montagem local (ex: $MOUNT_BASE/<nome>): " ;;
    ask_user)        echo "Nome de usuário SMB: " ;;
    ask_pass)        echo "Senha SMB: " ;;
    ask_domain)      echo "Domínio/Grupo de Trabalho (ENTER se não usado): " ;;
    ask_smbver)      echo "Versão SMB (ex: 3.0, 3.1.1, 2.1) [3.0]: " ;;
    mount_required)  echo "O caminho é obrigatório. Digite o ponto de montagem." ;;
    summary)         echo "==> Resumo da configuração:" ;;
    sum_server)      echo "    Servidor:    " ;;
    sum_mount)       echo "    Montagem:    " ;;
    sum_unit)        echo "    Unidade:     " ;;
    sum_cred)        echo "    Credenciais: " ;;
    sum_smbver)      echo "    Versão SMB:  " ;;
    sum_domain)      echo "    Domínio:     " ;;
    sum_nodomain)    echo "(nenhum)" ;;
    proceed)         echo "Prosseguir? [y/N]: " ;;
    warn_nonempty)   echo "AVISO: o diretório já existe e contém arquivos:" ;;
    warn_hidden)     echo "Se prosseguir, esses arquivos ficarão ocultos enquanto montado." ;;
    dir_choice)      echo "O que deseja fazer?" ;;
    dir_move_short)  echo "Mover conteúdo para pasta com sufixo -local e usar a pasta limpa" ;;
    dir_proceed_short) echo "Prosseguir mesmo assim (conteúdo ficará oculto enquanto montado)" ;;
    dir_abort_short) echo "Abortar" ;;
    moving)          echo "==> Movendo conteúdo para pasta com sufixo -local" ;;
    moved_to)        echo "    Conteúdo movido para:" ;;
    warn_proceed)    echo "AVISO: prosseguindo. Conteúdo ficará oculto enquanto montado." ;;
    creating_mp)     echo "==> Criando ponto de montagem:" ;;
    creating_cred)   echo "==> Criando arquivo de credenciais:" ;;
    writing_cred)    echo "==> Escrevendo credenciais..." ;;
    generating)      echo "==> Gerando unidade systemd:" ;;
    validating)      echo "==> Validando unidade..." ;;
    unit_error)      echo "ERRO: a unidade tem problemas. Abortando." ;;
    reloading_sd)    echo "==> Recarregando systemd" ;;
    enabling)        echo "==> Habilitando e montando:" ;;
    unit_status)     echo "==> Status da unidade:" ;;
    mp_contents)     echo "==> Conteúdo do ponto de montagem:" ;;
    success)         echo "Pronto. Montagem configurada com sucesso." ;;
    remove_done)     echo "Pronto." ;;
    unit_exists)     echo "AVISO: já existe uma unidade com este nome:" ;;
    overwrite_q)     echo "Sobrescrever a unidade existente? [y/N]: " ;;
    edit_choose_mount) echo "Escolha qual editar [0/número]: " ;;
    edit_what)       echo "O que deseja editar?" ;;
    edit_opt_creds)  echo "Credenciais (usuário/senha/domínio)" ;;
    edit_opt_smbver) echo "Versão SMB" ;;
    edit_choose_field) echo "Escolha [0/1/2/3/4]: " ;;
    cred_not_found)  echo "Arquivo de credenciais não encontrado:" ;;
    current_smbver)  echo "Versão SMB atual:" ;;
    remounting)      echo "==> Remontando:" ;;
    edit_done)       echo "Pronto. Edição concluída." ;;
    preflight_check) echo "==> Testando acesso ao compartilhamento:" ;;
    preflight_ok)    echo "    Acesso confirmado." ;;
    preflight_failed) echo "ERRO: não foi possível acessar o compartilhamento. Detalhes:" ;;
    preflight_aborted) echo "Abortando antes de gravar arquivos. Corrija e tente novamente." ;;
    preflight_skipped) echo "AVISO: smbclient não instalado, pulando teste de acesso." ;;
    auth_failed_hint) echo "==> Falha de autenticação: credenciais rejeitadas pelo servidor." ;;
    auth_retry_q)    echo "Reentrar usuário/senha e tentar de novo? [Y/n]: " ;;
    auth_attempts_left) echo "Tentativas restantes:" ;;
    auth_max_reached) echo "Limite de tentativas atingido. Abortando para evitar bloqueio no servidor." ;;
    enable_failed)   echo "ERRO: a montagem falhou ao subir. Status:" ;;
    rollback_q)      echo "Remover os arquivos recém-criados (.mount e .cred)? [Y/n]: " ;;
    rollback_doing)  echo "==> Revertendo arquivos criados..." ;;
    rollback_done)   echo "    Rollback concluído." ;;
    rollback_kept)   echo "    Arquivos mantidos. Use a opção Excluir para limpar depois." ;;
    boot_q)          echo "Como o boot deve tratar esta montagem?" ;;
    boot_opt_nowait) echo "Não esperar — o boot segue e a montagem sobe em segundo plano (padrão)" ;;
    boot_opt_wait)   echo "Esperar a conexão, mas seguir o boot se falhar (recomendado p/ servidores)" ;;
    boot_opt_require) echo "Esperar e exigir sucesso — o boot fica degradado se a montagem falhar" ;;
    ask_boot_timeout) echo "Tempo máximo de espera no boot, em segundos [90]: " ;;
    boot_lbl)        echo "Boot" ;;
    sum_boot)        echo "    Boot:        " ;;
    boot_mode_nowait) echo "não espera" ;;
    boot_mode_wait)  echo "espera (não bloqueia)" ;;
    boot_mode_require) echo "espera (obrigatória)" ;;
    boot_warn_require) echo "AVISO: se o servidor estiver fora do ar, o boot esperará até o tempo limite e terminará em estado degradado." ;;
    wait_online_check) echo "==> Verificando se o sistema aguarda a rede antes de concluir o boot..." ;;
    wait_online_ok)  echo "    OK, já habilitado:" ;;
    wait_online_off) echo "AVISO: serviço encontrado, porém desabilitado. Sem ele o network-online.target conclui de imediato e a montagem tende a falhar no boot:" ;;
    wait_online_enable_q) echo "Habilitar agora? [Y/n]: " ;;
    wait_online_enabled) echo "    Habilitado:" ;;
    wait_online_none) echo "AVISO: nenhum serviço wait-online encontrado (NetworkManager/systemd-networkd). A montagem pode ser tentada antes de a rede estar pronta." ;;
    deps_q)          echo "Serviços que devem iniciar só depois desta montagem (ex: docker.service; ENTER p/ nenhum): " ;;
    deps_pick)       echo "Quais serviços devem iniciar só depois desta montagem?" ;;
    deps_hint)       echo "(ESPAÇO marca/desmarca, ENTER confirma, ESC não escolhe nenhum)" ;;
    deps_other)      echo "Outro — digitar nomes manualmente" ;;
    deps_chosen)     echo "    Escolhidos:" ;;
    deps_nothing)    echo "    Nenhum serviço escolhido." ;;
    edit_opt_deps)   echo "Serviços dependentes" ;;
    current_deps)    echo "Serviços dependentes atuais:" ;;
    deps_none_now)   echo "(nenhum)" ;;
    deps_updating)   echo "==> Atualizando dependências de serviço..." ;;
    deps_writing)    echo "==> Criando dependências de serviço..." ;;
    deps_written)    echo "    Dependência criada:" ;;
    deps_unknown)    echo "    AVISO: serviço não encontrado, ignorado:" ;;
    deps_removing)   echo "==> Removendo dependências de serviço..." ;;
    edit_opt_boot)   echo "Comportamento no boot" ;;
    current_boot)    echo "Comportamento atual no boot:" ;;
    wait_srv_hint1)  echo "O mount.cifs não fica tentando: se o servidor ainda não subiu, ele falha em" ;;
    wait_srv_hint2)  echo "milissegundos e a montagem desiste — aumentar o tempo limite não adianta." ;;
    wait_srv_hint3)  echo "O wizard pode gerar um serviço que aguarda a porta SMB do servidor responder" ;;
    wait_srv_hint4)  echo "antes de tentar montar (útil quando o NAS demora mais para ligar que este PC)." ;;
    wait_srv_q)      echo "Aguardar o servidor ficar disponível antes de montar? [Y/n]: " ;;
    ask_wait_timeout) echo "Tempo máximo de espera pelo servidor, em segundos [600]: " ;;
    wait_srv_lbl)    echo "aguarda servidor" ;;
    generating_wait) echo "==> Gerando serviço de espera pelo servidor:" ;;
    removing_wait)   echo "==> Removendo serviços de espera pelo servidor..." ;;
    wait_srv_none)   echo "(sem espera pelo servidor)" ;;
  esac
}

# ── Strings EN ───────────────────────────────────────────────────────────────
msg_en() {
  case "$1" in
    title)           echo "SMB Mount Manager" ;;
    title_by)        echo "by rogercrocha" ;;
    thanks_line1)    echo "Thanks for using my script!" ;;
    thanks_line2)    echo "If you found it useful, consider leaving a star on GitHub:" ;;
    menu_list)       echo "List mounts" ;;
    menu_create)     echo "Create a mount" ;;
    menu_edit)       echo "Edit a mount" ;;
    menu_delete)     echo "Delete a mount" ;;
    menu_exit)       echo "Exit" ;;
    menu_choose)     echo "Choose [0/1/2/3/4]: " ;;
    press_enter)     echo "Press ENTER to continue..." ;;
    menu_invalid)    echo "Invalid option." ;;
    leaving)         echo "Leaving." ;;
    no_mounts)       echo "No SMB mounts configured." ;;
    mounts_found)    echo "Configured SMB mounts:" ;;
    mounts_avail)    echo "Available mounts:" ;;
    server_lbl)      echo "Server" ;;
    mount_lbl)       echo "Mount" ;;
    status_lbl)      echo "Status" ;;
    cred_lbl)        echo "Credentials" ;;
    unit_lbl)        echo "Unit" ;;
    status_active)   echo "active" ;;
    status_failed)   echo "failed" ;;
    status_inactive) echo "inactive" ;;
    status_unknown)  echo "unknown" ;;
    cred_undef)      echo "not defined" ;;
    remove_all)      echo "Remove all" ;;
    cancel)          echo "Cancel" ;;
    choose_num)      echo "Choose [0 / number / T]: " ;;
    cancelled)       echo "Cancelled." ;;
    aborted)         echo "Aborted." ;;
    invalid_opt)     echo "Invalid option. Aborted." ;;
    will_remove)     echo "The following will be removed:" ;;
    confirm_remove)  echo "Confirm removal? [y/N]: " ;;
    unmounting)      echo "==> Unmounting..." ;;
    unmounted)       echo "    Unmounted:" ;;
    already_unmnt)   echo "    Already unmounted:" ;;
    unmount_fail)    echo "    Failed to unmount:" ;;
    disabling)       echo "==> Disabling units..." ;;
    disabled)        echo "    Disabled:" ;;
    removing_units)  echo "==> Removing unit files..." ;;
    removing_creds)  echo "==> Removing credential files..." ;;
    removing_dirs)   echo "==> Removing mount directories..." ;;
    removed)         echo "    Removed:" ;;
    ignored_dir)     echo "    Ignored (not empty or non-existent):" ;;
    reloading)       echo "==> Reloading systemd..." ;;
    done)            echo "Done." ;;
    no_cifs)         echo "ERROR: cifs-utils not found. Please install it before continuing." ;;
    ask_server)      echo "SMB server (hostname or IP): " ;;
    ask_share)       echo "Share name: " ;;
    ask_mount)       echo "Local mount point (e.g. $MOUNT_BASE/<name>): " ;;
    ask_user)        echo "SMB username: " ;;
    ask_pass)        echo "SMB password: " ;;
    ask_domain)      echo "Domain/Workgroup (press ENTER if not used): " ;;
    ask_smbver)      echo "SMB version (e.g. 3.0, 3.1.1, 2.1) [3.0]: " ;;
    mount_required)  echo "Mount point is required. Please enter a path." ;;
    summary)         echo "==> Configuration summary:" ;;
    sum_server)      echo "    Server:      " ;;
    sum_mount)       echo "    Mount point: " ;;
    sum_unit)        echo "    Unit file:   " ;;
    sum_cred)        echo "    Credentials: " ;;
    sum_smbver)      echo "    SMB version: " ;;
    sum_domain)      echo "    Domain:      " ;;
    sum_nodomain)    echo "(none)" ;;
    proceed)         echo "Proceed? [y/N]: " ;;
    warn_nonempty)   echo "WARNING: directory already exists and contains files:" ;;
    warn_hidden)     echo "If you proceed, these files will be hidden while the share is mounted." ;;
    dir_choice)      echo "What would you like to do?" ;;
    dir_move_short)  echo "Move contents to a sibling folder with -local suffix and use the clean folder" ;;
    dir_proceed_short) echo "Proceed anyway (contents will be hidden while mounted)" ;;
    dir_abort_short) echo "Abort" ;;
    moving)          echo "==> Moving contents to sibling folder with -local suffix" ;;
    moved_to)        echo "    Contents moved to:" ;;
    warn_proceed)    echo "WARNING: proceeding. Contents will be hidden while mounted." ;;
    creating_mp)     echo "==> Creating mount point:" ;;
    creating_cred)   echo "==> Creating credential file:" ;;
    writing_cred)    echo "==> Writing credentials..." ;;
    generating)      echo "==> Generating systemd unit:" ;;
    validating)      echo "==> Validating unit..." ;;
    unit_error)      echo "ERROR: unit has problems. Aborting." ;;
    reloading_sd)    echo "==> Reloading systemd" ;;
    enabling)        echo "==> Enabling and mounting:" ;;
    unit_status)     echo "==> Unit status:" ;;
    mp_contents)     echo "==> Mount point contents:" ;;
    success)         echo "Done. Mount configured successfully." ;;
    remove_done)     echo "Done." ;;
    unit_exists)     echo "WARNING: a unit with this name already exists:" ;;
    overwrite_q)     echo "Overwrite existing unit? [y/N]: " ;;
    edit_choose_mount) echo "Choose which to edit [0/number]: " ;;
    edit_what)       echo "What do you want to edit?" ;;
    edit_opt_creds)  echo "Credentials (user/password/domain)" ;;
    edit_opt_smbver) echo "SMB version" ;;
    edit_choose_field) echo "Choose [0/1/2/3/4]: " ;;
    cred_not_found)  echo "Credential file not found:" ;;
    current_smbver)  echo "Current SMB version:" ;;
    remounting)      echo "==> Remounting:" ;;
    edit_done)       echo "Done. Edit complete." ;;
    preflight_check) echo "==> Testing share access:" ;;
    preflight_ok)    echo "    Access confirmed." ;;
    preflight_failed) echo "ERROR: could not access the share. Details:" ;;
    preflight_aborted) echo "Aborting before writing files. Fix the issue and try again." ;;
    preflight_skipped) echo "WARNING: smbclient not installed, skipping access test." ;;
    auth_failed_hint) echo "==> Authentication failed: credentials rejected by the server." ;;
    auth_retry_q)    echo "Re-enter user/password and try again? [Y/n]: " ;;
    auth_attempts_left) echo "Attempts remaining:" ;;
    auth_max_reached) echo "Maximum attempts reached. Aborting to avoid server lockout." ;;
    enable_failed)   echo "ERROR: mount failed to start. Status:" ;;
    rollback_q)      echo "Remove the just-created files (.mount and .cred)? [Y/n]: " ;;
    rollback_doing)  echo "==> Rolling back created files..." ;;
    rollback_done)   echo "    Rollback complete." ;;
    rollback_kept)   echo "    Files kept. Use the Delete option to clean up later." ;;
    boot_q)          echo "How should boot treat this mount?" ;;
    boot_opt_nowait) echo "Do not wait — boot continues and the mount comes up in the background (default)" ;;
    boot_opt_wait)   echo "Wait for the connection, but continue booting if it fails (recommended for servers)" ;;
    boot_opt_require) echo "Wait and require success — boot ends up degraded if the mount fails" ;;
    ask_boot_timeout) echo "Maximum time to wait at boot, in seconds [90]: " ;;
    boot_lbl)        echo "Boot" ;;
    sum_boot)        echo "    Boot:        " ;;
    boot_mode_nowait) echo "does not wait" ;;
    boot_mode_wait)  echo "waits (non-blocking)" ;;
    boot_mode_require) echo "waits (required)" ;;
    boot_warn_require) echo "WARNING: if the server is down, boot will wait for the full timeout and finish in a degraded state." ;;
    wait_online_check) echo "==> Checking whether the system waits for the network before finishing boot..." ;;
    wait_online_ok)  echo "    OK, already enabled:" ;;
    wait_online_off) echo "WARNING: service found but disabled. Without it network-online.target completes immediately and the mount is likely to fail at boot:" ;;
    wait_online_enable_q) echo "Enable it now? [Y/n]: " ;;
    wait_online_enabled) echo "    Enabled:" ;;
    wait_online_none) echo "WARNING: no wait-online service found (NetworkManager/systemd-networkd). The mount may be attempted before the network is ready." ;;
    deps_q)          echo "Services that must start only after this mount (e.g. docker.service; ENTER for none): " ;;
    deps_pick)       echo "Which services must start only after this mount?" ;;
    deps_hint)       echo "(SPACE toggles, ENTER confirms, ESC selects none)" ;;
    deps_other)      echo "Other — type names manually" ;;
    deps_chosen)     echo "    Chosen:" ;;
    deps_nothing)    echo "    No service chosen." ;;
    edit_opt_deps)   echo "Dependent services" ;;
    current_deps)    echo "Current dependent services:" ;;
    deps_none_now)   echo "(none)" ;;
    deps_updating)   echo "==> Updating service dependencies..." ;;
    deps_writing)    echo "==> Creating service dependencies..." ;;
    deps_written)    echo "    Dependency created:" ;;
    deps_unknown)    echo "    WARNING: service not found, skipped:" ;;
    deps_removing)   echo "==> Removing service dependencies..." ;;
    edit_opt_boot)   echo "Boot behaviour" ;;
    current_boot)    echo "Current boot behaviour:" ;;
    wait_srv_hint1)  echo "mount.cifs does not keep retrying: if the server is not up yet it fails in" ;;
    wait_srv_hint2)  echo "milliseconds and the mount gives up — raising the timeout does not help." ;;
    wait_srv_hint3)  echo "The wizard can generate a service that waits for the server's SMB port to answer" ;;
    wait_srv_hint4)  echo "before mounting (useful when the NAS takes longer to boot than this machine)." ;;
    wait_srv_q)      echo "Wait for the server to become available before mounting? [Y/n]: " ;;
    ask_wait_timeout) echo "Maximum time to wait for the server, in seconds [600]: " ;;
    wait_srv_lbl)    echo "waits for server" ;;
    generating_wait) echo "==> Generating server-wait service:" ;;
    removing_wait)   echo "==> Removing server-wait services..." ;;
    wait_srv_none)   echo "(no server wait)" ;;
  esac
}

# ── Função principal de mensagens ────────────────────────────────────────────
msg() {
  if [[ "$LANG_CODE" == "pt" ]]; then
    msg_pt "$1"
  else
    msg_en "$1"
  fi
}

# ╔══════════════════════════════════════════════════════════════╗
# ║  DETECÇÃO DE SISTEMA IMUTÁVEL                                ║
# ╚══════════════════════════════════════════════════════════════╝

detect_mountbase() {
  local real_user="${SUDO_USER:-${USER:-$(id -un)}}"
  if findmnt -n -o OPTIONS / 2>/dev/null | grep -qE '(^|,)ro(,|$)'; then
    echo "/home/$real_user/mnt"
  else
    echo "/mnt"
  fi
}

MOUNT_BASE="$(detect_mountbase)"

# ╔══════════════════════════════════════════════════════════════╗
# ║  MENU NAVEGÁVEL POR SETAS / ARROW-KEY MENU                   ║
# ╚══════════════════════════════════════════════════════════════╝

# Garante cursor restaurado se o script terminar com tput civis ativo.
# Só emite o escape em terminal real — evita lixo quando stdout é pipe.
trap '[ -t 1 ] && tput cnorm 2>/dev/null || true' EXIT

# menu_select <label1> <label2> ...
# Sets globals: SELECTED_INDEX (1-based, 0 if cancelled), SELECTED_LABEL
# Navigation: ↑/↓ + ENTER; digits 1-9 jump-and-confirm; ESC or q cancels.
# Falls back to numbered prompt when stdin/stdout is not a TTY.
SELECTED_INDEX=0
SELECTED_LABEL=""
menu_select() {
  local options=("$@")
  local n=${#options[@]}
  local selected=0
  local key="" rest="" i

  SELECTED_INDEX=0
  SELECTED_LABEL=""
  (( n == 0 )) && return

  if [[ ! -t 0 || ! -t 1 ]]; then
    for i in "${!options[@]}"; do
      echo "  $((i+1))) ${options[$i]}"
    done
    local choice=""
    read -r choice || true
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= n )); then
      SELECTED_INDEX=$choice
      SELECTED_LABEL="${options[$((choice-1))]}"
    fi
    return
  fi

  _menu_render() {
    local idx
    for idx in "${!options[@]}"; do
      tput el 2>/dev/null || true
      if (( idx == selected )); then
        printf "\e[7m  > %d) %s  \e[0m\n" "$((idx+1))" "${options[$idx]}"
      else
        printf "    %d) %s\n" "$((idx+1))" "${options[$idx]}"
      fi
    done
  }

  tput civis 2>/dev/null || true
  _menu_render

  while true; do
    IFS= read -rsn1 key || break
    case "$key" in
      $'\e')
        rest=""
        read -rsn2 -t 0.01 rest 2>/dev/null || true
        case "$rest" in
          '[A')
            if (( selected > 0 )); then selected=$((selected-1)); fi
            ;;
          '[B')
            if (( selected < n - 1 )); then selected=$((selected+1)); fi
            ;;
          *)
            tput cnorm 2>/dev/null || true
            return
            ;;
        esac
        ;;
      '')
        SELECTED_INDEX=$((selected + 1))
        SELECTED_LABEL="${options[$selected]}"
        tput cnorm 2>/dev/null || true
        return
        ;;
      [1-9])
        if (( key <= n )); then
          selected=$((key - 1))
          SELECTED_INDEX=$((selected + 1))
          SELECTED_LABEL="${options[$selected]}"
          tput cuu "$n" 2>/dev/null || true
          _menu_render
          tput cnorm 2>/dev/null || true
          return
        fi
        ;;
      q|Q)
        tput cnorm 2>/dev/null || true
        return
        ;;
    esac

    tput cuu "$n" 2>/dev/null || true
    _menu_render
  done

  tput cnorm 2>/dev/null || true
}

# menu_multiselect <label1> <label2> ...
# Sets globals: SELECTED_INDEXES (array of 1-based indexes, empty if none)
# Navigation: ↑/↓ move, SPACE toggles, digits 1-9 toggle, ENTER confirms,
# ESC / q cancels (leaving the selection empty).
# Falls back to a numbered prompt accepting several numbers when not a TTY.
SELECTED_INDEXES=()
MULTISELECT_PRESELECTED=""
menu_multiselect() {
  local options=("$@")
  local n=${#options[@]}
  local cursor=0
  local marks=() key="" rest="" i

  SELECTED_INDEXES=()
  (( n == 0 )) && return

  # MULTISELECT_PRESELECTED: rótulos já marcados ao abrir o menu.
  # MULTISELECT_PRESELECTED: labels that start out checked.
  local pre
  for ((i = 0; i < n; i++)); do
    marks[i]=0
    for pre in ${MULTISELECT_PRESELECTED:-}; do
      if [[ "$pre" == "${options[$i]}" ]]; then marks[i]=1; break; fi
    done
  done

  if [[ ! -t 0 || ! -t 1 ]]; then
    for i in "${!options[@]}"; do
      echo "  $((i+1))) ${options[$i]}"
    done
    local line=""
    read -r line || true
    for i in $line; do
      if [[ "$i" =~ ^[0-9]+$ ]] && (( i >= 1 && i <= n )); then
        SELECTED_INDEXES+=("$i")
      fi
    done
    return
  fi

  _multi_render() {
    local idx box
    for idx in "${!options[@]}"; do
      tput el 2>/dev/null || true
      if (( marks[idx] == 1 )); then box="[x]"; else box="[ ]"; fi
      if (( idx == cursor )); then
        printf "\e[7m  > %s %d) %s  \e[0m\n" "$box" "$((idx+1))" "${options[$idx]}"
      else
        printf "    %s %d) %s\n" "$box" "$((idx+1))" "${options[$idx]}"
      fi
    done
  }

  tput civis 2>/dev/null || true
  _multi_render

  while true; do
    IFS= read -rsn1 key || break
    case "$key" in
      $'\e')
        rest=""
        read -rsn2 -t 0.01 rest 2>/dev/null || true
        case "$rest" in
          '[A') (( cursor > 0 )) && cursor=$((cursor - 1)) ;;
          '[B') (( cursor < n - 1 )) && cursor=$((cursor + 1)) ;;
          *)
            SELECTED_INDEXES=()
            tput cnorm 2>/dev/null || true
            return
            ;;
        esac
        ;;
      ' ')
        if (( marks[cursor] == 1 )); then marks[cursor]=0; else marks[cursor]=1; fi
        ;;
      [1-9])
        if (( key <= n )); then
          cursor=$((key - 1))
          if (( marks[cursor] == 1 )); then marks[cursor]=0; else marks[cursor]=1; fi
        fi
        ;;
      '')
        for i in "${!options[@]}"; do
          (( marks[i] == 1 )) && SELECTED_INDEXES+=("$((i+1))")
        done
        tput cnorm 2>/dev/null || true
        return
        ;;
      q|Q)
        SELECTED_INDEXES=()
        tput cnorm 2>/dev/null || true
        return
        ;;
    esac

    tput cuu "$n" 2>/dev/null || true
    _multi_render
  done

  tput cnorm 2>/dev/null || true
}

# ╔══════════════════════════════════════════════════════════════╗
# ║  FUNÇÕES AUXILIARES                                          ║
# ╚══════════════════════════════════════════════════════════════╝

coletar_montagens() {
  UNIT_FILES=()
  WHATS=()
  WHERES=()
  CREDS=()
  BOOTS=()
  WAITS=()

  for unit_file in "$UNIT_DIR"/*.mount; do
    [[ -f "$unit_file" ]] || continue
    grep -q 'Type=cifs' "$unit_file" 2>/dev/null || continue
    UNIT_FILES+=("$unit_file")
    WHATS+=("$(grep -m1 '^What=' "$unit_file" | cut -d= -f2-)")
    WHERES+=("$(grep -m1 '^Where=' "$unit_file" | cut -d= -f2-)")
    CREDS+=("$(grep -m1 'credentials=' "$unit_file" | grep -o 'credentials=[^ ,]*' | cut -d= -f2- || true)")
    BOOTS+=("$(unit_boot_mode "$unit_file")")
    WAITS+=("$(unit_wait_unit "$unit_file")")
  done
}

status_unidade() {
  local s
  s="$(systemctl is-active "$1" 2>/dev/null || true)"
  case "$s" in
    active)   msg status_active ;;
    failed)   msg status_failed ;;
    inactive) msg status_inactive ;;
    *)        msg status_unknown ;;
  esac
}

# ╔══════════════════════════════════════════════════════════════╗
# ║  COMPORTAMENTO NO BOOT / BOOT BEHAVIOUR                      ║
# ╚══════════════════════════════════════════════════════════════╝
#
# Modo 1 - não espera: nofail + WantedBy=multi-user.target.
#          O boot nunca aguarda a montagem.
# Modo 2 - espera sem bloquear: nofail + Before/WantedBy=remote-fs.target.
#          O boot aguarda a tentativa até TimeoutSec; falha não degrada o boot.
# Modo 3 - espera e exige: sem nofail + Before/RequiredBy=remote-fs.target.
#          O boot aguarda; se a montagem falhar, remote-fs.target falha junto.
#
# Mode 1 - do not wait: nofail + WantedBy=multi-user.target.
# Mode 2 - wait, non-blocking: nofail + Before/WantedBy=remote-fs.target.
# Mode 3 - wait and require: no nofail + Before/RequiredBy=remote-fs.target.

# unit_boot_mode <unit_file> -> 1 | 2 | 3
unit_boot_mode() {
  local f="$1"
  if grep -q '^RequiredBy=remote-fs.target' "$f" 2>/dev/null; then
    echo 3
  elif grep -q '^WantedBy=remote-fs.target' "$f" 2>/dev/null; then
    echo 2
  else
    echo 1
  fi
}

# boot_mode_label <mode> [wait_unit]
boot_mode_label() {
  local label
  case "$1" in
    2) label="$(msg boot_mode_wait)" ;;
    3) label="$(msg boot_mode_require)" ;;
    *) label="$(msg boot_mode_nowait)" ;;
  esac
  if [[ -n "${2:-}" ]]; then
    printf '%s + %s\n' "$label" "$(msg wait_srv_lbl)"
  else
    printf '%s\n' "$label"
  fi
}

# Sem um serviço wait-online habilitado, network-online.target é atingido de
# imediato e a montagem no boot falha mesmo com Requires=network-online.target.
# Without an enabled wait-online service, network-online.target is reached
# immediately and the boot-time mount fails despite Requires=network-online.target.
verificar_wait_online() {
  local svc="" s state

  msg wait_online_check; echo
  for s in NetworkManager-wait-online.service \
           systemd-networkd-wait-online.service \
           ifupdown-wait-online.service; do
    if systemctl cat "$s" &>/dev/null; then svc="$s"; break; fi
  done

  # remote-fs.target precisa estar no boot para que a espera aconteça.
  # remote-fs.target must be part of the boot transaction for the wait to happen.
  sudo systemctl enable remote-fs.target &>/dev/null || true

  if [[ -z "$svc" ]]; then
    msg wait_online_none; echo
    return
  fi

  state="$(systemctl is-enabled "$svc" 2>/dev/null || true)"
  case "$state" in
    enabled|enabled-runtime|static|indirect)
      echo "$(msg wait_online_ok) $svc"
      return
      ;;
  esac

  echo "$(msg wait_online_off) $svc"
  local ans=""
  read -rp "$(msg wait_online_enable_q)" ans
  ans="${ans:-y}"
  if [[ "$ans" == "y" || "$ans" == "Y" ]]; then
    if sudo systemctl enable "$svc" &>/dev/null; then
      echo "$(msg wait_online_enabled) $svc"
    fi
  fi
}

# gerar_unidade <unit_file> <desc> <what> <where> <base_opts> <mode> <timeout> [wait_unit]
# base_opts nunca deve conter nofail; a função adiciona conforme o modo.
# base_opts must never contain nofail; the function adds it per mode.
gerar_unidade() {
  local unit_file="$1" desc="$2" what="$3" where="$4" opts="$5" mode="$6" tmo="$7"
  local wait_unit="${8:-}"
  local install_line=""
  local deps="Requires=network-online.target
After=network-online.target"

  # Requires= faz a montagem desistir se a espera estourar o prazo, em vez de
  # tentar montar contra um servidor que sabidamente não respondeu.
  # Requires= makes the mount give up if the wait hits its deadline, instead of
  # mounting against a server we already know did not answer.
  if [[ -n "$wait_unit" ]]; then
    deps="${deps}
Requires=$wait_unit
After=$wait_unit"
  fi

  case "$mode" in
    2)
      opts="${opts},nofail"
      deps="${deps}
Before=remote-fs.target"
      install_line="WantedBy=remote-fs.target"
      ;;
    3)
      deps="${deps}
Before=remote-fs.target"
      install_line="RequiredBy=remote-fs.target"
      ;;
    *)
      opts="${opts},nofail"
      install_line="WantedBy=multi-user.target"
      ;;
  esac

  sudo tee "$unit_file" > /dev/null <<EOF
[Unit]
Description=$desc
${deps}

[Mount]
What=$what
Where=$where
Type=cifs
Options=$opts
TimeoutSec=$tmo

[Install]
$install_line
EOF
  sudo chown root:root "$unit_file"
  sudo chmod 644 "$unit_file"
}

# ── Espera pelo servidor / server wait ───────────────────────────────────────
#
# O mount.cifs não tem retentativa: contra um servidor que ainda não subiu ele
# retorna erro em milissegundos, então TimeoutSec= alto não resolve nada. Este
# serviço auxiliar sonda a porta SMB até o servidor responder e só então a
# montagem é tentada.
#
# mount.cifs has no retry logic: against a server that is not up yet it errors
# out in milliseconds, so a large TimeoutSec= buys nothing. This helper service
# polls the SMB port until the server answers, and only then is the mount tried.

WAIT_PREFIX="smb-wizard-wait-"
WAIT_PORT=445
WAIT_INTERVAL=5

# wait_unit_name <escaped_unit_name>
wait_unit_name() {
  echo "${WAIT_PREFIX}$1.service"
}

# unit_wait_unit <unit_file> -> nome do serviço de espera, ou vazio
unit_wait_unit() {
  grep -m1 -oE "^Requires=${WAIT_PREFIX}[^ ]+\\.service" "$1" 2>/dev/null | cut -d= -f2- || true
}

# gerar_unidade_espera <escaped_unit_name> <server> <mountpoint> <deadline>
gerar_unidade_espera() {
  local esc="$1" server="$2" where="$3" deadline="$4"
  local file="$UNIT_DIR/$(wait_unit_name "$esc")"

  # /dev/tcp é builtin do bash: sem dependência extra no sistema alvo.
  # O timeout externo evita travar no connect quando não há rota até o host.
  # /dev/tcp is a bash builtin: no extra dependency on the target system.
  # The outer timeout avoids hanging on connect when there is no route to host.
  sudo tee "$file" > /dev/null <<EOF
[Unit]
Description=Wait for SMB server $server before mounting $where
Requires=network-online.target
After=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
TimeoutStartSec=$deadline
ExecStart=/bin/bash -c 'until timeout 3 bash -c "exec 3<>/dev/tcp/$server/$WAIT_PORT" 2>/dev/null; do sleep $WAIT_INTERVAL; done; sleep 3'
EOF
  sudo chown root:root "$file"
  sudo chmod 644 "$file"
  echo "$file"
}

# remover_unidade_espera <escaped_unit_name>
remover_unidade_espera() {
  local esc="$1" name file
  name="$(wait_unit_name "$esc")"
  file="$UNIT_DIR/$name"
  [[ -f "$file" ]] || return 0
  sudo systemctl disable --now "$name" &>/dev/null || true
  sudo rm -f "$file"
  echo "$(msg removed) $file"
}

# Descobre serviços que plausivelmente consomem o compartilhamento. Só entram os
# que existem de fato nesta máquina; instâncias de template (docker-compose@x)
# são preferíveis ao docker.service inteiro, porque reiniciar aquele derruba
# todos os contêineres.
# Discovers services that plausibly consume the share. Only ones that actually
# exist here are offered; template instances (docker-compose@x) are preferable
# to docker.service as a whole, since restarting that takes down every container.
detectar_servicos() {
  DEP_CANDIDATES=()
  local svc seen

  for svc in docker.service podman.service \
             home-assistant.service hass.service \
             jellyfin.service plexmediaserver.service emby-server.service; do
    systemctl cat "$svc" &>/dev/null && DEP_CANDIDATES+=("$svc")
  done

  # Instâncias de templates (docker-compose@midia.service etc), carregadas ou
  # apenas habilitadas. O template puro (nome terminado em @.service) não pode
  # ser iniciado, então fica de fora.
  while read -r svc; do
    [[ -n "$svc" ]] || continue
    [[ "$svc" == *@.service ]] && continue
    for seen in ${DEP_CANDIDATES[@]+"${DEP_CANDIDATES[@]}"}; do
      [[ "$seen" == "$svc" ]] && continue 2
    done
    DEP_CANDIDATES+=("$svc")
  done < <(
    {
      systemctl list-units --all --no-legend --plain --type=service \
        'docker-compose@*.service' 'compose@*.service' 'podman-compose@*.service' \
        'home-assistant@*.service' 2>/dev/null
      systemctl list-unit-files --no-legend \
        'docker-compose@*.service' 'compose@*.service' 'podman-compose@*.service' \
        'home-assistant@*.service' 2>/dev/null
    } | awk '{print $1}' | sort -u
  )
}

# escolher_dependencias [servicos_atuais] -> DEP_SERVICES (separado por espaços)
escolher_dependencias() {
  local current="${1:-}"
  DEP_SERVICES=""
  local idx other=0 extra="" svc seen

  detectar_servicos

  # Serviços já configurados que a varredura não reconhece (digitados à mão numa
  # execução anterior) precisam aparecer, senão editar apagaria a escolha.
  # Already-configured services the scan does not know about (typed by hand in an
  # earlier run) must still show, otherwise editing would silently drop them.
  for svc in $current; do
    for seen in ${DEP_CANDIDATES[@]+"${DEP_CANDIDATES[@]}"}; do
      [[ "$seen" == "$svc" ]] && continue 2
    done
    DEP_CANDIDATES+=("$svc")
  done

  # Nada reconhecido nesta máquina: cai no campo livre de sempre.
  # Nothing recognised here: fall back to the plain free-text field.
  if (( ${#DEP_CANDIDATES[@]} == 0 )); then
    read -rp "$(msg deps_q)" DEP_SERVICES
    return
  fi

  echo
  msg deps_pick; echo
  msg deps_hint; echo
  echo

  local labels=("${DEP_CANDIDATES[@]}")
  labels+=("$(msg deps_other)")
  MULTISELECT_PRESELECTED="$current"
  menu_multiselect "${labels[@]}"
  MULTISELECT_PRESELECTED=""

  for idx in ${SELECTED_INDEXES[@]+"${SELECTED_INDEXES[@]}"}; do
    if (( idx == ${#labels[@]} )); then
      other=1
    else
      DEP_SERVICES="$DEP_SERVICES ${DEP_CANDIDATES[$((idx-1))]}"
    fi
  done

  if (( other == 1 )); then
    echo
    read -rp "$(msg deps_q)" extra
    [[ -n "$extra" ]] && DEP_SERVICES="$DEP_SERVICES $extra"
  fi

  DEP_SERVICES="${DEP_SERVICES# }"

  echo
  if [[ -n "$DEP_SERVICES" ]]; then
    echo "$(msg deps_chosen) $DEP_SERVICES"
  else
    msg deps_nothing; echo
  fi
}

# aplicar_dependencias <escaped_unit_name> <mountpoint> <service...>
# Escreve um drop-in RequiresMountsFor para cada serviço, de modo que ele só
# inicie depois que a montagem estiver ativa.
# Writes a RequiresMountsFor drop-in per service so it only starts once the
# mount is up.
aplicar_dependencias() {
  local esc="$1" where="$2"
  shift 2
  local svc dropin_dir dropin

  msg deps_writing; echo
  for svc in "$@"; do
    [[ -n "$svc" ]] || continue
    [[ "$svc" == *.* ]] || svc="${svc}.service"
    if ! systemctl cat "$svc" &>/dev/null; then
      echo "$(msg deps_unknown) $svc"
      continue
    fi
    dropin_dir="$UNIT_DIR/${svc}.d"
    dropin="$dropin_dir/10-smb-wizard-${esc}.conf"
    sudo mkdir -p "$dropin_dir"
    printf '[Unit]\nRequiresMountsFor=%s\n' "$where" | sudo tee "$dropin" > /dev/null
    sudo chmod 644 "$dropin"
    echo "$(msg deps_written) $dropin"
  done
}

# listar_dependencias <escaped_unit_name> -> serviços já configurados
listar_dependencias() {
  local esc="$1" dropin dir out=""
  for dropin in "$UNIT_DIR"/*.d/10-smb-wizard-"${esc}".conf; do
    [[ -f "$dropin" ]] || continue
    dir="$(basename "$(dirname "$dropin")")"
    out="$out ${dir%.d}"
  done
  echo "${out# }"
}

# remover_dependencias <escaped_unit_name>
remover_dependencias() {
  local esc="$1" dropin dropin_dir
  for dropin in "$UNIT_DIR"/*.d/10-smb-wizard-"${esc}".conf; do
    [[ -f "$dropin" ]] || continue
    dropin_dir="$(dirname "$dropin")"
    sudo rm -f "$dropin"
    echo "$(msg removed) $dropin"
    sudo rmdir "$dropin_dir" 2>/dev/null || true
  done
}

# ╔══════════════════════════════════════════════════════════════╗
# ║  1. LISTAR MONTAGENS                                         ║
# ╚══════════════════════════════════════════════════════════════╝

listar_montagens() {
  coletar_montagens
  echo

  if [[ ${#UNIT_FILES[@]} -eq 0 ]]; then
    msg no_mounts; echo
    return
  fi

  msg mounts_found; echo
  echo
  for i in "${!UNIT_FILES[@]}"; do
    UNIT_NAME="$(basename "${UNIT_FILES[$i]}")"
    echo "  $((i+1))) $UNIT_NAME"
    echo "       $(msg server_lbl):    ${WHATS[$i]}"
    echo "       $(msg mount_lbl):    ${WHERES[$i]}"
    echo "       $(msg status_lbl):      $(status_unidade "$UNIT_NAME")"
    echo "       $(msg boot_lbl):        $(boot_mode_label "${BOOTS[$i]}" "${WAITS[$i]}")"
    echo "       $(msg cred_lbl): ${CREDS[$i]:-$(msg cred_undef)}"
    echo
  done
}

# ╔══════════════════════════════════════════════════════════════╗
# ║  2. CRIAR MONTAGEM                                           ║
# ╚══════════════════════════════════════════════════════════════╝

criar_montagem() {
  if ! command -v mount.cifs &>/dev/null; then
    msg no_cifs; echo
    exit 1
  fi

  echo
  read -rp "$(msg ask_server)" SERVER
  read -rp "$(msg ask_share)" SHARE
  SHARE="${SHARE#/}"; SHARE="${SHARE%/}"
  SHARE_ROOT="${SHARE%%/*}"
  SHARE_SUBPATH=""
  [[ "$SHARE" == */* ]] && SHARE_SUBPATH="${SHARE#*/}"
  while true; do
    read -rp "$(msg ask_mount)" MOUNTPOINT
    [[ -n "$MOUNTPOINT" ]] && break
    echo "$(msg mount_required)"
  done

  MOUNTPOINT="$(realpath -m "$MOUNTPOINT")"

  read -rp "$(msg ask_user)" USERNAME
  read -rsp "$(msg ask_pass)" PASSWORD
  echo
  read -rp "$(msg ask_domain)" DOMAIN
  read -rp "$(msg ask_smbver)" SMB_VERSION
  SMB_VERSION="${SMB_VERSION:-3.0}"

  echo
  msg boot_q; echo
  menu_select \
    "$(msg boot_opt_nowait)" \
    "$(msg boot_opt_wait)" \
    "$(msg boot_opt_require)"
  BOOT_MODE="$SELECTED_INDEX"
  (( BOOT_MODE >= 1 && BOOT_MODE <= 3 )) || BOOT_MODE=1

  MOUNT_TIMEOUT=30
  DEP_SERVICES=""
  WAIT_DEADLINE=0
  if (( BOOT_MODE > 1 )); then
    (( BOOT_MODE == 3 )) && { echo; msg boot_warn_require; echo; }
    echo
    read -rp "$(msg ask_boot_timeout)" MOUNT_TIMEOUT
    MOUNT_TIMEOUT="${MOUNT_TIMEOUT:-90}"
    [[ "$MOUNT_TIMEOUT" =~ ^[0-9]+$ ]] || MOUNT_TIMEOUT=90

    echo
    msg wait_srv_hint1; echo
    msg wait_srv_hint2; echo
    msg wait_srv_hint3; echo
    msg wait_srv_hint4; echo
    echo
    read -rp "$(msg wait_srv_q)" WAIT_SRV
    WAIT_SRV="${WAIT_SRV:-y}"
    if [[ "$WAIT_SRV" == "y" || "$WAIT_SRV" == "Y" ]]; then
      read -rp "$(msg ask_wait_timeout)" WAIT_DEADLINE
      WAIT_DEADLINE="${WAIT_DEADLINE:-600}"
      [[ "$WAIT_DEADLINE" =~ ^[0-9]+$ ]] && (( WAIT_DEADLINE > 0 )) || WAIT_DEADLINE=600
    fi

    escolher_dependencias
  fi

  UNIT_NAME="$(systemd-escape --path "$MOUNTPOINT")"
  UNIT_FILE="$UNIT_DIR/${UNIT_NAME}.mount"
  SAFE_SERVER="$(echo "$SERVER" | tr '.: ' '---')"
  SAFE_SHARE="$(echo "$SHARE" | tr '/ ' '--')"
  CRED_FILE="/etc/samba-cred-${SAFE_SERVER}-${SAFE_SHARE}--${UNIT_NAME}.cred"

  if [[ -f "$UNIT_FILE" ]]; then
    echo
    echo "$(msg unit_exists) $UNIT_FILE"
    read -rp "$(msg overwrite_q)" OVERWRITE
    OVERWRITE="${OVERWRITE:-n}"
    [[ "$OVERWRITE" == "y" || "$OVERWRITE" == "Y" ]] || { msg aborted; echo; return; }
  fi

  echo
  msg summary; echo
  echo "$(msg sum_server)//$SERVER/$SHARE"
  echo "$(msg sum_mount)$MOUNTPOINT"
  echo "$(msg sum_unit)$UNIT_FILE"
  echo "$(msg sum_cred)$CRED_FILE"
  echo "$(msg sum_smbver)$SMB_VERSION"
  echo "$(msg sum_domain)${DOMAIN:-$(msg sum_nodomain)}"
  if (( WAIT_DEADLINE > 0 )); then
    echo "$(msg sum_boot)$(boot_mode_label "$BOOT_MODE") + $(msg wait_srv_lbl) (${WAIT_DEADLINE}s), TimeoutSec=${MOUNT_TIMEOUT}s"
  else
    echo "$(msg sum_boot)$(boot_mode_label "$BOOT_MODE") (TimeoutSec=${MOUNT_TIMEOUT}s)"
  fi
  echo
  read -rp "$(msg proceed)" CONFIRM
  CONFIRM="${CONFIRM:-n}"
  [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]] || { msg aborted; echo; return; }

  if command -v smbclient &>/dev/null; then
    local MAX_AUTH_RETRIES=3
    local attempt=1
    while true; do
      echo
      echo "$(msg preflight_check) //$SERVER/$SHARE_ROOT"
      local PREFLIGHT_OUTPUT="" PREFLIGHT_FAILED=0
      if [[ -n "$DOMAIN" ]]; then
        PREFLIGHT_OUTPUT="$(PASSWD="$PASSWORD" timeout 15 smbclient "//$SERVER/$SHARE_ROOT" -U "$USERNAME" -W "$DOMAIN" -c "quit" 2>&1)" || PREFLIGHT_FAILED=1
      else
        PREFLIGHT_OUTPUT="$(PASSWD="$PASSWORD" timeout 15 smbclient "//$SERVER/$SHARE_ROOT" -U "$USERNAME" -c "quit" 2>&1)" || PREFLIGHT_FAILED=1
      fi
      if (( PREFLIGHT_FAILED == 0 )); then
        msg preflight_ok; echo
        break
      fi

      echo
      msg preflight_failed; echo
      echo "$PREFLIGHT_OUTPUT" | sed 's/^/    /' | head -n 5
      echo

      if echo "$PREFLIGHT_OUTPUT" | grep -q 'NT_STATUS_LOGON_FAILURE'; then
        msg auth_failed_hint; echo
        if (( attempt >= MAX_AUTH_RETRIES )); then
          msg auth_max_reached; echo
          return
        fi
        local remaining=$((MAX_AUTH_RETRIES - attempt))
        echo "$(msg auth_attempts_left) $remaining"
        read -rp "$(msg auth_retry_q)" RETRY
        RETRY="${RETRY:-y}"
        if [[ "$RETRY" == "y" || "$RETRY" == "Y" ]]; then
          echo
          read -rp "$(msg ask_user)" USERNAME
          read -rsp "$(msg ask_pass)" PASSWORD
          echo
          read -rp "$(msg ask_domain)" DOMAIN
          attempt=$((attempt + 1))
          continue
        fi
      fi

      msg preflight_aborted; echo
      return
    done
  else
    echo
    msg preflight_skipped; echo
  fi

  if (( BOOT_MODE > 1 )); then
    echo
    verificar_wait_online
  fi

  # Verificar pasta com conteúdo
  if [[ -d "$MOUNTPOINT" ]] && [[ -n "$(ls -A "$MOUNTPOINT" 2>/dev/null)" ]]; then
    echo
    msg warn_nonempty; echo
    ls -la "$MOUNTPOINT"
    echo
    msg warn_hidden; echo
    echo
    msg dir_choice; echo
    menu_select \
      "$(msg dir_move_short)" \
      "$(msg dir_proceed_short)" \
      "$(msg dir_abort_short)"

    case "$SELECTED_INDEX" in
      1)
        LOCAL_BACKUP="${MOUNTPOINT}-local"
        msg moving; echo
        mkdir -p "$LOCAL_BACKUP"
        mv "$MOUNTPOINT"/. "$LOCAL_BACKUP"/ 2>/dev/null || true
        echo "$(msg moved_to) $LOCAL_BACKUP"
        ;;
      2)
        msg warn_proceed; echo
        ;;
      *)
        msg aborted; echo
        return
        ;;
    esac
  fi

  echo "$(msg creating_mp) $MOUNTPOINT"
  sudo mkdir -p "$MOUNTPOINT"

  echo "$(msg creating_cred) $CRED_FILE"
  sudo touch "$CRED_FILE"
  sudo chown root:root "$CRED_FILE"
  sudo chmod 600 "$CRED_FILE"
  msg writing_cred; echo
  printf 'username=%s\npassword=%s\n' "$USERNAME" "$PASSWORD" \
    | sudo tee "$CRED_FILE" > /dev/null
  [[ -n "$DOMAIN" ]] && printf 'domain=%s\n' "$DOMAIN" | sudo tee -a "$CRED_FILE" > /dev/null

  WAIT_UNIT=""
  if (( WAIT_DEADLINE > 0 )); then
    WAIT_UNIT="$(wait_unit_name "$UNIT_NAME")"
    echo "$(msg generating_wait) $UNIT_DIR/$WAIT_UNIT"
    gerar_unidade_espera "$UNIT_NAME" "$SERVER" "$MOUNTPOINT" "$WAIT_DEADLINE" > /dev/null
  fi

  echo "$(msg generating) $UNIT_FILE"
  gerar_unidade \
    "$UNIT_FILE" \
    "SMB Mount $MOUNTPOINT ($SHARE)" \
    "//$SERVER/$SHARE" \
    "$MOUNTPOINT" \
    "credentials=$CRED_FILE,vers=$SMB_VERSION,iocharset=utf8,file_mode=0666,dir_mode=0777,noperm,_netdev" \
    "$BOOT_MODE" \
    "$MOUNT_TIMEOUT" \
    "$WAIT_UNIT"

  msg validating; echo
  systemd-analyze verify "$UNIT_FILE" 2>&1 || {
    msg unit_error; echo
    sudo rm -f "$UNIT_FILE"
    [[ -n "$WAIT_UNIT" ]] && remover_unidade_espera "$UNIT_NAME" > /dev/null
    return
  }

  msg reloading_sd; echo
  sudo systemctl daemon-reload

  echo "$(msg enabling) ${UNIT_NAME}.mount"
  if ! sudo systemctl enable --now "${UNIT_NAME}.mount"; then
    echo
    msg enable_failed; echo
    sudo systemctl status "${UNIT_NAME}.mount" --no-pager || true
    echo
    read -rp "$(msg rollback_q)" ROLLBACK
    ROLLBACK="${ROLLBACK:-y}"
    if [[ "$ROLLBACK" == "y" || "$ROLLBACK" == "Y" ]]; then
      msg rollback_doing; echo
      sudo systemctl disable "${UNIT_NAME}.mount" 2>/dev/null || true
      sudo rm -f "$UNIT_FILE" "$CRED_FILE"
      [[ -n "$WAIT_UNIT" ]] && remover_unidade_espera "$UNIT_NAME" > /dev/null
      sudo systemctl daemon-reload
      sudo systemctl reset-failed "${UNIT_NAME}.mount" 2>/dev/null || true
      sudo rmdir "$MOUNTPOINT" 2>/dev/null || true
      msg rollback_done; echo
    else
      msg rollback_kept; echo
    fi
    return
  fi

  if (( BOOT_MODE > 1 )) && [[ -n "$DEP_SERVICES" ]]; then
    echo
    # Divisão intencional em palavras: lista de serviços separada por espaços.
    # Intentional word splitting: whitespace-separated service list.
    # shellcheck disable=SC2086
    aplicar_dependencias "$UNIT_NAME" "$MOUNTPOINT" $DEP_SERVICES
    sudo systemctl daemon-reload
  fi

  echo
  msg unit_status; echo
  sudo systemctl status "${UNIT_NAME}.mount" --no-pager || true

  msg mp_contents; echo
  ls -la "$MOUNTPOINT" || true

  echo
  msg success; echo
}

# ╔══════════════════════════════════════════════════════════════╗
# ║  3. EXCLUIR MONTAGEM                                         ║
# ╚══════════════════════════════════════════════════════════════╝

excluir_montagem() {
  coletar_montagens

  if [[ ${#UNIT_FILES[@]} -eq 0 ]]; then
    echo
    msg no_mounts; echo
    return
  fi

  echo
  msg mounts_avail; echo
  echo
  for i in "${!UNIT_FILES[@]}"; do
    UNIT_NAME="$(basename "${UNIT_FILES[$i]}")"
    echo "  $((i+1))) $UNIT_NAME"
    echo "       $(msg server_lbl):    ${WHATS[$i]}"
    echo "       $(msg mount_lbl):     ${WHERES[$i]}"
    echo "       $(msg status_lbl):    $(status_unidade "$UNIT_NAME")"
    echo "       $(msg boot_lbl):      $(boot_mode_label "${BOOTS[$i]}" "${WAITS[$i]}")"
    echo "       $(msg cred_lbl): ${CREDS[$i]:-$(msg cred_undef)}"
    echo
  done

  local n=${#UNIT_FILES[@]}
  local labels=()
  for i in "${!UNIT_FILES[@]}"; do
    labels+=("$(basename "${UNIT_FILES[$i]}")")
  done
  labels+=("$(msg remove_all)")
  labels+=("$(msg cancel)")

  menu_select "${labels[@]}"

  SELECTED_UNITS=()
  SELECTED_WHERES=()
  SELECTED_CREDS=()

  local all_idx=$((n + 1))
  local cancel_idx=$((n + 2))

  if (( SELECTED_INDEX == 0 || SELECTED_INDEX == cancel_idx )); then
    msg cancelled; echo
    return
  elif (( SELECTED_INDEX == all_idx )); then
    SELECTED_UNITS=("${UNIT_FILES[@]}")
    SELECTED_WHERES=("${WHERES[@]}")
    SELECTED_CREDS=("${CREDS[@]}")
    for cred_file in /etc/samba-cred*.cred; do
      [[ -f "$cred_file" ]] || continue
      already=0
      for c in ${SELECTED_CREDS[@]+"${SELECTED_CREDS[@]}"}; do
        [[ "$c" == "$cred_file" ]] && already=1 && break
      done
      [[ $already -eq 0 ]] && SELECTED_CREDS+=("$cred_file") || true
    done
  elif (( SELECTED_INDEX >= 1 && SELECTED_INDEX <= n )); then
    IDX=$((SELECTED_INDEX - 1))
    SELECTED_UNITS=("${UNIT_FILES[$IDX]}")
    SELECTED_WHERES=("${WHERES[$IDX]}")
    SELECTED_CREDS=("${CREDS[$IDX]}")
  else
    msg invalid_opt; echo
    return
  fi

  echo
  msg will_remove; echo
  echo
  for u in "${SELECTED_UNITS[@]}";  do echo "  $(msg unit_lbl):   $(basename "$u")"; done
  for w in "${SELECTED_WHERES[@]}"; do echo "  $(msg mount_lbl):  $w"; done
  for c in ${SELECTED_CREDS[@]+"${SELECTED_CREDS[@]}"}; do [[ -n "$c" ]] && echo "  $(msg cred_lbl): $c"; done
  echo

  read -rp "$(msg confirm_remove)" CONFIRM
  CONFIRM="${CONFIRM:-n}"
  [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]] || { msg aborted; echo; return; }

  echo
  msg unmounting; echo
  for mountpoint in "${SELECTED_WHERES[@]}"; do
    if mountpoint -q "$mountpoint" 2>/dev/null; then
      sudo umount -l "$mountpoint" 2>/dev/null \
        && echo "$(msg unmounted) $mountpoint" \
        || echo "$(msg unmount_fail) $mountpoint"
    else
      echo "$(msg already_unmnt) $mountpoint"
    fi
  done

  msg disabling; echo
  for unit_file in "${SELECTED_UNITS[@]}"; do
    UNIT_NAME="$(basename "$unit_file")"
    sudo systemctl disable --now "$UNIT_NAME" 2>/dev/null || true
    echo "$(msg disabled) $UNIT_NAME"
  done

  msg deps_removing; echo
  for unit_file in "${SELECTED_UNITS[@]}"; do
    UNIT_NAME="$(basename "$unit_file")"
    remover_dependencias "${UNIT_NAME%.mount}"
  done

  msg removing_wait; echo
  for unit_file in "${SELECTED_UNITS[@]}"; do
    UNIT_NAME="$(basename "$unit_file")"
    remover_unidade_espera "${UNIT_NAME%.mount}"
  done

  msg removing_units; echo
  for unit_file in "${SELECTED_UNITS[@]}"; do
    sudo rm -f "$unit_file"
    echo "$(msg removed) $unit_file"
  done

  msg removing_creds; echo
  for cred_file in ${SELECTED_CREDS[@]+"${SELECTED_CREDS[@]}"}; do
    [[ -n "$cred_file" && -f "$cred_file" ]] || continue
    sudo rm -f "$cred_file"
    echo "$(msg removed) $cred_file"
  done

  msg removing_dirs; echo
  for mountpoint in "${SELECTED_WHERES[@]}"; do
    sudo rmdir "$mountpoint" 2>/dev/null \
      && echo "$(msg removed) $mountpoint" \
      || echo "$(msg ignored_dir) $mountpoint"
  done

  msg reloading; echo
  sudo systemctl daemon-reload
  sudo systemctl reset-failed

  echo
  msg remove_done; echo
}

# ╔══════════════════════════════════════════════════════════════╗
# ║  4. EDITAR MONTAGEM                                          ║
# ╚══════════════════════════════════════════════════════════════╝

editar_montagem() {
  coletar_montagens

  if [[ ${#UNIT_FILES[@]} -eq 0 ]]; then
    echo
    msg no_mounts; echo
    return
  fi

  echo
  msg mounts_avail; echo
  echo
  for i in "${!UNIT_FILES[@]}"; do
    UNIT_NAME="$(basename "${UNIT_FILES[$i]}")"
    echo "  $((i+1))) $UNIT_NAME"
    echo "       $(msg server_lbl):    ${WHATS[$i]}"
    echo "       $(msg mount_lbl):     ${WHERES[$i]}"
    echo "       $(msg status_lbl):    $(status_unidade "$UNIT_NAME")"
    echo "       $(msg boot_lbl):      $(boot_mode_label "${BOOTS[$i]}" "${WAITS[$i]}")"
    echo "       $(msg cred_lbl): ${CREDS[$i]:-$(msg cred_undef)}"
    echo
  done

  local n=${#UNIT_FILES[@]}
  local labels=()
  for i in "${!UNIT_FILES[@]}"; do
    labels+=("$(basename "${UNIT_FILES[$i]}")")
  done
  labels+=("$(msg cancel)")

  menu_select "${labels[@]}"

  local cancel_idx=$((n + 1))
  if (( SELECTED_INDEX == 0 || SELECTED_INDEX == cancel_idx )); then
    msg cancelled; echo
    return
  fi

  if (( SELECTED_INDEX < 1 || SELECTED_INDEX > n )); then
    msg invalid_opt; echo
    return
  fi

  IDX=$((SELECTED_INDEX - 1))
  TARGET_UNIT="${UNIT_FILES[$IDX]}"
  TARGET_WHERE="${WHERES[$IDX]}"
  TARGET_CRED="${CREDS[$IDX]}"
  UNIT_NAME="$(basename "$TARGET_UNIT")"

  echo
  msg edit_what; echo
  menu_select \
    "$(msg edit_opt_creds)" \
    "$(msg edit_opt_smbver)" \
    "$(msg edit_opt_boot)" \
    "$(msg edit_opt_deps)" \
    "$(msg cancel)"

  local FIELD="$SELECTED_INDEX"
  if (( FIELD == 0 || FIELD == 5 )); then
    msg cancelled; echo
    return
  fi

  local REENABLE=0
  # Alterar só os drop-ins de outros serviços não justifica remontar.
  # Changing only other services' drop-ins is no reason to remount.
  local REMOUNT=1

  case "$FIELD" in
    1)
      if [[ -z "$TARGET_CRED" || ! -f "$TARGET_CRED" ]]; then
        echo "$(msg cred_not_found) ${TARGET_CRED:-?}"; echo
        return
      fi
      echo
      read -rp "$(msg ask_user)" USERNAME
      read -rsp "$(msg ask_pass)" PASSWORD
      echo
      read -rp "$(msg ask_domain)" DOMAIN

      msg writing_cred; echo
      printf 'username=%s\npassword=%s\n' "$USERNAME" "$PASSWORD" \
        | sudo tee "$TARGET_CRED" > /dev/null
      [[ -n "$DOMAIN" ]] && printf 'domain=%s\n' "$DOMAIN" | sudo tee -a "$TARGET_CRED" > /dev/null
      sudo chown root:root "$TARGET_CRED"
      sudo chmod 600 "$TARGET_CRED"
      ;;
    2)
      CURRENT_VER="$(grep -m1 -oE 'vers=[^,]+' "$TARGET_UNIT" | cut -d= -f2 || echo "?")"
      echo
      echo "$(msg current_smbver) $CURRENT_VER"
      read -rp "$(msg ask_smbver)" NEW_VER
      NEW_VER="${NEW_VER:-3.0}"

      echo "$(msg generating) $TARGET_UNIT"
      sudo sed -i -E "s/(vers=)[^,]+/\1${NEW_VER}/" "$TARGET_UNIT"
      ;;
    3)
      local CUR_MODE CUR_WAIT NEW_MODE NEW_TMO NEW_WAIT NEW_DEADLINE
      local DESC WHAT WHERE OPTS SRV
      CUR_MODE="$(unit_boot_mode "$TARGET_UNIT")"
      CUR_WAIT="$(unit_wait_unit "$TARGET_UNIT")"
      echo
      echo "$(msg current_boot) $(boot_mode_label "$CUR_MODE" "$CUR_WAIT")"
      echo
      msg boot_q; echo
      menu_select \
        "$(msg boot_opt_nowait)" \
        "$(msg boot_opt_wait)" \
        "$(msg boot_opt_require)" \
        "$(msg cancel)"
      NEW_MODE="$SELECTED_INDEX"
      if (( NEW_MODE == 0 || NEW_MODE == 4 )); then
        msg cancelled; echo
        return
      fi

      NEW_TMO=30
      NEW_DEADLINE=0
      if (( NEW_MODE > 1 )); then
        (( NEW_MODE == 3 )) && { echo; msg boot_warn_require; echo; }
        echo
        read -rp "$(msg ask_boot_timeout)" NEW_TMO
        NEW_TMO="${NEW_TMO:-90}"
        [[ "$NEW_TMO" =~ ^[0-9]+$ ]] || NEW_TMO=90

        echo
        msg wait_srv_hint1; echo
        msg wait_srv_hint2; echo
        msg wait_srv_hint3; echo
        msg wait_srv_hint4; echo
        echo
        local ANS=""
        read -rp "$(msg wait_srv_q)" ANS
        ANS="${ANS:-y}"
        if [[ "$ANS" == "y" || "$ANS" == "Y" ]]; then
          read -rp "$(msg ask_wait_timeout)" NEW_DEADLINE
          NEW_DEADLINE="${NEW_DEADLINE:-600}"
          [[ "$NEW_DEADLINE" =~ ^[0-9]+$ ]] && (( NEW_DEADLINE > 0 )) || NEW_DEADLINE=600
        fi
      fi

      DESC="$(grep -m1 '^Description=' "$TARGET_UNIT" | cut -d= -f2-)"
      WHAT="$(grep -m1 '^What=' "$TARGET_UNIT" | cut -d= -f2-)"
      WHERE="$(grep -m1 '^Where=' "$TARGET_UNIT" | cut -d= -f2-)"
      OPTS="$(grep -m1 '^Options=' "$TARGET_UNIT" | cut -d= -f2-)"
      # nofail é reaplicado por gerar_unidade conforme o modo escolhido.
      # nofail is re-applied by gerar_unidade according to the chosen mode.
      OPTS="$(sed -E 's/(^|,)nofail(,|$)/\1/; s/,$//; s/^,//' <<< "$OPTS")"

      if (( NEW_MODE > 1 )); then
        echo
        verificar_wait_online
      fi

      # //servidor/share -> servidor
      SRV="${WHAT#//}"
      SRV="${SRV%%/*}"

      NEW_WAIT=""
      if (( NEW_DEADLINE > 0 )); then
        NEW_WAIT="$(wait_unit_name "${UNIT_NAME%.mount}")"
        echo
        echo "$(msg generating_wait) $UNIT_DIR/$NEW_WAIT"
        gerar_unidade_espera "${UNIT_NAME%.mount}" "$SRV" "$WHERE" "$NEW_DEADLINE" > /dev/null
      elif [[ -n "$CUR_WAIT" ]]; then
        echo
        msg removing_wait; echo
        remover_unidade_espera "${UNIT_NAME%.mount}"
      fi

      echo
      echo "$(msg generating) $TARGET_UNIT"
      gerar_unidade "$TARGET_UNIT" "$DESC" "$WHAT" "$WHERE" "$OPTS" "$NEW_MODE" "$NEW_TMO" "$NEW_WAIT"
      REENABLE=1
      ;;
    4)
      local ESC CUR_DEPS
      ESC="${UNIT_NAME%.mount}"
      CUR_DEPS="$(listar_dependencias "$ESC")"
      echo
      echo "$(msg current_deps) ${CUR_DEPS:-$(msg deps_none_now)}"

      escolher_dependencias "$CUR_DEPS"

      echo
      msg deps_updating; echo
      remover_dependencias "$ESC"
      if [[ -n "$DEP_SERVICES" ]]; then
        # Divisão intencional em palavras: lista separada por espaços.
        # Intentional word splitting: whitespace-separated list.
        # shellcheck disable=SC2086
        aplicar_dependencias "$ESC" "$TARGET_WHERE" $DEP_SERVICES
      fi
      REMOUNT=0
      ;;
    *)
      msg invalid_opt; echo
      return
      ;;
  esac

  msg validating; echo
  systemd-analyze verify "$TARGET_UNIT" 2>&1 || {
    msg unit_error; echo
    return
  }

  msg reloading_sd; echo
  sudo systemctl daemon-reload

  # A troca de modo muda a seção [Install]; refazer os symlinks.
  # Switching modes changes the [Install] section; redo the symlinks.
  if (( REENABLE == 1 )); then
    echo "$(msg enabling) $UNIT_NAME"
    sudo systemctl disable "$UNIT_NAME" &>/dev/null || true
    sudo systemctl enable "$UNIT_NAME" || true
  fi

  if (( REMOUNT == 1 )) && mountpoint -q "$TARGET_WHERE" 2>/dev/null; then
    echo "$(msg remounting) $UNIT_NAME"
    sudo systemctl restart "$UNIT_NAME" || true
  fi

  msg unit_status; echo
  sudo systemctl status "$UNIT_NAME" --no-pager || true

  echo
  msg edit_done; echo
}

# ╔══════════════════════════════════════════════════════════════╗
# ║  MENU PRINCIPAL                                              ║
# ╚══════════════════════════════════════════════════════════════╝

while true; do
  echo
  echo "╔══════════════════════════════════════╗"
  printf "║  %-36s║\n" "$(msg title)"
  printf "║  %-36s║\n" "$(msg title_by)"
  echo "╚══════════════════════════════════════╝"
  echo

  menu_select \
    "$(msg menu_list)" \
    "$(msg menu_create)" \
    "$(msg menu_delete)" \
    "$(msg menu_edit)" \
    "$(msg menu_exit)"

  case "$SELECTED_INDEX" in
    1) listar_montagens ;;
    2) criar_montagem ;;
    3) excluir_montagem ;;
    4) editar_montagem ;;
    5)
      echo
      msg thanks_line1; echo
      msg thanks_line2; echo
      echo "https://github.com/rogercrocha/smb-wizard-for-linux"
      echo
      exit 0
      ;;
    0) msg leaving; echo; exit 0 ;;
  esac

  echo
  read -rp "$(msg press_enter)" _
done
