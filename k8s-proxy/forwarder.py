"""
SOCKS proxy + DNS repeater.

The SOCKS proxy implements the tor extensions; it is used by LD_PRELOAD
mechanism (torsocks).

The DNS server handles A records by resolving them the way a DNS client would.
That means e.g. "kubernetes" can eventually be mapped to
"kubernetes.default.svc.cluster.local". This is used by VPN-y mechanisms like
sshuttle in order to make forwarded DNS queries work in way that matches
clients within a k8s pod.
"""

import os

from twisted.application.service import Application
from twisted.internet import reactor
from twisted.names import dns, server

import socks
import resolver


def listen(client):
    reactor.listenTCP(9050, socks.SOCKSv5Factory())
    factory = server.DNSServerFactory(clients=[client])
    protocol = dns.DNSDatagramProtocol(controller=factory)

    reactor.listenUDP(9053, protocol)


def main():
    predefined_namespace = os.getenv('TELEPRESENCE_CONTAINER_NAMESPACE', None)
    if predefined_namespace:
        NAMESPACE = predefined_namespace
    else:
        with open("/var/run/secrets/kubernetes.io/serviceaccount/namespace") as f:
            NAMESPACE = f.read()
    NOLOOP = os.environ.get("TELEPRESENCE_NAMESERVER") is not None
    reactor.suggestThreadPoolSize(50)
    print("Listening...")
    listen(resolver.LocalResolver(NOLOOP, os.environ["TELEPRESENCE_NAMESERVER"], NAMESPACE))


main()
application = Application("go")
