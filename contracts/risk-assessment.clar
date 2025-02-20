;; Risk Assessment Contract

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u401))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_INVALID_SCORE (err u400))

;; Data Maps
(define-map risk-assessments
  { request-id: uint }
  {
    credit-score: uint,
    risk-level: (string-ascii 10),
    assessor: principal,
    timestamp: uint
  }
)

;; Public Functions
(define-public (assess-risk (request-id uint) (credit-score uint) (risk-level (string-ascii 10)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (and (>= credit-score u300) (<= credit-score u850)) ERR_INVALID_SCORE)
    (ok (map-set risk-assessments
      { request-id: request-id }
      {
        credit-score: credit-score,
        risk-level: risk-level,
        assessor: tx-sender,
        timestamp: block-height
      }
    ))
  )
)

;; Read-only Functions
(define-read-only (get-risk-assessment (request-id uint))
  (map-get? risk-assessments { request-id: request-id })
)

