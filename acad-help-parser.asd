(asdf:defsystem #:acad-help-parser
  :description "Parser and loader for Autodesk ActiveX reference pages"
  :version "0.2.0"
  :serial t
  :depends-on (#:plump #:clss #:dexador #:jonathan #:cl-ppcre)
  :components ((:file "package")
               (:file "parser")
               (:file "autodesk-loader")))
