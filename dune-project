(lang dune 2.7)
(name ppx_map)
(version 0.2.1)
(generate_opam_files true)
(license MIT)
(authors "Benjamin Somers <benjamin.somers@imt-atlantique.fr>")
(maintainers "Benjamin Somers <benjamin.somers@imt-atlantique.fr>")
(homepage "https://github.com/bensmrs/ppx_map")
(source (github "bensmrs/ppx_map"))
(bug_reports "https://github.com/bensmrs/ppx_map/issues")

(package
 (name ppx_map)
 (synopsis "A PPX rewriter to simplify the declaration of maps")
 (description "This package allows to declare maps in an expressive way using [key => value] expressions")
 (depends
  (alcotest (and :with-test (>= 1.6.0)))
  (ppxlib (>= 0.27.0))))
