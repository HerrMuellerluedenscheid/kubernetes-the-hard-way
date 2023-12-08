for i in 0 1 2; do
  export WORKER${i}=$(hcloud server list --selector "tag=worker-${i}" -o columns=ipv4 -o noheader)
done
for i in 0 1 2; do
  export CONTROLLER${i}=$(hcloud server list --selector "tag=controller-${i}" -o columns=ipv4 -o noheader)
done
echo $CONTROLLER0 $CONTROLLER1 $CONTROLLER2 $WORKER0 $WORKER1 $WORKER2

