
set -euo pipefail

ZSHRC="${HOME}/.zshrc"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${SCRIPT_DIR}/main.sh"

# 이전 버전들 정리를 위한 패턴들
SUBPATH="${TARGET#${HOME}}"
OLD_PATTERNS=(
  "[ -f \"${TARGET}\" ] && source \"${TARGET}\""
  "[ -f \"\\$HOME${SUBPATH}\" ] && source \"\\$HOME${SUBPATH}\""
  '[ -f "./main.sh" ] && source "./main.sh"'
)

# 현재 디렉토리 기준으로 절대 경로 결정
CURRENT_PWD="$(pwd -P)"
if [[ -f "${CURRENT_PWD}/main.sh" ]]; then
  FINAL_TARGET="${CURRENT_PWD}/main.sh"
else
  FINAL_TARGET="${TARGET}"
fi

LINE_TO_ADD="[ -f \"${FINAL_TARGET}\" ] && source \"${FINAL_TARGET}\""

# ~/.zshrc 파일 존재 확인
touch "${ZSHRC}"

# 기존 항목들 제거
temp_file="${ZSHRC}.tmp"
cp "${ZSHRC}" "${temp_file}"

for pattern in "${OLD_PATTERNS[@]}"; do
  grep -Fvx "${pattern}" "${temp_file}" > "${temp_file}.new" || true
  mv "${temp_file}.new" "${temp_file}"
done

mv "${temp_file}" "${ZSHRC}"

# 새 항목 추가 (중복 확인)
if ! grep -Fqx "${LINE_TO_ADD}" "${ZSHRC}"; then
  printf '\n%s\n' "${LINE_TO_ADD}" >> "${ZSHRC}"
  echo "✅ ${ZSHRC}에 추가됨: ${LINE_TO_ADD}"
else
  echo "✅ 이미 ${ZSHRC}에 존재함"
fi

# zsh 환경에서 즉시 적용
if [ -n "${ZSH_VERSION-}" ]; then
  source "${ZSHRC}"
  echo "설정이 현재 세션에 적용되었습니다"
else
  echo "zsh를 시작하고 'source \"${ZSHRC}\"'를 실행하여 변경사항을 적용하세요"
fi