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

cp allumettes2.touist temp

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
                cp allumettes2.touist a
                echo "\$Nb=$i" >> a
                touist --qbf a >/dev/null && echo "$i" || true
                ((i++))
            done
            exit
        ;;
        *)
            echo "\$Nb = $p" >> temp
            echo "On joue avec $p allumettes"
        ;;
    esac
done

a_gagne=false
while ! $a_gagne; do
    touist temp --solve --qbf | sort -k2 -t"(" -n | grep '^[^?] ' > result || exit 1
    if grep "0_a_perdu" result | gray; then echo "Joueur 0 a gagné"; exit 0; fi
    reste=?
    prend_2=0
    num_coup=0
    while read line; do
        if echo $line | grep -q "[01] prend2"; then
            prend_2=$(echo $line | sed "s/^\([01]\) prend2.*/\1/g")
            num_coup=$(echo $line | sed "s/^[01] prend2(\([0-9][0-9]*\))/\1/g")
            #perl -n -e '/([01]) prend2\((\d+)\)$/ && print $1 $2'
        fi
        if echo $line | grep -q "^1 reste($((num_coup+1)),"; then
            reste=$(echo $line | sed "s/^1 reste(.*,\([0-9]*\)).*$/\1/g")
        fi
    done < result
    [ -z $DEBUG ] || grep "^\(1 reste(\|. prend2\)" result | gray
    echo "Tour $num_coup: $(joueur $((num_coup%2))) doit prendre $([ "$prend_2" -eq 0 ] && echo 1 || echo 2) allumettes (et reste $reste allumettes)"

    # We must be sure we won't change our choice anytime after this point
    sed "s/^\(.*\)\(forall\|exists\) prend2($num_coup):\(.*\)$/\1exists prend2($num_coup): $([[ $prend_2 -eq 0 ]] && echo 'not ')prend2($num_coup) and\3/g" temp > $$ && mv $$ temp

    # Winning condition
    if grep -q "^1 reste(.*,0)" result; then
        a_gagne=true
    else
        echo -n "Tour $((num_coup+1)): $(joueur $(((num_coup+1)%2))) en prend 1 ou 2? "
        read choix
        # Now, we want to replace the forall by a exists:
        #             forall prend2(7):
        # becomes     exists prend2(7): [not] prend2(7) and
        sed "s/^\(.*\)\(forall\|exists\) prend2($((num_coup+1))):\(.*\)$/\1exists prend2($((num_coup+1))): $([[ $choix -eq 1 ]] && echo 'not ')prend2($((num_coup+1))) and \3/g" temp > $$ && mv $$ temp

        [ -z $DEBUG ] || grep "^\(exists\|forall\) prend" temp | gray
    fi

done


# exists prend2(0): ;; joueur 0 (nous)
# forall prend2(1): prend2(1) and ;; joueur 1 (adversaire)
# exists prend2(2): ;; joueur 0 (nous)
# forall prend2(3): ;; joueur 1 (adversaire)

