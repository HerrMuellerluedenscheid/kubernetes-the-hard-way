# Cleaning Up

In this lab you will delete the compute resources created during this tutorial.

## Compute Instances

Delete the controller and worker compute instances:

```shell
for i in 0 1 2; do
  hcloud server delete controller-${i}
  hcloud server delete worker-${i}
done
```

## Networking

Delete the external load balancer network resources:

```shell
{
  hcloud load-balancer delete kubernetes-the-hard-way
  hcloud network delete kubernetes-the-hard-way
}
```
