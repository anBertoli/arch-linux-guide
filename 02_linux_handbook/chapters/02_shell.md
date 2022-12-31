# 🕹️ Shell

Si usa la shell come uno specifico utente del sistema. I comandi dati alla shell si
dividono in due categorie. Quelli interni sono parte della shell (del binario shell) e sono
ad esempio _echo_, _cd_, _pwd_, etc. Quelli esterni sono degli eseguibili a sé (es. _mv_, _cp_,
_uptime_) e si trovano in una cartella del sistema listata nella variabile d'ambiente `PATH`.
E’ possibile distinguerli usando il comando `type <command>`.

```shell
$ type mv       # mv is /bin/mv
$ type echo     # echo is a shell builtin

$ echo $SHELL   # /bin/bash
```

Esistono diversi tipi di shell, la env var `SHELL` mostra la shell di default sul sistema. Per
settare una shell di default diversa è possibile usare `chsh`.

# Bash

Bash (_bourne again shell_) è fra le shell più utilizzate. Fra le altre cose, offre auto
completamento e alias.

Bash supporta l’uso di variabili di shell e variabili d’ambiente. Le prime sono legate solo
alla corrente sessione, mentre le seconde sono anche passate ai processi figli della shell
corrente (`env` per printare var d’ambiente). Il comando `export` crea una nuova env var. E'
possibile farla permanere aggiugnengo l'export in `~/.profile` e `~/.bash_profile`.

La env `PATH` controlla i posti dove i binari dei comandi vengono cercati per essere eseguiti
quando si invoca un dato comando.

```shell
# set and use shell variable
$ MY_VAR=67		            
$ echo ${MY_VAR}		    

# print all env vars, then export a new one
$ env
$ export MY_ENV=67

# persist new env var
$ echo 'export MY_ENV=67' >> ~/.profile
$ echo 'export MY_ENV=67' >> ~/.bash_profile
```

## IO redirection

### With files

Ogni processo viene lanciato con tre file descriptor aperti di default:

- `STDIN`: standard input, il processo accetta input attraverso questo fd
- `STDOUT`: standard output, di default il processo scrive su questo fd
- `STDERR`: standard error, fd usato per scrivere errori

E’ possibile redirezionare questi stream verso altre destinazioni. La destinazione può
essere un altro processo, una pipe oppure un file/device.

- `>`, `1>` redirect di standard output, sovrascrivendo contenuto
- `>>`, `1>>` redirect di standard output, append al contenuto
- `2>` redirect di standard error, sovrascrivendo contenuto
- `2>>` redirect di standard error, append al contenuto
- `<` read standard input from source
- `1>&2` redirect standard output to standard error
- `2>&1` redirect standard error to standard output

```shell
# send STDOUT of ls command to one file, overwriting it
# send STDERR to another file, appending this new content
$ ls -alh > listing.txt 2>> list-err.txt

# start a specific program, reads STDIN from json file
# and discard errors sent to STDERR
$ my-command < input.json 2> /dev/null
```

### Between processes

E’ possibile connettere lo STDOUT di un processo allo STDIN di un secondo comando tramite le
`shell pipes` (simbolo `|`). Il comando `tee` di seguito ha la funzione di splittare l’output:
il comando scrive nella destinazione specificata, ma anche sullo STDOUT.

```shell
# list files in current directory, output is the
# input of wc, which counts the number of lines
$ ls -alh | wc -l

# list files in current directory, output is BOTH
# send to next command and written in a file
$ ls -alh | tee listing.txt | wc -l
```

In alternativa è possibile catturare tutto l'ouput di un comando ed utilizzarlo in un altro
comando
usando la `command sobstituion` eseguita con la sintassi `$(<command>)`.

```shell
$ ls -alh $(cat list_of_dirs.txt)
```

## Bash customization

La prompt di bash può essere customizzata attraverso la env var `PS1`, che è un template del
nostro prompt, personalizzabile attraverso alcuni caratteri speciali. Ad esempio con
`PS1="[\d \w example]$"` il nostro prompt sarà composto da, es. [Tue May 26 /etc/nginx]$.
La modifica del prompt per essere permanentemente deve essere salvato in `~/.profile` e
`~/.bash_profile`. Di seguito una lista non esaustiva di opzioni.

