#!/bin/bash
# =================================================================
# MoonTV 蓝绿部署脚本 v4.0.0
# 功能: 零停机时间部署，自动健康检查，快速回滚
# 使用: ./blue-green-deploy.sh [环境] [版本] [选项]
# =================================================================

set -euo pipefail

# 脚本配置
readonly SCRIPT_NAME="MoonTV Blue-Green Deploy"
readonly SCRIPT_VERSION="4.0.0"
readonly LOG_FILE="/var/log/moontv-blue-green-deploy.log"

# 颜色配置
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# 全局变量
ENVIRONMENT=""
VERSION=""
NAMESPACE="moontv"
DRY_RUN=false
SKIP_HEALTH_CHECK=false
FORCE_DEPLOY=false
ROLLBACK=false
BACKUP_ENABLED=true
HEALTH_CHECK_TIMEOUT=300
HEALTH_CHECK_INTERVAL=10
TRAFFIC_SWITCH_DELAY=30

# 函数: 日志记录
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case "$level" in
        "INFO")
            echo -e "${GREEN}[INFO]${NC} ${timestamp} - $message" | tee -a "$LOG_FILE"
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} ${timestamp} - $message" | tee -a "$LOG_FILE"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} ${timestamp} - $message" | tee -a "$LOG_FILE"
            ;;
        "DEBUG")
            echo -e "${BLUE}[DEBUG]${NC} ${timestamp} - $message" | tee -a "$LOG_FILE"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} ${timestamp} - $message" | tee -a "$LOG_FILE"
            ;;
    esac
}

# 函数: 显示帮助信息
show_help() {
    cat << EOF
$SCRIPT_NAME v$SCRIPT_VERSION

用法:
    $0 [选项] <环境> <版本>

参数:
    环境        部署环境 (dev/staging/prod)
    版本        部署版本号 (如: v4.0.0)

选项:
    -h, --help              显示此帮助信息
    -v, --version           显示版本信息
    -n, --namespace <ns>    指定命名空间 (默认: moontv)
    -d, --dry-run           模拟运行，不执行实际部署
    -s, --skip-health       跳过健康检查
    -f, --force             强制部署，跳过安全检查
    -r, --rollback          回滚到上一个版本
    --no-backup             禁用备份
    --health-timeout <sec>  健康检查超时时间 (默认: 300秒)
    --health-interval <sec> 健康检查间隔 (默认: 10秒)
    --traffic-delay <sec>   流量切换延迟 (默认: 30秒)

示例:
    $0 staging v4.0.0                    # 基础部署
    $0 production v4.0.1 --dry-run       # 模拟部署
    $0 production v4.0.0 --rollback      # 回滚部署
    $0 staging v4.0.0 --skip-health      # 跳过健康检查

环境变量:
    KUBECONFIG             Kubernetes配置文件路径
    DOCKER_REGISTRY        Docker镜像仓库地址
    SLACK_WEBHOOK_URL      Slack通知Webhook地址

EOF
}

# 函数: 检查依赖
check_dependencies() {
    log "INFO" "检查系统依赖..."

    local missing_deps=()

    # 检查kubectl
    if ! command -v kubectl &> /dev/null; then
        missing_deps+=("kubectl")
    fi

    # 检查docker
    if ! command -v docker &> /dev/null; then
        missing_deps+=("docker")
    fi

    # 检查curl
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi

    # 检查jq
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi

    if [ ${#missing_deps[@]} -ne 0 ]; then
        log "ERROR" "缺少依赖: ${missing_deps[*]}"
        exit 1
    fi

    # 检查Kubernetes连接
    if ! kubectl cluster-info &> /dev/null; then
        log "ERROR" "无法连接到Kubernetes集群"
        exit 1
    fi

    log "SUCCESS" "依赖检查通过"
}

# 函数: 参数验证
validate_arguments() {
    log "INFO" "验证部署参数..."

    # 验证环境
    if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod|production)$ ]]; then
        log "ERROR" "无效的环境: $ENVIRONMENT"
        log "ERROR" "支持的环境: dev, staging, prod, production"
        exit 1
    fi

    # 验证版本格式
    if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log "ERROR" "无效的版本格式: $VERSION"
        log "ERROR" "版本格式应为: v1.2.3"
        exit 1
    fi

    # 验证命名空间
    if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
        log "ERROR" "命名空间不存在: $NAMESPACE"
        exit 1
    fi

    # 验证镜像是否存在
    local image_name="${DOCKER_REGISTRY:-ghcr.io/your-repo}/moontv:${VERSION}"
    if ! docker pull "$image_name" &> /dev/null; then
        log "ERROR" "镜像不存在或无法拉取: $image_name"
        exit 1
    fi

    log "SUCCESS" "参数验证通过"
}

