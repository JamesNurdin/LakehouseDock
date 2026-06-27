WITH org_members AS (
    -- Employees of companies
    SELECT
        o.id AS org_id,
        o.name AS org_name,
        o.type AS org_type,
        p.id AS person_id
    FROM organisation o
    JOIN person_work_at_company wc ON wc.company_id = o.id
    JOIN person p ON p.id = wc.person_id
    UNION ALL
    -- Students of universities
    SELECT
        o.id AS org_id,
        o.name AS org_name,
        o.type AS org_type,
        p.id AS person_id
    FROM organisation o
    JOIN person_study_at_university su ON su.university_id = o.id
    JOIN person p ON p.id = su.person_id
),
comment_like_counts AS (
    SELECT
        clc.comment_id,
        COUNT(*) AS like_cnt
    FROM person_likes_comment clc
    GROUP BY clc.comment_id
),
org_comment_agg AS (
    SELECT
        om.org_id,
        COUNT(DISTINCT c.id) AS comment_cnt,
        AVG(c.length) AS avg_comment_len,
        COALESCE(SUM(lc.like_cnt), 0) AS total_likes
    FROM org_members om
    JOIN comment c ON c.creator_person_id = om.person_id
    LEFT JOIN comment_like_counts lc ON lc.comment_id = c.id
    GROUP BY om.org_id
)
SELECT
    o.id AS organisation_id,
    o.name AS organisation_name,
    o.type AS organisation_type,
    ca.comment_cnt,
    ca.avg_comment_len,
    ca.total_likes
FROM organisation o
JOIN org_comment_agg ca ON ca.org_id = o.id
ORDER BY ca.total_likes DESC
LIMIT 100
