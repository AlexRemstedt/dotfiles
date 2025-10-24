# Simple file loading function
load_module() {
    local module_file="${HOME}/.config/zsh/conf.d/${1}"
    [[ -f "$module_file" ]] && source "$module_file"
}

# Batch load multiple configuration files
load_modules() {
    for module in "$@"; do
        load_module "$module"
    done
}

