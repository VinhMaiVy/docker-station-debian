#
# RockyLinux IceWM Dockerfile
#
# Pull base image.
FROM rockylinux/rockylinux:8.9

# Setup argument default and enviroment variables
ARG WEBUSERNAME=rockyuser

ENV WEBUSERNAME=${WEBUSERNAME}
ENV WEBUSERADMIN=administrator
ENV DISPLAY=:1
ENV GEOMETRY=1320x720
ENV HOME=/home/${WEBUSERNAME}

# Update the package manager and upgrade the system
# #################################################
RUN yum -y install epel-release
RUN yum -y install 'dnf-command(config-manager)'
RUN yum -y install dnf-plugins-core
RUN yum -y config-manager --set-enabled powertools
RUN yum -y update
RUN yum -y upgrade

RUN yum -y install net-tools lsof passwd bzip2 sudo wget which vim nano
RUN yum -y install samba samba-common samba-client cifs-utils tini supervisor
RUN yum -y install openssh-server openssh-clients openssl-devel
RUN yum -y install langpacks-en glibc-langpack-en git make automake autoconf gcc
RUN yum -y install libcurl-devel libxml2-devel libssh-devel libxml2-devel
RUN yum -y install python3.9 python39-devel python39-numpy python39-tkinter

RUN ln -s /usr/share/tcl8.6/tcllib-1.19 /usr/local/lib/tcllib-1.19
RUN alternatives --set python3 /usr/bin/python3.9

# Compile and add Extra Themes for Icewm
ADD ./tgz/icewm-extra-themes.tgz /tmp/
WORKDIR /tmp/icewm-extra-themes
RUN ./autogen.sh
RUN ./configure --prefix=/usr --sysconfdir=/etc
RUN make V=0
RUN make DESTDIR="$pkgdir" install
RUN rm -rf /tmp/icewm-extra-themes

RUN ssh-keygen -A

# Set locale
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8


# Install icewm and tightvnc server.
# #################################################
RUN yum -y install icewm-minimal-session
RUN yum -y install xterm firefox 
RUN yum -y install tigervnc-server 
RUN /bin/dbus-uuidgen > /etc/machine-id


# install and setup noVNC
# #################################################
RUN /usr/bin/pip3.9 install wheel
RUN /usr/bin/pip3.9 install websockify
RUN yum -y install novnc 

# Setup Supervisord
# #################################################
COPY ./local/supervisord.conf /etc/supervisord.conf
COPY ./supervisord.d/ /etc/supervisord.d/

# Set up User ${WEBUSERADMIN}
# #################################################
RUN useradd -u 1000 -U -s /bin/bash -m -b /home ${WEBUSERADMIN}
RUN echo "${WEBUSERADMIN}  ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/${WEBUSERADMIN}

RUN mkdir /home/${WEBUSERADMIN}/.ssh
COPY authorized_keys /home/${WEBUSERADMIN}/.ssh/authorized_keys
COPY ./local/selfpem /home/${WEBUSERADMIN}/.ssh/selfpem
COPY ./local/certpem /home/${WEBUSERADMIN}/.ssh/certpem
COPY ./local/keypem /home/${WEBUSERADMIN}/.ssh/certpem
RUN chmod -R go-rwx /home/${WEBUSERADMIN}/.ssh
RUN chown -R ${WEBUSERADMIN}:${WEBUSERADMIN} /home/${WEBUSERADMIN}


# Set up User (${WEBUSERNAME})
# #################################################
RUN groupadd -g 59555 secshost
RUN useradd -u 7700 -g 59555 -s /bin/bash -m -b /home secshost_adm
RUN useradd -u 1094 -g 59555 -s /bin/bash -m -b /home ${WEBUSERNAME}

COPY ./local/dot-bashrc /home/${WEBUSERNAME}/.bashrc

RUN mkdir /home/${WEBUSERNAME}/.ssh
COPY authorized_keys /home/${WEBUSERNAME}/.ssh/authorized_keys
COPY ./local/id_rsa.svc_secshost /home/${WEBUSERNAME}/.ssh/id_rsa
COPY ./local/id_rsa-pub.svc_secshost /home/${WEBUSERNAME}/.ssh/id_rsa.pub
RUN chmod -R go-rwx /home/${WEBUSERNAME}/.ssh
RUN touch /home/${WEBUSERNAME}/.Xauthority
RUN chmod go-rwx /home/${WEBUSERNAME}/.Xauthority

RUN mkdir -p /home/${WEBUSERNAME}/.vnc
RUN mkdir -p /home/${WEBUSERNAME}/.vnc/passwd.cm
COPY ./local/passwd /home/${WEBUSERNAME}/.vnc/passwd.cm
RUN chmod go-rwx /home/${WEBUSERNAME}/.vnc/passwd.cm/passwd
RUN ln -fs /home/${WEBUSERNAME}/.vnc/passwd.cm/passwd /home/${WEBUSERNAME}/.vnc/passwd

RUN mkdir /home/${WEBUSERNAME}/.icewm
COPY ./webuser/dot-icewm/ /home/${WEBUSERNAME}/.icewm/

RUN chown -R 1094:59555 /home/${WEBUSERNAME}

# #################################################
RUN sed -i "s/webusername/${WEBUSERNAME}/g" /etc/supervisord.d/icewm-session.ini
RUN sed -i "s/webusername/${WEBUSERNAME}/g" /etc/supervisord.d/Xvnc.ini

RUN usermod -a -G adm ${WEBUSERADMIN}

# Finalize installation and default command
# #################################################
RUN mkdir /root/run.cm
COPY ./local/run.sh /root/run.cm/run.sh
RUN ln -fs /root/run.cm/run.sh /root/run.sh
RUN chmod +x /root/*.sh
RUN rm -f /run/nologin
RUN mkdir /tmp/.X11-unix
RUN chmod 1777 /tmp/.X11-unix

# Expose ports.
EXPOSE 22
EXPOSE 443

# Define default command
WORKDIR /home/${WEBUSERNAME}
CMD ["/root/run.sh"]
