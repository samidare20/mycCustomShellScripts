 bindkey -e

 # Home 키
 bindkey '\e[H' beginning-of-line
 bindkey '\e[1~' beginning-of-line

 # End 키
 bindkey '\e[F' end-of-line
 bindkey '\e[4~' end-of-line

 # Delete 키 (커서 위치의 글자 삭제)
 bindkey '\e[3~' delete-char

 # Page Up / Page Down (히스토리 검색)
 bindkey '\e[5~' up-line-or-history
 bindkey '\e[6~' down-line-or-history

 # Ctrl + 좌우 화살표로 단어 단위 이동
 bindkey '\e[1;5C' forward-word
 bindkey '\e[1;5D' backward-word