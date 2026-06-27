WITH forum_stats AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        mod.first_name AS moderator_first_name,
        mod.last_name AS moderator_last_name,
        COUNT(DISTINCT fm.person_id) AS member_count,
        COUNT(DISTINCT p.id) AS post_count,
        COALESCE(SUM(p.length), 0) AS total_post_length,
        COALESCE(AVG(p.length), 0) AS avg_post_length,
        COALESCE(SUM(pl.likes_per_post), 0) AS total_post_likes,
        COALESCE(AVG(pl.likes_per_post), 0) AS avg_likes_per_post,
        COUNT(DISTINCT c.id) AS comment_count,
        COALESCE(SUM(c.length), 0) AS total_comment_length,
        COALESCE(AVG(c.length), 0) AS avg_comment_length,
        COALESCE(SUM(cl.likes_per_comment), 0) AS total_comment_likes,
        COALESCE(AVG(cl.likes_per_comment), 0) AS avg_likes_per_comment,
        COUNT(DISTINCT pt.tag_id) AS distinct_post_tag_count
    FROM forum f
    LEFT JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    LEFT JOIN person mod
        ON f.moderator_person_id = mod.id
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN (
        SELECT
            pl.post_id,
            COUNT(*) AS likes_per_post
        FROM person_likes_post pl
        GROUP BY pl.post_id
    ) pl
        ON pl.post_id = p.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    LEFT JOIN (
        SELECT
            cl.comment_id,
            COUNT(*) AS likes_per_comment
        FROM person_likes_comment cl
        GROUP BY cl.comment_id
    ) cl
        ON cl.comment_id = c.id
    LEFT JOIN post_has_tag_tag pt
        ON pt.post_id = p.id
    GROUP BY
        f.id,
        f.title,
        mod.first_name,
        mod.last_name
)
SELECT *
FROM forum_stats
ORDER BY member_count DESC
LIMIT 10
