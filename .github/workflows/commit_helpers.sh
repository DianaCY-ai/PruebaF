#!/bin/bash

# Función mejorada para detectar la rama exacta
get_exact_branch() {
    local commit_hash=$1
    local branch=""
    
    # 1. Intento: Buscar en el reflog (más preciso para acciones recientes)
    branch=$(git reflog --format='%gs' | grep -m1 "$commit_hash" | \
             sed -nE 's/^.checkout: moving from [^ ] to ([^ ]).$/\1/p')
    
    # 2. Intento: Buscar branches que contengan el commit (incluyendo remotos)
    if [[ -z "$branch" ]]; then
        branch=$(git branch -a --contains "$commit_hash" | \
                grep -v "HEAD" | \
                sed -E 's/^[ ]((remotes\/)?origin\/)?//' | \
                sort | uniq | head -n1)
    fi
    
    # 3. Intento: Buscar en los logs de merge
    if [[ -z "$branch" ]]; then
        branch=$(git log --merges --first-parent --format='%s' --all | \
                grep -m1 "$commit_hash" | \
                sed -nE 's/^Merge branch '\''([^'\''])'\''.$/\1/p')
    fi
    
    # 4. Intento: Usar name-rev como último recurso
    if [[ -z "$branch" ]]; then
        branch=$(git name-rev --name-only --refs="refs/heads/*" "$commit_hash" 2>/dev/null | \
                sed 's/^.*\///')
    fi
    
    # Limpieza final del nombre
    branch=$(echo "$branch" | sed -E \
            -e 's/^origin\///' \
            -e 's/^remotes\///' \
            -e 's/[~^][0-9]*//g' \
            -e 's/HEAD -> //')
    
    # Validación y valor por defecto
    if [[ -z "$branch" ]] || [[ "$branch" =~ ^(.~[0-9]+|.\^[0-9]+|HEAD) ]]; then
        echo "main"
    else
        echo "$branch"
    fi
}

# Función para generar el reporte HTML
generate_html_report() {
    local start_time="$(TZ="America/Lima" date +"%Y-%m-%d") 00:00:00 -0500"
    local end_time="$(TZ="America/Lima" date +"%Y-%m-%d") 23:59:59 -0500"
    
    # HTML Header
    local html="""<html><head><style>
      /* Estilos mejorados */
      .branch-main { background-color: #e8f5e9; }
      .branch-feature { background-color: #e3f2fd; }
      .commit-hash { font-family: monospace; }
      .commit-table { border-collapse: collapse; width: 100%; }
      .commit-table th { background-color: #3498db; color: white; }
    </style></head><body>
    <h1>Ultimate Commit Report</h1>"""
    
    # Procesar cada usuario
    declare -A users=(
        ["DianaCY-ai"]="diana.carrasco@inetum.com"
        ["Dihani"]="dihani.cy@gmail.com"
    )
    
    for username in "${!users[@]}"; do
        local email="${users[$username]}"
        local commits=$(git log --since="$start_time" --until="$end_time" \
                      --author="$username" --pretty=format:"%H|%s|%cd|%P" \
                      --date=format:'%Y-%m-%d %H:%M:%S' --all)
        
        if [[ -n "$commits" ]]; then
            html+="<h2>✅ $username</h2><table class='commit-table'>"
            html+="<tr><th>Commit</th><th>Branch</th><th>Files</th></tr>"
            
            while IFS="|" read -r hash message date parents; do
                local branch=$(get_exact_branch "$hash")
                local branch_class=$([[ "$branch" == "main" ]] && echo "branch-main" || echo "branch-feature")
                
                html+="<tr>"
                html+="<td><span class='commit-hash'>${hash:0:7}</span><br>${message}<br><small>${date}</small></td>"
                html+="<td class='${branch_class}'>${branch}</td>"
                html+="<td><ul>$(git show --pretty="" --name-only "$hash" | sed 's/^/<li>/;s/$/<\/li>/')</ul></td>"
                html+="</tr>"
            done <<< "$commits"
            
            html+="</table>"
        else
            html+="<h2>❌ $username - No commits today</h2>"
        fi
    done
    
    html+="</body></html>"
    echo "$html"
}