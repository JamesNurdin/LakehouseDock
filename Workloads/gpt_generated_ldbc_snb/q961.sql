WITH moderator_friends AS (
    SELECT
        f.id AS forum_id,
        CASE
            WHEN pk.person1_id = p.id THEN pk.person2_id
            ELSE pk.person1_id
        END AS friend_id
    FROM forum f
    JOIN person p ON f.moderator_person_id = p.id
    JOIN person_knows_person pk
        ON (pk.person1_id = p.id OR pk.person2_id = p.id)
),
likes_by_friends AS (
    SELECT
        mf.forum_id,
        COUNT(pl.person_id) AS likes_by_friends
    FROM moderator_friends mf
    JOIN post po ON po.container_forum_id = mf.forum_id
    JOIN person_likes_post pl ON pl.post_id = po.id
    WHERE pl.person_id = mf.friend_id
    GROUP BY mf.forum_id
),
forum_stats AS (
    SELECT
        f.id AS forum_id,
        f.title,
        COUNT(po.id) AS total_posts,
        AVG(po.length) AS avg_post_length
    FROM forum f
    JOIN post po ON po.container_forum_id = f.id
    GROUP BY f.id, f.title
)
SELECT
    fs.forum_id,
    fs.title,
    fs.total_posts,
    fs.avg_post_length,
    COALESCE(lbf.likes_by_friends, 0) AS likes_by_friends
FROM forum_stats fs
LEFT JOIN likes_by_friends lbf ON lbf.forum_id = fs.forum_id
ORDER BY likes_by_friends DESC
LIMIT 10
