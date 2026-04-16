-- ============================================================
-- V2: Categories + Courses
-- Most complex migration — GENERATED column, tsvector, TEXT[].
-- ============================================================

CREATE TABLE categories (
    id          BIGSERIAL PRIMARY KEY,
    name        VARCHAR(100)    NOT NULL,
    slug        VARCHAR(100)    NOT NULL UNIQUE,
    -- Self-referencing: Technology → Programming → Backend → Spring Boot
    parent_id   BIGINT          REFERENCES categories(id) ON DELETE SET NULL
);

CREATE INDEX idx_categories_slug   ON categories(slug);
CREATE INDEX idx_categories_parent ON categories(parent_id);

CREATE TABLE courses (
    id                  BIGSERIAL PRIMARY KEY,
    slug                VARCHAR(255)        NOT NULL UNIQUE,
    title               VARCHAR(255)        NOT NULL,
    subtitle            VARCHAR(500),
    description         TEXT,
    thumbnail_url       VARCHAR(500),
    preview_video_url   VARCHAR(500),

    instructor_id       BIGINT              REFERENCES users(id) ON DELETE SET NULL,
    category_id         BIGINT              REFERENCES categories(id) ON DELETE SET NULL,

    price               DECIMAL(10, 2)      NOT NULL DEFAULT 0.00,

    -- GENERATED ALWAYS AS: PostgreSQL computes this from price automatically.
    -- You never write to this column. When price = 0, is_free = true.
    -- Eliminates the bug where price and is_free get out of sync.
    is_free             BOOLEAN GENERATED ALWAYS AS (price = 0) STORED,

    level               VARCHAR(20)         NOT NULL DEFAULT 'BEGINNER'
                            CHECK (level IN ('BEGINNER', 'INTERMEDIATE', 'ADVANCED')),

    status              VARCHAR(20)         NOT NULL DEFAULT 'DRAFT'
                            CHECK (status IN ('DRAFT', 'PUBLISHED', 'ARCHIVED')),

    -- TEXT[]: PostgreSQL native array.
    -- Stores tags like: {'spring-boot', 'java', 'backend'}
    -- Queryable with GIN index: WHERE 'java' = ANY(tags)
    tags                TEXT[],

    language            VARCHAR(10)         NOT NULL DEFAULT 'en',

    -- TSVECTOR: preprocessed document for full-text search.
    -- Auto-populated by the trigger in V7. Never write to this manually.
    -- Why tsvector over LIKE?
    -- LIKE '%spring boot%' does a full table scan — O(n), slow at scale.
    -- tsvector with GIN index is O(log n) and understands word stemming.
    search_vector       TSVECTOR,

    -- Denormalized counters: updated async via Kafka in Phase 7.
    -- Avoids expensive COUNT() joins on every course listing request.
    total_duration_mins INT                 NOT NULL DEFAULT 0,
    total_lessons       INT                 NOT NULL DEFAULT 0,
    enrolled_count      INT                 NOT NULL DEFAULT 0,

    published_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    is_deleted          BOOLEAN             NOT NULL DEFAULT FALSE,
    deleted_at          TIMESTAMPTZ
);

-- GIN index on tsvector: enables fast full-text search
CREATE INDEX idx_courses_search ON courses USING GIN(search_vector);

-- GIN index on tags array: enables fast array containment queries
CREATE INDEX idx_courses_tags ON courses USING GIN(tags);

-- Partial index: only index PUBLISHED non-deleted courses.
-- The homepage only ever shows published courses so this index
-- is much smaller and faster than a full index.
CREATE INDEX idx_courses_published
    ON courses(status, published_at DESC)
    WHERE is_deleted = FALSE AND status = 'PUBLISHED';

CREATE INDEX idx_courses_instructor ON courses(instructor_id);
CREATE INDEX idx_courses_category   ON courses(category_id);