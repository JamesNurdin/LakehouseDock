WITH forum_stats AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        COUNT(DISTINCT p.id) AS total_posts,
        AVG(p.length) AS avg_post_length
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    GROUP BY f.id, f.title
),
comment_stats AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT c.id) AS total_comments,
        AVG(c.length) AS avg_comment_length
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    GROUP BY f.id
),
like_stats AS (
    SELECT
        f.id AS forum_id,
        COUNT(plp.person_id) AS total_likes
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN person_likes_post plp
        ON plp.post_id = p.id
    GROUP BY f.id
),
tag_usage AS (
    -- Tags coming from posts
    SELECT
        f.id AS forum_id,
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(*) AS usage_count
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN post_has_tag_tag pht
        ON pht.post_id = p.id
    LEFT JOIN tag t
        ON pht.tag_id = t.id
    WHERE t.id IS NOT NULL
    GROUP BY f.id, t.id, t.name

    UNION ALL

    -- Tags coming from comments
    SELECT
        f.id AS forum_id,
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(*) AS usage_count
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    LEFT JOIN comment_has_tag_tag cht
        ON cht.comment_id = c.id
    LEFT JOIN tag t
        ON cht.tag_id = t.id
    WHERE t.id IS NOT NULL
    GROUP BY f.id, t.id, t.name
),
tag_counts AS (
    SELECT
        forum_id,
        tag_id,
        tag_name,
        SUM(usage_count) AS total_usage
    FROM tag_usage
    GROUP BY forum_id, tag_id, tag_name
),
top_tag_per_forum AS (
    SELECT
        forum_id,
        tag_name,
        total_usage,
        ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY total_usage DESC) AS rn
    FROM tag_counts
)
SELECT
    fs.forum_title,
    fs.total_posts,
    cs.total_comments,
    ls.total_likes,
    fs.avg_post_length,
    cs.avg_comment_length,
    tt.tag_name AS top_tag,
    tt.total_usage AS top_tag_usage
FROM forum_stats fs
LEFT JOIN comment_stats cs
    ON fs.forum_id = cs.forum_id
LEFT JOIN like_stats ls
    ON fs.forum_id = ls.forum_id
LEFT JOIN (
    SELECT forum_id, tag_name, total_usage
    FROM top_tag_per_forum
    WHERE rn = 1
) tt
    ON fs.forum_id = tt.forum_id
ORDER BY fs.total_posts DESC
LIMIT 10
