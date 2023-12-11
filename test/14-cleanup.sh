for i in 0 1 2; do
  hcloud server delete controller-${i}
  hcloud server delete worker-${i}
done
{
  hcloud load-balancer delete kubernetes-the-hard-way
  hcloud network delete kubernetes-the-hard-way
  hcloud firewall delete kubernetes-the-hard-way
}
