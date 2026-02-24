# repo2text

> **Exporta cualquier repositorio de GitHub como un único archivo de texto — diseñado para ventanas de contexto de LLM.**

[![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![PowerShell: 5.1+](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://microsoft.com/powershell)
[![Platform: Linux | macOS | Windows](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows-lightgrey.svg)](#)

---

## El Problema

Trabajar con asistentes de IA como ChatGPT, Claude o LLMs locales requiere proporcionar al modelo contexto completo sobre tu base de código. Pero, ¿cómo se pasa un repositorio entero a una ventana de chat de forma limpia, fiable y sin ruido?

Copiar archivos individuales es tedioso. Compartir el repositorio como ZIP es ilegible para los modelos de IA. No existía una solución simple y profesional — hasta ahora.

## La Solución

`repo2text` clona cualquier repositorio de GitHub y exporta todos sus archivos de texto en **un único archivo de salida estructurado** — listo para pegar en cualquier asistente de IA, usar en pipelines automatizados o archivar como documentación.

Disponible para **todas las plataformas principales**:

| Plataforma | Script | Requisitos |
|------------|--------|-----------|
| Linux / macOS | `repo2text.sh` | Bash, git, jq, pv, zip |
| Windows | `repo2text.ps1` | PowerShell 5.1+, git |

Sin instalación. Sin frameworks exóticos. Solo ejecútalo.

---

## Características

- **Multiplataforma** — Script Bash nativo para Linux/macOS, script PowerShell nativo para Windows
- **Múltiples formatos de salida** — Exporta como texto plano (`.txt`), JSON o Markdown
- **Detección inteligente de archivos** — Verificación en múltiples etapas garantiza que solo se incluyan archivos de texto reales
- **Archivo ZIP automático** — Cada exportación genera automáticamente un archivo `.zip` comprimido
- **Conversión SSH → HTTPS** — Funciona perfectamente con URLs remotas SSH y HTTPS
- **Integración inteligente con Git** — Detecta automáticamente la URL remota cuando se ejecuta dentro de un repositorio Git
- **Advertencia de estado Git** — Advierte si hay cambios no confirmados o no enviados antes de exportar
- **Exportación selectiva** — Exportar únicamente un subdirectorio específico
- **Modo plano** — Eliminar rutas de directorio de los nombres de archivo para una salida simplificada
- **Sumas MD5** — Opcionalmente calcula e incluye un hash MD5 para cada archivo exportado
- **Exclusiones configurables** — La lista de extensiones ignoradas se amplía fácilmente
- **Indicador de progreso** — Salida visual de progreso para repositorios grandes
- **Salida limpia** — Los repositorios clonados se eliminan automáticamente tras la exportación

---

## Linux / macOS

### Requisitos

| Herramienta | Propósito | Instalación (Debian/Ubuntu) |
|-------------|-----------|----------------------------|
| `git` | Clonar repositorios | `apt install git` |
| `file` | Detección de tipo MIME | preinstalado |
| `grep` | Detección de archivos binarios | preinstalado |
| `jq` | Formato de salida JSON | `apt install jq` |
| `pv` | Indicador de progreso | `apt install pv` |
| `zip` | Creación de archivos comprimidos | `apt install zip` |
| `md5sum` | Generación de sumas de verificación (opcional) | preinstalado |

### Instalación

```bash
# Clonar el repositorio
git clone https://github.com/debian-professional/repo2text.git

# Hacer el script ejecutable
chmod +x repo2text/repo2text.sh

# Opcional: disponible globalmente
sudo cp repo2text/repo2text.sh /usr/local/bin/repo2text
```

### Uso

```bash
./repo2text.sh [OPCIONES] [URL-del-repositorio-GitHub]
```

Si no se proporciona ninguna URL, el script la solicita de forma interactiva. Cuando se ejecuta dentro de un repositorio Git, la URL remota actual se detecta y sugiere automáticamente.

### Opciones

| Opción | Descripción |
|--------|-------------|
| `-f, --format FORMATO` | Formato de salida: `txt` (predeterminado), `json`, `md` / `markdown` |
| `--flat` | Usar solo nombres de archivo sin rutas de directorio |
| `-o, --only RUTA` | Exportar solo el subdirectorio especificado (relativo a la raíz del repositorio) |
| `-md5, --md5` | Calcular e incluir una suma MD5 para cada archivo |
| `-h, --help` | Mostrar información de ayuda |

### Ejemplos

```bash
# Exportación básica — solicitud interactiva de URL
./repo2text.sh

# Exportar un repositorio específico como texto plano
./repo2text.sh https://github.com/debian-professional/repo2text.git

# Exportar como Markdown — ideal para asistentes de IA
./repo2text.sh -f md https://github.com/tu-usuario/tu-repo.git

# Exportar como JSON — ideal para pipelines automatizados
./repo2text.sh -f json https://github.com/tu-usuario/tu-repo.git

# Exportar solo un subdirectorio específico
./repo2text.sh -o src https://github.com/tu-usuario/tu-repo.git

# Modo plano — sin estructura de directorios
./repo2text.sh --flat https://github.com/tu-usuario/tu-repo.git

# Exportar con sumas MD5 para verificación de integridad
./repo2text.sh -md5 https://github.com/tu-usuario/tu-repo.git

# Combinar opciones — exportación Markdown de un subdirectorio con sumas de verificación
./repo2text.sh -f md -o lib -md5 https://github.com/tu-usuario/tu-repo.git

# Detección automática de URL dentro de un repositorio Git
cd ~/proyectos/mi-repo
./repo2text.sh -f md
# El script detecta la URL remota automáticamente y la sugiere
```

### Cómo Funciona la Detección de Archivos (Linux/macOS)

`repo2text.sh` utiliza un proceso de verificación en tres etapas:

1. **Verificación de tipo MIME** — `file --mime-type` debe devolver un tipo `text/*`
2. **Exclusión por extensión** — Los archivos con extensiones como `lock`, `log`, `tmp`, `bak`, `swp`, `cache` se omiten
3. **Verificación de seguridad binaria** — `grep -Iq` confirma que el archivo no contiene datos binarios

---

## Windows (PowerShell)

### Requisitos

- **PowerShell 5.1 o superior** — preinstalado en Windows 10 y Windows 11
- **Git for Windows** — descargar desde [git-scm.com](https://git-scm.com/download/win)

No se requieren herramientas adicionales. Todo lo demás utiliza funcionalidad .NET integrada.

### Configuración Inicial

Windows restringe la ejecución de scripts PowerShell por defecto. Los siguientes dos pasos son necesarios **una sola vez** antes del primer uso.

**Paso 1 — Permitir la ejecución de scripts:**

Abrir PowerShell y ejecutar:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Confirmar con `S` cuando Windows lo solicite.

**Paso 2 — Desbloquear el script descargado:**

Como el script fue descargado de Internet, Windows lo marca como potencialmente inseguro. Desbloquearlo con:

```powershell
Unblock-File .\repo2text.ps1
```

Estos dos pasos solo son necesarios una vez por equipo.

### Instalación

```powershell
# Clonar el repositorio
git clone https://github.com/debian-professional/repo2text.git

# Navegar al directorio
cd repo2text

# Desbloquear el script (necesario una vez tras la descarga)
Unblock-File .\repo2text.ps1
```

### Uso

```powershell
.\repo2text.ps1 [OPCIONES] [URL-del-repositorio-GitHub]
```

Si no se proporciona ninguna URL, el script la solicita de forma interactiva. Cuando se ejecuta dentro de un repositorio Git, la URL remota actual se detecta automáticamente — simplemente presiona Enter para confirmar.

### Opciones

| Opción | Descripción |
|--------|-------------|
| `-Format` | Formato de salida: `txt` (predeterminado), `json`, `md` / `markdown` |
| `-Flat` | Usar solo nombres de archivo sin rutas de directorio |
| `-Only RUTA` | Exportar solo el subdirectorio especificado (relativo a la raíz del repositorio) |
| `-Md5` | Calcular e incluir una suma MD5 para cada archivo |

### Ejemplos

```powershell
# Exportación básica — solicitud interactiva de URL
.\repo2text.ps1

# Exportar un repositorio específico como texto plano
.\repo2text.ps1 https://github.com/debian-professional/repo2text.git

# Exportar como Markdown — ideal para asistentes de IA
.\repo2text.ps1 -Format md https://github.com/tu-usuario/tu-repo.git

# Exportar como JSON — ideal para pipelines automatizados
.\repo2text.ps1 -Format json https://github.com/tu-usuario/tu-repo.git

# Exportar solo un subdirectorio específico
.\repo2text.ps1 -Only src https://github.com/tu-usuario/tu-repo.git

# Modo plano — sin estructura de directorios
.\repo2text.ps1 -Flat https://github.com/tu-usuario/tu-repo.git

# Exportar con sumas MD5 para verificación de integridad
.\repo2text.ps1 -Md5 https://github.com/tu-usuario/tu-repo.git

# Combinar opciones — exportación Markdown de un subdirectorio con sumas de verificación
.\repo2text.ps1 -Format md -Only lib -Md5 https://github.com/tu-usuario/tu-repo.git

# Detección automática de URL dentro de un repositorio Git
cd C:\proyectos\mi-repo
.\repo2text.ps1 -Format md
# El script detecta la URL remota automáticamente y la sugiere
```

### Cómo Funciona la Detección de Archivos (Windows/PowerShell)

`repo2text.ps1` utiliza un proceso de verificación en tres etapas adaptado para Windows:

1. **Exclusión por extensión** — Los archivos con extensiones como `lock`, `log`, `tmp`, `bak`, `exe`, `dll`, `bin` se omiten
2. **Verificación de bytes nulos** — Los primeros 8192 bytes se analizan en busca de bytes nulos, lo que identifica archivos binarios de forma fiable
3. **Prueba de lectura UTF-8** — El archivo se abre como texto UTF-8; si falla, el archivo se excluye

Este enfoque logra la misma fiabilidad que la verificación de tipo MIME de Linux sin necesidad de herramientas adicionales.

---

## Ejemplos de Formato de Salida

### Texto Plano (`.txt`)
```
=========================================================================
Repository Export | Files: 12
Date: 2026-02-24 10:00:00 | URL: https://github.com/user/repo
=========================================================================

FILE: src/main.py
---------------------------------------------------------
# contenido de main.py
...

FILE: README.md
---------------------------------------------------------
# contenido de README.md
...
```

### Markdown (`.md`)
```markdown
# Repo Export

- **URL:** https://github.com/user/repo
- **Files:** 12
- **Date:** 2026-02-24 10:00:00

---

## `src/main.py`
```python
# contenido de main.py
```
```

### JSON (`.json`)
```json
{
  "metadata": {
    "url": "https://github.com/user/repo",
    "date": "2026-02-24 10:00:00",
    "file_count": 12
  },
  "files": [
    {
      "path": "src/main.py",
      "content": "# contenido de main.py\n..."
    }
  ]
}
```

---

## Casos de Uso

### 1. Revisión de código asistida por IA
Exporta tu repositorio y pega la salida directamente en ChatGPT, Claude o cualquier LLM. El modelo recibe la base de código completa como una única entrada estructurada — sin cambio de archivos, sin contexto fragmentado.

```bash
# Linux/macOS
repo2text -f md https://github.com/tu-usuario/tu-repo.git
```
```powershell
# Windows
.\repo2text.ps1 -Format md https://github.com/tu-usuario/tu-repo.git
```

### 2. Alimentar contexto a LLMs locales
Al trabajar con modelos locales mediante Ollama, LM Studio u herramientas similares, la gestión de la ventana de contexto es crítica. Exporta solo el subdirectorio relevante para mantenerte dentro de los límites de tokens.

```bash
repo2text -o backend/api -f txt https://github.com/tu-usuario/tu-repo.git
```

### 3. Pipelines de documentación automatizados
Integra `repo2text` en flujos de trabajo CI/CD para generar instantáneas actualizadas de la base de código como parte del proceso de documentación.

```bash
repo2text.sh -f json https://github.com/org/proyecto.git
```

### 4. Archivado de código e instantáneas
Crea una instantánea legible en un único archivo de cualquier repositorio en cualquier momento — ideal para auditorías, traspasos o archivado a largo plazo.

```bash
repo2text -md5 https://github.com/tu-usuario/tu-repo.git
# Las sumas MD5 permiten verificar la integridad de los archivos más adelante
```

### 5. Análisis entre repositorios
Exporta múltiples repositorios y compara su estructura y contenido sin cambiar entre directorios.

```bash
repo2text https://github.com/org/servicio-a.git
repo2text https://github.com/org/servicio-b.git
# Ambas exportaciones son ahora archivos de texto plano — compáralos, búscalos, analízalos con IA
```

### 6. Auditorías de seguridad
Exporta un repositorio y realiza revisiones de seguridad automatizadas o asistidas por IA contra el texto completo y sin filtrar.

```bash
repo2text -f txt https://github.com/vendor/libreria.git
grep -i "api_key\|password\|secret" repo_export_*.txt
```

### 7. Incorporación de nuevos miembros del equipo
Genera una exportación Markdown estructurada de una base de código y compártela con nuevos desarrolladores como una visión general legible del proyecto completo.

```bash
repo2text -f md https://github.com/org/producto-principal.git
```

---

## Demo Autorreferencial

Este script fue utilizado para exportar su propio repositorio y proporcionar contexto completo de la base de código a un asistente de IA durante el desarrollo. El archivo que estás leyendo ahora es resultado directo de ese flujo de trabajo.

```bash
# Linux/macOS
./repo2text.sh -f md https://github.com/debian-professional/repo2text.git
```
```powershell
# Windows
.\repo2text.ps1 -Format md https://github.com/debian-professional/repo2text.git
```

---

## Contribuir

Las contribuciones, informes de errores y solicitudes de funciones son bienvenidos. Por favor, abre un issue o envía un pull request.

---

## Licencia

Este proyecto está licenciado bajo la **GNU General Public License v2.0**. Consulta el archivo [LICENSE](LICENSE) para más detalles.

---

## Autor

Desarrollado por **[debian-professional](https://github.com/debian-professional)**  
Una herramienta nacida de flujos de trabajo reales de desarrollo asistido por IA.
