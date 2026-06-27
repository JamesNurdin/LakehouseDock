WITH comment_stats AS (
    SELECT
        p.id   AS place_id,
        p.name AS place_name,
        COUNT(c.id)                     AS comment_count,
        AVG(c.length)                   AS avg_comment_length,
        COUNT(DISTINCT c.creator_person_id) AS distinct_commenters
    FROM comment c
    JOIN place p ON c.location_country_id = p.id
    GROUP BY p.id, p.name
),
post_stats AS (
    SELECT
        p.id   AS place_id,
        p.name AS place_name,
        COUNT(po.id)                    AS post_count,
        AVG(po.length)                  AS avg_post_length,
        COUNT(DISTINCT po.creator_person_id) AS distinct_posters
    FROM post po
    JOIN place p ON po.location_country_id = p.id
    GROUP BY p.id, p.name
),
org_stats AS (
    SELECT
        pl.id   AS place_id,
        pl.name AS place_name,
        COUNT(o.id) AS org_count
    FROM organisation o
    JOIN place pl ON o.location_place_id = pl.id
    GROUP BY pl.id, pl.name
)
SELECT
    COALESCE(cs.place_id, ps.place_id, os.place_id)   AS place_id,
    COALESCE(cs.place_name, ps.place_name, os.place_name) AS place_name,
    COALESCE(cs.comment_count, 0)        AS comment_count,
    COALESCE(cs.avg_comment_length, 0)  AS avg_comment_length,
    COALESCE(cs.distinct_commenters, 0) AS distinct_commenters,
    COALESCE(ps.post_count, 0)          AS post_count,
    COALESCE(ps.avg_post_length, 0)     AS avg_post_length,
    COALESCE(ps.distinct_posters, 0)    AS distinct_posters,
    COALESCE(os.org_count, 0)           AS org_count
FROM comment_stats cs
FULL OUTER JOIN post_stats ps ON cs.place_id = ps.place_id
FULL OUTER JOIN org_stats os ON COALESCE(cs.place_id, ps.place_id) = os.place_id
ORDER BY comment_count DESC
LIMIT 20
