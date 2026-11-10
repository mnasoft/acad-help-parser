(in-package #:acad-help-parser/tests)

(def-suite :acad-help-parser/nyxt)

(in-suite :acad-help-parser/nyxt)

(defun ellipse-url (release)
  (format nil
          "https://help.autodesk.com/view/ACD/~A/ENU/?guid=GUID-85D3077C-DAE6-4BB7-BB69-E8A8BD10FEA5"
          release))

(test ellipse-2015
  (let ((object
          (acad-help-parser:fetch-activex-class-with-nyxt-url
           (ellipse-url 2015)
           :wait t
           :timeout 60)))
    (is (not (null object)))))

(test ellipse-2016
  (let ((object
          (acad-help-parser:fetch-activex-class-with-nyxt-url
           (ellipse-url 2016)
           :wait t
           :timeout 60)))
    (is (not (null object)))))

(test ellipse-2017
  (let ((object
          (acad-help-parser:fetch-activex-class-with-nyxt-url
           (ellipse-url 2017)
           :wait t
           :timeout 60)))
    (is (not (null object)))))
