WITH forum_stats AS (
    SELECT
        f.id AS forum_id,
        f.title,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT c.id) AS comment_count,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    LEFT JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    GROUP BY f.id, f.title
),
forum_tag_usage AS (
    SELECT
        f.id AS forum_id,
        t.name AS tag_name,
        COUNT(*) AS tag_usage
    FROM forum f
    JOIN post p
        ON p.container_forum_id = f.id
    JOIN post_has_tag_tag pt
        ON pt.post_id = p.id
    JOIN tag t
        ON t.id = pt.tag_id
    GROUP BY f.id, t.name
),
forum_top_tag AS (
    SELECT
        forum_id,
        tag_name AS top_tag_name,
        tag_usage,
        ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY tag_usage DESC) AS rn
    FROM forum_tag_usage
)
SELECT
    fs.forum_id,
    fs.title,
    fs.post_count,
    fs.avg_post_length,
    fs.comment_count,
    fs.member_count,
    ftt.top_tag_name
FROM forum_stats fs
LEFT JOIN forum_top_tag ftt
    ON ftt.forum_id = fs.forum_id
   AND ftt.rn = 1
ORDER BY fs.post_count DESC
LIMIT 100
