WITH tag_stats AS (
    SELECT
        pt.tag_id,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_length,
        MIN(p.creation_date) AS earliest_post,
        MAX(p.creation_date) AS latest_post
    FROM post_has_tag_tag pt
    JOIN post p
        ON pt.post_id = p.id
    GROUP BY pt.tag_id
)
SELECT
    tag_id,
    post_count,
    avg_length,
    earliest_post,
    latest_post,
    ROW_NUMBER() OVER (ORDER BY post_count DESC) AS rank_by_posts
FROM tag_stats
ORDER BY rank_by_posts
LIMIT 20
