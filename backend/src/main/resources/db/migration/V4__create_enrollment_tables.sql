-- ============================================================
-- V4: Enrollments, Lesson Progress, Quiz Attempts
-- The student journey through a course.
-- ============================================================

CREATE TABLE enrollments (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT          NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    course_id   BIGINT          NOT NULL REFERENCES courses(id) ON DELETE RESTRICT,

    -- RESTRICT: cannot delete a user or course that has enrollments.
    -- Enrollment records are permanent academic and financial records.

    status      VARCHAR(20)     NOT NULL DEFAULT 'ACTIVE'
                    CHECK (status IN ('ACTIVE', 'COMPLETED', 'CANCELLED')),

    -- NULL for free courses — paid courses link to a payment record
    payment_id  BIGINT,

    enrolled_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Database-level guard: one enrollment per student per course.
    -- Even if service layer has a bug, this prevents duplicate enrollments.
    CONSTRAINT uq_enrollment UNIQUE (user_id, course_id)
);

CREATE TABLE lesson_progress (
    id              BIGSERIAL PRIMARY KEY,
    enrollment_id   BIGINT      NOT NULL REFERENCES enrollments(id) ON DELETE CASCADE,
    lesson_id       BIGINT      NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
    completed_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- A lesson can only be completed once per enrollment
    CONSTRAINT uq_lesson_progress UNIQUE (enrollment_id, lesson_id)
);

CREATE TABLE quiz_attempts (
    id              BIGSERIAL PRIMARY KEY,
    enrollment_id   BIGINT      NOT NULL REFERENCES enrollments(id) ON DELETE CASCADE,
    quiz_id         BIGINT      NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,

    -- JSONB: stores submitted answers [{question_index, selected_index}]
    answers         JSONB       NOT NULL DEFAULT '[]',

    score           INT         NOT NULL DEFAULT 0,
    passed          BOOLEAN     NOT NULL DEFAULT FALSE,
    attempted_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
    -- No UNIQUE constraint: students can attempt quizzes multiple times
);

-- Indexes
CREATE INDEX idx_enrollments_user   ON enrollments(user_id);
CREATE INDEX idx_enrollments_course ON enrollments(course_id);
CREATE INDEX idx_enrollments_status ON enrollments(status);

-- Partial index: only index ACTIVE enrollments.
-- The student dashboard only shows active enrollments in real time.
-- Completed/cancelled are rarely queried.
CREATE INDEX idx_enrollments_active
    ON enrollments(user_id, course_id)
    WHERE status = 'ACTIVE';

CREATE INDEX idx_lesson_progress_enrollment ON lesson_progress(enrollment_id);
CREATE INDEX idx_quiz_attempts_enrollment   ON quiz_attempts(enrollment_id);