(asdf:defsystem #:acad-help-parser
  :description "Parser and loader for Autodesk ActiveX reference pages"
  :version "0.2.4"
  :serial t
  :depends-on (#:plump #:clss #:dexador #:jonathan #:cl-ppcre)
  :components ((:file "package") (:file "parser") (:file "autodesk-loader")))

(asdf:defsystem #:acad-help-parser/nyxt
  :description "Nyxt integration for acad-help-parser"
  :version "0.2.4"
  :depends-on (#:acad-help-parser)
  :components ((:file "nyxt")))
