;; Financial Access Control Contract

(define-map service-access
  { service-id: uint, user: principal }
  { granted: bool, last-verified: uint }
)

(define-data-var service-counter uint u0)

(define-public (register-service)
  (let
    (
      (service-id (var-get service-counter))
    )
    (var-set service-counter (+ service-id u1))
    (ok service-id)
  )
)

(define-public (request-access (service-id uint))
  (let
    (
      (user tx-sender)
    )
    (map-set service-access
      { service-id: service-id, user: user }
      { granted: true, last-verified: block-height }
    )
    (ok true)
  )
)

(define-read-only (check-access (service-id uint) (user principal))
  (ok (unwrap! (map-get? service-access { service-id: service-id, user: user }) (err u404)))
)
