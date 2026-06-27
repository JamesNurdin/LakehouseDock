WITH forum_tags AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        t.name AS tag_name,
        tc.name AS tag_class_name,
        mod.first_name AS moderator_first_name,
        mod.last_name AS moderator_last_name
    FROM forum f
    JOIN forum_has_tag_tag fht ON fht.forum_id = f.id
    JOIN tag t ON t.id = fht.tag_id
    LEFT JOIN tag_class tc ON t.type_tag_class_id = tc.id
    LEFT JOIN person mod ON f.moderator_person_id = mod.id
),
post_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT p.id) AS post_count,
        COUNT(plp.person_id) AS total_likes,
        COUNT(DISTINCT plp.person_id) AS distinct_likers,
        AVG(p.length) AS avg_post_length
    FROM post p
    LEFT JOIN person_likes_post plp ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
)
SELECT
    ft.forum_title,
    ft.tag_name,
    ft.tag_class_name,
    ft.moderator_first_name,
    ft.moderator_last_name,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(ps.total_likes, 0) AS total_likes,
    COALESCE(ps.distinct_likers, 0) AS distinct_likers,
    CASE WHEN COALESCE(ps.post_count, 0) = 0 THEN 0
         ELSE COALESCE(ps.total_likes, 0) * 1.0 / COALESCE(ps.post_count, 0)
    END AS avg_likes_per_post,
    COALESCE(ps.avg_post_length, 0) AS avg_post_length,
    COALESCE(cs.avg_comment_length, 0) AS avg_comment_length
FROM forum_tags ft
LEFT JOIN post_stats ps ON ps.forum_id = ft.forum_id
LEFT JOIN comment_stats cs ON cs.forum_id = ft.forum_id
ORDER BY avg_likes_per_post DESC
LIMIT 100
