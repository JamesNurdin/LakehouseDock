WITH
    forum_base AS (
        SELECT id AS forum_id,
               title AS forum_title
        FROM forum
    ),
    member_counts AS (
        SELECT forum_id,
               COUNT(DISTINCT person_id) AS member_count
        FROM forum_has_member_person
        GROUP BY forum_id
    ),
    post_counts AS (
        SELECT container_forum_id AS forum_id,
               COUNT(*) AS post_count,
               AVG(length) AS avg_post_length
        FROM post
        GROUP BY container_forum_id
    ),
    comment_counts AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(*) AS comment_count
        FROM comment c
        JOIN post p ON c.parent_post_id = p.id
        GROUP BY p.container_forum_id
    ),
    post_like_counts AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(*) AS post_like_count
        FROM person_likes_post plp
        JOIN post p ON plp.post_id = p.id
        GROUP BY p.container_forum_id
    ),
    comment_like_counts AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(*) AS comment_like_count
        FROM person_likes_comment plc
        JOIN comment c ON plc.comment_id = c.id
        JOIN post p ON c.parent_post_id = p.id
        GROUP BY p.container_forum_id
    ),
    post_tag_counts AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(DISTINCT pt.tag_id) AS post_tag_count
        FROM post_has_tag_tag pt
        JOIN post p ON pt.post_id = p.id
        GROUP BY p.container_forum_id
    ),
    forum_tag_counts AS (
        SELECT forum_id,
               COUNT(DISTINCT tag_id) AS forum_tag_count
        FROM forum_has_tag_tag
        GROUP BY forum_id
    )
SELECT
    fb.forum_id,
    fb.forum_title,
    COALESCE(mc.member_count, 0)               AS member_count,
    COALESCE(pc.post_count, 0)                 AS post_count,
    pc.avg_post_length,
    COALESCE(cc.comment_count, 0)              AS comment_count,
    COALESCE(plc.post_like_count, 0)           AS post_like_count,
    COALESCE(clc.comment_like_count, 0)        AS comment_like_count,
    COALESCE(ptc.post_tag_count, 0)            AS post_tag_count,
    COALESCE(ftc.forum_tag_count, 0)           AS forum_tag_count
FROM forum_base fb
LEFT JOIN member_counts mc      ON mc.forum_id = fb.forum_id
LEFT JOIN post_counts pc        ON pc.forum_id = fb.forum_id
LEFT JOIN comment_counts cc     ON cc.forum_id = fb.forum_id
LEFT JOIN post_like_counts plc  ON plc.forum_id = fb.forum_id
LEFT JOIN comment_like_counts clc ON clc.forum_id = fb.forum_id
LEFT JOIN post_tag_counts ptc   ON ptc.forum_id = fb.forum_id
LEFT JOIN forum_tag_counts ftc  ON ftc.forum_id = fb.forum_id
ORDER BY post_like_count DESC
LIMIT 10
