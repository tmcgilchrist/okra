(lang dune 3.7)
(name okra)

(generate_opam_files true)

(using mdx 0.3)
(cram enable)

(license ISC)
(authors "Magnus Skjegstad")
(maintainers "magnus@skjegstad.com")
(source (github MagnusS/okra))

(package
 (name okra-bin)
 (synopsis "Report parsing executable")
 (description "An executable to be used for report parsing")
 (depends
  (alcotest :with-test)
  (mdx :with-test)
  logs
  lwt_ssl
  fmt
  okra
  (cmdliner (>= 1.1.0))
  bos
  dune-build-info
  (yaml (>= 3.0))
  (cohttp-lwt-unix (>= 4.0.0))))

(package
 (name okra)
 (synopsis "Report parsing prototypes")
 (description "A library of tools for report parsing")
 (depends
  (ocaml (>= 4.10))
  (alcotest :with-test)
  logs
  fmt
  tls
  get-activity
  (gitlab (>= 0.1.4))
  calendar
  csv
  (omd (>= 2.0.0~alpha3))))
