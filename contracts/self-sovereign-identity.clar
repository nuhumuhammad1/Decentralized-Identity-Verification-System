;; Self-Sovereign Identity Contract

(define-map identities
  { owner: principal }
  {
    public-key: (buff 33),
    created-at: uint,
    updated-at: uint
  }
)

(define-public (create-identity (public-key (buff 33)))
  (let
    (
      (owner tx-sender)
    )
    (asserts! (is-none (map-get? identities { owner: owner })) (err u403)) ;; Identity already exists
    (ok (map-set identities
      { owner: owner }
      {
        public-key: public-key,
        created-at: block-height,
        updated-at: block-height
      }
    ))
  )
)

(define-public (update-identity (public-key (buff 33)))
  (let
    (
      (owner tx-sender)
      (identity (unwrap! (map-get? identities { owner: owner }) (err u404)))
    )
    (ok (map-set identities
      { owner: owner }
      (merge identity {
        public-key: public-key,
        updated-at: block-height
      })
    ))
  )
)

(define-read-only (get-identity (owner principal))
  (ok (unwrap! (map-get? identities { owner: owner }) (err u404)))
)

