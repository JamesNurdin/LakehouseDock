WITH forum_members AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
forum_posts AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_count
    FROM post p
    GROUP BY p.container_forum_id
),
forum_post_likes AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(pl.person_id) AS like_count
    FROM post p
    LEFT JOIN person_likes_post pl ON pl.post_id = p.id
    GROUP BY p.container_forum_id
),
forum_post_comments AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(c.id) AS comment_count
    FROM post p
    LEFT JOIN comment c ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
forum_details AS (
    SELECT
        f.id AS forum_id,
        f.title,
        f.moderator_person_id,
        p_mod.gender AS moderator_gender,
        pl.name AS moderator_city
    FROM forum f
    LEFT JOIN person p_mod ON p_mod.id = f.moderator_person_id
    LEFT JOIN place pl ON pl.id = p_mod.location_city_id
)
SELECT
    d.forum_id,
    d.title,
    d.moderator_gender,
    d.moderator_city,
    COALESCE(m.member_count, 0) AS member_count,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(l.like_count, 0) AS total_post_likes,
    COALESCE(c.comment_count, 0) AS total_comments,
    CASE WHEN COALESCE(p.post_count, 0) > 0 THEN COALESCE(l.like_count, 0) * 1.0 / p.post_count ELSE 0 END AS avg_likes_per_post,
    CASE WHEN COALESCE(p.post_count, 0) > 0 THEN COALESCE(c.comment_count, 0) * 1.0 / p.post_count ELSE 0 END AS avg_comments_per_post
FROM forum_details d
LEFT JOIN forum_members m ON m.forum_id = d.forum_id
LEFT JOIN forum_posts p ON p.forum_id = d.forum_id
LEFT JOIN forum_post_likes l ON l.forum_id = d.forum_id
LEFT JOIN forum_post_comments c ON c.forum_id = d.forum_id
WHERE d.moderator_gender = 'male'
ORDER BY total_post_likes DESC
LIMIT 10
