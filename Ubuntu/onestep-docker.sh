#!/bin/bash


function install_dependecies() {
    # Update System Packages
    sudo apt update && sudo apt upgrade -y

    # Install General Utilities and Tools
    sudo apt install nano screen curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev  -y

    # Install Python
    sudo apt install python3 python3-pip python3-venv python3-dev -y
}

function check_cuda() {
    sudo apt update
    sudo apt install nvidia-cuda-toolkit -y
	version=$(nvcc --version | grep -oP 'release \K[0-9]+\.[0-9]+')
	if [ "$version" = "12.4" ]; then
        echo "CUDA 12.4已安装"
    else
        echo "CUDA 12.4未安装, 当前版本："
        nvcc --version
        read -r -p "是否继续？[y/n] " choice
        choice=${choice:-y}
        if [[ $choice =~ ^[Yy]$ || $choice == "" ]]; then
            echo "继续安装..."
        else
            echo "操作已取消，退出脚本"
            exit 1
        fi
    fi
}

function install_w_ai_cli() {
    if command -v wai &> /dev/null; then
	   echo "w.ai cli已安装"
    else
        echo "w.ai cli未安装,开始安装..."
        curl -fsSL https://app.w.ai/install.sh | bash
        source ~/.bashrc
        wai run
    fi
}

function start_w_ai() {
    install_w_ai_cli
    read -p "请输入API KEY：" API_KEY
    read -p "请输入服务个数: " SERVICE_NUM

    # 启动所有服务实例
    for ((i=1; i<=$SERVICE_NUM; i++)); do
        export W_AI_API_KEY=$API_KEY
        wai run >> wai-cli-$i.log 2>&1 &
        echo $! > wai-cli-$i.pid
    done
}

# main menu
function main_menu() {
    # install_dependecies
    # check_cuda
    start_w_ai
}

main_menu
