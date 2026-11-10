(in-package #:acad-help-parser)
(defclass activex-member () ((name :initarg :name :reader activex-member-name) (guid :initarg :guid :reader activex-member-guid) (kind :initarg :kind :reader activex-member-kind)))
(defclass activex-class () ((name :initarg :name :reader activex-class-name) (title :initarg :title :reader activex-class-title) (topic-id :initarg :topic-id :reader activex-class-topic-id) (context-id :initarg :context-id :reader activex-class-context-id) (description :initarg :description :reader activex-class-description) (methods :initarg :methods :initform nil :reader activex-class-methods) (properties :initarg :properties :initform nil :reader activex-class-properties) (events :initarg :events :initform nil :reader activex-class-events)))
(defmethod print-object ((object activex-member) stream)
  (print-unreadable-object (object stream :type t :identity nil)
    (format stream "~A ~A ~A"
            (activex-member-kind object)
            (activex-member-name object)
            (activex-member-guid object))))

(defun print-member-names (stream label members)
  (format stream "~%  ~A (~D):" label (length members))
  (dolist (member members)
    (format stream "~%    ~A" (activex-member-name member))))

(defmethod print-object ((object activex-class) stream)
  (print-unreadable-object (object stream :type t :identity nil)
    (format stream "~A~%  topic-id: ~A"
            (or (activex-class-name object) "?")
            (or (activex-class-topic-id object) "?"))
    (print-member-names stream "methods" (activex-class-methods object))
    (print-member-names stream "properties" (activex-class-properties object))
    (print-member-names stream "events" (activex-class-events object))))

(defun select (s r) (coerce (clss:select s r) 'list))
(defun select-one (s r) (first (select s r)))
(defun node-text (n) (when n (string-trim '(#\Space #\Tab #\Newline #\Return) (plump:text n))))
(defun meta-content (r name) (let ((n (find name (select "meta" r) :test #'string-equal :key (lambda (x) (plump:attribute x "name"))))) (when n (plump:attribute n "content"))))
(defun href-guid (h) (when h (let ((e (search ".htm" h :test #'char-equal))) (when (and e (>= e 5) (string-equal "GUID-" h :end2 5)) (subseq h 0 e)))))
(defun parse-member (n k) (make-instance 'activex-member :name (node-text n) :guid (href-guid (plump:attribute n "href")) :kind k))
(defun parse-member-column (td k) (loop for a in (select "a" td) when (href-guid (plump:attribute a "href")) collect (parse-member a k)))
(defun parse-members (r) (let ((table (find-if (lambda (x) (let ((s (node-text x))) (and s (search "Methods" s) (search "Properties" s) (search "Events" s)))) (select "table" r)))) (unless table (return-from parse-members (values nil nil nil))) (let* ((row (find-if (lambda (x) (= 3 (length (select "td" x)))) (select "tr" table))) (c (and row (select "td" row)))) (if (and c (= 3 (length c))) (values (parse-member-column (first c) :method) (parse-member-column (second c) :property) (parse-member-column (third c) :event)) (values nil nil nil)))))
(defun definition-value (r term) (loop for dt in (select "dt" r) for text = (node-text dt) when (and text (string-equal term text)) return (plump:next-element dt)))
(defun class-name-from-document (r) (let ((dd (definition-value r "Class Name"))) (when dd (let ((n (select-one "samp" dd))) (and n (node-text n))))))
(defun parse-activex-class-document (r &key topic-id)
  (multiple-value-bind (m p e)
      (parse-members r)
    (make-instance 'activex-class
                   :name (class-name-from-document r)
                   :title (node-text (select-one "title" r))
                   :topic-id (or (meta-content r "topicid")
                                 topic-id)
                   :context-id (meta-content r "contextid")
                   :description (meta-content r "description")
                   :methods m
                   :properties p
                   :events e)))

(defun parse-activex-class (source) (parse-activex-class-document (plump:parse source)))

(defun select-xref (root &optional (selector "a"))
  (remove-if-not
   (lambda (node)
     (member "xref"
             (uiop:split-string
              (or (plump:attribute node "class") "")
              :separator " ")
             :test #'string=))
   (select selector root)))
