(asdf:defsystem #:acad-help-parser
  :description "Parser for Autodesk ActiveX reference pages"
  :version "0.1.0"
  :serial t
  :depends-on (#:plump #:clss)
  :components ((:file "package")
               (:file "parser")))
