/*
   Top‑10 tags ranked by the total number of likes received on posts and on comments belonging to those posts.
   The query aggregates likes, comments and post statistics per post first, then rolls those up per tag.
*/
WITH post_base AS (
    SELECT
        p.id AS post_id,
        p.length AS post_length,
        p.creator_person_id AS post_creator_id
    FROM post p
),
post_likes AS (
    SELECT
        plp.post_id,
        COUNT(plp.person_id) AS post_like_count
    FROM person_likes_post plp
    GROUP BY plp.post_id
),
comment_stats AS (
    SELECT
        c.parent_post_id AS post_id,
        COUNT(c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    GROUP BY c.parent_post_id
),
comment_likes AS (
    SELECT
        c.parent_post_id AS post_id,
        COUNT(plc.person_id) AS comment_like_count
    FROM comment c
    LEFT JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    GROUP BY c.parent_post_id
),
post_aggregates AS (
    SELECT
        pb.post_id,
        pb.post_length,
        pb.post_creator_id,
        COALESCE(pl.post_like_count, 0)      AS post_like_count,
        COALESCE(cs.comment_count, 0)        AS comment_count,
        cs.avg_comment_length,
        COALESCE(cl.comment_like_count, 0)   AS comment_like_count
    FROM post_base pb
    LEFT JOIN post_likes pl   ON pl.post_id   = pb.post_id
    LEFT JOIN comment_stats cs ON cs.post_id   = pb.post_id
    LEFT JOIN comment_likes cl ON cl.post_id   = pb.post_id
),
tag_metrics AS (
    SELECT
        pt.tag_id,
        COUNT(DISTINCT pa.post_id)                AS post_count,
        SUM(pa.post_like_count)                   AS total_post_likes,
        SUM(pa.comment_like_count)                AS total_comment_likes,
        SUM(pa.comment_count)                     AS total_comments,
        AVG(pa.post_length)                       AS avg_post_length,
        AVG(pa.avg_comment_length)                AS avg_comment_length,
        COUNT(DISTINCT pa.post_creator_id)        AS distinct_creators
    FROM post_has_tag_tag pt
    JOIN post_aggregates pa
        ON pa.post_id = pt.post_id
    GROUP BY pt.tag_id
)
SELECT
    tag_id,
    post_count,
    total_post_likes,
    total_comment_likes,
    total_comments,
    avg_post_length,
    avg_comment_length,
    distinct_creators
FROM tag_metrics
ORDER BY total_post_likes DESC
LIMIT 10
