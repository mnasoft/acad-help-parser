;;;; nyxt.lisp

(in-package #:acad-help-parser)

(defun fetch-dom-with-nyxt
    (buffer &key
              iframe
              wait
              (timeout 30)
              (interval 0.1))

  (when wait
    (unless (wait-for-dom-with-nyxt
             buffer
             :iframe (or iframe "#ui-content-frame")
             :timeout timeout
             :interval interval)
      (error "Timed out waiting for Autodesk document.")))

  (nyxt:ffi-buffer-evaluate-javascript
   buffer
   (if iframe
       (format nil
               "(function () {
                  const frame = document.querySelector(~S);

                  if (frame &&
                      frame.contentDocument &&
                      frame.contentDocument.querySelector(
                        '.referencebody-adsk'))
                    return frame.contentDocument.documentElement.outerHTML;

                  if (document.querySelector('.referencebody-adsk'))
                    return document.documentElement.outerHTML;

                  throw new Error(
                    'Autodesk ActiveX document not found');
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
  "Open URL in a new focused Nyxt buffer and parse the ActiveX class."

  (let ((buffer
          (nyxt:make-buffer-focus
           :url (nyxt:url url))))
    (fetch-activex-class-with-nyxt
     buffer
     :wait wait
     :timeout timeout
     :interval interval)))

(defun wait-for-dom-with-nyxt
    (buffer &key
              (iframe "#ui-content-frame")
              (timeout 30)
              (interval 0.1))
  "Wait until an Autodesk ActiveX document is available."

  (let ((deadline (+ (get-internal-real-time)
                     (* timeout internal-time-units-per-second))))
    (loop
      (when
          (nyxt:ffi-buffer-evaluate-javascript
           buffer
           (format nil
                   "(function () {
                      const frame = document.querySelector(~S);

                      const frameReady =
                        frame &&
                        frame.contentDocument &&
                        frame.contentDocument.querySelector(
                          '.referencebody-adsk');

                      const documentReady =
                        document.querySelector(
                          '.referencebody-adsk');

                      return !!(frameReady || documentReady);
                    })()"
                   iframe))
        (return t))

      (when (>= (get-internal-real-time) deadline)
        (return nil))

      (sleep interval))))
