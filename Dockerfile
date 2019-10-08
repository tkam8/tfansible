############################################################
# Dockerfile to build tfansible 
# Multi-Stage builds require Docker Engine 17.05 or higher
############################################################

# Start with ubuntu for now
FROM ubuntu:18:04

LABEL maintainer "t.kam@f5.com"

ENV TFANSIBLE_REPO https://github.com/tkam8/tfansible.git

# setuid so things like ping work
#RUN chmod +s /bin/busybox

# Add in S6 overlay so we can run multiple services (while not entirely best practice for containers 1:1 rule)
ADD https://github.com/just-containers/s6-overlay/releases/download/v1.21.8.0/s6-overlay-amd64.tar.gz /tmp/
RUN gunzip -c /tmp/s6-overlay-amd64.tar.gz | tar -xf - -C / && rm -f /tmp/s6-overlay-amd64.tar.gz

# Add go-dnsmasq so resolver works
#ADD https://github.com/janeczku/go-dnsmasq/releases/download/1.0.7/go-dnsmasq-min_linux-amd64 /usr/sbin/go-dnsmasq
#RUN chmod +x /usr/sbin/go-dnsmasq

# Start S6 init 
ENTRYPOINT ["/init"]

# Add useful APKs
RUN apk add --update openssh openssl bash curl git vim nano python py-pip

# Upgrade pip
RUN pip install --upgrade pip

# Setup various users and passwords
RUN useradd -h /home/tfansible -u 1000 -s /bin/bash tfansible -D
RUN echo 'tfansible:default' | chpasswd
RUN echo 'root:default' | chpasswd

# Expose SSH 
EXPOSE 22 

#Add libraries to compile ansible
RUN apk add --update gcc python-dev linux-headers libc-dev libffi libffi-dev openssl openssl-dev 

#Install ansible
RUN echo "----Installing Ansible----"  && \
    pip install ansible==2.8.5 bigsuds f5-sdk netaddr deepdiff ansible-lint ansible-review

RUN mkdir -p /etc/ansible                        && \
    echo 'localhost' > /etc/ansible/hosts

# Set the terraform image version
ENV TERRAFORM_VERSION=0.12.9
ENV TERRAFORM_SHA256SUM=69712c6216cc09b7eca514b9fb137d4b1fead76559c66f338b4185e1c347ace5

RUN echo "----Installing Terraform----"  && \
    curl https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip > terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    echo "${TERRAFORM_SHA256SUM}  terraform_${TERRAFORM_VERSION}_linux_amd64.zip" > terraform_${TERRAFORM_VERSION}_SHA256SUMS && \
    sha256sum -cs terraform_${TERRAFORM_VERSION}_SHA256SUMS && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /bin && \
    rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip  && \
    rm -f terraform_${TERRAFORM_VERSION}_SHA256SUMS


# RUN echo "----Cloning ansible-pan repo----"  && \
#     git clone https://github.com/PaloAltoNetworks/ansible-pan.git  && \
#     echo "----Install PaloAltoNetworks from ansible-galaxy----"  && \
#     ansible-galaxy install PaloAltoNetworks.paloaltonetworks

# RUN echo "----Copying terraform-templates repo----"  && \
#     git clone https://github.com/PaloAltoNetworks/terraform-templates.git  && \
#     echo "----initializing one click AWS terraform template---"  && \
#     cd /terraform-templates/one-click-multi-cloud/one-click-aws && \
#     terraform init && \
#     echo "----initializing one click Azure terraform template----"  && \
#     cd /terraform-templates/one-click-multi-cloud/one-click-azure  && \
#     terraform init

