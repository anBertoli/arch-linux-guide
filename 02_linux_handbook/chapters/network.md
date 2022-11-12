# 🌐Network

## Switching & routing

Uno switch connette dei sottoreti di livello 2, sottoreti su mezzi fisici diversi che possono
appunto essere connesse tramite switch (o bridge). Più reti di livello 2 sono raggruppate in
un unica rete di livello 3 (IP). Le reti di livello 3 hanno quindi IP di rete diverso e 
sono collegate tramite routers.

Gli switch permettono la comunicazione fra host solo all’interno dello stesso network, 
mentre la comunicazione fra reti diverse passa tramite router. I router hanno più 
interfacce ognuna collegata ad un network IP diverso ed ognuna con il proprio indirizzo 
IP compreso nel network a cui si affaccia. I router contengono regole di routing per 
inoltrare il traffico da una data interfaccia verso un’altra interfaccia, in base all’IP 
di destinazione.

<img src="../../02_linux_handbook/assets/net-2.png" width="1200"/>

Le macchine Linux astraggono il link fisico (es. collegamento con switch) come `interfacce`
Linux. Gli host possiedono anche una `routing table`, che controlla dove vengono inoltrati
i pacchetti in uscita in base alla destinazione. Ad esmepio, se la destinazione è un host 
in una delle reti IP su cui l'host ha un'interfaccia, la routing table specifica che quel 
pacchetto debba essere inoltrato sull'interfaccia collegata a tale rete. Gli host sono inoltre 
impostati per avere un `default gateway`. Si tratta dell'IP "di default" a cui viene mandato
il traffico quando la routing table non ha nessun match per l'IP del destinatario .

Il comando **`ip`** viene utilizzato per gestire le interfacce di rete Linux.

```shell
# modifica o lista le interfacce dell’host
$ ip link
```

Per modificare gli IP assegnati alle interfacce si usa `ip addr <command>`. Ad esempio è 
possibile assegnare ad una interfaccia l’IP fornito (deve essere nel network range indicato),
in modod che l'host possa comunicare all'interno del network.

```shell
# assegna IP ad una interfaccia
$ ip addr add <ip>/<netmask> dev <interfaccia>
```

Con `ip route` è possibile gestire la routing table e le sue entries.
```shell
# mostra la routing table dell'host
$ ip route

# configura una route nella routing table 
# (ip-gateway is typically the router)
$ ip route add  <net_ip>/<net_mask> via <ip-gateway>

# configura il default gateway
$ ip route add default via <ip-default-gateway>
# equivalente a 
$ ip route add 0.0.0.0 via <ip-default-gateway>
```

Le modifiche fatte alle interfacce o alla tabella di routing sono temporanee, a meno che non
venga modificato il file di configurazione `/etc/network/interfaces`.

## Diagnostics

Il comando **`ping`** manda un pacchetto ICMP ad un dato IP e si aspetta una risposta, 
monitorando anche diverse metriche. Usato tipicamente per troubleshooting e per verificare la 
connettività (routing, interfaces up, etc).

Il comando **`traceroute`** segue il percorso di un pacchetto dalla sua sorgente fino a
destinazione, riportando problemi e metriche. Permette di verificare problemi di routing,
colli di bottiglia ed altro.

Possible troubleshooting flow:
- verificare interfacce della macchina da cui facciamo il test o da cui si manifesta il 
  problema
- verificare IP ed interfaccie degli host destinatari
- verificare la risoluzione corretta dell'eventuale nome di dominio (`dig`)
- verifica connettività del newtork (`ping`), in caso si mancata connettività `traceroute` 
  può veririfcare dove l’invio dei messaggi si ferma e da li è possibile fare ulteriori indagini
- controllare processi che dovrebbero essere in ascolto sul server


## DNS

### Configuration

Il file `/etc/hosts` è una lista locale di associazioni nomi -> ip. Il file viene spesso
consultato prima dei server di DNS per risolvere un dominio, a meno che la macchina non
sia impostata diversamente. Molti tool adottano questo metodo fra cui curl, ssh, etc.

Gestire manualmente il file `/etc/hosts` per reti grandi e/o mutevoli è scomodo ed error
prone, si preferisce quindi impostare l'utilizzo diretto di un server DNS da parte della
macchine. Per puntare gli host verso il corretto server DNS si modifica il file
`/etc/resolv.conf`, indicando l’ip del nameserver. Il file `/etc/hosts` è solitamente ancora
usato con priorità maggiore (di default, ma dipende ta tool a tool). La priorità è
modificabile editando il file `/etc/nssswitch.conf`.

Riassumendo:

- `/etc/hosts`: file con nomi di dominio e relativo ip consultato da vari comandi e tools
  per tentare di risolvere un nome di dominio
- `/etc/resolv.conf`: lista di nameserver consultabili dall macchina
- `/etc/nssswitch.conf`: elenca la priorità fra la consultazione di _/etc/hosts_ e il
  nameserver impostato in _/etc/resolv.conf_

```shell
$ cat /etc/hosts

# mappings from names to ip
127.0.0.1	localhost
::1         localhost
10.2.4.128  database db
```

```shell
$ /etc/resolv.conf

# list of nameserver
search example.com local.test
nameserver 10.0.0.17
nameserver 10.1.0.12
nameserver 10.16.0.7
```

```shell
$ /etc/nssswitch.conf

# priority for host resolution, ignore other rows
hosts:          files dns
```

### Resolution process

Come già indicato il file `/etc/hosts` può essere usato dalle macchine Linux per la risoluzione
di nomi, con più o meno priorità rispetto ai nameservers. Nel caso di utilizzo di nameservers
tipicamente vien utilizzato un nameserver locale.

Il server DNS che viene usato ha tipicamente una lista configurata di nomi, che possono 
essere quindi risolti su richiesta dei clients. Se richiediamo la risoluzione di un nome
non presente nel database del nameserver possono accadere una delle due segeunti cose:
- il DNS server è anche un resolver, per cui autonomamente si occuperà di risolvere il nome
  ricorsivamente attraverso il sistema DNS pubblico. Il DNS server deve essere impostato per
  contattare il giusto nameserver esterno
- i client sono configurati per avere un secondo nameserver (es. 8.8.8.8) da contattare  nel
  caso il primo non abbia la risposta cercata (è possibile specificare più di un DNS server in
  `/etc/resolv.conf`)

Il DNS server locale ha di solito precedenza su DNS server pubblici.

Nel primo caso (nameserver locale che è anche resolver) una tipica richiesta ha questo
flow: il client contatta il server DNS locale, se il server non ha una risposta esso effettua
una risoluzione di tipo ricorsiva attraverso il DNS pubblico di internet a partire dai root
nameservers. Infine si giunge al nameserver autoritativo per il nome cercato. Le risposte
sono cachate anche su più livelli (TTL dei records DNS).

I comandi **`dig`** e **`nslookup`** fanno risoluzione di nomi (senza considerare il file
`/etc/hosts`).

```shell
# resolution of google.com
$ dig google.com

# resolve google.com without retries, asking 
# to the nameserver at 8.8.8.8 port 53
$ dig +retry=0 -p 53 @8.8.8.8 google.com

# resolve google.com without retries, asking 
# dig to perform and show the entire recursion
# from the root servers
$ dig +retry=0 +trace +recurse www.google.com 
```
