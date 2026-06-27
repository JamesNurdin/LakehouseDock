WITH post_like_counts AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(pl.person_id) AS total_post_likes
    FROM post p
    LEFT JOIN person_likes_post pl
        ON pl.post_id = p.id
    GROUP BY p.container_forum_id
),
post_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT p.id) AS post_count,
        SUM(p.length) / NULLIF(COUNT(DISTINCT p.id), 0) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
comment_like_counts AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(cl.person_id) AS total_comment_likes
    FROM comment c
    JOIN post p
        ON c.parent_post_id = p.id
    LEFT JOIN person_likes_comment cl
        ON cl.comment_id = c.id
    GROUP BY p.container_forum_id
),
comment_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT c.id) AS comment_count,
        SUM(c.length) / NULLIF(COUNT(DISTINCT c.id), 0) AS avg_comment_length
    FROM comment c
    JOIN post p
        ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
forum_members AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
forum_tags AS (
    SELECT
        ft.forum_id,
        COUNT(DISTINCT ft.tag_id) AS forum_tag_count
    FROM forum_has_tag_tag ft
    GROUP BY ft.forum_id
),
post_tags AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT pt.tag_id) AS post_tag_count
    FROM post_has_tag_tag pt
    JOIN post p
        ON pt.post_id = p.id
    GROUP BY p.container_forum_id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COALESCE(plc.total_post_likes, 0) AS total_post_likes,
    COALESCE(clc.total_comment_likes, 0) AS total_comment_likes,
    COALESCE(pm.member_count, 0) AS member_count,
    COALESCE(ft.forum_tag_count, 0) AS forum_tag_count,
    COALESCE(ptc.post_tag_count, 0) AS post_tag_count,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(ps.avg_post_length, 0) AS avg_post_length,
    COALESCE(cs.avg_comment_length, 0) AS avg_comment_length
FROM forum f
LEFT JOIN post_like_counts plc
    ON plc.forum_id = f.id
LEFT JOIN comment_like_counts clc
    ON clc.forum_id = f.id
LEFT JOIN forum_members pm
    ON pm.forum_id = f.id
LEFT JOIN forum_tags ft
    ON ft.forum_id = f.id
LEFT JOIN post_tags ptc
    ON ptc.forum_id = f.id
LEFT JOIN post_stats ps
    ON ps.forum_id = f.id
LEFT JOIN comment_stats cs
    ON cs.forum_id = f.id
ORDER BY (COALESCE(plc.total_post_likes, 0) + COALESCE(clc.total_comment_likes, 0)) DESC
LIMIT 10
