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

## 8. Локальное доменное имя
*   В `/etc/hosts` на Mac добавлена запись: `192.168.64.3 devops.local`.
*   FQDN сервера: `devops-vm.devops.local` (задано через `hostnamectl`).
