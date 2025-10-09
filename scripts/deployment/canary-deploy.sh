#!/bin/bash
# =================================================================
# MoonTV 金丝雀发布脚本 v4.0.0
# 功能: 渐进式流量控制，自动监控决策，智能回滚
# 使用: ./canary-deploy.sh [环境] [版本] [选项]
# =================================================================

set -euo pipefail

# 脚本配置
readonly SCRIPT_NAME="MoonTV Canary Deploy"
readonly SCRIPT_VERSION="4.0.0"
readonly LOG_FILE="/var/log/moontv-canary-deploy.log"

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
AUTO_ANALYSIS=true
CANARY_PERCENTAGE=5
MAX_PERCENTAGE=100
STEP_DURATION=300
ANALYSIS_INTERVAL=30
SUCCESS_RATE_THRESHOLD=95
ERROR_RATE_THRESHOLD=5
LATENCY_THRESHOLD=1000
FORCE_CONTINUE=false
ROLLBACK_ON_FAILURE=true

# 金丝雀阶段配置
declare -a CANARY_PHASES=(
    "5:300:analysis"     # 5%流量，5分钟，分析阶段
    "20:600:analysis"    # 20%流量，10分钟，分析阶段
    "50:900:analysis"    # 50%流量，15分钟，分析阶段
    "100:1800:verify"    # 100%流量，30分钟，验证阶段
)

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
        "CANARY")
            echo -e "${PURPLE}[CANARY]${NC} ${timestamp} - $message" | tee -a "$LOG_FILE"
            ;;
        "ANALYSIS")
            echo -e "${CYAN}[ANALYSIS]${NC} ${timestamp} - $message" | tee -a "$LOG_FILE"
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
    环境        部署环境 (staging/prod)
    版本        部署版本号 (如: v4.0.0)

选项:
    -h, --help              显示此帮助信息
    -v, --version           显示版本信息
    -n, --namespace <ns>    指定命名空间 (默认: moontv)
    -d, --dry-run           模拟运行，不执行实际部署
    -p, --percentage <num>  初始金丝雀流量百分比 (默认: 5)
    -s, --step-duration <sec>  每阶段持续时间 (默认: 300秒)
    -i, --analysis-interval <sec>  分析间隔 (默认: 30秒)
    --success-rate <num>    成功率阈值 (默认: 95)
    --error-rate <num>      错误率阈值 (默认: 5)
    --latency <ms>          延迟阈值 (默认: 1000ms)
    --no-analysis           禁用自动分析
    --force                 强制继续，忽略分析结果
    --no-rollback           禁用自动回滚
    --custom-phases <config> 自定义阶段配置

监控指标:
    --success-rate-threshold <num>  成功率阈值 (默认: 95%)
    --error-rate-threshold <num>    错误率阈值 (默认: 5%)
    --latency-p95-threshold <ms>    P95延迟阈值 (默认: 1000ms)
    --latency-p99-threshold <ms>    P99延迟阈值 (默认: 2000ms)

示例:
    $0 staging v4.0.0                          # 基础金丝雀发布
    $0 prod v4.0.1 --percentage 10              # 10%初始流量
    $0 prod v4.0.0 --no-analysis                # 禁用自动分析
    $0 staging v4.0.0 --custom-phases "5:300,20:600,100:1200"

环境变量:
    KUBECONFIG             Kubernetes配置文件路径
    PROMETHEUS_URL         Prometheus监控地址
    GRAFANA_URL            Grafana仪表板地址
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

    # 检查curl
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi

    # 检查jq
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi

    # 检查bc（用于计算）
    if ! command -v bc &> /dev/null; then
        missing_deps+=("bc")
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

    # 检查Prometheus连接（如果启用自动分析）
    if [[ "$AUTO_ANALYSIS" == "true" ]] && [[ -n "${PROMETHEUS_URL:-}" ]]; then
        if ! curl -s "${PROMETHEUS_URL}/api/v1/query" &> /dev/null; then
            log "WARN" "无法连接到Prometheus: $PROMETHEUS_URL"
            AUTO_ANALYSIS=false
        fi
    fi

    log "SUCCESS" "依赖检查通过"
}

