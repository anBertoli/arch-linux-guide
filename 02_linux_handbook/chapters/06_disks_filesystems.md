# ⚙️ Disks, partitions and filesystems

## Partitions

Le partizioni sono entità logiche (ma scritte anche su disco) che dividono un disco fisico
e rendono indipendenti diverse porzioni dello stesso. Tipicamente partizioni diverse
vengono usate per diversi scopi e sulle partizioni possono essere configurati filesystems
diversi (EXT4, EFI, FAT, SWAP, etc.).

Le partizioni sono invididuabili come block devices sotto `/dev`. Un block device è un file
che rappresenta un pezzo di hardware che può immagazzinare dati, scritto a blocchi. Il comando
`lsblk` lista i block devices, come da esempio sotto. Come si può notare esiste un disco
_sda_ fisico, suddiviso in sezioni logiche che sono le partizioni.

<img src="../../02_linux_handbook/assets/lsblk.png" width="600"/>

Ogni block device ha una versione `major` e `minor`. La major version (8) identifica il tipo
di hardware mentre la minor version (0,1,2,3) individua le singole partizioni.

I comandi come `lsblk` o `fdisk` leggono le partizioni da una zona del disco chiamata
partition table (di due tipi, MBR o GPT), che contiene tutte le informazioni su come e diviso
ed organizzato il disco, quante partizioni ha, che filesystem ha, etc. Esistono diversi
schemi di organizzazione delle partizioni e quindi diversi tipi di partiton tables:

- `MBR`, master boot record: legacy, max 2TB, max 4 partizioni senza extended partitions
- `GPT`, guid partition table: nuova e migliore, unlimited number of partitions, no max size

Esistono 3 tipi di partizioni:

- _primary partition_: partizione normale, nel passato con MBR non potevano essercene più di 4
  (può essere usata per bootare l’OS)
- _extended partition_: partizione non usabile di per sè, solo un contenitore per partizioni
  logiche, ha una sua partition table interna, legacy
- _logical partition_: sub-partizione contenuta nelle extended partition, legacy

### Partitions management

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

Lo _swap space/partition_ è un’area di riserva per la RAM, una partizione dedicata per lo
swap deve essere creata al momento del partizionamento e successivamente attivata. La
creazione della partizione è eseguibile tramite _gdisk_, mentre si usano `mkswap` e `swapon`
rispettivamente per setuppare una partizione con swap space e per comunicare al kernel di
usare tale partizione per lo swap.

```shell
# show swap partitions and current usage
$ swapon --show

# format the swap partition
$ mkswap --verbose /dev/<swap-partition>
# activate swap partitions
$ sudo swapon --verbose /dev/<swap-partition>
```

## Filesystems

Il partizionamento di per se non basta per rendere un disco utilizzabile dall’OS. Dobbiamo
anche creare un filesystem nella partizione e poi montare la partizione su una directory. Un
file system è uno standard che definisce come i file ed i dati devono essere organizzati
su disco.

I linux filesystem più diffusi sono _ext2_, _ext3_ e _ext4_. I filesystem sono una
caratteristica di una partizione, scritti in corrispondenza delle partition entries della
partition table, servono quindi ad indicare agli OS come interpretare/trattare le partizioni
di un disco.

Il comando `mkfs` crea un filesystem su una partizione.

```shell
# create filesystem on specified partition
$ mkfs.ext4 <path/to/partition_file>
```

Il comando `mount` monta una partizione in una locazione del filesystem.

```shell
# mount partition on specified filesystem point
$ mount <path/to/partition_file> <path/to/mount>
# mount partition with options
$ mount -o ro,noexec,nosuid <path/to/partition_file> <path/to/mount>
# list all mounts
$ mount
```

Per far permanere le modifiche (i mounts) al boot è necessario editare il file 📄`/etc/fstab`.
Tale file raccoglie la lista dei mount point per ogni partizione ed il tipo di file system
utilizzato, più alcune opzioni aggiuntive. La sintassi delle righe è la seguente:
`<partizione> <mount-point> <fs-type> <options> <dump> <pass>`. Ecco un esempio:

