function rezsh {
  if [ "/bin/zsh" = $SHELL ]; then
    source ~/.zshrc
  elif [ "/bin/bash" = $SHELL ]; then
    source ~/.bashrc
  fi
}

function refresh_env() {
  if [ -f ~/.env_snapshot ]; then
    env > ~/.env_latest

    # Process current environment
    while IFS='=' read -r env_name env_value; do
      matched="false"

      # Compare with snapshot
      while IFS='=' read -r name_snapshot value_snapshot; do
        if [ "$env_name" = "$name_snapshot" ]; then
          matched="true"
          if [ "$env_value" != "$value_snapshot" ]; then
            export "$env_name"="$value_snapshot"
          fi
        fi
      done < ~/.env_snapshot

      # Unset if not in the snapshot
      if [ "$matched" = "false" ]; then
        unset "$env_name"
      fi
    done < ~/.env_latest

    # Clean up
    rm ~/.env_latest
  fi
}

function refresh_alias() {
  if [ -f ~/.alias_snapshot ]; then
    alias > ~/.alias_latest

    # Process current environment
    while IFS='=' read -r env_name env_value; do
      matched="false"

      # Compare with snapshot
      while IFS='=' read -r name_snapshot value_snapshot; do
        if [ "$env_name" = "$name_snapshot" ]; then
          matched="true"
          if [ "$env_value" != "$value_snapshot" ]; then
            export "$env_name"="$value_snapshot"
          fi
        fi
      done < ~/.alias_snapshot

      # Unset if not in the snapshot
      if [ "$matched" = "false" ]; then
        unalias "$env_name"
      fi
    done < ~/.alias_latest

    # Clean up
    rm ~/.alias_latest
  fi
}

function env_uninstall() {
  local file_name=""
  if [ -f ~/.zshrc.bak ]; then
     file_name=".zshrc"
  elif [ -f ~/.bashrc.bak ]; then
    file_name=".bashrc"
  elif [ -f ~/.bash_profile.bak ]; then
    file_name=".bash_profile"
  else
    echo "No existing zsh or bash configuration files found."
    return
  fi
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
  if type private_uninstall > /dev/null 2>&1; then
    echo "Executing default private uninstallation"
    private_uninstall
    unset private_uninstall
  fi
  if [ -f ~/$file_name.bak ]; then
    mv ~/$file_name.bak ~/$file_name
  fi
  touch ~/$file_name
  source ~/$file_name
  refresh_alias
  rm -f ~/.alias_snapshot
  refresh_env
  rm -f ~/.env_snapshot
  env_remove_hosts
}

function env_add_hosts() {
  local file_name=$1
  local section=$(sed -n '/# ENVM_SECTION_START/,/# ENVM_SECTION_END/p' /etc/hosts)
  if [ -z "$section" ]; then
    echo "# ENVM_SECTION_START\n# ENVM_SECTION_END" | sudo tee -a /etc/hosts > /dev/null
  fi
  while IFS= read -r host; do
    sudo sed -i '' "/# ENVM_SECTION_END/i\\
    $host\\
    " /etc/hosts
  done < "$file_name"
  sudo sed -i '' 's/# ENVM_SECTION_END/\n# ENVM_SECTION_END/' /etc/hosts
}

function env_remove_hosts() {
  local section=$(sed -n '/# ENVM_SECTION_START/,/# ENVM_SECTION_END/p' /etc/hosts)
  if [ ! -z "$section" ]; then
    sudo sed -i '' '/# ENVM_SECTION_START/,/# ENVM_SECTION_END/d' /etc/hosts
  fi
}

function envm {
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
    env_uninstall 
    $ENV_HOME/install.sh $2
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
  else
    echo "share, jump, add, ls, list, use and del are available commands"
  fi
}

function hint() {
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

function ghx() {
  local workspace=""
  local url="https://github.com/"

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
  if [ "install" = "$1" ]; then
    while IFS='/' read -r user repo; do
      if [ 0 -eq $(ls -1 $workspace | grep -c $repo) ]; then
        cd $workspace
        git clone $url$user/$repo.git
        cd - > /dev/null 2>&1
      fi
    done < $workspace/.ghrc
  elif [ "clean" = "$1" ]; then
    ls -1 $workspace | while read -r line; do
      if [ 0 -eq $(grep -c $line $workspace/.ghrc) ]; then
        echo "Removing repository $line..."
        rm -rf $workspace/$line
      else
        local existing=$(grep $line $workspace/.ghrc | cut -d '/' -f 2)
        if [ "$existing" != "$line" ]; then
          echo "Removing repository $line..."
          rm -rf $workspace/$line
        fi
      fi
    done 
  else
    echo "Only install and clean are available commands"
  fi 
}