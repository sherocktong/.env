#!/bin/bash
rezsh() {
  if [ "/bin/zsh" = $SHELL ]; then
    source ~/.zshrc
  elif [ "/bin/bash" = $SHELL ]; then
    source ~/.bashrc
  fi
}

__print_sh_runtime() {
  if [ $(__get_sh_runtime) = "ZSH" ]; then
    echo "Shell is running on ZSH"
  else 
    echo "Shell is running on BASH"
  fi
}

__get_sh_config_file() {
  local runtime=$(__get_sh_runtime)
  if [ $runtime = "ZSH" ]; then
    echo ".zshrc"
  else
    if [ -f ~/.bash_profile ]; then
      echo ".bash_profile"
    else
      echo ".bashrc"
    fi
  fi
}

__get_sh_runtime() {
  if [ "/bin/zsh" = $SHELL ]; then
    echo "ZSH"
  else
    echo "BASH"
  fi
}

__refresh_env() {
  local home_dir="$ENV_HOME"
  local general_home="$HOME"
  if [ -z "$home_dir" ]; then
    echo "ERROR: ENV_HOME not found" >&2
    return 1
  fi
  local keep_file="$home_dir/config/env.whitelist"

  if [[ ! -f "$keep_file" ]]; then
    echo "Error: Env whitelist file not found: $keep_file. Please run \`cp $keep_file.template $keep_file\` to create one" >&2
    return 1
  fi

  local var allowed keep

  while IFS= read -r var; do
    if [[ "$var" == T_* ]]; then
      unset "$var"
      continue
    fi

    keep=0

    while IFS= read -r allowed; do
      [[ -z "$allowed" || "$allowed" == \#* ]] && continue

      if [[ "$var" == *"$allowed"* ]]; then
        keep=1
        break
      fi
    done < "$keep_file"

    [[ "$keep" -eq 0 ]] && unset "$var"

  done < <(printenv | cut -d= -f1)

  export ENV_HOME="$home_dir"
  export HOME="$general_home"
}

__refresh_alias() {
  unalias -a
}

__env_uninstall() {
  local file_name="$(__get_sh_config_file)"
  if type private_uninstall > /dev/null 2>&1; then
    unset -f private_uninstall
  fi
  if [ ! -z $ENV_ALIAS ]; then
    [ -f $ENV_HOME/config/local/$ENV_ALIAS/function.zsh ] && source $ENV_HOME/config/local/$ENV_ALIAS/function.zsh
    [ -f $ENV_HOME/config/local/$ENV_ALIAS/_function.zsh ] && source $ENV_HOME/config/local/$ENV_ALIAS/_function.zsh
    if type private_uninstall > /dev/null 2>&1; then
      echo "Executing private uninstallation"
      private_uninstall
      unset private_uninstall
    fi
  fi

  [ -f $ENV_HOME/config/local/.default/function.zsh ] && source $ENV_HOME/config/local/.default/function.zsh
  [ -f $ENV_HOME/config/local/.default/addon.zsh ] && source $ENV_HOME/config/local/.default/addon.zsh
  if type private_uninstall > /dev/null 2>&1; then
    echo "Executing default private uninstallation"
    private_uninstall
    unset private_uninstall
  fi
  sed -i '' '/^# >>> envm initialize >>>/,/^# <<< envm initialize <<</d' ~/$file_name 2>/dev/null
  touch ~/$file_name
  __refresh_alias
  # rm -f ~/.alias_snapshot
  __refresh_env
  # rm -f ~/.env_snapshot
  __addon_uninstall
  source ~/$file_name
  # remove all __envm_precmd registrations from the current shell
  precmd_functions=("${(@)precmd_functions:#__envm_precmd}")
}

__addon_uninstall() {
  return
}

__addon_install() {
  return
}

__env_install() {
  local target_file
  target_file="$(__get_sh_config_file)"
  local ENV_ALIAS="$1"

  __envm_precmd() {
    local name="${ENV_ALIAS:-default}"
    local new_prefix="($name) "
    [[ -n "$__ENVM_PRECMD_PREFIX" ]] && PROMPT="${PROMPT//${__ENVM_PRECMD_PREFIX}/}"
    PROMPT="${new_prefix}${PROMPT}"
    __ENVM_PRECMD_PREFIX="$new_prefix"
  }

  __append_sources() {
    setopt local_options nonomatch 2>/dev/null
    local dir="$1"
    [ -d "$dir" ] || return

    for f in "$dir"/*.zsh; do
      [ -e "$f" ] || continue
      echo "[ -f \"$f\" ] && source \"$f\"" >> ~/"$target_file"
    done
  }

  # remove any leftover env echo from previous install
  sed -i '' '/^echo "You are using/d' ~/"$target_file"

  # load existing config
  [ -f ~/"$target_file" ] && source ~/"$target_file"

  echo "# >>> envm initialize >>>" >> ~/"$target_file"

  # base configs
  __append_sources "$ENV_HOME/config"

  echo "set -o vi" >> ~/"$target_file"
  echo "export ENV_HOME=\"$ENV_HOME\"" >> ~/"$target_file"
  echo "__refresh_alias" >> ~/"$target_file"
  echo "__refresh_env" >> ~/"$target_file"

  __append_sources "$ENV_HOME/config/mods"
  __append_sources "$ENV_HOME/config/local/.default"

  # load default function
  if [ -f "$ENV_HOME/config/local/.default/function.zsh" ]; then
    source "$ENV_HOME/config/local/.default/function.zsh"
  fi

  # run private_install if defined
  if type private_install >/dev/null 2>&1; then
    echo "Executing default private installation"
    private_install
    unset -f private_install 2>/dev/null
  fi

  echo "export DEFAULT_ENV_HOME=\"$ENV_HOME/config/local/.default\"" >> ~/"$target_file"

  {
    echo "__envm_precmd() {"
    echo "  local name=\"\${ENV_ALIAS:-default}\""
    echo "  local new_prefix=\"(\$name) \""
    echo "  [[ -n \"\$__ENVM_PRECMD_PREFIX\" ]] && PROMPT=\"\${PROMPT//\${__ENVM_PRECMD_PREFIX}/}\""
    echo "  PROMPT=\"\${new_prefix}\${PROMPT}\""
    echo "  __ENVM_PRECMD_PREFIX=\"\$new_prefix\""
    echo "}"
    echo "autoload -Uz add-zsh-hook && add-zsh-hook precmd __envm_precmd"
  } >> ~/"$target_file"

  if [ -n "$ENV_ALIAS" ]; then

    __append_sources "$ENV_HOME/config/local/$ENV_ALIAS"

    if [ -f "$ENV_HOME/config/local/.default/addon.zsh" ]; then
      source "$ENV_HOME/config/local/.default/addon.zsh"
      __addon_install "$ENV_HOME/config/local/$ENV_ALIAS"
    fi

    echo "export ENV_ALIAS=\"$ENV_ALIAS\"" >> ~/"$target_file"
    echo "echo \"You are using environment $ENV_ALIAS\"" >> ~/"$target_file"

    [ -f "$ENV_HOME/config/local/$ENV_ALIAS/function.zsh" ] && \
      source "$ENV_HOME/config/local/$ENV_ALIAS/function.zsh"

    [ -f "$ENV_HOME/config/local/$ENV_ALIAS/_function.zsh" ] && \
      source "$ENV_HOME/config/local/$ENV_ALIAS/_function.zsh"

    if type private_install >/dev/null 2>&1; then
      echo "Executing private installation"
      private_install
      unset -f private_install 2>/dev/null
    fi

    echo "export SUBENV_HOME=\"$ENV_HOME/config/local/$ENV_ALIAS\"" >> ~/"$target_file"

  else
    echo "echo \"You are using default environment\"" >> ~/"$target_file"
  fi

  echo "# <<< envm initialize <<<" >> ~/"$target_file"
}

envm() {
  if [ -z $ENV_HOME ]; then
    echo "ENV_HOME is not set"
    exit 1
  fi
  if [ "list" = "$1" ]; then
    for file in $(ls -d $ENV_HOME/config/local/*/); do
      local file_name=$(basename $file)
      if [[ "_put_alias_here" == $file_name ]]; then
        continue
      fi
      echo $(basename $file)
    done
  elif [ "del" = "$1" ]; then
    rm -rf $ENV_HOME/config/local/$2/
  elif [ "use" = "$1" ]; then
    if [ ! -z $2 ]; then
      if [ ! -d $ENV_HOME/config/local/$2/ ]; then
        echo "Environment $2 does not exist"
        return 1
      fi
    fi
    if [ -d $ENV_HOME/config/mods ]; then
      for f in "$ENV_HOME/config/mods/"*.zsh; do
        [[ -e "$f" ]] || continue
        source "$f"
      done
    fi
    __env_uninstall 
    if [ -z "$1" ]; then
      __env_install "default"
    else 
      __env_install $2
    fi
    rezsh
  elif [ "add" = "$1" ]; then
    mkdir -p $ENV_HOME/config/local/$2/
  elif [ "jump" = "$1" ]; then
    cd $ENV_HOME/config/local/$2/
  elif [ "info" = "$1" ]; then
    if [ -z $ENV_ALIAS ]; then
      echo "You are using default environment"
    else
      echo "You are using environment "$ENV_ALIAS
    fi
  elif [ "ls" = "$1" ]; then
    ls -alfG $ENV_HOME/config/local/$2/*
  elif [ "share" = "$1" ]; then
    ln -s $ENV_HOME/config/local/$3/$2 $ENV_HOME/config/local/$4/_$2
  elif [ "link" = "$1" ]; then
    if [ -z $X ]; then
      echo "Please set environment variable X to use this function"
      return 1
    fi
    ln -s $X/$2 $ENV_HOME/config/local/$3
  else
    echo "share, jump, add, ls, list, use, link and del are available commands"
  fi
}

hint() {
  if [ ! -z $ENV_HOME ]; then
    if [ -f $ENV_HOME/config/local/.default/hint ]; then
      cat $ENV_HOME/config/local/.default/hint
    fi
  fi

  if [ ! -z $ENV_ALIAS ]; then
    if [ -f $ENV_HOME/config/local/$ENV_ALIAS/hint ]; then
      cat $ENV_HOME/config/local/$ENV_ALIAS/hint
    fi
  fi
}

ghx() {
  local workspace=""
  local url="https://github.com/"
  local dry_run=0
  local cmd=""

  for arg in "$@"; do
    if [ "$arg" = "-d" ]; then
      dry_run=1
    elif [ -z "$cmd" ]; then
      cmd="$arg"
    fi
  done

  if [ ! -z $GHX_DISABLED ] && [[ 1 -eq $GHX_DISABLED ]]; then
    echo "GHX is disabled"
    return 1
  fi
  if [ ! -z $GHX_URL ]; then
    url=$GHX_URL
  fi
  if [ -z $ENV_ALIAS ]; then
    if [ -z $X ]; then
      echo "Please set environment variable X to use this function"
      return 1
    else
      workspace=$X
    fi
  else
    if [ -z $WORKSPACE ]; then
      echo "Please set environment variable WORKSPACE to use this function"
      return 1
    else
      workspace=$WORKSPACE
    fi
  fi
  if [ ! -f $workspace/.ghrc ]; then
    echo "Please create a .ghrc file under the root directory of workspace"
    return 1
  fi
  if [ "install" = "$cmd" ]; then
    while IFS='/' read -r user repo; do
    local install_flag=0
      if [ 0 -eq $(ls -1 $workspace | grep -c $repo) ]; then
        install_flag=1
      else
        local existing=$(ls -1 $workspace | grep $repo)
        echo $existing | while read -r existing_line; do
          if [ "$existing_line" = "$repo" ]; then
            install_flag=0
            break
          else
            install_flag=1
          fi
        done
      fi
      if [ 1 -eq $install_flag ]; then
        if [ 1 -eq $dry_run ]; then
          echo "[dry-run] Would clone $url$user/$repo.git"
        else
          cd $workspace
          git clone $url$user/$repo.git
          cd - > /dev/null 2>&1
        fi
      fi
    done < $workspace/.ghrc
  elif [ "clean" = "$cmd" ]; then
    local delete_flag=0
    local global_ignore
    global_ignore=$(git config --global --path core.excludesfile 2>/dev/null)
    ls -1 $workspace | while read -r line; do
      delete_flag=0
      if [ 0 -eq $(grep -c "$line" $workspace/.ghrc) ]; then
        delete_flag=1
      else
        local existing=$(grep "$line" $workspace/.ghrc | cut -d '/' -f 2)
        echo "$existing" | while read -r existing_line; do
          if [ "$existing_line" = "$line" ]; then
            delete_flag=0
            break
          else
            delete_flag=1
          fi
        done
      fi
      if [ "$delete_flag" -eq 1 ] && [ -f "$global_ignore" ]; then
        while IFS= read -r pattern; do
          [[ -z "$pattern" || "$pattern" == \#* ]] && continue
          case "$line" in
            $pattern) delete_flag=0; break ;;
          esac
        done < "$global_ignore"
      fi
      if [ 1 -eq $delete_flag ]; then
        if [ 1 -eq $dry_run ]; then
          echo "[dry-run] Would remove repository $line..."
        else
          echo "Removing repository $line..."
          rm -rf "$workspace/$line"
        fi
      fi
    done
  elif [ "add" = "$cmd" ]; then
    if [ ! -d .git ]; then
      echo "Current directory is not a git repository"
      return 1
    fi
    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null)
    if [ -z "$remote_url" ]; then
      echo "No origin remote found in current git repository"
      return 1
    fi
    local user repo
    local clean_url="${remote_url%.git}"
    if [[ "$remote_url" == https://* ]] || [[ "$remote_url" == http://* ]]; then
      user=$(echo "$clean_url" | sed -E 's|https?://[^/]+/([^/]+)/([^/]+)/?$|\1|')
      repo=$(echo "$clean_url" | sed -E 's|https?://[^/]+/([^/]+)/([^/]+)/?$|\2|')
    elif [[ "$remote_url" == git@* ]]; then
      user=$(echo "$clean_url" | sed -E 's|^git@[^:]+:([^/]+)/([^/]+)/?$|\1|')
      repo=$(echo "$clean_url" | sed -E 's|^git@[^:]+:([^/]+)/([^/]+)/?$|\2|')
    else
      echo "Unsupported remote URL format: $remote_url"
      return 1
    fi
    if [ -z "$user" ] || [ -z "$repo" ]; then
      echo "Could not parse user/repo from remote URL: $remote_url"
      return 1
    fi
    local entry="$user/$repo"
    if grep -qx "$entry" "$workspace/.ghrc"; then
      echo "Entry $entry already exists in $workspace/.ghrc"
      return 0
    fi
    if [ 1 -eq $dry_run ]; then
      echo "[dry-run] Would add $entry to $workspace/.ghrc"
    else
      echo "$entry" >> "$workspace/.ghrc"
      echo "Added $entry to $workspace/.ghrc"
    fi
  elif [ "push" = "$cmd" ]; then
    while IFS='/' read -r user repo; do
      local repo_path="$workspace/$repo"
      if [ ! -d "$repo_path/.git" ]; then
        echo "Skipping $user/$repo: not a git repository"
        continue
      fi
      if [ 1 -eq $dry_run ]; then
        echo "[dry-run] Would push $user/$repo"
      else
        echo "Pushing $user/$repo..."
        cd "$repo_path"
        git push
        cd - > /dev/null 2>&1
      fi
    done < "$workspace/.ghrc"
  else
    echo "Only install, clean, add and push are available commands"
  fi
}
