#!/bin/bash
if [ -z $ENV_HOME ]; then
  LOCATION=$(pwd)
  export ENV_HOME=$LOCATION
else
  LOCATION=$ENV_HOME
fi
ENV_ALIAS=$1

source_files() {
  source $LOCATION/config/function.zsh
  if [ -f ~/$1.bak ]; then
    mv ~/$1.bak ~/$1
  fi

  cp ~/$1 ~/$1.bak
  source ~/$1
  env > ~/.env_snapshot
  alias > ~/.alias_snapshot
  ls $LOCATION/config/*.* | xargs -I {} echo "[ -f {} ] && source {}" >> ~/$1
  echo "set -o vi" >> ~/$1
  echo "refresh_alias" >> ~/$1
  echo "refresh_env" >> ~/$1
  ls $LOCATION/config/local/.default/*.zsh 2>/dev/null | xargs -I {} echo "[ -f {} ] && source {}" >> ~/$1
  [ -f $LOCATION/config/local/.default/function.zsh ] && source $LOCATION/config/local/.default/function.zsh
  if type private_install > /dev/null 2>&1; then
    echo "Executing default private installation"
    private_install
    unset private_install
  fi
  echo "export ENV_HOME="$LOCATION"" >> ~/$1
  echo "export DEFAULT_ENV_HOME="$LOCATION/config/local/.default"" >> ~/$1
  if [ ! -z $ENV_ALIAS ]; then
    ls $LOCATION/config/local/$ENV_ALIAS/*.zsh 2>/dev/null | xargs -I {} echo "[ -f {} ] && source {}" >> ~/$1
    if [ -f $LOCATION/config/local/.default/addon.zsh ]; then
      source $LOCATION/config/local/.default/addon.zsh
      __addon_install $LOCATION/config/local/$ENV_ALIAS
    fi
    echo "export ENV_ALIAS="$ENV_ALIAS"" >> ~/$1
    echo "echo "You are using environment "$ENV_ALIAS" >> ~/$1
    [ -f $LOCATION/config/local/$ENV_ALIAS/function.zsh ] && source $LOCATION/config/local/$ENV_ALIAS/function.zsh
    [ -f $LOCATION/config/local/$ENV_ALIAS/_function.zsh ] && source $LOCATION/config/local/$ENV_ALIAS/_function.zsh
    if type private_install > /dev/null 2>&1; then
      echo "Executing private installation"
      private_install
      unset private_install
    fi
    echo "export SUBENV_HOME="$LOCATION/config/local/$ENV_ALIAS"" >> ~/$1
  else
    echo "echo "You are using default environment"" >> ~/$1
  fi
}

if [ ! -d $LOCATION/config/local/_put_alias_here/ ]; then
  mkdir -p $LOCATION/config/local/_put_alias_here/
fi

if [ -f ~/.zshrc ]; then
  echo "Shell is running on ZSH"
  source_files .zshrc
elif [ -f ~/.bashrc ]; then
  echo "Shell is running on BASH"
  source_files .bashrc 
elif [ -f ~/.bash_profile ]; then
  echo "Shell is running on BASH PROFILE"
  source_files .bash_profile
else
  echo "No zsh or bash configuration files found."
fi

