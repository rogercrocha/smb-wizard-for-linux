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
    edit_choose_field) echo "Escolha [0/1/2]: " ;;
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
  esac
}

# ── Strings EN ───────────────────────────────────────────────────────────────
msg_en() {
  case "$1" in
    title)           echo "SMB Mount Manager" ;;
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
    edit_choose_field) echo "Choose [0/1/2]: " ;;
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

# ╔══════════════════════════════════════════════════════════════╗
# ║  FUNÇÕES AUXILIARES                                          ║
# ╚══════════════════════════════════════════════════════════════╝

coletar_montagens() {
  UNIT_FILES=()
  WHATS=()
  WHERES=()
  CREDS=()

  for unit_file in "$UNIT_DIR"/*.mount; do
    [[ -f "$unit_file" ]] || continue
    grep -q 'Type=cifs' "$unit_file" 2>/dev/null || continue
    UNIT_FILES+=("$unit_file")
    WHATS+=("$(grep -m1 '^What=' "$unit_file" | cut -d= -f2-)")
    WHERES+=("$(grep -m1 '^Where=' "$unit_file" | cut -d= -f2-)")
    CREDS+=("$(grep -m1 'credentials=' "$unit_file" | grep -o 'credentials=[^ ,]*' | cut -d= -f2- || true)")
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
  echo
  read -rp "$(msg proceed)" CONFIRM
  CONFIRM="${CONFIRM:-n}"
  [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]] || { msg aborted; echo; return; }

  if command -v smbclient &>/dev/null; then
    local MAX_AUTH_RETRIES=3
    local attempt=1
    while true; do
      echo
      echo "$(msg preflight_check) //$SERVER/$SHARE"
      local PREFLIGHT_OUTPUT="" PREFLIGHT_FAILED=0
      if [[ -n "$DOMAIN" ]]; then
        PREFLIGHT_OUTPUT="$(PASSWD="$PASSWORD" timeout 15 smbclient "//$SERVER/$SHARE" -U "$USERNAME" -W "$DOMAIN" -c "quit" 2>&1)" || PREFLIGHT_FAILED=1
      else
        PREFLIGHT_OUTPUT="$(PASSWD="$PASSWORD" timeout 15 smbclient "//$SERVER/$SHARE" -U "$USERNAME" -c "quit" 2>&1)" || PREFLIGHT_FAILED=1
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

  echo "$(msg generating) $UNIT_FILE"
  sudo tee "$UNIT_FILE" > /dev/null <<EOF
[Unit]
Description=SMB Mount $MOUNTPOINT ($SHARE)
Requires=network-online.target
After=network-online.target

[Mount]
What=//$SERVER/$SHARE
Where=$MOUNTPOINT
Type=cifs
Options=credentials=$CRED_FILE,vers=$SMB_VERSION,iocharset=utf8,file_mode=0777,dir_mode=0777,_netdev,nofail
TimeoutSec=30

[Install]
WantedBy=multi-user.target
EOF
  sudo chown root:root "$UNIT_FILE"
  sudo chmod 644 "$UNIT_FILE"

  msg validating; echo
  systemd-analyze verify "$UNIT_FILE" 2>&1 || {
    msg unit_error; echo
    sudo rm -f "$UNIT_FILE"
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
      sudo systemctl daemon-reload
      sudo systemctl reset-failed "${UNIT_NAME}.mount" 2>/dev/null || true
      sudo rmdir "$MOUNTPOINT" 2>/dev/null || true
      msg rollback_done; echo
    else
      msg rollback_kept; echo
    fi
    return
  fi

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
    "$(msg cancel)"

  local FIELD="$SELECTED_INDEX"
  if (( FIELD == 0 || FIELD == 3 )); then
    msg cancelled; echo
    return
  fi

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

  if mountpoint -q "$TARGET_WHERE" 2>/dev/null; then
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
    5|0) msg leaving; echo; exit 0 ;;
  esac

  echo
  read -rp "$(msg press_enter)" _
done
