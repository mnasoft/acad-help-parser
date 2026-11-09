(defpackage #:acad-help-parser
  (:use #:cl)
  (:export
   #:activex-class
   #:activex-class-name
   #:activex-class-title
   #:activex-class-topic-id
   #:activex-class-context-id
   #:activex-class-description
   #:activex-class-methods
   #:activex-class-properties
   #:activex-class-events
   #:activex-member
   #:activex-member-name
   #:activex-member-guid
   #:activex-member-kind
   #:parse-activex-class))
