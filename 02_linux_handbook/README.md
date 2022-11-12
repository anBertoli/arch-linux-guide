# Concetti di base

Il core del sistema operativo è il `kernel`. Il kernel si occupa di gestire la memoria (RAM), 
gestire i processi del sistema (CPU), gestire i device fisici (comunicazione fra processi e 
hardware) e offrire agli applicativi accesso controllato all'hardware (tramite system call). 
Il kernel è monolitico ma modulare, cioè può estendere le sue capacità tramite module kernel 
caricabili a runtime.

Il sistema operativo si divide fra `kernel space` (processi e risorse usati dal kernel) e 
`user space` (processi applicativi). I programmi in user space interagiscono con l’hardware
comunicando col kernel via `system calls`. Una system call è una richiesta specifica 
al kernel, dove il kernel prende il controllo, esegue le operazioni richieste e restituisce 
il risultato e/o eventuali errori.

## Hardware

Quando un device è collegato un device driver detecta il device è genera un evento (uevent) 
che viene inoltrato ad un processo userspace chiamato `udev`. Quest’ultimo processa l’evento
creando una `device file` che rappresenta il device nella cartella, tipicamente in /dev (e.g. 
/dev/sdd1).

Il comando `dmesg` ottiene messagi e logs generati dal kernel. Questi messaggi contengono 
anche log relativi all’hardware, per cui è possibile debuggare o saperne di più sui device 
collegati tramite questo comando. Inoltre il comando `udevadm` interroga udev per ottenere 
informazioni sui device e sugli eventi udev. Il comando invece `lspci` riporta informazioni 
sugli hardware attaccati alle porte PCI. Il comando `lsblk` lista informazioni 
esclusivamente sui block devices, sui dischi e le loro partizioni. Il comando `lscpu` 
fornisce informazioni sulla CPU. Il comando `lsmem` fornisce informazioni sulla RAM 
(provare con e senza --summary è utile), mentre `free -m` fornisce informazioni sulla memoria 
usata e libera. Il comando `lshw` fornisce info su tutto l’hardware del sistema.

## Boot Sequence

Approfondimento **consigliato** su Linux boot sequence:
https://www.happyassassin.net/posts/2014/01/25/uefi-boot-how-does-that-actually-work-then/

Il boot di un sistema Linux è composto fondamentalmente da 4 step. 

**POST**. Componente base del firmware del sistema che si assicura che tutto l’hardware 
collegato funzioni correttamente.  

**UEFI** (rimpiazza BIOS). Firmware della scheda madre che si occupa di caricare in memoria ed 
avviare sulla CPU il primo non-firmware (tipicamente bootloader). UEFI è un firmware 
"intelligente" in grado di leggere certe partizioni da disco, in particolare quelle formattate
con filesystem EFI, dove tipicamente si trova il bootloader. Una piccola memoria persistente
(NVRAM) salva le `boot entries`, ovvero una lista di indicazioni su come e da dove eseguire il
successivo step di boot. La NVRAM viene letta all'avvio dal firmware UEFI (consiglio link 
sopra per una spiegazione più completa).

**Bootloader (GRUB)**. Si occupa di caricare il kernel in memoria e gli da il controllo 
della CPU. 

**Kernel init**. Il sistema operativo inizializza driver, memoria, strutture dati interne 
etc. 

**User space init**. Avvia il processo init (PID 1) dello user space, lo standard è `systemd` 
ai giorni nostri.

Il runlevel è una modalità operativa del sistema operativo, ad esempio il boot fino al 
terminale (raw) è considerato livello 3, per interfaccia grafica tipicamente 5. Per ogni 
runlevel esistono delle componenti software da avviare e verificare ed ogni runlevel 
corrisponde ad un target systemd (e.s. 3 = terminale = multiuser.target, 5 = grafico = 
graphical.target).  Il comando systemctl può essere usato per verificare il runlevel di 
default e modificarlo. Notare che il termine runlevels è usato nei sistemi con sysV init. 
Questi sono stati sostituiti da target systemd nei sistemi basati su di esso. L'elenco 
completo dei runlevel e dei corrispondenti target di sistema è il seguente.

