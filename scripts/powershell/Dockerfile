FROM mcr.microsoft.com/powershell:lts-ubuntu-22.04

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends curl unzip ca-certificates \
 && curl --proto '=https' --tlsv1.2 -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o /tmp/awscliv2.zip \
 && unzip -q /tmp/awscliv2.zip -d /tmp \
 && /tmp/aws/install \
 && rm -rf /tmp/aws /tmp/awscliv2.zip /var/lib/apt/lists/*

COPY Get-RegistryReport.ps1 /scripts/Get-RegistryReport.ps1
ENTRYPOINT ["pwsh", "-NoProfile", "-File", "/scripts/Get-RegistryReport.ps1"]