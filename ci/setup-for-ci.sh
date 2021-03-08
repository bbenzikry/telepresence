#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

## This is a work in progress. It is intended to replace the current setup file
## environment-setup.sh but only for use in CI. At the moment there is a lot of
## duplication. FIXME.

OS=$(python3 -c "import sys; print(sys.platform)")

echo "Check for requirements"
uuidgen > /dev/null
curl -V > /dev/null
echo "$KUBERNAUT_TOKEN" > /dev/null

echo "Set up ${OS}-specific stuff"
case "${OS}" in
    osx)
        brew update > /dev/null
        brew install python3 || brew upgrade python
        brew install --cask osxfuse
        brew install sshfs
        pip3 install virtualenv
        ;;

    linux)
        sudo apt-get install sshfs conntrack lsb-release
        ;;

    *)
        echo "Unknown platform."
        exit 1
esac

echo "Download commands"
curl -sLO "https://storage.googleapis.com/kubernetes-release/release/v1.12.2/bin/${OS}/amd64/kubectl"
curl -sLO "http://releases.datawire.io/kubernaut/$(curl -s http://releases.datawire.io/kubernaut/latest.txt)/${OS}/amd64/kubernaut"
curl -sLO "https://github.com/rancher/k3s/releases/download/v0.5.0/k3s"

echo "Install commands"
chmod a+x kubectl kubernaut k3s
sudo mv kubectl kubernaut k3s /usr/local/bin

echo "Install torsocks"
./ci/build-torsocks.sh "$OS"

echo "Set up kubernaut's backend"
mkdir -p ~/.config/kubernaut
kubernaut config backend create --url="https://next.kubernaut.io" --name="v2" --activate "$KUBERNAUT_TOKEN"
