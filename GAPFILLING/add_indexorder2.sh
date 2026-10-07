#!/bin/bash

assembly=$1
instructions=$2

awk '
FNR==NR {
    # Read assembly file first
    id=$1; gsub(/^>/,"",id)
    split(id,a,":::")
    scaffold=a[1]
    idx[FNR]=$2
    scaf[FNR]=scaffold
    name[FNR]=id
    if(id ~ /debris/) isDebris[FNR]=1
    nLines=FNR
    next
}
{
    # Read instructions_pergap.txt
    instr[++nInstr]=$1
}
END {
    di=0                 # debris instruction counter
    lastscaf=""
    line=""
    for(i=1;i<=nLines;i++) {
        if(lastscaf!="" && scaf[i]!=lastscaf) {
            if(!(scaf[lastIndex] in skipScaf)) {
                print substr(line,2)
            }
            line=""
        }

        if(isDebris[i]) {
            action=instr[++di]
            if(action=="remove") {
                debrisRemoved[ idx[i] ]=1
            } else if(action=="flip") {
                line = line " -" idx[i]
                used[idx[i]]=1
            } else {
                # substitute with provided scaffold name
                for(j=1;j<=nLines;j++) {
                    if(scaf[j]==action && !isDebris[j]) {
                        line=line" "idx[j]
                        skipScaf[action]=1   # mark scaffold as already used
                        used[idx[j]]=1
                        break
                    }
                }
            }
        } else {
            line=line" "idx[i]
            used[idx[i]]=1
        }

        lastscaf=scaf[i]
        lastIndex=i
    }
    if(line!="" && !(scaf[lastIndex] in skipScaf)) {
        print substr(line,2)
    }

    # Print removed debris, one per line
    for(d in debrisRemoved) {
        print d
    }

    # Finally, print all unused scaffolds (not touched at all), in order
    for(i=1;i<=nLines;i++) {
        if(!(idx[i] in used) && !(idx[i] in debrisRemoved)) {
            print idx[i]
        }
    }
}
' "$assembly" "$instructions"
