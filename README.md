<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
consul-install-windows

- [Frequely used commands](#frequely-used-commands)
- [flag `rejoin_after_leave`](#flag-rejoin_after_leave)
- [Consul webui reports: There are no services to show.](#consul-webui-reports-there-are-no-services-to-show)
  - [solution: re-bootstrap](#solution-re-bootstrap)
- [vault: protect against outages by running multiple Vault servers](#vault-protect-against-outages-by-running-multiple-vault-servers)
  - [vault: `advertise_addr`](#vault-advertise_addr)
  - [vault advertise address](#vault-advertise-address)
- [TODO how to get two consul servers to find each other](#todo-how-to-get-two-consul-servers-to-find-each-other)
  - [getting started workflow1](#getting-started-workflow1)
- [TODO i'm installing symlink to `system32\consul.exe`, is that a bad idea?](#todo-im-installing-symlink-to-system32%5Cconsulexe-is-that-a-bad-idea)
- [Delete c:\ProgramData\consul\datadir on \[re-\]install](#delete-c%5Cprogramdata%5Cconsul%5Cdatadir-on-%5Cre-%5Cinstall)
- [I would like consul to discover all the nodes in my lan, but that doesn't seem possible](#i-would-like-consul-to-discover-all-the-nodes-in-my-lan-but-that-doesnt-seem-possible)
- [Consule webui](#consule-webui)
- [puppet consul module appears to not be supported on windows, but chef: yes](#puppet-consul-module-appears-to-not-be-supported-on-windows-but-chef-yes)
- [using vault with consul as backend](#using-vault-with-consul-as-backend)
- [install](#install)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

Frequely used commands
======================

    powershell -noprofile -executionpolicy unrestricted -command "(new-object System.Net.WebClient).DownloadFile('https://raw.githubusercontent.com/TaylorMonacelli/consul-install-windows/wip/nssminstall.ps1','nssminstall.ps1')"
    powershell -noprofile -executionpolicy unrestricted -file nssminstall.ps1

    powershell -noprofile -executionpolicy unrestricted -command "(new-object System.Net.WebClient).DownloadFile('https://raw.githubusercontent.com/TaylorMonacelli/consul-install-windows/wip/consulinstall.ps1','consulinstall.ps1')"
    powershell -noprofile -executionpolicy unrestricted -file consulinstall.ps1

    net stop consul & consul agent -server -bootstrap-expect 3 -ui-dir C:\ProgramData\consul\www -data-dir C:\ProgramData\consul\data -dc seattle -retry-join 10.0.3.207 -retry-join 10.0.3.94 -retry-join 10.0.2.78

    curl 'http://localhost:8500/v1/kv/foo?dc=seattle'

flag `rejoin_after_leave`
=========================

<https://www.consul.io/docs/agent/options.html#rejoin_after_leave>

After reboot, often consul ends up in a state where it can't elect a
leader given this config:

    {
      "retry_join": ["10.0.2.78", "10.0.3.94", "10.0.3.207"],
      "rejoin_after_leave": true,
      "datacenter": "seattle",
      "ui_dir": "C:/ProgramData/consul/www",
      "data_dir": "C:/ProgramData/consul/data",
      "log_level": "INFO",
      "server": true
    }

I thought `retry_join` would be enough.

Even after

Consul webui reports: There are no services to show.

curl "<http://localhost:8500/v1/kv/foo?dc=seattle>"

    Agent pid 2316
    [Administrator@IFB:~(master)]$ curl "http://localhost:8500/v1/kv/foo?dc=seattle"
    No cluster leader[Administrator@IFB:~(master)]$ consul members
    Node           Address          Status  Type    Build  Protocol  DC
    IFB            10.0.2.78:8301   alive   server  0.5.2  2         seattle
    TAYLORDESKTOP  10.0.3.60:8301   alive   server  0.5.2  2         seattle
    SBXE0ABB74     10.0.3.207:8301  alive   server  0.5.2  2         seattle
    [Administrator@IFB:~(master)]$

Consul webui reports: There are no services to show.
====================================================

curl "<http://localhost:8500/v1/kv/foo?dc=seattle>"

As of commit e4e25f9:

<http://localhost:8500/ui/#/seattle/services> reports:

    there are no services to show

I have 3 machines that correctly see each other after reboot:

    Microsoft Windows [Version 6.1.7601]
    Copyright (c) 2010 Microsoft Corporation.  All rights reserved.

    C:\Users\Administrator>consul members
    Node           Address          Status  Type    Build  Protocol  DC
    TAYLORDESKTOP  10.0.3.60:8301   alive   server  0.5.2  2         seattle
    SBXE0ABB74     10.0.3.207:8301  alive   server  0.5.2  2         seattle
    IFB            10.0.2.78:8301   alive   server  0.5.2  2         seattle

    C:\Users\Administrator>

but:

    [Administrator@taylordesktop:~(master)]$ curl 'http://localhost:8500/v1/kv/foo?dc=seattle'
    No cluster leader
    [Administrator@taylordesktop:~(master)]$

Possible leads:
-   <https://github.com/hashicorp/consul/issues/908>

solution: re-bootstrap
----------------------

From either one of the 3 machines: 10.0.2.78, 10.0.3.207 or 10.0.3.94
re-bootstrap:

    net stop consul & consul agent -server -bootstrap-expect 3 -ui-dir C:\ProgramData\consul\www -data-dir C:\ProgramData\consul\data -dc seattle -retry-join 10.0.3.207 -retry-join 10.0.3.94 -retry-join 10.0.2.78

<https://www.consul.io/docs/guides/bootstrapping.html>

Before a Consul cluster can begin to service requests, a server node
must be elected leader. Thus, the first nodes that are started are
generally the server nodes. Bootstrapping is the process of joining
these initial server nodes into a cluster.

Yeah, I get that, but I already bootstrapped a while back and rebooted a
few times after the bootstrap that succeeded.

How often or what condition caused the in-ability for consul to re-elect
a leader?

vault: protect against outages by running multiple Vault servers
================================================================

to increase scalability of Vault with Consul, you would scale Consul
instead of Vault

So in order to get fault taulerant vault, we need to get fault tolerant
consul if we're using consul as vault's storage backend.

<https://vaultproject.io/docs/concepts/ha.html>

High Availability Mode (HA)

Vault supports multi-server mode for high availability. This mode
protects against outages by running multiple Vault servers. High
availability mode is automatically enabled when using a storage backend
that supports it.

You can tell if a backend supports high availability mode ("HA") by
starting the server and seeing if "(HA available)" is outputted next to
the backend information. If it is, then HA will begin happening
automatically.

To be highly available, Vault elects a leader and does request
forwarding to the leader. Due to this architecture, HA does not enable
increased scalability. In general, the bottleneck of Vault is the
storage backend itself, not Vault core. For example: to increase
scalability of Vault with Consul, you would scale Consul instead of
Vault.

In addition to using a backend that supports HA, you have to configure
Vault with an advertise address. This is the address that Vault
advertises to other Vault servers in the cluster for request forwarding.
By default, Vault will use the first private IP address it finds, but
you can override this to any address you want.

vault: `advertise_addr`
-----------------------

<https://vaultproject.io/docs/config/#advertise_addr>

All backends support the following options:

`advertise_addr` (optional) - For backends that support HA, this is the
address to advertise to other Vault servers in the cluster for request
forwarding. Most HA backends will attempt to determine the advertise
address if not provided.

vault advertise address
-----------------------

-   <https://www.consul.io/docs/agent/options.html#advertise_addr>

<https://github.com/hashicorp/vault/issues/444> <https://goo.gl/bK9yzy>

TODO how to get two consul servers to find each other
=====================================================

Tutorial
-   <https://goo.gl/AkGzw0>
-   <https://www.consul.io/docs/agent/options.html>

Bootstrapping

getting started workflow1
-------------------------

1.  install consul using powershell on 2+ machines with IPs 10.0.2.78,
    10.0.3.94, 10.0.3.207 (see *install*)
2.  run this on one machine:

<!-- -->

    net stop consul
    consul agent -server -bootstrap-expect 3 -ui-dir C:\ProgramData\consul\www -data-dir C:\ProgramData\consul\data -dc seattle -retry-join 10.0.3.207 -retry-join 10.0.3.94 -retry-join 10.0.2.78
    consul members

    # Example config C:\ProgramData\consul\data
    # nssm set Consul AppParameters agent -server -config-file "C:\ProgramData\consul\config\config.hcl"
    {
      "retry_join": ["10.0.2.78", "10.0.3.94", "10.0.3.207"],
      "datacenter": "seattle",
      "ui_dir": "C:/ProgramData/consul/www",
      "data_dir": "C:/ProgramData/consul/data",
      "log_level": "INFO",
      "server": true
    }

TODO i'm installing symlink to `system32\consul.exe`, is that a bad idea?
=========================================================================

I'm installing symlink to `system32\consul.exe`, is that a bad idea?

I want consul.exe in my `%path%`.

Whats the correct practice for getting one binary to run via just
openning cmd.exe? Do you have to add every single binary to the system
path?

I'm aware of shimgen.exe from chocolatey, but whats the recommended way
to enable running c:\ProgramData\consul\consul.exe by openning up
cmd.exe and running consul.

Now, I'm doing this which works:

    mklink $env:windir\system32\consul.exe c:\programdata\consul\consul.exe

but that feels wrong.

Delete c:\ProgramData\consul\datadir on \[re-\]install
======================================================

Getting the nodes to find each other more reliably aft repeated installs
for testing this powershell install script is to first delete the whole
data dir.

    "retry_join": ["10.0.2.78", "10.0.3.94", "10.0.3.207"],

I would like consul to discover all the nodes in my lan, but that doesn't seem possible
=======================================================================================

Armon explains (ammended):

The second issue is cluster membership. Currently, there is no
zero-touch "join" mechanism. Either "consul join" is used, or the
appropriate flags (eg `retry_join`) to the agent to do the same thing on
start. We have ticket \#331 open to support this.

With the -bootstrap-expect and mDNS support (from \#331) you would get
the behavior you are describing. The nodes would start, 3 servers show
up, a leader gets elected and you are off to the races.

Because of that, I'm considering this ticket a dup, and closing. Let me
know if I missed something!
-   <https://github.com/hashicorp/consul/issues/393#issuecomment-58827480>
-   <https://github.com/hashicorp/consul/issues/331>

-   <https://www.consul.io/docs/agent/options.html#_retry_join>
-   <https://github.com/hashicorp/consul/issues/393#issuecomment-60476614>
-   <https://github.com/hashicorp/consul/issues/393#issuecomment-58828824>

Consule webui
=============

Where is it?
-   webui download link is here: <https://www.consul.io/downloads.html>

Does it run on windows?

Yes.

-   <https://www.consul.io/intro/getting-started/ui.html>
-   <https://www.consul.io/docs/agent/options.html#_ui_dir>

<!-- -->

    consul agent -ui-dir C:\ProgramData\consul\www -data-dir C:\ProgramData\consul\data

puppet consul module appears to not be supported on windows, but chef: yes
==========================================================================

Puppet
-   <https://github.com/solarkennedy/puppet-consul/issues/195>

Chef
-   <https://github.com/johnbellone/consul-cookbook>

using vault with consul as backend
==================================

-   <http://blog.illogicalextend.com/quick-setup-for-hashicorp-vault-with-consul-backend>

install
=======

    mkdir download
    cd download

    powershell -noprofile -executionpolicy unrestricted -command "(new-object System.Net.WebClient).DownloadFile('https://raw.githubusercontent.com/TaylorMonacelli/consul-install-windows/wip/nssminstall.ps1','nssminstall.ps1')"
    powershell -noprofile -executionpolicy unrestricted -file nssminstall.ps1

    powershell -noprofile -executionpolicy unrestricted -command "(new-object System.Net.WebClient).DownloadFile('https://raw.githubusercontent.com/TaylorMonacelli/consul-install-windows/wip/consulinstall.ps1','consulinstall.ps1')"
    powershell -noprofile -executionpolicy unrestricted -file consulinstall.ps1

