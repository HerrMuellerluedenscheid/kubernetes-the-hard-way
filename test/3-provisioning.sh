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

hcloud server list

echo "Create a load balancer"
hcloud load-balancer create --label tag=kubernetes-the-hard-way --type lb11 --name kubernetes-the-hard-way --network-zone kubernetes-the-hard-way --network-zone eu-central

# forward all traffic comming in on port 6443 to the controllers
hcloud load-balancer add-service kubernetes-the-hard-way  --destination-port 6443 --listen-port 6443 --protocol tcp

# connect load balancers to controllers
hcloud load-balancer add-target --label-selector "role=controller" kubernetes-the-hard-way
