WITH post_agg AS (
    SELECT
        p.location_country_id AS country_id,
        COUNT(*) AS post_cnt,
        AVG(p.length) AS avg_post_len,
        COUNT(DISTINCT p.creator_person_id) AS distinct_post_authors,
        COUNT(DISTINCT plp.person_id) AS distinct_post_likers
    FROM post p
    LEFT JOIN person_likes_post plp
        ON plp.post_id = p.id
    GROUP BY p.location_country_id
),
comment_agg AS (
    SELECT
        c.location_country_id AS country_id,
        COUNT(*) AS comment_cnt,
        AVG(c.length) AS avg_comment_len,
        COUNT(DISTINCT c.creator_person_id) AS distinct_comment_authors,
        COUNT(DISTINCT plc.person_id) AS distinct_comment_likers
    FROM comment c
    LEFT JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    GROUP BY c.location_country_id
)
SELECT
    co.id AS country_id,
    co.name AS country_name,
    co.type AS place_type,
    COALESCE(pa.post_cnt, 0) AS total_posts,
    COALESCE(ca.comment_cnt, 0) AS total_comments,
    pa.avg_post_len,
    ca.avg_comment_len,
    pa.distinct_post_authors,
    ca.distinct_comment_authors,
    pa.distinct_post_likers,
    ca.distinct_comment_likers
FROM place co
LEFT JOIN post_agg pa
    ON pa.country_id = co.id
LEFT JOIN comment_agg ca
    ON ca.country_id = co.id
WHERE co.type = 'Country'
ORDER BY total_posts DESC
LIMIT 20
