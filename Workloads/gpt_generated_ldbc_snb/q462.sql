WITH comment_reply_counts AS (
    SELECT
        parent.id AS parent_comment_id,
        COUNT(child.id) AS reply_count
    FROM comment parent
    LEFT JOIN comment child
        ON child.parent_comment_id = parent.id
    GROUP BY parent.id
),
comment_stats AS (
    SELECT
        p.id AS person_id,
        COUNT(c.id) AS comments_created,
        AVG(c.length) AS avg_comment_length,
        COALESCE(SUM(r.reply_count), 0) AS total_replies_to_my_comments
    FROM person p
    LEFT JOIN comment c
        ON c.creator_person_id = p.id
    LEFT JOIN comment_reply_counts r
        ON r.parent_comment_id = c.id
    GROUP BY p.id
),
like_stats AS (
    SELECT
        p.id AS person_id,
        COUNT(plc.comment_id) AS comments_liked,
        COUNT(DISTINCT plc.comment_id) AS distinct_comments_liked,
        COUNT(plc_liked.comment_id) AS likes_on_my_comments
    FROM person p
    LEFT JOIN person_likes_comment plc
        ON plc.person_id = p.id
    LEFT JOIN comment c_my
        ON c_my.creator_person_id = p.id
    LEFT JOIN person_likes_comment plc_liked
        ON plc_liked.comment_id = c_my.id
    GROUP BY p.id
),
post_stats AS (
    SELECT
        p.id AS person_id,
        COUNT(po.id) AS posts_created
    FROM person p
    LEFT JOIN post po
        ON po.creator_person_id = p.id
    GROUP BY p.id
),
tag_stats AS (
    SELECT
        p.id AS person_id,
        COUNT(DISTINCT pit.tag_id) AS distinct_tags
    FROM person p
    LEFT JOIN person_has_interest_tag pit
        ON pit.person_id = p.id
    GROUP BY p.id
)
SELECT
    p.id,
    p.first_name,
    p.last_name,
    COALESCE(cs.comments_created, 0)            AS comments_created,
    COALESCE(cs.avg_comment_length, 0)          AS avg_comment_length,
    COALESCE(cs.total_replies_to_my_comments, 0) AS total_replies_to_my_comments,
    COALESCE(ls.comments_liked, 0)              AS comments_liked,
    COALESCE(ls.likes_on_my_comments, 0)        AS likes_on_my_comments,
    COALESCE(ps.posts_created, 0)               AS posts_created,
    COALESCE(ts.distinct_tags, 0)               AS distinct_tags
FROM person p
LEFT JOIN comment_stats cs ON cs.person_id = p.id
LEFT JOIN like_stats    ls ON ls.person_id = p.id
LEFT JOIN post_stats    ps ON ps.person_id = p.id
LEFT JOIN tag_stats     ts ON ts.person_id = p.id
ORDER BY likes_on_my_comments DESC
LIMIT 100
