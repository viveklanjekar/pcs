FROM maci0/systemd

MAINTAINER Peter Schiffer <pschiffe@redhat.com>

ENV container=docker FIRST_START=True

RUN yum -y --setopt=tsflags=nodocs upgrade \
    && yum -y --setopt=tsflags=nodocs install pcs which conntrack \
    && yum -y clean all

RUN yum install -y yum-utils passwd
RUN yum-config-manager --add-repo http://download.opensuse.org/repositories/network:/ha-clustering:/Stable/CentOS_CentOS-7/network:ha-clustering:Stable.repo
RUN yum install -y epel-release && yum install -y python-pip crmsh
RUN pip install https://github.com/mvdbeek/pacemaker-etcd/archive/master.zip

LABEL RUN /usr/bin/docker run -d \$OPT1 --privileged --net=host -p 2224:2224 -v /sys/fs/cgroup:/sys/fs/cgroup -v /etc/localtime:/etc/localtime:ro -v /run/docker.sock:/run/docker.sock -v /usr/bin/docker:/usr/bin/docker:ro --name \$NAME \$IMAGE \$OPT2 \$OPT3

ADD *.service /usr/lib/systemd/system/
ADD setup_cluster.sh /usr/local/bin/setup_cluster.sh
ADD init.sh /usr/bin/init.sh
RUN systemctl mask network.service rhel-dmesg.service systemd-tmpfile.service chmod.service dbus-daemon.service
RUN sed -i '3 i\
After=dbus.service' /usr/lib/systemd/system/pcsd.service && \
    systemctl enable pcsd pcsd_setup pcs_etcd pass_watch
ENV MY_IP=""

EXPOSE 2224

VOLUME ["/sys/fs/cgroup"]
VOLUME ["/run"]
VOLUME ["/tmp"]

CMD ["/usr/bin/init.sh"]
