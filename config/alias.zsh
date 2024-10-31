alias unproxy='unset all_proxy http_proxy https_proxy'
alias list_certs='find ~/.ssh -name "*.pub" | xargs grep .com'
alias logging='script ~/.zsh_sessions/$(date +"%Y-%m-%d_%H-%M-%S").log'
alias knock='lsof -ni -P | grep LISTEN | grep'
alias time-curl='time curl -o /dev/null -s'

