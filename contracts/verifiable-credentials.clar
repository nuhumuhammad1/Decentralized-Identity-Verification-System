;; Verifiable Credentials Contract

(define-map credentials
  { credential-id: uint }
  {
    issuer: principal,
    holder: principal,
    type: (string-ascii 64),
    issued-at: uint,
    expires-at: uint,
    revoked: bool
  }
)

(define-data-var credential-counter uint u0)

(define-constant ISSUER_ROLE u1)
(define-constant VERIFIER_ROLE u2)

(define-map roles { user: principal } { role: uint })

(define-public (set-role (user principal) (role uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u403))
    (asserts! (or (is-eq role ISSUER_ROLE) (is-eq role VERIFIER_ROLE)) (err u400))
    (ok (map-set roles { user: user } { role: role }))
  )
)

(define-public (issue-credential (holder principal) (type (string-ascii 64)) (expires-at uint))
  (let
    (
      (issuer tx-sender)
      (credential-id (var-get credential-counter))
    )
    (asserts! (is-eq (get role (default-to { role: u0 } (map-get? roles { user: issuer }))) ISSUER_ROLE) (err u403))
    (map-set credentials
      { credential-id: credential-id }
      {
        issuer: issuer,
        holder: holder,
        type: type,
        issued-at: block-height,
        expires-at: expires-at,
        revoked: false
      }
    )
    (var-set credential-counter (+ credential-id u1))
    (ok credential-id)
  )
)

(define-public (revoke-credential (credential-id uint))
  (let
    (
      (issuer tx-sender)
      (credential (unwrap! (map-get? credentials { credential-id: credential-id }) (err u404)))
    )
    (asserts! (is-eq issuer (get issuer credential)) (err u403))
    (ok (map-set credentials
      { credential-id: credential-id }
      (merge credential { revoked: true })
    ))
  )
)

(define-read-only (verify-credential (credential-id uint))
  (let
    (
      (credential (unwrap! (map-get? credentials { credential-id: credential-id }) (err u404)))
    )
    (asserts! (is-eq (get role (default-to { role: u0 } (map-get? roles { user: tx-sender }))) VERIFIER_ROLE) (err u403))
    (ok {
      valid: (and
        (not (get revoked credential))
        (>= (get expires-at credential) block-height)
      ),
      credential: credential
    })
  )
)

(define-data-var contract-owner principal tx-sender)

(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u403))
    (ok (var-set contract-owner new-owner))
  )
)
