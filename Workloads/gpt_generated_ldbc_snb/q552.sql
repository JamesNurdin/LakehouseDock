/*
  Analytical query: Top 10 most active forums by combined post and comment count.
  For each forum we report:
    • Forum id and title
    • Number of posts and distinct post authors
    • Number of comments and distinct comment authors
    • Average post length and average comment length
    • Total likes received on posts and on comments
  The query respects the allowed join relationships and uses only the selected tables.
*/
WITH post_metrics AS (
    SELECT
        f.id AS forum_id,
        COUNT(p.id) AS post_count,
        COUNT(DISTINCT p.creator_person_id) AS distinct_post_authors,
        AVG(p.length) AS avg_post_length,
        SUM(plp.like_cnt) AS total_post_likes
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN (
        SELECT post_id, COUNT(*) AS like_cnt
        FROM person_likes_post
        GROUP BY post_id
    ) plp
        ON plp.post_id = p.id
    GROUP BY f.id
),
comment_metrics AS (
    SELECT
        f.id AS forum_id,
        COUNT(c.id) AS comment_count,
        COUNT(DISTINCT c.creator_person_id) AS distinct_comment_authors,
        AVG(c.length) AS avg_comment_length,
        SUM(plc.like_cnt) AS total_comment_likes
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    LEFT JOIN (
        SELECT comment_id, COUNT(*) AS like_cnt
        FROM person_likes_comment
        GROUP BY comment_id
    ) plc
        ON plc.comment_id = c.id
    GROUP BY f.id
),
forum_info AS (
    SELECT id AS forum_id, title AS forum_title
    FROM forum
)
SELECT
    fi.forum_id,
    fi.forum_title,
    COALESCE(pm.post_count, 0)            AS post_count,
    COALESCE(cm.comment_count, 0)         AS comment_count,
    COALESCE(pm.distinct_post_authors, 0) AS distinct_post_authors,
    COALESCE(cm.distinct_comment_authors, 0) AS distinct_comment_authors,
    pm.avg_post_length,
    cm.avg_comment_length,
    COALESCE(pm.total_post_likes, 0)      AS total_post_likes,
    COALESCE(cm.total_comment_likes, 0)  AS total_comment_likes
FROM forum_info fi
LEFT JOIN post_metrics pm   ON pm.forum_id = fi.forum_id
LEFT JOIN comment_metrics cm ON cm.forum_id = fi.forum_id
ORDER BY (COALESCE(pm.post_count, 0) + COALESCE(cm.comment_count, 0)) DESC
LIMIT 10
