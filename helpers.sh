check_email_var() {
    if [ -z ${EMAIL+x} ]; then
        echo "No EMAIL variable available, bailing"
        exit 1
    fi
}

append_to_file() {
    # Appends text to file if it does not exists there yet
    # --> safe to call multiple times with same args
    local file="$1"
    local line="$2"
    grep -qF -- "$line" "$file" || echo "$line" | sudo tee -a "$file"
}

append_to_shell_files() {
    # both bash and zsh
    touch ~/.bash_profile
    touch ~/.zshrc
    append_to_file ~/.bash_profile "$1"
    append_to_file ~/.zshrc "$1"
}

main() {
    echo "This is helper module, nothing to execute here"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi