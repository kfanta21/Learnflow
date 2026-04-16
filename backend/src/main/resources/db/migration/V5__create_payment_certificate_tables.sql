-- ============================================================
-- V5: Payments + Certificates
-- ============================================================

CREATE TABLE payments (
    id                  BIGSERIAL PRIMARY KEY,
    user_id             BIGINT          NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    course_id           BIGINT          NOT NULL REFERENCES courses(id) ON DELETE RESTRICT,

    amount              DECIMAL(10, 2)  NOT NULL,
    currency            VARCHAR(3)      NOT NULL DEFAULT 'USD',

    status              VARCHAR(20)     NOT NULL DEFAULT 'PENDING'
                            CHECK (status IN ('PENDING', 'SUCCESS', 'FAILED', 'REFUNDED')),

    provider            VARCHAR(20)     NOT NULL DEFAULT 'MOCK'
                            CHECK (provider IN ('STRIPE', 'MOCK')),

    -- Stripe's payment_intent id (null for MOCK provider)
    provider_reference  VARCHAR(255),

    -- Client generates this UUID before sending the payment request.
    -- If the request fails and they retry, the same key returns the
    -- original payment instead of creating a duplicate charge.
    idempotency_key     VARCHAR(255)    UNIQUE,

    paid_at             TIMESTAMPTZ,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE TABLE certificates (
    id                  BIGSERIAL PRIMARY KEY,

    -- UNIQUE: one certificate per enrollment, enforced at DB level
    enrollment_id       BIGINT          NOT NULL UNIQUE
                            REFERENCES enrollments(id) ON DELETE RESTRICT,

    user_id             BIGINT          NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    course_id           BIGINT          NOT NULL REFERENCES courses(id) ON DELETE RESTRICT,

    -- Human-readable: CERT-2024-000001
    -- Used for public verification at /verify/:certNumber
    certificate_number  VARCHAR(50)     NOT NULL UNIQUE,

    issued_at           TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    -- S3 object key: "certificates/2024/CERT-2024-000001.pdf"
    s3_key              VARCHAR(500),

    -- CloudFront signed URL regenerated on demand in Phase 6
    cloudfront_url      VARCHAR(500),

    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

-- Now that payments table exists, add the FK from enrollments.payment_id.
-- This could not be done in V4 because payments did not exist yet.
ALTER TABLE enrollments
    ADD CONSTRAINT fk_enrollment_payment
    FOREIGN KEY (payment_id) REFERENCES payments(id) ON DELETE SET NULL;

-- Indexes
CREATE INDEX idx_payments_user         ON payments(user_id);
CREATE INDEX idx_payments_course       ON payments(course_id);
CREATE INDEX idx_payments_status       ON payments(status);
CREATE INDEX idx_certificates_user     ON certificates(user_id);
CREATE INDEX idx_certificates_number   ON certificates(certificate_number);
