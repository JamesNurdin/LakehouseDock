WITH post_like_counts AS (
    SELECT
        post_id,
        COUNT(*) AS like_cnt
    FROM person_likes_post
    GROUP BY post_id
),
comment_like_counts AS (
    SELECT
        comment_id,
        COUNT(*) AS like_cnt
    FROM person_likes_comment
    GROUP BY comment_id
),
post_tag_stats AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(DISTINCT p.id) AS post_count,
        SUM(p.length) AS total_post_length,
        AVG(p.length) AS avg_post_length,
        COALESCE(SUM(pl.like_cnt), 0) AS post_like_count,
        COUNT(DISTINCT p.container_forum_id) AS distinct_forum_count
    FROM tag t
    JOIN post_has_tag_tag pht ON pht.tag_id = t.id
    JOIN post p ON p.id = pht.post_id
    LEFT JOIN post_like_counts pl ON pl.post_id = p.id
    GROUP BY t.id, t.name
),
comment_tag_stats AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(DISTINCT c.id) AS comment_count,
        SUM(c.length) AS total_comment_length,
        AVG(c.length) AS avg_comment_length,
        COALESCE(SUM(cl.like_cnt), 0) AS comment_like_count
    FROM tag t
    JOIN comment_has_tag_tag cht ON cht.tag_id = t.id
    JOIN comment c ON c.id = cht.comment_id
    LEFT JOIN comment_like_counts cl ON cl.comment_id = c.id
    GROUP BY t.id, t.name
)
SELECT
    pt.tag_id,
    pt.tag_name,
    pt.post_count,
    ct.comment_count,
    (pt.post_like_count + ct.comment_like_count) AS total_like_count,
    (pt.total_post_length + ct.total_comment_length) AS total_content_length,
    (pt.avg_post_length + ct.avg_comment_length) / 2.0 AS avg_content_length,
    pt.distinct_forum_count AS distinct_forum_count_for_posts
FROM post_tag_stats pt
LEFT JOIN comment_tag_stats ct ON ct.tag_id = pt.tag_id
ORDER BY total_like_count DESC
LIMIT 20
