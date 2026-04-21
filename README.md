# 🏢 Furnarius Bootstrap Scripts

Scripts oficiales de Devbout para crear nuevos proyectos basados en el template **Furnarius** (`mmanto/furnarius`), con soporte para Desarrollo Basado en Arquitectura + Asistencia por IA.

## 🚀 Uso rápido

### Linux / macOS / WSL / Git Bash
```bash
# Crear proyecto privado "mi-sistema"
curl -fsSL https://raw.githubusercontent.com/mmanto/create-bootstrap/refs/tags/1.0.1/bootstrap.sh | bash -s -- --name=mi-sistema

# Crear proyecto público
curl -fsSL .../bootstrap.sh | bash -s -- --name=mi-sistema --public

# Solo crear en GitHub, sin clonar local
curl -fsSL .../bootstrap.sh | bash -s -- --name=mi-sistema --no-clone
