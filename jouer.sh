#! /usr/bin/env bash
#set -ex
# We need `false | true` to fail because of false (see [gray])
set -o pipefail

DEBUG=
for p in $@; do
    case $p in
        -d|--debug) DEBUG="yes";;
    esac
done

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

cp allumettes2.touist temp
a_gagne=false
while ! $a_gagne; do
    touist temp --solve --qbf | sort -k2 -t"(" -n | grep '^[^?] ' > result || exit 1
    if grep "0_a_perdu" result | gray; then echo "Joueur 0 a gagné"; exit 0; fi
    while read line; do
        if echo $line | grep -q "[01] prend2"; then
            nb_allum=$(echo $line | sed "s/^\([01]\) prend2.*/\1/g")
            num_coup=$(echo $line | sed "s/^[01] prend2(\([0-9][0-9]*\))/\1/g")
            #perl -n -e '/([01]) prend2\((\d+)\)$/ && print $1 $2'
        fi
        if echo $line | grep -q "^1 reste($((num_coup+1)),"; then
            reste=$(echo $line | sed "s/^1 reste(.*,\([0-9]*\)).*$/\1/g")
        fi
    done < result
    [ -z $DEBUG ] || grep "^\(1 reste(\|. prend2\)" result | gray
    echo "Tour $num_coup: $(joueur $((num_coup%2))) doit prendre $([ "$nb_allum" -eq 0 ] && echo 1 || echo 2) allumettes (et reste $reste allumettes)"

    # Winning condition
    if grep -q "^1 reste(.*,0)" result; then
        a_gagne=true
    else
        echo -n "Tour $((num_coup+1)): $(joueur $(((num_coup+1)%2)))  prend 1 ou 2 au tour $((num_coup+1)) ? "
        read choix
        # Now, we want to replace the forall by a exists:
        #             forall prend2(7):
        # becomes     exists prend2(7): [not] prend2(7) and
        sed "s/^\(forall\|exists\) prend2($((num_coup+1))):\(.*\)$/exists prend2($((num_coup+1))): $([[ $choix -eq 1 ]] && echo not) prend2($((num_coup+1))) and \2/g" temp > $$ && mv $$ temp

        [ -z $DEBUG ] || grep "^\(exists\|forall\) prend" temp | while IFS= read line; do
            echo $line | gray
        done
    fi

done


# exists prend2(0): ;; joueur 0 (nous)
# forall prend2(1): prend2(1) and ;; joueur 1 (adversaire)
# exists prend2(2): ;; joueur 0 (nous)
# forall prend2(3): ;; joueur 1 (adversaire)

