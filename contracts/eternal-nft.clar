;; NFT-based Subscription Service (Simplified)

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u102))

;; Data Variables
(define-data-var last-token-id uint u0)

;; Data Maps
(define-map subscriptions
  uint
  {
    owner: principal,
    service-id: uint,
    end-block: uint
  }
)

(define-map services
  uint
  {
    name: (string-ascii 50),
    price: uint,
    duration: uint
  }
)

;; NFT Definition
(define-non-fungible-token subscription-nft uint)

;; Private Functions
(define-private (is-contract-owner)
  (is-eq tx-sender CONTRACT_OWNER)
)

;; Public Functions
;; Create a new service
(define-public (create-service (name (string-ascii 50)) (price uint) (duration uint))
  (let
    (
      (service-id (+ (var-get last-token-id) u1))
    )
    (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
    (map-set services service-id {
      name: name,
      price: price,
      duration: duration
    })
    (var-set last-token-id service-id)
    (ok service-id)
  )
)

;; Purchase a subscription
(define-public (purchase-subscription (service-id uint))
  (let
    (
      (service (unwrap! (map-get? services service-id) ERR_NOT_FOUND))
      (subscription-id (+ (var-get last-token-id) u1))
      (end-block (+ block-height (get duration service)))
      (buyer tx-sender)
    )
    (try! (stx-transfer? (get price service) buyer (as-contract tx-sender)))
    (try! (nft-mint? subscription-nft subscription-id buyer))
    (map-set subscriptions subscription-id {
      owner: buyer,
      service-id: service-id,
      end-block: end-block
    })
    (var-set last-token-id subscription-id)
    (ok subscription-id)
  )
)

;; Get subscription details
(define-read-only (get-subscription-details (subscription-id uint))
  (map-get? subscriptions subscription-id)
)

;; Get service details
(define-read-only (get-service-details (service-id uint))
  (map-get? services service-id)
)

;; NFT functions
(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) ERR_NOT_AUTHORIZED)
    (nft-transfer? subscription-nft token-id sender recipient)
  )
)

(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? subscription-nft token-id))
)

(define-read-only (get-last-token-id)
  (ok (var-get last-token-id))
)

(define-read-only (get-token-uri (token-id uint))
  (ok (some u"https://example.com/subscription-nft"))
)