#!/usr/bin/env bash
set -uo pipefail

PASS=0; FAIL=0
check() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$actual" == "$expected" ]]; then
    echo " [OK]  $desc"
    ((PASS++))
  else
    echo " [FAIL] $desc (ожидалось: '$expected', получено: '$actual')"
    ((FAIL++))
  fi
}

echo "Аудит конфигурации: $(hostname -f), $(date '+%Y-%m-%d %H:%M')"

echo "[1] Служба SSH"
check "Вход от имени root запрещён" "no" "$(sudo sshd -T | awk 'tolower($1)=="permitrootlogin"{print $2}')"
check "Парольная аутентификация отключена" "no" "$(sudo sshd -T | awk 'tolower($1)=="passwordauthentication"{print $2}')"
check "Порт SSH не 22" "2222" "$(sudo sshd -T | awk 'tolower($1)=="port"{print $2}')"
check "MaxAuthTries равно 3" "3" "$(sudo sshd -T | awk 'tolower($1)=="maxauthtries"{print $2}')"

echo "[2] Межсетевой экран"
check "Межсетевой экран активен" "active" "$(sudo ufw status | awk '/^Status:/{print $2}')"
check "Политика входящих: deny" "deny" "$(sudo ufw status verbose | grep 'Default:' | awk '{print $2}')"

echo "[3] Учётные записи"
awk -F: ' $3>=1000 && $3<65534 {printf " %s (uid=%s)\n",$1,$3}' /etc/passwd

echo "[4] Веб-сервер"
check "Конфигурация nginx синтаксически корректна" "0" "$(sudo nginx -t >/dev/null 2>&1; echo $?)"
check "Сертификат действителен более 30 дней" "0" "$(sudo openssl x509 -checkend 2592000 -noout -in /etc/ssl/certs/devops.crt >/dev/null 2>&1; echo $?)"
check "Нет файлов, доступных для записи всем" "" "$(sudo find /var/www/devops-site -perm -o+w)"
check "Права ключа TLS равны 600" "600" "$(sudo stat -c '%a' /etc/ssl/private/devops.key)"

echo "[5] Контейнеризация"
check "Служба Docker активна" "active" "$(systemctl is-active docker)"
check "СУБД в состоянии healthy" "healthy" "$(sudo docker inspect -f '{{.State.Health.Status}}' app-db-1 2>/dev/null || echo 'error')"
check "Порты 5000 и 5432 не прослушиваются на 0.0.0.0" "" "$(sudo ss -tln | awk '{print $4}' | grep -E ':5000|:5432' | grep -v '127.0.0.1' || true)"
check "Права файла .env равны 600" "600" "$(sudo stat -c '%a' /home/devops/app/.env 2>/dev/null || echo 'none')"

echo "Пройдено: $PASS, не пройдено: $FAIL"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
