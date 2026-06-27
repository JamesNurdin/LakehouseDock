WITH forum_stats AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        m.first_name AS moderator_first_name,
        m.last_name AS moderator_last_name,
        COUNT(DISTINCT p.id) AS post_count,
        COUNT(pl.person_id) AS total_likes,
        CASE
            WHEN COUNT(DISTINCT p.id) = 0 THEN 0.0
            ELSE CAST(COUNT(pl.person_id) AS double) / COUNT(DISTINCT p.id)
        END AS avg_likes_per_post
    FROM forum f
    LEFT JOIN person m
        ON f.moderator_person_id = m.id
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN person_likes_post pl
        ON pl.post_id = p.id
    GROUP BY f.id, f.title, m.first_name, m.last_name
),

tag_usage AS (
    SELECT
        f.id AS forum_id,
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(*) AS tag_usage
    FROM forum f
    JOIN post p
        ON p.container_forum_id = f.id
    JOIN post_has_tag_tag pht
        ON pht.post_id = p.id
    JOIN tag t
        ON t.id = pht.tag_id
    GROUP BY f.id, t.id, t.name
),

top_tag_per_forum AS (
    SELECT
        forum_id,
        tag_id,
        tag_name,
        tag_usage,
        ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY tag_usage DESC) AS rn
    FROM tag_usage
)
SELECT
    fs.forum_id,
    fs.forum_title,
    fs.moderator_first_name,
    fs.moderator_last_name,
    fs.post_count,
    fs.total_likes,
    fs.avg_likes_per_post,
    tt.tag_id   AS top_tag_id,
    tt.tag_name AS top_tag_name,
    tt.tag_usage AS top_tag_usage
FROM forum_stats fs
JOIN top_tag_per_forum tt
    ON tt.forum_id = fs.forum_id
WHERE tt.rn = 1
ORDER BY fs.total_likes DESC
LIMIT 10
