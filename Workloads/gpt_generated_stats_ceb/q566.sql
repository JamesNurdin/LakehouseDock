WITH tag_links AS (
    SELECT
        t.id AS tag_id,
        t.count AS tag_use_count,
        pl.id AS link_id,
        p.viewcount AS linking_post_viewcount,
        v.votetypeid AS vote_type
    FROM tags t
    JOIN posts p_ex
        ON t.excerptpostid = p_ex.id
    JOIN postlinks pl
        ON pl.relatedpostid = p_ex.id
    JOIN posts p
        ON pl.postid = p.id
    LEFT JOIN votes v
        ON v.postid = p.id
)
SELECT
    tag_id,
    tag_use_count,
    COUNT(DISTINCT link_id) AS linking_post_count,
    COALESCE(SUM(linking_post_viewcount), 0) AS total_viewcount_of_linking_posts,
    COALESCE(SUM(CASE WHEN vote_type = 2 THEN 1 ELSE 0 END), 0) AS upvote_count,
    COALESCE(SUM(CASE WHEN vote_type = 3 THEN 1 ELSE 0 END), 0) AS downvote_count,
    CASE
        WHEN COUNT(DISTINCT link_id) = 0 THEN 0
        ELSE COALESCE(SUM(linking_post_viewcount), 0) * 1.0 / COUNT(DISTINCT link_id)
    END AS avg_viewcount_per_link
FROM tag_links
GROUP BY tag_id, tag_use_count
ORDER BY total_viewcount_of_linking_posts DESC
LIMIT 20
