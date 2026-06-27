/*
   Top 10 most active forums – activity measured by the sum of posts, comments
   and likes on comments. The query aggregates per forum, shows moderator name,
   counts, average lengths and a derived likes‑per‑comment metric.
*/
WITH forum_posts AS (
    SELECT
        f.id AS forum_id,
        f.title,
        f.moderator_person_id,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    GROUP BY
        f.id,
        f.title,
        f.moderator_person_id
),
forum_comments AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    GROUP BY
        f.id
),
forum_likes AS (
    SELECT
        f.id AS forum_id,
        COUNT(*) AS like_count
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    LEFT JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    GROUP BY
        f.id
),
forum_members AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum f
    LEFT JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    GROUP BY
        f.id
)
SELECT
    f.id,
    f.title,
    mod.first_name,
    mod.last_name,
    COALESCE(fp.post_count, 0)          AS post_count,
    COALESCE(fp.avg_post_length, 0)     AS avg_post_length,
    COALESCE(fc.comment_count, 0)       AS comment_count,
    COALESCE(fc.avg_comment_length, 0)  AS avg_comment_length,
    COALESCE(fl.like_count, 0)          AS like_count,
    COALESCE(fm.member_count, 0)        AS member_count,
    CASE
        WHEN COALESCE(fc.comment_count, 0) = 0 THEN 0
        ELSE COALESCE(fl.like_count, 0) / CAST(COALESCE(fc.comment_count, 0) AS double)
    END                                 AS likes_per_comment
FROM forum f
LEFT JOIN forum_posts fp
    ON fp.forum_id = f.id
LEFT JOIN forum_comments fc
    ON fc.forum_id = f.id
LEFT JOIN forum_likes fl
    ON fl.forum_id = f.id
LEFT JOIN forum_members fm
    ON fm.forum_id = f.id
LEFT JOIN person mod
    ON mod.id = f.moderator_person_id
ORDER BY
    (COALESCE(fp.post_count, 0) + COALESCE(fc.comment_count, 0) + COALESCE(fl.like_count, 0)) DESC
LIMIT 10
