# ⚙️ Processes

I processi vengono lanciati e continuano finche finiscono o finchè non vengono chiusi
dall’esterno. Esistono diversi comandi per interrogare il sistema riguardo allo stato
dei processi in corso.

Con 🛠`ps` si ottiene lo snapshot dei processi, le colonne sono:

- **USER**: which user launched the process
- **PID**: the process ID
- **%CPU**: tempo di esecuzione sulla CPU (>100% per multi CPU)
- **%MEM**: consumo di RAM del processo
- **START**: timestamp di start del processo
- **TIME**: CPU time, tempo di effettivo run del processo (non sleep o altro), ad esempio per
  avere 5 secondi segnati qui significa (fra le varie opzioni) che 1 CPU è stata usata al 100%
  per un secondo oppure 2 CPU al 25% per 2 secondi
- **COMMAND**: comando che ha lanciato il processo, se fra _[ ]_ sono processi kernel space
- **NICENESS** (NI): -20 to +19: lower means more priority, ereditato da processo padre a
  figlio

```shell
# show processes with niceness and parent-child relations
$ ps flaux 
# show processes with given PID
$ ps -u <pid>
# show processes of given user
$ ps -U <user>
```

A richer alternative is 🛠️`top/htop`. It shows the processes of the system in real time, with
nice pagination and other customization options.

La niceness di un processo può essere modificata con i seguenti comandi:

```shell
# lancia un processo con una data niceness
[sudo] nice -n <num> /path/to/executable
# modifica la niceness di un processo già lanciato 
[sudo] renice <num> <PID>
```

## Signals

Signals are high priority messages sent to processes, i processi rispondono a quasi tutti i
segnali solo se programmati per farlo (ma _SIGSTOP/SIGCONT_, _SIGKILL_ non sono ignorabili).
Il comando 🛠`kill` è usato per gestire l'invio di signals.

Per un lista dei segnali disponibili: `kill -L`.

Per mandare signals è necessario indicare il tipo di segnale (numericamente o come stringa).
Se non si specifica il segnale quello di default è _SIGTERM_:

```shell
$ kill -SIGHUP <PID>
$ kill -HUP <PID>
$ kill -9 <PID>
```

Per quanto rigaurda i permessi, solo root/sudoers possono mandare segnali ad ogni processo,
mentre uno user normale può mandare signals solo ai suoi processi.

## Processes in foreground/background

Un gruppo di processi può essere gestito da una shell/tty, possiamo mettere in background
i processi e rimetterli in foreground.

Per lanciare un processo e metterlo immediatamente in background è possibile usare `&`. Se
un processo sta già correndo e possibile stopparlo con CTRL+Z, il processo viene messo in
background ma anche si stoppa.

```shell
$ <command> &
```

Per la gestione dei processi, il comando `jobs` mostra processi in background (con relativo
job number assegnato), mentre `fg` e `bg` permettono di spostare i jobs da foreground a
background e viceversa.

```shell
# show processes/jobs attached to this shell
$ jobs

$ fg <job_num>    # bring stopped process back to foreground
$ bg <job_num>    # resume process in background
```

## Misc

```shell
$ lsof -p <PID>           # mostra tutti open files and directories per il processo
$ lsof <path/to/file>     # mostra tutti i processi che hanno aperto il file

$ df -h 	              # show storage spaces
$ du -sh <dir>            # show disk space usato dalla directory specificata 	

$ free -h                 # mostra utilizzo RAM corrente
$ uptime                  # mostra utilizzo CPU (tempo + load average)

$ [ss/netstat] -ltunp     # mostra processi che sono in ascolto su una porta TCP
  # - l listening
  # - t TCP
  # - u UDP
  # - n use numeric values
  # - p show processes
```