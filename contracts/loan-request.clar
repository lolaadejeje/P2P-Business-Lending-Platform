;; Loan Request Contract

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u401))
(define-constant ERR_ALREADY_EXISTS (err u409))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_INVALID_AMOUNT (err u400))

;; Data Maps
(define-map loan-requests
  { request-id: uint }
  {
    business: principal,
    amount: uint,
    term: uint,
    purpose: (string-ascii 100),
    status: (string-ascii 20)
  }
)

(define-map business-requests
  { business: principal }
  (list 10 uint)
)

(define-data-var request-nonce uint u0)

;; Public Functions
(define-public (create-loan-request (amount uint) (term uint) (purpose (string-ascii 100)))
  (let
    ((new-request-id (+ (var-get request-nonce) u1)))
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (> term u0) ERR_INVALID_AMOUNT)
    (map-set loan-requests
      { request-id: new-request-id }
      {
        business: tx-sender,
        amount: amount,
        term: term,
        purpose: purpose,
        status: "pending"
      }
    )
    (map-set business-requests
      { business: tx-sender }
      (unwrap! (as-max-len? (append (default-to (list) (map-get? business-requests { business: tx-sender })) new-request-id) u10) ERR_ALREADY_EXISTS)
    )
    (var-set request-nonce new-request-id)
    (ok new-request-id)
  )
)

(define-public (update-loan-request-status (request-id uint) (new-status (string-ascii 20)))
  (let
    ((request (unwrap! (map-get? loan-requests { request-id: request-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (ok (map-set loan-requests
      { request-id: request-id }
      (merge request { status: new-status })
    ))
  )
)

;; Read-only Functions
(define-read-only (get-loan-request (request-id uint))
  (map-get? loan-requests { request-id: request-id })
)

(define-read-only (get-business-requests (business principal))
  (map-get? business-requests { business: business })
)

(define-read-only (get-total-requests)
  (ok (var-get request-nonce))
)

