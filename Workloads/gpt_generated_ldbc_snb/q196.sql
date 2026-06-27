WITH post_tag_usage AS (
    SELECT f.id AS forum_id,
           t.id AS tag_id,
           t.name AS tag_name,
           COUNT(*) AS usage_count
    FROM post_has_tag_tag pt
    JOIN post p ON pt.post_id = p.id
    JOIN forum f ON p.container_forum_id = f.id
    JOIN tag t ON pt.tag_id = t.id
    GROUP BY f.id, t.id, t.name
),
forum_tag_usage AS (
    SELECT f.id AS forum_id,
           t.id AS tag_id,
           t.name AS tag_name,
           COUNT(*) AS usage_count
    FROM forum_has_tag_tag ft
    JOIN forum f ON ft.forum_id = f.id
    JOIN tag t ON ft.tag_id = t.id
    GROUP BY f.id, t.id, t.name
),
combined_tag_usage AS (
    SELECT forum_id, tag_id, tag_name, usage_count FROM post_tag_usage
    UNION ALL
    SELECT forum_id, tag_id, tag_name, usage_count FROM forum_tag_usage
),
tag_agg AS (
    SELECT forum_id,
           tag_id,
           tag_name,
           SUM(usage_count) AS total_usage
    FROM combined_tag_usage
    GROUP BY forum_id, tag_id, tag_name
),
ranked_tags AS (
    SELECT forum_id,
           tag_id,
           tag_name,
           total_usage,
           ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY total_usage DESC, tag_name) AS tag_rank
    FROM tag_agg
),
forum_metrics AS (
    SELECT f.id AS forum_id,
           f.title AS forum_title,
           f.creation_date AS forum_creation_date,
           mod.id AS moderator_id,
           mod.first_name AS moderator_first_name,
           mod.last_name AS moderator_last_name,
           COUNT(DISTINCT p.id) AS post_count,
           COUNT(DISTINCT c.id) AS comment_count,
           COUNT(DISTINCT plp.person_id) AS like_user_count,
           AVG(p.length) AS avg_post_length,
           AVG(c.length) AS avg_comment_length,
           COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum f
    LEFT JOIN person mod ON f.moderator_person_id = mod.id
    LEFT JOIN post p ON p.container_forum_id = f.id
    LEFT JOIN comment c ON c.parent_post_id = p.id
    LEFT JOIN person_likes_post plp ON plp.post_id = p.id
    LEFT JOIN forum_has_member_person fm ON fm.forum_id = f.id
    GROUP BY f.id, f.title, f.creation_date, mod.id, mod.first_name, mod.last_name
)
SELECT
    fm.forum_id,
    fm.forum_title,
    fm.forum_creation_date,
    fm.moderator_id,
    fm.moderator_first_name,
    fm.moderator_last_name,
    fm.post_count,
    fm.comment_count,
    fm.like_user_count,
    fm.avg_post_length,
    fm.avg_comment_length,
    fm.member_count,
    rt.tag_name AS top_tag_name,
    rt.total_usage AS top_tag_usage
FROM forum_metrics fm
LEFT JOIN ranked_tags rt
    ON fm.forum_id = rt.forum_id AND rt.tag_rank = 1
ORDER BY fm.post_count DESC
LIMIT 10
