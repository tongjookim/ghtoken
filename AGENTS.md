# AGENTS.md

이 저장소를 수정하는 코딩 에이전트(Claude Code, Codex, opencode, aider 등)를 위한 안내입니다. 사람용 사용법은 `README.md`를 보세요.

## 프로젝트 개요

`ghtoken`은 GitHub 토큰을 `/etc/ghtoken/profiles/<프로필>.conf`에 저장하고 꺼내 쓰는 bash 스크립트 하나짜리 도구입니다. 가장 중요한 목표는 **토큰 원문이 노출되지 않는 것**입니다.

## 파일 구성

| 파일 | 역할 |
| --- | --- |
| `ghtoken` | 프로그램 전체 (bash). 명령은 하단 `case "$cmd"` 블록에 있음 |
| `install.sh` | `/etc/ghtoken`에 설치하고 `/usr/local/sbin/ghtoken` 링크 생성 |
| `README.md` | 사용자 문서 |
| `.gitignore` | 프로필, `.conf`, `.env` 제외 |

`ghtoken` 내부의 주요 함수:

- `load` — 프로필 파일을 파싱해 `GITHUB_USER`, `GITHUB_TOKEN`을 채움
- `save` — 임시 파일에 쓴 뒤 `mv`로 원자적 교체, 권한 600
- `mask` — 토큰을 `앞4자****뒤4자`로 표시

## 반드시 지킬 규칙

1. **토큰을 출력하지 않는다.** 원문을 표준출력으로 내는 명령은 `env`, `header`, `credential` 세 개뿐입니다. 새 명령이나 오류 메시지, 디버그 출력에 토큰이 들어가면 안 됩니다. 사람에게 보여줄 때는 `mask`를 씁니다.
2. **토큰을 명령줄 인자로 넘기지 않는다.** `ps`로 보입니다. `curl`은 `-K -`로 헤더를 표준입력에서 읽게 하고, `git`은 credential helper로 넘깁니다. `curl -H "Authorization: ..."`, `git -c http.extraHeader=...`, URL에 토큰 넣기(`https://user:token@github.com`)는 금지입니다.
3. **프로필 파일을 `source`하지 않는다.** `load`/`import`처럼 허용된 키만 `while IFS='=' read` 로 파싱합니다.
4. **권한을 유지한다.** 스크립트 상단의 `umask 077`, 디렉터리 700, 파일 600을 낮추지 않습니다.
5. **실제 토큰이나 실제 프로필을 커밋하지 않는다.** 예시는 `ghp_xxxx…`처럼 가짜 값만 씁니다. 테스트용 토큰도 저장소에 넣지 않습니다.
6. **credential helper는 github.com에만 답한다.** 다른 호스트 요청에는 아무것도 출력하지 않고 종료해야 합니다. `store`/`erase`는 무시합니다.
7. 저장소 URL은 프로필에 저장하지 않습니다. `push` 시점에 인자나 프롬프트로 받는 것이 의도된 설계입니다.

## 코드 스타일

- bash, `set -euo pipefail` 유지. POSIX sh로 바꾸지 않습니다.
- 사용자에게 보이는 메시지는 한국어, 오류는 `die "메시지"`로 표준에러에 출력합니다.
- 외부 의존성은 `git`, `curl`, `base64`만 씁니다. `jq`, `python` 등은 추가하지 않습니다.
- 명령을 추가하면 `usage()`의 도움말과 `README.md`의 명령어 표를 같이 고칩니다.

## 확인 방법

변경 후 최소한 다음을 실행합니다. 실제 토큰이 필요한 `verify`/`push`는 사람이 확인합니다.

```bash
bash -n ghtoken                     # 문법 검사
shellcheck ghtoken install.sh       # 설치돼 있으면

# 임시 프로필로 동작 확인 (가짜 토큰)
echo ghp_FAKEFAKEFAKEFAKEFAKE | sudo ./ghtoken -p agenttest set tester
sudo ./ghtoken -p agenttest show                       # 토큰이 마스킹되는지
printf 'protocol=https\nhost=github.com\n\n' | sudo ./ghtoken -p agenttest credential get | sed 's/password=.*/password=***/'
printf 'protocol=https\nhost=gitlab.com\n\n' | sudo ./ghtoken -p agenttest credential get   # 출력이 없어야 함
sudo ./ghtoken -p agenttest rm
```

`push` 로직을 바꿨다면 임시 git 저장소에서 `--dry-run`으로 확인합니다. 실제 푸시는 하지 않습니다.

```bash
ghtoken push owner/repo --dry-run HEAD:refs/heads/dryrun-test
```

## 하지 말 것

- `/etc/ghtoken/profiles` 안의 실제 프로필을 읽거나 출력하거나 수정하기
- `ghtoken env` / `header` 결과를 로그, 커밋 메시지, PR 본문에 남기기
- 사용자 확인 없이 실제 원격 저장소에 푸시하기
