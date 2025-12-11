# Мониторинг процессов в Linux (systemd + bash)

Простое и надёжное решение для мониторинга произвольных процессов в Linux с отправкой HTTPS-уведомлений и логированием перезапуска.

## Возможности

- Запуск при старте системы
- Проверка каждую минуту (`OnCalendar=minutely`)
- Отправка HTTPS-запроса на `https://test.com/monitoring/test/api`, если процесс запущен
- Логирование перезапуска процесса в `/var/log/monitoring.log`
- Логирование недоступности сервера мониторинга
- Поддержка нескольких процессов через шаблоны systemd (`@`)

## Структура проекта

```
test_devops/
├── Тест.txt                    → исходное ТЗ
├── monitor_process.sh          → основной скрипт мониторинга
├── monitor_process@.service    → systemd service (oneshot)
├── monitor_process@.timer      → systemd timer (каждую минуту)
├── test, test2                 → тестовые процессы
├── start_monitoring.sh         → удобный запуск мониторинга
├── stop_monitoring.sh          → удобная остановка
└── README.md
```

## Установка

```bash
# Как root или через sudo

# Копируем скрипт
cp monitor_process.sh /usr/local/bin/
chmod +x /usr/local/bin/monitor_process.sh

# Копируем юниты systemd
cp monitor_process@.service monitor_process@.timer /etc/systemd/system/

# Перезагружаем конфигурацию systemd
systemctl daemon-reload

# Делаем исполняемыми скрипты для тестирования
chmod +x start_monitoring.sh stop_monitoring.sh
```

## Использование

### Вариант 1: Через удобные скрипты (рекомендуется для тестов)

```bash
# Как root или через sudo

# Запуск мониторинга процесса test
./start_monitoring.sh test

# Запуск мониторинга процесса test2
./start_monitoring.sh test2

# Остановка
./stop_monitoring.sh test
./stop_monitoring.sh test2
```

### Вариант 2: Напрямую через systemctl

```bash
# Как root или через sudo

# Запуск мониторинга
systemctl enable --now monitor_process@test.timer
systemctl enable --now monitor_process@test2.timer

# Остановить
systemctl disable --now monitor_process@test.timer
systemctl disable --now monitor_process@test2.timer
```

## Проверка статуса

```bash
systemctl list-timers | grep monitor_process
journalctl -u monitor_process@test.timer -f
tail -f /var/log/monitoring.log
```

## Удаление (полная очистка)

```bash
# Как root или через sudo

# Остановить все таймеры
systemctl disable --now monitor_process@*.timer 2>/dev/null || true

# Удалить юниты
rm -f /etc/systemd/system/monitor_process@.*

# Перезагрузить systemd
systemctl daemon-reload

# Удалить скрипт мониторинга
rm -f /usr/local/bin/monitor_process.sh

# удалить логи и PID-файлы
rm -f /var/log/monitoring.log
rm -f /var/run/monitor_*.pid
```

## Тестирование

```bash
# Запустите мониторинг
sudo ./start_monitoring.sh test

# Запустите тестовый процесс
./test

# Нажмите ENTER, чтобы завершить процесс и запустите снова:
# в /var/log/monitoring.log появится запись о перезапуске
./test
```

## Как это понимать

Извините, не удержался.
Хотел показать, что у меня именно DevOps направления слабые:

- Ansible
- Jenkins
- CI/CD
- Kubernetes

С навыками системного администратора всё более менее.  
Линуксы знаю, с докерами дружу.

