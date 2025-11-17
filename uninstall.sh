#!/bin/bash
source $ENV_HOME/config/function.zsh
__env_uninstall

rm -f ~/$(__get_sh_config_file).bak
# rm -f ~/.env_snapshot
# rm -f ~/.alias_snapshot

