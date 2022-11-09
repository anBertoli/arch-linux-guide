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

<img src="../assets/lsblk.png" width="600"/>

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

<img src="../assets/fstab.png" width="600"/>

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
