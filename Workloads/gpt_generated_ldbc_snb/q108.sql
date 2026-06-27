WITH
    forum_posts AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(*) AS post_cnt
        FROM post p
        GROUP BY p.container_forum_id
    ),
    forum_comments AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(*) AS comment_cnt
        FROM comment c
        JOIN post p ON c.parent_post_id = p.id
        GROUP BY p.container_forum_id
    ),
    forum_post_likes AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(*) AS post_like_cnt
        FROM person_likes_post plp
        JOIN post p ON plp.post_id = p.id
        GROUP BY p.container_forum_id
    ),
    forum_comment_likes AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(*) AS comment_like_cnt
        FROM person_likes_comment plc
        JOIN comment c ON plc.comment_id = c.id
        JOIN post p ON c.parent_post_id = p.id
        GROUP BY p.container_forum_id
    )
SELECT
    f.id AS forum_id,
    f.title,
    COALESCE(fp.post_cnt, 0)      AS post_count,
    COALESCE(fc.comment_cnt, 0)   AS comment_count,
    COALESCE(fpl.post_like_cnt, 0)   AS post_like_count,
    COALESCE(fcl.comment_like_cnt, 0) AS comment_like_count,
    (COALESCE(fp.post_cnt, 0) + COALESCE(fc.comment_cnt, 0) + COALESCE(fpl.post_like_cnt, 0) + COALESCE(fcl.comment_like_cnt, 0)) AS total_engagement
FROM forum f
LEFT JOIN forum_posts fp           ON fp.forum_id = f.id
LEFT JOIN forum_comments fc        ON fc.forum_id = f.id
LEFT JOIN forum_post_likes fpl     ON fpl.forum_id = f.id
LEFT JOIN forum_comment_likes fcl  ON fcl.forum_id = f.id
ORDER BY total_engagement DESC
LIMIT 5
