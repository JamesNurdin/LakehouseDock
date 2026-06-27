/*
  Analytical query: for each forum and each tag that appears on posts within the forum,
  report the number of posts, total likes on those posts, total comments and comment length,
  and the average comment length per comment.
*/
WITH post_tags AS (
    SELECT
        f.id   AS forum_id,
        f.title AS forum_title,
        t.id   AS tag_id,
        t.name AS tag_name,
        p.id   AS post_id
    FROM forum f
    JOIN post p
        ON p.container_forum_id = f.id
    JOIN post_has_tag_tag pht
        ON pht.post_id = p.id
    JOIN tag t
        ON t.id = pht.tag_id
),
post_likes AS (
    SELECT
        p.id AS post_id,
        COUNT(pl.person_id) AS like_count
    FROM post p
    LEFT JOIN person_likes_post pl
        ON pl.post_id = p.id
    GROUP BY p.id
),
post_comments AS (
    SELECT
        p.id AS post_id,
        COUNT(c.id) AS comment_count,
        SUM(c.length) AS total_comment_length
    FROM post p
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    GROUP BY p.id
)
SELECT
    pt.forum_id,
    pt.forum_title,
    pt.tag_id,
    pt.tag_name,
    COUNT(DISTINCT pt.post_id)                                 AS post_count,
    SUM(COALESCE(pl.like_count, 0))                           AS total_likes,
    SUM(COALESCE(pc.comment_count, 0))                        AS total_comments,
    SUM(COALESCE(pc.total_comment_length, 0))                AS total_comment_length,
    CASE
        WHEN SUM(COALESCE(pc.comment_count, 0)) > 0
        THEN SUM(COALESCE(pc.total_comment_length, 0)) / SUM(COALESCE(pc.comment_count, 0))
        ELSE NULL
    END                                                       AS avg_comment_length
FROM post_tags pt
LEFT JOIN post_likes pl
    ON pl.post_id = pt.post_id
LEFT JOIN post_comments pc
    ON pc.post_id = pt.post_id
GROUP BY
    pt.forum_id,
    pt.forum_title,
    pt.tag_id,
    pt.tag_name
ORDER BY
    pt.forum_id,
    total_likes DESC
