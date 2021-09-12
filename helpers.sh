# Common helper functions to be shared in other scripts

helpers::check_email_var() {
    if [ -z ${EMAIL+x} ]; then
        echo "No EMAIL environment variable available, bailing"
        exit 1
    fi
}

helpers::append_to_file() {
    # Appends text to file if it does not exists there yet
    # Idempotency FTW --> safe to call multiple times with same args
    # Args:
    #   $1 path to file
    #   $2 text to append to file
    if [ -z ${1+x} ] || [ -z ${2+x} ]; then
        echo "Invalid usage, needs 2 argumets: filepath and line to appends"
        exit 1
    fi
    local file="$1"
    local line="$2"
    grep -qF -- "$line" "$file" || echo "$line" | sudo tee -a "$file"
}

helpers::append_to_shell_files() {
    # Helper to append lines to _all_ the different shell files with single
    # command currently bash and zsh, due Macs transition from bash to zsh as
    # the default shell.
    # In case the line needs a shell specific part there is %SHELL_NAME% macro
    # that is replaced with the shell name
    if [ -z ${1+x} ]; then
        echo "Invalid usage, needs an argument: line to append to shell files"
        exit 1
    fi
    touch ~/.bash_profile
    touch ~/.zshrc
    SHELL_NAME="bash"
    formated_str=$(sed 's/%SHELL_NAME%/'"$SHELL_NAME"'/g' <<<"$1")
    helpers::append_to_file ~/.bash_profile "$formated_str"
    SHELL_NAME="zsh"
    formated_str=$(sed 's/%SHELL_NAME%/'"$SHELL_NAME"'/g' <<<"$1")
    helpers::append_to_file ~/.zshrc "$formated_str"
}

helpers::main() {
    echo "This is helper module, nothing to execute here"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    helpers::main "$@"
fi