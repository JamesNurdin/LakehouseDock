WITH post_tag_stats AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length,
        COUNT(pl.person_id) AS post_like_count,
        COUNT(DISTINCT p.creator_person_id) AS distinct_post_authors,
        COUNT(DISTINCT f.id) AS forum_count
    FROM tag t
    JOIN post_has_tag_tag pt ON pt.tag_id = t.id
    JOIN post p ON p.id = pt.post_id
    LEFT JOIN person_likes_post pl ON pl.post_id = p.id
    LEFT JOIN forum f ON f.id = p.container_forum_id
    GROUP BY t.id, t.name
),
comment_tag_stats AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(DISTINCT c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length,
        COUNT(cl.person_id) AS comment_like_count,
        COUNT(DISTINCT c.creator_person_id) AS distinct_comment_authors
    FROM tag t
    JOIN comment_has_tag_tag ct ON ct.tag_id = t.id
    JOIN comment c ON c.id = ct.comment_id
    LEFT JOIN person_likes_comment cl ON cl.comment_id = c.id
    GROUP BY t.id, t.name
)
SELECT
    COALESCE(p.tag_id, c.tag_id) AS tag_id,
    COALESCE(p.tag_name, c.tag_name) AS tag_name,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.avg_post_length, 0) AS avg_post_length,
    COALESCE(p.post_like_count, 0) AS post_like_count,
    COALESCE(p.distinct_post_authors, 0) AS distinct_post_authors,
    COALESCE(p.forum_count, 0) AS forum_count,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(c.comment_like_count, 0) AS comment_like_count,
    COALESCE(c.distinct_comment_authors, 0) AS distinct_comment_authors
FROM post_tag_stats p
FULL OUTER JOIN comment_tag_stats c ON c.tag_id = p.tag_id
ORDER BY tag_id
