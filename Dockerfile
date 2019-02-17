FROM eosio/builder as builder
ARG branch=master
ARG symbol=SYS
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install libsoci-dev openssl ca-certificates pkg-config librabbitmq-dev libzmq5-dev && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/eosrio/eos_zmq_plugin.git
RUN git clone https://github.com/EOSLaoMao/elasticsearch_plugin.git elasticsearch_plugin && cd elasticsearch_plugin && git submodule update --init --recursive && cd ..

RUN git clone https://github.com/WLBF/elasticlient.git && \
    cd elasticlient && \
    git submodule update --init --recursive && \
    cmake -DBUILD_ELASTICLIENT_TESTS=NO -DBUILD_ELASTICLIENT_EXAMPLE=NO && \
    make && \
    make install && \
    cp -r "external/cpr/include/cpr" "/usr/local/include/cpr" && \
    cp "lib/libcpr.so" "/usr/local/lib/libcpr.so"

RUN cd /usr/local && git clone https://github.com/edenhill/librdkafka.git && \
    cd librdkafka && \
    ./configure && \
    make && \
    make install


    
RUN git clone https://github.com/asiniscalchi/eosio_sql_plugin.git
RUN git clone https://github.com/LiquidEOS/eos-rabbitmq-plugin.git
RUN git clone https://github.com/LiquidEOS/eos-producer-heartbeat-plugin.git
RUN git clone https://github.com/EOSLaoMao/blacklist_plugin.git
RUN git clone https://github.com/spoonincode/eosio_all_code_dump_plugin.git
RUN git clone https://github.com/angelol/eosio-stats-plugin.git
RUN git clone https://github.com/tiboong/eosio_ledger_plugin.git
RUN git clone https://github.com/MyWishPlatform/eosio_acc_check_plugin.git
RUN git clone https://github.com/MyWishPlatform/eosio_table_entry_plugin.git
RUN git clone https://github.com/eosauthority/eosio-watcher-plugin.git

RUN git clone https://github.com/aws/aws-sdk-cpp && \
    cd aws-sdk-cpp && \
    cmake . && \
    make && \
    make install
    
RUN git clone https://github.com/necokeine/AWS_plugin.git
RUN git clone https://github.com/TP-Lab/kafka_plugin.git


RUN wget https://github.com/Kitware/CMake/releases/download/v3.13.4/cmake-3.13.4-Linux-x86_64.sh \
    && bash cmake-3.13.4-Linux-x86_64.sh --prefix=/usr/local --exclude-subdir --skip-license \
    && rm cmake-3.13.4-Linux-x86_64.sh

RUN git clone -b $branch https://github.com/EOSIO/eos.git --recursive \
    && cd eos && echo "$branch:$(git rev-parse HEAD)" > /etc/eosio-version \
    && cmake -H. -B"/tmp/build" -GNinja -DCMAKE_BUILD_TYPE=Release -DWASM_ROOT=/opt/wasm -DCMAKE_CXX_COMPILER=clang++ \
       -DEOSIO_ADDITIONAL_PLUGINS="/eosio-watcher-plugin;/eosio_table_entry_plugin;/eosio_acc_check_plugin;/eosio-stats-plugin;/eosio_all_code_dump_plugin;/blacklist_plugin;/eos-producer-heartbeat-plugin;/eos_zmq_plugin;/elasticsearch_plugin;/eosio_sql_plugin;/eos-rabbitmq-plugin" -DCMAKE_C_COMPILER=clang -DCMAKE_INSTALL_PREFIX=/tmp/build -DBUILD_MONGO_DB_PLUGIN=true -DCORE_SYMBOL_NAME=$symbol \
    && cmake --build /tmp/build --target install




FROM ubuntu:18.04

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install openssl ca-certificates pkg-config libzmq5-dev && rm -rf /var/lib/apt/lists/*
COPY --from=builder /usr/local/lib/* /usr/local/lib/
COPY --from=builder /tmp/build/bin /opt/eosio/bin
COPY --from=builder /tmp/build/contracts /contracts
COPY --from=builder /eos/Docker/config.ini /
COPY --from=builder /etc/eosio-version /etc
COPY --from=builder /eos/Docker/nodeosd.sh /opt/eosio/bin/nodeosd.sh
ENV EOSIO_ROOT=/opt/eosio
RUN chmod +x /opt/eosio/bin/nodeosd.sh
ENV LD_LIBRARY_PATH /usr/local/lib
ENV PATH /opt/eosio/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin