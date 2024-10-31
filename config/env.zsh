set -o vi
export ENV_HOME="$HOME/.env"
export PATH=/usr/local/bin:$PATH

if [ 1 -eq $(lsof -ni -P | grep LISTEN | grep -c "7890") ]; then
  export https_proxy=http://127.0.0.1:7890
  export http_proxy=http://127.0.0.1:7890
  export all_proxy=socks5://127.0.0.1:7890
  ln -sf ~/.docker/config.proxy.json ~/.docker/config.json
  if command -v npm &> /dev/null; then
    npm config set proxy $http_proxy
    npm config set https-proxy $https_proxy
  fi
else
  unset https_proxy http_proxy all_proxy
  ln -sf ~/.docker/config.nonproxy.json ~/.docker/config.json
  if command -v npm &> /dev/null; then
    npm config delete proxy
    npm config delete https-proxy
  fi
fi