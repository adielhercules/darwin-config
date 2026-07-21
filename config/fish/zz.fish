function zz --argument layout
  set -l session (path basename $PWD)
  set -l layout_dir "$HOME/.config/zellij/layouts"
  set -f layout_param

  if test -n "$layout"; and test -f "$layout_dir/$layout.kdl"
    set -f layout_param "options" "--default-layout" $layout
  else if test -f "$layout_dir/default.kdl"
    set -f layout_param "options" "--default-layout" "default"
  else
    echo "Layout file: '$layout' not found"
  end

  zellij attach --create $session $layout_param
end
