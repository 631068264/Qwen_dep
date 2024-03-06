```sh
注释：
cudatoolkit强制要求12.1（VLLM-gptq项目）
所以宿主机显卡驱动支持cuda需要>=12.1

路径：
122.13.25.106：/home/yaokj5/dl/lihz_project/Qwen_dep

构建命令：
docker build --no-cache -t qwen_vllm:dev1 .

压缩镜像
docker save xxx > xx.tar
tar -zcvf  xxx.tar.gz xx.tar

解压镜像
tar -zxvf xx.tar.gz
docker load < xx.tar

```

容器内的执行命令：

```sh

# 运行第一个命令并将输出重定向到日志文件
nohup python -m fastchat.serve.controller --host 0.0.0.0 > controller.log 2>&1 &
# 运行第二个命令并将输出重定向到另一个日志文件
nohup python -m fastchat.serve.vllm_worker --host 0.0.0.0 --model-path "/mnt/qwen/Qwen-1_8B-Chat-Int4" --tensor-parallel-size 1 --trust-remote-code --gpu-memory-utilization 0.2 > vllm_worker.log 2>&1 &
nohup python -m fastchat.serve.openai_api_server --host 0.0.0.0 --port 8180 > openai_api.log 2>&1 &
tail -f vllm_worker.log
```


```sh

-v 映射外面的模型路径：固定容器内/mnt  
--tensor-parallel-size tensor切分的数量，要能被模型的head整除 一般和dcvice数量相同 一般为1 2 4 8测试。
--gpu-memory-utilization 0.2  占用单张显卡总显存的百分比。例如16g*0.2=3.2G 同时要求这个数值大于该模型的最低占用需求。 需要根据不同的卡调整。一般为0.4-0.8之间。
--model-path 容器内指定的模型
--gpus '"device=0,1"'  自己选用nvidia-smi的显卡编号 从0-7 根据指定推理卡选择
```





容器外启动命令：

```sh
docker run --name qwen_vllm  --gpus '"device=3"' -v /data/home/yaokj5/dl/models:/mnt -p 8188:8180 qwen_vllm:latest bash start_servers.sh --tensor-parallel-size 1 --gpu-memory-utilization 0.8 --model-path "/mnt/Qwen-72B-Chat-Int4"
docker run --name qwen_vllm  --gpus '"device=3"' -v /data/home/yaokj5/dl/models:/mnt -p 8188:8180 qwen_vllm:dev1 bash start_servers.sh --tensor-parallel-size 1 --gpu-memory-utilization 0.2 --model-path "/mnt/qwen/Qwen-1_8B-Chat-Int4"
docker run --name qwen_vllm  --gpus '"device=4,5"' -v /data/home/yaokj5/dl/models:/mnt -p 8188:8180 qwen_vllm:dev1 bash start_servers.sh --tensor-parallel-size 2 --gpu-memory-utilization 0.8 --model-path "/mnt/Qwen-72B-Chat-Int4"
```

模型在容器内镜像测试：

```sh
docker run --gpus '"device=7"' -p 8189:8180 qwen_vllm_model_inside:latest 
```



容器外（宿主机）调用

```sh
curl --location 'http://localhost:8188/v1/chat/completions' \
--header 'Content-Type: application/json' \
--data '{
    "messages": [
        {
            "role": "user",
            "content": "用50字解释下量子计算的原理及应用场景、方向等。"
        }
    ],
    "model":"Qwen-72B-Chat-Int4",
    "temperature": 0.95,
    "top_p": 0.7,
    "max_length": 256,
    "stream": false,
    "is_knowledge": false
}'
```

