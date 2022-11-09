# 📄 Files

_Tutto è un file in Linux_ o quasi. Questo è un motto del mondo Linux, dove molte cose sono 
modellate ed esposte con un interfaccia file-simile.

Esistono diversi tipi di file:
- `regular files`, `-`: normal files
- `directory files`, `d`: directories
- special files:
  - `character files`, `c`: rappresentano device con cui si comunica in modo seriale
  - `block files`, `b`: rappresentano device con cui si comunica tramite blocchi di dati
  - `hard link files`, `-`: puntatori reali ad un file su disco, eliminare l’ultimo 
    significa eliminare il file
  - `soft link files`, `l`: shortcut verso un altro file, ma non i dati
  - `socket files`, `s`: file per comunicazione fra processi, via network e non
  - `pipes files`, `p`: file per comunicazione unidirezionale fra due processi

Esistono due comandi utili per esaminare il tipo di un file:

```shell
# reports the type and some additional info about a file
$ file <path>

# list file(s) and some infos like number of hard links, 
# permissions, size , etc.
$ ls -alh [file, ...] 
```

### Linux filesystem hierarchy

Tipicamente il filesystem linux è organizzato come segue, si tratta di convenzioni.

- `/home`   -> contiene le cartelle degli utenti è aliasata dal simbolo ~ (tilde)
- `/root`   -> home dell’utente root

- `/media`  -> montati filesystem di device esterni e rimuovili (es. USB)
- `/dev`    -> contiene i file speciali di tipo carattere e blocco (es. hard disk, mouse, etc)
- `/mnt`    -> filesystem montati temporaneamente

- `/opt`    -> dove vengono installati programmi di terze parti
- `/etc`    -> usata tipicamente per file di configurazione
- `/bin`    -> contiene i binari dei software di sistema
- `/lib`    -> contiene librerie (statiche e dinamiche) dei software di sistema
- `/usr`    -> contiene i binari di applicazioni degli utenti
- `/var`    -> contiene tipicamente dati scritti da applicazioni, es logs e caches

- `/tmp`    -> cartella con file e dati temporanei

## File manipulation

### Archival and compression

Il comando tar è usato per raggruppare file e creare archivi (definiti tarballs). Il comando
ls supporta un flag per vedere dentro una tarball. I comandi più utili sono:

```shell
# create tarball from specified files
$ tar -cf <output> <files..>

# create tarball and compress it
$ tar -zcf <output> <files..>

# look at the tarball contents
$ tar -tf <tarball>

# extract contents in specified directory
$ tar -xf <tarball> -C <output_dir>
```

La compressione riduce la dimensione dei file, fra le utilities più utili ci sono `bzip2`,
`gzip` e `xz`. Ogni utility può utilizzare diversi algoritmi e diversi livelli compressione.
Non serve sempre decomprimere un file per poterlo leggere, es. `zcat` legge un file
compresso senza decomprimerlo davvero.

```shell
# compress a file
$ gzip --keep -v <file>
# decompress a file
$ gzip/gunzip --keep -vd <file>
```

### Searching & grepping

Il comando `find` cerca un file in una specifica director. Il comando find è potente e 
supporta un ricco set di flags ed opzioni, è ricorsivo di default. Ecco alcuni esempi.

```shell
# general usage pattern
$ find <root-di-ricerca> -name <nome-file>

# find files under /home directory with a specific name
$ find /home -name file.txt
# same but ignore case, and use wildcards
$ find /home -iname "file.*"
# find directories, not files
$ find /home -type d -name <dir_name>

# find files whose permissions are 777 owned by the user
$ find /home -type f -perm 0777 -user <user>
# find files and for each of them exec a command
$ find /home -type f -perm 0777 -exec chmod 644 {} \;
```

Esiste anche il comando `locate` cerca un file nel filesystem, ma si base su un DB locale 
creato ed aggiornato periodicamente e non sempre necessariamente aggiornato (`updatedb` per 
riaggiornare). 

Il comando **`grep`** è molto utilizzato per cercare pattern all’interno di files.

- `-i` 	ricerca case insensitive (di default è case sensitive)
- `-r` 	ricerca ricorsiva in tutti i file a partire da una root
- `-v` 	ricerca per linee dove non c’è match col pattern
- `-w`	matcha solo le parole e non le substring di parole
- `-A <n>`	riporta i match e _n_ linee dopo
- `-B <n>`	riporta i match e _n_ linee prima

```shell
# general usage pattern
$ grep <options> <pattern> <files>

# grep lines starting with hello in txt files 
$ grep "^hello" *.txt
# grep lines starting with "fn" and some lines around, 
# recursive mode starting from current directory
$ grep -A 3 -B 2 -r -i "^fn" .
```

## Permissions

### Title3

```shell
```

```shell
```

```shell
```

### Title3

```shell
```

```shell
```

```shell
```
