#!/bin/sh

function uninstall() {
    mv ~/$1.bak ~/$1
}

if [ -f ~/.zshrc ]; then
  uninstall .zshrc
elif [ -f ~/.bash_profile ]; then
  uninstall .bash_profile
elif [ -f ~/.bashrc ]; then
  uninstall .bashrc 
else
  echo "No zsh or bash configuration files found."
fi