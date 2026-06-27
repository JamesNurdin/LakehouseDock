WITH post_counts AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT p.id) AS post_count,
           AVG(p.length) AS avg_post_length
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    GROUP BY f.id
),
comment_counts AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT c.id) AS comment_count,
           AVG(c.length) AS avg_comment_length
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    GROUP BY f.id
),
post_like_counts AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT plp.person_id) AS post_like_user_count
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN person_likes_post plp
        ON plp.post_id = p.id
    GROUP BY f.id
),
comment_like_counts AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT plc.person_id) AS comment_like_user_count
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    LEFT JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    GROUP BY f.id
),
member_counts AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum f
    LEFT JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    GROUP BY f.id
),
forum_tag_counts AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT ft.tag_id) AS forum_tag_count
    FROM forum f
    LEFT JOIN forum_has_tag_tag ft
        ON ft.forum_id = f.id
    GROUP BY f.id
),
post_tag_counts AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT pt.tag_id) AS post_tag_count
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN post_has_tag_tag pt
        ON pt.post_id = p.id
    GROUP BY f.id
)
SELECT f.id AS forum_id,
       f.title AS forum_title,
       COALESCE(pc.post_count, 0) AS post_count,
       COALESCE(cc.comment_count, 0) AS comment_count,
       COALESCE(plc.post_like_user_count, 0) AS post_like_user_count,
       COALESCE(clc.comment_like_user_count, 0) AS comment_like_user_count,
       COALESCE(mc.member_count, 0) AS member_count,
       COALESCE(ftc.forum_tag_count, 0) AS forum_tag_count,
       COALESCE(ptc.post_tag_count, 0) AS post_tag_count,
       pc.avg_post_length,
       cc.avg_comment_length
FROM forum f
LEFT JOIN post_counts pc
    ON pc.forum_id = f.id
LEFT JOIN comment_counts cc
    ON cc.forum_id = f.id
LEFT JOIN post_like_counts plc
    ON plc.forum_id = f.id
LEFT JOIN comment_like_counts clc
    ON clc.forum_id = f.id
LEFT JOIN member_counts mc
    ON mc.forum_id = f.id
LEFT JOIN forum_tag_counts ftc
    ON ftc.forum_id = f.id
LEFT JOIN post_tag_counts ptc
    ON ptc.forum_id = f.id
ORDER BY post_count DESC
LIMIT 10
