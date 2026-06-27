WITH post_counts AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(p.id) AS total_posts,
        AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
post_likes AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(plp.person_id) AS total_post_likes
    FROM post p
    LEFT JOIN person_likes_post plp
        ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_counts AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT c.id) AS total_comments,
        AVG(c.length) AS avg_comment_length
    FROM post p
    JOIN comment c
        ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
comment_likes AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(plc.person_id) AS total_comment_likes
    FROM post p
    JOIN comment c
        ON c.parent_post_id = p.id
    LEFT JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    GROUP BY p.container_forum_id
),
member_counts AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS distinct_members
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
moderators AS (
    SELECT
        f.id AS forum_id,
        p.first_name AS moderator_first_name,
        p.last_name AS moderator_last_name
    FROM forum f
    JOIN person p
        ON f.moderator_person_id = p.id
)
SELECT
    f.id AS forum_id,
    f.title,
    m.moderator_first_name,
    m.moderator_last_name,
    pc.total_posts,
    cc.total_comments,
    pc.avg_post_length,
    cc.avg_comment_length,
    pl.total_post_likes,
    cl.total_comment_likes,
    mem.distinct_members
FROM forum f
LEFT JOIN post_counts pc
    ON pc.forum_id = f.id
LEFT JOIN comment_counts cc
    ON cc.forum_id = f.id
LEFT JOIN post_likes pl
    ON pl.forum_id = f.id
LEFT JOIN comment_likes cl
    ON cl.forum_id = f.id
LEFT JOIN member_counts mem
    ON mem.forum_id = f.id
LEFT JOIN moderators m
    ON m.forum_id = f.id
ORDER BY f.id
