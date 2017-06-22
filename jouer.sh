#! /usr/bin/env bash
#set -ex
# We need `false | true` to fail because of false (see [gray])
set -o pipefail


# Parameter: turn number
function joueur() {
    if (($1 == 0)); then
        echo -ne "\033[92mjoueur $1\033[0m"
    else
        echo -ne "\033[91mjoueur $1\033[0m"
    fi
}
# In order to fail if the command that is piped to [gray] fails, the calling
# script must be set with `set -o pipefail`.
function gray() {
    echo -ne "\033[90m"
    cat /dev/stdin
    echo -ne "\033[0m"
}

function usage() {
cat <<-EOF
Usage: $0 [-d] N
Usage: $0 -l
Options:
    N                 the number of matches
    -d | --debug      enable the debug mode to see what happens
    -l | --list       list the N where the player 0 has a winning strategy
EOF
exit 0
}

cp allumettes2.touist temp.touist

DEBUG=
for p in $@; do
    case $p in
        -d|--debug)
            DEBUG="yes"
        ;;
        -l|--list)
            echo "Nombre d'allumettes valides pour que $(joueur 0) gagne:"
            i=1
            while ((i<=27)); do
                cp allumettes2.touist temp.touist
                sed "s/\\\$NA = [0-9]*/\$NA = $i/" temp.touist > t && mv t temp.touist
                [ -z $DEBUG ] || head -1 temp.touist | gray
                touist --qbf temp.touist >/dev/null && echo "$i" || true
                ((i++))
            done
            exit
        ;;
        -h|--help)
            usage
        ;;
        *)
            sed "s/\\\$NA = [0-9]*/\$NA = $p/" temp.touist > t && mv t temp.touist
            echo "On joue avec $p allumettes"
        ;;
    esac
done

# The player 0 wins as soon as the proposition 'reste(_,0)' is true.
a_gagne=false
while ! $a_gagne; do
    touist temp.touist --solve --qbf | sort -k2 -t"(" -n | grep '^[^?] ' > result || exit 1
    reste=?
    while read line; do
        if echo $line | grep -q "[01] prend"; then
            prend_2=$(echo $line | sed "s/^\([01]\) prend.*/\1/g")
            num_coup=$(echo $line | sed "s/^[01] prend_2(\([0-9][0-9]*\).*/\1/g")
            #perl -n -e '/([01]) prend\((\d+)\),.*$/ && print $1 $2'
        fi
        if echo $line | grep -q "^1 reste($((num_coup+1)),"; then
            reste=$(echo $line | sed "s/^1 reste(.*,\([0-9]*\)).*$/\1/g")
        fi
    done < result
    [ -z $DEBUG ] || grep "^\(1 reste(\|[01]* prend\)" result | gray
    echo "Tour $num_coup: $(joueur $((num_coup%2))) doit prendre $([ "$prend_2" -eq 0 ] && echo 1 || echo 2) allumettes (et reste $reste allumettes)"

    # We must be sure we won't change our choice anytime after this point
    sed "s/^\(.*\)\(forall\|exists\) prend_2($num_coup):\(.*\)$/\1exists prend_2($num_coup): $([[ $prend_2 -eq 0 ]] && echo 'not ')prend_2($num_coup) and\3/g" temp.touist > $$ && mv $$ temp.touist

    # Winning condition
    if grep -q "^1 reste(.*,0)" result; then
        a_gagne=true
    else
        echo -n "Tour $((num_coup+1)): $(joueur $(((num_coup+1)%2))) en prend 1 ou 2? "
        read choix
        # Now, we want to replace the forall by a exists:
        #             forall prend_2(7):
        # becomes     exists prend_2(7): [not] prend_2(7) and
        sed "s/^\(.*\)\(forall\|exists\) prend_2($((num_coup+1))):\(.*\)$/\1exists prend_2($((num_coup+1))): $([[ $choix -eq 1 ]] && echo 'not ')prend_2($((num_coup+1))) and \3/g" temp.touist > $$ && mv $$ temp.touist

        [ -z $DEBUG ] || grep "^\(exists\|forall\) prend" temp.touist | gray
    fi

done
echo "Joueur 0 a gagné"; exit 0


# exists prend_2(0): ;; joueur 0 (nous)
# forall prend_2(1): prend_2(1) and ;; joueur 1 (adversaire)
# exists prend_2(2): ;; joueur 0 (nous)
# forall prend_2(3): ;; joueur 1 (adversaire)

