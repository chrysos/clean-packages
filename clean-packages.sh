#!/bin/bash

###############################################################################
# Script de Limpeza de node_modules e vendor (Primeiro Nível)
#
# Remove apenas node_modules e vendor de primeiro nível em projetos
# Exemplo: /Code/projeto/node_modules (DELETADO)
#          /Code/projeto/vendor (DELETADO)
#          /Code/projeto/subpasta/node_modules (PRESERVADO)
#          /Code/projeto/subpasta/vendor (PRESERVADO)
#
# Uso: ./clean-packages.sh [opções]
###############################################################################

# Configurações padrão
TARGET_DIR="$HOME/Code"
DRY_RUN=true
FORCE=false
VERBOSE=true
CLEAN_CACHE=false

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Contadores
FOUND_COUNT=0
DELETED_COUNT=0
FAILED_COUNT=0
TOTAL_SIZE=0

# Função de ajuda
show_help() {
    cat << EOF
${BOLD}Script de Limpeza de node_modules e vendor${NC}

${BOLD}USO:${NC}
    $0 [opções]

${BOLD}OPÇÕES:${NC}
    --dry-run          Modo dry-run (padrão) - mostra o que seria deletado
    --execute          Executa a deleção de fato
    --force            Não pede confirmação (use com cuidado!)
    --dir <caminho>    Diretório alvo (padrão: $TARGET_DIR)
    --clean-cache      Limpa caches (Docker, npm, pnpm, yarn)
    --help             Mostra esta ajuda

${BOLD}EXEMPLOS:${NC}
    $0                          # Dry-run - seguro
    $0 --execute                # Executa com confirmação
    $0 --execute --force        # Executa sem confirmação (perigoso!)
    $0 --dir /outro/caminho     # Usa outro diretório

${BOLD}COMPORTAMENTO:${NC}
    ✓ Deleta:    /Code/projeto/node_modules
    ✓ Deleta:    /Code/projeto/vendor
    ✗ Preserva:  /Code/projeto/subpasta/node_modules
    ✗ Preserva:  /Code/projeto/subpasta/vendor
    ✗ Preserva:  /Code/projeto/node_modules/.pnpm/pkg/node_modules

EOF
    exit 0
}

# Processa argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --execute)
            DRY_RUN=false
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --dir)
            TARGET_DIR="$2"
            shift 2
            ;;
        --clean-cache)
            CLEAN_CACHE=true
            shift
            ;;
        --help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}Opção desconhecida: $1${NC}"
            echo "Use --help para ver as opções disponíveis"
            exit 1
            ;;
    esac
done

# Função para formatar tamanho em bytes para formato legível
format_size() {
    local size=$1
    if [[ $size -lt 1024 ]]; then
        echo "${size}B"
    elif [[ $size -lt 1048576 ]]; then
        awk -v s="$size" 'BEGIN {printf "%.1fKB", s/1024}'
    elif [[ $size -lt 1073741824 ]]; then
        awk -v s="$size" 'BEGIN {printf "%.1fMB", s/1048576}'
    else
        awk -v s="$size" 'BEGIN {printf "%.2fGB", s/1073741824}'
    fi
}

# Função para calcular tamanho de diretório
get_dir_size() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        du -sk "$dir" 2>/dev/null | cut -f1 | awk '{print $1 * 1024}'
    else
        echo "0"
    fi
}

