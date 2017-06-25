#lang racket

(require "hash-procedures.rkt")

(provide (all-defined-out))

;; GENERAL
(define (vocabulary-words-list a-vocabulary)
  (nested-hash-get a-vocabulary 'words))

;; METADATA
(define (word-id a-word)
  (nested-hash-get a-word 'metadata 'id))
(define (word-description a-word)
  (nested-hash-get a-word 'metadata 'description))
(define (word-learned? a-word)
  (nested-hash-get a-word 'metadata 'learned))

;; TRANSLATION DATA
(define (word-english a-word)
  (nested-hash-get a-word 'translation-data 'english))
(define (word-pinyin-numbered a-word)
  (nested-hash-get a-word 'translation-data 'pinyin-numbered))
(define (word-pinyin a-word)
  (nested-hash-get a-word 'translation-data 'pinyin))
(define (word-simplified a-word)
  (nested-hash-get a-word 'translation-data 'simplified))
(define (word-traditional a-word)
  (nested-hash-get a-word 'translation-data 'traditional))
