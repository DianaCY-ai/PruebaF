#!/bin/bash

# Funcion que obtiene el nombre del branch actual de un commit  
get_actual_branch() {
    local commit_hash=$1

    # 1. Priorizar ramas principales (main/master) usando first-parent
    local branch=$(git log --first-parent --pretty=format:"%D" "$commit_hash" -1 | \
                   grep -oE "origin/(main|master|brDihani)" | \
                   sed 's/origin\///' | \
                   head -n1)

    # 2. Si no se encontró, buscar ramas que contengan el commit (sin checkout)
    if [ -z "$branch" ]; then
        branch=$(git branch -r --contains "$commit_hash" | \
                sed 's/^[ \t]*origin\///' | \
                grep -v "HEAD" | \
                awk '{ if ($0 == "main") print; }' | \
                head -n1)
    fi

    # 3. Si sigue vacío, usar el nombre de referencia más cercano
    [ -z "$branch" ] && branch=$(git name-rev --name-only --exclude="tags/" --refs="refs/heads/" "$commit_hash" | \
                                sed 's/^origin\///' | \
                                cut -d/ -f1)

    # 4. Limpiar y asegurar rama válida
    branch=$(echo "$branch" | sed -e 's/[~^][0-9]*//g' -e 's/HEAD -> //')
    echo "${branch:-main}"
}

# Funcion para obtener archivos modificados inluidos los merge de commits
get_modified_files() {
    local commit_hash=$1
    local files=$(git diff-tree --no-commit-id --name-only -r "$commit_hash")
    
    # Para un merge commits, obtener todos los archivos modficados incluido los padres
    if git show --no-patch --format="%P" "$commit_hash" | grep -q " "; then
        files+=$'\n'$(git diff --name-only "$commit_hash"^1 "$commit_hash"^2)
    fi
    
    echo "$files" | grep -v "^$" | sort | uniq
}

# Funcion para generar el reporte en HTML
generate_html_report() {
    local today=$1
    local start_time="${today} 00:00:00 -0500"
    local end_time="${today} 23:59:59 -0500"
    local CURRENT_TIME_PERU=$(date +"%Y-%m-%d %H:%M:%S %z")

    # HTML Header
    local html="""<html>
    <head>
    <style>
      /* CSS styles remain the same as previous version */
      body { font-family: Arial, sans-serif; margin: 20px; }
      h2 { color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
      h3 { color: #3498db; margin-top: 25px; }
      table { border-collapse: collapse; width: 100%; margin: 15px 0; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
      th { background-color: #3498db; color: white; padding: 12px; text-align: left; }
      td { padding: 10px; border-bottom: 1px solid #ddd; vertical-align: top; }
      .commit-hash { font-family: monospace; color: #2980b9; font-size: 0.9em; }
      .commit-date { color: #7f8c8d; font-size: 0.9em; }
      .files-list { margin: 0; padding-left: 20px; list-style-type: none; }
      .files-list li { font-family: monospace; margin: 3px 0; padding: 2px 5px; background-color: #f9f9f9; border-radius: 3px; }
      .merge-info { color: #6a1b9a; font-weight: bold; background-color: #f3e5f5; padding: 2px 5px; border-radius: 3px; display: inline-block; }
      .no-files { color: #95a5a6; font-style: italic; }
      .branch-main { background-color: #e8f5e9; padding: 2px 5px; border-radius: 3px; }
      .branch-feature { background-color: #e3f2fd; padding: 2px 5px; border-radius: 3px; }
      /* ... (keep all your existing styles) ... */
    </style>
    </head>
    <body>
    
    <h2>🔍 <strong>REPORTE DE COMMITS - $today</strong></h2>
    <p class="timestamp">Generado el: $CURRENT_TIME_PERU (hora local Perú)</p>"""

    # Configuraciones de usuario
    declare -A users=(
        ["DianaCY-ai"]="diana.carrasco@inetum.com"
        ["Dihani"]="dihani.cy@gmail.com"
    )
    
    # Procesar a cada usuario
    for username in "${!users[@]}"; do
        local email="${users[$username]}"
        local commits=$(git log --since="$start_time" --until="$end_time" \
                      --author="$username" --pretty=format:"%H|%s|%cd|%P" \
                      --date=format:'%H:%M:%S' --all)
        
        if [ -n "$commits" ]; then
            html+="<h3>✅ $username ($email)</h3>"
            html+="<table>"
            html+="<tr><th>Commit ID</th><th>Mensaje</th><th>Hora</th><th>Branch</th><th>Arcivos modificados</th></tr>"
            
            while IFS="|" read -r hash message date parents; do
                local branch=$(get_actual_branch "$hash")
                local files=$(get_modified_files "$hash")
                local branch_class=$([ "$branch" = "main" ] && echo "branch-main" || echo "branch-feature")
                local merge_info=$([ $(echo "$parents" | wc -w) -gt 1 ] && \
                                 echo "<div class='merge-info'>Merge commit</div>")
                
                html+="<tr>"
                html+="<td><span class='commit-hash'>${hash:0:7}</span></td>"
                html+="<td><strong>${message}</strong><br>${merge_info}</td>"
                html+="<td><span class='commit-date'>${date}</span></td>"
                html+="<td><span class='${branch_class}'>${branch}</span></td>"
                html+="<td><ul class='files-list'>"
                
                if [ -n "$files" ]; then
                    while read -r file; do
                        html+="<li>$file</li>"
                    done <<< "$files"
                else
                    html+="<li class='no-files'>No se detectaron archivos modificados</li>"
                fi
                
                html+="</ul></td></tr>"
            done <<< "$commits"
            
            html+="</table>"
        else
            html+="<h3>❌ $username ($email) NO realizó commits hoy.</h3>"
        fi
    done
    
    html+="</body></html>"
    echo "$html"
}
