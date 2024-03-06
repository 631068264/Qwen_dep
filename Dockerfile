FROM nvidia/cuda:12.1.0-cudnn8-devel-ubuntu20.04 as build

RUN sed -i "s@http://.*archive.ubuntu.com@http://repo.huaweicloud.com@g" /etc/apt/sources.list && \
    sed -i "s@http://.*security.ubuntu.com@http://repo.huaweicloud.com@g" /etc/apt/sources.list && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* && apt update -y && \
    apt install -y --no-install-recommends wget && \
    wget https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-py39_4.9.2-Linux-x86_64.sh && \
    bash Miniconda3-py39_4.9.2-Linux-x86_64.sh -b && \
    rm Miniconda3-py39_4.9.2-Linux-x86_64.sh && apt-get install -y libgl1-mesa-glx

# 使用非交互式前端来避免交互式输入
ENV DEBIAN_FRONTEND=noninteractive
# 安装软件包并配置时区
RUN apt-get install -y --no-install-recommends tzdata && \
    ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata && \
    apt-get install -y --no-install-recommends libglib2.0-0



# 恢复 DEBIAN_FRONTEND 环境变量
ENV DEBIAN_FRONTEND=dialog
ENV PATH /root/miniconda3/bin:$PATH
COPY requirements.txt /root/
COPY ./vllm-gptq /root/vllm-gptq
COPY start_servers.sh /root

RUN pip install --upgrade pip && cd /root/vllm-gptq && pip install -e . &&  \
    cd /root && pip install -r requirements.txt && \
    rm -rf ~/.cache/pip


WORKDIR /root
CMD ["/bin/bash"]