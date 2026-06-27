WITH org_comment_stats AS (
    SELECT
        o.id AS org_id,
        o.name AS org_name,
        org_loc.name AS org_location,
        c_loc.name AS comment_country,
        COUNT(DISTINCT c.id) AS comment_count,
        COUNT(plc.person_id) AS like_count,
        AVG(c.length) AS avg_comment_length,
        CAST(COUNT(plc.person_id) AS double) / NULLIF(COUNT(DISTINCT c.id), 0) AS likes_per_comment
    FROM person_work_at_company pwc
    JOIN person p
        ON pwc.person_id = p.id
    JOIN comment c
        ON c.creator_person_id = p.id
    JOIN place c_loc
        ON c.location_country_id = c_loc.id
    JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    JOIN organisation o
        ON pwc.company_id = o.id
    JOIN place org_loc
        ON o.location_place_id = org_loc.id
    GROUP BY o.id, o.name, org_loc.name, c_loc.name
)
SELECT *
FROM org_comment_stats
ORDER BY like_count DESC, comment_count DESC
LIMIT 100