```shell
$ cat /etc/fstab
# /dev/sda1    /        ext4   defaults   0   0 
# /dev/sda2    /mnt     ext4   defaults   0   0 
# /dev/sda3    none     swap   defaults   0   0 
# etc.

# fields (6)
#   1 - dev file path or partition UUID
#   2 - mount point
#   3 - fs type
#   4 - mounting options (defaults)
#   5 - dump should backup (0)
#   6 - errors detection (0 = no scan,  1 = scan for errors, 2 = scan with more priority than 1)
```

Se editato deve essere ricaricato tramite _systemctl_ (o reboot). Per swap non c’è mount point.

Il comando `findmnt`/`mount` lista tutti i fs montati e le relative opzioni di mount. La
maggior parte di queste opzioni sono settate al momento del `mount`.

- _rw/ro_: read and write/read only file systems
- _noexec_: cannot launch programs here
- _nosuid_: cannot use *setuid/setgid* bits

Alcune opzioni sono però fs specifiche e si possono usare quindi solo con fs specifici. Le
mount options possono essere specificate nell’ultima colonna di _/etc/fstab_.

## DAS, NAS and SAN

- `DAS`: direct attached storage
- `NAS`: network attached storage
- `SAN`: storage area network

`DAS` impiega uno storage fisico direttamente collegato ad una macchina, è di tipo block,
veloce, affidabile, dedicato per un singolo host e ideale per piccoli business. Non sono
coinvolti firewall o rete di alcun tipo, poichè l’hardware è direttamente collegato
alla macchina.

`NAS` è uno storage che scambia dati con le macchine tramite rete, il network deve essere
attraversato e quindi può introdurre latenza. Per gli host, il filesystem NFS montato appare
come un normale mount point (directory) nel filesystem dell’host. Abbastanza veloce,
condiviso fra piu macchine, ma risente della rete. SAN è un block storage simile, è
condiviso ma comunica con gli host tramite fibra ottica.

I sistemi NAS (ma non solo), usano tipi di filesystem come `NFS` (_network file system_).
Questo filesystem nello specifico lavora tramite files e non blocchi ed opera con un
paradigma client server. NFS viene montato sulle macchine client su specifici mount point
(come ogni altro filesystem), ed appare come normali directories. Nel modello client-server,
il server NFS mantiene il suo filesystem e quando gli host montano il filesystem possono
accedere al filesystem condiviso (sempre via rete). Solitamente solo specifiche cartelle
dello storage sel server sono montate sui client.

Il server NFS mantiene una lista di exports (in `/etc/exports`), ovvero una lista di
directories esposte alle macchine client. Possono esistere firewall da configurare fra
macchina/NFS client e NFS server.

## Logical volume mounting (LVM)

Il LVM permette di raggruppare diversi dischi e/o partizioni creando _volume groups_, i quali
possono essere poi splittati in _logical volumes_. Un gruppo può raggruppare molti dischi o
partizioni. Uno dei vantaggi di questo metodo è che i volumi logici possono essere re-sizati
dinamicamente senza dover smontare e rimontare i filesystem.

I concetti principali di LVM sono:

- `pv`, _physical volume_: storage device fisici, da assegnare a LVM per l’utilizzo (di
  solito sono dischi interi, non partizioni)
- `vg`, _volume group_: un singolo disco virtuale, composto raggruppando piú physical volumes
- `lv`, _logical volume_: una “partizione” di un volume group, simile alle partizioni
  classiche nel concetto
- `pe`, _physical extent_

Per usare LVM è necessario installare il package `lvm2`. E’ necessario identificare
partizioni/dischi liberi da includere nel futuro volume group e creare `physical volumes` a
partire da tali partizioni (i volumi fisici sono degli identificativi usati da LVM per i
dischi fisici/partizioni). Si passa poi alla creazione dei volumes groups e dei logical
volumes che possono essere formattati con un filesystem specifico e infine montati. Di seguito
una guida.

Si parte dalla creazione di _physical volumes_:

```shell
# list physical volumes and their usage in LVM context
$ lvmdiskscan

# create a couple of physical volumes from real storage partitions
$ pvcreate /dev/sda1 /dev/sda2
# show physical volumes
$ pvs
```

Dopo, si deve aggiungere i pv ad un _volume group_. Dopodiché possiamo vedere il _volume
group_ come un unico disco “virtuale” con spazio che é la somma dei singoli _physical
volumes_. Il _volume group_ è un disco virtuale che puó essere allargato aggiungendo
nuove partizioni.

