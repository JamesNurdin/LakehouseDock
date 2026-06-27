-- Analytical query: comment activity per country with top commenter
WITH comment_person_country AS (
    SELECT
        pc.id AS country_id,
        pc.name AS country_name,
        p.id AS person_id,
        p.first_name,
        p.last_name,
        COUNT(c.id) AS person_comment_count
    FROM comment c
    JOIN person p
        ON c.creator_person_id = p.id
    JOIN place pc
        ON c.location_country_id = pc.id
    GROUP BY pc.id, pc.name, p.id, p.first_name, p.last_name
),
top_commenter AS (
    SELECT
        country_id,
        country_name,
        person_id,
        first_name,
        last_name,
        person_comment_count,
        ROW_NUMBER() OVER (PARTITION BY country_id ORDER BY person_comment_count DESC) AS rn
    FROM comment_person_country
),
country_agg AS (
    SELECT
        pc.id AS country_id,
        pc.name AS country_name,
        pr.name AS region_name,
        COUNT(c.id) AS total_comments,
        AVG(c.length) AS avg_comment_length,
        COUNT(DISTINCT p.id) AS distinct_commenters,
        SUM(CASE WHEN c.parent_comment_id IS NOT NULL THEN 1 ELSE 0 END) AS reply_comments,
        SUM(CASE WHEN c.parent_comment_id IS NULL THEN 1 ELSE 0 END) AS top_level_comments
    FROM comment c
    JOIN person p
        ON c.creator_person_id = p.id
    JOIN place pc
        ON c.location_country_id = pc.id
    LEFT JOIN place pr
        ON pc.part_of_place_id = pr.id
    GROUP BY pc.id, pc.name, pr.name
)
SELECT
    ca.country_id,
    ca.country_name,
    ca.region_name,
    ca.total_comments,
    ca.avg_comment_length,
    ca.distinct_commenters,
    ca.reply_comments,
    ca.top_level_comments,
    tc.person_id AS top_commenter_id,
    tc.first_name AS top_commenter_first_name,
    tc.last_name AS top_commenter_last_name,
    tc.person_comment_count AS top_commenter_comment_count
FROM country_agg ca
LEFT JOIN top_commenter tc
    ON ca.country_id = tc.country_id
    AND tc.rn = 1
ORDER BY ca.total_comments DESC
LIMIT 100
