WITH forum_posts AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        COUNT(p.id) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM forum AS f
    JOIN post AS p
        ON p.container_forum_id = f.id
    GROUP BY f.id, f.title
),
forum_comments AS (
    SELECT
        f.id AS forum_id,
        COUNT(c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM forum AS f
    JOIN post AS p
        ON p.container_forum_id = f.id
    JOIN comment AS c
        ON c.parent_post_id = p.id
    GROUP BY f.id
),
forum_post_likes AS (
    SELECT
        f.id AS forum_id,
        COUNT(pl.person_id) AS post_like_count
    FROM forum AS f
    JOIN post AS p
        ON p.container_forum_id = f.id
    JOIN person_likes_post AS pl
        ON pl.post_id = p.id
    GROUP BY f.id
),
forum_comment_likes AS (
    SELECT
        f.id AS forum_id,
        COUNT(cl.person_id) AS comment_like_count
    FROM forum AS f
    JOIN post AS p
        ON p.container_forum_id = f.id
    JOIN comment AS c
        ON c.parent_post_id = p.id
    JOIN person_likes_comment AS cl
        ON cl.comment_id = c.id
    GROUP BY f.id
),
forum_tag_counts AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT ct.tag_id) AS distinct_tag_count
    FROM forum AS f
    JOIN post AS p
        ON p.container_forum_id = f.id
    JOIN comment AS c
        ON c.parent_post_id = p.id
    JOIN comment_has_tag_tag AS ct
        ON ct.comment_id = c.id
    GROUP BY f.id
)
SELECT
    fp.forum_title,
    fp.post_count,
    fp.avg_post_length,
    fc.comment_count,
    fc.avg_comment_length,
    fpl.post_like_count,
    fcl.comment_like_count,
    ftc.distinct_tag_count
FROM forum_posts AS fp
LEFT JOIN forum_comments AS fc
    ON fc.forum_id = fp.forum_id
LEFT JOIN forum_post_likes AS fpl
    ON fpl.forum_id = fp.forum_id
LEFT JOIN forum_comment_likes AS fcl
    ON fcl.forum_id = fp.forum_id
LEFT JOIN forum_tag_counts AS ftc
    ON ftc.forum_id = fp.forum_id
ORDER BY fpl.post_like_count DESC
LIMIT 10
