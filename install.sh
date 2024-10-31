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
    echo "echo "Environment Using: $ENV_ALIAS"" >> ~/$1
  fi
  touch ~/$1
}

if [ "/bin/zsh" = "$SHELL" ]; then
  source_files .zshrc
elif [ -f ~/.bash_profile ]; then
  source_files .bash_profile
elif [ -f ~/.bashrc ]; then
  source_files .bashrc 
else
  echo "No zsh or bash configuration files found."
fi

