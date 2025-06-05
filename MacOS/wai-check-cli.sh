#!/bin/zsh

# 配置参数
SERVICE_PREFIX="com.wai-cli-"   # 服务名前缀
SERVICE_COUNT=5                 # 服务数量
LOG_LINES=10                    # 检查的日志行数
MAX_LOG_TIME_SEC=300           # 日志时间阈值（秒），超过则重启（示例：5分钟）

# 存储最大coin值的变量
MAX_COIN_VALUE=0

# 遍历所有服务
for ((i=1; i<=$SERVICE_COUNT; i++)); do
    SERVICE_NAME="${SERVICE_PREFIX}${i}.service"
    echo "检查服务: $SERVICE_NAME"
    
    # 检查服务是否正在运行
    SERVICE_STATUS=$(launchctl list | grep "$SERVICE_NAME" | awk '{print $1}')
    if [[ -z "$SERVICE_STATUS" ]]; then
        echo "  ➤ 服务未运行，启动服务"
        launchctl start "$SERVICE_NAME"
        continue
    fi
    
    # ----------------------------
    # 条件1：检查日志中是否有特定字符串
    # ----------------------------
    
    # 获取日志内容（从标准输出和错误输出文件）
    STDOUT_LOG="/tmp/wai-cli-${i}.out"
    STDERR_LOG="/tmp/wai-cli-${i}.err"
    
    LOG_CONTENT=""
    if [[ -f "$STDOUT_LOG" ]]; then
        LOG_CONTENT+=$(tail -n "$LOG_LINES" "$STDOUT_LOG" 2>/dev/null)
    fi
    if [[ -f "$STDERR_LOG" ]]; then
        LOG_CONTENT+=$'\n'$(tail -n "$LOG_LINES" "$STDERR_LOG" 2>/dev/null)
    fi
    
    HAS_ERROR=0  # 标记是否需要重启（0=需要，1=不需要）
    
    # 提取所有匹配的coin值并记录最大值
    while IFS= read -r line; do
        if [[ "$line" =~ have\ ([0-9]+)\ w\.ai\ coin ]]; then
            CURRENT_VALUE=${match[1]}  # zsh 风格的匹配
            if (( CURRENT_VALUE > MAX_COIN_VALUE )); then
                MAX_COIN_VALUE=$CURRENT_VALUE
            fi
            HAS_ERROR=1  # 存在匹配，标记为不需要重启
        fi
    done <<< "$LOG_CONTENT"
    
    # 如果没有匹配到字符串，则重启服务
    if (( HAS_ERROR == 0 )); then
        echo "  ➤ 未找到coin值，触发重启"
        launchctl stop "$SERVICE_NAME"
        sleep 2
        launchctl start "$SERVICE_NAME"
        continue  # 重启后跳过时间检查
    fi
    
    # ----------------------------
    # 条件2：检查最后一条日志的时间
    # ----------------------------
    
    LAST_LOG_TIME=""
    
    # 尝试从日志文件获取最后修改时间
    if [[ -f "$STDOUT_LOG" ]]; then
        LAST_LOG_TIME=$(stat -f "%m" "$STDOUT_LOG" 2>/dev/null)
    elif [[ -f "$STDERR_LOG" ]]; then
        LAST_LOG_TIME=$(stat -f "%m" "$STDERR_LOG" 2>/dev/null)
    fi
    
    if [[ -z "$LAST_LOG_TIME" ]]; then
        echo "  ➤ 无法获取日志时间，触发重启"
        launchctl stop "$SERVICE_NAME"
        sleep 2
        launchctl start "$SERVICE_NAME"
        continue
    fi
    
    # 计算时间差（当前时间戳 - 最后日志时间戳）
    CURRENT_TIME=$(date +%s)
    TIME_DIFF=$(( CURRENT_TIME - LAST_LOG_TIME ))
    
    if (( TIME_DIFF > MAX_LOG_TIME_SEC )); then
        echo "  ➤ 日志已过期（${TIME_DIFF}秒），触发重启"
        launchctl stop "$SERVICE_NAME"
        sleep 2
        launchctl start "$SERVICE_NAME"
    else
        echo "  ➤ 服务正常运行（最后活动：${TIME_DIFF}秒前）"
    fi
done

# 输出最大coin值
if (( MAX_COIN_VALUE > 0 )); then
    echo "$(date "+%m-%d %H:%M:%S") 当前w.ai coin值: $MAX_COIN_VALUE"
else
    echo "$(date "+%m-%d %H:%M:%S") 未找到有效的w.ai coin值"
fi
