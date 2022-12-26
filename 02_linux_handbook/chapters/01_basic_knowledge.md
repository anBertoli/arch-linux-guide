# 📝 Concetti di base

Il core del sistema operativo è il `kernel`. Il kernel si occupa di gestire la memoria (RAM),
gestire i processi del sistema (CPU), gestire i device fisici (comunicazione fra processi e
hardware) e offrire agli applicativi accesso controllato all'hardware. Il kernel è monolitico
ma modulare, cioè può estendere le sue capacità tramite moduli caricabili a runtime.

Il sistema operativo si divide fra `kernel space` (processi e risorse usati dal kernel) e
`user space` (processi applicativi). I programmi in user space interagiscono con l’hardware
comunicando col kernel via `system calls`. Una system call è una richiesta specifica
al kernel, dove il kernel prende il controllo, esegue le operazioni richieste e restituisce
il risultato e/o eventuali errori.

## Hardware

Quando un device è collegato un device driver Linux detecta il device è genera un evento
(_uevent_) che viene inoltrato ad un processo userspace chiamato `udev`. Quest’ultimo
processa l’evento creando una `device file` (che rappresenta il device) in una cartella,
tipicamente `/dev` (e.g. `/dev/sdd1`).

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

- **POST**. Componente base del firmware del sistema che si assicura che tutto l’hardware
  collegato funzioni correttamente.
- **UEFI** (rimpiazza BIOS). Firmware della scheda madre che si occupa di caricare in
  memoria ed
  avviare sulla CPU il primo non-firmware (tipicamente bootloader). UEFI è un firmware
  "intelligente" in grado di leggere certe partizioni da disco, in particolare quelle
  formattate
  con filesystem EFI, dove tipicamente si trova il bootloader. Una piccola memoria persistente
  (NVRAM) salva le `boot entries`, ovvero una lista di indicazioni su come e da dove eseguire
  il
  successivo step di boot. La NVRAM viene letta all'avvio dal firmware UEFI (consiglio link
  sopra per una spiegazione più completa).
- **Bootloader (GRUB)**. Si occupa di caricare il kernel in memoria e gli da il controllo
  della CPU.
- **Kernel init**. Il sistema operativo inizializza driver, memoria, strutture dati interne
  etc.
- **User space init**. Avvia il processo init (PID 1) dello user space, lo standard è
  `systemd` ai giorni nostri.

Il runlevel è una modalità operativa del sistema operativo, ad esempio il boot fino al
terminale (raw) è considerato livello 3, per interfaccia grafica tipicamente 5. Per ogni
runlevel esistono delle componenti software da avviare e verificare ed ogni runlevel
corrisponde ad un target systemd (e.s. 3 = terminale = multiuser.target, 5 = grafico =
graphical.target). Il comando systemctl può essere usato per verificare il runlevel di
default e modificarlo. Notare che il termine runlevels è usato nei sistemi con sysV init.
Questi sono stati sostituiti da target systemd nei sistemi basati su di esso. L'elenco
completo dei runlevel e dei corrispondenti target di sistema è il seguente.

- _runlevel 0_: `poweroff.target`
- _runlevel 1_: `rescue.target`
- _runlevel 2_: `multi-user.target`
- _runlevel 3_: `multi-user.target`
- _runlevel 4_: `multi-user.target`
- _runlevel 5_: `graphical.target`
- _runlevel 6_: `reboot.target`

## Log in

- local/remote text mode
- local/remote graphical mode

Originariamente esistevano le console o terminali: postazioni per utenti diversi per accedere
alla stessa macchina. Da molti anni sono concetti virtuali, con i _virtual terminal_: in
Linux ci si accede con _ctrl + alt + f2_. Sono come i terminali del passato ma virtuali e
multipli. In ambienti grafici si usano più spesso i _terminal emulator_: software user space
con interfaccia grafica che offrono le stesse funzionalità di un terminale (virtuale).
