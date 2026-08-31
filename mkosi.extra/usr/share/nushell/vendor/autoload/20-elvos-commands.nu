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

def "elvos vpn enroll" [config: path] {
    let file = ($config | path expand)

    if not ($file | path exists) {
        error make { msg: $"no such config file: ($file)" }
    }

    run0 /usr/lib/elvos/wg-enroll $file
}

def "elvos vpn up" [] {
    run0 networkctl up wg0
}

def "elvos vpn down" [] {
    run0 networkctl down wg0
}

def "elvos vpn status" [--full] {
    if not ("/sys/class/net/wg0" | path exists) {
        print "wg0 does not exist - not enrolled, or systemd-networkd needs a restart"
        return
    }

    if $full {
        run0 wg show wg0
    } else {
        networkctl status wg0
    }
}

def "elvos vpn ip" [] {
    let probe = {|flag|
        let out = (do --ignore-errors { ^curl $flag -s --max-time 10 https://ifconfig.co } | default "" | str trim)
        if ($out | is-empty) { "unreachable" } else { $out }
    }

    { v4: (do $probe "-4"), v6: (do $probe "-6") }
}

def elvos-portal-resolver [device: string]: nothing -> string {
    let gateways = (
        ip -json route show default dev $device
        | from json
        | get gateway?
        | compact
    )

    if ($gateways | is-empty) {
        error make { msg: $"no default gateway on ($device) - join the network first" }
    }

    $gateways | first
}

def "elvos portal probe" [] {
    let device = (elvos-wifi-device)
    let gateway = (elvos-portal-resolver $device)

    let http = {|url|
        let r = (^curl -s -m 8 --interface $device -o /dev/null -w '%{http_code}\t%{redirect_url}' $url | complete)

        if $r.exit_code != 0 {
            { code: (if $r.exit_code == 28 { "timeout" } else { "unreachable" }), redirect: "" }
        } else {
            let parts = ($r.stdout | str trim | split row "\t")
            { code: ($parts | get 0), redirect: ($parts | get 1? | default "") }
        }
    }

    let gw = (do $http $"http://($gateway)/")
    let net = (do $http "http://connectivitycheck.gstatic.com/generate_204")

    let intercepted = (($gw.code | str starts-with "3") and ($gw.redirect | is-not-empty))

    {
        device: $device
        gateway: $gateway

        advertised_portal: (
            do --ignore-errors {
                networkctl status $device --json=short | from json | get CaptivePortal?
            }
        )
        link_dns: (resolvectl dns $device | str trim)
        global_dns: (
            resolvectl status
            | lines
            | take until {|l| $l | str starts-with "Link " }
            | where {|l| $l =~ "DNS Servers:" }
            | str join " "
            | str trim
        )
        generate_204: $net.code
        gateway_http: $gw.code
        portal_host: (if $intercepted { $gw.redirect | url parse | get host } else { null })
        login_url: (if $intercepted { $"http://($gateway)/" } else { null })
        verdict: (
            if $intercepted {
                "captive portal - run `elvos portal login`"
            } else if ($net.code == "204") {
                "open - nothing is intercepting; no login needed"
            } else {
                "blocked, and the gateway offers no redirect - not an HTTP portal"
            }
        )
    }
}

def "elvos portal login" [] {
    let probe = (elvos portal probe)

    if ($probe.login_url | is-empty) {
        print $"no captive portal detected: ($probe.verdict)"
        return
    }

    print $"opening ($probe.login_url) -> ($probe.portal_host)"
    ^setsid --fork xdg-open $probe.login_url
}

def "elvos portal up" [resolver?: string] {
    let device = (elvos-wifi-device)

    if $resolver == null {
        run0 /usr/lib/elvos/portal-mode up $device
    } else {
        run0 /usr/lib/elvos/portal-mode up $device $resolver
    }

    print $"portal mode on: ($device) resolvers widened to ~., AdGuard parked, wg0 down."
    elvos portal login
}

def "elvos portal down" [] {
    run0 /usr/lib/elvos/portal-mode down (elvos-wifi-device)

    print "portal mode off: AdGuard over TLS and wg0 restored."
}

def "elvos portal status" [] {
    resolvectl status (elvos-wifi-device)
}