```shell
# create a volume group from physical volumes
$ vgcreate my_volume_group_name /dev/sda1 /dev/sda2

# list virtual groups
$ vgs
```

Per aggiungere un nuovo pv al _volume group_ giá esistente:

```shell
# create new physical volume from partition
$ pvcreate /dev/sda3
# add the pv to the pre-existent volume group
$ vgextend my_volume_group_name /dev/sda3

# list virtual groups
$ vgs
```

Per rimuovere un pv da un _volume group_ ed eliminare il pv:

```shell
# remove pv from vg
$ vgreduce my_volume_group_name /dev/sda3
# completely remove pv from the system 
$ pvremove /dev/sda3
```

Ora é necessario creare dei _logical volumes_ all'interno del volume group creato prima.
Un logical volume è simile al concetto di partizione per un disco fisico:

```shell
# create two logical volumes for the volume group
$ lvcreate --size 2G --name part1 my_volume_group_name
$ lvcreate --size 4G --name part2 my_volume_group_name
 
# list logical volumes
$ lvs
```

Per espandere un _logical volume_ per occupare tutto lo spazio disponibile nel suo _volume
group_ esistono diverse opzioni, fra cui:

```shell
# expand logical volume
$ lvresize --extents 100%VG my_volume_group_name/part1
# shrink logical volume
$ lvresize --size 1G my_volume_group_name/part1
```

Serve ovviamente anche creare un filesystem per questi _logical volumes_ (empty logical
volume=empty partition). Da quando abbiamo un FS sul lv, dobbiamo fare i resize con un
parametro specifico, _-resizefs_, in modo da resizare non solo il logical volume ma anche
l'fs scritto sopra. Non tutti i FS possono essere resizati dopo creazione.

```shell
# describe logical volumes, it shows the logical volumes 
# are in /dev/<volume_group>/<logical_volume>
$ lvdisplay

# create the fs on the logical volume
$ mkfs.ext4 /dev/my_volume_group_name/part1

# resize with the special option (if needed)
$ lvresize --resizefs --size 6G /dev/my_volume_group_name/part1
```

## RAID

### Devices

A RAID (_redundant array of independent disks_) is an array of multiple storage devices
combined in a single storage area. Quindi si pososno raggruppare piú dischi per formare
array di dischi (2,3,4, etc.), che in base alla configurazione, hanno un certo grado di
ridondanza dei dati.

- *level 0 RAID array (stripe)*: un gruppo di dischi sono raggruppati in un array level 0,
  la size totale é la somma dei singoli dischi, ma se failure disco dati persi (not redundant)
- *level 1 RAID array (mirrored)*: i dati sono clonati su tutti i dischi, singolo failure
  non compromette i dati
- *level 5 RAID array:* almeno 3 dischi, i dati non sono duplicati, ma altri dischi
  contengono dati di parity su altri dischi (sort of backup di altri dischi). Posso perdere
  fino a 1 disco
- *level 6 RAID array*: maggiore parity, posso fino perdere 2 dischi
- *level 0+1 RAID array:* array of drives, each array mirrored

Possiamo creare un array RAID con i seguente comando. Definiamo _/dev/md0_ come il block
device creato come risultato, _level_ è il livello del RAID, _—raid-devices_ è il numero di
dischi nell’array RAID.

```shell
# create a RAID array from 3 partitions
$ mdadm --create /dev/md0 -level 0 --raid-devices=3 /dev/sda1 /dev/sda2 /dev/sda3
# create a filesystem on it
$ mkfs.ext4 /dev/md0
```

Per stoppare un RAID:

```shell
$ mdadm --stop /dev/md0
```

Informazioni nel superblocco dei dischi riportano se i disco stesso fa parte di un RAID, in tal
caso Linux al boot ricrea in automatico il RAID array (esiste il flag *—zero-superbock* per
cancellare tale informazione).

Per aggiungere/rimuovere un disco ad un RAID già esistente:

```shell
$ mdadm --manage /dev/md0 --add /dev/vde
$ mdadm --manage /dev/md0 --remove /dev/vde
```

Possiamo anche aggiungere spare disks ai RAID, si tratta di dischi di riserva se un disco
fallisce.

```shell
$ mdadm --create /dev/md0 -level 1 --raid-devices=2 /dev/sda1 /dev/sda2 --spare-devices=1 
/dev/vde 
```