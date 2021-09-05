append_to_file() {
    local file="$1"
    local line="$2"
    grep -qF -- "$line" "$file" || echo "$line" | sudo tee -a "$file"
}

main() {
    echo "This is helper module, nothing to execute here"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi