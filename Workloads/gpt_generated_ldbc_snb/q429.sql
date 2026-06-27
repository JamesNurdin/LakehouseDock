WITH
    -- Moderator information for each forum
    moderators AS (
        SELECT
            f.id AS forum_id,
            f.title,
            mod.first_name AS moderator_first_name,
            mod.last_name  AS moderator_last_name
        FROM forum f
        LEFT JOIN person mod
            ON f.moderator_person_id = mod.id
    ),

    -- Number of distinct members per forum
    member_counts AS (
        SELECT
            fm.forum_id,
            COUNT(DISTINCT fm.person_id) AS member_count
        FROM forum_has_member_person fm
        GROUP BY fm.forum_id
    ),

    -- Post statistics per forum
    post_counts AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(*)               AS post_count,
            AVG(p.length)          AS avg_post_length,
            SUM(p.length)          AS total_post_length
        FROM post p
        GROUP BY p.container_forum_id
    ),

    -- Distinct people who liked posts in each forum
    post_like_counts AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(DISTINCT pl.person_id) AS post_like_count
        FROM post p
        LEFT JOIN person_likes_post pl
            ON pl.post_id = p.id
        GROUP BY p.container_forum_id
    ),

    -- Distinct people who liked comments on posts in each forum
    comment_like_counts AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(DISTINCT cl.person_id) AS comment_like_count
        FROM post p
        LEFT JOIN comment c
            ON c.parent_post_id = p.id
        LEFT JOIN person_likes_comment cl
            ON cl.comment_id = c.id
        GROUP BY p.container_forum_id
    ),

    -- Number of distinct tags associated with each forum
    forum_tag_counts AS (
        SELECT
            ft.forum_id,
            COUNT(DISTINCT ft.tag_id) AS forum_tag_count
        FROM forum_has_tag_tag ft
        GROUP BY ft.forum_id
    ),

    -- Number of distinct interest‑tags held by the members of each forum
    member_interest_counts AS (
        SELECT
            fm.forum_id,
            COUNT(DISTINCT pi.tag_id) AS member_interest_tag_count
        FROM forum_has_member_person fm
        JOIN person m
            ON fm.person_id = m.id
        LEFT JOIN person_has_interest_tag pi
            ON pi.person_id = m.id
        GROUP BY fm.forum_id
    )
SELECT
    m.forum_id,
    m.title,
    m.moderator_first_name,
    m.moderator_last_name,
    COALESCE(mc.member_count, 0)               AS member_count,
    COALESCE(pc.post_count, 0)                 AS post_count,
    COALESCE(pc.avg_post_length, 0)            AS avg_post_length,
    COALESCE(pc.total_post_length, 0)          AS total_post_length,
    COALESCE(plc.post_like_count, 0)           AS post_like_count,
    COALESCE(clc.comment_like_count, 0)        AS comment_like_count,
    COALESCE(ftc.forum_tag_count, 0)           AS forum_tag_count,
    COALESCE(mic.member_interest_tag_count, 0) AS member_interest_tag_count
FROM moderators m
LEFT JOIN member_counts mc
    ON mc.forum_id = m.forum_id
LEFT JOIN post_counts pc
    ON pc.forum_id = m.forum_id
LEFT JOIN post_like_counts plc
    ON plc.forum_id = m.forum_id
LEFT JOIN comment_like_counts clc
    ON clc.forum_id = m.forum_id
LEFT JOIN forum_tag_counts ftc
    ON ftc.forum_id = m.forum_id
LEFT JOIN member_interest_counts mic
    ON mic.forum_id = m.forum_id
ORDER BY member_count DESC
LIMIT 10
