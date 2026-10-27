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
# TODO 1
check "Порт SSH не 22" "2222" "$(sudo sshd -T | awk 'tolower($1)=="port"{print $2}')"
# TODO 2
check "MaxAuthTries равно 3" "3" "$(sudo sshd -T | awk 'tolower($1)=="maxauthtries"{print $2}')"
echo "[2] Межсетевой экран"
check "Межсетевой экран активен" "active" "$(sudo ufw status | awk '/^Status:/{print $2}')"
# TODO 3: проверьте, что политика по умолчанию для входящего трафика равна deny
check "Политика входящих: deny" "deny" "$(sudo ufw status verbose | grep 'Default:' | awk '{print $2}')"

echo "[3] Учётные записи"
awk -F: ' $3>=1000 && $3<65534 {printf " %s (uid=%s)\n",$1,$3}' /etc/passwd

echo "[4] Веб-сервер"
check "Конфигурация nginx синтаксически корректна" "0" "$(sudo nginx -t >/dev/null 2>&1; echo $?)"
check "Сертификат действителен более 30 дней" "0" "$(sudo openssl x509 -checkend 2592000 -noout -in /etc/ssl/certs/devops.crt >/dev/null 2>&1; echo $?)"
check "Нет файлов, доступных для записи всем" "" "$(sudo find /var/www/devops-site -perm -o+w)"
check "Права ключа TLS равны 600" "600" "$(sudo stat -c '%a' /etc/ssl/private/devops.key)"
echo "Пройдено: $PASS, не пройдено: $FAIL"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
