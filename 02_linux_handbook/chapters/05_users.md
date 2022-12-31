# 👨‍💻 Users

Una macchina Linux prevede uno o più **users**, ognuno con un suo ID univoco (uid), username
e password. Gli utenti si raggruppano in **groups**, ognuno con un group ID univoco (gid).
Informazioni sugli user e sui gruppi sono mantenute in appositi file di configurazione.

Un utente ha le seguenti caratteristiche:

- `username`
- `user ID` (uid)
- `group ID` di default (gid) il gruppo di default costituito solo dall’utente stesso
- `altri groups ID` di appartenenza
- `home path`
- `default shell`

Oltre ai normali _user accounts_. Esiste sempre anche il _superuser account_ (root) è l’unico
superuser (UID = 0). Esistono infine anche i _system accounts_, creati per gestire/avviare
software e demoni e non pensati per essere direttamente usati dagli utenti umani.

- `id`: ritorna informazioni sull’utente attivo
- `who`: mostra gli utenti loggati correntemente
- `last`: mostra gli utenti che si sono loggati come uno storico

I file di configurazione degli utenti (detti access control files) sono tipicamente in
/etc. Di solito sono leggibili da tutti ma modificabili sono da root.

- `/etc/passwd`: info utenti del sistema, ma senza password
- `/etc/shadow`: contiene password degli utenti
- `/etc/group` lista i gruppi del sistema e i membri dei gruppi

```shell
$ grep -i ^bob /etc/passwd
# USERNAME:PASSWORD:UID:GID:GECOS:HOMEDIR:SHELL
bob:x:1001:1001::/home/bob:/bin/bash
```

```shell
$ grep -i ^bob /etc/shadow
# USERNAME:PASSWORD:LASTCHANGE:MINAGE:MAXAGE:WARN:INACTIVE:EXPDATE
bob:h@utotocuRXR7y72LLQk4Kdog7u09LsNFS@yZPkIC8pV9tgD@wXCHutYcWFhdsb73TfGfG0lj4JF63PyuPwKC18tJS.:18188:0:99999:7::
```

```shell
$ grep -i ^bob /etc/group
# NAME:PASSWORD:GID:MEMBERS
developer:x:1001:bob,sara
```

Riguardo ai campi delle entries presenti in `/etc/shadow`:

- `lastchange`: data (numero di giorni dal 01/01/1970) in cui la password è stata modificata
  per l'ultima volta. Un valore di 0 significa che la password deve essere modificata al
  prossimo accesso
- `minage`: la password non può essere modificata fino a quando la data non è _lastchange +
  minage_ (vuoto o 0 significa che la password può essere modificata in qualsiasi momento)
- `maxage`: la password deve essere modificata quando la data è _lastchange + maxage_, questa
  è la data di scadenza della password (vuoto significa che le password non scadono mai,
  quindi i campi maxage, warn e inattività non sono utilizzati)
- `warn`: l'utente verrà avvisato che è necessaria una modifica della password quando la data
  è _lastchange + maxage - warning_ (vuoto o 0 significa nessun periodo di avviso)
- `inactive`: l'utente potrà comunque modificare la propria password fino _inactive_ giorni
  dopo la scadenza della password (vuoto significa nessun periodo di inattività). Dopodiché,
  la password non funzionerà più
- `expdate`: la data di scadenza dell'account. Dopo tale data, gli accessi non saranno più
  consentiti. Vuoto significa che l'account non scade mai, 0 non deve essere utilizzato

## Users management

Per creare nuovi utenti si usa `useradd`, un nuovo utente viene inserito
nel file `/etc/passwd` con nuovo uid e gid. La sua home viene creata di default. Useradd
supporta molte opzioni:

- `-c`: aggiunge commento custom
- `-d`: specifica home directory
- `-e`: data di expiration dell’utente
- `-g`: specifica manualmente gID
- `-u`: specifica manualmente uID
- `-s`: specifica shell di login
- `-G`: specifica gruppi di appartenenza aggiuntivi

```shell
# add user and check results
$ useradd -u 1009 -e 1009 -d /home/bob -s /bin/bash -c "bob user" --gecos "bob@gmail.com" bob

$ id bob
# uid=1009 gid=1009 groups=1009
$ grep -i bob /etc/passwd
# bob:x:1009:1009:bob@gmail.com:/home/bob:/bin/bash
```

Per settare la password per uno user esiste il comando `passwd <user>`, il comando va usato
da root o da dall’utente stesso per cambiare la sua stessa password. Il comando `chage` viene
usato per gestire diverse impostazioni di un utente relative a login e password.

```shell
# verify the state of the user
$ chage -l <user>

$ chage --lastday 0 jane     # setta expiration date per password
$ chage --maxdays 30 jane    # user deve cambiare password ogni 30 giorni	
$ chage --maxdays -1 jane    # no limits on max days
$ chage --warndays 2 jane    # gets a warning 2 days before the password expires
```

Il comando `userdel` elimina un utente, opzionalmente anche la sua home dir viene
eliminata.

```shell
# remove user and its home directory
$ userdel --remove <user>
# remove its primary group
$ groupdel <username>
```

Il comando `usermod` modifica un utente già esistente.

```shell
# change home directory, expiration and group for the bob user
$ usermod -d /home/bob_2 -e 2020-05-29 -g heros bob

# move home directory, shell and other stuff related to a user 
$ usermod --home /home/otherdirectory --move-home john 
$ usermod --login jane john
$ usermod --shell /bin/othershell jane
# set expiration date for user
$ sudo usermod --expiredate 2021-12-29 jane
```

## Groups management

Esistono due tipi di gruppi:

