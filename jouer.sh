#! /usr/bin/env bash
set -ex

touist allumettes2.touist --solve --qbf | sort -k2 -t"(" | grep '^[^?] ' > a
cat a
cat a | tail -1 | sed "s/[01] prend2(\([0-9][0-9]*\))/\1/g"



# exists prend2(0): ;; joueur 0 (nous)
# forall prend2(1): prend2(1) and ;; joueur 1 (adversaire)
# exists prend2(2): ;; joueur 0 (nous)
# forall prend2(3): ;; joueur 1 (adversaire)

