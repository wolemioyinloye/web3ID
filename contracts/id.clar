;; Web3Identity: Decentralized Identity Management Contract
;; Define error messages
(define-constant ERR-PROFILE-EXISTS (err "Profile already exists"))
(define-constant ERR-PROFILE-NOT-FOUND (err "Profile not found"))
(define-constant ERR-INVALID-HANDLE (err "Invalid handle: must be between 3 and 50 characters"))
(define-constant ERR-INVALID-CONTACT (err "Invalid contact: must be between 5 and 100 characters and contain '@' and '.'"))
(define-constant ERR-INVALID-AVATAR-URL (err "Invalid avatar URL: must be a valid URL string"))

;; Define the data map for storing identity information
(define-map identities principal
  {
    handle: (string-ascii 50),
    contact: (string-ascii 100),
    avatar: (optional (string-utf8 256))
  }
)

;; Define a data var to track total registered identities
(define-data-var identity-registry-count uint u0)

;; Function to validate handle
(define-private (validate-handle (handle (string-ascii 50)))
  (let
    (
      (length (len handle))
    )
    (and (>= length u3) (<= length u50))
  )
)

;; Function to validate contact
(define-private (validate-contact (contact (string-ascii 100)))
  (let
    (
      (length (len contact))
      (has-at (is-some (index-of contact "@")))
      (has-dot (is-some (index-of contact ".")))
    )
    (and (>= length u5) (<= length u100) has-at has-dot)
  )
)

;; Function to create a new identity
(define-public (create-identity (handle (string-ascii 50)) (contact (string-ascii 100)))
  (let
    (
      (caller tx-sender)
      (safe-handle (as-max-len? handle u50))
      (safe-contact (as-max-len? contact u100))
    )
    (asserts! (is-none (map-get? identities caller)) ERR-PROFILE-EXISTS)
    (asserts! (is-some safe-handle) ERR-INVALID-HANDLE)
    (asserts! (is-some safe-contact) ERR-INVALID-CONTACT)
    (asserts! (validate-handle (unwrap-panic safe-handle)) ERR-INVALID-HANDLE)
    (asserts! (validate-contact (unwrap-panic safe-contact)) ERR-INVALID-CONTACT)
    (map-set identities caller
      {
        handle: (unwrap-panic safe-handle),
        contact: (unwrap-panic safe-contact),
        avatar: none
      }
    )
    (var-set identity-registry-count (+ (var-get identity-registry-count) u1))
    (ok true)
  )
)

;; Function to update identity details
(define-public (update-identity (new-handle (string-ascii 50)) (new-contact (string-ascii 100)))
  (let
    (
      (caller tx-sender)
      (safe-handle (as-max-len? new-handle u50))
      (safe-contact (as-max-len? new-contact u100))
    )
    (asserts! (is-some (map-get? identities caller)) ERR-PROFILE-NOT-FOUND)
    (asserts! (is-some safe-handle) ERR-INVALID-HANDLE)
    (asserts! (is-some safe-contact) ERR-INVALID-CONTACT)
    (asserts! (validate-handle (unwrap-panic safe-handle)) ERR-INVALID-HANDLE)
    (asserts! (validate-contact (unwrap-panic safe-contact)) ERR-INVALID-CONTACT)
    (map-set identities caller
      (merge (unwrap-panic (map-get? identities caller))
        {
          handle: (unwrap-panic safe-handle),
          contact: (unwrap-panic safe-contact)
        }
      )
    )
    (ok true)
  )
)

;; Function to set avatar image
(define-public (set-avatar (avatar-url (string-utf8 256)))
  (let
    (
      (caller tx-sender)
      (safe-url (as-max-len? avatar-url u256))
    )
    (asserts! (is-some (map-get? identities caller)) ERR-PROFILE-NOT-FOUND)
    (asserts! (is-some safe-url) ERR-INVALID-AVATAR-URL)
    (map-set identities caller
      (merge (unwrap-panic (map-get? identities caller))
        { avatar: safe-url }
      )
    )
    (ok true)
  )
)

;; Read-only function to retrieve identity information
(define-read-only (get-identity-info (user principal))
  (map-get? identities user)
)

;; Read-only function to get total registered identities
(define-read-only (get-identity-count)
  (var-get identity-registry-count)
)

;; Function to check identity registration status
(define-read-only (is-identity-registered (user principal))
  (is-some (map-get? identities user))
)