# 函数: 获取当前活跃颜色
get_active_color() {
    local active_color=$(kubectl get service moontv-service -n "$NAMESPACE" -o jsonpath='{.spec.selector.color}' 2>/dev/null || echo "")

    if [[ -z "$active_color" ]]; then
        log "WARN" "无法获取当前活跃颜色，默认为blue"
        echo "blue"
    else
        echo "$active_color"
    fi
}

# 函数: 获取待部署颜色
get_next_color() {
    local active_color=$(get_active_color)

    if [[ "$active_color" == "blue" ]]; then
        echo "green"
    else
        echo "blue"
    fi
}

# 函数: 创建备份
create_backup() {
    if [[ "$BACKUP_ENABLED" == "true" ]]; then
        log "INFO" "创建当前环境备份..."

        local backup_name="moontv-backup-$(date +%Y%m%d-%H%M%S)"
        local backup_dir="/tmp/moontv-backups/$backup_name"

        mkdir -p "$backup_dir"

        # 备份当前部署配置
        kubectl get deployment,service,configmap,secret -n "$NAMESPACE" -o yaml > "$backup_dir/k8s-backup.yaml"

        # 备份应用数据（如果有）
        if kubectl get pvc moontv-data-pvc -n "$NAMESPACE" &> /dev/null; then
            log "INFO" "备份应用数据..."
            kubectl exec -n "$NAMESPACE" deployment/moontv-deployment -- tar -czf /tmp/data-backup.tar.gz /app/data || true
            kubectl cp -n "$NAMESPACE" deployment/moontv-deployment:/tmp/data-backup.tar.gz "$backup_dir/" || true
        fi

        log "SUCCESS" "备份创建完成: $backup_dir"
    else
        log "INFO" "备份已禁用，跳过备份创建"
    fi
}

# 函数: 部署新版本
deploy_new_version() {
    local deploy_color="$1"
    local deploy_name="moontv-deployment-${deploy_color}"

    log "INFO" "部署新版本到${deploy_color}环境..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] 模拟部署: $deploy_name"
        return 0
    fi

    # 创建或更新部署
    cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${deploy_name}
  namespace: ${NAMESPACE}
  labels:
    app.kubernetes.io/name: moontv
    app.kubernetes.io/component: app
    color: ${deploy_color}
    version: ${VERSION}
spec:
  replicas: 3
  selector:
    matchLabels:
      app.kubernetes.io/name: moontv
      app.kubernetes.io/component: app
      color: ${deploy_color}
  template:
    metadata:
      labels:
        app.kubernetes.io/name: moontv
        app.kubernetes.io/component: app
        color: ${deploy_color}
        version: ${VERSION}
    spec:
      containers:
      - name: moontv-app
        image: ${DOCKER_REGISTRY:-ghcr.io/your-repo}/moontv:${VERSION}
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "production"
        - name: APP_VERSION
          value: "${VERSION}"
        - name: DEPLOY_COLOR
          value: "${deploy_color}"
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /api/health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /api/ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 10
EOF

    # 等待部署完成
    log "INFO" "等待部署完成..."
    kubectl rollout status deployment/"$deploy_name" -n "$NAMESPACE" --timeout=600s

    log "SUCCESS" "新版本部署完成"
}

