#!/bin/bash
source $ENV_HOME/config/function.zsh
if [ -d $ENV_HOME/config/mods ]; then
  for f in "$ENV_HOME/config/mods/"*.zsh; do
    [[ -e "$f" ]] || continue
    source "$f"
  done
fi

__env_uninstall

rm -f ~/$(__get_sh_config_file).bak
# rm -f ~/.env_snapshot
# rm -f ~/.alias_snapshot

