;; Web3ID: Decentralized Identity Management Contract
;; Define error messages
(define-constant ERR-PROFILE-EXISTS (err "Profile already exists"))
(define-constant ERR-PROFILE-NOT-FOUND (err "Profile not found"))
(define-constant ERR-INVALID-HANDLE (err "Invalid handle: must be between 3 and 50 characters"))
(define-constant ERR-INVALID-CONTACT (err "Invalid contact: must be between 5 and 100 characters and contain '@' and '.'"))
(define-constant ERR-INVALID-AVATAR-URL (err "Invalid avatar URL: must be a valid URL string"))
(define-constant ERR-SELF-ENDORSEMENT (err "Cannot endorse yourself"))
(define-constant ERR-ALREADY-ENDORSED (err "Already endorsed"))
(define-constant ERR-ENDORSEMENT-MESSAGE-TOO-LONG (err "Endorsement message too long"))

;; Define the data map for storing identity information
(define-map identities principal
  {
    handle: (string-ascii 50),
    contact: (string-ascii 100),
    avatar: (optional (string-utf8 256))
  }
)

;; Define map to track endorsements
(define-map endorsements 
  { endorser: principal, endorsed: principal } 
  { message: (optional (string-utf8 100)) }
)

;; Define data vars to track counts
(define-data-var identity-registry-count uint u0)
(define-map endorsement-counts principal uint)

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

;; Function to endorse an identity
(define-public (endorse-identity (target principal) (optional-message (optional (string-utf8 100))))
  (let
    (
      (caller tx-sender)
    )
    ;; Ensure the target identity exists
    (asserts! (is-some (map-get? identities target)) ERR-PROFILE-NOT-FOUND)
    ;; Prevent self-endorsement
    (asserts! (not (is-eq caller target)) ERR-SELF-ENDORSEMENT)
    ;; Prevent multiple endorsements from same endorser
    (asserts! (is-none (map-get? endorsements {endorser: caller, endorsed: target})) ERR-ALREADY-ENDORSED)
    
    ;; Optional: Validate message length if provided
    (if (is-some optional-message)
        (asserts! (<= (len (unwrap-panic optional-message)) u100) ERR-ENDORSEMENT-MESSAGE-TOO-LONG)
        true
    )
    
    ;; Record endorsement
    (map-set endorsements 
      {endorser: caller, endorsed: target} 
      {message: optional-message}
    )
    
    ;; Update endorsement count
    (map-set endorsement-counts 
      target 
      (+ (default-to u0 (map-get? endorsement-counts target)) u1)
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

;; Read-only function to get endorsement count
(define-read-only (get-endorsement-count (user principal))
  (default-to u0 (map-get? endorsement-counts user))
)

;; Read-only function to check if already endorsed
(define-read-only (is-endorsed-by (endorser principal) (endorsed principal))
  (is-some (map-get? endorsements {endorser: endorser, endorsed: endorsed}))
)

;; Function to remove an endorsement
(define-public (remove-endorsement (target principal))
  (let
    (
      (caller tx-sender)
      (endorsement-key {endorser: caller, endorsed: target})
      (current-endorsement (map-get? endorsements endorsement-key))
      (current-count (default-to u0 (map-get? endorsement-counts target)))
    )
    ;; Ensure the target identity exists
    (asserts! (is-some (map-get? identities target)) ERR-PROFILE-NOT-FOUND)
    
    ;; Ensure the endorsement exists
    (asserts! (is-some current-endorsement) (err "No existing endorsement"))
    
    ;; Remove the endorsement
    (map-delete endorsements endorsement-key)
    
    ;; Safely decrement endorsement count (prevent underflow)
    (if (> current-count u0)
        (map-set endorsement-counts 
          target 
          (- current-count u1)
        )
        true
    )
    
    (ok true)
  )
)