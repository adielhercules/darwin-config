function ask
    set -l prompt_parts
    set -l passthrough
    set -l has_allow_flag 0
    set -l resume_id
    set -l interactive_resume 0
    set -l filter_by_path 0

    for arg in $argv
        switch $arg
            case '--allow-tool=*' '--allow-tool' '--allow-all-tools'
                set has_allow_flag 1
                set -a passthrough $arg
            case '--c=*'
                set resume_id (string replace -r '^--c=' '' -- $arg)
            case '--c'
                set interactive_resume 1
                set filter_by_path 1
            case '--ca'
                set interactive_resume 1
                set filter_by_path 0
            case '-*'
                set -a passthrough $arg
            case '*'
                set -a prompt_parts $arg
        end
    end

    set -l sessions_dir "$HOME/development/ask"
    set -l sessions_file "$sessions_dir/sessions.json"

    if test $interactive_resume -eq 1 -a -z "$resume_id"
        if not test -f $sessions_file
            echo "No matching sessions found, continuing without resume."
        else
            set -l current_path (pwd)
            set -l fzf_input
            if test "$filter_by_path" = "1"
                set fzf_input (jq -r --arg p "$current_path" '.[] | select(.path == $p) | "\(.session_id)\t\(.prompt)\t\(.path)"' $sessions_file)
            else
                set fzf_input (jq -r '.[] | "\(.session_id)\t\(.prompt)\t\(.path)"' $sessions_file)
            end

            if test -z "$fzf_input"
                echo "No matching sessions found, continuing without resume."
            else
                set -l selected (printf '%s\n' $fzf_input | fzf --delimiter='\t' --with-nth=2,3)
                if test -n "$selected"
                    set resume_id (string split -f1 \t -- $selected)
                end
            end
        end
    end

    if test (count $prompt_parts) -eq 0
        read -l -P "ask> " user_input
        set prompt_parts $user_input
    end

    echo "Thinking..."

    set -l current_datetime (date -u +"%Y-%m-%dT%H:%M:%SZ")

    set -l cmd copilot -p "$prompt_parts"
    if test $has_allow_flag -eq 0
        set -a cmd --allow-tool="web_fetch"
    end
    set -a cmd $passthrough
    if test -n "$resume_id"
        set -a cmd --resume=$resume_id
    end

    set -l tmpfile (mktemp)
    $cmd 2>&1 | tee $tmpfile

    set -l session_id (string match -r '(?:^|\n)Resume\s+copilot --resume=([0-9a-fA-F-]+)' -g < $tmpfile)

    if test -n "$session_id"
        mkdir -p $sessions_dir
        if not test -f $sessions_file
            echo '[]' >$sessions_file
        end

        set -l already_exists (jq --arg id "$session_id" 'any(.[]; .session_id == $id)' $sessions_file)

        if test "$already_exists" != true
            set -l current_path (pwd)
            set -l tmp_json (mktemp)
            jq --arg prompt "$prompt_parts" \
                --arg session_id "$session_id" \
                --arg path "$current_path" \
                --arg datetime "$current_datetime" \
                '. + [{prompt: $prompt, session_id: $session_id, path: $path, datetime: $datetime}]' \
                $sessions_file >$tmp_json
            mv $tmp_json $sessions_file
        end
    end

    rm -f $tmpfile
end
