WITH comment_agg AS (
    SELECT postid,
           COUNT(*) AS comment_count,
           SUM(score) AS comment_score_sum,
           AVG(score) AS comment_score_avg
    FROM comments
    GROUP BY postid
),
link_agg AS (
    SELECT postid,
           COUNT(*) AS link_count,
           COUNT(DISTINCT relatedpostid) AS distinct_related_posts,
           SUM(CASE WHEN linktypeid = 3 THEN 1 ELSE 0 END) AS linktype3_count
    FROM postlinks
    GROUP BY postid
)
SELECT
    t.id AS tag_id,
    t.excerptpostid AS excerpt_post_id,
    t.count AS tag_use_count,
    p.score AS post_score,
    p.viewcount AS post_viewcount,
    COALESCE(ca.comment_count, 0) AS comment_count,
    COALESCE(ca.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(ca.comment_score_avg, 0) AS comment_score_avg,
    COALESCE(la.link_count, 0) AS total_link_count,
    COALESCE(la.distinct_related_posts, 0) AS distinct_related_posts,
    COALESCE(la.linktype3_count, 0) AS linktype3_count,
    RANK() OVER (ORDER BY COALESCE(ca.comment_score_sum, 0) DESC) AS tag_rank
FROM tags t
JOIN posts p ON t.excerptpostid = p.id
LEFT JOIN comment_agg ca ON p.id = ca.postid
LEFT JOIN link_agg la ON p.id = la.postid
ORDER BY COALESCE(ca.comment_score_sum, 0) DESC
LIMIT 20
