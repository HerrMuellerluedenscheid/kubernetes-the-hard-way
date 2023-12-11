hcloud network create --name kubernetes-the-hard-way --ip-range 10.240.0.0/24

hcloud network add-subnet kubernetes-the-hard-way \
  --network-zone eu-central \
  --ip-range 10.240.0.0/24 \
  --type server

hcloud firewall create --name kubernetes-the-hard-way

hcloud firewall add-rule kubernetes-the-hard-way --protocol icmp --source-ips 0.0.0.0/0 --direction in
hcloud firewall add-rule kubernetes-the-hard-way --protocol tcp --port 22 --source-ips 0.0.0.0/0 --direction in
hcloud firewall add-rule kubernetes-the-hard-way --protocol tcp --port 6443 --source-ips 0.0.0.0/0 --direction in

hcloud firewall describe kubernetes-the-hard-way

echo "Create 3 controller nodes"
for i in 0 1 2; do
  hcloud server create --firewall kubernetes-the-hard-way --name controller-${i} --image ubuntu-20.04 --type cpx11 --network kubernetes-the-hard-way --label tag=controller-${i} --label role=controller --ssh-key kubernetes-the-hard-way
done

echo "Create 3 worker nodes"
for i in 0 1 2; do
  hcloud server create --firewall kubernetes-the-hard-way --name worker-${i} --image ubuntu-20.04 --type cpx11 --network kubernetes-the-hard-way --label tag=worker-${i} --ssh-key kubernetes-the-hard-way
done

# give the ssh servers some time to boot
sleep 10
## Setting environment variables for the next steps
for i in 0 1 2; do
  export TMP_IP=$(hcloud server list --selector "tag=worker-${i}" -o columns=ipv4 -o noheader)
  echo "Setting environment variables for worker-${i} with IP ${TMP_IP}"
  ssh -i $HOME/.ssh/hetzner_cloud_ed25519 root@${TMP_IP} -o StrictHostKeyChecking=accept-new -n "echo \"POD_CIDR=10.200.${i}.0/24\" >> /etc/environment"
done

hcloud server list

echo "Create a load balancer"
hcloud load-balancer create --label tag=kubernetes-the-hard-way --type lb11 --name kubernetes-the-hard-way --network-zone kubernetes-the-hard-way --network-zone eu-central

# forward all traffic comming in on port 6443 to the controllers
hcloud load-balancer add-service kubernetes-the-hard-way  --destination-port 6443 --listen-port 6443 --protocol tcp

# connect load balancers to controllers
hcloud load-balancer add-target --label-selector "role=controller" kubernetes-the-hard-way
