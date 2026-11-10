;;;; nyxt.lisp

(in-package #:acad-help-parser)

(defun fetch-dom-with-nyxt (buffer &key iframe)
  "Return the current DOM of BUFFER as an HTML string.

When IFRAME is non-NIL, it must be a CSS selector identifying
an iframe.  In that case return the DOM of the document contained
in that iframe."

  (nyxt:ffi-buffer-evaluate-javascript
   buffer
   (if iframe
       (format nil
               "(function () {
                  const frame = document.querySelector(~S);
                  if (!frame)
                    throw new Error('iframe not found: ' + ~S);
                  if (!frame.contentDocument)
                    throw new Error('iframe contentDocument is unavailable');
                  return frame.contentDocument.documentElement.outerHTML;
                })()"
               iframe iframe)
       "document.documentElement.outerHTML")))

(defun fetch-activex-class-with-nyxt (buffer)
  "Parse the ActiveX class currently displayed in BUFFER."
  (parse-activex-class-document
   (plump:parse
    (fetch-dom-with-nyxt
     buffer
     :iframe "#ui-content-frame"))))
