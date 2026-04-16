-- ============================================================
-- V6: Additional Performance Indexes
-- Covers the most common multi-column query patterns.
-- Kept separate so indexes can be added/dropped independently
-- without touching table definitions.
-- ============================================================

-- Course catalog page: filter by category + level + status together.
-- Covers: GET /courses?category=programming&level=BEGINNER
CREATE INDEX idx_courses_filter
    ON courses(category_id, level, status)
    WHERE is_deleted = FALSE;

-- Instructor dashboard: show an instructor's courses by status.
-- Covers: GET /instructor/courses (filtered by instructor + status)
CREATE INDEX idx_courses_instructor_status
    ON courses(instructor_id, status)
    WHERE is_deleted = FALSE;

-- Quiz attempts: find all attempts for a specific quiz.
-- Used when an instructor views quiz analytics.
CREATE INDEX idx_quiz_attempts_quiz ON quiz_attempts(quiz_id);

-- Lesson progress: find all progress records for a specific lesson.
-- Used to count how many students completed a lesson.
CREATE INDEX idx_lesson_progress_lesson ON lesson_progress(lesson_id);

-- Payments: look up a payment by idempotency key on retry.
-- Already has a UNIQUE constraint index but making intent explicit.
CREATE INDEX idx_payments_idempotency ON payments(idempotency_key);