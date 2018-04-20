# Описание

Скрипт мониторит все адаптеры, но они должны иметь номера по порядку, наптимер 0, 1, 2. Если это не так, например 0, 2 - то работать не будет.

Скрипт имеет встроенную справку:
```bash
 ./lsimegaraid_discovery_trapper.sh help
WARNING: Correctly setup 'Hostname=' in config is REQUIRED!

INFO: Get info about all arrays;
 Examples:
    Discovery is default action:
        ./$(basename $0)                            - physdiscovery disks for all arrays.
        ./$(basename $0) discovery                  - physdiscovery disks for all arrays.
        ./$(basename $0) discovery virtdiscovery    - virtdiscovery disks for all arrays.
    Data sending to zabbix-server:
        ./$(basename $0) trapper    - send data to zabbix for all arrays.

03.2015 - metajiji@gmail.com
04.2018 - vsyscoder@gmail.com
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
# MegaCli нужно запускать через sudo
MEGACLI='/usr/bin/sudo /usr/local/sbin/MegaCli'
ZABBIX_SENDER='/usr/local/bin/zabbix_sender'
CONFIG='/etc/zabbix/zabbix_agentd.conf'
```

### В конфигурационном файле zabbix-агента должно быть явно задано имя узла сети
```bash
Hostname=<Имя узла сети>
```

### Не забываем перезапустить агент, чтобы агент прочитал новый конфигурационный файл:
```bash
service zabbix-agentd restart
```

### Проверка:
```bash
zabbix_get -s HOST -k "lsimegaraid.data[Adp0,DriveSlot0, inquiry]"
```
не работает, так как данные отправляются через zabbix_sender и отсутствует соответствующий UserParam.
Проверить можно discovery (должен вернуть json со списком адаптеров и дисков или виртуальных томов):
```bash
zabbix_get -s HOST -k "lsimegaraid.discovery[phisdiscovery]"
zabbix_get -s HOST -k "lsimegaraid.discovery[virtdiscovery]"
```
 и trapper (вернёт 1 в случае, если данные на сервер отправлены, или 0 в случае ошибок):
 ```bash
 zabbix_get -s HOST -k "lsimegaraid.trapper"
 ```
 ВАЖНО: после назначения шаблона узлу сети, может пройти достаточно длительное время (десятки минут) прежде чем trapper начнёт успешно отправлять данные.

# Файлы для загрузки
* [Конфигурационный файл /etc/zabbix/zabbix_agentd.conf.d/lsimegaraid.conf](etc/zabbix/zabbix_agentd.conf.d/lsimegaraid.conf)
* [Код скрипта /etc/zabbix/scripts/lsimegaraid_discovery_trapper.sh](etc/zabbix/scripts/lsimegaraid_discovery_trapper.sh)
* [Шаблон для zabbix](Template_LSIMegaRaid_trapper.xml)

# Ссылки
1. [Мониторинг LSI MegaRAID в Zabbix](http://wiki.enchtex.info/howto/zabbix/zabbix_megaraid_monitoring)
2. [Мониторинг состояния HDD в RAID контроллере LSI MegaRAID под Linux, средствами Nagios.](https://ru.intel.com/business/community/?automodule=blog&amp;blogid=44433&amp;showentry=2452)
3. [Intel Raid Controller RS2BL040 Slow Performance – BBU problems.](https://odesk.by/archives/1922)
4. [Perc RAID Controllers](https://twiki.cern.ch/twiki/bin/view/FIOgroup/DiskRefPerc)
5. [Adding a Hard Drive back into RAID on a Web Gateway 5000 or 5500 Intel based Appliance](https://community.mcafee.com/docs/DOC-5318)
