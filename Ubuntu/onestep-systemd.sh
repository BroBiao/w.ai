#!/bin/bash


function install_dependecies() {
    # Update System Packages
    sudo apt update && sudo apt upgrade -y

    # Install General Utilities and Tools
    sudo apt install nano screen curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev  -y

    # Install Python
    sudo apt install python3 python3-pip python3-venv python3-dev -y
}

function install_cuda() {
    # Uninstall the existing CUDA version:
    sudo apt remove --purge cuda-* nvidia-* -y
    sudo apt autoremove -y

    # Install CUDA 12.4
    wget https://developer.download.nvidia.com/compute/cuda/12.4.0/local_installers/cuda_12.4.0_550.54.14_linux.run
    sudo sh cuda_12.4.0_550.54.14_linux.run

    # Setup environment variables
    echo 'export PATH=/usr/local/cuda-12.4/bin:$PATH' >> ~/.bashrc
    echo 'export LD_LIBRARY_PATH=/usr/local/cuda-12.4/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
    source ~/.bashrc
}

function check_cuda() {
    if command -v nvcc &> /dev/null; then
    	version=$(nvcc --version | grep -oP 'release \K[0-9]+\.[0-9]+')
    	if [ "$version" = "12.4" ]; then
            echo "CUDA 12.4已安装"
        else
            echo "CUDA 12.4未安装,开始安装..."
            install_cuda
        fi
    else
        install_cuda
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

function install_w_ai_services() {
    install_w_ai_cli
    read -p "请输入API KEY：" API_KEY
    read -p "请输入服务个数: " SERVICE_NUM

    for ((i=1; i<=$SERVICE_NUM; i++)); do
        SERVICE_CONTENT="[Unit]
Description=w.ai Node Service
After=network.target

[Service]
User=$(whoami)
ExecStart=/usr/bin/bash -lc '$(command -v wai) run'
Restart=on-failure
RestartSec=30
Environment=W_AI_API_KEY=$API_KEY

[Install]
WantedBy=multi-user.target"
	echo "$SERVICE_CONTENT" | sudo tee /etc/systemd/system/wai-cli-$i.service > /dev/null
    done

    sudo systemctl daemon-reload
}

function setup_cron() {
    wget -O wai-check-cli.sh https://github.com/BroBiao/w.ai/raw/main/Ubuntu/wai-check-cli-systemd.sh
    chmod +x wai-check-cli.sh
    (crontab -l 2>/dev/null; echo "*/5 * * * * /usr/bin/bash $(pwd)/wai-check-cli.sh >> $(pwd)/wai-check-cli.sh.log 2>&1") | crontab -
}

# main menu
function main_menu() {
    install_dependecies
    check_cuda
    install_w_ai_services
    setup_cron
}

main_menu
