WITH person_info AS (
    SELECT id,
           first_name,
           last_name
    FROM person
),
comment_stats AS (
    SELECT p.id AS person_id,
           COUNT(c.id) AS comment_count,
           AVG(c.length) AS avg_comment_length,
           SUM(c.length) AS total_comment_length,
           COUNT(DISTINCT c.location_country_id) AS comment_countries
    FROM comment c
    JOIN person p ON c.creator_person_id = p.id
    GROUP BY p.id
),
post_stats AS (
    SELECT p.id AS person_id,
           COUNT(po.id) AS post_count,
           AVG(po.length) AS avg_post_length,
           SUM(po.length) AS total_post_length,
           COUNT(DISTINCT po.location_country_id) AS post_countries
    FROM post po
    JOIN person p ON po.creator_person_id = p.id
    GROUP BY p.id
),
person_countries AS (
    SELECT p.id AS person_id,
           c.location_country_id AS country_id
    FROM comment c
    JOIN person p ON c.creator_person_id = p.id
    UNION
    SELECT p.id,
           po.location_country_id
    FROM post po
    JOIN person p ON po.creator_person_id = p.id
),
orgs_per_person AS (
    SELECT pc.person_id,
           COUNT(DISTINCT o.id) AS org_count
    FROM person_countries pc
    JOIN place pl ON pc.country_id = pl.id
    JOIN organisation o ON o.location_place_id = pl.id
    GROUP BY pc.person_id
)
SELECT pi.id AS person_id,
       pi.first_name,
       pi.last_name,
       COALESCE(cs.comment_count, 0) AS comment_count,
       cs.avg_comment_length,
       cs.total_comment_length,
       COALESCE(ps.post_count, 0) AS post_count,
       ps.avg_post_length,
       ps.total_post_length,
       COALESCE(cs.comment_countries, 0) + COALESCE(ps.post_countries, 0) AS distinct_activity_countries,
       COALESCE(op.org_count, 0) AS organisations_in_activity_countries
FROM person_info pi
LEFT JOIN comment_stats cs ON pi.id = cs.person_id
LEFT JOIN post_stats ps ON pi.id = ps.person_id
LEFT JOIN orgs_per_person op ON pi.id = op.person_id
ORDER BY (COALESCE(cs.comment_count, 0) + COALESCE(ps.post_count, 0)) DESC
LIMIT 100
