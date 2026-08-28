alias ll = ls --long
alias la = ls --all
alias lla = ls --all --long

def lt [path?: path] {
    (if $path == null { ls --long } else { ls --long $path }) | sort-by modified
}

alias ".." = cd ..
alias "..." = cd ../..
alias "...." = cd ../../..

def --env mkcd [path: path] {
    mkdir $path
    cd $path
}

alias j = jj
alias js = jj status
alias jl = jj log
alias jd = jj diff
alias jn = jj new
alias jb = jj bookmark

alias g = git
alias gs = git status
alias gd = git diff
alias gl = git log --oneline --graph --decorate

alias sc = systemctl
alias scu = systemctl --user
alias jctl = journalctl

alias boot-errors = journalctl --boot --priority=err..warning

alias root = run0

def elvos-wifi-device []: nothing -> string {
    let devices = (
        ls /sys/class/net
        | get name
        | path basename
        | where {|nic| ($"/sys/class/net/($nic)/wireless" | path exists) }
    )

    if ($devices | is-empty) {
        error make { msg: "no wireless interface found under /sys/class/net" }
    }

    $devices | first
}

def "wifi scan" [] {
    let device = (elvos-wifi-device)
    iwctl station $device scan
    sleep 3sec
    iwctl station $device get-networks
}

def "wifi connect" [ssid: string] {
    iwctl station (elvos-wifi-device) connect $ssid
}

def "wifi status" [] {
    iwctl station (elvos-wifi-device) show
}

def "elvos version" [] {
    open --raw /etc/os-release
    | lines
    | parse --regex '^(?<key>[A-Z0-9_]+)="?(?<value>.*?)"?$'
}

def "elvos config list" [] {
    chezmoi managed --include files
}

def "elvos config apply" [] {
    chezmoi apply --force --no-tty
}

def "elvos config reset" [] {
    elvos config list
    | lines
    | each { |it| $env.HOME | path join $it }
    | where { |it| not ($it | str ends-with "chezmoi.toml") }
    | each { |it| rm $it }

    elvos config apply
}
