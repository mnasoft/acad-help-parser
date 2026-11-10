(asdf:defsystem #:acad-help-parser
  :description "Parser and loader for Autodesk ActiveX reference pages"
  :version "0.2.6"
  :serial t
  :depends-on (#:plump #:clss #:dexador #:jonathan #:cl-ppcre)
  :components ((:file "package")
               (:file "parser")
               (:file "autodesk-loader")))

(asdf:defsystem #:acad-help-parser/nyxt
  :description "Nyxt integration for acad-help-parser"
  :depends-on (#:acad-help-parser)
  :components ((:file "nyxt"))
  :in-order-to
  ((asdf:test-op
    (asdf:test-op #:acad-help-parser/nyxt/tests))))

(asdf:defsystem #:acad-help-parser/nyxt/tests
  :description "Integration tests for acad-help-parser/nyxt"
  :depends-on (#:acad-help-parser/nyxt
               #:fiveam)
  :serial t
  :components
  ((:file "tests/package")
   (:file "tests/nyxt"))
  :perform
  (asdf:test-op (op system)
    (declare (ignore op system))
    (uiop:symbol-call
     :fiveam
     :run!
     :acad-help-parser/nyxt)))
