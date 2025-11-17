#!/bin/bash

function __backup() {
  cp ~/$1 ~/$1.bak
}

function __print_source_cmd() {
  local runtime=$(__get_sh_runtime)
  if [ $runtime = "ZSH" ]; then
    echo 'source ~/.zshrc'
  else
    echo 'source ~/.bashrc'
  fi 
}

if [ -z $ENV_HOME ]; then
  LOCATION=$(pwd)
  export ENV_HOME=$LOCATION
else
  LOCATION=$ENV_HOME
fi

source $ENV_HOME/config/function.zsh

# if [ ! -f ~/.env_snapshot ]; then
#   env > ~/.env_snapshot
# fi
# if [ ! -f ~/.alias_snapshot ]; then
#   if [ "ZSH" == $(__get_sh_runtime) ]; then
#     zsh $ENV_HOME/config/zsh/print_alias.zsh .alias_snapshot
#   else
#     alias > ~/.alias_snapshot
#   fi
# fi 

if [ ! -d $LOCATION/config/local/_put_alias_here/ ]; then
  mkdir -p $LOCATION/config/local/_put_alias_here/
fi
__print_sh_runtime
__backup $(__get_sh_config_file)
__env_install default
source $ENV_HOME/config/function.zsh
rezsh
echo "✅Installed successfully"
