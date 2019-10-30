############################################################
# Dockerfile to build tfansible 
# Multi-Stage builds require Docker Engine 17.05 or higher
############################################################

# Start with alpine
FROM alpine:3.10

LABEL maintainer "t.kam@f5.com"

ENV TFANSIBLE_REPO https://github.com/tkam8/tfansible.git
ENV GOOGLE_CREDENTIALS /tmp/gcp_creds.json
# The GitHub branch to target for dynamic resources
ENV TFANSIBLE_GH_BRANCH master

# setuid so things like ping work
#RUN chmod +s /bin/busybox

# Add in S6 overlay so we can run multiple services 
ADD https://github.com/just-containers/s6-overlay/releases/download/v1.21.8.0/s6-overlay-amd64.tar.gz /tmp/
RUN gunzip -c /tmp/s6-overlay-amd64.tar.gz | tar -xf - -C / && rm -f /tmp/s6-overlay-amd64.tar.gz

# Add go-dnsmasq so resolver works
ADD https://github.com/janeczku/go-dnsmasq/releases/download/1.0.7/go-dnsmasq-min_linux-amd64 /usr/sbin/go-dnsmasq
RUN chmod +x /usr/sbin/go-dnsmasq

# Start S6 init 
ENTRYPOINT ["/init"]
CMD ["/tfansboot/start"]

# Add useful APKs
RUN apk add --update openssh openssl bash curl git vim nano python py-pip

# Upgrade pip
RUN pip install --upgrade pip

# Setup various users and passwords
RUN adduser -h /home/tfansible -u 1000 -s /bin/bash tfansible -D
RUN echo 'tfansible:default' | chpasswd
RUN echo 'root:default' | chpasswd

# Expose SSH 
EXPOSE 22 

# Copy in base FS from repo into root

COPY fs /

# Set execute permissions for all files under tfansboot
RUN chmod +x /tfansboot/*

# Set Work directory
WORKDIR /home/tfansible

RUN chmod 777 /tmp

# Add libraries to compile ansible
RUN apk add --update gcc python-dev linux-headers libc-dev libffi libffi-dev openssl openssl-dev make

# Install ansible
RUN echo "----Installing Ansible----"  && \
    pip install ansible==2.8.5 bigsuds f5-sdk paramiko netaddr deepdiff ansible-lint ansible-review openshift 

RUN mkdir -p /etc/ansible                        && \
    echo 'localhost' > /etc/ansible/hosts

# Create ansible.cfg file for setting host key checking to false
RUN echo $'[defaults]\n\
host_key_checking = False\n'\
>> /etc/ansible/ansible.cfg

# Set the terraform image version
ENV TERRAFORM_VERSION=0.12.10
ENV TERRAFORM_SHA256SUM=2215208822f1a183fb57e24289de417c9b3157affbe8a5e520b768edbcb420b4

# Set the gcp key location
ENV GCP_GCE_KEY=/tmp/gcp_key

# Install Terraform
RUN echo "----Installing Terraform----"  && \
    curl https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip > terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    echo "${TERRAFORM_SHA256SUM}  terraform_${TERRAFORM_VERSION}_linux_amd64.zip" > terraform_${TERRAFORM_VERSION}_SHA256SUMS && \
    sha256sum -cs terraform_${TERRAFORM_VERSION}_SHA256SUMS && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /bin && \
    rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip  && \
    rm -f terraform_${TERRAFORM_VERSION}_SHA256SUMS

# Clone all templates and initialize Terraform

# RUN echo "----Copying terraform and ansible templates repo----"  && \
#     git clone https://github.com/tkam8/NGINX-F5-CDN.git  && \
#     echo "----Initializing GCP terraform template----"  && \
#     cd /NGINX-F5-CDN/tf-ansible-gcp/terraform/  && \
#     terraform init