# Função para limpar caches
clean_caches() {
    echo ""
    echo -e "${BOLD}===================================================${NC}"
    echo -e "${BOLD}  Limpeza de Caches${NC}"
    echo -e "${BOLD}===================================================${NC}"
    echo ""

    local total_freed=0
    local cache_log=""

    # Limpar cache do npm
    if command -v npm &> /dev/null; then
        echo -e "${CYAN}Limpando cache do npm...${NC}"
        if [[ "$DRY_RUN" == true ]]; then
            local npm_cache_size=$(du -sk "$(npm config get cache)" 2>/dev/null | cut -f1 | awk '{print $1 * 1024}')
            echo -e "  ${YELLOW}[DRY RUN]${NC} Cache do npm: $(format_size $npm_cache_size)"
            total_freed=$((total_freed + npm_cache_size))
            cache_log+="[DRY RUN] npm cache: $(format_size $npm_cache_size)\n"
        else
            npm cache clean --force 2>&1 | grep -v "^npm"
            echo -e "  ${GREEN}[✓]${NC} Cache do npm limpo"
            cache_log+="[SUCESSO] npm cache limpo\n"
        fi
    else
        echo -e "  ${YELLOW}[⊘]${NC} npm não encontrado"
    fi
    echo ""

    # Limpar cache do pnpm
    if command -v pnpm &> /dev/null; then
        echo -e "${CYAN}Limpando cache do pnpm...${NC}"
        if [[ "$DRY_RUN" == true ]]; then
            local pnpm_cache_dir=$(pnpm store path 2>/dev/null)
            if [[ -d "$pnpm_cache_dir" ]]; then
                local pnpm_cache_size=$(du -sk "$pnpm_cache_dir" 2>/dev/null | cut -f1 | awk '{print $1 * 1024}')
                echo -e "  ${YELLOW}[DRY RUN]${NC} Cache do pnpm: $(format_size $pnpm_cache_size)"
                total_freed=$((total_freed + pnpm_cache_size))
                cache_log+="[DRY RUN] pnpm cache: $(format_size $pnpm_cache_size)\n"
            fi
        else
            pnpm store prune 2>&1 | grep -v "^Progress"
            echo -e "  ${GREEN}[✓]${NC} Cache do pnpm limpo"
            cache_log+="[SUCESSO] pnpm cache limpo\n"
        fi
    else
        echo -e "  ${YELLOW}[⊘]${NC} pnpm não encontrado"
    fi
    echo ""

    # Limpar cache do yarn
    if command -v yarn &> /dev/null; then
        echo -e "${CYAN}Limpando cache do yarn...${NC}"
        if [[ "$DRY_RUN" == true ]]; then
            local yarn_cache_dir=$(yarn cache dir 2>/dev/null)
            if [[ -d "$yarn_cache_dir" ]]; then
                local yarn_cache_size=$(du -sk "$yarn_cache_dir" 2>/dev/null | cut -f1 | awk '{print $1 * 1024}')
                echo -e "  ${YELLOW}[DRY RUN]${NC} Cache do yarn: $(format_size $yarn_cache_size)"
                total_freed=$((total_freed + yarn_cache_size))
                cache_log+="[DRY RUN] yarn cache: $(format_size $yarn_cache_size)\n"
            fi
        else
            yarn cache clean 2>&1 | grep -v "^yarn"
            echo -e "  ${GREEN}[✓]${NC} Cache do yarn limpo"
            cache_log+="[SUCESSO] yarn cache limpo\n"
        fi
    else
        echo -e "  ${YELLOW}[⊘]${NC} yarn não encontrado"
    fi
    echo ""

    # Limpar cache do Docker
    if command -v docker &> /dev/null; then
        echo -e "${CYAN}Limpando cache do Docker...${NC}"
        if [[ "$DRY_RUN" == true ]]; then
            local docker_output=$(docker system df 2>/dev/null)
            if [[ $? -eq 0 ]]; then
                echo -e "  ${YELLOW}[DRY RUN]${NC} Docker system info:"
                echo "$docker_output" | grep -E "RECLAIMABLE|TYPE" | head -5
                cache_log+="[DRY RUN] docker cache mostrado\n"
            else
                echo -e "  ${YELLOW}[⊘]${NC} Docker não está rodando ou não tem permissão"
            fi
        else
            docker system prune -af --volumes 2>&1
            echo -e "  ${GREEN}[✓]${NC} Cache do Docker limpo (imagens, containers, volumes, build cache)"
            cache_log+="[SUCESSO] docker cache limpo\n"
        fi
    else
        echo -e "  ${YELLOW}[⊘]${NC} docker não encontrado"
    fi
    echo ""

    if [[ "$DRY_RUN" == true && $total_freed -gt 0 ]]; then
        echo -e "${BOLD}Estimativa de espaço a ser liberado dos caches: ${GREEN}$(format_size $total_freed)${NC}"
        echo ""
    fi

    echo "$cache_log"
}

