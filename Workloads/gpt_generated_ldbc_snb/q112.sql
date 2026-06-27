WITH forum_stats AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        COUNT(p.id) AS total_posts,
        AVG(p.length) AS avg_post_length
    FROM forum f
    JOIN post p
        ON p.container_forum_id = f.id
    GROUP BY f.id, f.title
),
forum_tag_counts AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(*) AS tag_usage_count
    FROM post_has_tag_tag pht
    JOIN post p
        ON pht.post_id = p.id
    JOIN forum f
        ON p.container_forum_id = f.id
    JOIN tag t
        ON pht.tag_id = t.id
    GROUP BY f.id, f.title, t.id, t.name
),
ranked_tags AS (
    SELECT
        ftc.forum_id,
        ftc.forum_title,
        ftc.tag_name,
        ftc.tag_usage_count,
        ROW_NUMBER() OVER (PARTITION BY ftc.forum_id ORDER BY ftc.tag_usage_count DESC) AS tag_rank
    FROM forum_tag_counts ftc
)
SELECT
    fs.forum_id,
    fs.forum_title,
    fs.total_posts,
    fs.avg_post_length,
    rt.tag_name,
    rt.tag_usage_count,
    rt.tag_rank
FROM forum_stats fs
JOIN ranked_tags rt
    ON rt.forum_id = fs.forum_id
WHERE rt.tag_rank <= 3
ORDER BY fs.forum_id, rt.tag_rank
