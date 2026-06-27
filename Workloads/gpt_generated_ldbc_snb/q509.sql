WITH post_info AS (
    SELECT
        p.id AS post_id,
        p.creator_person_id,
        p.location_country_id,
        p.length AS post_length,
        pl.name AS country_name
    FROM post p
    JOIN place pl
        ON p.location_country_id = pl.id
),
likes_agg AS (
    SELECT
        plp.post_id,
        COUNT(plp.person_id) AS likes_cnt
    FROM person_likes_post plp
    GROUP BY plp.post_id
),
comments_agg AS (
    SELECT
        c.parent_post_id AS post_id,
        COUNT(c.id) AS comment_cnt,
        AVG(c.length) AS avg_comment_len
    FROM comment c
    GROUP BY c.parent_post_id
),
tags_agg AS (
    SELECT
        pht.post_id,
        COUNT(DISTINCT pht.tag_id) AS distinct_tag_cnt
    FROM post_has_tag_tag pht
    GROUP BY pht.post_id
)
SELECT
    pi.country_name AS country,
    COUNT(DISTINCT pi.post_id) AS total_posts,
    SUM(COALESCE(l.likes_cnt, 0)) AS total_likes,
    SUM(COALESCE(c.comment_cnt, 0)) AS total_comments,
    AVG(pi.post_length) AS avg_post_length,
    AVG(COALESCE(c.avg_comment_len, 0)) AS avg_comment_length,
    SUM(COALESCE(t.distinct_tag_cnt, 0)) AS total_distinct_tags,
    CASE WHEN COUNT(DISTINCT pi.post_id) = 0 THEN 0
         ELSE CAST(SUM(COALESCE(l.likes_cnt, 0)) AS double) / COUNT(DISTINCT pi.post_id)
    END AS avg_likes_per_post
FROM post_info pi
LEFT JOIN likes_agg l ON l.post_id = pi.post_id
LEFT JOIN comments_agg c ON c.post_id = pi.post_id
LEFT JOIN tags_agg t ON t.post_id = pi.post_id
GROUP BY pi.country_name
ORDER BY total_likes DESC
LIMIT 10
