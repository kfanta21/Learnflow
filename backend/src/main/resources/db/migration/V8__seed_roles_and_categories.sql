-- ============================================================
-- V8: Seed Data — Roles + Categories
-- Runs exactly once. Flyway tracks it in flyway_schema_history.
-- No need to check if data exists — Flyway guarantees that.
-- ============================================================

-- The 3 fixed roles every environment needs to function
INSERT INTO roles (name, description) VALUES
    ('STUDENT',    'Can browse, enroll, and complete courses'),
    ('INSTRUCTOR', 'Can create and publish courses, view enrollment analytics'),
    ('ADMIN',      'Full system access — manages users, courses, and enrollments');

-- Top-level categories
INSERT INTO categories (name, slug, parent_id) VALUES
    ('Technology',           'technology',           NULL),
    ('Business',             'business',             NULL),
    ('Design',               'design',               NULL),
    ('Personal Development', 'personal-development', NULL);

-- Subcategories — reference parents by slug lookup
INSERT INTO categories (name, slug, parent_id)
SELECT 'Programming', 'programming', id FROM categories WHERE slug = 'technology';

INSERT INTO categories (name, slug, parent_id)
SELECT 'Data Science', 'data-science', id FROM categories WHERE slug = 'technology';

INSERT INTO categories (name, slug, parent_id)
SELECT 'Cloud Computing', 'cloud-computing', id FROM categories WHERE slug = 'technology';

INSERT INTO categories (name, slug, parent_id)
SELECT 'Entrepreneurship', 'entrepreneurship', id FROM categories WHERE slug = 'business';

INSERT INTO categories (name, slug, parent_id)
SELECT 'UI/UX Design', 'ui-ux-design', id FROM categories WHERE slug = 'design';