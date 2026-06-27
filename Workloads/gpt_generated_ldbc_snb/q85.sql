WITH post_counts AS (
    SELECT f.id AS forum_id,
           COUNT(*) AS post_count
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    GROUP BY f.id
),
comment_counts AS (
    SELECT f.id AS forum_id,
           COUNT(*) AS comment_count
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN comment c ON c.parent_post_id = p.id
    GROUP BY f.id
),
post_like_counts AS (
    SELECT f.id AS forum_id,
           COUNT(*) AS post_like_count
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN person_likes_post plp ON plp.post_id = p.id
    GROUP BY f.id
),
comment_like_counts AS (
    SELECT f.id AS forum_id,
           COUNT(*) AS comment_like_count
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN comment c ON c.parent_post_id = p.id
    JOIN person_likes_comment plc ON plc.comment_id = c.id
    GROUP BY f.id
),
member_counts AS (
    SELECT f.id AS forum_id,
           COUNT(*) AS member_count
    FROM forum f
    JOIN forum_has_member_person fhmp ON fhmp.forum_id = f.id
    GROUP BY f.id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COALESCE(pc.post_count, 0) AS post_count,
    COALESCE(cc.comment_count, 0) AS comment_count,
    COALESCE(plc.post_like_count, 0) AS post_like_count,
    COALESCE(clc.comment_like_count, 0) AS comment_like_count,
    COALESCE(mc.member_count, 0) AS member_count,
    COALESCE(pc.post_count, 0) + COALESCE(cc.comment_count, 0) + COALESCE(plc.post_like_count, 0) + COALESCE(clc.comment_like_count, 0) + COALESCE(mc.member_count, 0) AS total_interactions
FROM forum f
LEFT JOIN post_counts pc      ON pc.forum_id = f.id
LEFT JOIN comment_counts cc   ON cc.forum_id = f.id
LEFT JOIN post_like_counts plc ON plc.forum_id = f.id
LEFT JOIN comment_like_counts clc ON clc.forum_id = f.id
LEFT JOIN member_counts mc    ON mc.forum_id = f.id
ORDER BY total_interactions DESC
LIMIT 10
