#!/bin/bash


function install_dependecies() {
    # Update System Packages
    sudo apt update && sudo apt upgrade -y

    # Install General Utilities and Tools
    sudo apt install nano screen curl iptables vim cron psmisc build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev  -y

    # Install Python
    sudo apt install python3 python3-pip python3-venv python3-dev -y
}

function check_cuda() {
	version=$(nvcc --version | grep -oP 'release \K[0-9]+\.[0-9]+')
	if [ "$version" = "12.4" ]; then
        echo "CUDA 12.4已安装"
    else
        echo "CUDA 12.4未安装, 开始安装..."
        wget https://developer.download.nvidia.com/compute/cuda/12.4.0/local_installers/cuda_12.4.0_550.54.14_linux.run
        sudo sh cuda_12.4.0_550.54.14_linux.run
        echo 'export PATH=/usr/local/cuda-12.4/bin:$PATH' >> ~/.bashrc
        echo 'export LD_LIBRARY_PATH=/usr/local/cuda-12.4/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
        source ~/.bashrc
    fi
}

function install_w_ai_cli() {
    if command -v wai &> /dev/null; then
	   echo "w.ai cli已安装"
    else
        echo "w.ai cli未安装,开始安装..."
        curl -fsSL https://app.w.ai/install.sh | bash
        source ~/.bashrc
        wai help
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
    install_dependecies
    check_cuda
    start_w_ai
}

main_menu
