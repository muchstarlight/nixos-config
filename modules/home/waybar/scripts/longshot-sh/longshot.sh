#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_PYTHON="$SCRIPT_DIR/venv/bin/python"

# =================配置区=================
CONFIG_DIR="$HOME/.cache/longshot-sh"
mkdir -p "$CONFIG_DIR"

FILE_MODE="$CONFIG_DIR/mode"       # PREVIEW / EDIT / SAVE
FILE_BACKEND="$CONFIG_DIR/backend" # WF / GRIM

# 初始化默认值
[ ! -f "$FILE_MODE" ] && echo "PREVIEW" > "$FILE_MODE"
[ ! -f "$FILE_BACKEND" ] && echo "WF" > "$FILE_BACKEND"

# =================语言资源=================
if env | grep -q "zh_CN"; then
    TXT_TITLE_WF="缓慢滚动，回车停止"
    TXT_TITLE_GRIM="记住截图末尾位置"
    
    TXT_START="📷 选择截图区域"
    TXT_SETTING="⚙️ 设置"
    TXT_EXIT="❌ 退出"
    
    TXT_BACK="🔙 返回主菜单"
    TXT_SW_BACKEND="📹 切换后端"
    TXT_SW_ACTION="🛠 切换动作"
    TXT_PROMPT_ACTION="请选择截图后的动作:"
    
    TXT_ST_WF="流式录制 (wf-recorder)"
    TXT_ST_GRIM="分段截图 (grim)"
    
    TXT_ST_PRE="预览 (imv)"
    TXT_ST_EDIT="编辑 (satty)"
    TXT_ST_SAVE="仅保存"

    # 初始化提示
    TXT_MSG_INIT="首次运行，正在初始化环境..."
    TXT_MSG_SETUP_DONE="环境初始化完成！"
    TXT_ERR_SETUP="环境安装失败，请查看 /tmp/longshot_setup.log"
    TXT_ERR_NO_SETUP="未找到 setup.sh 文件"

    # 新增：依赖缺失提示
    TXT_ERR_DEP_TITLE="缺少系统依赖"
    TXT_ERR_DEP_MSG="请安装以下包："
else
    TXT_TITLE_WF="Scroll Slowly, Enter to Stop"
    TXT_TITLE_GRIM="Remember End Position"
    
    TXT_START="📷 Select Area"
    TXT_SETTING="⚙️ Settings"
    TXT_EXIT="❌ Exit"
    
    TXT_BACK="🔙 Back"
    TXT_SW_BACKEND="📹 Switch Backend"
    TXT_SW_ACTION="🛠 Switch Action"
    TXT_PROMPT_ACTION="Select action after capture:"
    
    TXT_ST_WF="Stream (wf-recorder)"
    TXT_ST_GRIM="Manual (grim)"
    
    TXT_ST_PRE="Preview"
    TXT_ST_EDIT="Edit"
    TXT_ST_SAVE="Save Only"

    # Init messages
    TXT_MSG_INIT="First run, initializing environment..."
    TXT_MSG_SETUP_DONE="Environment initialized!"
    TXT_ERR_SETUP="Setup failed, check /tmp/longshot_setup.log"
    TXT_ERR_NO_SETUP="setup.sh not found"

    # New: Dependency error
    TXT_ERR_DEP_TITLE="Missing Dependencies"
    TXT_ERR_DEP_MSG="Please install:"
fi

# ================= 1. 系统依赖检测 (新增) =================
# 检测核心工具: wf-recorder, grim, slurp, imagemagick (magick)
REQUIRED_TOOLS=("wf-recorder" "grim" "slurp" "magick" "wl-copy")
MISSING_TOOLS=()

for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        MISSING_TOOLS+=("$tool")
    fi
done

if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
    # 构建错误信息
    MSG="${TXT_ERR_DEP_MSG} ${MISSING_TOOLS[*]}"
    
    # 尝试发送通知
    if command -v notify-send &> /dev/null; then
        notify-send -u critical "$TXT_ERR_DEP_TITLE" "$MSG"
    else
        # 如果连 notify-send 都没有，这就很尴尬了，尝试用 echo 输出到 stderr
        echo "❌ $TXT_ERR_DEP_TITLE: $MSG" >&2
    fi
    exit 1
fi

# ================= 2. Python 环境自动检测与修复 =================
if [ ! -f "$VENV_PYTHON" ]; then
    notify-send -t 5000 "Longshot" "$TXT_MSG_INIT"
    
    if [ -f "$SCRIPT_DIR/setup.sh" ]; then
        chmod +x "$SCRIPT_DIR/setup.sh"
        "$SCRIPT_DIR/setup.sh" > /tmp/longshot_setup.log 2>&1
        
        if [ ! -f "$VENV_PYTHON" ]; then
            notify-send -u critical "Error" "$TXT_ERR_SETUP"
            exit 1
        else
            notify-send -t 3000 "Longshot" "$TXT_MSG_SETUP_DONE"
        fi
    else
        notify-send -u critical "Error" "$TXT_ERR_NO_SETUP"
        exit 1
    fi
fi

# =================菜单工具=================
if command -v fuzzel &> /dev/null; then
    MENU_CMD="fuzzel -d --anchor top --y-margin 20 --width 35 --lines 4"
