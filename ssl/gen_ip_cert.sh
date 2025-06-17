#!/bin/bash

# 检查是否安装了 openssl
if ! command -v openssl &>/dev/null; then
  echo "Error: OpenSSL is not installed. Please install it first."
  exit 1
fi

# 检查是否提供了 IP 地址参数
if [[ -z "$1" ]]; then
  echo "Error: Please provide the IP address as the first argument."
  exit 1
fi

IP_ADDRESS="$1"

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 定义证书和私钥文件名
KEY_FILE="$SCRIPT_DIR/${IP_ADDRESS}.key"
CERT_FILE="$SCRIPT_DIR/${IP_ADDRESS}.crt"
CSR_FILE="$SCRIPT_DIR/${IP_ADDRESS}.csr"

# 生成私钥
openssl genrsa -out "$KEY_FILE" 2048

# 生成证书签名请求 (CSR)
openssl req -new -key "$KEY_FILE" -out "$CSR_FILE" \
  -subj "/C=US/ST=State/L=City/O=Organization/OU=Unit/CN=$IP_ADDRESS"

# 生成自签名证书
openssl x509 -req -in "$CSR_FILE" -signkey "$KEY_FILE" -out "$CERT_FILE" -days 365

# 删除临时的 CSR 文件
rm -f "$CSR_FILE"

# 输出结果
echo "Certificate and key have been generated in the script directory: $SCRIPT_DIR"
echo "Private Key: $KEY_FILE"
echo "Certificate: $CERT_FILE"