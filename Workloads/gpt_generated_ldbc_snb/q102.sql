WITH post_stats AS (
    SELECT
        c.id AS country_id,
        c.name AS country_name,
        COUNT(p.id) AS total_posts,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT u.id) AS distinct_authors
    FROM post p
    JOIN place c ON p.location_country_id = c.id
    JOIN person u ON p.creator_person_id = u.id
    GROUP BY c.id, c.name
),
org_stats AS (
    SELECT
        CASE
            WHEN op.type = 'Country' THEN op.id
            ELSE co.id
        END AS country_id,
        COUNT(DISTINCT o.id) AS total_organizations
    FROM organisation o
    JOIN place op ON o.location_place_id = op.id
    LEFT JOIN place co ON op.part_of_place_id = co.id
    GROUP BY CASE
        WHEN op.type = 'Country' THEN op.id
        ELSE co.id
    END
)
SELECT
    ps.country_name,
    ps.total_posts,
    ROUND(ps.avg_post_length, 2) AS avg_post_length,
    ps.distinct_authors,
    COALESCE(os.total_organizations, 0) AS total_organizations
FROM post_stats ps
LEFT JOIN org_stats os ON ps.country_id = os.country_id
ORDER BY ps.total_posts DESC
LIMIT 100
