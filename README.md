# Clean Packages Script

Script bash para limpeza automatizada de pastas `node_modules` e `vendor` de primeiro nível em projetos dentro de uma pasta geral de projetos (padrão: `~/Code`), com suporte para limpeza de caches de gerenciadores de pacotes e Docker.

## Como funciona

O script foi projetado para trabalhar com uma **estrutura de pasta geral de projetos**. Por exemplo:

```
~/Code/
├── projeto-1/
│   ├── node_modules/     ← SERÁ DELETADO
│   ├── src/
│   └── package.json
├── projeto-2/
│   ├── vendor/           ← SERÁ DELETADO
│   ├── src/
│   └── composer.json
└── projeto-3/
    ├── frontend/
    │   └── node_modules/ ← PRESERVADO (aninhado)
    └── backend/
        └── vendor/       ← PRESERVADO (aninhado)
```

**Como o script limpa:**
1. Você aponta para uma **pasta pai** que contém vários projetos (ex: `~/Code`)
2. O script busca pastas `node_modules` e `vendor` **apenas no primeiro nível** dentro de cada projeto
3. Pastas aninhadas (dentro de subpastas dos projetos) são preservadas
4. Por padrão, usa `~/Code` mas você pode especificar qualquer pasta com `--dir`

## Descrição

Este script identifica e remove apenas pastas de dependências de **primeiro nível** (diretamente dentro dos projetos), preservando pastas aninhadas em subdiretórios. Ideal para liberar espaço em disco removendo dependências que podem ser reinstaladas posteriormente.

Adicionalmente, o script pode limpar caches de:
- **npm** - Node Package Manager
- **pnpm** - Performant npm
- **yarn** - Yet Another Resource Negotiator
- **Docker** - Imagens, containers, volumes e build cache

### O que o script FAZ:

- ✅ Remove `/Code/projeto/node_modules`
- ✅ Remove `/Code/projeto/vendor`

### O que o script NÃO remove:

- ❌ Preserva `/Code/projeto/subpasta/node_modules`
- ❌ Preserva `/Code/projeto/subpasta/vendor`
- ❌ Preserva `/Code/projeto/node_modules/.pnpm/pkg/node_modules`

## Requisitos

- **Bash** (disponível nativamente no macOS e Linux)
- Permissões de leitura e escrita na pasta de projetos alvo
- **Opcional**: npm, pnpm, yarn ou Docker instalados (apenas se quiser usar `--clean-cache`)

## Instalação

1. Clone o repositório ou baixe o script
2. Torne o script executável:

```bash
chmod +x clean-packages.sh
```

## Uso

### Sintaxe básica:

```bash
./clean-packages.sh [opções]
```

### Opções disponíveis:

| Opção | Descrição |
|-------|-----------|
| `--dry-run` | Modo simulação (padrão) - mostra o que seria deletado sem deletar |
| `--execute` | Executa a deleção de fato |
| `--force` | Não pede confirmação (use com cuidado!) |
| `--dir <caminho>` | Especifica diretório alvo (padrão: ~/Code) |
| `--clean-cache` | Limpa caches: npm, pnpm, yarn, Go, Composer, pip, Serena, Xcode, Gradle, uv, Cypress, Playwright, Homebrew, Codex/Claude/ChatGPT, navegadores (Chrome/Brave/Firefox/Edge/Arc), apps Electron e Docker |
| `--help` ou `-h` | Mostra ajuda completa |

## Exemplos de uso

### 1. Modo Dry-Run (Seguro)

Ver o que seria deletado sem deletar nada:

```bash
./clean-packages.sh
# ou
./clean-packages.sh --dry-run
```

**Saída exemplo:**

```
===================================================
  Script de Limpeza de node_modules e vendor
===================================================
Modo: DRY RUN (nenhum arquivo será deletado)
Diretório: ~/Code
Profundidade: 1 nível (projeto/node_modules e projeto/vendor)

Escaneando pastas node_modules e vendor de primeiro nível...

Encontradas 64 pastas para [SIMULAÇÃO DE] deleção:

  [539.6MB]  pgb-datainsights-site-next/node_modules
  [987.2MB]  ebiblico-astro/node_modules
  [187.4MB]  vion-cms/vendor
  ...

Tamanho total a ser liberado: 28.61GB
Total de pastas: 64
```

### 2. Executar com confirmação

Deletar após confirmação do usuário:

```bash
./clean-packages.sh --execute
```

O script mostrará a lista de pastas e pedirá confirmação:

```
AVISO: Esta operação irá deletar permanentemente 64 pastas!

Você tem certeza que deseja continuar? (digite 'sim' para confirmar)
```

### 3. Executar sem confirmação

**⚠️ ATENÇÃO: Perigoso! Use com cuidado!**

```bash
./clean-packages.sh --execute --force
```

### 4. Usar diretório customizado

```bash
./clean-packages.sh --dir /outro/caminho --dry-run
```

