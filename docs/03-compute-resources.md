# Provisioning Compute Resources

Kubernetes requires a set of machines to host the Kubernetes control plane and the worker nodes where containers are ultimately run. In this lab you will provision the compute resources required for running a secure and highly available Kubernetes cluster across a single [compute zone](https://cloud.google.com/compute/docs/regions-zones/regions-zones).

> Ensure a default compute zone and region have been set as described in the [Prerequisites](01-prerequisites.md#set-a-default-compute-region-and-zone) lab.

## Networking

The Kubernetes [networking model](https://kubernetes.io/docs/concepts/cluster-administration/networking/#kubernetes-model) assumes a flat network in which containers and nodes can communicate with each other. In cases where this is not desired [network policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) can limit how groups of containers are allowed to communicate with each other and external network endpoints.

> Setting up network policies is out of scope for this tutorial.

### Virtual Private Cloud Network

In this section a dedicated [Virtual Private Cloud](https://cloud.google.com/compute/docs/networks-and-firewalls#networks) (VPC) network will be setup to host the Kubernetes cluster.

Create the `kubernetes-the-hard-way` custom VPC network:

```shell
hcloud network create --name kubernetes-the-hard-way --ip-range 10.240.0.0/24
```

A [subnet](https://cloud.google.com/compute/docs/vpc/#vpc_networks_and_subnets) must be provisioned with an IP address range large enough to assign a private IP address to each node in the Kubernetes cluster.

Create the `kubernetes` subnet in the `kubernetes-the-hard-way` VPC network:

```shell
hcloud network add-subnet kubernetes-the-hard-way \
  --network-zone eu-central \
  --ip-range 10.240.0.0/24 \
  --type server
```

> The `10.240.0.0/24` IP address range can host up to 254 compute instances.

### Firewall Rules

Create a firewall
```shell
hcloud firewall create --name kubernetes-the-hard-way
```

Create a firewall rule that allows external SSH, ICMP, and HTTPS:

```shell
hcloud firewall add-rule kubernetes-the-hard-way --protocol icmp --source-ips 0.0.0.0/0 --direction in
hcloud firewall add-rule kubernetes-the-hard-way --protocol tcp --port 22 --source-ips 0.0.0.0/0 --direction in
hcloud firewall add-rule kubernetes-the-hard-way --protocol tcp --port 6443 --source-ips 0.0.0.0/0 --direction in
```

> An [external load balancer](https://cloud.google.com/compute/docs/load-balancing/network/) will be used to expose the Kubernetes API Servers to remote clients.

List the firewall rules in the `kubernetes-the-hard-way` VPC network:

```shell
hcloud firewall describe kubernetes-the-hard-way
```

> output

```
ID:             1100929
Name:           kubernetes-the-hard-way
Created:        Thu Oct 26 11:38:13 CEST 2023 (20 seconds ago)
Labels:
  No labels
Rules:
  - Direction:          in
    Protocol:           icmp
    Source IPs:
                        0.0.0.0/0
  - Direction:          in
    Protocol:           tcp
    Port:               22
    Source IPs:
                        0.0.0.0/0
  - Direction:          in
    Protocol:           tcp
    Port:               6443
    Source IPs:
                        0.0.0.0/0
Applied To:
  Not applied
```

## Configuring SSH Access

SSH will be used to configure the controller and worker instances. When connecting to compute instances for the first time SSH keys will be generated for you and stored in the project or instance metadata as described in the [connecting to instances](https://cloud.google.com/compute/docs/instances/connecting-to-instance) documentation.

Generate a new SSH key-pair without setting the password:
```shell
ssh-keygen -t ed25519 -C "kubernetes-the-hard-way" -N "" -f $HOME/.ssh/hetzner_cloud_ed25519
```

Upload the **public** key to the Hetzner Cloud:

```shell
hcloud ssh-key create --name kubernetes-the-hard-way --public-key-from-file $HOME/.ssh/hetzner_cloud_ed25519.pub
```

### Kubernetes Public IP Address

NOTE: We assign the public address of the load balancer later. Thus, we do not need this step.

## Compute Instances

The compute instances in this lab will be provisioned using [Ubuntu Server](https://www.ubuntu.com/server) 20.04, which has good support for the [containerd container runtime](https://github.com/containerd/containerd). Each compute instance will be provisioned with a fixed private IP address to simplify the Kubernetes bootstrapping process.

### Kubernetes Controllers

Create three compute instances which will host the Kubernetes control plane:

```shell
for i in 0 1 2; do
  hcloud server create --firewall kubernetes-the-hard-way --name controller-${i} --image ubuntu-22.04 --type cpx11 --network kubernetes-the-hard-way --label tag=controller-${i} --label role=controller --ssh-key kubernetes-the-hard-way
done
```

For convenience assign environment variables for each controller instance (`CONTROLLER0`, `CONTROLLER1`, etc):

```shell
for i in 0 1 2; do
  export CONTROLLER${i}=$(hcloud server list --selector "tag=controller-${i}" -o columns=ipv4 -o noheader)
done
```

### Kubernetes Workers

Each worker instance requires a pod subnet allocation from the Kubernetes cluster CIDR range. The pod subnet allocation will be used to configure container networking in a later exercise. The `pod-cidr` instance metadata will be used to expose pod subnet allocations to compute instances at runtime.

> The Kubernetes cluster CIDR range is defined by the Controller Manager's `--cluster-cidr` flag. In this tutorial the cluster CIDR range will be set to `10.200.0.0/16`, which supports 254 subnets.

Create three compute instances which will host the Kubernetes worker nodes:

```shell
for i in 0 1 2; do
  hcloud server create --firewall kubernetes-the-hard-way --name worker-${i} --image ubuntu-22.04 --type cpx11 --network kubernetes-the-hard-way --label tag=worker-${i} --ssh-key kubernetes-the-hard-way
done
```

For convenience assign environment variables for each worker instance (`WORKER0`, `WORKER1`, etc):

```shell
for i in 0 1 2; do
  export WORKER${i}=$(hcloud server list --selector "tag=worker-${i}" -o columns=ipv4 -o noheader)
done
```

Confirm that the environment variables were created. This should list 6 IPv4 addresses:
```shell
echo $CONTROLLER0 $CONTROLLER1 $CONTROLLER2 $WORKER0 $WORKER1 $WORKER2
```


### Verification

List the compute instances in your default compute zone:

```bash
hcloud server list
```

> output

```
ID         NAME           STATUS    IPV4              IPV6                      PRIVATE NET                            DATACENTER   AGE
38250477   controller-0   running   XX.XXX.XX.XX      2a01:4f9:c012:9b39::/64   10.240.0.2 (kubernetes-the-hard-way)   hel1-dc2     2m
38250489   controller-1   running   XX.XXX.XX.XX      2a01:4f9:c012:540d::/64   10.240.0.3 (kubernetes-the-hard-way)   hel1-dc2     1m
38250502   controller-2   running   XX.XXX.XX.XX      2a01:4f9:c010:ac33::/64   10.240.0.4 (kubernetes-the-hard-way)   hel1-dc2     1m
38250524   worker-0       running   XX.XXX.XX.XX      2a01:4f9:c012:92bd::/64   10.240.0.5 (kubernetes-the-hard-way)   hel1-dc2     1m
38250539   worker-1       running   XX.XXX.XX.XX      2a01:4f9:c010:a664::/64   10.240.0.6 (kubernetes-the-hard-way)   hel1-dc2     45s
38250543   worker-2       running   XX.XXX.XX.XX      2a01:4f9:c012:7e4a::/64   10.240.0.7 (kubernetes-the-hard-way)   hel1-dc2     28s
```

Test SSH access to the `controller-0` compute instances:

```shell
ssh -i $HOME/.ssh/hetzner_cloud_ed25519 root@${CONTROLLER0}
```

If this is your first time connecting to a compute instance SSH keys will be generated for you. Enter a passphrase at the prompt to continue:

```
❯ ssh -i $HOME/.ssh/hetzner_cloud_ed25519 root@${WORKER0}

The authenticity of host 'XX.XX.XXX.XXX (XX.XX.XXX.XXX)' can't be established.
ED25519 key fingerprint is SHA256:ijdfoiDoisDfj12309sd0f9u123oijsdf.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? 
```

Reply with `yes` to continue connecting.

Type `exit` at the prompt to exit the `controller-0` compute instance:

```
$USER@controller-0:~$ exit
```
> output

```
logout
Connection to XX.XX.XXX.XXX closed
```

Next: [Provisioning a CA and Generating TLS Certificates](04-certificate-authority.md)

## Create Load Balancer

```shell
hcloud load-balancer create --label tag=kubernetes-the-hard-way --type lb11 --name kubernetes-the-hard-way --network-zone kubernetes-the-hard-way --network-zone eu-central

# forward all traffic comming in on port 6443 to the controllers
hcloud load-balancer add-service kubernetes-the-hard-way  --destination-port 6443 --listen-port 6443 --protocol tcp

# connect load balancers to controllers
hcloud load-balancer add-target --label-selector "role=controller" kubernetes-the-hard-way
```

If you check the hetzner console you will see that this load balancer has and will have an unhealthy state for the next steps. This will only change once all services are bootstrapped.
