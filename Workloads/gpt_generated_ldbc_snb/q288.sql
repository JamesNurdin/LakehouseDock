/*
  Analytical query: counts and averages of comments and posts per country and gender,
  plus number of organisations located in each country.
*/
WITH comment_agg AS (
    SELECT
        pl.id   AS country_id,
        pl.name AS country_name,
        per.gender,
        COUNT(*)                AS comment_count,
        AVG(comment.length)     AS avg_comment_length
    FROM comment
    JOIN person per   ON comment.creator_person_id = per.id
    JOIN place  pl    ON comment.location_country_id = pl.id
    WHERE pl.type = 'Country'
    GROUP BY pl.id, pl.name, per.gender
),
post_agg AS (
    SELECT
        pl.id   AS country_id,
        pl.name AS country_name,
        per.gender,
        COUNT(*)                AS post_count,
        AVG(post.length)        AS avg_post_length
    FROM post
    JOIN person per   ON post.creator_person_id = per.id
    JOIN place  pl    ON post.location_country_id = pl.id
    WHERE pl.type = 'Country'
    GROUP BY pl.id, pl.name, per.gender
),
org_agg AS (
    SELECT
        pl.id   AS country_id,
        pl.name AS country_name,
        COUNT(*) AS org_count
    FROM organisation
    JOIN place pl ON organisation.location_place_id = pl.id
    WHERE pl.type = 'Country'
    GROUP BY pl.id, pl.name
)
SELECT
    COALESCE(c.country_id, p.country_id, o.country_id)   AS country_id,
    COALESCE(c.country_name, p.country_name, o.country_name) AS country_name,
    COALESCE(c.gender, p.gender)                         AS gender,
    COALESCE(c.comment_count, 0)                         AS comment_count,
    COALESCE(p.post_count, 0)                            AS post_count,
    COALESCE(c.avg_comment_length, 0)                    AS avg_comment_length,
    COALESCE(p.avg_post_length, 0)                       AS avg_post_length,
    COALESCE(o.org_count, 0)                             AS org_count
FROM comment_agg c
FULL OUTER JOIN post_agg p
    ON c.country_id = p.country_id
   AND c.gender     = p.gender
FULL OUTER JOIN org_agg o
    ON COALESCE(c.country_id, p.country_id) = o.country_id
ORDER BY country_name, gender
