# Конфигурация виртуальной машины devops-vm

## 1. Параметры машины
*   **Память:** 2048 МБ
*   **Ядра:** 2
*   **Диск:** 25 ГБ

## 2. Сетевые интерфейсы
*   **Тип адаптера:** UTM Shared Network (аналог NAT)
*   **IP-адрес:** 192.168.64.3 (выдается DHCP, проверить командой `ip -brief address`)
*   **Назначение:** Доступ к интернету и подключение по SSH с хостовой системы (Mac).

## 3. Правило проброса портов
*   Проброс не используется (UTM Shared Network позволяет обращаться напрямую по IP).
*   Порт SSH на сервере: 2222.

## 4. Учётные записи
*   **student:** sudo-пользователь (создан при установке).
*   **devops:** sudo-пользователь, вход только по SSH-ключу (`~/.ssh/devops_vm` на Mac).

## 5. Служба SSH
*   **Порт:** 2222
*   **Конфигурационный файл:** `/etc/ssh/sshd_config.d/99-hardening.conf`
*   **Изменения:** `PermitRootLogin no`, `PasswordAuthentication no`, `MaxAuthTries 3`, `AllowUsers devops`.
*   *Важно:* В файле `/etc/ssh/sshd_config.d/50-cloud-init.conf` закомментирована строка `PasswordAuthentication yes`.

## 6. Правила межсетевого экрана (UFW)
*   Политика по умолчанию: deny incoming, allow outgoing.
*   Разрешены порты: 2222/tcp (LIMIT), 80/tcp (ALLOW), 443/tcp (ALLOW).

## 7. Снимки состояния
*   `01-clean-install`
*   `02-keys-configured`
*   `03-ssh-hardened`
*   `04-lab5-complete` (текущий)

## 8. Веб-сервер
*   **Устанавливаемый пакет:** nginx
*   **Путь к конфигурации ресурса:** /etc/nginx/sites-available/devops-site
*   **Каталог ресурса:** /var/www/devops-site (владелец devops:devops, права 755 для каталогов, 644 для файлов)
*   **Пути к сертификату и ключу:** /etc/ssl/certs/devops.crt (права 644) и /etc/ssl/private/devops.key (владелец root, права 600)
*   **Команда формирования сертификата:** `sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/devops.key -out /etc/ssl/certs/devops.crt -subj "/CN=devops.local" -addext "subjectAltName=DNS:devops.local"` (срок действия 365 дней)

## 9. Локальное доменное имя
*   В `/etc/hosts` на Mac добавлена запись: `192.168.64.3 devops.local`.
*   FQDN сервера: `devops-vm.devops.local` (задано через `hostnamectl`).

## 10. Контейнеризация
*   **Способ установки Docker Engine:** Официальный репозиторий Docker (версия 27.x).
*   **Участники группы docker:** devops.
*   **Расположение проекта на сервере:** ~/app
*   **Расположение файла .env и его права:** ~/app/.env (права 600).
*   **Публикуемые порты и адреса:** 127.0.0.1:5000 (только для Nginx).
*   **Именованные тома:** app_db_data (для PostgreSQL).
*   **Конфигурация обратного прокси:** location /app/ в /etc/nginx/sites-available/devops-site (proxy_pass на http://127.0.0.1:5000/).
