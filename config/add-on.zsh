function __hosts_install() {
  local file_name=$1/hosts
  if [ ! -f $file_name ]; then
    return
  fi

  local section=$(sed -n '/# ENVM_SECTION_START/,/# ENVM_SECTION_END/p' /etc/hosts)
  if [ -z "$section" ]; then
    echo "# ENVM_SECTION_START\n# ENVM_SECTION_END" | sudo tee -a /etc/hosts > /dev/null
  fi
  while IFS= read -r host; do
    sudo sed -i '' "/# ENVM_SECTION_END/i\\
$host\\
" /etc/hosts
  done < "$file_name"
  sudo sed -i '' 's/# ENVM_SECTION_END/\n# ENVM_SECTION_END/' /etc/hosts
}

function __hosts_uninstall() {
  local section=$(sed -n '/# ENVM_SECTION_START/,/# ENVM_SECTION_END/p' /etc/hosts)
  if [ ! -z "$section" ]; then
    sudo sed -i '' '/# ENVM_SECTION_START/,/# ENVM_SECTION_END/d' /etc/hosts
  fi
}

function __dnsmasq_install() {
  local file_name=$1/dnsmasq
  if [ ! -f $file_name ]; then
    return
  fi

  local section=$(sed -n '/# ENVM_SECTION_START/,/# ENVM_SECTION_END/p' $(brew --prefix)/etc/dnsmasq.conf)
  if [ -z "$section" ]; then
    echo "# ENVM_SECTION_START\n# ENVM_SECTION_END" | tee -a $(brew --prefix)/etc/dnsmasq.conf > /dev/null
  fi
  while read -r host; do
    sed -i '' "/# ENVM_SECTION_END/i\\
$host" $(brew --prefix)/etc/dnsmasq.conf
  done < "$file_name"
  sed -i '' 's/# ENVM_SECTION_END/\n# ENVM_SECTION_END/' $(brew --prefix)/etc/dnsmasq.conf
}

function __dnsmasq_uninstall() {
  local section=$(sed -n '/# ENVM_SECTION_START/,/# ENVM_SECTION_END/p' $(brew --prefix)/etc/dnsmasq.conf)
  if [ ! -z "$section" ]; then
    sed -i '' '/# ENVM_SECTION_START/,/# ENVM_SECTION_END/d' $(brew --prefix)/etc/dnsmasq.conf
  fi
}

function __resolver_install() {
  local file_name=$1/resolver
  if [ ! -f $file_name ]; then
    return
  fi
  while IFS='=' read -r host ip; do
    echo "nameserver $ip" | sudo tee /etc/resolver/$host > /dev/null
  done < "$file_name"
}

function __resolver_uninstall() {
  if [ -d /etc/resolver ]; then
    local files=$(ls -1 /etc/resolver)
    for file in $files; do
      sudo rm -rf /etc/resolver/$file
    done
  fi
}
