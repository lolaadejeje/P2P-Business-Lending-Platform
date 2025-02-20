;; Lending Pool Contract

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u401))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_INSUFFICIENT_FUNDS (err u402))
(define-constant ERR_INVALID_AMOUNT (err u400))

;; Data Maps
(define-map lender-balances
  { lender: principal }
  { balance: uint }
)

(define-map active-loans
  { loan-id: uint }
  {
    lender: principal,
    borrower: principal,
    amount: uint,
    interest-rate: uint,
    start-block: uint,
    end-block: uint,
    status: (string-ascii 20)
  }
)

(define-data-var total-pool-balance uint u0)
(define-data-var loan-nonce uint u0)

;; Public Functions
(define-public (contribute-to-pool (amount uint))
  (let
    ((current-balance (default-to { balance: u0 } (map-get? lender-balances { lender: tx-sender }))))
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set lender-balances
      { lender: tx-sender }
      { balance: (+ (get balance current-balance) amount) }
    )
    (var-set total-pool-balance (+ (var-get total-pool-balance) amount))
    (ok true)
  )
)

(define-public (withdraw-from-pool (amount uint))
  (let
    ((current-balance (default-to { balance: u0 } (map-get? lender-balances { lender: tx-sender }))))
    (asserts! (<= amount (get balance current-balance)) ERR_INSUFFICIENT_FUNDS)
    (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
    (map-set lender-balances
      { lender: tx-sender }
      { balance: (- (get balance current-balance) amount) }
    )
    (var-set total-pool-balance (- (var-get total-pool-balance) amount))
    (ok true)
  )
)

(define-public (fund-loan (borrower principal) (amount uint) (interest-rate uint) (term uint))
  (let
    ((lender-balance (default-to { balance: u0 } (map-get? lender-balances { lender: tx-sender })))
     (new-loan-id (+ (var-get loan-nonce) u1)))
    (asserts! (<= amount (get balance lender-balance)) ERR_INSUFFICIENT_FUNDS)
    (map-set active-loans
      { loan-id: new-loan-id }
      {
        lender: tx-sender,
        borrower: borrower,
        amount: amount,
        interest-rate: interest-rate,
        start-block: block-height,
        end-block: (+ block-height (* term u144)), ;; Assuming 1 day = 144 blocks
        status: "active"
      }
    )
    (map-set lender-balances
      { lender: tx-sender }
      { balance: (- (get balance lender-balance) amount) }
    )
    (var-set loan-nonce new-loan-id)
    (ok new-loan-id)
  )
)

;; Read-only Functions
(define-read-only (get-lender-balance (lender principal))
  (default-to { balance: u0 } (map-get? lender-balances { lender: lender }))
)

(define-read-only (get-total-pool-balance)
  (ok (var-get total-pool-balance))
)

(define-read-only (get-active-loan (loan-id uint))
  (map-get? active-loans { loan-id: loan-id })
)

