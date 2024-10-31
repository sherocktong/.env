function fetch_to_clipboard() {
    local file=$1
    local start_line=$2
    local end_line=$3

    if [[ -z $end_line ]]; then
        sed -n "${start_line}p" "$file" | pbcopy
    else
        sed -n "${start_line},${end_line}p" "$file" | pbcopy
    fi
}

function determine() {
    # Get the list of tokens from the parameter
    # IFS=','

    echo "Start searching file: $1"
    # Check if the file exists
    if [ -f $1 ]; then
      # Loop through each token and check if it exists in the file
      while read -r token; do
        count=$(grep -c "$token" "$1")
        if [ "$count" -gt 0 ]; then
          echo "$token exists $count times in $1."
          grep -n "$token" "$1"
        fi
      done <<< "$(echo "$GREP_TOKENS" | tr ' ' '\n')"
    else
        echo "$1 NOT existing."
    fi
}

function split_by() {
    index=$3
    to_index=$(($4 + 1))
    token=""
    while [ $index -lt $to_index ]; do
        token+=$(echo "$1" | cut -d "$2" -f $index)"/"
        index=$((index + 1))
    done
    echo $token
}

function decompress_jars() {
    if [ -z "$1" ]; then
        echo "Usage: decompress_jars <directory>"
        return 1
    fi

    decompress $1 jar
}

function decompress() {
    if [ -z "$1" ]; then
        echo "Usage: decompress <directory> <extension>"
        return 1
    fi

    local dir="$1"

    for jar_file in $(find $dir -type f -name "*.$2"); do
        local jar_dir=$(dirname "$jar_file")
        local jar_name=$(basename "$jar_file")
        local temp_dir="$jar_dir/$jar_name.temp"

        # Create a temporary directory
        mkdir -p "$temp_dir"

        if [ "$2" = "gz" ]; then
          gunzip -fk $jar_file
        else 
          # Extract the JAR contents to the temporary directory
          unzip -oq $jar_file -d $temp_dir 
          # jar xf "$jar_file" -c "$temp_dir"
        fi
    done
}

function set_tunnel() {
    ssh -v $7 -Ni ~/.ssh/$1 -L $6:$4:$5 $2@$3
}

function brew_prefix {
  echo $(brew --prefix $1)
}

function envm {
  if [ "list" = "$1" ]; then
    ls -d $ENV_HOME/config/local/*/ | xargs -n 1 basename
  elif [ "del" = "$1" ]; then
    rm -rf $ENV_HOME/config/local/$2/
  elif [ "use" = "$1" ]; then
    $ENV_HOME/switch.sh $2
    rezsh
  elif [ "add" = "$1" ]; then
    mkdir -p $ENV_HOME/config/local/$2/
  elif [ "jump" = "$1" ]; then
    cd $ENV_HOME/config/local/$2/
  else
    echo "jump, add, list, use and del are available commands"
  fi
}

function rezsh {
  if [ "/bin/zsh" = $SHELL ]; then
    source ~/.zshrc
  elif [ "/bin/bash" = $SHELL ]; then
    source ~/.bashrc
  fi
}