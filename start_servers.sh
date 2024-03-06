#!/bin/bash

# 设置默认值
tensor_parallel_size=1
gpu_memory_utilization=0.2
model_path="/qwen/Qwen-1_8B-Chat-Int4"

# 解析命令行参数
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --tensor-parallel-size) tensor_parallel_size="$2"; shift ;;
        --gpu-memory-utilization) gpu_memory_utilization="$2"; shift ;;
        --model-path) model_path="$2"; shift ;;
        *) echo "未知参数: $1"; exit 1 ;;
    esac
    shift
done

# 启动服务
nohup python -m fastchat.serve.controller --host 0.0.0.0 > controller.log 2>&1 &
echo "启动 Controller，等待启动..."
sleep 10 # 延时10秒，确保服务启动

nohup python -m fastchat.serve.vllm_worker --host 0.0.0.0 --model-path "$model_path" --tensor-parallel-size $tensor_parallel_size --trust-remote-code --gpu-memory-utilization $gpu_memory_utilization > vllm_worker.log 2>&1 &
echo "启动 serve..."
sleep 3 # 延时10秒，确保服务启动

nohup python -m fastchat.serve.openai_api_server --host 0.0.0.0 --port 8180 > openai_api.log 2>&1 &
tail -f vllm_worker.log