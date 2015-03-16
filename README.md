# Описание

Скрипт мониторит по-умолчанию адаптер 0, т.е. когда в системе только одна плата **Raid** контроллера (опция **-a0**), но можно указать конкретный номер адаптера, если это необходимо.

Скрипт имеет встроенную справку:
```bash
# ./lsimegaraid_discovery_trapper.sh help
WARNING: Correctly setup 'Hostname=' in config is REQUIRED!

INFO: Number of array is default 0;
 Examples:
    Discovery is default action:
        ./lsimegaraid_discovery_trapper.sh                            - physdiscovery disks for default array 0.
        ./lsimegaraid_discovery_trapper.sh discovery                  - physdiscovery disks for default array 0.
        ./lsimegaraid_discovery_trapper.sh discovery virtdiscovery    - virtdiscovery disks for custom array 0.
        ./lsimegaraid_discovery_trapper.sh discovery virtdiscovery 1  - virtdiscovery disks for custom array 1.
        ./lsimegaraid_discovery_trapper.sh discovery physdiscovery 1  - physdiscovery disks for custom array 1.
    Data sending to zabbix-server:
        ./lsimegaraid_discovery_trapper.sh trapper    - send data to zabbix for default array 0.
        ./lsimegaraid_discovery_trapper.sh trapper 1  - send data to zabbix for custom array 1.

03.2015 - metajiji@gmail.com
```

Скрипт поддерживает обнаружение (**discovery**) виртуальных и физических дисков в слотах. Отправка данных осуществляется через `zabbix_sender`.

# Установка:
```bash
mkdir /etc/zabbix/scripts
chown root:zabbix -R /etc/zabbix/scripts
chmod 750 /etc/zabbix/scripts
```

### Установка прав на скрипт:
```bash
chown root:zabbix /etc/zabbix/scripts/lsimegaraid_discovery_trapper.sh
chmod 750 /etc/zabbix/scripts/lsimegaraid_discovery_trapper.sh
```

### Не забываем про настройки в скрипте, где нужно указать полные пути до необходимых программ и конфигурационных файлов:
```bash
MEGACLI='/usr/local/sbin/MegaCli'
ZABBIX_SENDER='/usr/local/bin/zabbix_sender'
CONFIG='/etc/zabbix/zabbix_agentd.conf'
```

### Не забываем перезапустить агент, чтобы агент прочитал новый конфигурационный файл:
```bash
service zabbix-agentd restart
```

### Проверка:
```bash
zabbix_get -s HOST -k "lsimegaraid[DriveSlot0, inquiry]"
```

# Файлы для загрузки
* [Конфигурационный файл **/etc/zabbix/zabbix_agentd.conf.d/lsimegaraid.conf**](etc/zabbix/zabbix_agentd.conf.d/lsimegaraid.conf)
* [Код скрипта **/etc/zabbix/scripts/lsimegaraid_discovery_trapper.sh**](etc/zabbix/scripts/lsimegaraid_discovery_trapper.sh)
* [Шаблон для **zabbix**](Template_LSIMegaRaid_trapper.xml)

# Ссылки
1. [Мониторинг LSI MegaRAID в Zabbix](http://wiki.enchtex.info/howto/zabbix/zabbix_megaraid_monitoring)
2. [Мониторинг состояния HDD в RAID контроллере LSI MegaRAID под Linux, средствами Nagios.](https://ru.intel.com/business/community/?automodule=blog&amp;blogid=44433&amp;showentry=2452)
3. [Intel Raid Controller RS2BL040 Slow Performance – BBU problems.](https://odesk.by/archives/1922)
