WITH forum_base AS (
    SELECT f.id AS forum_id,
           f.title AS forum_title
    FROM forum f
),
post_metrics AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT p.id) AS post_count,
           AVG(p.length) AS avg_post_length,
           COUNT(DISTINCT p.creator_person_id) AS distinct_poster_user_count
    FROM post p
    GROUP BY p.container_forum_id
),
comment_metrics AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT c.id) AS comment_count,
           AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
post_like_metrics AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT pl.person_id) AS post_like_user_count
    FROM person_likes_post pl
    JOIN post p ON pl.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_like_metrics AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT cl.person_id) AS comment_like_user_count
    FROM person_likes_comment cl
    JOIN comment c ON cl.comment_id = c.id
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
tag_metrics AS (
    SELECT t.forum_id,
           COUNT(DISTINCT t.tag_id) AS distinct_tag_count
    FROM (
        SELECT p.container_forum_id AS forum_id, pht.tag_id
        FROM post_has_tag_tag pht
        JOIN post p ON pht.post_id = p.id
        UNION
        SELECT p.container_forum_id AS forum_id, cht.tag_id
        FROM comment_has_tag_tag cht
        JOIN comment c ON cht.comment_id = c.id
        JOIN post p ON c.parent_post_id = p.id
    ) t
    GROUP BY t.forum_id
)
SELECT
    fb.forum_id,
    fb.forum_title,
    COALESCE(pm.post_count, 0) AS post_count,
    COALESCE(cm.comment_count, 0) AS comment_count,
    COALESCE(plm.post_like_user_count, 0) AS post_like_user_count,
    COALESCE(clm.comment_like_user_count, 0) AS comment_like_user_count,
    COALESCE(pm.avg_post_length, 0) AS avg_post_length,
    COALESCE(cm.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(pm.distinct_poster_user_count, 0) AS distinct_poster_user_count,
    COALESCE(tm.distinct_tag_count, 0) AS distinct_tag_count
FROM forum_base fb
LEFT JOIN post_metrics pm ON pm.forum_id = fb.forum_id
LEFT JOIN comment_metrics cm ON cm.forum_id = fb.forum_id
LEFT JOIN post_like_metrics plm ON plm.forum_id = fb.forum_id
LEFT JOIN comment_like_metrics clm ON clm.forum_id = fb.forum_id
LEFT JOIN tag_metrics tm ON tm.forum_id = fb.forum_id
ORDER BY post_count DESC
LIMIT 10
