#!/usr/bin/env bash
# Доставка статического ресурса на devops-vm
# Использование: scripts/deploy.sh [--dry-run]
set -euo pipefail

REMOTE="devops"
REMOTE_DIR="/var/www/devops-site"
SITE_URL="https://devops.local"
CA_CERT="${HOME}/devops.crt"
LOCAL_DIR="$(git rev-parse --show-toplevel)/site/"

# 1. Разбор аргумента --dry-run
DRY_RUN=""
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN="--dry-run"
fi

# 4. Проверка наличия файла site/index.html
if [[ ! -f "${LOCAL_DIR}index.html" ]]; then
    echo "Ошибка: файл site/index.html не найден!" >&2
    exit 1
fi

# 5. Проверка на незафиксированные изменения (включая добавленные в индекс)
if [[ -n $(git status --porcelain) ]]; then
    echo "Ошибка: в репозитории есть незафиксированные изменения!" >&2
    exit 1
fi

# Определяем путь к новому rsync (для Mac)
RSYNC_CMD="rsync"
if [ -x "/opt/homebrew/bin/rsync" ]; then
    RSYNC_CMD="/opt/homebrew/bin/rsync"
fi

# 3. Синхронизация каталога
echo "Синхронизация ${LOCAL_DIR} на ${REMOTE}:${REMOTE_DIR}..."
$RSYNC_CMD -avz --delete --chmod=D755,F644 $DRY_RUN -e "ssh -o BatchMode=yes -o ConnectTimeout=5" "${LOCAL_DIR}" "${REMOTE}:${REMOTE_DIR}"

# 4. При --dry-run завершение с кодом 0 без проверки доступности
if [[ -n "$DRY_RUN" ]]; then
    echo "Пробный запуск успешно завершен (код 0)."
    exit 0
fi

# 6. Проверка доступности ресурса
echo "Проверка доступности ${SITE_URL}..."
if ! curl -fsS --cacert "${CA_CERT}" "${SITE_URL}" > /dev/null; then
    echo "Ошибка: ресурс ${SITE_URL} недоступен!" >&2
    exit 1
fi

# 7. Успешное завершение
COMMIT_HASH=$(git rev-parse --short HEAD)
echo "Деплой успешно завершен. Доставлен коммит: ${COMMIT_HASH}"
exit 0
