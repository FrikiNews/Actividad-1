#!/bin/bash
# =============================================================
#  deploy.sh — Script de despliegue automatizado hacia AWS S3
#  Proyecto : HydroTrans (Actividad 1 — DevOps)
#  Autor    : FrikiNews
# =============================================================

set -e  # Detener el script si cualquier comando falla

# ── CONFIGURACIÓN ─────────────────────────────────────────────
BUCKET_NAME="hydrotrans-actividad1-friki"   # Nombre único del bucket S3
REGION="us-east-1"                          # Región de AWS Learner Lab
SOURCE_DIR="."                              # Directorio fuente (raíz del proyecto)
FILES_TO_DEPLOY=("index.html" "styles.css" "app.js")

# ── COLORES PARA OUTPUT ───────────────────────────────────────
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # Sin color

# ── FUNCIONES ─────────────────────────────────────────────────
log()     { echo -e "${CYAN}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[OK]${NC}    $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ── PASO 1: Verificar dependencias ────────────────────────────
log "Verificando dependencias..."

command -v aws  &>/dev/null || error "AWS CLI no está instalado. Instálalo desde https://aws.amazon.com/cli/"
command -v git  &>/dev/null || error "Git no está instalado."

success "Dependencias verificadas."

# ── PASO 2: Verificar credenciales AWS ───────────────────────
log "Verificando credenciales de AWS..."

aws sts get-caller-identity --output table 2>/dev/null \
  || error "Credenciales de AWS no configuradas o expiradas. Ejecuta: aws configure"

success "Credenciales válidas."

# ── PASO 3: Obtener rama y commit actuales ────────────────────
BRANCH=$(git rev-parse --abbrev-ref HEAD)
COMMIT=$(git rev-parse --short HEAD)
log "Rama activa : ${BRANCH}"
log "Commit      : ${COMMIT}"

# ── PASO 4: Asegurar que el repo está actualizado ─────────────
log "Sincronizando con el repositorio remoto..."
git pull origin "$BRANCH" --quiet
success "Repositorio actualizado."

# ── PASO 5: Crear bucket si no existe ────────────────────────
log "Verificando bucket S3: ${BUCKET_NAME}..."

if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
  warn "El bucket '${BUCKET_NAME}' ya existe. Se usará el existente."
else
  log "Creando bucket '${BUCKET_NAME}' en ${REGION}..."
  if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket \
      --bucket "$BUCKET_NAME" \
      --region "$REGION"
  else
    aws s3api create-bucket \
      --bucket "$BUCKET_NAME" \
      --region "$REGION" \
      --create-bucket-configuration LocationConstraint="$REGION"
  fi
  success "Bucket creado."
fi

# ── PASO 6: Deshabilitar bloqueo de acceso público ───────────
log "Configurando acceso público del bucket..."

aws s3api put-public-access-block \
  --bucket "$BUCKET_NAME" \
  --public-access-block-configuration \
    "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

success "Acceso público habilitado."

# ── PASO 7: Bucket policy — acceso público de lectura ────────
log "Aplicando política de acceso público..."

aws s3api put-bucket-policy \
  --bucket "$BUCKET_NAME" \
  --policy "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [{
      \"Sid\"      : \"PublicReadGetObject\",
      \"Effect\"   : \"Allow\",
      \"Principal\": \"*\",
      \"Action\"   : \"s3:GetObject\",
      \"Resource\" : \"arn:aws:s3:::${BUCKET_NAME}/*\"
    }]
  }"

success "Política aplicada."

# ── PASO 8: Habilitar hosting estático ───────────────────────
log "Habilitando hosting estático..."

aws s3 website "s3://${BUCKET_NAME}" \
  --index-document index.html \
  --error-document index.html

success "Hosting estático habilitado."

# ── PASO 9: Subir archivos al bucket ─────────────────────────
log "Desplegando archivos hacia s3://${BUCKET_NAME}..."

aws s3 sync "$SOURCE_DIR" "s3://${BUCKET_NAME}" \
  --exclude "*"                    \
  --include "index.html"           \
  --include "styles.css"           \
  --include "app.js"               \
  --delete                         \
  --acl public-read                \
  --output text

success "Archivos desplegados correctamente."

# ── PASO 10: Mostrar URL del sitio ───────────────────────────
SITE_URL="http://${BUCKET_NAME}.s3-website-${REGION}.amazonaws.com"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✅  DESPLIEGUE EXITOSO${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  🌐 URL    : ${CYAN}${SITE_URL}${NC}"
echo -e "  🌿 Rama   : ${YELLOW}${BRANCH}${NC}"
echo -e "  📦 Commit : ${YELLOW}${COMMIT}${NC}"
echo -e "  🪣 Bucket : ${YELLOW}${BUCKET_NAME}${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
