WITH post_like_counts AS (
    SELECT
        p.id AS post_id,
        p.container_forum_id AS forum_id,
        p.length AS post_length,
        COUNT(pl.person_id) AS like_count
    FROM post p
    LEFT JOIN person_likes_post pl
        ON pl.post_id = p.id
    GROUP BY p.id, p.container_forum_id, p.length
),
forum_aggregates AS (
    SELECT
        plc.forum_id,
        COUNT(plc.post_id) AS post_count,
        AVG(plc.post_length) AS avg_post_length,
        SUM(plc.like_count) AS total_likes
    FROM post_like_counts plc
    GROUP BY plc.forum_id
),
forum_members AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
)
SELECT
    f.id AS forum_id,
    f.title,
    mod.first_name || ' ' || mod.last_name AS moderator_name,
    COALESCE(fm.member_count, 0) AS member_count,
    COALESCE(fa.post_count, 0) AS post_count,
    COALESCE(fa.avg_post_length, 0) AS avg_post_length,
    COALESCE(fa.total_likes, 0) AS total_likes
FROM forum f
LEFT JOIN forum_members fm
    ON fm.forum_id = f.id
LEFT JOIN forum_aggregates fa
    ON fa.forum_id = f.id
LEFT JOIN person mod
    ON mod.id = f.moderator_person_id
ORDER BY total_likes DESC
LIMIT 10
