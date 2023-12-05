# Prerequisites

## Hetzner

While the original version if this tutorial leverages the [Google Cloud Platform](https://cloud.google.com/)  this fork uses the [Hetzner](http://hetzner.com/) to streamline provisioning of the compute infrastructure required to bootstrap a Kubernetes cluster from the ground up.

[Estimated cost on Google Cloud Platform](https://cloud.google.com/products/calculator#id=873932bc-0840-4176-b0fa-a8cfd4ca61ae) to run this tutorial: **$5.50 per day**.

[Estimated cost on Hetzner](https://www.hetzner.com/cloud) to run this tutorial: **$1.25 per day**. We will spawn in total 6 CX21 instances which are 5.77 EUR ($6.25) per month each.


## Hetzner Cloud Platform SDK

### Install the Hetzner Cloud SDK

Follow the Hetzner [documentation](https://github.com/hetznercloud/cli) to install and configure the `hcloud` command line utility.
It's also helpful to checkout their [user guide](https://community.hetzner.com/tutorials/howto-hcloud-cli).

Verify the Hetzner Cloud SDK version is `v1.38.2` or higher:

```
hcloud version
```

You need to create a project to be able to create servers.

## Running Commands in Parallel with tmux

[tmux](https://github.com/tmux/tmux/wiki) can be used to run commands on multiple compute instances at the same time. Labs in this tutorial may require running the same commands across multiple compute instances, in those cases consider using tmux and splitting a window into multiple panes with synchronize-panes enabled to speed up the provisioning process.

> The use of tmux is optional and not required to complete this tutorial.

![tmux screenshot](images/tmux-screenshot.png)

> Enable synchronize-panes by pressing `ctrl+b` followed by `shift+:`. Next type `set synchronize-panes on` at the prompt. To disable synchronization: `set synchronize-panes off`.

Next: [Installing the Client Tools](02-client-tools.md)
