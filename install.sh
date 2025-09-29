#!/bin/bash
set -e

# Banner
cat << "EOF"
███████╗█████╗ ███████╗████████╗███████╗██╗███████╗
██╔════╝██╔══██╗██╔════╝╚══██╔══╝██╔════╝██║██╔════╝
███████╗███████║███████╗   ██║   █████╗  ██║███████╗
╚════██║██╔══██║╚════██║   ██║   ██╔══╝  ██║╚════██║
███████║██║  ██║███████║   ██║   ███████╗██║███████║
╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝╚══════╝
EOF

echo "\n🚀 Instalando FastDir - Ultra Fast Directory Brute Forcer"
echo "By lgdev2002 - Co-CEO BackTrackSec"
echo ""

# Verifica se Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "❌ Docker é necessário, mas não está instalado."
    echo "Instale o Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

echo "📦 Baixando a imagem mais recente do FastDir..."
docker pull lgdev2002/fastdir:latest

echo "🔗 Criando comando 'fastdir' no sistema..."
INSTALL_DIR="/usr/local/bin"
SCRIPT_PATH="$INSTALL_DIR/fastdir"

sudo tee "$SCRIPT_PATH" > /dev/null <<EOF
#!/bin/bash
docker run --rm -v \$(pwd):/output lgdev2002/fastdir:latest "\$@"
EOF

sudo chmod +x "$SCRIPT_PATH"

echo "✅ FastDir instalado com sucesso!"
echo ""
echo "Exemplo de uso:"
echo "  fastdir -u https://target.com -w /wordlists/common.txt"
echo "  fastdir -u https://target.com -w https://example.com/wordlist.txt -t 200"
echo ""
echo "Documentação: https://github.com/lgdev2002/fastdir"
echo "Issues: https://github.com/lgdev2002/fastdir/issues"