# 函数: 参数验证
validate_arguments() {
    log "INFO" "验证金丝雀发布参数..."

    # 验证环境
    if [[ ! "$ENVIRONMENT" =~ ^(staging|prod|production)$ ]]; then
        log "ERROR" "无效的环境: $ENVIRONMENT"
        log "ERROR" "支持的环境: staging, prod, production"
        exit 1
    fi

    # 验证版本格式
    if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log "ERROR" "无效的版本格式: $VERSION"
        log "ERROR" "版本格式应为: v1.2.3"
        exit 1
    fi

    # 验证流量百分比
    if ! [[ "$CANARY_PERCENTAGE" =~ ^[0-9]+$ ]] || [[ "$CANARY_PERCENTAGE" -lt 1 ]] || [[ "$CANARY_PERCENTAGE" -gt 100 ]]; then
        log "ERROR" "无效的流量百分比: $CANARY_PERCENTAGE (范围: 1-100)"
        exit 1
    fi

    # 验证阈值
    if ! [[ "$SUCCESS_RATE_THRESHOLD" =~ ^[0-9]+$ ]] || [[ "$SUCCESS_RATE_THRESHOLD" -lt 1 ]] || [[ "$SUCCESS_RATE_THRESHOLD" -gt 100 ]]; then
        log "ERROR" "无效的成功率阈值: $SUCCESS_RATE_THRESHOLD (范围: 1-100)"
        exit 1
    fi

    # 验证命名空间
    if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
        log "ERROR" "命名空间不存在: $NAMESPACE"
        exit 1
    fi

    log "SUCCESS" "参数验证通过"
}

