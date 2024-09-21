;; NFT-based Subscription Service with Time-lock Functionality

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_ALREADY_INITIALIZED (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_INVALID_SUBSCRIPTION (err u103))
(define-constant ERR_SUBSCRIPTION_EXPIRED (err u104))
(define-constant ERR_INSUFFICIENT_BALANCE (err u105))
(define-constant ERR_INVALID_AMOUNT (err u106))
(define-constant ERR_SUBSCRIPTION_ACTIVE (err u107))

;; Data Variables
(define-data-var last-token-id uint u0)
(define-data-var contract-initialized bool false)

;; Data Maps
(define-map subscriptions
  uint
  {
    owner: principal,
    service-id: uint,
    start-block: uint,
    end-block: uint,
    auto-renew: bool
  }
)

(define-map services
  uint
  {
    name: (string-ascii 50),
    description: (string-utf8 500),
    price: uint,
    duration: uint
  }
)

(define-map service-providers principal bool)

(define-map user-balances principal uint)

;; NFT Definitions
(impl-trait 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait)

(define-non-fungible-token subscription-nft uint)

;; Private Functions

(define-private (is-contract-owner)
  (is-eq tx-sender CONTRACT_OWNER)
)

(define-private (is-service-provider (provider principal))
  (default-to false (map-get? service-providers provider))
)

(define-private (get-current-block-height)
  block-height
)

(define-private (is-subscription-active (subscription-id uint))
  (match (map-get? subscriptions subscription-id)
    subscription (>= (get end-block subscription) (get-current-block-height))
    false
  )
)

;; Public Functions

