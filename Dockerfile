FROM debian:jessie

RUN apt-get update
RUN apt-get install --yes build-essential automake libcapstone-dev libsqlite3-dev wget git
RUN apt-get install --yes --no-install-recommends wget make g++ clang
RUN apt-get install --yes --no-install-recommends libstdc++-4.9-dev libssl-dev libsqlite3-dev libompl-dev

RUN dpkg --add-architecture i386
RUN apt-get update
RUN apt-get install --yes --no-install-recommends gcc-multilib g++-multilib vim python libstdc++-4.9-dev:i386 libssl-dev:i386 libsqlite3-dev:i386

RUN useradd -ms /bin/bash  vault
USER vault

WORKDIR /home/vault
RUN git clone https://github.com/mrtuborg/Tracer.git

WORKDIR /home/vault
RUN git clone git://sourceware.org/git/valgrind.git -b svn/VALGRIND_3_13_0 valgrind-3.13.0
RUN cp -r /home/vault/Tracer/TracerGrind/tracergrind valgrind-3.13.0/
RUN cp -r /home/vault/Tracer/TracerGrind/valgrind-3.13.0.diff .
RUN patch -p0 < valgrind-3.13.0.diff

WORKDIR /home/vault/valgrind-3.13.0
RUN ./autogen.sh && ./configure --prefix=/usr && make -j4

WORKDIR /home/vault
RUN wget https://software.intel.com/sites/landingpage/pintool/downloads/pin-2.14-71313-gcc.4.4.7-linux.tar.gz
RUN tar xzf pin-2.14-71313-gcc.4.4.7-linux.tar.gz

WORKDIR /home/vault/Tracer/TracerGrind/sqlitetrace
RUN make all

WORKDIR /home/vault/Tracer/TracerGrind/texttrace 
RUN make all

WORKDIR /home/vault
RUN git clone https://github.com/mrtuborg/Daredevil.git
WORKDIR /home/vault/Daredevil
RUN make

WORKDIR /home/vault
RUN git clone https://github.com/mrtuborg/Deadpool.git

USER root
WORKDIR /home/vault/valgrind-3.13.0/
RUN make install

WORKDIR /home/vault/Tracer/TracerGrind/sqlitetrace 
RUN make install

WORKDIR /home/vault/Tracer/TracerGrind/texttrace
RUN make install

RUN mv /home/vault/pin-2.14-71313-gcc.4.4.7-linux /opt
RUN chown -hR vault:vault /opt/pin-2.14-71313-gcc.4.4.7-linux
# export PIN_ROOT=/opt/pin-2.14-71313-gcc.4.4.7-linux
RUN echo "\nexport PIN_ROOT=/opt/pin-2.14-71313-gcc.4.4.7-linux" >> ~/.bashrc

WORKDIR /home/vault/Tracer/TracerPIN
RUN PIN_ROOT=/opt/pin-2.14-71313-gcc.4.4.7-linux make
RUN make install

WORKDIR /home/vault/Daredevil
RUN make install

WORKDIR /home/vault/Deadpool
RUN mkdir -p /opt/deadpool
RUN cp *.py /opt/deadpool
RUN chown -hR vault:vault /opt/deadpool

