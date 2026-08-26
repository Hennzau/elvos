$env.config.show_banner = false

$env.config.edit_mode = "emacs"
$env.config.error_style = "fancy"
$env.config.rm.always_trash = true

$env.config.table.mode = "rounded"
$env.config.table.index_mode = "auto"
$env.config.table.header_on_separator = false
$env.config.footer_mode = 25

$env.config.completions.algorithm = "fuzzy"
$env.config.completions.case_sensitive = false
$env.config.completions.quick = true
$env.config.completions.partial = true

$env.config.history.file_format = "sqlite"
$env.config.history.max_size = 1_000_000
$env.config.history.isolation = true

$env.config.shell_integration.osc7 = true
$env.config.shell_integration.osc8 = true
$env.config.shell_integration.osc133 = true
$env.config.ls.clickable_links = true

$env.config.cursor_shape.emacs = "line"
$env.config.cursor_shape.vi_insert = "line"
$env.config.cursor_shape.vi_normal = "block"

let editor = if ($env.WAYLAND_DISPLAY? | is-not-empty) { "zeditor --wait" } else { "nano" }
$env.EDITOR = $editor
$env.VISUAL = $editor
$env.config.buffer_editor = $editor

if ($env.PATH | describe | str starts-with "list") {
    $env.PATH = (
        [$"($nu.home-dir)/.local/bin" $"($nu.home-dir)/.cargo/bin"] ++ $env.PATH | uniq
    )
}
