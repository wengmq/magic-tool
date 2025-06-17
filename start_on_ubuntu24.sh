#!/bin/bash

# 以脚本所在目录作为工作目录
cd "$(dirname "$0")"
# 遇到错误立即退出
set -e 

# 路径变量定义
OPENRESTY_CONF_DIR="/usr/local/openresty/nginx/conf"
SSL_DIR="./ssl"
HOST_CONF_DIR="$OPENRESTY_CONF_DIR/host"
V2RAY_CONF_FILE="$HOST_CONF_DIR/v2ray.domain.com.host"

# 安装 OpenResty
install_openresty() {
    echo "Installing OpenResty..."
    sudo apt-get -y install --no-install-recommends wget gnupg ca-certificates lsb-release
    rm -f /usr/share/keyrings/openresty.gpg
    wget -O - https://openresty.org/package/pubkey.gpg | sudo gpg --dearmor -o /usr/share/keyrings/openresty.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/openresty.gpg] \
    http://openresty.org/package/ubuntu $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/openresty.list > /dev/null
    sudo apt-get update
    sudo apt-get -y install openresty
    sudo systemctl enable --now openresty
}

# 初始化 OpenResty 配置
init_openresty() {
    echo "Initializing OpenResty..."
    local ip=$(curl -s ifconfig.me)
    chmod +x ./ssl/gen_ip_cert.sh
    sudo ./ssl/gen_ip_cert.sh "$ip"
    sudo mkdir -p "$HOST_CONF_DIR"
    sudo cp -r "$SSL_DIR/" /usr/local/openresty/nginx/
    
    if ! grep -q 'include host' "$OPENRESTY_CONF_DIR/nginx.conf"; then
        sudo sed -i '$s/}$/\n    include host\/\*.host;\n}/' "$OPENRESTY_CONF_DIR/nginx.conf"
    fi
    
    sudo cp ./v2ray/v2ray.domain.com.host "$V2RAY_CONF_FILE"
    sudo sed -i "s/v2ray.domain.top/$ip/" "$V2RAY_CONF_FILE"
    systemctl restart openresty
    echo "OpenResty initialization completed."
}

# 安装 Docker
install_docker() {
    echo "Installing Docker..."
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://test.docker.com -o test-docker.sh
        sudo sh test-docker.sh
        rm -f test-docker.sh
        sudo systemctl enable --now docker
    else
        echo "Docker is already installed."
    fi
}

# 启动 V2Ray
start_v2ray() {
    echo "Starting V2Ray..."
    docker compose -f ./v2ray/docker-compose.yaml up -d
    docker restart v2ray
    echo "V2Ray started successfully."
}

main() {
    if ! command -v openresty &> /dev/null; then
        install_openresty
    fi
    init_openresty
    install_docker
    start_v2ray
    echo "Script execution completed."
}

main