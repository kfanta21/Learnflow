-- ============================================================
-- V3: Sections, Lessons, Quizzes
-- Course content hierarchy: Course → Section → Lesson → Quiz
-- ============================================================

CREATE TABLE sections (
    id          BIGSERIAL PRIMARY KEY,
    course_id   BIGINT          NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    title       VARCHAR(255)    NOT NULL,
    description TEXT,

    -- position: display order within the course (1, 2, 3...)
    position    INT             NOT NULL DEFAULT 0,

    created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sections_course ON sections(course_id, position);

CREATE TABLE lessons (
    id          BIGSERIAL PRIMARY KEY,
    section_id  BIGINT          NOT NULL REFERENCES sections(id) ON DELETE CASCADE,
    title       VARCHAR(255)    NOT NULL,

    lesson_type VARCHAR(20)     NOT NULL
                    CHECK (lesson_type IN ('VIDEO', 'TEXT', 'QUIZ', 'PDF')),

    -- For VIDEO/PDF: the S3 object key, not the public URL.
    -- We generate signed CloudFront URLs on demand in Phase 6.
    content_url     VARCHAR(500),

    -- For TEXT lessons: HTML or Markdown content stored directly
    content_text    TEXT,

    duration_mins   INT         NOT NULL DEFAULT 0,
    position        INT         NOT NULL DEFAULT 0,

    -- Preview lessons are visible to non-enrolled users (free sample)
    is_preview      BOOLEAN     NOT NULL DEFAULT FALSE,

    created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_lessons_section ON lessons(section_id, position);

CREATE TABLE quizzes (
    id          BIGSERIAL PRIMARY KEY,

    -- UNIQUE: enforces one quiz per lesson at the database level
    lesson_id   BIGINT          NOT NULL UNIQUE REFERENCES lessons(id) ON DELETE CASCADE,

    title       VARCHAR(255)    NOT NULL,

    -- Percentage required to pass (70 = 70%)
    pass_score  INT             NOT NULL DEFAULT 70,

    -- JSONB: stores the entire question set as structured JSON.
    -- Format: [{question, type, options[], correct_index, explanation}]
    -- Why JSONB?
    -- Questions are variable-structure. Modeling this relationally
    -- would need 4+ tables. JSONB keeps it clean and queryable.
    questions   JSONB           NOT NULL DEFAULT '[]',

    created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);