# Função para exibir header
show_header() {
    echo ""
    echo -e "${BOLD}===================================================${NC}"
    echo -e "${BOLD}  Script de Limpeza de node_modules e vendor${NC}"
    echo -e "${BOLD}===================================================${NC}"

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${CYAN}Modo: DRY RUN${NC} ${YELLOW}(nenhum arquivo será deletado)${NC}"
    else
        echo -e "${RED}Modo: EXECUÇÃO${NC} ${RED}(arquivos SERÃO deletados!)${NC}"
    fi

    echo -e "Diretório: ${BLUE}$TARGET_DIR${NC}"
    echo -e "Profundidade: ${GREEN}1 nível${NC} (projeto/node_modules e projeto/vendor)"
    echo ""
}

# Verifica se o diretório existe
if [[ ! -d "$TARGET_DIR" ]]; then
    echo -e "${RED}Erro: Diretório não encontrado: $TARGET_DIR${NC}"
    exit 1
fi

# Mostra header
show_header

# Encontra todas as pastas node_modules e vendor de primeiro nível
echo -e "${CYAN}Escaneando pastas node_modules e vendor de primeiro nível...${NC}"
echo ""

# Array para armazenar pastas encontradas
declare -a DEPENDENCY_DIRS

# Busca pastas node_modules e vendor de primeiro nível (maxdepth 2)
# Formato: /Code/projeto/node_modules ou /Code/projeto/vendor
while IFS= read -r dir; do
    if [[ -d "$dir" ]]; then
        DEPENDENCY_DIRS+=("$dir")
    fi
done < <(find "$TARGET_DIR" -maxdepth 2 -type d \( -name "node_modules" -o -name "vendor" \) 2>/dev/null)

