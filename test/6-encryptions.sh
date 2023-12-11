for i in 0 1 2; do
  export WORKER${i}=$(hcloud server list --selector "tag=worker-${i}" -o columns=ipv4 -o noheader)
done
for i in 0 1 2; do
  export CONTROLLER${i}=$(hcloud server list --selector "tag=controller-${i}" -o columns=ipv4 -o noheader)
done
echo $CONTROLLER0 $CONTROLLER1 $CONTROLLER2 $WORKER0 $WORKER1 $WORKER2

ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

for instance in ${CONTROLLER0} ${CONTROLLER1} ${CONTROLLER2}; do
  scp -o StrictHostKeyChecking=no -i $HOME/.ssh/hetzner_cloud_ed25519 encryption-config.yaml root@${instance}:~/
done
