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

## 11. Ansible — практическая работа № 11

Текущее состояние после восстановления 01-clean-install.
Предыдущие разделы описывают прошлые практические работы.

### Окружение и доступ

- Control: macOS ARM64, Ansible Core 2.22.0.
- VM: UTM, Ubuntu 26.10 ARM64, IP 192.168.64.3, SSH на порту 22.
- Проект: ansible/ в репозитории devops-course-2026-turanov.
- Bootstrap: inventory/bootstrap.ini, student по ключу ~/.ssh/devops_vm;
  пароль sudo запрашивается через --ask-become-pass.
- Prod: inventory/prod.ini, devops по тому же ключу, sudo без пароля.
- Закрытый ключ остаётся на Mac и не включается в репозиторий.
- Парольный SSH-вход и вход root отключены после установки открытого ключа.
- NOPASSWD:ALL используется как учебное упрощение и даёт полный доступ sudo.

### Роли и приложение

- base: проверка ОС, зависимости, официальный репозиторий Docker, Docker Engine.
- ssh: пользователь devops, ключ, sudo, hardening SSH и UFW.
- nginx: reverse proxy; nginx -t перед reload.
- app: загрузка образа, запуск контейнера и проверка /health.
- Образ: ghcr.io/im2high/devops-ci-app-turanov.
- SHA: 1e23496d385f58beff5b96e2d69b29400689842a.
- ARM64-образ проверен и опубликован CI после PR № 3 репозитория приложения.
- Контейнер: devops-ci-app.
- Публикация: 127.0.0.1:5000 → 5000 контейнера.
- Внешняя проверка: http://192.168.64.3/health.
- UFW: разрешены 22/tcp и 80/tcp, входящие соединения по умолчанию запрещены.
- HTTPS в этой работе не настраивается.
- force_handlers = True обеспечивает выполнение уведомлённых handlers
  при отказе последующих задач.
- Коллекции: ansible.posix 2.2.2, community.docker 5.4.0,
  community.general 14.0.1; версии записаны в requirements.yml.

### Запуск с Mac из каталога ansible/

Первый запуск:
`ansible-playbook -i inventory/bootstrap.ini site.yml --ask-become-pass`

Повторный запуск:
`ansible-playbook site.yml`

Аудит без изменения конфигурации:
`ansible-playbook verify.yml`

### Результаты проверки

- Первый деплой: ok=27, changed=18, failed=0.
- Повторный запуск: ok=24, changed=0, failed=0.
- Drift: удаление контейнера и неверный порт Nginx вызвали 502;
  site.yml восстановил состояние с changed=3, failed=0, HTTP снова 200.
- Несуществующий тег из 40 нулей вызвал 404 на этапе pull;
  работающий контейнер сохранился и продолжал отвечать 200.
- После возврата правильного SHA: changed=0, failed=0.
- verify.yml проверяет SSH, состояние и SHA контейнера,
  прямой health endpoint и ответ через Nginx.
- Два аудита: ok=10, changed=0, failed=0.
- Остановленный контейнер обнаружен аудитом; site.yml восстановил работу,
  после чего аудит прошёл и HTTP вернулся к 200.
- Сравнение вывода sshd -T нормализует регистр названий параметров.
