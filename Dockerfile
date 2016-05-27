FROM maci0/systemd

MAINTAINER Peter Schiffer <pschiffe@redhat.com>

ENV container=docker FIRST_START=True

RUN yum -y --setopt=tsflags=nodocs upgrade \
    && yum -y --setopt=tsflags=nodocs install pcs which conntrack \
    && yum -y clean all

RUN yum install -y yum-utils passwd
RUN yum-config-manager --add-repo http://download.opensuse.org/repositories/network:/ha-clustering:/Stable/CentOS_CentOS-7/network:ha-clustering:Stable.repo
RUN yum install -y crmsh wget

LABEL RUN /usr/bin/docker run -d \$OPT1 --privileged --net=host -p 2224:2224 -v /sys/fs/cgroup:/sys/fs/cgroup -v /etc/localtime:/etc/localtime:ro -v /run/docker.sock:/run/docker.sock -v /usr/bin/docker:/usr/bin/docker:ro --name \$NAME \$IMAGE \$OPT2 \$OPT3

RUN curl -L https://github.com/kelseyhightower/confd/releases/download/v0.11.0/confd-0.11.0-linux-amd64 -o /usr/local/bin/confd && chmod +x /usr/local/bin/confd
RUN curl -L  https://github.com/coreos/etcd/releases/download/v3.0.0-beta.0/etcd-v3.0.0-beta.0-linux-amd64.tar.gz \
    -o etcd-v3.0.0-beta.0-linux-amd64.tar.gz && \
    tar xzvf etcd-v3.0.0-beta.0-linux-amd64.tar.gz && \
    cp etcd-v3.0.0-beta.0-linux-amd64/etcd* /usr/bin/
RUN mkdir -p /etc/confd/{conf.d,templates}
ADD conf.d/ /etc/confd/conf.d/
ADD templates/ /etc/confd/templates/
ADD *.service /usr/lib/systemd/system/
ADD setup_cluster.sh /usr/local/bin/setup_cluster.sh
ADD init.sh /usr/bin/init.sh
RUN systemctl mask network.service rhel-dmesg.service systemd-tmpfile.service chmod.service dbus-daemon.service
RUN sed -i '3 i\
After=dbus.service' /usr/lib/systemd/system/pcsd.service && \
    systemctl enable pcsd pcsd_setup confd
ENV MY_IP=""

EXPOSE 2224

VOLUME ["/sys/fs/cgroup"]
VOLUME ["/run"]
VOLUME ["/tmp"]

CMD ["/usr/bin/init.sh"]
