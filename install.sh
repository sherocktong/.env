#!/bin/sh
if [ -z $ENV_HOME ]; then
  LOCATION=$(pwd)
else
  LOCATION=$ENV_HOME
fi
ENV_ALIAS=$1

function source_files() {
  if [ -f ~/$1.bak ]; then
    mv ~/$1.bak ~/$1
  fi

  cp ~/$1 ~/$1.bak
  ls $LOCATION/config/*.* | xargs -I {} echo "[ -f {} ] && source {}" >> ~/$1
  ls $LOCATION/config/local/*.* 2>/dev/null | xargs -I {} echo "[ -f {} ] && source {}" >> ~/$1
  if [ ! -z $ENV_ALIAS ]; then
    ls $LOCATION/config/local/$ENV_ALIAS/*.* 2>/dev/null | xargs -I {} echo "[ -f {} ] && source {}" >> ~/$1
    echo "export ENV_ALIAS="$ENV_ALIAS"" >> ~/$1
  fi
  touch ~/$1
}

if [[ ! -d $LOCATION/config/local/_put_alias_here/ ]]; then
  mkdir -p $LOCATION/config/local/_put_alias_here/
fi

if [[ "/bin/zsh" == "$SHELL" ]]; then
  echo "Shell is running on ZSH"
  source_files .zshrc
elif [[ -f ~/.bashrc ]]; then
  echo "Shell is running on BASH"
  source_files .bashrc 
elif [[ -f ~/.bash_profile ]]; then
  echo "Shell is running on BASH PROFILE"
  source_files .bash_profile
else
  echo "No zsh or bash configuration files found."
fi