elif command -v wofi &> /dev/null; then
    MENU_CMD="wofi -d -i -p Longshot"
else
    MENU_CMD="rofi -dmenu"
fi

# =================主循环=================
while true; do
    # 1. 读取当前配置
    CUR_MODE=$(cat "$FILE_MODE")
    CUR_BACKEND=$(cat "$FILE_BACKEND")
    
    # 2. 动态生成 UI 文本
    CURRENT_TITLE=""
    if [ "$CUR_BACKEND" == "WF" ]; then
        CURRENT_TITLE="$TXT_TITLE_WF"
    else
        CURRENT_TITLE="$TXT_TITLE_GRIM"
    fi

    LBL_MODE=""
    case "$CUR_MODE" in
        "PREVIEW") LBL_MODE="$TXT_ST_PRE" ;;
        "EDIT")    LBL_MODE="$TXT_ST_EDIT" ;;
        "SAVE")    LBL_MODE="$TXT_ST_SAVE" ;;
    esac
    
    LBL_BACKEND=""
    case "$CUR_BACKEND" in
        "WF")   LBL_BACKEND="$TXT_ST_WF" ;;
        "GRIM") LBL_BACKEND="$TXT_ST_GRIM" ;;
    esac

    # 3. 显示主菜单
    OPTION_START="$TXT_START"
    OPTION_SETTING="$TXT_SETTING  [$LBL_BACKEND | $LBL_MODE]"
    OPTION_EXIT="$TXT_EXIT"

    if [[ "$MENU_CMD" == *"fuzzel"* ]] || [[ "$MENU_CMD" == *"rofi"* ]]; then
        CHOICE=$(echo -e "$OPTION_START\n$OPTION_SETTING\n$OPTION_EXIT" | $MENU_CMD -p "$CURRENT_TITLE")
    else
        CHOICE=$(echo -e "$OPTION_START\n$OPTION_SETTING\n$OPTION_EXIT" | $MENU_CMD)
    fi

    # 4. 处理选择
    if [[ "$CHOICE" == *"$TXT_START"* ]]; then
        # === 启动后端 ===
        if [ "$CUR_BACKEND" == "WF" ]; then
            exec "$SCRIPT_DIR/longshot-wf-recorder.sh"
        else
            exec "$SCRIPT_DIR/longshot-grim.sh"
        fi
        break 

    elif [[ "$CHOICE" == *"$TXT_SETTING"* ]]; then
        # === 设置菜单循环 ===
        while true; do
            S_MODE=$(cat "$FILE_MODE")
            S_BACK=$(cat "$FILE_BACKEND")
            
            D_BACK=""; [ "$S_BACK" == "WF" ] && D_BACK="$TXT_ST_WF" || D_BACK="$TXT_ST_GRIM"
            D_MODE=""; 
            case "$S_MODE" in
                "PREVIEW") D_MODE="$TXT_ST_PRE" ;;
                "EDIT")    D_MODE="$TXT_ST_EDIT" ;;
                "SAVE")    D_MODE="$TXT_ST_SAVE" ;;
            esac

            ITEM_BACKEND="$TXT_SW_BACKEND [$D_BACK]"
            ITEM_ACTION="$TXT_SW_ACTION [$D_MODE]"
            
            if [[ "$MENU_CMD" == *"fuzzel"* ]] || [[ "$MENU_CMD" == *"rofi"* ]]; then
                S_CHOICE=$(echo -e "$TXT_BACK\n$ITEM_BACKEND\n$ITEM_ACTION" | $MENU_CMD -p "$TXT_SETTING")
            else
                S_CHOICE=$(echo -e "$TXT_BACK\n$ITEM_BACKEND\n$ITEM_ACTION" | $MENU_CMD)
            fi

            if [[ "$S_CHOICE" == *"$TXT_BACK"* ]]; then
                break 
            elif [[ "$S_CHOICE" == *"$TXT_SW_BACKEND"* ]]; then
                if [ "$S_BACK" == "WF" ]; then echo "GRIM" > "$FILE_BACKEND"; else echo "WF" > "$FILE_BACKEND"; fi
            elif [[ "$S_CHOICE" == *"$TXT_SW_ACTION"* ]]; then
                if [[ "$MENU_CMD" == *"fuzzel"* ]] || [[ "$MENU_CMD" == *"rofi"* ]]; then
                    A_CHOICE=$(echo -e "$TXT_ST_PRE\n$TXT_ST_EDIT\n$TXT_ST_SAVE" | $MENU_CMD -p "$TXT_PROMPT_ACTION")
                else
                    A_CHOICE=$(echo -e "$TXT_ST_PRE\n$TXT_ST_EDIT\n$TXT_ST_SAVE" | $MENU_CMD)
                fi
                
                if [[ "$A_CHOICE" == *"$TXT_ST_PRE"* ]]; then echo "PREVIEW" > "$FILE_MODE"; fi
                if [[ "$A_CHOICE" == *"$TXT_ST_EDIT"* ]]; then echo "EDIT" > "$FILE_MODE"; fi
                if [[ "$A_CHOICE" == *"$TXT_ST_SAVE"* ]]; then echo "SAVE" > "$FILE_MODE"; fi
            else
                exit 0
            fi
        done
    else
        exit 0
    fi
done