# 函数: 健康检查
health_check() {
    local deploy_color="$1"
    local service_name="moontv-service-${deploy_color}"

    if [[ "$SKIP_HEALTH_CHECK" == "true" ]]; then
        log "INFO" "跳过健康检查"
        return 0
    fi

    log "INFO" "开始健康检查..."

    local start_time=$(date +%s)
    local end_time=$((start_time + HEALTH_CHECK_TIMEOUT))

    while [[ $(date +%s) -lt $end_time ]]; do
        # 检查Pod状态
        local ready_pods=$(kubectl get pods -n "$NAMESPACE" -l color="$deploy_color" --field-selector=status.phase=Running --no-headers | wc -l)
        local total_pods=$(kubectl get pods -n "$NAMESPACE" -l color="$deploy_color" --no-headers | wc -l)

        if [[ $ready_pods -eq $total_pods ]] && [[ $total_pods -gt 0 ]]; then
            log "INFO" "所有Pod就绪: $ready_pods/$total_pods"
        else
            log "WARN" "Pod未全部就绪: $ready_pods/$total_pods"
            sleep "$HEALTH_CHECK_INTERVAL"
            continue
        fi

        # 检查服务健康状态
        local pod_name=$(kubectl get pods -n "$NAMESPACE" -l color="$deploy_color" -o jsonpath='{.items[0].metadata.name}')

        if kubectl exec -n "$NAMESPACE" "$pod_name" -- curl -f http://localhost:3000/api/health &> /dev/null; then
            log "SUCCESS" "健康检查通过"
            return 0
        fi

        log "WARN" "健康检查失败，等待重试..."
        sleep "$HEALTH_CHECK_INTERVAL"
    done

    log "ERROR" "健康检查超时"
    return 1
}

# 函数: 切换流量
switch_traffic() {
    local new_color="$1"
    local old_color=$(get_active_color)

    log "INFO" "切换流量从${old_color}到${new_color}..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] 模拟流量切换"
        return 0
    fi

    # 更新服务选择器
    kubectl patch service moontv-service -n "$NAMESPACE" -p '{"spec":{"selector":{"color":"'$new_color'"}}}'

    # 等待流量切换生效
    log "INFO" "等待流量切换生效..."
    sleep "$TRAFFIC_SWITCH_DELAY"

    # 验证流量切换
    if curl -f http://moontv-service."$NAMESPACE".svc.cluster.local/api/health &> /dev/null; then
        log "SUCCESS" "流量切换成功"
        return 0
    else
        log "ERROR" "流量切换失败"
        return 1
    fi
}

# 函数: 清理旧版本
cleanup_old_version() {
    local old_color="$1"
    local old_deployment="moontv-deployment-${old_color}"

    log "INFO" "清理旧版本: $old_deployment"

    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] 模拟清理: $old_deployment"
        return 0
    fi

    # 删除旧部署
    kubectl delete deployment "$old_deployment" -n "$NAMESPACE" --ignore-not-found=true

    log "SUCCESS" "旧版本清理完成"
}

# 函数: 回滚部署
rollback_deployment() {
    log "WARN" "开始回滚部署..."

    local current_color=$(get_active_color)
    local rollback_color

    if [[ "$current_color" == "blue" ]]; then
        rollback_color="green"
    else
        rollback_color="blue"
    fi

    # 检查回滚目标是否存在
    if ! kubectl get deployment "moontv-deployment-${rollback_color}" -n "$NAMESPACE" &> /dev/null; then
        log "ERROR" "回滚目标不存在: moontv-deployment-${rollback_color}"
        exit 1
    fi

    # 切换流量
    if switch_traffic "$rollback_color"; then
        log "SUCCESS" "回滚成功"
        # 清理失败的部署
        cleanup_old_version "$current_color"
    else
        log "ERROR" "回滚失败"
        exit 1
    fi
}

# 函数: 发送通知
send_notification() {
    local status="$1"
    local message="$2"

    if [[ -n "${SLACK_WEBHOOK_URL:-}" ]]; then
        local color="good"
        if [[ "$status" == "failed" ]]; then
            color="danger"
        elif [[ "$status" == "warning" ]]; then
            color="warning"
        fi

        local payload=$(cat << EOF
{
    "attachments": [
        {
            "color": "$color",
            "title": "$SCRIPT_NAME",
            "fields": [
                {
                    "title": "Environment",
                    "value": "$ENVIRONMENT",
                    "short": true
                },
                {
                    "title": "Version",
                    "value": "$VERSION",
                    "short": true
                },
                {
                    "title": "Namespace",
                    "value": "$NAMESPACE",
                    "short": true
                },
                {
                    "title": "Status",
                    "value": "$status",
                    "short": true
                },
                {
                    "title": "Message",
                    "value": "$message",
                    "short": false
                }
            ],
            "footer": "MoonTV CI/CD Pipeline",
            "ts": $(date +%s)
        }
    ]
}
EOF
)

        curl -X POST -H 'Content-type: application/json' \
            --data "$payload" \
            "$SLACK_WEBHOOK_URL" &> /dev/null || log "WARN" "Slack通知发送失败"
    fi
}

