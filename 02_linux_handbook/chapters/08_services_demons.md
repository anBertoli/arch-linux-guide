# 📡 Services & demons

## SystemD

Si tratta del primo user space program, detto init (con PID = 1). SystemD lavora con `unit
files` che descivono come i servizi devono essere startati, gestiti e terminati.

Gli unit files sono presenti in `/etc/systemd/system/<unit_name>.service`. Il tool di gestione
di systemD è `systemctl`. I log dei servizi sono indirizzati automaticamente al syslog e
visualizzabili mediante `journalctl`.

L’utente di default dei servizi è root.

### Systemctl and journalctl

`systemctl` è il tool per gestire i servizi e gli unit files. Permette di avviare, stoppare,
installare unità, ricaricare configurazioni e molto altro.

```shell
# list units
$ systemctl list-units [--all]
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
# get info about a service
$ systemctl status <unit-name>


# reload systemd units
$ systemctl deamon-reload 
# vedi target corrente
$ systemctl get-default		
# setta nuovo target di default
$ systemctl set-default 		
```

Il comando `journalctl` è usato per leggere i log dei servizi e altre informazioni relative.

```shell
# printa i logs da tutti i servizi
$ journalctl		

# printa logs dei servizi dal current boot in poi
$ journalctl -b		

# printa logs di una specifica unit/servizio
$ journalctl -u <unit-name>	
```

## SSH

Il comando 🏷️`ssh`è usato per eseguire shell su macchine remote, protocollo comunicante su
porta 22:

```shell
$ ssh -i <path-to-key> <remote-user>@<hostname/ip>
```

La macchina remota deve avere un demone ssh in esecuzione. Il login può avvenire tramite
password (sconsigliato) oppure tramite chiavi, dove l’utente che si connette deve presentare
una chiave privata la cui chiave pubblica corrispondente è presente sul server remoto.

Tipicamente l’utente in locale crea una coppia di chiavi, privata e pubblica. La privata
deve rimanere segreta, la pubblica può essere inviata all’amministratore per essere
installata sul server. Una chiave può essere generata ad esempio con: `ssh-keygen -t rsa`.

Le chiavi generate localmente vengono salvate tipicamente in `~/.ssh/my_key.pub` e
`~/.ssh/my_key`, per quanto riguarda rispettivamente la chiave pubblica e privata. Le
chiavi pubbliche “autorizzate” sono installate sul server in `~/.ssh/authorized_keys` (la
home è quella dell’utente che deve loggarsi). Il formato del file è semplicemente una
lista di chiavi pubbliche, una per riga (il comando ssh-copy-id può installare chiavi
pubbliche da locale con più facilità).

Il comando 🏷️`scp` serve a copiare files da remoto verso locale e viceversa usando una
connessione SSH. E’ possibile copiare intere directory ricorsivamente con il flag -r,
mentre -p preserva i permessi dei file locali. La sintassi per uploadare dei file è:

```shell
$ scp -i <path/to/key> [-r] [-p] </local/files> <user>@<host/ip>:</remote/dir>
```

## Cron jobs

Cron ci permette di schedulare task ricorrenti usando un formato specifico per lo
scheduling. I task cron una volta confermati, vengono gestiti dal demone `crond`.

```shell
# schedulare un job come utente corrente (non usare root pls)
$ crontab -e	
# lista tutti i jobs schedulati
$ crontab -l 	
```

La sintassi è la seguente, con * per indicare che ogni valore di quel campo è valido per far
correre il job. E’ possibile anche usare una sintassi per indicare di eseguire il job non in
momenti precisi, ma a step periodici.

```shell
# minute:hour:day:month:weekday, runs at 08:10 
# on day-of-month 19 on Monday in February
10 8 19 2 1
# periodic (every 2 mins)
*/2 * * * * 
```