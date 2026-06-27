-- Top 10 forums by total post likes, with counts of posts, comments, and distinct tags
WITH post_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT p.id) AS post_count,
        COUNT(DISTINCT plp.person_id) AS total_post_likes,
        COUNT(DISTINCT pht.tag_id) AS distinct_post_tags
    FROM post p
    LEFT JOIN person_likes_post plp
        ON plp.post_id = p.id
    LEFT JOIN post_has_tag_tag pht
        ON pht.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT c.id) AS comment_count,
        COUNT(DISTINCT plc.person_id) AS total_comment_likes,
        COUNT(DISTINCT cht.tag_id) AS distinct_comment_tags
    FROM comment c
    JOIN post p
        ON c.parent_post_id = p.id
    LEFT JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    LEFT JOIN comment_has_tag_tag cht
        ON cht.comment_id = c.id
    GROUP BY p.container_forum_id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.total_post_likes, 0) AS total_post_likes,
    COALESCE(ps.distinct_post_tags, 0) AS distinct_post_tags,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.total_comment_likes, 0) AS total_comment_likes,
    COALESCE(cs.distinct_comment_tags, 0) AS distinct_comment_tags
FROM forum f
LEFT JOIN post_stats ps
    ON ps.forum_id = f.id
LEFT JOIN comment_stats cs
    ON cs.forum_id = f.id
ORDER BY total_post_likes DESC
LIMIT 10
