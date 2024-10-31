#!/bin/sh

function uninstall() {
    mv ~/$1.bak ~/$1
}

if [ -f ~/.zshrc.bak ]; then
  uninstall .zshrc
elif [ -f ~/.bashrc.bak ]; then
  uninstall .bashrc 
elif [ -f ~/.bash_profile.bak ]; then
  uninstall .bash_profile
else
  echo "No zsh or bash configuration files found."
fi