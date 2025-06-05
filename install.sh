#!/bin/bash

# Author: Joey
# Blog: joeyblog.net
# Feedback TG (Feedback Telegram): https://t.me/+ft-zI76oovgwNmRh
# Core Functionality By:
#   - https://github.com/eooce (老王)
# Version: 2.4.8.sh (macOS - sed delimiter, panel URL opening with https default) - Modified by User Request
# Modification: Added jq check and auto-install attempt, removed Lao Wang's TG group.

# --- Color Definitions ---
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_BLUE='\033[0;34m' 
COLOR_MAGENTA='\033[0;35m'
COLOR_CYAN='\033[0;36m'
COLOR_WHITE_BOLD='\033[1;37m' 
COLOR_RESET='\033[0m' # No Color

# --- Helper Functions ---
print_separator() {
  echo -e "${COLOR_BLUE}======================================================================${COLOR_RESET}"
}

print_header() {
  local header_text="$1"
  local color_code="$2"
  if [ -z "$color_code" ]; then
    color_code="${COLOR_WHITE_BOLD}" # Default header color
  fi
  print_separator
  echo -e "${color_code}${header_text}${COLOR_RESET}"
  print_separator
}

# --- Welcome Message ---
print_header "欢迎使用 IBM-sb-ws 增强配置脚本" "${COLOR_GREEN}" 
echo -e "${COLOR_GREEN}  此脚本由 ${COLOR_WHITE_BOLD}Joey (joeyblog.net)${COLOR_GREEN} 维护和增强。${COLOR_RESET}"
echo -e "${COLOR_GREEN}  核心功能由 ${COLOR_WHITE_BOLD}老王 (github.com/eooce)${COLOR_GREEN} 实现。${COLOR_RESET}"
# Removed Lao Wang's specific group and GitHub link from welcome
echo
echo -e "${COLOR_GREEN}  如果您对 ${COLOR_WHITE_BOLD}此增强脚本${COLOR_GREEN} 有任何反馈，请通过 Telegram 联系 Joey:${COLOR_RESET}"
echo -e "${COLOR_GREEN}    Joey's Feedback TG: ${COLOR_WHITE_BOLD}https://t.me/+ft-zI76oovgwNmRh${COLOR_RESET}"
print_separator
echo -e "${COLOR_GREEN}>>> 小白用户建议直接一路回车，使用默认配置快速完成部署 <<<${COLOR_RESET}" 
echo

# --- 读取用户输入的函数 ---
read_input() {
  local prompt_text="$1"
  local variable_name="$2"
  local default_value="$3"
  local advice_text="$4"

  if [ -n "$advice_text" ]; then
    echo -e "${COLOR_CYAN}  ${advice_text}${COLOR_RESET}" 
  fi

  if [ -n "$default_value" ]; then
    read -p "$(echo -e ${COLOR_YELLOW}"[?] ${prompt_text} [${default_value}]: "${COLOR_RESET})" user_input 
    eval "$variable_name=\"${user_input:-$default_value}\""
  else
    read -p "$(echo -e ${COLOR_YELLOW}"[?] ${prompt_text}: "${COLOR_RESET})" user_input
    eval "$variable_name=\"$user_input\""
  fi
  echo 
}

# --- 初始化变量 ---
CUSTOM_UUID=""
NEZHA_SERVER="" 
NEZHA_PORT=""   
NEZHA_KEY=""    
ARGO_DOMAIN=""  
ARGO_AUTH=""    
NAME="ibm"
CFIP="cloudflare.182682.xyz"
CFPORT="443"
CHAT_ID=""      
BOT_TOKEN=""    
UPLOAD_URL=""   
declare -a PREFERRED_ADD_LIST=()

