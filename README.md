Munin Plugin for RabbitMQ
============

![example](rabbitmq-munin.png)

Requirements for compiling the plugin
-----------
* [D compiler](http://dlang.org/download.html)
* [dub](http://code.dlang.org/download)

Installation
------------

**Build plugin**

```bash
dub build # binary can be build locally and copied to remote server
sudo install -m 755 -D rabbitmq /usr/share/munin/plugins/rabbitmq
sudo ln -sf /usr/share/munin/plugins/rabbitmq /etc/munin/plugins/rabbitmq
```

Configure the host, credentials, and path to reach the RabbitMQ Management Plugin.

**Add /etc/munin/plugin-conf.d/rabbitmq**

    [rabbitmq]
    env.API_URL http://user:password@localhost:15672/api/

Restart munin-node:

    sudo service munin-node restart

Check if plugins are running:

    munin-node-configure | grep rabbitmq

Test plugin output:

    munin-run rabbitmq
