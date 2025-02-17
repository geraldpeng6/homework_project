#!/bin/bash

# generate.sh
# 用于在指定目录下随机生成1-25个作业文件，文件名格式为 homeworkXX

# 默认配置
DEFAULT_HOMEWORK_DIR="/homework"
LOG_FILE="./generate_homework_files.log"

# 学生学号范围
MIN_ID=1
MAX_ID=50

# 功能函数

# 显示帮助信息
usage() {
    echo "Usage: $0 [-d homework_directory] [-l log_file] [-c]"
    echo "  -d homework_directory : 指定作业目录，默认为$DEFAULT_HOMEWORK_DIR"
    echo "  -l log_file           : 指定日志文件，默认为$LOG_FILE"
    echo "  -c                    : 覆盖已存在的同名文件"
    echo "  -h                    : 显示帮助信息"
    exit 1
}

# 日志记录函数
log() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') : $message" >> "$LOG_FILE"
}

# 解析命令行参数
COVER=false
while getopts "d:l:ch" opt; do
    case "$opt" in
        d) HOMEWORK_DIR="$OPTARG" ;;
        l) LOG_FILE="$OPTARG" ;;
        c) COVER=true ;;
        h) usage ;;
        *) usage ;;
    esac
done

# 设置默认值
HOMEWORK_DIR=${HOMEWORK_DIR:-$DEFAULT_HOMEWORK_DIR}

# 检查并创建作业目录
if [ ! -d "$HOMEWORK_DIR" ]; then
    mkdir -p "$HOMEWORK_DIR" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "Error: 无法创建目录 $HOMEWORK_DIR"
        log "Failed to create directory: $HOMEWORK_DIR"
        exit 1
    fi
    log "Created directory: $HOMEWORK_DIR"
fi

# 增加对作业目录的读写权限
chmod u+rw "$HOMEWORK_DIR"
if [ $? -ne 0 ]; then
    echo "Error: 无法增加目录 $HOMEWORK_DIR 的读写权限"
    log "Failed to set read/write permissions for directory: $HOMEWORK_DIR"
    exit 1
fi

# 检查作业目录的写权限
if [ ! -w "$HOMEWORK_DIR" ]; then
    echo "Error: 没有写入目录 $HOMEWORK_DIR 的权限"
    log "Insufficient permissions to write to directory: $HOMEWORK_DIR"
    exit 1
fi

log "脚本开始执行"
log "作业目录: $HOMEWORK_DIR"

# 生成随机数量的作业文件 (1-25)
NUM_FILES=$((RANDOM % 25 + 1))
log "计划生成作业文件数量: $NUM_FILES"

# 生成1到50的学号数组
ALL_IDS=($(seq $MIN_ID $MAX_ID))

# 随机选择NUM_FILES个唯一的学号
SELECTED_IDS=()
while [ "${#SELECTED_IDS[@]}" -lt "$NUM_FILES" ]; do
    # 生成一个随机学号
    RANDOM_ID=$((RANDOM % MAX_ID + MIN_ID))
    # 确保学号唯一
    if [[ ! " ${SELECTED_IDS[@]} " =~ " ${RANDOM_ID} " ]]; then
        SELECTED_IDS+=("$RANDOM_ID")
    fi
done

# 将所有选定的学号记录到日志中
log "选择的学号: ${SELECTED_IDS[*]}"

# 生成作业文件
for id in "${SELECTED_IDS[@]}"; do
    # 格式化学号为两位数
    printf -v STUDENT_ID "%02d" "$id"
    FILENAME="homework${STUDENT_ID}"

    # 随机添加特殊字符和改变大小写
    filename_chars=($(echo "$FILENAME" | grep -o .))
    FILENAME=""
    for char in "${filename_chars[@]}"; do
        # 随机决定是否添加特殊字符
        if [ $((RANDOM % 2)) -eq 0 ]; then
            special_chars=('_' '@' '#' '$' '%')
            random_special=${special_chars[$((RANDOM % ${#special_chars[@]}))]}
            FILENAME+="$random_special"
        fi
        
        # 随机决定是否改变大小写
        if [ $((RANDOM % 2)) -eq 0 ] && [[ "$char" =~ [a-zA-Z] ]]; then
            if [[ "$char" =~ [a-z] ]]; then
                FILENAME+="${char^^}" # 转大写
            else
                FILENAME+="${char,,}" # 转小写
            fi
        else
            FILENAME+="$char"
        fi
    done

    FILEPATH="$HOMEWORK_DIR/$FILENAME"

    # 处理文件名以便检查是否存在
    clean_name=$(echo "$FILENAME" | tr -cd "[:alnum:]" | tr "[:upper:]" "[:lower:]")

    # 检查文件是否存在并覆盖
    if [ -e "$FILEPATH" ]; then
        echo "覆盖已存在的文件: $FILENAME"
        echo "这是作业文件的模拟内容。" > "$FILEPATH"
        log "覆盖并生成文件: $FILEPATH"
    else
        # 创建文件并添加一些模拟内容
        echo "这是学生学号 $id 的作业。" > "$FILEPATH"
        log "生成文件: $FILEPATH"
    fi
done

log "脚本执行完成，生成了 $NUM_FILES 个作业文件。"

echo "已在 $HOMEWORK_DIR 生成 $NUM_FILES 个作业文件。"
if [ "$COVER" = true ]; then
    echo "已覆盖存在的同名文件。"
fi
echo "日志记录在 $LOG_FILE"
