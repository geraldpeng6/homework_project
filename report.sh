#!/bin/bash

# homework_report.sh
# 用于自动化统计学生作业提交情况并生成详细报告

# 默认配置
DEFAULT_HOMEWORK_DIR="/homework"
DEFAULT_REPORT_DIR="./reports"
LOG_FILE="./homework_report.log"

# 动态生成当天的截止时间为23:59:59
DEADLINE=$(date -d "23:59:59" "+%Y-%m-%d %H:%M:%S")

# 学生学号范围
MIN_ID=1
MAX_ID=50

# 功能函数

# 显示帮助信息
usage() {
    echo "Usage: $0 [-d homework_directory] [-o output_directory] [-l log_file] [-t deadline]"
    echo "  -d homework_directory : 指定作业目录，默认为$DEFAULT_HOMEWORK_DIR"
    echo "  -o output_directory   : 指定报告输出目录，默认为$DEFAULT_REPORT_DIR"
    echo "  -l log_file           : 指定日志文件，默认为$LOG_FILE"
    echo "  -t deadline           : 指定作业截止时间 (格式: YYYY-MM-DD HH:MM:SS)，默认为当天的23:59:59"
    exit 1
}

# 日志记录函数
log() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') : $message" >> "$LOG_FILE"
}

# 检查并创建目录
check_create_dir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" 2>/dev/null
        if [ $? -ne 0 ]; then
            echo "Error: 无法创建目录 $dir"
            log "Failed to create directory: $dir"
            exit 1
        fi
        log "Created directory: $dir"
    fi
}

# 检查权限
check_permissions() {
    local dir="$1"
    if [ ! -r "$dir" ]; then
        echo "Error: 没有读取目录 $dir 的权限"
        log "Insufficient permissions to read directory: $dir"
        exit 1
    fi
}

# 解析命令行参数
while getopts "d:o:l:t:h" opt; do
    case "$opt" in
        d) HOMEWORK_DIR="$OPTARG" ;;
        o) OUTPUT_DIR="$OPTARG" ;;
        l) LOG_FILE="$OPTARG" ;;
        t) DEADLINE="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# 设置默认值
HOMEWORK_DIR=${HOMEWORK_DIR:-$DEFAULT_HOMEWORK_DIR}
OUTPUT_DIR=${OUTPUT_DIR:-$DEFAULT_REPORT_DIR}

# 检查并创建作业目录和报告输出目录
check_create_dir "$HOMEWORK_DIR"
check_create_dir "$OUTPUT_DIR"

# 检查作业目录的取权限
check_permissions "$HOMEWORK_DIR"

log "脚本开始执行"
log "作业目录: $HOMEWORK_DIR"
log "报告输出目录: $OUTPUT_DIR"
log "截止时间: $DEADLINE"

# 获取截止时间的时间戳
DEADLINE_TS=$(date -d "$DEADLINE" +%s)
if [ $? -ne 0 ]; then
    echo "Error: 无法解析截止时间 '$DEADLINE'"
    log "Invalid deadline format: $DEADLINE"
    exit 1
fi

# 初始化学生学号列表
declare -a all_students
for ((i=MIN_ID; i<=MAX_ID; i++)); do
    all_students+=("$i")
done

# 初始化提交情况
declare -A submitted_students
declare -A submission_times
declare -a late_students

# 扫描作业文件
log "扫描作业文件"
temp_file=$(mktemp)
find "$HOMEWORK_DIR" -type f -exec bash -c '
    filename=$(basename "$1")
    # 去除特殊字符和空格,只保留字母和数字
    clean_name=$(echo "$filename" | tr -cd "[:alnum:]" | tr "[:upper:]" "[:lower:]")
    if [[ "$clean_name" =~ homework ]]; then
        echo "$1"
    fi
' bash {} \; > "$temp_file"