### 5. Limpar caches (modo seguro)

Ver quanto espaço os caches ocupam sem deletar:

```bash
./clean-packages.sh --clean-cache
# ou
./clean-packages.sh --dry-run --clean-cache
```

### 6. Executar limpeza completa (node_modules + caches)

```bash
./clean-packages.sh --execute --clean-cache
```

### 7. Limpar apenas caches (sem node_modules)

Se não houver pastas node_modules/vendor ou você quiser limpar apenas os caches:

```bash
./clean-packages.sh --execute --clean-cache
```

O script detectará automaticamente que não há pastas para limpar e executará apenas a limpeza de caches.

## Características

### Segurança

- **Modo dry-run por padrão**: Sempre mostra o que seria deletado antes de deletar
- **Confirmação obrigatória**: No modo `--execute`, pede confirmação (exceto com `--force`)
- **Detecção precisa de profundidade**: Usa `find -maxdepth 2` para garantir apenas primeiro nível
- **Log de operações**: Cria arquivo de log com timestamp de todas as operações
- **Limpeza de cache segura**: Respeita modo dry-run para mostrar estimativa antes de limpar

### Informações exibidas

- Lista de todas as pastas encontradas
- Tamanho individual de cada pasta
- Tamanho total a ser liberado
- Status de limpeza de cache por ferramenta (npm, pnpm, yarn, Go, Composer, pip, Serena, Xcode, Gradle, uv, Cypress, Playwright, Homebrew, Codex/Claude/ChatGPT, navegadores, apps Electron, Docker)
- Estimativa de espaço dos caches (modo dry-run)
- Barra de progresso durante deleção
- Resumo final com estatísticas
- Saída colorida para melhor visualização

### Arquivos de log

Quando executado no modo `--execute`, o script cria um arquivo de log:

```
~/Code/cleanup-log-2025-11-18-14-30-00.txt
```

O log contém:
- Data e hora da execução
- Diretório alvo
- Lista de pastas deletadas (sucesso/falha)
- Tamanho de cada pasta deletada
- Resumo da operação

## Resultados esperados

Com base na última execução em dry-run:

- **64 pastas** serão removidas
  - 49 pastas `node_modules`
  - 15 pastas `vendor`
- **28.61GB** de espaço em disco será liberado

## Reinstalando dependências

Após a limpeza, você pode reinstalar as dependências em cada projeto conforme necessário:

### Para projetos Node.js:

```bash
cd ~/Code/nome-do-projeto
npm install
# ou
pnpm install
# ou
yarn install
```

### Para projetos PHP (Composer):

```bash
cd ~/Code/nome-do-projeto
composer install
```

## Perguntas frequentes

### Por que usar este script?

- Liberar espaço em disco rapidamente
- Limpar projetos antigos que não estão em uso
- Manutenção periódica da pasta de projetos
- Reinstalar dependências do zero quando necessário
- Limpar caches acumulados de gerenciadores de pacotes e Docker

### É seguro usar?

Sim, desde que você:
- Execute primeiro no modo `--dry-run` para verificar
- Tenha backups dos seus projetos (Git, etc.)
- Entenda que as dependências podem ser reinstaladas

### O que acontece se eu precisar das dependências depois?

Basta executar o gerenciador de pacotes do projeto:
- Node.js: `npm install` / `pnpm install` / `yarn install`
- PHP: `composer install`

### O script pode danificar meu código?

Não. O script remove apenas pastas de dependências (`node_modules` e `vendor`) e caches de gerenciadores de pacotes, que são regeneráveis. Seu código-fonte permanece intacto.

### O que acontece quando limpo os caches?

A limpeza de cache remove:
- **npm**: Cache de pacotes baixados (será reconstruído automaticamente)
- **pnpm**: Store de pacotes compartilhados não utilizados
- **yarn**: Cache de pacotes globais
- **Docker**: Imagens não utilizadas, containers parados, volumes órfãos e build cache

Todos esses caches serão reconstruídos automaticamente conforme necessário.

## Solução de problemas

### Erro: "Permissão negada"

Execute com permissões adequadas ou use `sudo` (não recomendado):

```bash
chmod +x clean-packages.sh
./clean-packages.sh
```

### Script não encontra pastas

Verifique se:
- O diretório alvo está correto
- As pastas realmente existem no primeiro nível
- Você tem permissões de leitura no diretório

### Algumas pastas não foram deletadas

Verifique o arquivo de log para detalhes. Possíveis causas:
- Permissões insuficientes
- Arquivos em uso
- Sistema de arquivos bloqueado

## Contribuindo

Contribuições são bem-vindas! Sinta-se livre para:
- Abrir issues para reportar bugs ou sugerir melhorias
- Enviar pull requests com correções ou novos recursos
- Melhorar a documentação

## Licença

MIT License - Livre para uso pessoal e comercial.

## Autor

Criado com 🤖 [Claude Code](https://claude.com/claude-code)

---

**Versão:** 1.0.0
