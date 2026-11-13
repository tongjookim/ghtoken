#!/usr/bin/env bash
# ghtoken 설치: /etc/ghtoken 에 프로그램을 두고 /usr/local/sbin/ghtoken 링크를 만든다.
# 기존 프로필(/etc/ghtoken/profiles)은 건드리지 않는다.
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "root 권한으로 실행하세요" >&2; exit 1; }
src="$(cd "$(dirname "$0")" && pwd)/ghtoken"
umask 077
install -d -m 700 /etc/ghtoken /etc/ghtoken/profiles
install -m 700 "$src" /etc/ghtoken/ghtoken
ln -sf /etc/ghtoken/ghtoken /usr/local/sbin/ghtoken
echo "설치 완료: /etc/ghtoken/ghtoken (명령: ghtoken)"
echo "다음 단계: ghtoken set && ghtoken verify"