- runlevel 0 --> poweroff.target
- runlevel 1 --> rescue.target
- runlevel 2 --> multi-user.target
- runlevel 3 --> multi-user.target
- runlevel 4 --> multi-user.target
- runlevel 5 --> graphical.target
- runlevel 6 --> reboot.target

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

# ⚙️ Disks, partitions and filesystems

## Partitions

Le partizioni sono entità logiche (ma scritte anche su disco) che dividono un disco fisico 
e rendono indipendenti diverse porzioni dello stesso. Tipicamente partizioni diverse 
vengono  usate per diversi scopi e sulle partizioni possono essere configurati filesystems 
diversi (EXT4, EFI, FAT, SWAP, etc.).

Le partizioni sono invididuabili come block devices sotto `/dev`. Un block device è un file 
che rappresenta un pezzo di hardware che può immagazzinare dati, scritto a blocchi. Il comando 
`lsblk` lista i block devices, come da esempio sotto. Come si può notare esiste un disco 
_sda_ fisico, suddiviso in sezioni logiche che sono le partizioni. 

<img src="../02_linux_handbook/assets/lsblk.png" width="600"/>

Ogni block device ha una versione `major` e `minor`. La major version (8) identifica il tipo 
di hardware mentre la minor version (0,1,2,3) individua le singole partizioni.

I comandi com3 `lsblk` o `fdisk` leggono le partizioni da una zona del disco chiamata
partition table (di due tipi, MBR o GPT),  che contiene tutte le informazioni su come e diviso
ed organizzato il disco, quante partizioni ha, che filesystem ha, etc. Esistono diversi 
schemi di organizzazione delle partizioni e quindi diversi tipi di partiton tables:
- `MBR`, master boot record: legacy, max 2TB, max 4 partizioni senza extended partitions
- `GPT`, guid partition table: nuova e migliore, unlimited number of partitions, no max size

Esistono 3 tipi di partizioni:
- primary partition: partizione usata per bootare l’OS, nel passato con MBR non potevano 
  esserci più di 4
- extended partition: partizione non usabile di per sè, solo un contenitore per partizioni 
  logiche, ha una sua partition table interna, legacy
- logical partition: sub-partizione contenuta nelle extended partition, legacy


Esistono diversi comandi per gestire le partizioni, fra cui `gdisk`. E' una CLI interattiva.

```shell
# start the gdisk CLI
$ gdisk </path/to/your/device/file>
  # show help and commands
  > ?
  # list current partitions on disk
  > p 
  # create new partition, it will ask first and last sector so the
  # size of the partition will be (last sector - first sector)
  # OR you can input the first sector and the size directly as the 
  # last sector field e.g. +100G
  > n
  # show type of partitions, then choose appropriate value
  # (EFI type, Linux filesystem, etc)
  > l
  # confirm partitions creation and exit
  > w
```

## Filesystems

Il partizionamento di per se non basta per rendere un disco utilizzabile dall’OS. Dobbiamo 
anche creare un filesystem nella partizione e poi montare la partizione su una directory. Un 
file system è uno standard che definisce come i file ed i dati devono essere organizzati 
su disco. 

I linux filesystem più diffusi sono `ext2`, `ext3` e `ext4`. I filesystem sono una
caratteristica di una partizione, scritti in corrispondenza delle partition entries della
partition table, servono quindi ad indicare agli OS come interpretare/trattare le partizioni 
di un disco.

Il comando `mkfs` crea un filesystem su una partizione. 
```shell
# create filesystem on specified partition
$ mkfs.ext4 <path/to/device>
```

Il comando `mount` monta una partizione in una locazione del filesystem.
```shell
# create partition on specified filesystem point
$ mount <path/to/device> <path/to/mount>
# list all mounts
$ mount
```
Per far permanere le modifiche (i mounts) è necessario editare il file `/etc/fstab`. Tale 
file raccoglie la lista dei mount point per ogni partizione ed il tipo di file system 
utilizzato, più alcune opzioni aggiuntive. La sintasi delle righe è la seguente: 

`<partizione> <mount-point> <fs-type> <options> <dump> <pass>` 
(dump controlla backups, pass controlla se bisogna fare check sul fs dopo crash)

<img src="../02_linux_handbook/assets/fstab.png" width="600"/>

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

