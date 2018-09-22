#!/usr/bin/env awk
# by klzsysy


BEGIN {
    
    printf "# this is auto build for Sonny yum mirror tools\n"
    printf "# ---------------------------------------------\n"
    repo=""
    status=0
    servername=ENVIRON["SERVER_NAME"]

    if (servername !~ /\/$/) {
        servername = servername "/"
    }

    if (servername !~ /^https?:\/\//) {
        servername = "http://" servername
    }
    # print servername
}

{

    if (/^\[.*\]/) {
        if (status==1) {
            repo = repo "priority=90\n\n"
        }
        repo = repo "\n"
        repo = repo $0 "\n"
        status=1
    }

        # print repo
    if (/^name/) {
        repo = repo $0 "\n"
    }

    
    if (/^localpath/) {
        # gsub(/https?:\/\/[a-zA-Z0-9][-a-zA-Z0-9]{0,62}(\.[a-zA-Z0-9][-a-zA-Z0-9]{0,62})+\//, servername)
        gsub(/localpath=/, "")
        repo = repo "baseurl="
        repo = repo servername $0 "\n"
        repo = repo "enabled=1\n"
        repo = repo "gpgcheck=0\n"

    }

    if (/^priority=[0-9]+/) {
        repo = repo $0 "\n"
        status=2
    }
    lines[NR] = $0
    # repos[]
}

END {
    if (lines[NR] !~ /^priority/) {
        repo = repo "priority=90\n"
    }
    print repo
}