while IFS= read -r file; do
    filename=$(basename "$file")
    # 去除特殊字符和空格,只保留字母和数字
    filename=$(echo "$filename" | tr -cd "[:alnum:]" | tr "[:upper:]" "[:lower:]")
    
    # 在日志中打印处理后的文件名
    log "处理后的文件名: $filename"
    
    # 使用正则表达式提取学号
    if [[ "$filename" =~ homework([0-9]{1,2}) ]]; then
        student_id="${BASH_REMATCH[1]}"
        # 去掉学号的前导零
        student_id=$((10#$student_id))
        # 确保学号在1-50范围内
        if (( student_id >= MIN_ID && student_id <= MAX_ID )); then
            submitted_students["$student_id"]=1
            # 获取文件修改时间
            mod_time=$(stat -c %Y "$file")
            submission_times["$student_id"]="$mod_time"
            # 检查是否迟交
            if (( mod_time > DEADLINE_TS )); then
                late_students+=("$student_id")
            fi
            log "学生 $student_id 提交作业，时间戳: $mod_time"
        else
            log "忽略无效学号的文件: $filename"
        fi
    else
        log "文件名不符合规则，忽略: $filename"
    fi
done < "$temp_file"

# 清理临时文件
rm -f "$temp_file"

# 统计已提交人数
submitted_count=${#submitted_students[@]}
log "已提交作业人数: $submitted_count"

# 列出未提交作业的学生学号
declare -a not_submitted_students
for student in "${all_students[@]}"; do
    if [ -z "${submitted_students[$student]}" ]; then
        not_submitted_students+=("$student")
    fi
done
not_submitted_count=${#not_submitted_students[@]}
log "未提交作业人数: $not_submitted_count"

# 生成HTML报告
report_file="$OUTPUT_DIR/homework_report_$(date '+%Y%m%d%H%M%S').html"
log "生成HTML报告: $report_file"

# 对已提交的学生学号进行排序
sorted_submitted_students=($(for student in "${!submitted_students[@]}"; do echo "$student"; done | sort -n))

# 对未提交的学生学号进行排序
sorted_not_submitted_students=($(for student in "${not_submitted_students[@]}"; do echo "$student"; done | sort -n))

cat <<EOF > "$report_file"
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <title>学生作业提交报告</title>
    <style>
        table { width: 100%; border-collapse: collapse; }
        th, td { border: 1px solid #ddd; padding: 8px; }
        th { background-color: #f2f2f2; }
        .late { background-color: #ffcccc; }
    </style>
</head>
<body>
    <h1>学生作业提交报告</h1>
    <p>截止时间: $DEADLINE</p>
    <h2>提交情况统计</h2>
    <ul>
        <li>已提交作业人数: $submitted_count</li>
        <li>未提交作业人数: $not_submitted_count</li>
        <li>迟交作业人数: ${#late_students[@]}</li>
    </ul>

    <h2>已提交作业的学生</h2>
    <table>
        <tr><th>学号</th><th>提交时间</th></tr>
EOF

for student in "${sorted_submitted_students[@]}"; do
    submit_ts=${submission_times[$student]}
    submit_time=$(date -d "@$submit_ts" "+%Y-%m-%d %H:%M:%S")
    if (( submit_ts > DEADLINE_TS )); then
        echo "        <tr class=\"late\"><td>$student</td><td>$submit_time (迟交)</td></tr>" >> "$report_file"
    else
        echo "        <tr><td>$student</td><td>$submit_time</td></tr>" >> "$report_file"
    fi
done

cat <<EOF >> "$report_file"
    </table>

    <h2>未提交作业的学生</h2>
EOF

if [ ${#sorted_not_submitted_students[@]} -eq 0 ]; then
    echo "    <p>所有学生均已提交作业。</p>" >> "$report_file"
else
    echo "    <ul>" >> "$report_file"
    for student in "${sorted_not_submitted_students[@]}"; do
        echo "        <li>学号: $student</li>" >> "$report_file"
    done
    echo "    </ul>" >> "$report_file"
fi

cat <<EOF >> "$report_file"
    <h2>迟交作业的学生</h2>
EOF

if [ ${#late_students[@]} -eq 0 ]; then
    echo "    <p>没有学生迟交作业。</p>" >> "$report_file"
else
    echo "    <ul>" >> "$report_file"
    for student in "${late_students[@]}"; do
        submit_ts=${submission_times[$student]}
        submit_time=$(date -d "@$submit_ts" "+%Y-%m-%d %H:%M:%S")
        echo "        <li>学号: $student，提交时间: $submit_time</li>" >> "$report_file"
    done
    echo "    </ul>" >> "$report_file"
fi

cat <<EOF >> "$report_file"
</body>
</html>
EOF

log "HTML报告生成成功"

echo "报告已生成: $report_file"
log "脚本执行完成"

exit 0 