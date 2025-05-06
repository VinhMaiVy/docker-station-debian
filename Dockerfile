#
# RockyLinux IceWM Dockerfile
#
# Pull base image.
FROM debian:trixie

# Setup argument default and enviroment variables
ARG WEBUSERNAME=webuser

ENV WEBUSERNAME=${WEBUSERNAME}
ENV WEBUSERADMIN=administrator
ENV DISPLAY=:1
ENV GEOMETRY=1320x720
ENV HOME=/home/${WEBUSERNAME}

# Update the package manager and upgrade the system
# #################################################
RUN apt-get -y update
RUN apt-get -y upgrade

RUN apt-get -y install net-tools lsof passwd bzip2 sudo wget which vim nano
RUN apt-get -y install samba samba-common samba-client cifs-utils tini supervisor
RUN apt-get -y install openssh-server openssh-client
RUN apt-get -y install build-essential git automake autoconf
RUN apt-get -y install libcurl4-openssl-dev libxml2-dev libssh-dev libxml2-dev libssl-dev
RUN apt-get -y install python3 python3-dev python3-numpy python3-pip

#RUN alternatives --set python3 /usr/bin/python3.9

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
RUN apt-get -y install locales 
RUN echo "LC_ALL=en_US.UTF-8" >> /etc/environment
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
RUN echo "LANG=en_US.UTF-8" > /etc/locale.conf
RUN /usr/sbin/locale-gen


# Install icewm and tightvnc server.
# #################################################
RUN apt-get -y install icewm
RUN apt-get -y install xterm xfonts-terminus firefox-esr
RUN apt-get -y install tigervnc-standalone-server 
RUN /bin/dbus-uuidgen > /etc/machine-id


# install and setup noVNC
# #################################################
# RUN /usr/bin/pip3 install wheel
RUN apt-get -y install python3-pip-whl python3-websockify
RUN apt-get -y install novnc 
RUN cp /usr/share/novnc/vnc.html /usr/share/novnc/index.html

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
RUN useradd -u 1026 -g 100 -s /bin/bash -m -b /home ${WEBUSERNAME}

COPY ./local/dot-bashrc /home/${WEBUSERNAME}/.bashrc

RUN mkdir /home/${WEBUSERNAME}/.ssh
COPY authorized_keys /home/${WEBUSERNAME}/.ssh/authorized_keys
COPY ./local/id_rsa.svc_webuser /home/${WEBUSERNAME}/.ssh/id_rsa
COPY ./local/id_rsa-pub.svc_webuser /home/${WEBUSERNAME}/.ssh/id_rsa.pub
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

RUN chown -R 1026:100 /home/${WEBUSERNAME}

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
