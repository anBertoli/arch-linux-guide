# 📚 Libs & dependencies

Le distribuzioni Linux usano package managers per gestire le dipendenze. Per dipendenze si
intende librerie necessarie per eseguire e/o compilare un software. Esistono due filoni
principali di distribuzioni Linux. RHEL (Red Hat), Centos, Fedora usano il package manager
`rpm` mentre Debian, Ubuntu, Arch Linux usano il package manager `deb`. La distribuzione Red
Hat è a pagamento ma offe anche assistenza, CentOS è un derivato di Red Hat.

Un package è un archivio compresso che comprende tutti i file che compongono una dipendenza.
Prendiamo ad esempio un package DEB. L’archivio `.deb` conterrà i binari/librerie, i files
e script di configurazione, metadati sul software e un file manifest che lista le dipendenze
transitive del package stesso. Installare un package senza un package manager generalmente non
porta all’installazione di dipendenze transitive del package stesso (ed è quindi un proceso
molto manuale ed error-prone).

Un package manager è un software che automatizza e semplifica l’installazione, la rimozione,
l'upgrade di software, controlla l’integrità e l’autenticità dei package, automatizza
installazione ricorsiva delle dipendenze. Alcuni esempi: DPKG (debian like), APT (front end
per DPKG), APT-GET (front end per DPKG), RPM (red hat like), YUM (front end per RPM),
DNF (front end per RPM).

## Red Hat Package Manager (RPM & YUM)

`rpm` non risolve dipendenze automaticamente, per fare questo usa un front end chiamato `yum`.
Il package manager yum sfrutta software repositories remoti, che sono collezioni di package,
le info sui repos remoti sono salvati localmente (files di configurazione in `/etc/yum.repos.
d` e files `/etc/yum.respos.d/.repo`). yum usa rpm internamente ma si occupa anche delle
dipendenze transitive seguendo i seguenti step:

- controlla se il package da installare, se è presente esce
- se non è presente, verifica i repo configurati per vedere se contengono il package richiesto
- verifica le dipendenze del package, se ci sono e se sono eventualmente da upgradare
- download dei .rpm necessari, installazione a lancio di eventuali script e files di
  configurazione

Gli archivi hanno estensione `.rpm`. Il package manager inoltre ha una lista delle dipendenze
installate sul sistema e possiamo fare query contro questo database locale.

## Debian Package Manager (DPKG & APT)

`DPKG` è di basso livello, esattamente come RPM e non gestisce dipendenze transitive. Per
questo motivo si usano package manager di più alto livello, in questo caso `APT`
(advanced package manager).

APT si basa su software repositories (come YUM) che contengono i package da installare. I
repositories sono definiti nel file `/etc/apt/sources.list`, mentre esiste un index locale
dei package disponibili nei repositories tipicamente in `/var/lib/apt/lists/`.

```shell
# download informazioni sui package da tutti i repository configurati ed 
# aggiornamento dell’index dei package
$ apt update

# edita manualmente i source repository presenti in 
# /etc/apt/sources.list (si può fare manualmente)
$ apt edit-sources	

# installa upgrade di tutti i package del sistema, dai repository configurati, 
# in base alle versioni disponibili listate nell’index locale
$ apt upgrade

# installa un package specifico
$ apt install <pkg>

# rimuove package
$ apt remove <pkg>

# cerca package in repository
$ apt search <pkg>

# lista package disponibili
$ apt list | grep <pkg>
```