# 函数: 解析自定义阶段配置
parse_custom_phases() {
    local config="$1"

    if [[ -n "$config" ]]; then
        log "INFO" "解析自定义金丝雀阶段配置: $config"
        CANARY_PHASES=()

        IFS=',' read -ra phases <<< "$config"
        for phase in "${phases[@]}"; do
            IFS=':' read -ra parts <<< "$phase"
            if [[ ${#parts[@]} -eq 3 ]]; then
                CANARY_PHASES+=("${parts[0]}:${parts[1]}:${parts[2]}")
            else
                log "ERROR" "无效的阶段配置格式: $phase"
                log "ERROR" "正确格式: percentage:duration:action"
                exit 1
            fi
        done

        log "INFO" "自定义阶段配置解析完成，共${#CANARY_PHASES[@]}个阶段"
    fi
}

# 函数: 创建金丝雀部署
create_canary_deployment() {
    log "CANARY" "创建金丝雀部署..."

    local canary_name="moontv-deployment-canary"

    if [[ "$DRY_RUN" == "true" ]]; then
        log "CANARY" "[DRY-RUN] 模拟创建金丝雀部署: $canary_name"
        return 0
    fi

    # 创建金丝雀部署
    cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${canary_name}
  namespace: ${NAMESPACE}
  labels:
    app.kubernetes.io/name: moontv
    app.kubernetes.io/component: app
    deployment-type: canary
    version: ${VERSION}
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: moontv
      app.kubernetes.io/component: app
      deployment-type: canary
  template:
    metadata:
      labels:
        app.kubernetes.io/name: moontv
        app.kubernetes.io/component: app
        deployment-type: canary
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
        - name: DEPLOYMENT_TYPE
          value: "canary"
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

    # 等待金丝雀部署就绪
    log "CANARY" "等待金丝雀部署就绪..."
    kubectl rollout status deployment/"$canary_name" -n "$NAMESPACE" --timeout=600s

    log "SUCCESS" "金丝雀部署创建完成"
}

# 函数: 配置流量分割
configure_traffic_split() {
    local percentage="$1"

    log "CANARY" "配置流量分割: 金丝雀 ${percentage}% / 稳定版 $((100 - percentage))%"

    if [[ "$DRY_RUN" == "true" ]]; then
        log "CANARY" "[DRY-RUN] 模拟流量分割配置"
        return 0
    fi

    # 创建或更新VirtualService（Istio）
    if kubectl get crd virtualservices.networking.istio.io &> /dev/null; then
        configure_istio_traffic_split "$percentage"
    else
        # 使用K8s Service进行简单流量分割
        configure_k8s_traffic_split "$percentage"
    fi

    log "SUCCESS" "流量分割配置完成"
}

# 函数: Istio流量分割配置
configure_istio_traffic_split() {
    local percentage="$1"

    cat << EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: moontv-virtualservice
  namespace: ${NAMESPACE}
spec:
  hosts:
  - moontv-service
  http:
  - match:
    - headers:
        canary:
          exact: "true"
    route:
    - destination:
        host: moontv-service
        subset: canary
      weight: 100
  - route:
    - destination:
        host: moontv-service
        subset: stable
      weight: $((100 - percentage))
    - destination:
        host: moontv-service
        subset: canary
      weight: $percentage
---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: moontv-destinationrule
  namespace: ${NAMESPACE}
spec:
  host: moontv-service
  subsets:
  - name: stable
    labels:
      deployment-type: stable
  - name: canary
    labels:
      deployment-type: canary
EOF
}

# 函数: Kubernetes流量分割配置
configure_k8s_traffic_split() {
    local percentage="$1"
    local canary_replicas=$((percentage / 10 + 1))  # 简单计算副本数
    local stable_replicas=$((10 - canary_replicas))

    # 更新金丝雀副本数
    kubectl scale deployment moontv-deployment-canary -n "$NAMESPACE" --replicas="$canary_replicas"

    # 更新稳定版副本数
    kubectl scale deployment moontv-deployment-stable -n "$NAMESPACE" --replicas="$stable_replicas"
}

# 函数: 收集性能指标
collect_metrics() {
    local duration="$1"
    local start_time=$(date +%s)
    local end_time=$((start_time + duration))

    log "ANALYSIS" "开始收集性能指标，持续时间: ${duration}秒"

    # 初始化统计变量
    local total_requests=0
    local success_requests=0
    local error_requests=0
    local total_latency=0
    local latency_samples=0

    while [[ $(date +%s) -lt $end_time ]]; do
        if [[ "$AUTO_ANALYSIS" == "true" ]] && [[ -n "${PROMETHEUS_URL:-}" ]]; then
            # 从Prometheus获取指标
            local current_time=$(date +%s)
            local query_time=$((current_time - 60))  # 查询最近1分钟的数据

            # HTTP请求总数
            local requests=$(curl -s "${PROMETHEUS_URL}/api/v1/query_range" \
                -G -d "query=sum(rate(http_requests_total{namespace=\"${NAMESPACE}\",deployment_type=\"canary\"}[1m]))" \
                -d "start=${query_time}" -d "end=${current_time}" \
                | jq -r '.data.result[0].values[0][1]' 2>/dev/null || echo "0")

            # HTTP错误率
            local errors=$(curl -s "${PROMETHEUS_URL}/api/v1/query_range" \
                -G -d "query=sum(rate(http_requests_total{namespace=\"${NAMESPACE}\",deployment_type=\"canary\",status!~\"2..\"}[1m]))" \
                -d "start=${query_time}" -d "end=${current_time}" \
                | jq -r '.data.result[0].values[0][1]' 2>/dev/null || echo "0")

            # HTTP延迟
            local latency=$(curl -s "${PROMETHEUS_URL}/api/v1/query_range" \
                -G -d "query=histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{namespace=\"${NAMESPACE}\",deployment_type=\"canary\"}[1m]))" \
                -d "start=${query_time}" -d "end=${current_time}" \
                | jq -r '.data.result[0].values[0][1]' 2>/dev/null || echo "0")

            # 累积统计
            total_requests=$(echo "$total_requests + $requests" | bc)
            success_requests=$(echo "$success_requests + ($requests - $errors)" | bc)
            error_requests=$(echo "$error_requests + $errors" | bc)

            if [[ "$latency" != "0" ]]; then
                total_latency=$(echo "$total_latency + $latency" | bc)
                latency_samples=$((latency_samples + 1))
            fi

            log "ANALYSIS" "实时指标 - 请求: $requests/s, 错误: $errors/s, 延迟: ${latency}s"
        fi

        sleep "$ANALYSIS_INTERVAL"
    done

    # 计算平均指标
    local success_rate=0
    local error_rate=0
    local avg_latency=0

    if [[ $total_requests -gt 0 ]]; then
        success_rate=$(echo "scale=2; $success_requests * 100 / $total_requests" | bc)
        error_rate=$(echo "scale=2; $error_requests * 100 / $total_requests" | bc)
    fi

    if [[ $latency_samples -gt 0 ]]; then
        avg_latency=$(echo "scale=3; $total_latency / $latency_samples" | bc)
    fi

    # 输出结果
    log "ANALYSIS" "性能指标收集完成:"
    log "ANALYSIS" "  总请求数: $total_requests"
    log "ANALYSIS" "  成功率: ${success_rate}%"
    log "ANALYSIS" "  错误率: ${error_rate}%"
    log "ANALYSIS" "  平均延迟: ${avg_latency}s"

    # 返回指标（用于后续分析）
    echo "$success_rate,$error_rate,$avg_latency,$total_requests"
}

# 函数: 分析性能指标
analyze_metrics() {
    local metrics="$1"

    IFS=',' read -ra metric_array <<< "$metrics"
    local success_rate="${metric_array[0]}"
    local error_rate="${metric_array[1]}"
    local avg_latency="${metric_array[2]}"
    local total_requests="${metric_array[3]}"

    log "ANALYSIS" "分析性能指标..."

    # 转换延迟为毫秒
    local latency_ms=$(echo "$avg_latency * 1000" | bc)

    # 阈值检查
    local success_check=$(echo "$success_rate >= $SUCCESS_RATE_THRESHOLD" | bc)
    local error_check=$(echo "$error_rate <= $ERROR_RATE_THRESHOLD" | bc)
    local latency_check=$(echo "$latency_ms <= $LATENCY_THRESHOLD" | bc)
    local requests_check=$(echo "$total_requests >= 10" | bc)  # 至少10个请求才有统计意义

    log "ANALYSIS" "阈值检查结果:"
    log "ANALYSIS" "  成功率: ${success_rate}% (阈值: ${SUCCESS_RATE_THRESHOLD}%) - $([ "$success_check" == "1" ] && echo "✅ PASS" || echo "❌ FAIL")"
    log "ANALYSIS" "  错误率: ${error_rate}% (阈值: ${ERROR_RATE_THRESHOLD}%) - $([ "$error_check" == "1" ] && echo "✅ PASS" || echo "❌ FAIL")"
    log "ANALYSIS" "  延迟: ${latency_ms}ms (阈值: ${LATENCY_THRESHOLD}ms) - $([ "$latency_check" == "1" ] && echo "✅ PASS" || echo "❌ FAIL")"
    log "ANALYSIS" "  请求数: $total_requests (最小: 10) - $([ "$requests_check" == "1" ] && echo "✅ PASS" || echo "❌ FAIL")"

    # 综合判断
    if [[ "$success_check" == "1" && "$error_check" == "1" && "$latency_check" == "1" && "$requests_check" == "1" ]]; then
        log "ANALYSIS" "🎉 性能分析结果: 通过"
        return 0
    else
        log "ANALYSIS" "⚠️  性能分析结果: 未通过阈值检查"
        return 1
    fi
}

# 函数: 执行金丝雀阶段
execute_canary_phase() {
    local phase_config="$1"

    IFS=':' read -ra phase_parts <<< "$phase_config"
    local percentage="${phase_parts[0]}"
    local duration="${phase_parts[1]}"
    local action="${phase_parts[2]}"

    log "CANARY" "执行金丝雀阶段: ${percentage}%流量, ${duration}秒, ${action}操作"

    # 配置流量分割
    configure_traffic_split "$percentage"

    if [[ "$action" == "analysis" ]]; then
        # 执行性能分析
        log "ANALYSIS" "开始性能分析阶段..."

        local metrics=$(collect_metrics "$duration")
        local analysis_result=0

        if [[ "$AUTO_ANALYSIS" == "true" ]]; then
            if ! analyze_metrics "$metrics"; then
                analysis_result=1

                if [[ "$FORCE_CONTINUE" == "false" ]]; then
                    log "ANALYSIS" "性能分析失败，建议终止金丝雀发布"
                    return 1
                else
                    log "WARN" "强制继续金丝雀发布（忽略分析结果）"
                fi
            fi
        fi

        log "SUCCESS" "金丝雀阶段完成: ${percentage}%流量"

    elif [[ "$action" == "verify" ]]; then
        # 执行最终验证
        log "ANALYSIS" "开始最终验证阶段..."

        local metrics=$(collect_metrics "$duration")

        if [[ "$AUTO_ANALYSIS" == "true" ]]; then
            if ! analyze_metrics "$metrics"; then
                log "ERROR" "最终验证失败"
                return 1
            fi
        fi

        log "SUCCESS" "最终验证通过"
    fi

    return 0
}

# 函数: 推广金丝雀到生产
promote_canary_to_production() {
    log "CANARY" "推广金丝雀版本到生产环境..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log "CANARY" "[DRY-RUN] 模拟推广金丝雀版本"
        return 0
    fi

    # 更新稳定版部署
    kubectl patch deployment moontv-deployment-stable -n "$NAMESPACE" -p \
        '{"spec":{"template":{"spec":{"containers":[{"name":"moontv-app","image":"'${DOCKER_REGISTRY:-ghcr.io/your-repo}/moontv:${VERSION}'"}]}}}}'

    # 等待稳定版更新完成
    kubectl rollout status deployment/moontv-deployment-stable -n "$NAMESPACE" --timeout=600s

    # 清理金丝雀部署
    kubectl delete deployment moontv-deployment-canary -n "$NAMESPACE" --ignore-not-found=true

    # 恢复正常流量
    configure_traffic_split 0

    log "SUCCESS" "金丝雀版本成功推广到生产环境"
}

# 函数: 回滚金丝雀部署
rollback_canary_deployment() {
    log "WARN" "回滚金丝雀部署..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log "WARN" "[DRY-RUN] 模拟回滚操作"
        return 0
    fi

    # 清理金丝雀部署
    kubectl delete deployment moontv-deployment-canary -n "$NAMESPACE" --ignore-not-found=true

    # 恢复正常流量
    configure_traffic_split 0

    log "SUCCESS" "金丝雀部署回滚完成"
}

# 函数: 发送金丝雀通知
send_canary_notification() {
    local status="$1"
    local phase="$2"
    local metrics="$3"

    if [[ -n "${SLACK_WEBHOOK_URL:-}" ]]; then
        local color="good"
        local emoji="🚀"

        if [[ "$status" == "failed" ]]; then
            color="danger"
            emoji="🚨"
        elif [[ "$status" == "warning" ]]; then
            color="warning"
            emoji="⚠️"
        fi

        local payload=$(cat << EOF
{
    "attachments": [
        {
            "color": "$color",
            "title": "$emoji MoonTV Canary Deploy",
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
                    "title": "Phase",
                    "value": "$phase",
                    "short": true
                },
                {
                    "title": "Status",
                    "value": "$status",
                    "short": true
                }
            ],
            "footer": "MoonTV Canary Pipeline",
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

# 函数: 主金丝雀发布流程
main_canary_deploy() {
    log "CANARY" "开始金丝雀发布流程..."

    # 创建金丝雀部署
    create_canary_deployment

    # 执行金丝雀阶段
    for phase in "${CANARY_PHASES[@]}"; do
        log "CANARY" "开始执行阶段: $phase"

        if ! execute_canary_phase "$phase"; then
            log "ERROR" "金丝雀阶段失败: $phase"

            if [[ "$ROLLBACK_ON_FAILURE" == "true" ]]; then
                rollback_canary_deployment
                send_canary_notification "failed" "$phase" ""
                exit 1
            else
                log "WARN" "金丝雀阶段失败，但配置为不自动回滚"
            fi
        fi

        send_canary_notification "success" "$phase" ""
    done

    # 推广到生产环境
    promote_canary_to_production

    log "SUCCESS" "金丝雀发布完成"
    send_canary_notification "success" "completed" ""
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
            -p|--percentage)
                CANARY_PERCENTAGE="$2"
                shift 2
                ;;
            -s|--step-duration)
                STEP_DURATION="$2"
                shift 2
                ;;
            -i|--analysis-interval)
                ANALYSIS_INTERVAL="$2"
                shift 2
                ;;
            --success-rate)
                SUCCESS_RATE_THRESHOLD="$2"
                shift 2
                ;;
            --error-rate)
                ERROR_RATE_THRESHOLD="$2"
                shift 2
                ;;
            --latency)
                LATENCY_THRESHOLD="$2"
                shift 2
                ;;
            --no-analysis)
                AUTO_ANALYSIS=false
                shift
                ;;
            --force)
                FORCE_CONTINUE=true
                shift
                ;;
            --no-rollback)
                ROLLBACK_ON_FAILURE=false
                shift
                ;;
            --custom-phases)
                parse_custom_phases "$2"
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
    log "CANARY" "$SCRIPT_NAME v$SCRIPT_VERSION"
    log "CANARY" "部署环境: $ENVIRONMENT"
    log "CANARY" "部署版本: $VERSION"
    log "CANARY" "命名空间: $NAMESPACE"
    log "CANARY" "初始流量: $CANARY_PERCENTAGE%"
    log "CANARY" "自动分析: $AUTO_ANALYSIS"
    log "CANARY" "模拟运行: $DRY_RUN"
    log "CANARY" "强制继续: $FORCE_CONTINUE"
    log "CANARY" "自动回滚: $ROLLBACK_ON_FAILURE"

    # 显示金丝雀阶段
    log "CANARY" "金丝雀阶段配置:"
    for i in "${!CANARY_PHASES[@]}"; do
        log "CANARY" "  阶段$((i+1)): ${CANARY_PHASES[i]}"
    done

    # 执行金丝雀发布流程
    check_dependencies
    validate_arguments
    main_canary_deploy

    log "SUCCESS" "金丝雀发布流程完成"
}

# 信号处理
trap 'log "ERROR" "脚本被中断"; exit 1' INT TERM

# 执行主函数
main "$@"