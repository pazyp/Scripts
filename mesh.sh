#!/bin/ksh

line='---------------------------------------------'
pids=$(/usr/bin/ps -ef | sed 1d | awk '{print $2}')

if [ $# -eq 0 ]; then
   read ans?"Enter port you would like to know pid for: "
else
   ans=$1
fi

for f in $pids
do
   /usr/proc/bin/pfiles $f 2>/dev/null | /usr/xpg4/bin/grep -q "port: $ans"
   if [ $? -eq 0 ]; then
      echo $line
      echo "Port: $ans is being used by PID:\c"
      /usr/bin/ps -ef -o pid -o args | egrep -v "grep|pfiles" | grep $f
   fi
done
exit 0
