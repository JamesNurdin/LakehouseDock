WITH comment_region_stats AS (
    SELECT
        COALESCE(parent.id, p.id) AS region_id,
        COALESCE(parent.name, p.name) AS region_name,
        COUNT(c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length,
        COUNT(DISTINCT c.creator_person_id) AS distinct_commenters
    FROM comment c
    JOIN place p
        ON c.location_country_id = p.id
    LEFT JOIN place parent
        ON p.part_of_place_id = parent.id
    GROUP BY
        COALESCE(parent.id, p.id),
        COALESCE(parent.name, p.name)
),
post_region_stats AS (
    SELECT
        COALESCE(parent.id, pl.id) AS region_id,
        COALESCE(parent.name, pl.name) AS region_name,
        COUNT(DISTINCT po.id) AS post_count,
        COUNT(plp.person_id) AS total_likes,
        COUNT(DISTINCT plp.person_id) AS distinct_likers
    FROM post po
    JOIN place pl
        ON po.location_country_id = pl.id
    LEFT JOIN place parent
        ON pl.part_of_place_id = parent.id
    LEFT JOIN person_likes_post plp
        ON plp.post_id = po.id
    GROUP BY
        COALESCE(parent.id, pl.id),
        COALESCE(parent.name, pl.name)
)
SELECT
    COALESCE(cr.region_name, pr.region_name) AS region_name,
    cr.comment_count,
    cr.avg_comment_length,
    cr.distinct_commenters,
    pr.post_count,
    pr.total_likes,
    pr.distinct_likers
FROM comment_region_stats cr
FULL OUTER JOIN post_region_stats pr
    ON cr.region_id = pr.region_id
ORDER BY COALESCE(cr.comment_count, 0) DESC
LIMIT 20
