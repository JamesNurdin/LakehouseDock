WITH org_posts AS (
    -- Posts created by employees of an organisation (company)
    SELECT
        o.id AS org_id,
        o.name AS org_name,
        o.type AS org_type,
        pl.name AS org_location_name,
        pl.type AS org_location_type,
        p.id AS post_id,
        p.length AS post_length,
        'employee' AS assoc_type
    FROM organisation o
    JOIN person_work_at_company pwc ON pwc.company_id = o.id
    JOIN person per ON per.id = pwc.person_id
    JOIN post p ON p.creator_person_id = per.id
    LEFT JOIN place pl ON pl.id = o.location_place_id

    UNION ALL

    -- Posts created by students of an organisation (university)
    SELECT
        o.id AS org_id,
        o.name AS org_name,
        o.type AS org_type,
        pl.name AS org_location_name,
        pl.type AS org_location_type,
        p.id AS post_id,
        p.length AS post_length,
        'student' AS assoc_type
    FROM organisation o
    JOIN person_study_at_university psu ON psu.university_id = o.id
    JOIN person per ON per.id = psu.person_id
    JOIN post p ON p.creator_person_id = per.id
    LEFT JOIN place pl ON pl.id = o.location_place_id
)
SELECT
    op.org_id,
    op.org_name,
    op.org_type,
    op.org_location_name,
    op.org_location_type,
    op.assoc_type,
    COUNT(DISTINCT op.post_id) AS post_count,
    AVG(op.post_length) AS avg_post_length,
    COUNT(plp.person_id) AS like_count
FROM org_posts op
LEFT JOIN person_likes_post plp ON plp.post_id = op.post_id
GROUP BY
    op.org_id,
    op.org_name,
    op.org_type,
    op.org_location_name,
    op.org_location_type,
    op.assoc_type
ORDER BY
    op.org_id,
    op.assoc_type
