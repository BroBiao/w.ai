#!/bin/bash

# 配置参数
FILE_PREFIX="wai-cli-"      # 日志文件名前缀
INSTANCE_COUNT=1            # 服务数量
LOG_LINES=10                # 检查的日志行数
MAX_LOG_TIME_SEC=300        # 日志时间阈值（秒），超过则重启（示例：5分钟）

API_KEY=$(<api_key.txt)
export W_AI_API_KEY="$API_KEY"

# 存储最大coin值的变量
MAX_COIN_VALUE=0

if command -v pstree &> /dev/null; then
    echo "psmisc已安装"
else
    echo "psmisc未安装，开始安装"
    sudo apt update
    sudo apt install psmisc
fi

# 遍历所有服务
for ((i=1; i<=$INSTANCE_COUNT; i++)); do
    LOG_FILE_NAME="${FILE_PREFIX}${i}.log"
    echo "正在检查: $LOG_FILE_NAME"

    # ----------------------------
    # 条件1：检查日志中是否有特定字符串
    # ----------------------------
    LOG_CONTENT=$(tail -n 10 "$LOG_FILE_NAME")
    HAS_ERROR=0  # 标记是否需要重启（0=需要，1=不需要）

    # 提取所有匹配的coin值并记录最大值
    while IFS= read -r line; do
        if [[ "$line" =~ have\ ([0-9]+)\ w\.ai\ coin ]]; then
            CURRENT_VALUE=${BASH_REMATCH[1]}
            if (( CURRENT_VALUE > MAX_COIN_VALUE )); then
                MAX_COIN_VALUE=$CURRENT_VALUE
            fi
            HAS_ERROR=1  # 存在匹配，标记为不需要重启
        fi
    done <<< "$LOG_CONTENT"

    # 如果没有匹配到字符串，则重启服务
    if (( HAS_ERROR == 0 )); then
        echo "  ➤ 未找到coin值，触发重启"
        PID_FILE_NAME="${FILE_PREFIX}${i}.pid"
        INSTANCE_PID=$(cat $PID_FILE_NAME)
        kill -TERM $(pstree -p $INSTANCE_PID | grep -oP '\(\K[0-9]+' | sort -rn) 2>/dev/null
        sleep 5
        wai run >> wai-cli-$i.log 2>&1 &
        echo $! > wai-cli-$i.pid
        continue  # 重启后跳过时间检查
    fi

    # ----------------------------
    # 条件2：检查最后一条日志的时间
    # ----------------------------
    LAST_LOG_TIME=$(stat -c %Y "$LOG_FILE_NAME")
    if [[ -z "$LAST_LOG_TIME" ]]; then
        echo "  ➤ 无日志记录，触发重启"
        PID_FILE_NAME="${FILE_PREFIX}${i}.pid"
        INSTANCE_PID=$(cat $PID_FILE_NAME)
        kill -TERM $(pstree -p $INSTANCE_PID | grep -oP '\(\K[0-9]+' | sort -rn) 2>/dev/null
        sleep 5
        wai run >> wai-cli-$i.log 2>&1 &
        echo $! > wai-cli-$i.pid
        continue
    fi

    # 计算时间差（当前时间戳 - 最后日志时间戳）
    CURRENT_TIME=$(date +%s)
    TIME_DIFF=$(( CURRENT_TIME - LAST_LOG_TIME ))

    if (( TIME_DIFF > MAX_LOG_TIME_SEC )); then
        echo "  ➤ 日志已过期（${TIME_DIFF}秒），触发重启"
        PID_FILE_NAME="${FILE_PREFIX}${i}.pid"
        INSTANCE_PID=$(cat $PID_FILE_NAME)
        kill -TERM $(pstree -p $INSTANCE_PID | grep -oP '\(\K[0-9]+' | sort -rn) 2>/dev/null
        sleep 5
        wai run >> wai-cli-$i.log 2>&1 &
        echo $! > wai-cli-$i.pid
    fi
done

# 输出最大coin值
if (( MAX_COIN_VALUE > 0 )); then
    echo "$(date "+%m-%d %H:%M:%S") 当前w.ai coin值: $MAX_COIN_VALUE"
else
    echo "$(date "+%m-%d %H:%M:%S") 未找到有效的w.ai coin值"
fi
