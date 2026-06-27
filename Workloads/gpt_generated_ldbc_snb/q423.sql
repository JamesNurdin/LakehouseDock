WITH forum_members AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum f
    JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    GROUP BY f.id
),
forum_posts AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        p_mod.first_name AS moderator_first_name,
        p_mod.last_name AS moderator_last_name,
        COUNT(DISTINCT po.id) AS post_count,
        AVG(po.length) AS avg_post_length
    FROM forum f
    JOIN person p_mod
        ON f.moderator_person_id = p_mod.id
    LEFT JOIN post po
        ON po.container_forum_id = f.id
    GROUP BY f.id, f.title, p_mod.first_name, p_mod.last_name
),
forum_likes AS (
    SELECT
        f.id AS forum_id,
        COUNT(pl.person_id) AS total_likes,
        COUNT(DISTINCT pl.person_id) AS distinct_likers
    FROM forum f
    LEFT JOIN post po
        ON po.container_forum_id = f.id
    LEFT JOIN person_likes_post pl
        ON pl.post_id = po.id
    GROUP BY f.id
)
SELECT
    fp.forum_id,
    fp.forum_title,
    fp.moderator_first_name,
    fp.moderator_last_name,
    fm.member_count,
    fp.post_count,
    fp.avg_post_length,
    fl.total_likes,
    fl.distinct_likers
FROM forum_posts fp
LEFT JOIN forum_members fm
    ON fm.forum_id = fp.forum_id
LEFT JOIN forum_likes fl
    ON fl.forum_id = fp.forum_id
ORDER BY fp.post_count DESC
LIMIT 10
