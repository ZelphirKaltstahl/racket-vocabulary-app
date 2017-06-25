#lang racket

(require
  web-server/servlet-env
  web-server/servlet)

(provide (all-defined-out))

(define DOCTYPE-SEPARATOR "\n\n")
(define HTML5-DOCTYPE "<!DOCTYPE html>")

(define (string-startswith? a-string searched-string)
  (let* ([start 0]
         [end (string-length searched-string)]
         [a-string-beginning (substring a-string start end)])
    (string=? a-string-beginning searched-string)))

(define (add-html5-doctype content)
  (cond [(string-startswith? content HTML5-DOCTYPE) content]
        [else (string-append HTML5-DOCTYPE
                             DOCTYPE-SEPARATOR
                             content)]))

(define (make-response #:code [code 200]
                       #:message [message #"OK"]
                       #:seconds [seconds (current-seconds)]
                       #:mime-type [mime-type TEXT/HTML-MIME-TYPE]
                       #:headers [headers (list (make-header #"Cache-Control" #"no-cache"))]
                       #:add-doctype [add-doctype true]
                       content)
  (response/full code
                 message
                 seconds
                 mime-type
                 headers
                 (list (string->bytes/utf-8 (if add-doctype
                                                (add-html5-doctype content)
                                                content)))))

(define (make-success-response rendered-page)
  (make-response rendered-page))

(define (make-json-response json)
  (make-response #:mime-type #"application/json"
                 #:add-doctype false
                 json))

(define (make-404-json-response json)
  (make-response #:mime-type #"application/json"
                 #:code 404
                 #:message #"Not Found"
                 #:add-doctype false
                 json))
