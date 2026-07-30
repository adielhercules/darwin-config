function zz --argument layout
    set -l session (path basename $PWD)
    set -l layout_dir "$HOME/.config/zellij/layouts"
    set -f layout_param

    if test -n "$layout"; and test -f "$layout_dir/$layout.kdl"
        set -f layout_param options --default-layout $layout
    else if test -f "$layout_dir/default.kdl"
        set -f layout_param options --default-layout default
    else
        echo "Layout file: '$layout' not found"
    end

    zellij attach --create $session $layout_param
end

function zr
    zellij run --name "$argv" -- zsh -ic "$argv"
end

function zrf
    zellij run --name "$argv" --floating -- zsh -ic "$argv"
end

function zri
    zellij run --name "$argv" --in-place -- zsh -ic "$argv"
end

function ze
    zellij edit "$argv"
end

function zef
    zellij edit --floating "$argv"
end

function zei
    zellij edit --in-place "$argv"
end

function zpipe
    if test (count $argv) -eq 0
        zellij pipe
    else
        zellij pipe -p $argv[1]
    end
end
