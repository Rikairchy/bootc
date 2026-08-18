FROM registry.redhat.io/rhel10/rhel-bootc:latest

RUN subscription-manager register --org=8014867 --activationkey=Lab && \
    dnf -y install dnf-plugins-core && \
    dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo && \
    dnf -y install \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin \
        firewalld \
        keepalived \
        nfs-utils \
        gettext && \
        dnf clean all && \
        subscription-manager unregister && \
        rm -rf /var/cache/dnf

ARG SSH_PUB_KEY
RUN groupadd -g 1000 container && \
    useradd -u 1000 -g 1000 -m -s /bin/bash container && \
    usermod -aG wheel,docker container && \
    install -d -m 0700 -o container -g container /home/container/.ssh && \
    echo "${SSH_PUB_KEY}" > /home/container/.ssh/authorized_keys && \
    chmod 600 /home/container/.ssh/authorized_keys && \
    restorecon -Rv /home/container && \
    mkdir -p /nfs && \
    echo "container ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/container && \
    chmod 0440 /etc/sudoers.d/container

COPY keepalived.conf.template /etc/keepalived/keepalived.conf.template

COPY traefik-check.service traefik-check.timer customize.service /etc/systemd/system/

RUN systemctl enable docker firewalld keepalived customize traefik-check.timer sshd

COPY public.xml /etc/firewalld/zones/public.xml

COPY check-traefik.sh parse_check.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/check-traefik.sh /usr/local/bin/parse_check.sh

RUN dnf clean all && \
    export KVER=$(cd /usr/lib/modules && ls -d * | head -n 1) && \
    find /usr/lib/modules -mindepth 1 -maxdepth 1 -not -name "$KVER" -exec rm -rf {} +

RUN bootc container lint

CMD ["/usr/lib/systemd/systemd"]
