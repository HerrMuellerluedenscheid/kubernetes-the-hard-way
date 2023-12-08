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
  scp -i $HOME/.ssh/hetzner_cloud_ed25519 encryption-config.yaml root@${instance}:~/
done
