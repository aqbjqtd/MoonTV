@echo off
chcp 65001 >nul

:: MoonTV Docker 镜像构建脚本 for Windows
:: 用法: build-docker.bat [tag]

setlocal enabledelayedexpansion

:: 默认参数
set IMAGE_NAME=aqbjqtd/moontv
set DEFAULT_TAG=test

if "%~1"=="" (
    set TAG=%DEFAULT_TAG%
) else (
    set TAG=%~1
)

echo.
echo MoonTV Docker 镜像构建工具
echo 目标镜像: %IMAGE_NAME%:%TAG%
echo.

:: 检查 Docker 是否可用
:check_docker
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker 未安装，请先安装 Docker
    exit /b 1
)

docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker 守护进程未运行，请启动 Docker
    exit /b 1
)

echo [INFO] Docker 检查通过
echo.

:: 构建镜像
:build_image
echo [INFO] 开始构建 Docker 镜像: %IMAGE_NAME%:%TAG%

:: 使用 BuildKit 进行构建
set "DOCKER_BUILDKIT=1"
docker build ^
    --tag "%IMAGE_NAME%:%TAG%" ^
    --build-arg BUILDKIT_INLINE_CACHE=1 ^
    --progress=plain ^
    .

if %errorlevel% neq 0 (
    echo [ERROR] 镜像构建失败
    exit /b 1
)

echo [SUCCESS] 镜像构建成功: %IMAGE_NAME%:%TAG%
echo.

:: 显示镜像信息
:show_image_info
echo [INFO] 镜像构建完成
echo.
echo 📦 镜像详情:
echo 名称: %IMAGE_NAME%:%TAG%

for /f "tokens=3" %%i in ('docker images --format "{{.Size}}" "%IMAGE_NAME%:%TAG%"') do (
    echo 大小: %%i
)

echo.
echo 🚀 运行命令:
echo docker run -d -p 3000:3000 --name moontv %IMAGE_NAME%:%TAG%
echo.
echo 🔍 查看日志:
echo docker logs moontv
echo.
echo 🛑 停止容器:
echo docker stop moontv ^&^& docker rm moontv
echo.

:: 询问是否推送镜像
:push_prompt
set /p "PUSH=是否推送镜像到 Docker Hub? (y/N): "
if /i "!PUSH!"=="y" (
    goto push_image
) else (
    goto finish
)

:: 推送镜像
:push_image
echo [INFO] 登录 Docker Hub...
docker login

if %errorlevel% neq 0 (
    echo [ERROR] Docker Hub 登录失败
    exit /b 1
)

echo [INFO] 推送镜像: %IMAGE_NAME%:%TAG%
docker push "%IMAGE_NAME%:%TAG%"

if %errorlevel% neq 0 (
    echo [ERROR] 镜像推送失败
    exit /b 1
)

echo [SUCCESS] 镜像推送成功
echo.
echo 镜像信息:
echo - 名称: %IMAGE_NAME%:%TAG%
echo - 拉取命令: docker pull %IMAGE_NAME%:%TAG%
echo.

:finish
echo [SUCCESS] 所有操作完成!
echo.
pause
exit /b 0