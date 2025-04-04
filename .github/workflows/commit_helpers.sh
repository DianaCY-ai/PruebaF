#!/bin/bash

# Function to get the actual branch name for a commit
get_actual_branch() {
    local commit_hash=$1
    
    # First try: check reflog for branch names
    local branch=$(git reflog --format='%gs' | \
                   grep -m1 "$commit_hash" | \
                   sed -n 's/^.checkout: moving from [^ ] to \(.*\)$/\1/p')
    
    # Second try: find branches containing this commit
    [ -z "$branch" ] && branch=$(git branch -r --contains "$commit_hash" | \
                                sed 's/^[ \t]*origin\///' | \
                                grep -v "HEAD" | \
                                head -n1)
    
    # Third try: find tags containing this commit
    [ -z "$branch" ] && branch=$(git tag --contains "$commit_hash" | head -n1)
    
    # Fallback: use commit reference
    [ -z "$branch" ] && branch=$(git name-rev --name-only --exclude="tags/*" "$commit_hash" | \
                                sed 's/^remotes\/origin\///')
    
    # Clean up branch name
    branch=$(echo "$branch" | sed -e 's/[~^][0-9]*//g' -e 's/HEAD -> //')
    
    # Default to main if still empty or contains invalid characters
    if [ -z "$branch" ] || [[ "$branch" =~ [\~\^] ]]; then
        echo "main"
    else
        echo "$branch"
    fi
}

# Function to get modified files including merge commits
get_modified_files() {
    local commit_hash=$1
    local files=$(git diff-tree --no-commit-id --name-only -r "$commit_hash")
    
    # For merge commits, get all changed files between parents
    if git show --no-patch --format="%P" "$commit_hash" | grep -q " "; then
        files+=$'\n'$(git diff --name-only "$commit_hash"^1 "$commit_hash"^2)
    fi
    
    echo "$files" | grep -v "^$" | sort | uniq
}

# Function to generate HTML report
generate_html_report() {
    local today=$1
    local start_time="${today} 00:00:00 -0500"
    local end_time="${today} 23:59:59 -0500"
    
    # HTML Header
    local html="""<html>
    <head>
    <style>
      /* CSS styles remain the same as previous version */
      body { font-family: Arial, sans-serif; margin: 20px; }
      /* ... (keep all your existing styles) ... */
    </style>
    </head>
    <body>
    <h2>🔍 COMMIT REPORT - $today</h2>"""
    
    # User configuration
    declare -A users=(
        ["DianaCY-ai"]="diana.carrasco@inetum.com"
        ["Dihani"]="dihani.cy@gmail.com"
    )
    
    # Process each user
    for username in "${!users[@]}"; do
        local email="${users[$username]}"
        local commits=$(git log --since="$start_time" --until="$end_time" \
                      --author="$username" --pretty=format:"%H|%s|%cd|%P" \
                      --date=format:'%Y-%m-%d %H:%M:%S' --all)
        
        if [ -n "$commits" ]; then
            html+="<h3>✅ $username ($email)</h3>"
            html+="<table>"
            html+="<tr><th>Commit ID</th><th>Message</th><th>Date/Time</th><th>Branch</th><th>Modified Files</th></tr>"
            
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
                    html+="<li class='no-files'>No modified files detected</li>"
                fi
                
                html+="</ul></td></tr>"
            done <<< "$commits"
            
            html+="</table>"
        else
            html+="<h3>❌ $username ($email) NO commits today.</h3>"
        fi
    done
    
    html+="</body></html>"
    echo "$html"
}