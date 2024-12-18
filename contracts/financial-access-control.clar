;; Financial Access Control Contract

(use-trait ssi-trait .self-sovereign-identity.self-sovereign-identity)
(use-trait vc-trait .verifiable-credentials.verifiable-credentials)

(define-map service-access
  { service-id: uint, user: principal }
  { granted: bool, last-verified: uint }
)

(define-data-var service-counter uint u0)

(define-constant KYC_CREDENTIAL_TYPE "KYC")
(define-constant AML_CREDENTIAL_TYPE "AML")

(define-public (register-service (name (string-ascii 64)))
  (let
    (
      (service-id (var-get service-counter))
    )
    (var-set service-counter (+ service-id u1))
    (ok service-id)
  )
)

(define-public (request-access (ssi-contract <ssi-trait>) (vc-contract <vc-trait>) (service-id uint))
  (let
    (
      (user tx-sender)
      (identity (try! (contract-call? ssi-contract get-identity user)))
      (kyc-credential (try! (contract-call? vc-contract get-credential-by-type user KYC_CREDENTIAL_TYPE)))
      (aml-credential (try! (contract-call? vc-contract get-credential-by-type user AML_CREDENTIAL_TYPE)))
    )
    (asserts! (and
      (is-some kyc-credential)
      (is-some aml-credential)
      (try! (contract-call? vc-contract verify-credential (get credential-id (unwrap! kyc-credential (err u404)))))
      (try! (contract-call? vc-contract verify-credential (get credential-id (unwrap! aml-credential (err u404)))))
    ) (err u403))
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

