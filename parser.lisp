(in-package #:acad-help-parser)

(defclass activex-member ()
  ((name :initarg :name :reader activex-member-name)
   (guid :initarg :guid :reader activex-member-guid)
   (kind :initarg :kind :reader activex-member-kind)))

(defclass activex-class ()
  ((name :initarg :name :reader activex-class-name)
   (title :initarg :title :reader activex-class-title)
   (topic-id :initarg :topic-id :reader activex-class-topic-id)
   (context-id :initarg :context-id :reader activex-class-context-id)
   (description :initarg :description :reader activex-class-description)
   (methods :initarg :methods :initform nil :reader activex-class-methods)
   (properties :initarg :properties :initform nil :reader activex-class-properties)
   (events :initarg :events :initform nil :reader activex-class-events)))

(defun select (selector root)
  (coerce (clss:select selector root) 'list))

(defun select-one (selector root)
  (first (select selector root)))

(defun node-text (node)
  (when node
    (string-trim '(#\Space #\Tab #\Newline #\Return)
                 (plump:text node))))

(defun meta-content (root name)
  (let ((node (find name (select "meta" root)
                    :test #'string-equal
                    :key (lambda (node)
                           (plump:attribute node "name")))))
    (when node (plump:attribute node "content"))))

(defun href-guid (href)
  (when href
    (let ((end (search ".htm" href :test #'char-equal)))
      (when (and end (>= end 5)
                 (string-equal "GUID-" href :end2 5))
        (subseq href 0 end)))))

(defun parse-member (node kind)
  (make-instance 'activex-member
                 :name (node-text node)
                 :guid (href-guid (plump:attribute node "href"))
                 :kind kind))

(defun parse-member-column (td kind)
  (loop for link in (select "a" td)
        when (href-guid (plump:attribute link "href"))
          collect (parse-member link kind)))

(defun parse-members (root)
  (let ((table
          (find-if
           (lambda (table)
             (let ((text (node-text table)))
               (and text (search "Methods" text)
                    (search "Properties" text)
                    (search "Events" text))))
           (select "table" root))))
    (unless table
      (return-from parse-members (values nil nil nil)))
    (let* ((data-row
             (find-if (lambda (row)
                        (= 3 (length (select "td" row))))
                      (select "tr" table)))
           (columns (and data-row (select "td" data-row))))
      (if (and columns (= (length columns) 3))
          (values (parse-member-column (first columns) :method)
                  (parse-member-column (second columns) :property)
                  (parse-member-column (third columns) :event))
          (values nil nil nil)))))

(defun class-name-from-document (root)
  (loop for row in (select "tr" root)
        for cells = (select "td" row)
        when (and (>= (length cells) 2)
                  (string-equal "Class Name" (node-text (first cells))))
          return (node-text (second cells))))

(defun parse-activex-class-document (root)
  (multiple-value-bind (methods properties events)
      (parse-members root)
    (make-instance 'activex-class
                   :name (class-name-from-document root)
                   :title (node-text (select-one "title" root))
                   :topic-id (meta-content root "topicid")
                   :context-id (meta-content root "contextid")
                   :description (meta-content root "description")
                   :methods methods
                   :properties properties
                   :events events)))

(defun parse-activex-class (source)
  "Parse an Autodesk ActiveX page from a pathname, stream, or markup string."
  (parse-activex-class-document (plump:parse source)))