FOUND_COUNT=${#DEPENDENCY_DIRS[@]}

if [[ $FOUND_COUNT -eq 0 ]]; then
    echo -e "${GREEN}Nenhuma pasta node_modules ou vendor de primeiro nível encontrada!${NC}"
    echo ""

    # Se não há pastas mas o usuário quer limpar cache, faz isso
    if [[ "$CLEAN_CACHE" == true ]]; then
        clean_caches
    fi

    exit 0
fi

# Calcula tamanho total e exibe lista
echo -e "${BOLD}Encontradas ${FOUND_COUNT} pastas para ${DRY_RUN:+[SIMULAÇÃO DE] }deleção:${NC}"
echo ""

for dir in "${DEPENDENCY_DIRS[@]}"; do
    size=$(get_dir_size "$dir")
    TOTAL_SIZE=$((TOTAL_SIZE + size))
    formatted_size=$(format_size $size)
    project_name=$(basename "$(dirname "$dir")")
    folder_name=$(basename "$dir")

    echo -e "  ${YELLOW}[${formatted_size}]${NC}  ${BLUE}$project_name/$folder_name${NC}"
done

echo ""
echo -e "${BOLD}Tamanho total a ser liberado: ${GREEN}$(format_size $TOTAL_SIZE)${NC}"
echo -e "${BOLD}Total de pastas: ${GREEN}${FOUND_COUNT}${NC}"
echo ""

# Limpar caches se solicitado (modo dry-run ou execute)
if [[ "$CLEAN_CACHE" == true ]]; then
    clean_caches
fi

# Se for dry-run, apenas mostra o que seria deletado
if [[ "$DRY_RUN" == true ]]; then
    echo -e "${CYAN}===================================================${NC}"
    echo -e "${CYAN}Este é um DRY RUN - nenhum arquivo foi deletado${NC}"
    echo -e "${CYAN}===================================================${NC}"
    echo ""
    echo -e "Para executar a deleção, use: ${BOLD}$0 --execute${NC}"
    echo ""
    exit 0
fi

# Modo de execução - pede confirmação se não for force
if [[ "$FORCE" != true ]]; then
    echo -e "${RED}${BOLD}AVISO: Esta operação irá deletar permanentemente ${FOUND_COUNT} pastas!${NC}"
    echo ""
    echo -e "Você tem certeza que deseja continuar? ${YELLOW}(digite 'sim' para confirmar)${NC}"
    read -r confirmation

    if [[ "$confirmation" != "sim" ]]; then
        echo -e "${YELLOW}Operação cancelada pelo usuário.${NC}"
        exit 0
    fi
fi

# Cria arquivo de log
LOG_FILE="$TARGET_DIR/cleanup-log-$(date +%Y-%m-%d-%H-%M-%S).txt"
echo "Log de Limpeza de node_modules - $(date)" > "$LOG_FILE"
echo "Diretório alvo: $TARGET_DIR" >> "$LOG_FILE"
echo "Total de pastas encontradas: $FOUND_COUNT" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Executa a deleção
echo ""
echo -e "${CYAN}Deletando pastas node_modules e vendor...${NC}"
echo ""

for dir in "${DEPENDENCY_DIRS[@]}"; do
    project_name=$(basename "$(dirname "$dir")")
    folder_name=$(basename "$dir")
    size=$(get_dir_size "$dir")
    formatted_size=$(format_size $size)

    if rm -rf "$dir" 2>/dev/null; then
        echo -e "  ${GREEN}[✓]${NC} Deletado: ${BLUE}$project_name/$folder_name${NC} (${formatted_size})"
        echo "[SUCESSO] $dir ($formatted_size)" >> "$LOG_FILE"
        DELETED_COUNT=$((DELETED_COUNT + 1))
    else
        echo -e "  ${RED}[✗]${NC} Falha: ${BLUE}$project_name/$folder_name${NC} (${formatted_size})"
        echo "[FALHA] $dir ($formatted_size)" >> "$LOG_FILE"
        FAILED_COUNT=$((FAILED_COUNT + 1))
    fi
done

# Mostra resumo
echo ""
echo -e "${BOLD}===================================================${NC}"
echo -e "${BOLD}Resumo da Operação:${NC}"
echo -e "${BOLD}===================================================${NC}"
echo -e "Deletadas com sucesso: ${GREEN}${DELETED_COUNT}${NC} pastas"
if [[ $FAILED_COUNT -gt 0 ]]; then
    echo -e "Falhas: ${RED}${FAILED_COUNT}${NC} pastas"
fi
echo -e "Espaço liberado: ${GREEN}$(format_size $TOTAL_SIZE)${NC}"
echo -e "Log salvo em: ${BLUE}$LOG_FILE${NC}"
echo ""

# Adiciona resumo ao log
echo "" >> "$LOG_FILE"
echo "=== RESUMO ===" >> "$LOG_FILE"
echo "Deletadas: $DELETED_COUNT" >> "$LOG_FILE"
echo "Falhas: $FAILED_COUNT" >> "$LOG_FILE"
echo "Espaço liberado: $(format_size $TOTAL_SIZE)" >> "$LOG_FILE"

echo -e "${CYAN}Para reinstalar dependências em um projeto:${NC}"
echo -e "  ${YELLOW}cd $TARGET_DIR/nome-do-projeto${NC}"
echo -e "  ${YELLOW}npm install${NC}  ${CYAN}(ou pnpm install, ou yarn install)${NC}"
echo ""
