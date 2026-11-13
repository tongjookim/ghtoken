# ghtoken

GitHub 토큰을 프로젝트별 `.env` 파일에 흩어 두지 않고, 서버의 한 곳(`/etc/ghtoken`)에 모아서 관리하는 root 전용 명령줄 도구입니다.

- 토큰은 root만 읽을 수 있는 파일(600)에 저장합니다.
- 토큰은 화면, 셸 히스토리, 프로세스 인자(`ps`)에 남지 않습니다.
- 푸시할 때 저장소를 입력받고, 토큰은 git credential helper로만 넘깁니다.
- 계정이 여럿이면 프로필(`-p`)로 나눠 관리합니다.

## 요구 사항

- Linux, bash 4 이상
- `git`, `curl`, `base64` (coreutils)
- root 권한

## 설치

```bash
git clone https://github.com/tongjookim/ghtoken.git
cd ghtoken
sudo ./install.sh
```

설치하면 아래 파일이 생깁니다. 이미 있는 프로필은 그대로 둡니다.

| 경로 | 권한 | 설명 |
| --- | --- | --- |
| `/etc/ghtoken/ghtoken` | 700 | 프로그램 본체 |
| `/usr/local/sbin/ghtoken` | 링크 | `ghtoken` 명령 |
| `/etc/ghtoken/profiles/` | 700 | 프로필 디렉터리 |
| `/etc/ghtoken/profiles/<이름>.conf` | 600 | 프로필 하나당 파일 하나 |

## 빠른 시작

```bash
ghtoken set        # 사용자명과 토큰 입력 (토큰은 화면에 안 보임)
ghtoken verify     # HTTP 200, 로그인 이름, scope, 만료일 확인
cd ~/my-project
ghtoken push       # 푸시할 저장소를 물어봄
```

## 명령어

형식: `ghtoken [-p 프로필] <명령>`. `-p`를 생략하면 `default` 프로필을 씁니다.

| 명령 | 설명 | 토큰 원문 출력 |
| --- | --- | --- |
| `set` | 사용자명과 토큰을 입력받아 저장. 파이프 입력도 됨: `echo "$T" \| ghtoken set <user>` | 아니오 |
| `import <파일>` | `.env` 파일에서 `GITHUB_USER`, `GITHUB_TOKEN`을 읽어 저장 | 아니오 |
| `show` | 프로필 정보 표시. 토큰은 앞뒤 4자만 (`ghp_****abcd`) | 아니오 |
| `list` | 프로필 목록 | 아니오 |
| `verify` | GitHub API(`GET /user`)로 유효성, scope, 만료일 확인. 200이 아니면 종료 코드 1 | 아니오 |
| `push [저장소] [git push 인자…]` | 현재 git 디렉터리를 푸시. 저장소를 생략하면 입력받음. 브랜치를 안 주면 현재 `HEAD` | 아니오 |
| `env` | `export GITHUB_USER / GITHUB_TOKEN / GH_TOKEN` 출력 | **예** |
| `header` | `Authorization: Basic …` 헤더 출력 | **예** (base64) |
| `credential get` | git credential helper 응답. `host=github.com`에만 답함 | **예** |
| `rm` | 프로필 삭제 | 아니오 |

### push 저장소 표기

다음 표기를 모두 받습니다.

```bash
ghtoken push owner/repo
ghtoken push https://github.com/owner/repo.git
ghtoken push git@github.com:owner/repo.git     # HTTPS로 바꿔서 푸시
ghtoken push repo                               # 프로필 사용자 계정의 repo
ghtoken push owner/repo main --force-with-lease # 뒤에 오는 인자는 git push에 그대로 전달
ghtoken -p work push org/repo                   # 다른 프로필의 토큰 사용
```

## git과 연동하기

`ghtoken push` 말고 일반 `git push`에서도 토큰을 쓰려면 credential helper로 등록합니다. github.com 요청에만 적용됩니다.

```bash
git config --global credential.https://github.com.helper '!/usr/local/sbin/ghtoken credential'
```

스크립트에서 환경변수로 쓰려면 이렇게 합니다.

```bash
eval "$(ghtoken env)"
```

## 프로필 파일 형식

```
# ghtoken profile: default  (updated 2026-11-13 15:40:18)
GITHUB_USER=octocat
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
```

이 파일은 `source`하지 않고 `KEY=VALUE` 두 줄만 읽습니다. 다른 내용이 들어 있어도 실행되지 않습니다.

## 보안 참고

- `env`, `header`, `credential`의 출력은 로그나 채팅에 붙여넣지 마세요. 토큰 원문이 들어 있습니다.
- `/etc`를 백업하거나 버전 관리(etckeeper 등)한다면 `/etc/ghtoken/profiles`는 빼 두세요.
- 토큰은 필요한 저장소와 권한만 주고 만료일을 정해서 발급하세요. 만료가 다가오면 `ghtoken set`으로 바꾸면 됩니다.
- 이 저장소의 `.gitignore`가 `profiles/`, `*.conf`, `.env`를 제외합니다. 실제 토큰은 커밋하지 마세요.

## 제거

```bash
sudo rm -f /usr/local/sbin/ghtoken /etc/ghtoken/ghtoken
sudo rm -rf /etc/ghtoken/profiles   # 저장된 토큰까지 지울 때만
```

## 라이선스

MIT. [LICENSE](LICENSE) 파일을 보세요.