- `\a` : an ASCII bell character (07)
- `\d` : the date in "Weekday Month Date" format (e.g., "Tue May 26")
- `\e` : an ASCII escape character (033)
- `\h` : the hostname up to the first '.'
- `\H` : the hostname
- `\j` : the number of jobs currently managed by the shell
- `\n` : newline
- `\r` : carriage return
- `\s` : the name of the shell
- `\t` : the current time in 24-hour HH:MM:SS format
- `\T` : the current time in 12-hour HH:MM:SS format
- `\@ `: the current time in 12-hour am/pm format
- `\A` : the current time in 24-hour HH:MM format
- `\u` : the username of the current user
- `\v` : the version of bash (e.g., 2.00)
- `\V` : the release of bash, version + patch level (e.g., 2.00.0)
- `\w` : the current working directory, with $HOME abbreviated with a tilde
- `\W` : the basename of the current working directory, with $HOME abbreviated with a tilde
- `\! `: the history number of this command
- `\# `: the command number of this command
- `\$` : if the effective UID is 0, a #, otherwise a $
- `\nnn` : the character corresponding to the octal number nnn

For colors: https://misc.flogisoft.com/bash/tip_colors_and_formatting

## Symbols

- `.` directory corrente
- `..` directory superiore
- `~` home directory
- `*` wildcard

- `$0, $1, $n` positional parameters, passed from command line
- `$#` number of command-line arguments
- `$$` pID of the shell itself

- `${VAR}` parameter substitution
- `$VAR` parameter substitution

## Doc & help

Per accedere alle doc di un commando, esistono diversi metodi:

- `whatis <command>`: one line description del comando, spesso poco esplicativa
- `<command> --help/-h`: istruzioni sul comando, often useful enough
- `man <command>`: accedi al manuale del comando, if manuals for the command are installed.
  If a command has different functionalities and/or usage contexts, manuals report those in
  different sections (1, 2, 3, etc.). Single sections can be accessed via `man <1|2|..>
  <command>`
- `apropos <some-words>`: fa query sulle short description di tutte le man pages, e ritorna il
  comando che matcha, utile per cercare un comando. apropos relies on a local db, which can
  be created/update with `mandb`

## Regex

Le regex vengono usate in molti ambiti come _grep_, _sed_, linguaggi di programmazione, e
molti altri (https://regexr.com per maggiori info). Esistono _basic_ and _extended_ regex.
Nell'ambito del comando _grep_, le extended regex vanno usate con `egrep` oppure `grep -E`,
le basic con _grep_. Le basic chiedono di escapare certi special symbols (con \, e.g. \$),
sono perciò tricky.

- `^` (carat): matches a term if the term appears at the beginning of a paragraph or a line,
  e.g. _^apple_ matches lines che iniziano con apple
- `$` (dollar sign): matches a term if the term appears at the end of a paragraph or a line.
  For example _bye$_ matches a paragraph or a line ending with bye
- `.` (period): matches a single instance of any single character, except the end of a line.
  For example, _sh.rt_ matches _shirt_, _short_ and any character between sh and rt
- `*` (asterisk): matches 0 or more instances of any character. For example, _co*l_ regular
  expression matches _cl_, _col_, _cool_, _cool_, _coool_, etc.
- `+` (plus): matches 1 or more instances of any character. For example, _co+l_ regular
  expression matches _col_, _cool_, _cool_, _coool_, etc.
- `?`: makes the previous element optional, e.g.: _disabled?_ matches _disable_ and
  _disabled_


- `element{min,max}`: previous elements can exists “this many” times, e.g.:
    - _grep -E 10{,3}_ matcha 1 seguito da al massimo 3 volte zero
    - _grep -E 10{3,}_ matcha 1 seguito da almeno 3 volte zero
    - _grep -E 10{3}_ matcha 1 seguito da esattamente 3 volte zero
    - _grep -E 10{3,5}_ matcha 1 seguito da zero ripetuto da 3 a 5 volte
- `elem1|elem2`: matches uno o l’altra expression, e.g. _enabled?|disabled?’ matcha
  _enable/enabled/disable/disabled_


- `[charset]` matcha range/set di caratteri, matches a single instance of any single character
  from within the bracketed list
    - _[a-z]_: matches letters
    - _[0-9]_: matches digits
    - _[abz1234]_: matches set indicato
    - _c[au]t_: matches _cat_ e _cut_
    - _/dev/[a-z]*[0-9]?_: matches tutti i file in dev che hanno nome che inizia per lettere
      ed opzionalmente finiscono con una sola digit
- `[^charset]`: negated ranges, matches any letter not in the indicated set, e.g. _http[^s]_
  matcha _httpX_ dove X non è la lettera _s_


- `()` subexpressions: groups one or more regular expressions. E.g.: _codexpedia\.
  (com|net|org)_ matches codexpedia.com, codexpedia.net, and codexpedia.org
    - _/dev/(([a-z]|[A-Z])*[0-9]?)+_ match file in dev che hanno nome che ripete il pattern
      seguente almeno una volta: zero o più lettere upper o lower seguite da zero o più digits

