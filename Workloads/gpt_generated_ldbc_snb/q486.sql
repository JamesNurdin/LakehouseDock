WITH post_stats AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        COUNT(p.id) AS post_count,
        COALESCE(SUM(p.length), 0) AS total_post_length,
        COALESCE(SUM(pl.like_cnt), 0) AS total_post_likes
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    LEFT JOIN (
        SELECT post_id, COUNT(*) AS like_cnt
        FROM person_likes_post
        GROUP BY post_id
    ) pl ON pl.post_id = p.id
    GROUP BY f.id, f.title
),
comment_stats AS (
    SELECT
        f.id AS forum_id,
        COUNT(c.id) AS comment_count,
        COALESCE(SUM(cl.like_cnt), 0) AS total_comment_likes
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    LEFT JOIN comment c ON c.parent_post_id = p.id
    LEFT JOIN (
        SELECT comment_id, COUNT(*) AS like_cnt
        FROM person_likes_comment
        GROUP BY comment_id
    ) cl ON cl.comment_id = c.id
    GROUP BY f.id
),
forum_tag_usage AS (
    SELECT
        f.id AS forum_id,
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(*) AS tag_usage_count,
        ROW_NUMBER() OVER (PARTITION BY f.id ORDER BY COUNT(*) DESC) AS rn
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN post_has_tag_tag pht ON pht.post_id = p.id
    JOIN tag t ON t.id = pht.tag_id
    GROUP BY f.id, t.id, t.name
)
SELECT
    ps.forum_id,
    ps.forum_title,
    ps.post_count,
    ps.total_post_length,
    cs.comment_count,
    ps.total_post_likes,
    cs.total_comment_likes,
    ft.tag_name AS top_tag,
    ft.tag_usage_count AS top_tag_usage
FROM post_stats ps
LEFT JOIN comment_stats cs ON cs.forum_id = ps.forum_id
LEFT JOIN forum_tag_usage ft ON ft.forum_id = ps.forum_id AND ft.rn = 1
ORDER BY ps.post_count DESC
LIMIT 10
