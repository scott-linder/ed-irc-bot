#!/bin/bash

SERVER=localhost
PORT=6667
CHAN=ed
NICK=ed

out() {
    echo $@ >>bot.out
}

msg() {
    out "PRIVMSG #$CHAN :$@"
}

# init
echo "" >bot.in
echo "" >bot.out
[ -p ed.in ] || mkfifo ed.in

# keep ed running async
while true; do
    tail -f ed.in | red 2>&1 | while read output; do
        msg $output
    done
    msg "session closed; restarting..."
done & 

# talk to the irc server and pass things to ed
out "NICK $NICK"
out "USER $NICK $SERVER $SERVER $NICK"
out "JOIN #$CHAN"
tail -f bot.out | telnet $SERVER $PORT | tee bot.in | while read input; do
    case $input in
        PING*)
            out $(echo $input | sed 's/I/O/')
            ;;
        *PRIVMSG*)
            body=$(echo $input | sed 's/.*PRIVMSG.*:\(.*\)/\1/')
            echo $body >ed.in
            ;;
    esac
done
