FROM centos:7

# install OS packages
RUN yum install -y epel-release && \
	yum clean all && yum makecache && \
	yum install -y \
	createrepo \
	git \
	golang \
	make \
	mercurial \
	nginx \
	which \
	net-tools \
	yum-utils


RUN useradd -u 10000 -G nginx repo && \
    mkdir -p /data && \
    chmod g+s /data && \
    chmod 755 -R /home/repo && \
    mkdir -p /var/nginx && \
	chmod -R 777 /var/run && \
    chown repo:root -R /var/lib/nginx/  /var/nginx && \
    chmod 775 -R /var/lib/nginx/ /var/nginx && \
    chmod 775 /var/log/nginx && \
	ln -sf /dev/stdout /var/log/nginx/access.log && \
	ln -sf /dev/stderr /var/log/nginx/error.log


# setup GOPATH and source directory
RUN mkdir -p /go/{bin,pkg,src} /go/src/yum-mirror && go get -u github.com/codegangsta/cli
ENV GOPATH=/go PATH=$PATH:/go/bin TZ=Asia/Shanghai GEM_PATH=/home/repo/.gem/ruby:/usr/share/gems:/usr/local/share/gems

WORKDIR /go/src/yum-mirror
COPY . ./

RUN cp -f nginx.conf /etc/nginx/nginx.conf && \
    cp nginx-site.conf /etc/nginx/conf.d/ && \
    chown repo:root -R . /data /etc/nginx/conf.d/ && \
    chmod -R 775  /etc/nginx/conf.d/ *.sh && \
	chmod 777 /data

RUN go get && go build


STOPSIGNAL SIGTERM
USER repo
VOLUME [ "/data" ]

EXPOSE 8080

ENTRYPOINT [ "./entrypoint.sh" ]