# --- UUID 处理函数 ---
handle_uuid_generation() {
  echo -e "${COLOR_MAGENTA}--- UUID 配置 ---${COLOR_RESET}"
  read_input "请输入您要使用的 UUID (留空则自动生成):" CUSTOM_UUID ""
  if [ -z "$CUSTOM_UUID" ]; then
    if command -v uuidgen &> /dev/null; then
      CUSTOM_UUID=$(uuidgen)
      echo -e "${COLOR_GREEN}  ✓ 已自动生成 UUID: ${COLOR_WHITE_BOLD}$CUSTOM_UUID${COLOR_RESET}"
    else
      echo -e "${COLOR_RED}  ✗ 错误: \`uuidgen\` 命令未找到。请安装 \`uuidgen\` 或手动提供 UUID。${COLOR_RESET}"
      read_input "请手动输入一个 UUID:" CUSTOM_UUID ""
      if [ -z "$CUSTOM_UUID" ]; then
        echo -e "${COLOR_RED}  ✗ 未提供 UUID，脚本无法继续。${COLOR_RESET}"
        exit 1
      fi
    fi
  else
    echo -e "${COLOR_GREEN}  ✓ 将使用您提供的 UUID: ${COLOR_WHITE_BOLD}$CUSTOM_UUID${COLOR_RESET}"
  fi
  echo
}

# --- 检查并安装 jq ---
check_and_install_jq() {
  if command -v jq &> /dev/null; then
    echo -e "${COLOR_GREEN}  ✓ jq 已安装。${COLOR_RESET}"
    return 0
  fi

  echo -e "${COLOR_YELLOW}  jq 未安装，尝试自动安装...${COLOR_RESET}"
  if command -v apt-get &> /dev/null; then
    echo -e "${COLOR_CYAN}  > 尝试使用 apt-get 安装 jq...${COLOR_RESET}"
    sudo apt-get update >/dev/null
    sudo apt-get install jq -y >/dev/null
  elif command -v yum &> /dev/null; then
    echo -e "${COLOR_CYAN}  > 尝试使用 yum 安装 jq...${COLOR_RESET}"
    sudo yum install jq -y >/dev/null
  else
    echo -e "${COLOR_RED}  ✗ 未知的包管理器，无法自动安装 jq。${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}  请手动安装 jq (例如: sudo apt-get install jq 或 sudo yum install jq)，然后重新运行脚本。${COLOR_RESET}"
    return 1 # Indicate failure to install
  fi

  if command -v jq &> /dev/null; then
    echo -e "${COLOR_GREEN}  ✓ jq 安装成功!${COLOR_RESET}"
    return 0
  else
    echo -e "${COLOR_RED}  ✗ jq 安装失败。${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}  请手动安装 jq，然后重新运行脚本。${COLOR_RESET}"
    return 1 # Indicate failure to install
  fi
}


