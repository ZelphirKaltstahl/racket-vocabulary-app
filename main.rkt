#lang racket

(require json
         "data.rkt"
         "response.rkt"
         "hash-procedures.rkt")

(provide (all-defined-out))

(struct vocabulary-context (vocabularies))

(define app-vocabulary-context
  (vocabulary-context
   (make-hash (list (cons "HSK1" HSK-1 #;(make-hash (hash->list HSK-1)))
                    (cons "HSK2" HSK-2 #;(make-hash (hash->list HSK-2)))
                    (cons "HSK3" HSK-3 #;(make-hash (hash->list HSK-3)))
                    (cons "HSK3" HSK-4 #;(make-hash (hash->list HSK-4)))
                    (cons "HSK5" HSK-5 #;(make-hash (hash->list HSK-5)))
                    (cons "HSK6" HSK-6 #;(make-hash (hash->list HSK-6)))))))

;; =============
;; STATE CHANGES
;; =============
(define (update-voc! voc-id voc)
  (hash-set! (vocabulary-context-vocabularies app-vocabulary-context)
             voc-id
             voc))

(define (remove-word voc word-id)
  (hash-set voc
            'words
            (hash-remove (hash-ref voc 'words)
                         (string->symbol (pad-word-id-for-voc voc word-id)))))

;; =================
;; GETTERS & SETTERS
;; =================
(define (set-word-description voc word-id a-description)
  (let* ([padded-word-id (pad-word-id-for-voc voc word-id)]
         [word (nested-hash-get voc 'words (string->symbol padded-word-id))]
         [updated-metadata (hash-set (hash-ref word 'metadata) 'description a-description)]
         [updated-word (hash-set word 'metadata updated-metadata)]
         [updated-words
          (hash-set (hash-ref voc 'words) (string->symbol padded-word-id) updated-word)])
    (hash-set voc 'words updated-words)))

(define (set-word-learned-status voc word-id learned-status)
  (let* ([padded-word-id (pad-word-id-for-voc voc word-id)]
         [word (nested-hash-get voc 'words (string->symbol padded-word-id))]
         [updated-metadata (hash-set (hash-ref word 'metadata) 'learned learned-status)]
         [updated-word (hash-set word 'metadata updated-metadata)]
         [updated-words
          (hash-set (hash-ref voc 'words) (string->symbol padded-word-id) updated-word)])
    (hash-set voc 'words updated-words)))

(define (set-word-learned voc-id word-id)
  (update-voc! voc-id
               (set-word-learned-status (get-voc-by-id voc-id)
                                        word-id
                                        #t)))

(define (set-word-unlearned voc-id word-id)
  (update-voc! voc-id
               (set-word-learned-status (get-voc-by-id voc-id)
                                        word-id
                                        #f)))

(define (get-voc-by-id voc-id)
  (nested-hash-get (vocabulary-context-vocabularies app-vocabulary-context)
                   voc-id))

(define (get-word-by-id voc word-id)
  (nested-hash-get voc 'words (string->symbol (pad-word-id-for-voc voc word-id))))

;; =======
;; HELPERS
;; =======
(define (number-pad number padding-string padding-length)
  (cond [(and (string? number)
              (>= (string-length number) padding-length))
         number]
        [(number? number)
         (number-pad (number->string number)
                     padding-string
                     padding-length)]
        [(string? number)
         (number-pad (string-append padding-string number)
                     padding-string
                     padding-length)]
        [else
         (error "cannot process number which shall be padded, unexpected and unhandled type")]))

(define (hash-length a-hash)
  (length (hash-keys a-hash)))

(define (pad-word-id-for-voc voc word-id)
  (number-pad word-id
              "0"
              (string-length
               (number->string
                (hash-length (nested-hash-get voc 'words))))))

(define (generate-random-word-id voc)
  (let ([min 0]
        [max (hash-length (hash-ref voc 'words 0))])
    (pad-word-id-for-voc voc (random max))))

;; ==============
;; ROUTE HANDLERS
;; ==============
(define (learn-word req voc-id word-id)
  (define (handle-exn exn)
    (displayln exn)
    (make-404-json-response
     (jsexpr->string
      (hash 'error "could not set word learned"))))
  (with-handlers ([exn:fail? handle-exn])
    (set-word-learned voc-id word-id)
    (make-json-response
     (jsexpr->string
      (hash 'success "set word learned")))))


(define (unlearn-word req voc-id word-id)
  (define (handle-exn exn)
    (displayln exn)
    (make-404-json-response
     (jsexpr->string
      (hash 'error "could not set word unlearned"))))
  (with-handlers ([exn:fail? handle-exn])
    (set-word-unlearned voc-id word-id)
    (make-json-response
     (jsexpr->string
      (hash 'success "set word unlearned")))))


(define (get-vocabulary req voc-id)
  (define (handle-exn exn)
    (make-404-json-response
     (jsexpr->string
      (hash 'error "could not find vocabulary"))))
  (with-handlers ([exn:fail? handle-exn])
    (make-json-response
     (jsexpr->string
      (get-voc-by-id voc-id)))))


(define (get-random-word req voc-id)
  (get-word req voc-id
            (generate-random-word-id (get-voc-by-id voc-id))))


(define (get-word req voc-id word-id)
  (define (handle-exn exn)
    (make-404-json-response
     (jsexpr->string
      (hash 'error "could not find word"))))
  (with-handlers ([exn:fail? handle-exn])
    (let ([voc (get-voc-by-id voc-id)])
      (make-json-response
       (jsexpr->string
        (get-word-by-id voc word-id))))))


(define (delete-word req voc-id word-id)
  (define (handle-exn exn)
    (displayln exn)
    (make-404-json-response
     (jsexpr->string
      (hash 'error "could not delete word"))))
  (with-handlers ([exn:fail? handle-exn])
    (let ([voc (get-voc-by-id voc-id)])
      (update-voc! voc-id (remove-word voc word-id))
      (make-json-response
       (jsexpr->string
        (hash 'success "removed word"))))))

;; ==============
;; PAGE RENDERING
;; ==============
(define (render-page req)
  (make-response
   (render-page-template)))


;; =========
;; TEMPLATES
;; =========
(require xml)
(define (render-page-template)
  (xexpr->string
   `(html ((lang "en"))
          (head
           (title "HSK App")
           (script ((src "/js/main.js"))))
          (body
           (p "Hello World!")))))
