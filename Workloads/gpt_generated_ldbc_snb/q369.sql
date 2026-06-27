WITH forum_posts AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        COUNT(p.id) AS num_posts,
        SUM(p.length) AS total_post_length,
        CASE WHEN COUNT(p.id) = 0 THEN 0 ELSE SUM(p.length) / COUNT(p.id) END AS avg_post_length
    FROM forum AS f
    LEFT JOIN post AS p
        ON p.container_forum_id = f.id
    GROUP BY f.id, f.title
),
forum_comments AS (
    SELECT
        f.id AS forum_id,
        COUNT(c.id) AS num_comments,
        SUM(c.length) AS total_comment_length,
        CASE WHEN COUNT(c.id) = 0 THEN 0 ELSE SUM(c.length) / COUNT(c.id) END AS avg_comment_length
    FROM forum AS f
    LEFT JOIN post AS p
        ON p.container_forum_id = f.id
    LEFT JOIN comment AS c
        ON c.parent_post_id = p.id
    GROUP BY f.id
),
forum_post_tags AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT pht.tag_id) AS distinct_post_tags
    FROM forum AS f
    LEFT JOIN post AS p
        ON p.container_forum_id = f.id
    LEFT JOIN post_has_tag_tag AS pht
        ON pht.post_id = p.id
    GROUP BY f.id
),
forum_comment_tags AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT cht.tag_id) AS distinct_comment_tags
    FROM forum AS f
    LEFT JOIN post AS p
        ON p.container_forum_id = f.id
    LEFT JOIN comment AS c
        ON c.parent_post_id = p.id
    LEFT JOIN comment_has_tag_tag AS cht
        ON cht.comment_id = c.id
    GROUP BY f.id
)
SELECT
    fp.forum_id,
    fp.forum_title,
    fp.num_posts,
    fp.total_post_length,
    fp.avg_post_length,
    fc.num_comments,
    fc.total_comment_length,
    fc.avg_comment_length,
    fpt.distinct_post_tags,
    fct.distinct_comment_tags
FROM forum_posts AS fp
LEFT JOIN forum_comments AS fc
    ON fc.forum_id = fp.forum_id
LEFT JOIN forum_post_tags AS fpt
    ON fpt.forum_id = fp.forum_id
LEFT JOIN forum_comment_tags AS fct
    ON fct.forum_id = fp.forum_id
ORDER BY fp.total_post_length DESC
LIMIT 10
