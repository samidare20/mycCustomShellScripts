
if [ -n "${BASH_SOURCE-}" ]; then
	__main_file="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION-}" ]; then
	__main_file="${(%):-%N}"
else
	__main_file="$0"
fi
__main_dir="$(cd "$(dirname "${__main_file}")" 2>/dev/null && pwd)"

# Project line counter
count-lines() {
	"${__main_dir}/CountProjectLine.sh" "$@"
}

# Legacy alias for backward compatibility
cpl() {
	count-lines "$@"
}

# Load KeyBind settings
if [ -f "${__main_dir}/KeyBind.sh" ]; then
	source "${__main_dir}/KeyBind.sh"
fi
if [ -f "${__main_dir}/aliass.sh" ]; then
	source "${__main_dir}/aliass.sh"
fi
# Display available commands
show-commands() {
	echo "Available commands:"
	echo "  count-lines [options] - Calculate project line count"
	echo "    -s, --show          - Show current directory history"
	echo "  cpl [options]         - Alias for count-lines"
	echo "  show-commands         - Show this help"
	echo ""
	echo "Current directory: ${PWD}"
}