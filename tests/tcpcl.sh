#!/bin/bash

cargo build --bins

if [ $? -ne 0 ]
then
  echo "Build failed."
  exit 1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

OUT_NODE1=$(mktemp /tmp/node1.XXXXXX)
PORT_NODE1=3000
#DB1="-W /tmp/node1 -D sled"
$DIR/../target/debug/dtnd -d -j0 -i0 -w $PORT_NODE1 -C tcp:2342 -e incoming -r epidemic -n node1 -s tcp://127.0.0.1:4223/node2 $DB1 2>&1 &> $OUT_NODE1 &
PID_NODE1=$!
echo node1 pid: $PID_NODE1
echo node1 out: $OUT_NODE1
echo node1 port: $PORT_NODE1


OUT_NODE2=$(mktemp /tmp/node2.XXXXXX)
PORT_NODE2=3001
#DB2="-W /tmp/node2 -D sled"
$DIR/../target/debug/dtnd -d -j0 -i0 -w $PORT_NODE2 -C tcp:4223 -e incoming -r epidemic \
    -n node2 \
    -s tcp://127.0.0.1:2342/node1 \
    -s tcp://127.0.0.1:2432/node3 \
    $DB2 2>&1 &> $OUT_NODE2 &
PID_NODE2=$!
echo node2 pid: $PID_NODE2
echo node2 out: $OUT_NODE2
echo node2 port: $PORT_NODE2

OUT_NODE3=$(mktemp /tmp/node3.XXXXXX)
PORT_NODE3=3002
#DB3="-W /tmp/node3 -D sled"
$DIR/../target/debug/dtnd -d -j0 -i0 -w $PORT_NODE3 -C tcp:2432 -e incoming -r epidemic -n node3 -s tcp://127.0.0.1:4223/node2 $DB3 2>&1 &> $OUT_NODE3 &
PID_NODE3=$!
echo node3 pid: $PID_NODE3
echo node3 out: $OUT_NODE3
echo node3 port: $PORT_NODE3

sleep 1

echo

echo "Sending 'test' to node 3"
echo test | $DIR/../target/debug/dtnsend -r dtn://node3/incoming -p $PORT_NODE1

sleep 1

echo -n "Receiving on node 3: "
$DIR/../target/debug/dtnrecv -v -e incoming -p $PORT_NODE3
echo 

echo "Press any key to stop daemons and clean up logs"
read -n 1
kill $PID_NODE1 $PID_NODE2 $PID_NODE3
rm $OUT_NODE1 $OUT_NODE2 $OUT_NODE3
