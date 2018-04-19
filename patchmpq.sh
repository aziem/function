#!/bin/bash

sed -i '28s/^.*/OCAMLOPTLIBS = bigarray.cmxa gmp.cmxa apron.cmxa boxMPQ.cmxa octMPQ.cmxa zarith.cmxa polkaMPQ.cmxa str.cmxa #threads.cmxa/' Makefile
