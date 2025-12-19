#!/bin/bash
# 检查是否提供了参数
if [ $# -eq 0 ]; then
    echo "Usage: spd <port_range>"
    echo "Examples:"
    echo "spd 8000- : List processes with ports below 8000"
    echo "spd 8000+ : List processes with ports above 8000"
    echo "spd 8000-9000: List processes with ports between 8000 and 9000 (inclusive)"
    echo "spd 8000 : List processes using port 8000"
    exit 1
fi

# 获取输入参数
port_range=$1

# 检查lsof命令是否存在
if ! command -v lsof &> /dev/null; then
    echo "Error: lsof command not found. Please install lsof."
    exit 1
fi

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 解析端口范围
if [[ $port_range =~ ^([0-9]+)-$ ]]; then
    max_port=${BASH_REMATCH[1]}
    lsof -iTCP -iUDP -n -P | awk -v max="$max_port" '$9 ~ /:[0-9]+/ {split($9, a, ":"); if (a[2] <= max) print $0}' | sort -u | \
        awk -v red="$RED" -v green="$GREEN" -v nc="$NC" '{gsub(/^[[:alnum:]-]+[[:space:]]+([0-9]+)/, red "&" nc); gsub(/:[0-9]+/, green "&" nc); print}'

elif [[ $port_range =~ ^([0-9]+)\+$ ]]; then
    min_port=${BASH_REMATCH[1]}
    lsof -iTCP -iUDP -n -P | awk -v min="$min_port" '$9 ~ /:[0-9]+/ {split($9, a, ":"); if (a[2] >= min) print $0}' | sort -u | \
        awk -v red="$RED" -v green="$GREEN" -v nc="$NC" '{gsub(/^[[:alnum:]-]+[[:space:]]+([0-9]+)/, red "&" nc); gsub(/:[0-9]+/, green "&" nc); print}'

elif [[ $port_range =~ ^([0-9]+)-([0-9]+)$ ]]; then
    min_port=${BASH_REMATCH[1]}
    max_port=${BASH_REMATCH[2]}
    if [ "$min_port" -gt "$max_port" ]; then
        echo "Error: Minimum port ($min_port) cannot be greater than maximum port ($max_port)."
        exit 1
    fi
    lsof -iTCP -iUDP -n -P | awk -v min="$min_port" -v max="$max_port" '$9 ~ /:[0-9]+/ {split($9, a, ":"); if (a[2] >= min && a[2] <= max) print $0}' | sort -u | \
        awk -v red="$RED" -v green="$GREEN" -v nc="$NC" '{gsub(/^[[:alnum:]-]+[[:space:]]+([0-9]+)/, red "&" nc); gsub(/:[0-9]+/, green "&" nc); print}'

elif [[ $port_range =~ ^([0-9]+)$ ]]; then
    port=${BASH_REMATCH[1]}
    lsof -iTCP -iUDP -n -P | awk -v port="$port" '$9 ~ /:[0-9]+/ {split($9, a, ":"); if (a[2] == port) print $0}' | sort -u | \
        awk -v red="$RED" -v green="$GREEN" -v nc="$NC" '{gsub(/^[[:alnum:]-]+[[:space:]]+([0-9]+)/, red "&" nc); gsub(/:[0-9]+/, green "&" nc); print}'

else
    echo "Invalid port range format. Use one of the following:"
    echo " <port>- : Ports below the specified port"
    echo " <port>+ : Ports above the specified port"
    echo " <min>-<max> : Ports between min and max (inclusive)"
    echo " <port> : Specific port"
    exit 1
fi
