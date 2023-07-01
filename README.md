## Init Scripts

Variants of a script for initialzing a VM runnig Debian 11 (Bullseye) or Ubuntu
22.04. These are meant to be used after the host boots the first time, before
Ansible or a similar tool takes over.

These scripts will:

- Create an admin account with sudo access
- Disable root logins
- Disable SSH passwords
- Configure SSH keys to be read from `/etc/ssh/authorized_keys/$USER`
- Configure WireGuard (generate keys, set port number, configure the first peer)
- On Linode, configures `ufw` to block SSH except over WireGuard

Currently there are published scripts for AWS and Linode.

This automates the steps from [this guide](https://pboyd.io/posts/securing-a-linux-vm/).

### Linode

The Linode script can be imported as a StackScript (or use [this
one](https://cloud.linode.com/stackscripts/946556)).

The WireGuard peer information will be written to `/etc/issue`, so you can grab
the public key and port number from the web console. You may need to wait for
the console to refresh before it appears (reboot it if you're impatient).

This version of the script enables `ufw` to restrict SSH to the WireGuard
interface. If you use Linode's firewall you might prefer to remove that
behavior.

### AWS

To use the AWS scripts, modify the variables at the beginning as supply it as user data.

The WireGuard peer information will be written to the system log (Actions ->
Monitoring -> Get system log). The config will need the host's public IP filled
in.

The AWS scripts do not configure `ufw`. You will need to open the WireGuard
port in the AWS firewall (remember it's UDP), and also block public SSH.
