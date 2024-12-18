;; Self-Sovereign Identity Contract

(define-map identities
  { owner: principal }
  {
    did: (string-ascii 64),
    public-key: (buff 33),
    created-at: uint,
    updated-at: uint
  }
)

(define-data-var did-counter uint u0)

(define-public (create-identity (public-key (buff 33)))
  (let
    (
      (owner tx-sender)
      (did (concat "did:stacks:" (var-get did-counter)))
    )
    (asserts! (is-none (map-get? identities { owner: owner })) (err u403)) ;; Identity already exists
    (map-set identities
      { owner: owner }
      {
        did: did,
        public-key: public-key,
        created-at: block-height,
        updated-at: block-height
      }
    )
    (var-set did-counter (+ (var-get did-counter) u1))
    (ok did)
  )
)

(define-public (update-identity (public-key (buff 33)))
  (let
    (
      (owner tx-sender)
      (identity (unwrap! (map-get? identities { owner: owner }) (err u404)))
    )
    (map-set identities
      { owner: owner }
      (merge identity {
        public-key: public-key,
        updated-at: block-height
      })
    )
    (ok true)
  )
)

(define-read-only (get-identity (owner principal))
  (ok (unwrap! (map-get? identities { owner: owner }) (err u404)))
)

