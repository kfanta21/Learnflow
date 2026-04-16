-- ============================================================
-- V1: Roles, Users, User Roles, Refresh Tokens
-- Foundation for the entire auth system.
-- ============================================================

-- Roles first: users reference roles, not the other way around.
-- Using VARCHAR + CHECK instead of PostgreSQL native ENUM because:
-- adding a value to a native ENUM requires ALTER TYPE which can
-- lock the table under load. VARCHAR + CHECK is safer to migrate.
CREATE TABLE roles (
    id          BIGSERIAL PRIMARY KEY,
    name        VARCHAR(50)     NOT NULL UNIQUE
                    CHECK (name IN ('STUDENT', 'INSTRUCTOR', 'ADMIN')),
    description VARCHAR(255)
);

CREATE TABLE users (
    id              BIGSERIAL PRIMARY KEY,
    email           VARCHAR(255)    NOT NULL UNIQUE,

    -- NULL allowed: Google OAuth users never set a password
    password_hash   VARCHAR(255),

    first_name      VARCHAR(100)    NOT NULL,
    last_name       VARCHAR(100)    NOT NULL,
    bio             TEXT,
    avatar_url      VARCHAR(500),

    status          VARCHAR(30)     NOT NULL DEFAULT 'PENDING_VERIFICATION'
                        CHECK (status IN ('ACTIVE', 'SUSPENDED', 'PENDING_VERIFICATION')),

    auth_provider   VARCHAR(20)     NOT NULL DEFAULT 'LOCAL'
                        CHECK (auth_provider IN ('LOCAL', 'GOOGLE')),

    -- Google's unique user ID from their OAuth token
    provider_id     VARCHAR(255),

    -- TIMESTAMPTZ stores an absolute moment in time (always UTC internally).
    -- Unlike TIMESTAMP, it is unambiguous regardless of server timezone.
    -- Always use TIMESTAMPTZ in production systems.
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    -- Soft delete: users with enrollments cannot be hard deleted.
    -- Deleting the row would orphan enrollment and payment records.
    is_deleted      BOOLEAN         NOT NULL DEFAULT FALSE,
    deleted_at      TIMESTAMPTZ
);

-- Join table: one user can have multiple roles
CREATE TABLE user_roles (
    user_id     BIGINT  NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id     BIGINT  NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE refresh_tokens (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT          NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- SHA-256 hash of the token, never the raw value.
    -- If this table is breached, hashes are useless to an attacker.
    token_hash  VARCHAR(255)    NOT NULL UNIQUE,

    expires_at  TIMESTAMPTZ     NOT NULL,
    revoked     BOOLEAN         NOT NULL DEFAULT FALSE,
    revoked_at  TIMESTAMPTZ,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_users_email       ON users(email);
CREATE INDEX idx_users_status      ON users(status);
CREATE INDEX idx_users_provider    ON users(auth_provider, provider_id);

-- Partial index: only index non-deleted users.
-- Most queries -- ============================================================
-- V1: Roles, Users, User Roles, Refresh Tokens
-- Foundation for the entire auth system.
-- ============================================================

-- Roles first: users reference roles, not the other way around.
-- Using VARCHAR + CHECK instead of PostgreSQL native ENUM because:
-- adding a value to a native ENUM requires ALTER TYPE which can
-- lock the table under load. VARCHAR + CHECK is safer to migrate.
CREATE TABLE roles (
    id          BIGSERIAL PRIMARY KEY,
    name        VARCHAR(50)     NOT NULL UNIQUE
                    CHECK (name IN ('STUDENT', 'INSTRUCTOR', 'ADMIN')),
    description VARCHAR(255)
);

CREATE TABLE users (
    id              BIGSERIAL PRIMARY KEY,
    email           VARCHAR(255)    NOT NULL UNIQUE,

    -- NULL allowed: Google OAuth users never set a password
    password_hash   VARCHAR(255),

    first_name      VARCHAR(100)    NOT NULL,
    last_name       VARCHAR(100)    NOT NULL,
    bio             TEXT,
    avatar_url      VARCHAR(500),

    status          VARCHAR(30)     NOT NULL DEFAULT 'PENDING_VERIFICATION'
                        CHECK (status IN ('ACTIVE', 'SUSPENDED', 'PENDING_VERIFICATION')),

    auth_provider   VARCHAR(20)     NOT NULL DEFAULT 'LOCAL'
                        CHECK (auth_provider IN ('LOCAL', 'GOOGLE')),

    -- Google's unique user ID from their OAuth token
    provider_id     VARCHAR(255),

    -- TIMESTAMPTZ stores an absolute moment in time (always UTC internally).
    -- Unlike TIMESTAMP, it is unambiguous regardless of server timezone.
    -- Always use TIMESTAMPTZ in production systems.
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    -- Soft delete: users with enrollments cannot be hard deleted.
    -- Deleting the row would orphan enrollment and payment records.
    is_deleted      BOOLEAN         NOT NULL DEFAULT FALSE,
    deleted_at      TIMESTAMPTZ
);

-- Join table: one user can have multiple roles
CREATE TABLE user_roles (
    user_id     BIGINT  NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id     BIGINT  NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE refresh_tokens (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT          NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- SHA-256 hash of the token, never the raw value.
    -- If this table is breached, hashes are useless to an attacker.
    token_hash  VARCHAR(255)    NOT NULL UNIQUE,

    expires_at  TIMESTAMPTZ     NOT NULL,
    revoked     BOOLEAN         NOT NULL DEFAULT FALSE,
    revoked_at  TIMESTAMPTZ,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_users_email       ON users(email);
CREATE INDEX idx_users_status      ON users(status);
CREATE INDEX idx_users_provider    ON users(auth_provider, provider_id);

-- Partial index: only index non-deleted users.
-- Most queries filter is_deleted = false anyway.
-- A partial index is smaller and faster than a full index.
CREATE INDEX idx_users_not_deleted ON users(id) WHERE is_deleted = FALSE;

CREATE INDEX idx_user_roles_user   ON user_roles(user_id);

-- Partial index: only index active (non-revoked) tokens.
-- Revoked tokens are rarely looked up after revocation.
CREATE INDEX idx_refresh_tokens_lookup
    ON refresh_tokens(user_id, token_hash)
    WHERE revoked = FALSE;filter is_deleted = false anyway.
-- A partial index is smaller and faster than a full index.
CREATE INDEX idx_users_not_deleted ON users(id) WHERE is_deleted = FALSE;

CREATE INDEX idx_user_roles_user   ON user_roles(user_id);

-- Partial index: only index active (non-revoked) tokens.
-- Revoked tokens are rarely looked up after revocation.
CREATE INDEX idx_refresh_tokens_lookup
    ON refresh_tokens(user_id, token_hash)
    WHERE revoked = FALSE;