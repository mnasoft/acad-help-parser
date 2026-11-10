;;;; nyxt.lisp

(in-package #:acad-help-parser)

(defun wait-for-dom-with-nyxt
    (buffer &key
              (iframe "#ui-content-frame")
              (timeout 30)
              (interval 0.1))
  "Wait until IFRAME in BUFFER contains a loaded document.

Return T when ready, NIL on timeout."

  (let ((deadline (+ (get-internal-real-time)
                     (* timeout internal-time-units-per-second))))
    (loop
      (when
          (nyxt:ffi-buffer-evaluate-javascript
           buffer
           (format nil
                   "(function () {
                      const frame = document.querySelector(~S);
                      return !!(frame &&
                                frame.contentDocument &&
                                frame.contentDocument.documentElement &&
                                frame.contentDocument.body);
                    })()"
                   iframe))
        (return t))

      (when (>= (get-internal-real-time) deadline)
        (return nil))

      (sleep interval))))

(defun fetch-dom-with-nyxt
    (buffer &key iframe wait
                 (timeout 30)
                 (interval 0.1))
  "Return current DOM of BUFFER as an HTML string.

When IFRAME is non-NIL, return the DOM contained in that iframe.

When WAIT is true, wait until the requested iframe document
becomes available."

  (when (and wait iframe)
    (unless (wait-for-dom-with-nyxt
             buffer
             :iframe iframe
             :timeout timeout
             :interval interval)
      (error "Timed out waiting for iframe ~S." iframe)))

  (nyxt:ffi-buffer-evaluate-javascript
   buffer
   (if iframe
       (format nil
               "(function () {
                  const frame = document.querySelector(~S);
                  if (!frame)
                    throw new Error('iframe not found');
                  if (!frame.contentDocument)
                    throw new Error('iframe contentDocument unavailable');
                  return frame.contentDocument.documentElement.outerHTML;
                })()"
               iframe)
       "document.documentElement.outerHTML")))


(defun fetch-activex-class-with-nyxt
    (buffer &key
              (wait nil)
              (timeout 30)
              (interval 0.1))
  "Parse the ActiveX class displayed in BUFFER.

When WAIT is true, wait for the Autodesk content iframe."
  (parse-activex-class-document
   (plump:parse
    (fetch-dom-with-nyxt
     buffer
     :iframe "#ui-content-frame"
     :wait wait
     :timeout timeout
     :interval interval))))

(defun find-buffer-with-nyxt (title)
  "Return the first Nyxt buffer whose document title equals TITLE.
Return NIL when no matching buffer exists."
  (find title
        (nyxt:buffer-list)
        :test #'string=
        :key (lambda (buffer)
               (nyxt:ffi-buffer-evaluate-javascript
                buffer
                "document.title"))))

(defun fetch-activex-class-with-nyxt-url
    (url &key
           (wait t)
           (timeout 60)
           (interval 0.1))
  "Open URL in a new Nyxt buffer and parse the ActiveX class.

When WAIT is true, wait for the Autodesk content iframe to become
available.  Return the parsed ACTIVEX-CLASS object."

  (let ((buffer
          (nyxt:make-buffer
           :url (nyxt:url url))))
    (fetch-activex-class-with-nyxt
     buffer
     :wait wait
     :timeout timeout
     :interval interval)))
