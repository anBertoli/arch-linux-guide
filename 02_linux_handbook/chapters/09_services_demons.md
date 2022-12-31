# 📡 Services & demons

## SystemD

Si tratta del primo user space program, detto init (con PID = 1). SystemD lavora con `unit
files` che descivono come i servizi devono essere startati, gestiti e terminati.

Gli unit files sono presenti in 📄`/etc/systemd/system/<unit_name>.service`. Il tool di gestione
di systemD è `systemctl`. I log dei servizi sono indirizzati automaticamente al syslog e
visualizzabili mediante `journalctl`.

L’utente di default dei servizi è root.

### Systemctl

Il tool 🛠️`systemctl` è usato per gestire i servizi e gli unit files. Permette di avviare,
stoppare, installare unità, ricaricare configurazioni e molto altro.

```shell
# list units
$ systemctl list-units [--all]
# get info about a service
$ systemctl status <unit-name>
# cat unit file for the service
$ systemctl cat <unit-name>

# edit the unit file 
$ systemctl edit --full <unit-name>
# start the unit which file is /etc/systemd/system/<unit-name>.service 
$ systemctl start <unit-name>
# stop the service
$ systemctl stop <unit-name>
# restart the service, if the unit supports it
$ systemctl restart <unit-name>
# reload config for the service, if the unit supports it
$ systemctl reload <unit-name>
# install the service, if the unit supports it
# the service will start at boot
$ systemctl enable <unit-name>
# uninstall the service
$ systemctl disable <unit-name>

# reload systemd units
$ systemctl deamon-reload 
# vedi target corrente
$ systemctl get-default		
# setta nuovo target di default
$ systemctl set-default 		
```

### System logs

Kernel e processi generano logs. I logs di default vengono mandati verso _logging deamons_.
`rsyslog` è il più comune, esso stora logs in formato testuale e leggibile in _/var/log_. I
logs contengono timestamp, messaggio di log, processo che lo ha generato, etc.

Il comando 🛠️`journalctl` è usato per leggere i log dei servizi e altre informazioni relative.

```shell
# printa i logs da tutti i servizi
$ journalctl		
# printa logs dei servizi dal current boot in poi
$ journalctl -b		

# printa logs di una specifica unit/servizio, e vai alla fine
$ journalctl -u/--unit <unit-name> -e
# printa logs di una specifica unit/servizio, e stai in follow mode
$ journalctl -u/--unit <unit-name> --follow

# show priorities
$ journalctl -p
# show logs with given priority
$ journalctl -p [alert, crit, err, …]

# mostra i logs since/until la data/timestamp
$ journalctl -S 02:00 
$ journalctl -U 3:00
```

## SSH

### SSH demon

Il demone SSH più usato é _openSSH_, dopo installazione viene gestito tramite unit systemD.
Il suo file di configurazione è `/etc/ssh/sshd_config`, dove possiamo controllare diversi
parameteri fra cui:

- _Port_ (22): porta su cui il demone ascolta
- _PasswordAuthentication_: secifica se auth con password é permessa
- _ListenAddress_: specifica ip su cui ascoltare
- _PermitRootLogin_: permette o meno login come root user
- _X11Forwarding_: lancia server grafico quando ci si connette via ssh

Ad ogni cambiamento del file di conf é necessario reloadare il demone:

```shell
$ sudo systemctl reload sshd.service
```

Le chiavi pubbliche “autorizzate” devono essere installate sul server in
`<remote-user-home>/.ssh/authorized_keys` (la home è quella dell’utente con cui vogliamo
loggarci). Il formato del file è semplicemente una lista di chiavi pubbliche, una per riga.
Le chiavi pubbliche qui presenti permettono all’utente corrispondente di potersi
loggare presnetando la relativa chiave privata.

### SSH client

Il comando 🛠️`ssh` è il client SSH usato per eseguire shell su macchine remote, protocollo
comunicante su porta 22 tipicamente.

```shell
$ ssh -i <path/to/private/key> <remote-user>@<remote-ip/name>
```

I file di configurazione sono `/etc/ssh/ssh_config`, file di configurazione generale, e
`/etc/ssh/ssh_config.d`, file di configurazione dei profili singoli che sono, importati sul
default.

La macchina remota deve avere un demone ssh in esecuzione. Il login può avvenire tramite
password (sconsigliato) oppure tramite chiavi, dove l’utente che si connette deve presentare
una chiave privata la cui chiave pubblica corrispondente è presente sul server remoto.

Tipicamente l’utente in locale crea una coppia di chiavi, privata e pubblica. La privata
deve rimanere segreta, la pubblica può essere data all’amministratore per essere
installata sul server. Una chiave può essere generata localmente con:

```shell
$ ssh-keygen -t rsa
```

Le chiavi generate vengono salvate di default in `~/.ssh/my_key.pub` e`~/.ssh/my_key`, per
quanto riguarda rispettivamente la chiave pubblica e privata.

La chiave pubblica viene validata tramite chiave privata durante la fase di auth.
Si puó fare manualmente o via lo shortcut 🛠`ssh-copy-id`, da eseguire sul client per copiare
la chiave indicata sul server remoto nella cartella dell’utente specificato. In alternativa
il comando 🛠️`scp` serve a copiare files da remoto verso locale e viceversa usando una
connessione SSH. E’ possibile copiare intere directory ricorsivamente con il flag _-r_,
mentre _-p_ preserva i permessi dei file locali.

```shell
# copy keys with ssh-copy-id 
$ ssh-copy-id <user>@<remote-machine>
# copy files with scp
$ scp -i <path/to/key> [-r] [-p] </local/files> <user>@<host/ip>:</remote/dir>
```

Sempre in locale/sul client esiste il file `/<home>/.ssh/known-hosts`, questo file contiene
tutti i server a cui ci siamo collegati precedentemente (motivi di security). Quando ci
colleghiamo a server non noto, tale server viene riconosciuto e viene chiesto all'utente
conferma.

## Cron jobs

Il sistema _cron_ ci permette di schedulare task ricorrenti usando un formato specifico per lo
scheduling. I task cron una volta create mediante comando 🛠`crontab` e vengono gestiti dal
demone `crond`.

Il file `/etc/crontab` è la cron tab globale, da non modificare direttamente, contiene anche
esempi di sintassi, direttive per impostare la shell, env vars, mandare mail dopo che i
jobs sono completati, etc.

```shell
# edit the crontab for the current user
$ crontab -e	
# lista all scheduled cron jobs
$ crontab -l 	
# remove all cron of the current user
$ crontab -e
```

La sintassi dei _cronjob_ è la seguente, con * per indicare che ogni valore di quel campo è
valido per far correre il job. E’ possibile anche usare una sintassi specifica per indicare
di far eseguire il job non in momenti precisi, ma a step periodici.

Sintassi: `minute:hour:day:month:weekday`

- `*` match all
- `,` match listed values
- `-` range of values
- `/` specify steps

Esempi:

```shell
# minute:hour:day:month:weekday, runs at 08:10 
# on day-of-month 19 on Monday in February
10 8 19 2 1
# periodic (every 2 mins)
*/2 * * * * 
```


