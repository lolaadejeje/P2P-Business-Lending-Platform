;; Collateral Management Contract

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u401))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_INVALID_AMOUNT (err u400))

;; Data Maps
(define-map collaterals
  { loan-id: uint }
  {
    asset-type: (string-ascii 50),
    asset-value: uint,
    locked-amount: uint,
    status: (string-ascii 20)
  }
)

;; Public Functions
(define-public (add-collateral (loan-id uint) (asset-type (string-ascii 50)) (asset-value uint) (locked-amount uint))
  (let
    ((loan (unwrap! (contract-call? .lending-pool get-active-loan loan-id) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get lender loan)) ERR_NOT_AUTHORIZED)
    (asserts! (>= asset-value locked-amount) ERR_INVALID_AMOUNT)
    (ok (map-set collaterals
      { loan-id: loan-id }
      {
        asset-type: asset-type,
        asset-value: asset-value,
        locked-amount: locked-amount,
        status: "locked"
      }
    ))
  )
)

(define-public (release-collateral (loan-id uint))
  (let
    ((collateral (unwrap! (map-get? collaterals { loan-id: loan-id }) ERR_NOT_FOUND))
     (loan (unwrap! (contract-call? .lending-pool get-active-loan loan-id) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get status loan) "repaid") ERR_NOT_AUTHORIZED)
    (ok (map-set collaterals
      { loan-id: loan-id }
      (merge collateral { status: "released" })
    ))
  )
)

(define-public (liquidate-collateral (loan-id uint))
  (let
    ((collateral (unwrap! (map-get? collaterals { loan-id: loan-id }) ERR_NOT_FOUND))
     (loan (unwrap! (contract-call? .lending-pool get-active-loan loan-id) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get status loan) "defaulted") ERR_NOT_AUTHORIZED)
    (ok (map-set collaterals
      { loan-id: loan-id }
      (merge collateral { status: "liquidated" })
    ))
  )
)

;; Read-only Functions
(define-read-only (get-collateral (loan-id uint))
  (map-get? collaterals { loan-id: loan-id })
)

