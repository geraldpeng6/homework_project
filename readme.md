# 作业管理脚本

本项目包含两个主要的 Bash 脚本：`report.sh` 和 `generate.sh`，用于管理学生作业的提交和生成。

## 脚本说明

### report.sh

`report.sh` 用于统计学生作业的提交情况，并生成详细的 HTML 报告。

#### 使用方法

```bash
./report.sh [-d homework_directory] [-o output_directory] [-l log_file] [-t deadline]
```

#### 参数说明

- `-d homework_directory` : 指定作业目录，默认为 `/homework`
- `-o output_directory` : 指定报告输出目录，默认为 `./reports`
- `-l log_file` : 指定日志文件，默认为 `./homework_report.log`
- `-t deadline` : 指定作业截止时间 (格式: YYYY-MM-DD HH:MM:SS)，默认为当天的 23:59:59
- `-h` : 显示帮助信息

### generate.sh

`generate.sh` 用于在指定目录下随机生成 1-25 个作业文件，文件名格式随机。

#### 使用方法

```bash
./generate.sh [-d homework_directory] [-l log_file] [-c]
```

#### 参数说明

- `-d homework_directory` : 指定作业目录，默认为 `/homework`
- `-l log_file` : 指定日志文件，默认为 `./generate_homework_files.log`
- `-c` : 覆盖已存在的同名文件
- `-h` : 显示帮助信息

## 日志记录

每个脚本都会在执行过程中生成日志文件，记录执行的详细信息和可能的错误信息。

## 注意事项

- 确保在执行脚本时具有相应目录的读写权限。
- 在使用 `generate.sh` 时，若选择覆盖模式（`-c`），将会覆盖已存在的同名文件。
