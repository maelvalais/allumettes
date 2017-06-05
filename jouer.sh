#! /usr/bin/env bash
#set -ex

cp allumettes2.touist temp
a_gagne=false
while ! $a_gagne; do
    touist temp --solve --qbf | sort -k2 -t"(" | grep '^[^?] ' > result
    if grep "0 0_a_perdu" result; then echo "Joueur 0 a gagné"; exit 0; fi
    while read line; do
        nb_allum=$(echo $line | sed "s/^\([01]\) .*/\1/g")
        num_coup=$(echo $line | sed "s/^[01] prend2(\([0-9][0-9]*\))/\1/g")
        #perl -n -e '/([01]) prend2\((\d+)\)$/ && print $1 $2'
        echo "Au coup $num_coup: le joueur $((num_coup % 2)) doit prendre $([ "$nb_allum" -eq 0 ] && echo 1 || echo 2) allumettes"
    done < result

    # Now, we want to replace the forall by a exists:
    #             forall prend2(7):
    # becomes     exists prend2(7): [not] prend2(7) and

    echo "Adversaire prend 1 ou 2 au tour $((num_coup+1)) ?"
    read choix
    sed "s/^forall prend2($((num_coup+1))):/exists prend2($((num_coup+1))): $([[ $choix -eq 1 ]] && echo not) prend2($((num_coup+1))) and/g" temp > $$ && mv $$ temp

    grep "\(exists\|forall\)" temp | while IFS= read line; do
        echo -e "\033[90m${line}\033[0m"
    done
done


# exists prend2(0): ;; joueur 0 (nous)
# forall prend2(1): prend2(1) and ;; joueur 1 (adversaire)
# exists prend2(2): ;; joueur 0 (nous)
# forall prend2(3): ;; joueur 1 (adversaire)

