# Files

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

Esistono due comandi per esaminare il tipo di un file:

```shell
# reports the type and some additional info about a file
$ file <path>

# list file(s) and some infos like number of hard links, 
# permissions, size , etc.
$ ls -alh [file, ...] 
```

## Linux filesystem hierarchy

Tipicamente il filesystem linux è organizzato come segue, anche se si tratta di convenzioni.

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

```shell
```

```shell
```

```shell
```

## Title2

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

### Title3

```shell
```

```shell
```

```shell
```

## Title2

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

### Title3

```shell
```

```shell
```

```shell
```
