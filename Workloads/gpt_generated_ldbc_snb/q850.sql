WITH large_forums AS (
    SELECT forum_id
    FROM forum_has_member_person
    GROUP BY forum_id
    HAVING COUNT(DISTINCT person_id) >= 100
),
post_tag_usage AS (
    SELECT
        pt.tag_id,
        t.name AS tag_name,
        p.id AS post_id,
        p.length AS content_length,
        COUNT(plp.person_id) AS like_count
    FROM post_has_tag_tag pt
    JOIN post p ON pt.post_id = p.id
    JOIN large_forums lf ON p.container_forum_id = lf.forum_id
    JOIN tag t ON pt.tag_id = t.id
    LEFT JOIN person_likes_post plp ON plp.post_id = p.id
    GROUP BY pt.tag_id, t.name, p.id, p.length
),
comment_tag_usage AS (
    SELECT
        ct.tag_id,
        t.name AS tag_name,
        c.id AS comment_id,
        c.length AS content_length,
        COUNT(plc.person_id) AS like_count
    FROM comment_has_tag_tag ct
    JOIN comment c ON ct.comment_id = c.id
    JOIN post p ON c.parent_post_id = p.id
    JOIN large_forums lf ON p.container_forum_id = lf.forum_id
    JOIN tag t ON ct.tag_id = t.id
    LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
    GROUP BY ct.tag_id, t.name, c.id, c.length
),
tag_aggregated AS (
    SELECT
        tag_id,
        tag_name,
        COUNT(*) AS usage_count,
        SUM(content_length) AS total_length,
        SUM(like_count) AS total_likes,
        AVG(content_length) AS avg_length
    FROM (
        SELECT tag_id, tag_name, content_length, like_count FROM post_tag_usage
        UNION ALL
        SELECT tag_id, tag_name, content_length, like_count FROM comment_tag_usage
    ) AS combined
    GROUP BY tag_id, tag_name
)
SELECT
    tag_id,
    tag_name,
    usage_count,
    total_length,
    total_likes,
    avg_length
FROM tag_aggregated
ORDER BY usage_count DESC
LIMIT 10
