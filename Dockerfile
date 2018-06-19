FROM cubeearth/headless-desktop:ubuntu_bionic
ENV DEBIAN_FRONTEND noninteractive
SHELL [ "/bin/bash", "-c" ]

RUN apt-get update && \
	apt-get install -y wget dbus-x11 gnupg \
				libgtk2.0-0 libnotify-dev libgconf-2-4 libnss3 libxss1 libasound2 xvfb \
				git nodejs npm firefox 

RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
	echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list && \
  	apt-get update && apt-get install -y google-chrome-stable
  	
RUN npm install npm@latest -g

USER desktop

RUN mkdir -p /home/desktop/package
WORKDIR /home/desktop/package

RUN mkdir -p /home/desktop/.node && \
	npm config set prefix=/home/desktop/.node && \
	npm init -y && \
	npm set progress=false && \
	npm install --save-dev cypress | awk 'BEGIN{n=0} {f=0} s == $0 { f=1 } /(Downloading|Unzipping) Cypress/ && f==0 { s=$0; n=n+1; f=1; if(n==15) { print s; n=0 } } f==0 { if(n > 0) { print s; n=0 }; print $0 } END{ if(n > 0) { print s } }' && test ${PIPESTATUS[0]} -eq 0 && \
	$(npm bin)/cypress verify
	
RUN echo ========================== && \
  	echo -n "Google Chrome    " && google-chrome --version | sed -r 's/[^0-9]+([0-9.]+)/\1/' && \
	echo -n "Mozilla Firefox  " && firefox --version | sed -r 's/[^0-9]+([0-9.]+)/\1/' && \
	echo -n "NodeJS           " && nodejs -v && \
	echo -n "NPM              " && npm -v && \
	echo -n "Cypress          " && npm list cypress | grep cypress | sed 's/^.*@\(.*\)$/\1/' && \
	echo ==========================
	
# Launch google-chrome with "google-chrome --no-sandbox".
# This is considered as unsafe, but since we are using a container with a non-privileged
# user dedicated to cypress test cases, the risk should be very limited. The alternative is
# to launch the container with cap-admin which grants the container admin privileges able to
# change everthing on the host system which is more dangerous.

# launch firefox with "firefox"

USER root

ADD scripts/* /usr/scripts/
RUN chmod +x /usr/scripts/*.sh

#RUN	rm -rf /var/lib/apt/lists/*

##RUN $(npm bin)/cypress run

ENV TERM xterm
ENV DBUS_SESSION_BUS_ADDRESS=/dev/null
ENV npm_config_loglevel warn
#ENV npm_config_unsafe_perm true

VOLUME /home/desktop/package/cypress
