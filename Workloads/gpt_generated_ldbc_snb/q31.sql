/*
  Analytical query: Top 10 forums by total likes (post + comment) with activity metrics.
  The query aggregates per forum:
    • Number of posts
    • Number of comments
    • Likes on posts
    • Likes on comments
    • Average comment length
    • Number of distinct participants (post or comment creators)
  Results are ordered by total likes (posts + comments) descending.
*/
WITH post_stats AS (
    SELECT
        f.id AS forum_id,
        COUNT(p.id) AS post_count,
        COALESCE(SUM(pl.like_count), 0) AS post_like_count
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN (
        SELECT plp.post_id, COUNT(*) AS like_count
        FROM person_likes_post plp
        GROUP BY plp.post_id
    ) pl
        ON pl.post_id = p.id
    GROUP BY f.id
),
comment_stats AS (
    SELECT
        f.id AS forum_id,
        COUNT(c.id) AS comment_count,
        COALESCE(SUM(cl.like_count), 0) AS comment_like_count,
        AVG(c.length) AS avg_comment_length
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    LEFT JOIN (
        SELECT plc.comment_id, COUNT(*) AS like_count
        FROM person_likes_comment plc
        GROUP BY plc.comment_id
    ) cl
        ON cl.comment_id = c.id
    GROUP BY f.id
),
forum_participants AS (
    SELECT
        forum_id,
        COUNT(DISTINCT person_id) AS participant_count
    FROM (
        SELECT f.id AS forum_id, p.creator_person_id AS person_id
        FROM forum f
        JOIN post p
            ON p.container_forum_id = f.id
        UNION ALL
        SELECT f.id AS forum_id, c.creator_person_id AS person_id
        FROM forum f
        JOIN post p
            ON p.container_forum_id = f.id
        JOIN comment c
            ON c.parent_post_id = p.id
    ) u
    GROUP BY forum_id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(ps.post_like_count, 0) AS post_like_count,
    COALESCE(cs.comment_like_count, 0) AS comment_like_count,
    COALESCE(cs.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(fp.participant_count, 0) AS participant_count,
    (COALESCE(ps.post_like_count, 0) + COALESCE(cs.comment_like_count, 0)) AS total_like_count
FROM forum f
LEFT JOIN post_stats ps
    ON ps.forum_id = f.id
LEFT JOIN comment_stats cs
    ON cs.forum_id = f.id
LEFT JOIN forum_participants fp
    ON fp.forum_id = f.id
ORDER BY total_like_count DESC
LIMIT 10
