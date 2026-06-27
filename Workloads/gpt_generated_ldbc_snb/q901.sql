-- Top 10 forums by total likes on their posts, with additional activity metrics
WITH forum_agg AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        mod.first_name AS moderator_first_name,
        mod.last_name AS moderator_last_name,
        COUNT(DISTINCT p.id) AS num_posts,
        COUNT(DISTINCT pl.person_id) AS total_post_likes,
        COUNT(DISTINCT ph.tag_id) AS num_tags,
        COUNT(DISTINCT fm.person_id) AS num_members
    FROM forum f
    LEFT JOIN person mod
        ON f.moderator_person_id = mod.id
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN person_likes_post pl
        ON pl.post_id = p.id
    LEFT JOIN post_has_tag_tag ph
        ON ph.post_id = p.id
    LEFT JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    GROUP BY
        f.id,
        f.title,
        mod.first_name,
        mod.last_name
)
SELECT
    forum_id,
    forum_title,
    moderator_first_name,
    moderator_last_name,
    num_posts,
    total_post_likes,
    num_tags,
    num_members
FROM forum_agg
ORDER BY total_post_likes DESC
LIMIT 10
