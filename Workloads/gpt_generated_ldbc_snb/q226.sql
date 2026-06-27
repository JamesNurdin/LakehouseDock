WITH liked_posts AS (
    SELECT
        plp.person_id,
        COUNT(DISTINCT plp.post_id) AS liked_posts_cnt,
        AVG(p.length) AS avg_liked_post_length,
        SUM(p.length) AS total_liked_post_length
    FROM person_likes_post plp
    JOIN post p
        ON plp.post_id = p.id
    GROUP BY plp.person_id
),
person_comments AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(DISTINCT c.id) AS comment_cnt,
        SUM(c.length) AS total_comment_length,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    GROUP BY c.creator_person_id
),
person_posts AS (
    SELECT
        po.creator_person_id AS person_id,
        COUNT(DISTINCT po.id) AS created_posts_cnt,
        SUM(po.length) AS total_post_length,
        AVG(po.length) AS avg_post_length
    FROM post po
    GROUP BY po.creator_person_id
),
reply_counts AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(r.id) AS reply_received_cnt
    FROM comment c
    LEFT JOIN comment r
        ON r.parent_comment_id = c.id
    GROUP BY c.creator_person_id
)
SELECT
    p.id AS person_id,
    p.first_name,
    p.last_name,
    p.gender,
    COALESCE(lp.liked_posts_cnt, 0) AS liked_posts_cnt,
    COALESCE(lp.avg_liked_post_length, 0) AS avg_liked_post_length,
    COALESCE(pc.comment_cnt, 0) AS comment_cnt,
    COALESCE(pc.total_comment_length, 0) AS total_comment_length,
    COALESCE(pc.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(pp.created_posts_cnt, 0) AS created_posts_cnt,
    COALESCE(pp.total_post_length, 0) AS total_post_length,
    COALESCE(pp.avg_post_length, 0) AS avg_post_length,
    COALESCE(rc.reply_received_cnt, 0) AS reply_received_cnt
FROM person p
LEFT JOIN liked_posts lp
    ON lp.person_id = p.id
LEFT JOIN person_comments pc
    ON pc.person_id = p.id
LEFT JOIN person_posts pp
    ON pp.person_id = p.id
LEFT JOIN reply_counts rc
    ON rc.person_id = p.id
ORDER BY liked_posts_cnt DESC, comment_cnt DESC
LIMIT 100
