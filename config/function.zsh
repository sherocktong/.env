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
    rm ~/.env_snapshot
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
    rm ~/.alias_snapshot
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
  if [ -f ~/$file_name.bak ]; then
    mv ~/$file_name.bak ~/$file_name
  fi
  touch ~/$file_name
  source ~/$file_name
  refresh_alias
  refresh_env
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
      echo "You are using environment " $ENV_ALIAS
    fi
  elif [ "ls" = "$1" ]; then
    ls -f $ENV_HOME/config/local/$2/*
  elif [ "share" = "$1" ]; then
    ln -s $ENV_HOME/config/local/$3/$2 $ENV_HOME/config/local/$4/_$2
  else
    echo "share, jump, add, ls, list, use and del are available commands"
  fi
}
