FROM jenkins/jenkins:lts-jdk17
USER root

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl gnupg unzip jq maven \
 && install -m 0755 -d /etc/apt/keyrings \
 && curl --proto '=https' --tlsv1.2 -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc \
 && chmod a+r /etc/apt/keyrings/docker.asc \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends docker-ce-cli docker-buildx-plugin \
 && curl --proto '=https' --tlsv1.2 -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o /tmp/awscliv2.zip \
 && unzip -q /tmp/awscliv2.zip -d /tmp \
 && /tmp/aws/install \
 && rm -rf /tmp/aws /tmp/awscliv2.zip /var/lib/apt/lists/*

ARG TERRAFORM_VERSION=1.14.6
RUN arch="$(dpkg --print-architecture)" \
 && curl --proto '=https' --tlsv1.2 -fsSL -o "/tmp/terraform_${TERRAFORM_VERSION}_linux_${arch}.zip" "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${arch}.zip" \
 && curl --proto '=https' --tlsv1.2 -fsSL -o /tmp/terraform.sums "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS" \
 && (cd /tmp && grep " terraform_${TERRAFORM_VERSION}_linux_${arch}.zip$" terraform.sums | sha256sum -c -) \
 && unzip -q "/tmp/terraform_${TERRAFORM_VERSION}_linux_${arch}.zip" -d /usr/local/bin terraform \
 && rm -f /tmp/terraform_*.zip /tmp/terraform.sums \
 && terraform version

USER jenkins