;; Initialize the contract
(define-public (initialize)
  (begin
    (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
    (asserts! (not (var-get contract-initialized)) ERR_ALREADY_INITIALIZED)
    (var-set contract-initialized true)
    (ok true)
  )
)

;; Add a service provider
(define-public (add-service-provider (provider principal))
  (begin
    (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
    (map-set service-providers provider true)
    (ok true)
  )
)

;; Remove a service provider
(define-public (remove-service-provider (provider principal))
  (begin
    (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
    (map-delete service-providers provider)
    (ok true)
  )
)

;; Create a new service
(define-public (create-service (name (string-ascii 50)) (description (string-utf8 500)) (price uint) (duration uint))
  (let
    (
      (service-id (+ (var-get last-token-id) u1))
    )
    (asserts! (is-service-provider tx-sender) ERR_NOT_AUTHORIZED)
    (map-set services service-id {
      name: name,
      description: description,
      price: price,
      duration: duration
    })
    (var-set last-token-id service-id)
    (ok service-id)
  )
)

;; Update an existing service
(define-public (update-service (service-id uint) (name (string-ascii 50)) (description (string-utf8 500)) (price uint) (duration uint))
  (begin
    (asserts! (is-service-provider tx-sender) ERR_NOT_AUTHORIZED)
    (asserts! (is-some (map-get? services service-id)) ERR_NOT_FOUND)
    (map-set services service-id {
      name: name,
      description: description,
      price: price,
      duration: duration
    })
    (ok true)
  )
)

;; Purchase a subscription
(define-public (purchase-subscription (service-id uint) (auto-renew bool))
  (let
    (
      (service (unwrap! (map-get? services service-id) ERR_NOT_FOUND))
      (subscription-id (+ (var-get last-token-id) u1))
      (start-block (get-current-block-height))
      (end-block (+ start-block (get duration service)))
      (buyer tx-sender)
      (buyer-balance (default-to u0 (map-get? user-balances buyer)))
    )
    (asserts! (>= buyer-balance (get price service)) ERR_INSUFFICIENT_BALANCE)
    (try! (nft-mint? subscription-nft subscription-id buyer))
    (map-set subscriptions subscription-id {
      owner: buyer,
      service-id: service-id,
      start-block: start-block,
      end-block: end-block,
      auto-renew: auto-renew
    })
    (map-set user-balances buyer (- buyer-balance (get price service)))
    (var-set last-token-id subscription-id)
    (ok subscription-id)
  )
)

;; Renew a subscription
(define-public (renew-subscription (subscription-id uint))
  (let
    (
      (subscription (unwrap! (map-get? subscriptions subscription-id) ERR_NOT_FOUND))
      (service (unwrap! (map-get? services (get service-id subscription)) ERR_NOT_FOUND))
      (owner (get owner subscription))
      (current-block (get-current-block-height))
      (new-end-block (+ (get end-block subscription) (get duration service)))
      (owner-balance (default-to u0 (map-get? user-balances owner)))
    )
    (asserts! (is-eq tx-sender owner) ERR_NOT_AUTHORIZED)
    (asserts! (>= owner-balance (get price service)) ERR_INSUFFICIENT_BALANCE)
    (map-set subscriptions subscription-id (merge subscription {
      end-block: new-end-block
    }))
    (map-set user-balances owner (- owner-balance (get price service)))
    (ok true)
  )
)

;; Cancel auto-renewal of a subscription
(define-public (cancel-auto-renew (subscription-id uint))
  (let
    (
      (subscription (unwrap! (map-get? subscriptions subscription-id) ERR_NOT_FOUND))
      (owner (get owner subscription))
    )
    (asserts! (is-eq tx-sender owner) ERR_NOT_AUTHORIZED)
    (map-set subscriptions subscription-id (merge subscription {
      auto-renew: false
    }))
    (ok true)
  )
)

;; Check if a user has an active subscription
(define-read-only (check-subscription (user principal) (service-id uint))
  (let
    (
      (subscription-id (unwrap! (get-subscription-by-user-and-service user service-id) ERR_NOT_FOUND))
    )
    (ok (is-subscription-active subscription-id))
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

;; Get user balance
(define-read-only (get-user-balance (user principal))
  (default-to u0 (map-get? user-balances user))
)

;; Deposit funds to user balance
(define-public (deposit-funds (amount uint))
  (let
    (
      (user tx-sender)
      (current-balance (default-to u0 (map-get? user-balances user)))
    )
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (try! (stx-transfer? amount user (as-contract tx-sender)))
    (map-set user-balances user (+ current-balance amount))
    (ok true)
  )
)

;; Withdraw funds from user balance
(define-public (withdraw-funds (amount uint))
  (let
    (
      (user tx-sender)
      (current-balance (default-to u0 (map-get? user-balances user)))
    )
    (asserts! (>= current-balance amount) ERR_INSUFFICIENT_BALANCE)
    (try! (as-contract (stx-transfer? amount tx-sender user)))
    (map-set user-balances user (- current-balance amount))
    (ok true)
  )
)

;; Internal function to get subscription by user and service
(define-private (get-subscription-by-user-and-service (user principal) (service-id uint))
  (fold check-subscription-match (ok none) (map-to-list subscriptions))
  
  (define-private (check-subscription-match (entry {id: uint, subscription: {owner: principal, service-id: uint, start-block: uint, end-block: uint, auto-renew: bool}}) (result (response (optional uint) uint)))
    (match result
      success (if (and (is-eq (get owner (get subscription entry)) user) (is-eq (get service-id (get subscription entry)) service-id))
                  (ok (some (get id entry)))
                  success)
      failure failure
    )
  )
)

;; Automatic subscription renewal (to be called periodically)
(define-public (process-auto-renewals)
  (let
    (
      (current-block (get-current-block-height))
      (renewals (filter needs-renewal (map-to-list subscriptions)))
    )
    (map try-renew renewals)
    (ok true)
  )
  
  (define-private (needs-renewal (entry {id: uint, subscription: {owner: principal, service-id: uint, start-block: uint, end-block: uint, auto-renew: bool}}))
    (and (get auto-renew (get subscription entry))
         (>= current-block (get end-block (get subscription entry))))
  )
  
  (define-private (try-renew (entry {id: uint, subscription: {owner: principal, service-id: uint, start-block: uint, end-block: uint, auto-renew: bool}}))
    (let
      (
        (subscription-id (get id entry))
        (service (unwrap! (map-get? services (get service-id (get subscription entry))) ERR_NOT_FOUND))
        (owner (get owner (get subscription entry)))
        (new-end-block (+ current-block (get duration service)))
        (owner-balance (default-to u0 (map-get? user-balances owner)))
      )
      (if (>= owner-balance (get price service))
        (begin
          (map-set subscriptions subscription-id (merge (get subscription entry) {
            end-block: new-end-block
          }))
          (map-set user-balances owner (- owner-balance (get price service)))
          (ok true)
        )
        (begin
          (map-set subscriptions subscription-id (merge (get subscription entry) {
            auto-renew: false
          }))
          (err ERR_INSUFFICIENT_BALANCE)
        )
      )
    )
  )
)

;; Transfer subscription NFT
(define-public (transfer-subscription (subscription-id uint) (recipient principal))
  (let
    (
      (subscription (unwrap! (map-get? subscriptions subscription-id) ERR_NOT_FOUND))
      (owner (get owner subscription))
    )
    (asserts! (is-eq tx-sender owner) ERR_NOT_AUTHORIZED)
    (asserts! (is-valid-principal recipient) ERR_INVALID_PRINCIPAL)
    (try! (nft-transfer? subscription-nft subscription-id owner recipient))
    (map-set subscriptions subscription-id (merge subscription {
      owner: recipient
    }))
    (ok true)
  )
)

;; Pause a subscription
(define-public (pause-subscription (subscription-id uint))
  (let
    (
      (subscription (unwrap! (map-get? subscriptions subscription-id) ERR_NOT_FOUND))
      (owner (get owner subscription))
      (current-block (get-current-block-height))
    )
    (asserts! (is-eq tx-sender owner) ERR_NOT_AUTHORIZED)
    (asserts! (is-subscription-active subscription-id) ERR_SUBSCRIPTION_EXPIRED)
    (let
      (
        (remaining-blocks (- (get end-block subscription) current-block))
      )
      (map-set subscriptions subscription-id (merge subscription {
        end-block: current-block,
        remaining-blocks: (some remaining-blocks)
      }))
      (ok true)
    )
  )
)

;; Resume a paused subscription
(define-public (resume-subscription (subscription-id uint))
  (let
    (
      (subscription (unwrap! (map-get? subscriptions subscription-id) ERR_NOT_FOUND))
      (owner (get owner subscription))
      (current-block (get-current-block-height))
    )
    (asserts! (is-eq tx-sender owner) ERR_NOT_AUTHORIZED)
    (asserts! (is-some (get remaining-blocks subscription)) ERR_SUBSCRIPTION_ACTIVE)
    (let
      (
        (new-end-block (+ current-block (unwrap! (get remaining-blocks subscription) ERR_INVALID_SUBSCRIPTION)))
      )
      (map-set subscriptions subscription-id (merge subscription {
        end-block: new-end-block,
        remaining-blocks: none
      }))
      (ok true)
    )
  )
)

;; Get all subscriptions for a user
(define-read-only (get-user-subscriptions (user principal))
  (filter owned-by-user (map-to-list subscriptions))
  
  (define-private (owned-by-user (entry {id: uint, subscription: {owner: principal, service-id: uint, start-block: uint, end-block: uint, auto-renew: bool}}))
    (is-eq (get owner (get subscription entry)) user)
  )
)

;; Get all services offered by a provider
(define-read-only (get-provider-services (provider principal))
  (filter offered-by-provider (map-to-list services))
  
  (define-private (offered-by-provider (entry {id: uint, service: {name: (string-ascii 50), description: (string-utf8 500), price: uint, duration: uint}}))
    (is-service-provider provider)
  )
)

;; Helper function to check if a principal is valid
(define-private (is-valid-principal (address principal))
  (and
    (not (is-eq address 'SP000000000000000000002Q6VF78))  ;; Check if not zero address
    (not (is-eq address (as-contract tx-sender)))         ;; Check if not the contract itself
  )
)