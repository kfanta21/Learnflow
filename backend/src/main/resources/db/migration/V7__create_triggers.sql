-- ============================================================
-- V7: Database Triggers
-- Trigger 1: auto-update updated_at on every row update
-- Trigger 2: auto-update course search_vector on title/description change
-- ============================================================

-- ── Trigger 1: Auto-update updated_at ──────────────────────
-- Fires BEFORE every UPDATE on tables that have an updated_at column.
-- More reliable than @UpdateTimestamp in Hibernate because it fires
-- for ALL updates, not just ones made through the application.

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to every table that has an updated_at column
CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_courses_updated_at
    BEFORE UPDATE ON courses
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_sections_updated_at
    BEFORE UPDATE ON sections
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_lessons_updated_at
    BEFORE UPDATE ON lessons
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_quizzes_updated_at
    BEFORE UPDATE ON quizzes
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_enrollments_updated_at
    BEFORE UPDATE ON enrollments
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_payments_updated_at
    BEFORE UPDATE ON payments
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ── Trigger 2: Auto-update course search_vector ────────────
-- Fires BEFORE INSERT or UPDATE of title, subtitle, or description.
-- Rebuilds the tsvector so full-text search is always current.
--
-- setweight assigns relevance ranking:
-- A (highest) = title match ranks first in results
-- B (medium)  = subtitle match ranks second
-- C (lowest)  = description match ranks third
--
-- Example: a student searching "spring boot" will see courses
-- with "Spring Boot" in the TITLE ranked above courses that only
-- mention it in the description.

CREATE OR REPLACE FUNCTION update_course_search_vector()
RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector :=
        setweight(to_tsvector('english', COALESCE(NEW.title, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.subtitle, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(NEW.description, '')), 'C');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_course_search_vector
    BEFORE INSERT OR UPDATE OF title, subtitle, description
    ON courses
    FOR EACH ROW EXECUTE FUNCTION update_course_search_vector();