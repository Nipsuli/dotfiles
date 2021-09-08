append_to_file() {
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