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
    | where { |it| not (($it | str ends-with "chezmoi.toml") or ($it | str ends-with "niri/monitors.kdl")) }
    | each { |it| rm $it }

    elvos config apply
}

def "elvos security install" [
    config: path                # wg-quick config to enrol
    --manual                    # do not bring wg0 up automatically at boot
    --use-peer-dns              # take DNS from the peer instead of AdGuard
] {
    let file = ($config | path expand)

    if not ($file | path exists) {
        error make { msg: $"no such config file: ($file)" }
    }

    mut args = [$file]
    if $manual { $args = ($args | prepend "--manual") }
    if $use_peer_dns { $args = ($args | prepend "--use-peer-dns") }

    run0 /usr/lib/elvos/wg-enroll ...$args

    print "enrolled. `elvos security on` brings the tunnel up."
}

def "elvos security on" [] {
    run0 /usr/lib/elvos/security on

    print "security on: WireGuard up, AdGuard over TLS."
}

def "elvos security off" [] {
    run0 /usr/lib/elvos/security off

    print "security off: WireGuard down, plain DNS from the network."
    print "run `elvos security on` when you are through the portal."
}

def "elvos security status" [] {
    let tunnel = (
        if ("/sys/class/net/wg0" | path exists) {
            if ((open --raw /sys/class/net/wg0/operstate | str trim) == "down") { "down" } else { "up" }
        } else {
            "not enrolled"
        }
    )

    let global = (
        resolvectl status
        | lines
        | take until {|l| $l | str starts-with "Link " }
        | where {|l| $l =~ "DNS Servers:" }
        | str join " "
        | str trim
    )

    let egress = (
        let out = (do --ignore-errors { ^curl -4 -s --max-time 8 https://ifconfig.co } | default "" | str trim);
        if ($out | is-empty) { "unreachable" } else { $out }
    )

    {
        state: (if ($global | is-empty) { "off" } else { "on" })
        tunnel: $tunnel
        global_dns: (if ($global | is-empty) { "parked" } else { $global })
        egress_ip: $egress
    }
}
