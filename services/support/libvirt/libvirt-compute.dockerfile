FROM ubuntu:14.04.3
MAINTAINER mhenkel@juniper.net

RUN apt-get -qqy update && apt-get install -y --no-install-recommends \
  libvirt-bin \
  libvirt0 \ 
  python-libvirt \
  qemu-kvm \
  && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY services/support/libvirt/entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
RUN echo "listen_tls = 0" >> /etc/libvirt/libvirtd.conf; \
echo 'listen_tcp = 1' >> /etc/libvirt/libvirtd.conf; \
echo 'tls_port = "16514"' >> /etc/libvirt/libvirtd.conf; \ 
echo 'tcp_port = "16509"' >> /etc/libvirt/libvirtd.conf; \
echo 'auth_tcp = "none"' >> /etc/libvirt/libvirtd.conf

RUN mkdir -p /var/lib/libvirt/images/
VOLUME [ "/sys/fs/cgroup" ]
RUN echo 'clear_emulator_capabilities = 0' >> /etc/libvirt/qemu.conf; \
echo 'user = "root"' >> /etc/libvirt/qemu.conf; \
echo 'group = "root"' >> /etc/libvirt/qemu.conf; \
echo 'cgroup_device_acl = [' >> /etc/libvirt/qemu.conf; \
echo '        "/dev/null", "/dev/full", "/dev/zero",'>> /etc/libvirt/qemu.conf; \
echo '        "/dev/random", "/dev/urandom",'>> /etc/libvirt/qemu.conf; \
echo '        "/dev/ptmx", "/dev/kvm", "/dev/kqemu",'>> /etc/libvirt/qemu.conf; \
echo '        "/dev/rtc", "/dev/hpet", "/dev/net/tun",'>> /etc/libvirt/qemu.conf; \
echo ']'>> /etc/libvirt/qemu.conf

CMD ["/usr/sbin/libvirtd","-l"]
