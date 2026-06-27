WITH forum_stats AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        COUNT(DISTINCT p.id) AS post_count,
        COUNT(DISTINCT c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length,
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
post_tag_counts AS (
    SELECT
        p.container_forum_id AS forum_id,
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(*) AS tag_usage
    FROM post p
    JOIN post_has_tag_tag pt
        ON pt.post_id = p.id
    JOIN tag t
        ON t.id = pt.tag_id
    GROUP BY p.container_forum_id, t.id, t.name
),
top_tags AS (
    SELECT
        forum_id,
        tag_name,
        tag_usage,
        ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY tag_usage DESC) AS rn
    FROM post_tag_counts
)
SELECT
    fs.forum_id,
    fs.forum_title,
    fs.post_count,
    fs.comment_count,
    fs.avg_comment_length,
    fs.member_count,
    tt.tag_name,
    tt.tag_usage
FROM forum_stats fs
LEFT JOIN (
    SELECT forum_id, tag_name, tag_usage
    FROM top_tags
    WHERE rn <= 3
) tt
    ON tt.forum_id = fs.forum_id
ORDER BY fs.forum_id, tt.tag_usage DESC