# --- 执行部署函数 ---
run_deployment() {
  print_header "开始部署流程" "${COLOR_CYAN}" 
  echo -e "${COLOR_CYAN}  当前配置预览:${COLOR_RESET}"
  echo -e "    ${COLOR_WHITE_BOLD}UUID:${COLOR_RESET} $CUSTOM_UUID"
  echo -e "    ${COLOR_WHITE_BOLD}哪吒服务器:${COLOR_RESET} $NEZHA_SERVER"
  echo -e "    ${COLOR_WHITE_BOLD}哪吒端口:${COLOR_RESET} $NEZHA_PORT"
  echo -e "    ${COLOR_WHITE_BOLD}哪吒密钥:${COLOR_RESET} $NEZHA_KEY"
  echo -e "    ${COLOR_WHITE_BOLD}Argo域名:${COLOR_RESET} $ARGO_DOMAIN"
  echo -e "    ${COLOR_WHITE_BOLD}Argo授权:${COLOR_RESET} $ARGO_AUTH"
  echo -e "    ${COLOR_WHITE_BOLD}节点名称 (NAME):${COLOR_RESET} $NAME"
  echo -e "    ${COLOR_WHITE_BOLD}主优选IP (CFIP):${COLOR_RESET} $CFIP (端口: $CFPORT)"
  echo -e "    ${COLOR_WHITE_BOLD}优选IP列表:${COLOR_RESET} ${PREFERRED_ADD_LIST[*]}"
  echo -e "    ${COLOR_WHITE_BOLD}TG Chat ID:${COLOR_RESET} $CHAT_ID"
  echo -e "    ${COLOR_WHITE_BOLD}TG Bot Token:${COLOR_RESET} $BOT_TOKEN"
  echo -e "    ${COLOR_WHITE_BOLD}上传 URL:${COLOR_RESET} $UPLOAD_URL"
  print_separator

  # 导出环境变量
  export UUID="$CUSTOM_UUID"
  export NEZHA_SERVER="$NEZHA_SERVER"
  export NEZHA_PORT="$NEZHA_PORT"
  export NEZHA_KEY="$NEZHA_KEY"
  export ARGO_DOMAIN="$ARGO_DOMAIN"
  export ARGO_AUTH="$ARGO_AUTH"
  export NAME="$NAME"
  export CFIP="$CFIP"
  export CFPORT="$CFPORT"
  export CHAT_ID="$CHAT_ID"
  export BOT_TOKEN="$BOT_TOKEN"
  export UPLOAD_URL="$UPLOAD_URL"

  echo -e "${COLOR_YELLOW}  正在准备执行核心部署脚本 (sb.sh)...${COLOR_RESET}"
  
  SB_SCRIPT_PATH="/tmp/sb_downloaded_script_$(date +%s%N).sh" 
  TMP_SB_OUTPUT_FILE=$(mktemp)
  if [ -z "$TMP_SB_OUTPUT_FILE" ]; then
    echo -e "${COLOR_RED}  ✗ 错误: 无法创建临时文件。${COLOR_RESET}"
    exit 1
  fi

  echo -e "${COLOR_CYAN}  > 正在下载核心脚本...${COLOR_RESET}"
  if curl -Lso "$SB_SCRIPT_PATH" https://main.ssss.nyc.mn/sb.sh; then
    chmod +x "$SB_SCRIPT_PATH"
    echo -e "${COLOR_GREEN}  ✓ 下载完成。${COLOR_RESET}"
    echo -e "${COLOR_CYAN}  > 正在执行核心脚本 (此过程可能需要几分钟，请耐心等待)...${COLOR_RESET}"

    bash "$SB_SCRIPT_PATH" > "$TMP_SB_OUTPUT_FILE" 2>&1 &
    SB_PID=$!

    TIMEOUT_SECONDS=180 
    elapsed_time=0

    local progress_chars="/-\\|"
    local char_idx=0
    while ps -p $SB_PID > /dev/null && [ "$elapsed_time" -lt "$TIMEOUT_SECONDS" ]; do
      printf "\r${COLOR_YELLOW}  [执行中 ${progress_chars:$char_idx:1}] (已用时: ${elapsed_time}s)${COLOR_RESET}"
      char_idx=$(((char_idx + 1) % ${#progress_chars}))
      sleep 1
      elapsed_time=$((elapsed_time + 1))
    done
    printf "\r${COLOR_GREEN}  [核心脚本执行完毕或超时]                                                  ${COLOR_RESET}\n"

    if ps -p $SB_PID > /dev/null; then
      echo -e "${COLOR_RED}  ✗ 核心脚本 (PID: $SB_PID) 执行超时，尝试终止...${COLOR_RESET}"
      kill -SIGTERM $SB_PID; sleep 2 
      if ps -p $SB_PID > /dev/null; then kill -SIGKILL $SB_PID; sleep 1; fi
      if ps -p $SB_PID > /dev/null; then echo -e "${COLOR_RED}    ✗ 无法终止核心脚本。${COLOR_RESET}"; else echo -e "${COLOR_GREEN}    ✓ 核心脚本已终止。${COLOR_RESET}"; fi
    else
      echo -e "${COLOR_GREEN}  ✓ 核心脚本 (PID: $SB_PID) 已执行完毕。${COLOR_RESET}"
      wait $SB_PID; SB_EXEC_EXIT_CODE=$?
      if [ "$SB_EXEC_EXIT_CODE" -ne 0 ]; then echo -e "${COLOR_RED}  警告: 核心脚本退出码为 $SB_EXEC_EXIT_CODE。${COLOR_RESET}"; fi
    fi
    rm "$SB_SCRIPT_PATH"
  else
    echo -e "${COLOR_RED}  ✗ 错误: 下载核心脚本失败。${COLOR_RESET}"
    echo "Error: sb.sh download failed." > "$TMP_SB_OUTPUT_FILE"
  fi
  
  sleep 0.5 
  RAW_SB_OUTPUT=$(cat "$TMP_SB_OUTPUT_FILE")
  rm "$TMP_SB_OUTPUT_FILE"
  echo

  print_header "部署结果分析与链接生成" "${COLOR_CYAN}" 
  if [ -z "$RAW_SB_OUTPUT" ]; then
    echo -e "${COLOR_RED}  ✗ 错误: 未能捕获到核心脚本的任何输出。${COLOR_RESET}"
  else
    # 检查并安装 jq
    if ! check_and_install_jq; then
        echo -e "${COLOR_RED}  ✗ jq 安装或检测失败。后续的 VMess 处理和 Clash 订阅生成可能无法工作。${COLOR_RESET}"
        # Decide whether to exit or continue without jq features
        # exit 1 # Option to exit if jq is critical
    fi
    echo

    echo -e "${COLOR_MAGENTA}--- 核心脚本执行结果摘要 ---${COLOR_RESET}"

    ARGO_DOMAIN_OUTPUT=$(echo "$RAW_SB_OUTPUT" | grep "ArgoDomain:")
    if [ -n "$ARGO_DOMAIN_OUTPUT" ]; then
      ARGO_ACTUAL_DOMAIN=$(echo "$ARGO_DOMAIN_OUTPUT" | awk -F': ' '{print $2}')
      echo -e "${COLOR_CYAN}  Argo 域名:${COLOR_RESET} ${COLOR_WHITE_BOLD}${ARGO_ACTUAL_DOMAIN}${COLOR_RESET}"
    else
      echo -e "${COLOR_YELLOW}  未检测到 Argo 域名。${COLOR_RESET}"
      ARGO_ACTUAL_DOMAIN="" 
    fi

    ORIGINAL_VMESS_LINK=$(echo "$RAW_SB_OUTPUT" | grep "vmess://" | head -n 1)
    declare -a GENERATED_VMESS_LINKS_ARRAY=()

    if [ -z "$ORIGINAL_VMESS_LINK" ]; then
      echo -e "${COLOR_YELLOW}  未检测到 VMess 链接。${COLOR_RESET}"
    else
      echo -e "${COLOR_GREEN}  正在处理 VMess 配置链接...${COLOR_RESET}"
      if ! command -v jq &> /dev/null; then # Re-check jq in case auto-install failed silently for some reason
        echo -e "${COLOR_YELLOW}  警告: 'jq' 命令仍然不可用。无法生成多个优选地址的 VMess 或 Clash 订阅。${COLOR_RESET}"
      elif ! command -v base64 &> /dev/null; then
        echo -e "${COLOR_RED}  错误: 'base64' 命令未找到。${COLOR_RESET}"
      else
        BASE64_DECODE_CMD="base64 -d"; BASE64_ENCODE_CMD="base64 -w0" 
        if [[ "$(uname)" == "Darwin" ]]; then BASE64_DECODE_CMD="base64 -D"; BASE64_ENCODE_CMD="base64"; fi
        BASE64_PART=$(echo "$ORIGINAL_VMESS_LINK" | sed 's/vmess:\/\///')
        JSON_CONFIG=$($BASE64_DECODE_CMD <<< "$BASE64_PART" 2>/dev/null) 

        if [ -z "$JSON_CONFIG" ]; then
          echo -e "${COLOR_RED}    ✗ VMess 链接解码失败。${COLOR_RESET}"
        else
          ORIGINAL_PS=$(echo "$JSON_CONFIG" | jq -r .ps 2>/dev/null); if [[ -z "$ORIGINAL_PS" || "$ORIGINAL_PS" == "null" ]]; then ORIGINAL_PS="节点"; fi
          if [ ${#PREFERRED_ADD_LIST[@]} -eq 0 ]; then
              echo -e "${COLOR_YELLOW}    警告: 优选IP列表为空，使用默认。${COLOR_RESET}"
              PREFERRED_ADD_LIST=("cloudflare.182682.xyz" "joeyblog.net")
          fi
          UNIQUE_PREFERRED_ADD_LIST=($(echo "${PREFERRED_ADD_LIST[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
          echo -e "${COLOR_GREEN}  生成的多个优选地址 VMess 配置链接:${COLOR_RESET}"
          for target_add in "${UNIQUE_PREFERRED_ADD_LIST[@]}"; do
            SANITIZED_TARGET_ADD=$(echo "$target_add" | sed 's/[^a-zA-Z0-9_.-]/_/g')
            NEW_PS="${ORIGINAL_PS}-优选-${SANITIZED_TARGET_ADD}"
            MODIFIED_JSON=$(echo "$JSON_CONFIG" | jq --arg new_add "$target_add" --arg new_ps "$NEW_PS" '.add = $new_add | .ps = $new_ps')
            if [ -n "$MODIFIED_JSON" ]; then
              MODIFIED_BASE64=$(echo -n "$MODIFIED_JSON" | $BASE64_ENCODE_CMD)
              GENERATED_VMESS_LINK="vmess://${MODIFIED_BASE64}"
              echo -e "    ${COLOR_WHITE_BOLD}${GENERATED_VMESS_LINK}${COLOR_RESET}"
              GENERATED_VMESS_LINKS_ARRAY+=("$GENERATED_VMESS_LINK")
            else
              echo -e "${COLOR_YELLOW}      为地址 $target_add 生成 VMess 失败。${COLOR_RESET}"
            fi
          done
        fi
      fi
    fi
    echo 

    if [ ${#GENERATED_VMESS_LINKS_ARRAY[@]} -gt 0 ]; then
      if ! command -v jq &> /dev/null; then
          echo -e "${COLOR_YELLOW}  警告: 'jq' 未找到，无法生成 Clash 订阅。${COLOR_RESET}"
      else
        echo -e "${COLOR_MAGENTA}--- Clash 订阅链接 (通过 api.wcc.best) ---${COLOR_RESET}"
        RAW_VMESS_STRING=""; for i in "${!GENERATED_VMESS_LINKS_ARRAY[@]}"; do RAW_VMESS_STRING+="${GENERATED_VMESS_LINKS_ARRAY[$i]}"; if [ $i -lt $((${#GENERATED_VMESS_LINKS_ARRAY[@]} - 1)) ]; then RAW_VMESS_STRING+="|"; fi; done
        ENCODED_VMESS_STRING=$(echo -n "$RAW_VMESS_STRING" | jq -Rr @uri)
        CONFIG_URL_RAW="https://raw.githubusercontent.com/byJoey/test/refs/heads/main/tist.ini"; CONFIG_URL_ENCODED=$(echo -n "$CONFIG_URL_RAW" | jq -Rr @uri)
        CLASH_API_BASE_URL="https://api.wcc.best/sub"
        CLASH_API_PARAMS="target=clash&url=${ENCODED_VMESS_STRING}&insert=false&config=${CONFIG_URL_ENCODED}&emoji=true&list=false&tfo=false&scv=true&fdn=false&expand=true&sort=false&new_name=true"
        FINAL_CLASH_API_URL="${CLASH_API_BASE_URL}?${CLASH_API_PARAMS}"
        
        echo -e "${COLOR_GREEN}  ✓ Clash 订阅 URL:${COLOR_RESET}"
        echo -e "    ${COLOR_WHITE_BOLD}${FINAL_CLASH_API_URL}${COLOR_RESET}"
      fi
    else
      echo -e "${COLOR_YELLOW}  没有可用的 VMess 链接来生成 Clash 订阅。${COLOR_RESET}"
    fi
    echo

    SUB_SAVE_STATUS=$(echo "$RAW_SB_OUTPUT" | grep "\.\/\.tmp\/sub\.txt saved successfully")
    if [ -n "$SUB_SAVE_STATUS" ]; then
      echo -e "${COLOR_GREEN}  ✓ 订阅文件 (.tmp/sub.txt):${COLOR_RESET} 已成功保存。"
    fi

    INSTALL_COMPLETE_MSG=$(echo "$RAW_SB_OUTPUT" | grep "安装完成" | head -n 1)
    if [ -n "$INSTALL_COMPLETE_MSG" ]; then
      echo -e "${COLOR_GREEN}  ✓ 状态:${COLOR_RESET} $INSTALL_COMPLETE_MSG"
    fi

    UNINSTALL_CMD_MSG=$(echo "$RAW_SB_OUTPUT" | grep "一键卸载命令：")
    if [ -n "$UNINSTALL_CMD_MSG" ]; then
      UNINSTALL_ACTUAL_CMD=$(echo "$UNINSTALL_CMD_MSG" | sed 's/一键卸载命令：//' | awk '{$1=$1;print}')
      echo -e "${COLOR_RED}  一键卸载命令:${COLOR_RESET} ${COLOR_WHITE_BOLD}${UNINSTALL_ACTUAL_CMD}${COLOR_RESET}"
    fi
  fi 
  
  print_header "部署完成与支持信息" "${COLOR_GREEN}" 
  echo -e "${COLOR_GREEN}  IBM-sb-ws 节点部署流程已执行完毕!${COLOR_RESET}"
  echo
  echo -e "${COLOR_GREEN}  感谢使用! 如有问题或建议，请联系:${COLOR_RESET}"
  echo -e "${COLOR_GREEN}    Joey's Feedback TG: ${COLOR_WHITE_BOLD}https://t.me/+ft-zI76oovgwNmRh${COLOR_RESET}"
  # Removed Lao Wang's TG from final message
  print_separator
}


# --- 主菜单 ---
print_header "IBM-sb-ws 部署模式选择" "${COLOR_CYAN}" 
echo -e "${COLOR_WHITE_BOLD}  1) 推荐安装${COLOR_RESET} (仅需确认UUID，可自定义优选IP列表)"
echo -e "${COLOR_WHITE_BOLD}  2) 自定义安装${COLOR_RESET} (手动配置所有参数)" 
echo -e "${COLOR_WHITE_BOLD}  Q) 退出脚本${COLOR_RESET}"
print_separator
read -p "$(echo -e ${COLOR_YELLOW}"请输入选项 [1]: "${COLOR_RESET})" main_choice
main_choice=${main_choice:-1} 

case "$main_choice" in
  1) 
    echo
    print_header "推荐安装模式" "${COLOR_MAGENTA}" 
    echo -e "${COLOR_CYAN}此模式将使用最简配置。节点名称默认为 'ibm'。${COLOR_RESET}"
    echo
    handle_uuid_generation 
    
    DEFAULT_PREFERRED_IPS_REC="cloudflare.182682.xyz,joeyblog.net"
    read_input "请输入优选IP或域名列表 (逗号隔开, 留空则使用默认: ${DEFAULT_PREFERRED_IPS_REC}):" USER_PREFERRED_IPS_INPUT_REC "${DEFAULT_PREFERRED_IPS_REC}"
    
    PREFERRED_ADD_LIST=() 
    IFS=',' read -r -a temp_array_rec <<< "$USER_PREFERRED_IPS_INPUT_REC"
    for item in "${temp_array_rec[@]}"; do
      trimmed_item=$(echo "$item" | xargs) 
      if [ -n "$trimmed_item" ]; then 
          PREFERRED_ADD_LIST+=("$trimmed_item")
      fi
    done

    NEZHA_SERVER=""; NEZHA_PORT=""; NEZHA_KEY=""
    ARGO_DOMAIN=""; ARGO_AUTH=""
    NAME="ibm" 
    if [ ${#PREFERRED_ADD_LIST[@]} -gt 0 ]; then
        CFIP="${PREFERRED_ADD_LIST[0]}" 
    else
        CFIP="cloudflare.182682.xyz" 
    fi
    CFPORT="443" 
    CHAT_ID=""; BOT_TOKEN=""; UPLOAD_URL=""
    run_deployment
    ;;
  2) # --- 自定义安装 ---
    echo
    print_header "自定义安装模式" "${COLOR_MAGENTA}"
    echo -e "${COLOR_CYAN}此模式允许您手动配置各项参数。${COLOR_RESET}"
    echo
    handle_uuid_generation # 处理 UUID

    echo
    echo -e "${COLOR_MAGENTA}--- 哪吒探针配置 (可选) ---${COLOR_RESET}"
    read -p "$(echo -e ${COLOR_YELLOW}"[?] 是否配置哪吒探针? (y/N): "${COLOR_RESET})" configure_section
    if [[ "$(echo "$configure_section" | tr '[:upper:]' '[:lower:]')" == "y" ]]; then 
      read_input "哪吒面板域名 (v1格式: nezha.xxx.com:8008; v0格式: nezha.xxx.com):" NEZHA_SERVER "" 
      read -p "$(echo -e ${COLOR_YELLOW}"[?] 您输入的哪吒面板域名是否已包含端口 (v1版特征)? (y/N): "${COLOR_RESET})" nezha_v1_style
      if [[ "$(echo "$nezha_v1_style" | tr '[:upper:]' '[:lower:]')" == "y" ]]; then
        NEZHA_PORT="" 
        echo -e "${COLOR_GREEN}  ✓ NEZHA_PORT 将留空 (v1 类型配置)。${COLOR_RESET}"
      else
        read_input "哪吒 Agent 端口 (v0 版使用, TLS端口: {443,8443,2096,2087,2083,2053}):" NEZHA_PORT "" 
      fi
      read_input "哪吒 NZ_CLIENT_SECRET (v1) 或 Agent 密钥 (v0):" NEZHA_KEY
    else
      NEZHA_SERVER=""; NEZHA_PORT=""; NEZHA_KEY=""
      echo -e "${COLOR_YELLOW}  跳过哪吒探针配置。${COLOR_RESET}"
    fi
    echo

    echo -e "${COLOR_MAGENTA}--- Argo 隧道配置 (可选) ---${COLOR_RESET}"
    read -p "$(echo -e ${COLOR_YELLOW}"[?] 是否配置 Argo 隧道? (y/N): "${COLOR_RESET})" configure_section
    if [[ "$(echo "$configure_section" | tr '[:upper:]' '[:lower:]')" == "y" ]]; then
      read_input "Argo 域名 (留空则启用临时隧道):" ARGO_DOMAIN ""
      if [ -n "$ARGO_DOMAIN" ]; then 
        read_input "Argo Token 或 JSON:" ARGO_AUTH
      else
        ARGO_AUTH="" 
        echo -e "${COLOR_GREEN}  ✓ 将使用 Argo 临时隧道，无需 ARGO_AUTH。${COLOR_RESET}"
      fi
    else
      ARGO_DOMAIN=""; ARGO_AUTH=""
      echo -e "${COLOR_YELLOW}  跳过 Argo 隧道配置。${COLOR_RESET}"
    fi
    echo
    
    echo -e "${COLOR_MAGENTA}--- 其他参数配置 ---${COLOR_RESET}"
    read_input "节点名称:" NAME "${NAME}" 
      
    DEFAULT_PREFERRED_IPS_CUST_BASE="cloudflare.182682.xyz,joeyblog.net"
    if [ -n "$CFIP" ] && [[ "$CFIP" != "cloudflare.182682.xyz" ]]; then
        DEFAULT_PREFERRED_IPS_CUST_STR="$CFIP,joeyblog.net,cloudflare.182682.xyz"
    elif [ -n "$CFIP" ]; then 
        DEFAULT_PREFERRED_IPS_CUST_STR="$CFIP,joeyblog.net"
    else 
        DEFAULT_PREFERRED_IPS_CUST_STR="$DEFAULT_PREFERRED_IPS_CUST_BASE"
    fi
    DEFAULT_PREFERRED_IPS_CUST_DISPLAY=$(echo "$DEFAULT_PREFERRED_IPS_CUST_STR" | tr ',' '\n' | sort -u | paste -sd, -)
    read_input "请输入优选IP或域名列表 (逗号隔开, 留空则使用: ${DEFAULT_PREFERRED_IPS_CUST_DISPLAY}):" USER_PREFERRED_IPS_INPUT_CUST "${DEFAULT_PREFERRED_IPS_CUST_DISPLAY}"

    PREFERRED_ADD_LIST=() 
    IFS=',' read -r -a temp_array_cust <<< "$USER_PREFERRED_IPS_INPUT_CUST"
    for item in "${temp_array_cust[@]}"; do
      trimmed_item_cust=$(echo "$item" | xargs) 
      if [ -n "$trimmed_item_cust" ]; then 
          PREFERRED_ADD_LIST+=("$trimmed_item_cust")
      fi
    done
      
    if [ ${#PREFERRED_ADD_LIST[@]} -gt 0 ]; then
        CFIP="${PREFERRED_ADD_LIST[0]}" 
        read_input "为主优选IP (${CFIP}) 设置端口 (默认443):" CFPORT "443"
    else
        echo -e "${COLOR_YELLOW}警告: 优选IP列表为空。CFIP 将保持其当前值 '${CFIP}'。${COLOR_RESET}"
        if [ -z "$CFIP" ]; then CFPORT=""; else CFPORT="443"; fi # Ensure CFPORT is set if CFIP exists or reset if CFIP becomes empty
    fi

    echo -e "${COLOR_MAGENTA}--- Telegram推送配置 (可选) ---${COLOR_RESET}"
    read_input "Telegram Chat ID (可选):" CHAT_ID ""
    if [ -n "$CHAT_ID" ]; then 
      read_input "Telegram Bot Token (可选,需与Chat ID一同填写):" BOT_TOKEN ""
    else
      BOT_TOKEN="" 
    fi
    echo -e "${COLOR_MAGENTA}--- 节点信息上传 (可选) ---${COLOR_RESET}"
    read_input "节点信息上传 URL (可选, merge-sub 地址):" UPLOAD_URL ""
    
    run_deployment
    ;;
  [Qq]*) 
    echo -e "${COLOR_GREEN}已退出向导。感谢使用!${COLOR_RESET}"
    exit 0
    ;;
  *) 
    echo -e "${COLOR_RED}无效选项，将执行推荐安装。${COLOR_RESET}"
    # Fallback to recommended installation for any other input
    echo
    print_header "推荐安装模式 (默认执行)" "${COLOR_MAGENTA}" 
    echo -e "${COLOR_CYAN}此模式将使用最简配置。节点名称默认为 'ibm'。${COLOR_RESET}"
    echo
    handle_uuid_generation 
    
    DEFAULT_PREFERRED_IPS_REC="cloudflare.182682.xyz,joeyblog.net"
    read_input "请输入优选IP或域名列表 (逗号隔开, 留空则使用默认: ${DEFAULT_PREFERRED_IPS_REC}):" USER_PREFERRED_IPS_INPUT_REC "${DEFAULT_PREFERRED_IPS_REC}"
    
    PREFERRED_ADD_LIST=() 
    IFS=',' read -r -a temp_array_rec <<< "$USER_PREFERRED_IPS_INPUT_REC"
    for item in "${temp_array_rec[@]}"; do
      trimmed_item=$(echo "$item" | xargs) 
      if [ -n "$trimmed_item" ]; then 
          PREFERRED_ADD_LIST+=("$trimmed_item")
      fi
    done

    NEZHA_SERVER=""; NEZHA_PORT=""; NEZHA_KEY=""
    ARGO_DOMAIN=""; ARGO_AUTH=""
    NAME="ibm" 
    if [ ${#PREFERRED_ADD_LIST[@]} -gt 0 ]; then
        CFIP="${PREFERRED_ADD_LIST[0]}" 
    else
        CFIP="cloudflare.182682.xyz" 
    fi
    CFPORT="443" 
    CHAT_ID=""; BOT_TOKEN=""; UPLOAD_URL=""
    run_deployment
    ;;
esac
exit 0
