#!/bin/bash

mkdir -p ~/.ssh/controlmasters
chmod 711 ~/.ssh
ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts


cat - <<SSHCONFIG > ~/.ssh/config
Host *
  # Wait max 30s to establish connection
  ConnectTimeout 30
  # Control persist to speed 2nd ssh connection
  ControlMaster auto
  ControlPath ~/.ssh/controlmasters/%C
  ControlPersist 5
  # Disables warning when IP is added to known_hosts
  CheckHostIP no
  # Use the identity provided via attached Secret
  IdentityFile /keys/id_rsa
  # Enable protocol-level keepalive to detect connection failure
  ServerAliveCountMax 4
  ServerAliveInterval 30
  # Using protocol-level, so we don't need TCP-level
  TCPKeepAlive no
SSHCONFIG

git clone $REPO /repo
mkdir /repo/deployments || true

for i in `kubectl get deployment | grep -v NAME | awk '{print $1}'`; do
    kubectl get -o=json deployment $i | jq --sort-keys 'del(
          .metadata.annotations."kubectl.kubernetes.io/last-applied-configuration",
          .metadata.annotations."control-plane.alpha.kubernetes.io/leader",
          .metadata.uid,
          .metadata.selfLink,
          .metadata.resourceVersion,
          .metadata.creationTimestamp,
          .metadata.generation,
          .metadata.managedFields
      )' | python3 -c 'import sys, yaml, json; yaml.safe_dump(json.load(sys.stdin), sys.stdout, default_flow_style=False)' > /repo/deployments/$i.yaml ;
      done

      cd /repo
      git config --global user.email "rcook@redhat.com"
      git add *
      git commit -am 'bot commit'
      git push origin $BRANCH