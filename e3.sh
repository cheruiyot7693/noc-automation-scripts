#!/usr/bin/expect

# =====================================================
# Author: Brian
# Purpose: SSH into multiple repeater RCPs and fetch optical parameters)
# =====================================================

set timeout 20


source creds.secret.conf
source nodes.secret.conf


log_file -a noc_session.log


set nodes {
    "NODE01,port-u13/1"
    "NODE02,port-u7/1"
    "NODE03,port-u1/1"
    "NODE04,port-u0/1"
    "NODE05,port-u1/1"
}

# ---- Main Loop ----
foreach node $nodes {

    set parts   [split $node ","]
    set node_id [lindex $parts 0]
    set port    [lindex $parts 1]

    # Resolve real IP from secret mapping
    if {![dict exists $NODE_IPS $node_id]} {
        puts "$node_id: No IP mapping found"
        continue
    }

    set host [dict get $NODE_IPS $node_id]

    puts " Connecting to $node_id ($host)"

    spawn ssh $username@$host

    expect {
        -re "authenticity of host.*" {
            send "yes\r"
            exp_continue
        }

        -re "Password:" {
            send "$password\r"
            exp_continue
        }

        -re "Last login:" {
            puts " $node_id: Login successful"
            expect ">"
            send "show chassis port oncp $port | grep Actual\r"
            expect ">"
            send "exit\r"
        }

        -re "Permission denied" {
            puts " $node_id: Authentication failed"
        }

        -re "Connection refused" {
            puts " $node_id: Connection refused"
        }

        timeout {
            puts " $node_id: Connection timed out"
        }

        eof {
            puts " $node_id: Connection closed unexpectedly"
        }
    }
}

# ---- Close log ----
log_file
puts "Done go fetch the log file for further analysis"