# 函数: 主部署流程
main_deploy() {
    log "INFO" "开始蓝绿部署流程..."

    # 获取当前状态
    local active_color=$(get_active_color)
    local new_color=$(get_next_color)

    log "INFO" "当前活跃环境: $active_color"
    log "INFO" "新部署环境: $new_color"

    # 创建备份
    create_backup

    # 部署新版本
    if ! deploy_new_version "$new_color"; then
        log "ERROR" "新版本部署失败"
        send_notification "failed" "部署失败: 新版本部署到${new_color}环境失败"
        exit 1
    fi

    # 健康检查
    if ! health_check "$new_color"; then
        log "ERROR" "健康检查失败"
        send_notification "failed" "部署失败: 健康检查失败"
        exit 1
    fi

    # 切换流量
    if ! switch_traffic "$new_color"; then
        log "ERROR" "流量切换失败"
        send_notification "failed" "部署失败: 流量切换失败"
        # 尝试回滚
        rollback_deployment
        exit 1
    fi

    # 清理旧版本
    cleanup_old_version "$active_color"

    log "SUCCESS" "蓝绿部署完成"
    send_notification "success" "部署成功: 版本${VERSION}已部署到${ENVIRONMENT}环境"
}

# 函数: 主函数
main() {
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                echo "$SCRIPT_NAME v$SCRIPT_VERSION"
                exit 0
                ;;
            -n|--namespace)
                NAMESPACE="$2"
                shift 2
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -s|--skip-health)
                SKIP_HEALTH_CHECK=true
                shift
                ;;
            -f|--force)
                FORCE_DEPLOY=true
                shift
                ;;
            -r|--rollback)
                ROLLBACK=true
                shift
                ;;
            --no-backup)
                BACKUP_ENABLED=false
                shift
                ;;
            --health-timeout)
                HEALTH_CHECK_TIMEOUT="$2"
                shift 2
                ;;
            --health-interval)
                HEALTH_CHECK_INTERVAL="$2"
                shift 2
                ;;
            --traffic-delay)
                TRAFFIC_SWITCH_DELAY="$2"
                shift 2
                ;;
            -*)
                log "ERROR" "未知选项: $1"
                show_help
                exit 1
                ;;
            *)
                if [[ -z "$ENVIRONMENT" ]]; then
                    ENVIRONMENT="$1"
                elif [[ -z "$VERSION" ]]; then
                    VERSION="$1"
                else
                    log "ERROR" "多余的参数: $1"
                    show_help
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # 验证必需参数
    if [[ -z "$ENVIRONMENT" || -z "$VERSION" ]]; then
        log "ERROR" "缺少必需参数"
        show_help
        exit 1
    fi

    # 显示部署信息
    log "INFO" "$SCRIPT_NAME v$SCRIPT_VERSION"
    log "INFO" "部署环境: $ENVIRONMENT"
    log "INFO" "部署版本: $VERSION"
    log "INFO" "命名空间: $NAMESPACE"
    log "INFO" "模拟运行: $DRY_RUN"
    log "INFO" "跳过健康检查: $SKIP_HEALTH_CHECK"
    log "INFO" "强制部署: $FORCE_DEPLOY"
    log "INFO" "回滚模式: $ROLLBACK"
    log "INFO" "备份启用: $BACKUP_ENABLED"

    # 执行部署流程
    check_dependencies
    validate_arguments

    if [[ "$ROLLBACK" == "true" ]]; then
        rollback_deployment
    else
        main_deploy
    fi

    log "SUCCESS" "部署流程完成"
}

# 信号处理
trap 'log "ERROR" "脚本被中断"; exit 1' INT TERM

# 执行主函数
main "$@"