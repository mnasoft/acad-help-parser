(in-package #:acad-help-parser)

(defparameter *autodesk-bookmark-endpoint*
  "https://beehive.autodesk.com/community/service/rest/cloudhelp/resource/cloudhelpchannel/bookmark/")

(defstruct autodesk-help-descriptor product release language guid)

(defun parse-autodesk-help-url (url)
  "Extract product, release, language, and GUID from an Autodesk view URL."
  (multiple-value-bind (match registers)
      (cl-ppcre:scan-to-strings
       "(?i)^https://help\\.autodesk\\.com/view/([^/?#]+)/([^/?#]+)/([^/?#]+)/?"
       url)
    (declare (ignore match))
    (unless registers
      (error "Unsupported Autodesk help URL: ~A" url))
    (multiple-value-bind (guid-match guid-registers)
        (cl-ppcre:scan-to-strings "(?i)(?:[?&])guid=([^&#]+)" url)
      (declare (ignore guid-match))
      (unless guid-registers
        (error "The Autodesk help URL has no guid parameter: ~A" url))
      (make-autodesk-help-descriptor
       :product (aref registers 0)
       :release (aref registers 1)
       :language (aref registers 2)
       :guid (aref guid-registers 0)))))

(defun autodesk-bookmark-url (descriptor)
  "Build the Autodesk bookmark service URL for DESCRIPTOR."
  (format nil "~A?p=~A&v=~A&l=~A&guid=~A"
          *autodesk-bookmark-endpoint*
          (autodesk-help-descriptor-product descriptor)
          (autodesk-help-descriptor-release descriptor)
          (autodesk-help-descriptor-language descriptor)
          (autodesk-help-descriptor-guid descriptor)))

(defun http-get-string (url)
  (multiple-value-bind (body status)
      (dex:get url :force-string t)
    (unless (= status 200)
      (error "HTTP request failed with status ~D: ~A" status url))
    body))

(defun resolve-autodesk-article-url (view-url)
  "Resolve an Athena view URL to the underlying CloudHelp XHTML URL."
  (let* ((descriptor (parse-autodesk-help-url view-url))
         (json (http-get-string (autodesk-bookmark-url descriptor)))
         (response (jonathan:parse json :as :hash-table))
         (article-url (gethash "url" response)))
    (unless (and article-url (stringp article-url))
      (error "Autodesk bookmark response contains no article URL for ~A"
             view-url))
    article-url))

(defun fetch-activex-document (view-url)
  "Download VIEW-URL's underlying XHTML and return a Plump DOM root."
  (plump:parse
   (http-get-string (resolve-autodesk-article-url view-url))))

(defun fetch-activex-class (view-url)
  "Download and parse an Autodesk ActiveX class page."
  (parse-activex-class-document
   (fetch-activex-document view-url)))