- _primary group/login group_: gruppo primario di un utente, viene creato al momento della
  creazione dell’utente
- _secondary group_: gruppi addizionali aggiunti in un secondo momento

Quando creiamo file o lanciamo processi, essi hanno permessi/ownership di uid + primary gid.

Per creare/eliminare nuovi gruppi: `groupadd/groupdel <nome>`.

```shell
# add group with specific name and gid
$ groupadd -g 1010 mygroup

# check the outcome
$ grep -i ^mygroup /etc/group
mygroup:x:1010:
```

I gruppi possono essere modificati tramite `groupmod` ed eliminati tramite `groupdel`:

```shell
# change group name
$ groupmod --new-name programmers developers
# delete group
$ groupdel programmers
```

Per visualizzare il primary group e i secondary groups di un utente esiste il comando `groups`:

```shell
$ groups <user>
```

Per aggiungere un utente a un gruppo, rimuoverlo o effettuare modifiche è possibile usare
sia `gpasswd` che `usermod`:

```shell
# add user to group
$ gpasswd --add <user> <group>
# remove user from group
$ gpasswd --delete <user> <group>
# modifica primary group per utente
$ usermod -g <group> <user>
# aggiunge utente a secondary group 
$ usermod -G <group> <user>
```

## Su & sudo

Per switchare da un user all’altro esistono alcuni comandi specifici, `su` e `sudo`. Il primo
switcha ad altro utente, chiedendone la password, mentre il secondo permette di eseguire solo
determinate operazioni secondo delle precise policy configurabili, ma impersonando l'utente
solo per il comando specifico da eseguire. Tipicamente si ha necessità di eseguire comandi
come un altro utente (es. root) per ottenere i permessi necessari a quell'operazione.

Tipicamente i gruppi _wheel_/_admin_/_sudoers_ sono i gruppi admin che possono usare _sudo_
per impersonificare root e lanciare comandi che richiedono alti privilegi.

La directory `/etc/sudoers.d` ed il file `/etc/sudoers` contengono i files delle policy.
Ogni entry di questi file controlla le operazioni che è possibile eseguire per un utente
o gruppo e quali altri utenti/gruppi possono essere impersonificati.

⚠️ Never edit these files with a normal text editor! Always use the `visudo` command instead!

Il formato delle entries è:

`<user/%group> <hostname>=(<users>:<groups>) <command>`

- the first field indicates the user or group that the rule will apply to
- the <hostname> indicates on which hosts this rule will apply on
- the <users> indicates the users that can be impersonated
- the <groups> indicates the groups that can be impersonated
- the <command> indicates the commands that can be run

```shell
$ sudo visudo

# reset env vars when switching users
Defaults env_reset

User privilege specification
root    ALL=(ALL:ALL) ALL
# members of the admin group can run all commands as every user
%admin  ALL=(ALL) ALL
# members of the sudo group can run all commands as every user/group
%sudo   ALL=(ALL:ALL) ALL
# user Bob can to run any command as every user/group
bob     ALL=(ALL:ALL) ALL
# user Sarah can reboot the system (default=ALL)
sarah   localhost=/usr/bin/shutdown -r now
# user mark can run ls and stats as user alice or carl 
mark    ALL=(alice,carl)	/bin/ls,/bin/stats

# See sudoers(5) for more information on "#include"
directives:
#includedir/etc/sudoers.d
```

```shell
# user mark can
$ sudo -u alice ls /home/alice
```

Se vogliamo loggarci come root con password dobbiamo settare la password di root e assicurarsi
che lo user root non sia lockato (`passwd root` + `passwd --unlock`). Viceversa se vogliamo
lockare root: `passwd --lock root`. WARNING: lockare root è safe solo se hai sudo privilegies
con un altro utente e puoi loggarti con tale utente altrimenti sei tagliato fuori dalla
macchina.

Per loggarsi come root da un altro utente:

```shell
$ sudo --login     
```

## System wide env profiles

Due tipi di file controllano l'ambiente in cui viene lanciata una shell session: i file
`.bashrc` e i files `.profile` per i singoli utenti, mentre il file `/etc/environment`
controlla env vars per tutti.

- `~/.profile` is one of your own user's personal shell initialization scripts. Every user
  has one and can edit their file without affecting others. `/etc/profile` and
  `/etc/profile.d/*.sh` are the global initialization scripts that are equivalent
  to _~/.profile_ for each user. The global scripts get executed before the user-specific
  scripts though; and the main _/etc/profile_ executes all the *.sh scripts in _/etc/profile.
  d/_ just before
- `~/.bashrc` is the place to put stuff that applies only to bash itself, such as alias
  and function definitions, shell options, and prompt settings.
- `~/.bash_profile`, bash uses it instead of _~/.profile_ or _~/.bash_login_.

According to the bash man page, _.bash_profile_ is executed for login shells, while _.bashrc_
is executed for interactive non-login shells.

## User resource limits

Il file `/etc/security/limits.conf` contiene i limiti di risorse utilizzabili dai singoli
utenti. Il file è diviso in colonne:

- _domain_: username/gruppo (applicato a tutti), * = everyone (defaults)
- _type_: hard/soft/both, hard è fisso, non modificabile e non superabile, soft può essere
  modificato fino ad hard
- _item_: risorsa in question, e.g. nproc (numero di processi creati)/fsize (max size file
  creato)/cpu (core usage * second)
- _value_: the limit related to the item

```shell
# mostra i limiti per l’utente corrente
$ ulimit -a

# setta un limite per un dato parametro, si può abbassare, alzare
# se soft (fino a max), solo root può fare tutto liberamente
$ ulimit -u 
```




